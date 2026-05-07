/// Mirrors the `batches` Supabase table schema (database.types.ts)
class Batch {
  final String id;
  final String name;        // drug name
  final String mfg;         // manufacturing date (ISO string)
  final String exp;         // expiry date (ISO string)
  final int qty;
  final String status;
  final String? manufacturer;
  final String? dataHash;
  final String? currentHolder;
  final String? lastLocation;
  final bool isBlockchainSynced;
  final String? composition;
  final String? strength;
  final String createdAt;
  final String updatedAt;

  const Batch({
    required this.id,
    required this.name,
    required this.mfg,
    required this.exp,
    required this.qty,
    required this.status,
    this.manufacturer,
    this.dataHash,
    this.currentHolder,
    this.lastLocation,
    this.isBlockchainSynced = false,
    this.composition,
    this.strength,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Batch.fromJson(Map<String, dynamic> json) => Batch(
        id: json['id'] as String,
        name: json['name'] as String,
        mfg: json['mfg'] as String,
        exp: json['exp'] as String,
        qty: (json['qty'] as num).toInt(),
        status: json['status'] as String,
        manufacturer: json['manufacturer'] as String?,
        dataHash: json['data_hash'] as String?,
        currentHolder: json['current_holder'] as String?,
        lastLocation: json['last_location'] as String?,
        isBlockchainSynced: json['is_blockchain_synced'] as bool? ?? false,
        composition: json['composition'] as String?,
        strength: json['strength'] as String?,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );

  bool get isExpired {
    try {
      final expDate = DateTime.parse(exp);
      return DateTime.now().isAfter(expDate);
    } catch (_) {
      return false;
    }
  }

  bool get isRecalled => status.toLowerCase() == 'recalled';

  bool get isApproved =>
      ['approved', 'in-transit', 'at-pharmacy', 'sold']
          .contains(status.toLowerCase());
}

/// Mirrors the `batch_history` table
class BatchHistoryEntry {
  final String id;
  final String batchId;
  final String location;
  final String status;
  final String timestamp;
  final String? notes;
  final double? latitude;
  final double? longitude;

  const BatchHistoryEntry({
    required this.id,
    required this.batchId,
    required this.location,
    required this.status,
    required this.timestamp,
    this.notes,
    this.latitude,
    this.longitude,
  });

  factory BatchHistoryEntry.fromJson(Map<String, dynamic> json) =>
      BatchHistoryEntry(
        id: json['id'] as String,
        batchId: json['batch_id'] as String,
        location: json['location'] as String? ?? '',
        status: json['status'] as String,
        timestamp: json['timestamp'] as String,
        notes: json['notes'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}

/// Represents a completed scan stored in local history
class ScanHistoryEntry {
  final String id;
  final String batchCode;
  final String drugName;
  final String verificationStatus;
  final bool isAuthentic;
  final DateTime scannedAt;
  final String message;

  const ScanHistoryEntry({
    required this.id,
    required this.batchCode,
    required this.drugName,
    required this.verificationStatus,
    required this.isAuthentic,
    required this.scannedAt,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'batchCode': batchCode,
        'drugName': drugName,
        'verificationStatus': verificationStatus,
        'isAuthentic': isAuthentic,
        'scannedAt': scannedAt.toIso8601String(),
        'message': message,
      };

  factory ScanHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ScanHistoryEntry(
        id: json['id'] as String,
        batchCode: json['batchCode'] as String,
        drugName: json['drugName'] as String? ?? 'Unknown',
        verificationStatus: json['verificationStatus'] as String,
        isAuthentic: json['isAuthentic'] as bool,
        scannedAt: DateTime.parse(json['scannedAt'] as String),
        message: json['message'] as String? ?? '',
      );
}
