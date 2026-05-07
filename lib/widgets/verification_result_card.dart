import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/constants.dart';
import '../models/verification_result.dart';

class VerificationResultCard extends StatelessWidget {
  final VerificationResult result;
  final bool showLogs;
  final VoidCallback onToggleLogs;
  final VoidCallback onVerifyAgain;

  const VerificationResultCard({
    super.key,
    required this.result,
    required this.showLogs,
    required this.onToggleLogs,
    required this.onVerifyAgain,
  });

  // ── Helpers ─────────────────────────────────────────────────────────

  Color get _borderColor {
    switch (result.status) {
      case VerificationStatus.genuine:
        return const Color(0xFF4ADE80);
      case VerificationStatus.tampered:
      case VerificationStatus.recalled:
        return const Color(0xFFF87171);
      case VerificationStatus.expired:
      case VerificationStatus.notApproved:
        return const Color(0xFFFBBF24);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Color get _bgColor {
    switch (result.status) {
      case VerificationStatus.genuine:
        return const Color(0xFF052e16);
      case VerificationStatus.tampered:
      case VerificationStatus.recalled:
        return const Color(0xFF450a0a);
      case VerificationStatus.expired:
      case VerificationStatus.notApproved:
        return const Color(0xFF431407);
      default:
        return const Color(0xFF1E293B);
    }
  }

  IconData get _icon {
    switch (result.status) {
      case VerificationStatus.genuine:
        return Icons.check_circle;
      case VerificationStatus.tampered:
        return Icons.dangerous;
      case VerificationStatus.recalled:
        return Icons.cancel;
      case VerificationStatus.expired:
        return Icons.schedule;
      case VerificationStatus.notApproved:
        return Icons.warning_amber;
      case VerificationStatus.notFound:
        return Icons.search_off;
      default:
        return Icons.shield_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status header ────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Icon(_icon, size: 64, color: _borderColor),
                  const SizedBox(height: 10),
                  Text(
                    result.isAuthentic
                        ? 'Authentic Medicine'
                        : 'Verification Failed',
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _borderColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _borderColor.withOpacity(0.5), width: 1),
                    ),
                    child: Text(
                      result.status.label,
                      style: TextStyle(
                          color: _borderColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Message ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _borderColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _borderColor.withOpacity(0.25), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: _borderColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      result.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFCBD5E1)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Batch details ────────────────────────────────────
            if (_hasDetails) ...[
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF334155)),
              const SizedBox(height: 12),
              Text('Batch Details',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _buildDetailsGrid(theme),
            ],

            // ── Blockchain verification badge ─────────────────────
            if (result.details.blockchainVerified == true) ...[
              const SizedBox(height: 12),
              _buildBlockchainBadge(theme),
            ],

            // ── Action buttons ───────────────────────────────────
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onVerifyAgain,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Verify Again'),
                  ),
                ),
                if (result.details.batchId != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openBlockchainExplorer(
                          result.details.batchId!),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Explorer'),
                    ),
                  ),
                ],
              ],
            ),

            // ── Technical logs (collapsible) ─────────────────────
            if (result.logs.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: onToggleLogs,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        showLogs ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        showLogs
                            ? 'Hide technical logs'
                            : 'Show technical logs',
                        style: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              if (showLogs) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: SelectableText(
                    result.logs.join('\n'),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasDetails {
    final d = result.details;
    return d.drugName != null ||
        d.manufacturer != null ||
        d.expiryDate != null ||
        d.batchId != null;
  }

  Widget _buildDetailsGrid(ThemeData theme) {
    final d = result.details;
    final items = <_DetailItem>[
      if (d.drugName != null)
        _DetailItem(
            icon: Icons.medication_outlined, label: 'Drug Name', value: d.drugName!),
      if (d.batchId != null)
        _DetailItem(
            icon: Icons.qr_code_2, label: 'Batch ID', value: d.batchId!, mono: true),
      if (d.manufacturer != null)
        _DetailItem(
            icon: Icons.factory_outlined,
            label: 'Manufacturer',
            value: d.manufacturer!),
      if (d.manufacturingDate != null)
        _DetailItem(
            icon: Icons.calendar_today_outlined,
            label: 'Manufactured',
            value: d.manufacturingDate!),
      if (d.expiryDate != null)
        _DetailItem(
            icon: Icons.schedule_outlined,
            label: 'Expires',
            value: d.expiryDate!),
      if (d.quantity != null)
        _DetailItem(
            icon: Icons.inventory_2_outlined,
            label: 'Quantity',
            value: d.quantity!),
      if (d.batchStatus != null)
        _DetailItem(
            icon: Icons.info_outline,
            label: 'Status',
            value: d.batchStatus!),
      if (d.currentHolder != null)
        _DetailItem(
            icon: Icons.business_outlined,
            label: 'Current Holder',
            value: d.currentHolder!),
      if (d.lastLocation != null && d.lastLocation!.isNotEmpty)
        _DetailItem(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: d.lastLocation!),
    ];

    return Column(
      children: items.map((item) => _buildDetailRow(theme, item)).toList(),
    );
  }

  Widget _buildDetailRow(ThemeData theme, _DetailItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              item.label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: const Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              item.value,
              style: item.mono
                  ? theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFCBD5E1),
                    )
                  : theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (item.copyable)
            InkWell(
              onTap: () => Clipboard.setData(ClipboardData(text: item.value)),
              child: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.copy_outlined,
                    size: 14, color: Color(0xFF64748B)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlockchainBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0f2d1a),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: Color(0xFF4ADE80), width: 3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, size: 16, color: Color(0xFF4ADE80)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verified on ${AppConstants.chainName}',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF4ADE80),
                  fontWeight: FontWeight.w600),
            ),
          ),
          if (result.details.hashMatch == true)
            const Icon(Icons.verified, size: 16, color: Color(0xFF4ADE80)),
        ],
      ),
    );
  }

  void _openBlockchainExplorer(String batchCode) async {
    final url =
        '${AppConstants.blockExplorerUrl}/address/${AppConstants.contractAddress}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;
  final bool copyable;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
    this.copyable = false,
  });
}
