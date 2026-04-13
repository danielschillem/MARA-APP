import 'package:flutter/material.dart';
import 'package:mara_flutter/core/services/api_service.dart';
import 'package:mara_flutter/core/services/offline_service.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  List<Map<String, dynamic>> _queue = [];
  bool _syncing = false;
  double _syncProgress = 0.0;

  late final OfflineService _offline;

  @override
  void initState() {
    super.initState();
    _offline = OfflineService(ApiService());
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    final q = await _offline.getQueue();
    setState(() => _queue = q);
  }

  Future<void> _sync() async {
    setState(() {
      _syncing = true;
      _syncProgress = 0.0;
    });

    // Animate progress bar
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (mounted) setState(() => _syncProgress = i / 100.0);
    }

    final synced = await _offline.sync();

    if (mounted) {
      setState(() => _syncing = false);
      _loadQueue();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$synced alerte(s) synchronisée(s)'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4601A), Color(0xFFA04010)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white70, size: 28),
                      const SizedBox(width: 10),
                      const Text('Mode hors-ligne actif',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Playfair Display')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Vos alertes sont sauvegardées localement et seront synchronisées automatiquement dès le retour de la connexion.',
                    style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.6),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                            value: '${_queue.length}', label: 'En attente'),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: _StatBox(value: '0', label: 'Synchronisées'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('FILE D\'ATTENTE LOCALE',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.12,
                    color: AppColors.muted)),
            const SizedBox(height: 10),

            if (_queue.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Aucune alerte en attente',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted)),
              )
            else
              ..._queue.asMap().entries.map((e) => _QueueItem(
                    index: e.key + 1,
                    item: e.value,
                  )),

            if (_syncing) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _syncProgress,
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.green),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _syncing ? null : _sync,
              icon: const Icon(Icons.sync, color: Colors.white),
              label: Text(_syncing ? 'Synchronisation…' : 'Synchroniser maintenant',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFamily: 'Playfair Display')),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Colors.white70, letterSpacing: 0.06)),
        ],
      ),
    );
  }
}

class _QueueItem extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;
  const _QueueItem({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    final typeId = item['type_id'] ?? 'physical';
    final victimType = item['victim_type'] ?? 'inconnu';
    final zone = item['zone'] ?? '';
    final queuedAt = item['queued_at'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: AppColors.orangeLight,
                borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.warning_rounded,
                color: AppColors.orange, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$typeId · $victimType',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                Text(
                    '${zone.isNotEmpty ? zone : "GPS"} · ${queuedAt.substring(0, 10)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.orangeLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('En attente',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange)),
          ),
        ],
      ),
    );
  }
}
