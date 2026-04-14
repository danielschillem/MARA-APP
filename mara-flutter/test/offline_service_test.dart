import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mara_flutter/core/services/offline_service.dart';
import 'package:mara_flutter/core/services/api_service.dart';

void main() {
  group('OfflineService', () {
    late OfflineService svc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      svc = OfflineService(ApiService());
    });

    test('getQueue returns empty list initially', () async {
      final q = await svc.getQueue();
      expect(q, isEmpty);
    });

    test('enqueue persists item with queued_at timestamp', () async {
      await svc.enqueue({'_type': 'alert', 'type_id': 'physical'});
      final q = await svc.getQueue();
      expect(q.length, 1);
      expect(q.first['_type'], 'alert');
      expect(q.first.containsKey('queued_at'), isTrue);
    });

    test('enqueue multiple items accumulates them', () async {
      await svc.enqueue({'_type': 'alert', 'n': 1});
      await svc.enqueue({'_type': 'report', 'n': 2});
      final q = await svc.getQueue();
      expect(q.length, 2);
      expect(q[0]['n'], 1);
      expect(q[1]['n'], 2);
    });

    test('clear removes all queued items', () async {
      await svc.enqueue({'_type': 'alert'});
      await svc.clear();
      final q = await svc.getQueue();
      expect(q, isEmpty);
    });

    test('enqueue stores valid JSON', () async {
      final item = {'_type': 'alert', 'lat': 12.34, 'lng': -1.56};
      await svc.enqueue(item);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('offline_queue')!;
      final decoded = jsonDecode(raw.first) as Map<String, dynamic>;
      expect(decoded['_type'], 'alert');
      expect(decoded['lat'], 12.34);
    });
  });
}
