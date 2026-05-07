import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/batch.dart';

/// Wraps Supabase queries for patient-facing features.
/// All queries are read-only (uses anon key + RLS).
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._();
  factory SupabaseService() => _instance;
  SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ── Batches ──────────────────────────────────────────────────────────

  /// Fetch all batches (used as local fallback for verification).
  Future<List<Map<String, dynamic>>> fetchAllBatches() async {
    try {
      final response = await _client
          .from('batches')
          .select(
              'id, name, mfg, exp, qty, status, manufacturer, data_hash, '
              'current_holder, last_location, is_blockchain_synced, '
              'composition, strength, created_at, updated_at')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      return [];
    }
  }

  /// Fetch a single batch by its batch code (id).
  Future<Batch?> fetchBatchByCode(String batchCode) async {
    try {
      final response = await _client
          .from('batches')
          .select()
          .eq('id', batchCode.toUpperCase())
          .maybeSingle();

      if (response == null) return null;
      return Batch.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  // ── Batch History ─────────────────────────────────────────────────────

  /// Fetch supply-chain journey events for a batch.
  Future<List<BatchHistoryEntry>> fetchBatchHistory(String batchId) async {
    try {
      final response = await _client
          .from('batch_history')
          .select('id, batch_id, location, status, timestamp, notes, latitude, longitude')
          .eq('batch_id', batchId)
          .order('timestamp', ascending: true);

      return (response as List)
          .map((e) => BatchHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
