import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/batch.dart';

/// Renders the live geospatial shipment route using OpenStreetMap tiles.
/// Mirrors the web app's ShipmentMap / DashboardMap component.
class ShipmentMapWidget extends StatelessWidget {
  final List<BatchHistoryEntry> history;

  const ShipmentMapWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final validEntries = history
        .where((e) => e.latitude != null && e.longitude != null)
        .toList();

    if (validEntries.isEmpty) {
      return _buildNoGpsState();
    }

    final validPoints =
        validEntries.map((e) => LatLng(e.latitude!, e.longitude!)).toList();

    final MapOptions mapOptions;
    if (validPoints.length == 1) {
      mapOptions = MapOptions(
        initialCenter: validPoints.first,
        initialZoom: 11.0,
      );
    } else {
      mapOptions = MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: validPoints,
          padding: const EdgeInsets.all(48),
          maxZoom: 12.0,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 280,
        child: FlutterMap(
          options: mapOptions,
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.meditrust.patient',
            ),
            if (validPoints.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: validPoints,
                    color: const Color(0xFF6366F1),
                    strokeWidth: 3.5,
                  ),
                ],
              ),
            MarkerLayer(
              markers: validEntries.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final isLast = i == validEntries.length - 1;
                return Marker(
                  point: LatLng(e.latitude!, e.longitude!),
                  width: isLast ? 44 : 28,
                  height: isLast ? 44 : 28,
                  child: _buildMarker(e.status, isLast),
                );
              }).toList(),
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => launchUrl(
                    Uri.parse('https://openstreetmap.org/copyright'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarker(String status, bool isLast) {
    final color = _statusColor(status);
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: isLast ? 3 : 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: isLast
          ? const Icon(Icons.local_shipping, size: 22, color: Colors.white)
          : null,
    );
  }

  Widget _buildNoGpsState() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                color: Color(0xFF64748B), size: 28),
            SizedBox(height: 6),
            Text(
              'No GPS coordinates recorded for this shipment',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('approved')) return const Color(0xFF22C55E);
    if (s.contains('transit')) return const Color(0xFF06B6D4);
    if (s.contains('pharmacy')) return const Color(0xFF8B5CF6);
    if (s.contains('sold')) return const Color(0xFF4ADE80);
    if (s.contains('recall')) return const Color(0xFFF87171);
    return const Color(0xFF6366F1);
  }
}
