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
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadQueue,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hero
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cloud_off_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mode hors-ligne actif',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                              SizedBox(height: 2),
                              Text('Alertes sauvegardées localement',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Vos alertes seront synchronisées automatiquement dès le retour de la connexion.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.white70, height: 1.6),
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
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
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
                icon: _syncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_sync_rounded,
                        color: Colors.white, size: 18),
                label: Text(
                  _syncing ? 'Synchronisation…' : 'Synchroniser maintenant',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ],
          ),
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
        color: Colors.white.withValues(alpha: 0.15),
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.schedule_rounded,
                color: AppColors.warning, size: 24),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerte #$index · $typeId',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                ),
                const SizedBox(height: 3),
                Text(
                  '${zone.isNotEmpty ? zone : 'GPS'} · victime: $victimType',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                if (queuedAt.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    queuedAt.length >= 10
                        ? queuedAt.substring(0, 10)
                        : queuedAt,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.placeholder),
                  ),
                ],
              ],
            ),
          ),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'En attente',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
