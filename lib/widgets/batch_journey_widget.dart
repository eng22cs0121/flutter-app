import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/batch.dart';

/// Renders the supply-chain journey as a vertical timeline.
/// Mirrors the web app's BatchJourney component.
class BatchJourneyWidget extends StatelessWidget {
  final List<BatchHistoryEntry> history;

  const BatchJourneyWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.route_outlined, color: Color(0xFF64748B), size: 28),
              SizedBox(height: 8),
              Text(
                'No supply chain history available',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: history.asMap().entries.map((entry) {
        return _buildTimelineEntry(
          context,
          entry.value,
          isFirst: entry.key == 0,
          isLast: entry.key == history.length - 1,
        );
      }).toList(),
    );
  }

  Widget _buildTimelineEntry(
    BuildContext context,
    BatchHistoryEntry entry, {
    required bool isFirst,
    required bool isLast,
  }) {
    final color = _statusColor(entry.status);
    final icon = _statusIcon(entry.status);

    DateTime? dt;
    try {
      dt = DateTime.parse(entry.timestamp).toLocal();
    } catch (_) {}

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline spine ──────────────────────────────────────
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                      width: 2, height: 8, color: const Color(0xFF334155)),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child:
                        Container(width: 2, color: const Color(0xFF334155)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ── Content ─────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.location,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF1F5F9),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: color.withOpacity(0.4)),
                        ),
                        child: Text(
                          entry.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (dt != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      DateFormat('MMM d, yyyy · h:mm a').format(dt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                  if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.notes!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('approved')) return const Color(0xFF4ADE80);
    if (s.contains('transit')) return const Color(0xFF06B6D4);
    if (s.contains('pharmacy')) return const Color(0xFF8B5CF6);
    if (s.contains('sold')) return const Color(0xFF4ADE80);
    if (s.contains('recall')) return const Color(0xFFF87171);
    if (s.contains('created') || s.contains('pending')) {
      return const Color(0xFF6366F1);
    }
    return const Color(0xFF94A3B8);
  }

  IconData _statusIcon(String status) {
    final s = status.toLowerCase();
    if (s.contains('approved')) return Icons.verified_outlined;
    if (s.contains('transit')) return Icons.local_shipping_outlined;
    if (s.contains('pharmacy')) return Icons.local_pharmacy_outlined;
    if (s.contains('sold')) return Icons.check_circle_outline;
    if (s.contains('recall')) return Icons.cancel_outlined;
    if (s.contains('created')) return Icons.factory_outlined;
    if (s.contains('pending')) return Icons.pending_outlined;
    return Icons.circle_outlined;
  }
}
