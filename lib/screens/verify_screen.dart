import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../config/constants.dart';
import '../models/verification_result.dart';
import '../services/blockchain_service.dart';
import '../services/supabase_service.dart';
import '../services/scan_history_service.dart';
import '../widgets/verification_result_card.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────
  final _batchCodeController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isScanning = false;
  bool _isVerifying = false;
  bool _showLogs = false;
  VerificationResult? _result;

  MobileScannerController? _scannerController;
  List<Map<String, dynamic>>? _cachedBatches;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _prefetchBatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _batchCodeController.dispose();
    _scrollController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _prefetchBatches() async {
    try {
      _cachedBatches = await SupabaseService().fetchAllBatches();
    } catch (_) {}
  }

  // ── Scanner ─────────────────────────────────────────────────────────

  void _startScanner() {
    setState(() {
      _isScanning = true;
      _result = null;
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    });
  }

  void _stopScanner() {
    _scannerController?.dispose();
    setState(() {
      _isScanning = false;
      _scannerController = null;
    });
  }

  void _onQRDetected(BarcodeCapture capture) {
    if (!_isScanning || _isVerifying) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    _stopScanner();
    _verify(barcode!.rawValue!);
  }

  // ── Verification ─────────────────────────────────────────────────────

  Future<void> _verify([String? rawData]) async {
    final data = (rawData ?? _batchCodeController.text).trim();
    if (data.isEmpty) {
      _showSnack('Please enter a batch code or scan a QR code.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _result = null;
    });

    try {
      final result = await BlockchainService().verifyBatch(
        data,
        localBatches: _cachedBatches,
      );

      setState(() => _result = result);

      // Save to history
      await ScanHistoryService().saveResult(result);

      // Scroll to result
      await Future.delayed(const Duration(milliseconds: 200));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      setState(() => _result = VerificationResult(
            isAuthentic: false,
            status: VerificationStatus.notFound,
            message: 'Verification failed: ${e.toString()}',
            details: const VerificationDetails(),
            logs: [],
            verifiedAt: DateTime.now(),
          ));
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _reset() {
    setState(() {
      _result = null;
      _batchCodeController.clear();
      _showLogs = false;
    });
  }

  // ── UI ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined,
                  size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(AppConstants.appName,
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          // Blockchain status indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(Icons.link, size: 14, color: Color(0xFF4ADE80)),
              label: Text(AppConstants.chainName,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF4ADE80))),
              backgroundColor: const Color(0xFF052e16),
              side: const BorderSide(color: Color(0xFF166534)),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(theme),
            const SizedBox(height: 20),
            _buildScannerCard(theme),
            if (_result != null) ...[
              const SizedBox(height: 16),
              VerificationResultCard(
                result: _result!,
                showLogs: _showLogs,
                onToggleLogs: () =>
                    setState(() => _showLogs = !_showLogs),
                onVerifyAgain: _reset,
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Medicine\nAuthenticity',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Scan the QR code on your medicine package or enter the batch code '
          'to verify authenticity using blockchain technology.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildScannerCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab switcher
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.colorScheme.primary,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 16),
                        SizedBox(width: 6),
                        Text('Scan QR'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.keyboard, size: 16),
                        SizedBox(width: 6),
                        Text('Manual'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 320,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCameraTab(theme),
                  _buildManualTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Camera tab ──────────────────────────────────────────────────────
  // mobile_scanner 5.x has no 'overlay' param — use Stack to draw viewfinder.

  Widget _buildCameraTab(ThemeData theme) {
    if (_isScanning) {
      return Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _scannerController!,
                    onDetect: _onQRDetected,
                  ),
                  // Viewfinder frame drawn on top via Stack
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: theme.colorScheme.primary, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _stopScanner,
              child: const Text('Stop Scanner'),
            ),
          ),
        ],
      );
    }

    // Not scanning — show prompt to start camera
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.qr_code_scanner,
              size: 40, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 16),
        Text(
          'Point your camera at the QR code',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: const Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _isVerifying ? null : _startScanner,
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Start Camera'),
        ),
      ],
    );
  }

  // ── Manual entry tab ─────────────────────────────────────────────────

  Widget _buildManualTab(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.search_outlined,
              size: 40, color: theme.colorScheme.secondary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _batchCodeController,
          enabled: !_isVerifying,
          decoration: const InputDecoration(
            hintText: 'Enter Batch Code (e.g., BCH-001)',
            prefixIcon: Icon(Icons.qr_code_2_outlined),
          ),
          textCapitalization: TextCapitalization.characters,
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isVerifying ? null : () => _verify(),
          icon: _isVerifying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.shield_outlined),
          label: Text(_isVerifying ? 'Verifying...' : 'Verify Batch'),
        ),
      ],
    );
  }
}

