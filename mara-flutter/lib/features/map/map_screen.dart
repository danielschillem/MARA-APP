import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mara_flutter/core/services/api_service.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';
import 'package:mara_flutter/shared/widgets/error_banner.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<dynamic> _alerts = [];
  String _filter = 'all';
  bool _loading = true;
  bool _error = false;
  final _mapController = MapController();
  LatLng? _userPosition;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
    _centerOnUser();
  }

  Future<void> _centerOnUser() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.medium));
      setState(() => _userPosition = LatLng(pos.latitude, pos.longitude));
      _mapController.move(_userPosition!, 13.0);
    } catch (_) {/* use default center */}
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final api = ApiService();
      final data = await api.getMapAlerts();
      setState(() {
        _alerts = data;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return AppColors.red;
      case 'high':
        return AppColors.orange;
      case 'medium':
        return AppColors.amber;
      default:
        return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(5.36, -4.00), // Abidjan default
              initialZoom: 11.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'bf.mara.flutter',
              ),
              if (_userPosition != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _userPosition!,
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 10)
                        ],
                      ),
                    ),
                  ),
                ]),
              if (!_loading)
                MarkerLayer(
                  markers: _alerts
                      .where((a) {
                        if (_filter == 'all') return true;
                        return a['severity'] == _filter ||
                            a['type_id'] == _filter;
                      })
                      .map((a) => Marker(
                            point: LatLng(
                              (a['lat'] ?? 5.36).toDouble(),
                              (a['lng'] ?? -4.00).toDouble(),
                            ),
                            width: 32,
                            height: 32,
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    _severityColor(a['severity'] ?? 'medium'),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _severityColor(
                                            a['severity'] ?? 'medium')
                                        .withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.warning_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ))
                      .toList(),
                ),
            ],
          ),

          // Legend
          Positioned(
            top: 60,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Niveau de risque',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  const SizedBox(height: 8),
                  _LegendRow(color: AppColors.red, label: 'Critique'),
                  _LegendRow(color: AppColors.orange, label: 'Élevé'),
                  _LegendRow(color: AppColors.amber, label: 'Modéré'),
                  _LegendRow(color: AppColors.green, label: 'Faible'),
                ],
              ),
            ),
          ),

          // Filter bar
          Positioned(
            bottom: 20,
            left: 12,
            right: 12,
            child: Container(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                      label: 'Toutes',
                      active: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all')),
                  _FilterChip(
                      label: 'Police',
                      active: _filter == 'police',
                      onTap: () => setState(() => _filter = 'police')),
                  _FilterChip(
                      label: 'Hôpitaux',
                      active: _filter == 'health',
                      onTap: () => setState(() => _filter = 'health')),
                  _FilterChip(
                      label: 'Refuges',
                      active: _filter == 'refuge',
                      onTap: () => setState(() => _filter = 'refuge')),
                  _FilterChip(
                      label: 'Critiques',
                      active: _filter == 'critical',
                      onTap: () => setState(() => _filter = 'critical')),
                ],
              ),
            ),
          ),

          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ErrorBanner(
                message: 'Impossible de charger les alertes.',
                onRetry: _loadAlerts,
              ),
            ),
          // Refresh button
          Positioned(
            top: 12,
            left: 12,
            child: GestureDetector(
              onTap: _loadAlerts,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.sm,
                ),
                child: const Icon(Icons.refresh_rounded,
                    size: 20, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.sub)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
          ],
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.ink)),
      ),
    );
  }
}
