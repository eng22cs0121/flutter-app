import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../config/constants.dart';
import '../models/batch.dart';
import '../models/verification_result.dart';

/// Persists scan history to device storage (SharedPreferences).
class ScanHistoryService {
  static final ScanHistoryService _instance = ScanHistoryService._();
  factory ScanHistoryService() => _instance;
  ScanHistoryService._();

  static const _uuid = Uuid();

  Future<List<ScanHistoryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConstants.scanHistoryKey) ?? [];
    return raw
        .map((s) {
          try {
            return ScanHistoryEntry.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<ScanHistoryEntry>()
        .toList()
        .reversed
        .toList();
  }

  Future<void> saveResult(VerificationResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(AppConstants.scanHistoryKey) ?? [];

    final entry = ScanHistoryEntry(
      id: _uuid.v4(),
      batchCode: result.details.batchId ?? 'Unknown',
      drugName: result.details.drugName ?? 'Unknown',
      verificationStatus: result.status.label,
      isAuthentic: result.isAuthentic,
      scannedAt: result.verifiedAt,
      message: result.message,
    );

    existing.add(jsonEncode(entry.toJson()));

    // Keep only the most recent N entries
    final trimmed = existing.length > AppConstants.maxHistoryEntries
        ? existing.sublist(existing.length - AppConstants.maxHistoryEntries)
        : existing;

    await prefs.setStringList(AppConstants.scanHistoryKey, trimmed);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.scanHistoryKey);
  }
}
