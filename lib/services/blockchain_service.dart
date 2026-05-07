import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

import '../config/constants.dart';
import '../models/verification_result.dart';

/// Mirrors web app's verifyBatchOnBlockchain() and related helpers
/// from src/lib/blockchain/verification.ts
class BlockchainService {
  static final BlockchainService _instance = BlockchainService._();
  factory BlockchainService() => _instance;
  BlockchainService._();

  Web3Client? _client;
  DeployedContract? _contract;

  // ── Status label mapping (matches BatchStatus enum in contract) ──────
  static const _statusLabels = <int, String>{
    0: 'Created',
    1: 'Pending Approval',
    2: 'Approved',
    3: 'In Transit',
    4: 'At Pharmacy',
    5: 'Sold',
    6: 'Recalled',
    7: 'Expired',
  };

  String _getStatusLabel(int status) =>
      _statusLabels[status] ?? 'Unknown ($status)';

  // ── Lazy initialisation ──────────────────────────────────────────────

  Web3Client get _ethClient {
    _client ??= Web3Client(AppConstants.rpcUrl, http.Client());
    return _client!;
  }

  DeployedContract get _deployedContract {
    if (_contract == null) {
      final abi = ContractAbi.fromJson(kMediTrustAbi, 'MediTrustChainV2');
      _contract = DeployedContract(
        abi,
        EthereumAddress.fromHex(AppConstants.contractAddress),
      );
    }
    return _contract!;
  }

  // ── Helper: bytes32 ↔ hex conversion ─────────────────────────────────

  /// Convert a 0x-prefixed hex hash to a 32-byte Uint8List (for bytes32 param).
  static Uint8List _hexToBytes32(String hexHash) {
    final clean = hexHash.startsWith('0x') ? hexHash.substring(2) : hexHash;
    final padded = clean.padLeft(64, '0');
    return Uint8List.fromList(hex.decode(padded));
  }

  /// Convert Uint8List to 0x-prefixed hex string.
  static String _bytes32ToHex(Uint8List bytes) {
    return '0x${hex.encode(bytes)}';
  }

  // ── QR code parsing (mirrors parseQRCodeData in verification.ts) ─────

  static QRCodeData? parseQRCodeData(String rawData) {
    try {
      final decoded = jsonDecode(rawData);
      if (decoded is String) {
        return QRCodeData(batchId: decoded.trim(), batchCode: decoded.trim());
      }
      if (decoded is Map<String, dynamic>) {
        return QRCodeData(
          batchId: decoded['batchCode'] as String? ?? decoded['batchId'] as String?,
          batchCode: decoded['batchCode'] as String? ?? decoded['batchId'] as String?,
          drugName: decoded['drugName'] as String?,
          manufacturer: decoded['manufacturer'] as String?,
          mfgDate: decoded['mfgDate'],
          expDate: decoded['expDate'],
          quantity: (decoded['quantity'] as num?)?.toInt(),
          dataHash: decoded['dataHash'] as String?,
        );
      }
    } catch (_) {
      // Not JSON – treat as plain batch code
      final trimmed = rawData.trim();
      if (trimmed.isNotEmpty) {
        return QRCodeData(batchId: trimmed, batchCode: trimmed);
      }
    }
    return null;
  }

  // ── Timestamp formatting ─────────────────────────────────────────────

  static String formatTimestamp(BigInt unixSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(
        unixSeconds.toInt() * 1000,
        isUtc: true);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static bool isBatchExpired(BigInt unixSeconds) {
    return DateTime.now().millisecondsSinceEpoch >
        unixSeconds.toInt() * 1000;
  }

  // ── Main verification entry point ─────────────────────────────────────

  Future<VerificationResult> verifyBatch(
    String qrCodeData, {
    List<Map<String, dynamic>>? localBatches,
  }) async {
    final logs = <String>[];
    void addLog(String msg) {
      final entry = '[${DateTime.now().toIso8601String()}] $msg';
      logs.add(entry);
    }

    addLog('=== BLOCKCHAIN VERIFICATION STARTED ===');

    // Step 1: Parse QR / batch code
    addLog('Step 1: Parsing QR code data...');
    final qrData = parseQRCodeData(qrCodeData);

    if (qrData == null || (qrData.batchCode ?? '').isEmpty) {
      addLog('❌ Failed to parse QR code or missing batchCode');
      return VerificationResult(
        isAuthentic: false,
        status: VerificationStatus.tampered,
        message: 'Invalid QR code format. This may be a counterfeit product.',
        details: const VerificationDetails(),
        logs: logs,
        verifiedAt: DateTime.now(),
      );
    }

    addLog('   Batch Code: ${qrData.batchCode}');
    addLog('   Drug Name: ${qrData.drugName ?? 'N/A'}');
    addLog('   QR Hash: ${qrData.dataHash ?? 'NOT PRESENT (legacy QR)'}');

    // Step 2: Try blockchain verification
    try {
      addLog('Step 2: Connecting to ${AppConstants.chainName}...');

      // Fetch batch ID by code
      final getBatchIdFn =
          _deployedContract.function('getBatchIdByCode');

      BigInt batchId;
      try {
        final idResult = await _ethClient.call(
          contract: _deployedContract,
          function: getBatchIdFn,
          params: [qrData.batchCode!],
        );
        batchId = idResult[0] as BigInt;
        addLog('   Found batch ID on-chain: $batchId');
      } catch (e) {
        addLog('❌ Batch not found on blockchain – falling back to database');
        return await _verifyWithLocalData(qrData, localBatches, logs);
      }

      if (batchId == BigInt.zero) {
        addLog('❌ Batch ID = 0 – not on blockchain');
        return await _verifyWithLocalData(qrData, localBatches, logs);
      }

      // Step 3: Get full batch data
      addLog('Step 3: Fetching full batch details from blockchain (V2)...');
      final getBatchFullFn = _deployedContract.function('getBatchFull');

      final fullResult = await _ethClient.call(
        contract: _deployedContract,
        function: getBatchFullFn,
        params: [batchId],
      );

      // Destructure BatchCore (index 0) and BatchState (index 1)
      // web3dart returns each tuple as List<dynamic>
      final batchCore = fullResult[0] as List<dynamic>;
      final batchState = fullResult[1] as List<dynamic>;

      // BatchCore fields: id, batchCode, manufacturer, drugName, quantity, mfgDate, expDate, createdAt, dataHash
      final onChainDrugName = batchCore[3].toString();
      final onChainManufacturer = batchCore[2].toString();
      final onChainQuantity = batchCore[4] as BigInt;
      final onChainMfgDate = batchCore[5] as BigInt;
      final onChainExpDate = batchCore[6] as BigInt;
      final onChainDataHashBytes = batchCore[8] as Uint8List;
      final onChainHash = _bytes32ToHex(onChainDataHashBytes);

      // BatchState fields: status, approvedAt, approvalHash, currentHolder, lastLocation, isRecalled, lastUpdated
      final onChainStatus = (batchState[0] as BigInt).toInt();
      final onChainIsRecalled = batchState[5] as bool;
      final onChainLastLocation = batchState[4].toString();

      addLog('   Drug Name: $onChainDrugName');
      addLog('   Manufacturer: $onChainManufacturer');
      addLog('   Status: ${_getStatusLabel(onChainStatus)}');
      addLog('   On-chain Hash: $onChainHash');
      addLog('   Is Recalled: $onChainIsRecalled');

      // Step 4: Hash comparison (primary anti-tampering check)
      addLog('Step 4: Hash verification...');
      final qrDataHash = qrData.dataHash;

      if (qrDataHash != null && qrDataHash.isNotEmpty) {
        if (qrDataHash.toLowerCase() != onChainHash.toLowerCase()) {
          addLog('❌ CRITICAL: QR hash ≠ on-chain hash – TAMPERED!');
          return VerificationResult(
            isAuthentic: false,
            status: VerificationStatus.tampered,
            message:
                '🚨 TAMPERED: The QR code hash does not match blockchain records. '
                'This may be a counterfeit product!',
            details: VerificationDetails(
              batchId: qrData.batchCode,
              drugName: onChainDrugName,
              manufacturer: onChainManufacturer,
              expiryDate: formatTimestamp(onChainExpDate),
              manufacturingDate: formatTimestamp(onChainMfgDate),
              quantity: onChainQuantity.toString(),
              batchStatus: _getStatusLabel(onChainStatus),
              onChainHash: onChainHash,
              hashMatch: false,
              blockchainVerified: true,
            ),
            logs: logs,
            verifiedAt: DateTime.now(),
          );
        }
        addLog('✅ QR hash matches on-chain hash');
      } else {
        addLog('   Legacy QR (no dataHash) – skipping hash comparison');
      }

      // Step 5: Call verifyBatchWithHash on contract
      addLog('Step 5: Calling verifyBatchWithHash() on contract...');
      final hashToVerify = qrDataHash != null && qrDataHash.isNotEmpty
          ? _hexToBytes32(qrDataHash)
          : onChainDataHashBytes;

      final verifyFn = _deployedContract.function('verifyBatchWithHash');
      final verifyResult = await _ethClient.call(
        contract: _deployedContract,
        function: verifyFn,
        params: [batchId, hashToVerify],
      );

      final contractIsGenuine = verifyResult[0] as bool;
      final contractStatus = verifyResult[1].toString();

      addLog(
          '   Contract result: ${contractIsGenuine ? "✅ GENUINE" : "❌ NOT GENUINE"}');
      addLog('   Contract status: $contractStatus');

      final baseDetails = VerificationDetails(
        batchId: qrData.batchCode,
        drugName: onChainDrugName,
        manufacturer: onChainManufacturer,
        expiryDate: formatTimestamp(onChainExpDate),
        manufacturingDate: formatTimestamp(onChainMfgDate),
        quantity: onChainQuantity.toString(),
        batchStatus: _getStatusLabel(onChainStatus),
        lastLocation: onChainLastLocation,
        onChainHash: onChainHash,
        hashMatch: true,
        blockchainVerified: true,
        contractStatus: contractStatus,
      );

      switch (contractStatus.toUpperCase()) {
        case 'TAMPERED':
          return VerificationResult(
            isAuthentic: false,
            status: VerificationStatus.tampered,
            message:
                '🚨 TAMPERED: Data mismatch detected on blockchain. Possible counterfeit!',
            details: baseDetails,
            logs: logs,
            verifiedAt: DateTime.now(),
          );
        case 'RECALLED':
          return VerificationResult(
            isAuthentic: false,
            status: VerificationStatus.recalled,
            message:
                '⚠️ RECALLED: Batch ${qrData.batchCode} has been recalled. DO NOT USE.',
            details: baseDetails,
            logs: logs,
            verifiedAt: DateTime.now(),
          );
        case 'EXPIRED':
          return VerificationResult(
            isAuthentic: false,
            status: VerificationStatus.expired,
            message:
                '⚠️ EXPIRED: This medicine expired on ${formatTimestamp(onChainExpDate)}.',
            details: baseDetails,
            logs: logs,
            verifiedAt: DateTime.now(),
          );
        case 'NOT_APPROVED':
          return VerificationResult(
            isAuthentic: false,
            status: VerificationStatus.notApproved,
            message:
                '⚠️ NOT APPROVED: Batch ${qrData.batchCode} has not been approved by regulators.',
            details: baseDetails,
            logs: logs,
            verifiedAt: DateTime.now(),
          );
        default:
          // GENUINE or unknown positive
          addLog('✅ RESULT: Batch is GENUINE');
          return VerificationResult(
            isAuthentic: true,
            status: VerificationStatus.genuine,
            message:
                '✅ AUTHENTIC: $onChainDrugName (Batch ${qrData.batchCode}) is verified genuine on the blockchain.',
            details: baseDetails,
            logs: logs,
            verifiedAt: DateTime.now(),
          );
      }
    } catch (e) {
      addLog('⚠️ Blockchain call failed: $e');
      addLog('Falling back to Supabase database verification...');
      return await _verifyWithLocalData(qrData, localBatches, logs);
    }
  }

  // ── Supabase fallback (mirrors verifyWithLocalData in verification.ts) ─

  Future<VerificationResult> _verifyWithLocalData(
    QRCodeData qrData,
    List<Map<String, dynamic>>? localBatches,
    List<String> logs,
  ) async {
    void addLog(String msg) {
      logs.add('[${DateTime.now().toIso8601String()}] $msg');
    }

    addLog('=== DATABASE FALLBACK VERIFICATION ===');

    if (localBatches == null || localBatches.isEmpty) {
      addLog('❌ No local batch data available');
      return VerificationResult(
        isAuthentic: false,
        status: VerificationStatus.notFound,
        message:
            'Batch "${qrData.batchCode}" not found. Please check the batch code.',
        details: VerificationDetails(batchId: qrData.batchCode),
        logs: logs,
        verifiedAt: DateTime.now(),
      );
    }

    // Find batch by id (batch code)
    final batchJson = localBatches.firstWhere(
      (b) =>
          b['id']?.toString().toLowerCase() ==
          qrData.batchCode?.toLowerCase(),
      orElse: () => {},
    );

    if (batchJson.isEmpty) {
      addLog('❌ Batch "${qrData.batchCode}" not found in database');
      return VerificationResult(
        isAuthentic: false,
        status: VerificationStatus.notFound,
        message:
            'Batch "${qrData.batchCode}" not found in the system.',
        details: VerificationDetails(batchId: qrData.batchCode),
        logs: logs,
        verifiedAt: DateTime.now(),
      );
    }

    addLog('✅ Found batch in database');
    final status = (batchJson['status'] as String? ?? '').toLowerCase();
    final expStr = batchJson['exp'] as String? ?? '';
    final drugName = batchJson['name'] as String? ?? 'Unknown';
    final manufacturer = batchJson['manufacturer'] as String? ?? 'Unknown';

    final details = VerificationDetails(
      batchId: qrData.batchCode,
      drugName: drugName,
      manufacturer: manufacturer,
      expiryDate: expStr,
      manufacturingDate: batchJson['mfg'] as String?,
      batchStatus: batchJson['status'] as String?,
      quantity: batchJson['qty']?.toString(),
      currentHolder: batchJson['current_holder'] as String?,
      lastLocation: batchJson['last_location'] as String?,
      blockchainVerified: false,
    );

    // Check recall
    if (status == 'recalled') {
      addLog('❌ Batch is RECALLED');
      return VerificationResult(
        isAuthentic: false,
        status: VerificationStatus.recalled,
        message: '⚠️ RECALLED: Batch ${qrData.batchCode} has been recalled by regulators. DO NOT USE.',
        details: details,
        logs: logs,
        verifiedAt: DateTime.now(),
      );
    }

    // Check expiry
    if (expStr.isNotEmpty) {
      try {
        final expDate = DateTime.parse(expStr);
        if (DateTime.now().isAfter(expDate)) {
          addLog('❌ Batch is EXPIRED');
          return VerificationResult(
            isAuthentic: false,
            status: VerificationStatus.expired,
            message: '⚠️ EXPIRED: This medicine expired on $expStr.',
            details: details,
            logs: logs,
            verifiedAt: DateTime.now(),
          );
        }
      } catch (_) {}
    }

    // Check approval
    final approvedStatuses = {'approved', 'in-transit', 'at-pharmacy', 'sold'};
    if (!approvedStatuses.contains(status)) {
      addLog('❌ Batch not approved (status: $status)');
      return VerificationResult(
        isAuthentic: false,
        status: VerificationStatus.notApproved,
        message:
            '⚠️ NOT APPROVED: Batch ${qrData.batchCode} has not been approved by regulators yet.',
        details: details,
        logs: logs,
        verifiedAt: DateTime.now(),
      );
    }

    addLog('✅ RESULT: Batch is GENUINE (database verification)');
    return VerificationResult(
      isAuthentic: true,
      status: VerificationStatus.genuine,
      message:
          '✅ AUTHENTIC: $drugName (Batch ${qrData.batchCode}) is verified in the database.',
      details: details,
      logs: logs,
      verifiedAt: DateTime.now(),
    );
  }

  void dispose() {
    _client?.dispose();
    _client = null;
    _contract = null;
  }
}
