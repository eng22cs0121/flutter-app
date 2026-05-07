import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/constants.dart';
import '../models/batch.dart';
import '../models/verification_result.dart';
import '../services/supabase_service.dart';
import 'batch_journey_widget.dart';
import 'shipment_map_widget.dart';

class VerificationResultCard extends StatefulWidget {
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

  @override
  State<VerificationResultCard> createState() =>
      _VerificationResultCardState();
}

class _VerificationResultCardState extends State<VerificationResultCard>
    with SingleTickerProviderStateMixin {
  // ── Extra data (loaded asynchronously) ──────────────────────────────
  Batch? _batchDetails;
  List<BatchHistoryEntry> _history = [];
  bool _loadingExtra = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    _loadExtra();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadExtra() async {
    final batchId = widget.result.details.batchId;
    if (batchId == null) return;
    setState(() => _loadingExtra = true);
    try {
      final results = await Future.wait([
        SupabaseService().fetchBatchByCode(batchId),
        SupabaseService().fetchBatchHistory(batchId),
      ]);
      if (mounted) {
        setState(() {
          _batchDetails = results[0] as Batch?;
          _history = results[1] as List<BatchHistoryEntry>;
          _loadingExtra = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingExtra = false);
    }
  }

  // ── Theme helpers ────────────────────────────────────────────────────

  Color get _borderColor {
    switch (widget.result.status) {
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
    switch (widget.result.status) {
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

  IconData get _statusIcon {
    switch (widget.result.status) {
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

  bool get _hasDetails {
    final d = widget.result.details;
    return d.drugName != null ||
        d.manufacturer != null ||
        d.expiryDate != null ||
        d.batchId != null;
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedContainer(
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
              // ── Status header ──────────────────────────────────
              _buildStatusHeader(theme),
              const SizedBox(height: 16),

              // ── Message ────────────────────────────────────────
              _buildMessageBox(theme),

              // ── Batch details ──────────────────────────────────
              if (_hasDetails) ...[
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF334155)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 16, color: _borderColor),
                  const SizedBox(width: 6),
                  Text('Batch Information',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 10),
              _buildDetailsGrid(theme),
            ],

            // ── Blockchain verification badge ─────────────────────
            if (widget.result.details.blockchainVerified == true) ...[
              const SizedBox(height: 12),
              _buildBlockchainBadge(theme),
            ],

            // ── Authentic-only: extra data ────────────────────────
            if (widget.result.isAuthentic) ...[
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF334155), height: 1),
              _buildExtraSections(theme),
            ],

            // ── Action buttons ───────────────────────────────────
            const SizedBox(height: 16),
            _buildActionButtons(),

            // ── Technical logs (collapsible) ─────────────────────
            if (widget.result.logs.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildLogsToggle(theme),
            ],
          ],
        ),
      ),
    ),
  );
  }

  // ── Section builders ─────────────────────────────────────────────────

  Widget _buildStatusHeader(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Icon(_statusIcon, size: 64, color: _borderColor),
          const SizedBox(height: 10),
          Text(
            widget.result.isAuthentic
                ? 'Authentic Medicine'
                : 'Verification Failed',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _borderColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _borderColor.withOpacity(0.5), width: 1),
            ),
            child: Text(
              widget.result.status.label,
              style: TextStyle(
                color: _borderColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBox(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _borderColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: _borderColor.withOpacity(0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: _borderColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.result.message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: const Color(0xFFCBD5E1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(ThemeData theme) {
    final d = widget.result.details;
    final items = <_DetailItem>[
      if (d.drugName != null)
        _DetailItem(icon: Icons.medication_outlined, label: 'Drug Name', value: d.drugName!),
      if (d.batchId != null)
        _DetailItem(icon: Icons.qr_code_2, label: 'Batch ID', value: d.batchId!, mono: true),
      if (d.manufacturer != null)
        _DetailItem(icon: Icons.factory_outlined, label: 'Manufacturer', value: d.manufacturer!),
      if (d.manufacturingDate != null)
        _DetailItem(icon: Icons.calendar_today_outlined, label: 'Manufactured', value: d.manufacturingDate!),
      if (d.expiryDate != null)
        _DetailItem(icon: Icons.schedule_outlined, label: 'Expires', value: d.expiryDate!),
      if (d.quantity != null)
        _DetailItem(icon: Icons.inventory_2_outlined, label: 'Quantity', value: d.quantity!),
      if (d.batchStatus != null)
        _DetailItem(icon: Icons.info_outline, label: 'Status', value: d.batchStatus!),
      if (d.currentHolder != null)
        _DetailItem(icon: Icons.business_outlined, label: 'Current Holder', value: d.currentHolder!),
      if (d.lastLocation != null && d.lastLocation!.isNotEmpty)
        _DetailItem(icon: Icons.location_on_outlined, label: 'Last Location', value: d.lastLocation!),
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
            child: Text(item.label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: const Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(
              item.value,
              style: item.mono
                  ? theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFCBD5E1))
                  : theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          InkWell(
            onTap: () =>
                Clipboard.setData(ClipboardData(text: item.value)),
            borderRadius: BorderRadius.circular(4),
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
      decoration: const BoxDecoration(
        color: Color(0xFF0f2d1a),
        borderRadius: BorderRadius.all(Radius.circular(10)),
        border: Border(left: BorderSide(color: Color(0xFF4ADE80), width: 3)),
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
          if (widget.result.details.hashMatch == true)
            const Icon(Icons.verified, size: 16, color: Color(0xFF4ADE80)),
        ],
      ),
    );
  }

  Widget _buildExtraSections(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // ── Drug Safety Profile ────────────────────────────────
        _buildSectionHeader(
          theme,
          icon: Icons.science_outlined,
          title: 'Drug Safety Profile',
          color: const Color(0xFF6366F1),
        ),
        const SizedBox(height: 12),
        _buildDrugSafetyCard(theme),

        const SizedBox(height: 20),
        const Divider(color: Color(0xFF334155), height: 1),
        const SizedBox(height: 20),

        // ── Verified Audit Trail ───────────────────────────────
        _buildSectionHeader(
          theme,
          icon: Icons.local_shipping_outlined,
          title: 'Verified Audit Trail',
          color: const Color(0xFF06B6D4),
        ),
        const SizedBox(height: 12),
        _loadingExtra
            ? _buildLoadingPlaceholder(56)
            : BatchJourneyWidget(history: _history),

        const SizedBox(height: 20),
        const Divider(color: Color(0xFF334155), height: 1),
        const SizedBox(height: 20),

        // ── Live Geospatial Route ──────────────────────────────
        _buildSectionHeader(
          theme,
          icon: Icons.map_outlined,
          title: 'Live Geospatial Route',
          color: const Color(0xFF4ADE80),
        ),
        const SizedBox(height: 12),
        _loadingExtra
            ? _buildLoadingPlaceholder(280)
            : ShipmentMapWidget(history: _history),

        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFFF1F5F9),
          ),
        ),
      ],
    );
  }

  Widget _buildDrugSafetyCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1e3a5f)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  size: 16, color: Color(0xFF4ADE80)),
              const SizedBox(width: 6),
              Text(
                'Manufacturer Verified Specifications',
                style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingExtra)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF6366F1)),
              ),
            )
          else ...[
            if (_batchDetails?.composition != null)
              _safetyRow('Composition', _batchDetails!.composition!, theme),
            if (_batchDetails?.strength != null)
              _safetyRow('Dosage / Strength', _batchDetails!.strength!, theme),
            _safetyRow(
              'Blockchain Synced',
              _batchDetails?.isBlockchainSynced == true
                  ? '✓ Confirmed on-chain'
                  : 'Database verified',
              theme,
            ),
            if (widget.result.details.drugName != null)
              _safetyRow('Drug Name', widget.result.details.drugName!, theme),
            if (widget.result.details.manufacturer != null)
              _safetyRow('Manufacturer', widget.result.details.manufacturer!, theme),
            if (_batchDetails?.composition == null &&
                _batchDetails?.strength == null)
              const Text(
                'Full composition data not available for this batch.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
          ],
        ],
      ),
    );
  }

  Widget _safetyRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF6366F1)),
            ),
            SizedBox(height: 10),
            Text('Loading supply chain data...',
                style:
                    TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onVerifyAgain,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Verify Again'),
          ),
        ),
        if (widget.result.details.batchId != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  _openBlockchainExplorer(widget.result.details.batchId!),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Explorer'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogsToggle(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: widget.onToggleLogs,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  widget.showLogs ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.showLogs
                      ? 'Hide technical logs'
                      : 'Show technical verification logs',
                  style: const TextStyle(
                      color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (widget.showLogs) ...[
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
              widget.result.logs.join('\n'),
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
    );
  }

  void _openBlockchainExplorer(String batchCode) async {
    const url =
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

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });
}
