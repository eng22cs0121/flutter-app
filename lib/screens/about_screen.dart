import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Logo + Title ───────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.shield_outlined,
                        size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Patient Verification App v${AppConstants.appVersion}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.appTagline,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: const Color(0xFF94A3B8)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── How it works ───────────────────────────────────────
            Text('How It Works',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _HowStep(
              step: 1,
              icon: Icons.qr_code_scanner,
              title: 'Scan or Enter',
              description:
                  'Scan the QR code on your medicine package or manually enter the batch code.',
              color: const Color(0xFF6366F1),
            ),
            _HowStep(
              step: 2,
              icon: Icons.link,
              title: 'Blockchain Check',
              description:
                  'The app queries the Ethereum blockchain to verify the batch\'s authenticity and integrity.',
              color: const Color(0xFF8B5CF6),
            ),
            _HowStep(
              step: 3,
              icon: Icons.verified_outlined,
              title: 'Instant Result',
              description:
                  'Get an immediate GENUINE, EXPIRED, TAMPERED or RECALLED status with full batch details.',
              color: const Color(0xFF06B6D4),
            ),

            const SizedBox(height: 24),

            // ── Verification statuses ─────────────────────────────
            Text('Verification Statuses',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _StatusExplanation(
              status: 'GENUINE',
              color: const Color(0xFF4ADE80),
              description:
                  'Medicine is authentic and verified on the blockchain.',
            ),
            _StatusExplanation(
              status: 'TAMPERED',
              color: const Color(0xFFF87171),
              description:
                  'QR code data does not match blockchain records. Do not use!',
            ),
            _StatusExplanation(
              status: 'EXPIRED',
              color: const Color(0xFFFBBF24),
              description: 'Medicine is past its expiry date.',
            ),
            _StatusExplanation(
              status: 'RECALLED',
              color: const Color(0xFFF87171),
              description:
                  'Batch has been recalled by regulators. Do not use!',
            ),
            _StatusExplanation(
              status: 'NOT APPROVED',
              color: const Color(0xFFFBBF24),
              description:
                  'Batch has not yet been approved by regulatory authorities.',
            ),
            _StatusExplanation(
              status: 'NOT FOUND',
              color: const Color(0xFF94A3B8),
              description:
                  'Batch code not found. Check the code or contact your pharmacy.',
            ),

            const SizedBox(height: 24),

            // ── Blockchain info ───────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.link,
                          size: 18, color: Color(0xFF4ADE80)),
                      const SizedBox(width: 8),
                      Text('Blockchain Network',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 12),
                    _InfoRow(
                        label: 'Network',
                        value: AppConstants.chainName),
                    _InfoRow(
                        label: 'Contract',
                        value:
                            '${AppConstants.contractAddress.substring(0, 10)}...${AppConstants.contractAddress.substring(AppConstants.contractAddress.length - 8)}'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _launchUrl(
                          '${AppConstants.blockExplorerUrl}/address/${AppConstants.contractAddress}',
                        ),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('View on Etherscan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Privacy ───────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.lock_outline,
                          size: 18, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      Text('Privacy',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      'This app only reads batch data from the blockchain and Supabase. '
                      'No personal data is collected. Scan history is stored locally '
                      'on your device only and never uploaded.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _HowStep extends StatelessWidget {
  final int step;
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _HowStep({
    required this.step,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusExplanation extends StatelessWidget {
  final String status;
  final Color color;
  final String description;

  const _StatusExplanation({
    required this.status,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(status,
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: const Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }
}
