import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Stores pending alerts/reports locally when offline, syncs when online.
class OfflineService {
  static const _queueKey = 'offline_queue';

  final ApiService _api;

  OfflineService(this._api);

  Future<List<Map<String, dynamic>>> getQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_queueKey) ?? [];
    return raw.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  Future<void> enqueue(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];
    item['queued_at'] = DateTime.now().toIso8601String();
    queue.add(jsonEncode(item));
    await prefs.setStringList(_queueKey, queue);
  }

  Future<int> sync() async {
    final queue = await getQueue();
    if (queue.isEmpty) return 0;

    int synced = 0;
    final failed = <String>[];
    final prefs = await SharedPreferences.getInstance();

    for (final item in queue) {
      try {
        if (item['_type'] == 'alert') {
          await _api.createAlert(item);
        } else {
          await _api.createReport(item);
        }
        synced++;
      } catch (_) {
        failed.add(jsonEncode(item));
      }
    }

    await prefs.setStringList(_queueKey, failed);
    return synced;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }
}
