import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/batch.dart';
import '../services/scan_history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanHistoryEntry> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final history = await ScanHistoryService().getHistory();
    if (mounted) setState(() {
      _history = history;
      _loading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
            'Are you sure you want to clear all scan history?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await ScanHistoryService().clearHistory();
      _load();
    }
  }

  Color _statusColor(bool isAuthentic, String status) {
    if (status.toLowerCase().contains('genuine')) {
      return const Color(0xFF4ADE80);
    }
    if (status.toLowerCase().contains('tamper')) {
      return const Color(0xFFF87171);
    }
    if (status.toLowerCase().contains('expir')) {
      return const Color(0xFFFBBF24);
    }
    if (status.toLowerCase().contains('recall')) {
      return const Color(0xFFF87171);
    }
    return const Color(0xFF94A3B8);
  }

  IconData _statusIcon(String status) {
    if (status.toLowerCase().contains('genuine')) return Icons.check_circle;
    if (status.toLowerCase().contains('tamper')) return Icons.cancel;
    if (status.toLowerCase().contains('expir')) return Icons.schedule;
    if (status.toLowerCase().contains('recall')) return Icons.warning;
    return Icons.help_outline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear history',
            ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? _buildEmpty(theme)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (context, i) =>
                        _buildHistoryTile(theme, _history[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.history,
                size: 40, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 16),
          Text('No scans yet',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: const Color(0xFF64748B))),
          const SizedBox(height: 8),
          Text('Your verification history will appear here',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: const Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(ThemeData theme, ScanHistoryEntry entry) {
    final color = _statusColor(entry.isAuthentic, entry.verificationStatus);
    final icon = _statusIcon(entry.verificationStatus);
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(entry.scannedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetail(entry),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.drugName,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.batchCode,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(
                  entry.verificationStatus,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(ScanHistoryEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _HistoryDetailSheet(entry: entry),
    );
  }
}

class _HistoryDetailSheet extends StatelessWidget {
  final ScanHistoryEntry entry;
  const _HistoryDetailSheet({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGenuine = entry.isAuthentic;
    final borderColor =
        isGenuine ? const Color(0xFF4ADE80) : const Color(0xFFF87171);
    final dateStr =
        DateFormat('MMMM d, yyyy – h:mm a').format(entry.scannedAt);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Icon(
            isGenuine ? Icons.check_circle : Icons.cancel,
            size: 56,
            color: borderColor,
          ),
          const SizedBox(height: 12),
          Text(
            isGenuine ? 'Authentic Medicine' : 'Verification Failed',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor.withOpacity(0.4)),
              ),
              child: Text(
                entry.verificationStatus,
                style: TextStyle(
                    color: borderColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _row(theme, 'Drug Name', entry.drugName),
          _row(theme, 'Batch Code', entry.batchCode),
          _row(theme, 'Scanned On', dateStr),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(entry.message,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: const Color(0xFF94A3B8))),
          ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: const Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
