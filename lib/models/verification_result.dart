/// Mirrors the VerificationResult from the web app's blockchain/verification.ts
enum VerificationStatus {
  genuine,
  tampered,
  notFound,
  notApproved,
  expired,
  recalled,
  blockchainError,
  notConfigured,
}

extension VerificationStatusLabel on VerificationStatus {
  String get label {
    switch (this) {
      case VerificationStatus.genuine:
        return 'GENUINE';
      case VerificationStatus.tampered:
        return 'TAMPERED';
      case VerificationStatus.notFound:
        return 'NOT FOUND';
      case VerificationStatus.notApproved:
        return 'NOT APPROVED';
      case VerificationStatus.expired:
        return 'EXPIRED';
      case VerificationStatus.recalled:
        return 'RECALLED';
      case VerificationStatus.blockchainError:
        return 'BLOCKCHAIN ERROR';
      case VerificationStatus.notConfigured:
        return 'NOT CONFIGURED';
    }
  }
}

class VerificationDetails {
  final String? batchId;
  final String? drugName;
  final String? manufacturer;
  final String? expiryDate;
  final String? manufacturingDate;
  final String? batchStatus;
  final String? quantity;
  final String? currentHolder;
  final String? lastLocation;
  final String? onChainHash;
  final bool? hashMatch;
  final bool? blockchainVerified;
  final String? contractStatus;

  const VerificationDetails({
    this.batchId,
    this.drugName,
    this.manufacturer,
    this.expiryDate,
    this.manufacturingDate,
    this.batchStatus,
    this.quantity,
    this.currentHolder,
    this.lastLocation,
    this.onChainHash,
    this.hashMatch,
    this.blockchainVerified,
    this.contractStatus,
  });

  Map<String, dynamic> toJson() => {
        'batchId': batchId,
        'drugName': drugName,
        'manufacturer': manufacturer,
        'expiryDate': expiryDate,
        'manufacturingDate': manufacturingDate,
        'batchStatus': batchStatus,
        'quantity': quantity,
        'currentHolder': currentHolder,
        'lastLocation': lastLocation,
        'onChainHash': onChainHash,
        'hashMatch': hashMatch,
        'blockchainVerified': blockchainVerified,
        'contractStatus': contractStatus,
      };

  factory VerificationDetails.fromJson(Map<String, dynamic> json) =>
      VerificationDetails(
        batchId: json['batchId'] as String?,
        drugName: json['drugName'] as String?,
        manufacturer: json['manufacturer'] as String?,
        expiryDate: json['expiryDate'] as String?,
        manufacturingDate: json['manufacturingDate'] as String?,
        batchStatus: json['batchStatus'] as String?,
        quantity: json['quantity'] as String?,
        currentHolder: json['currentHolder'] as String?,
        lastLocation: json['lastLocation'] as String?,
        onChainHash: json['onChainHash'] as String?,
        hashMatch: json['hashMatch'] as bool?,
        blockchainVerified: json['blockchainVerified'] as bool?,
        contractStatus: json['contractStatus'] as String?,
      );
}

class VerificationResult {
  final bool isAuthentic;
  final VerificationStatus status;
  final String message;
  final VerificationDetails details;
  final List<String> logs;
  final DateTime verifiedAt;

  const VerificationResult({
    required this.isAuthentic,
    required this.status,
    required this.message,
    required this.details,
    required this.logs,
    required this.verifiedAt,
  });

  Map<String, dynamic> toJson() => {
        'isAuthentic': isAuthentic,
        'status': status.name,
        'message': message,
        'details': details.toJson(),
        'logs': logs,
        'verifiedAt': verifiedAt.toIso8601String(),
      };

  factory VerificationResult.fromJson(Map<String, dynamic> json) =>
      VerificationResult(
        isAuthentic: json['isAuthentic'] as bool,
        status: VerificationStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => VerificationStatus.notFound,
        ),
        message: json['message'] as String,
        details: VerificationDetails.fromJson(
            json['details'] as Map<String, dynamic>),
        logs: List<String>.from(json['logs'] as List),
        verifiedAt: DateTime.parse(json['verifiedAt'] as String),
      );
}

/// Parsed QR code payload (matches web app's parseQRCodeData output)
class QRCodeData {
  final String? batchId;
  final String? batchCode;
  final String? drugName;
  final String? manufacturer;
  final dynamic mfgDate;
  final dynamic expDate;
  final int? quantity;
  final String? dataHash;

  const QRCodeData({
    this.batchId,
    this.batchCode,
    this.drugName,
    this.manufacturer,
    this.mfgDate,
    this.expDate,
    this.quantity,
    this.dataHash,
  });
}
