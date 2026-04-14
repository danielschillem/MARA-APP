import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

// URL resolved at compile time via --dart-define=API_URL=https://api.mara.bf
// Fallbacks: web/iOS → localhost, Android emulator → 10.0.2.2
const _kApiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8081/api',
);

class ApiService {
  static const String _baseUrl = _kApiUrl;

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final box = Hive.box('mara_auth');
          final token = box.get('jwt_token') as String?;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {/* Hive not yet open */}
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res =
        await _dio.post('/login', data: {'email': email, 'password': password});
    return res.data;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'role': 'conseiller',
    });
    return res.data;
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final res = await _dio
        .post('/refresh-token', data: {'refresh_token': refreshToken});
    return res.data;
  }

  // ── Alerts (VeilleProtect) ────────────────────────────────────────────────
  Future<Map<String, dynamic>> createAlert(Map<String, dynamic> alert) async {
    final res = await _dio.post('/alerts', data: alert);
    return res.data;
  }

  Future<List<dynamic>> getMapAlerts() async {
    final res = await _dio.get('/alerts/map');
    return res.data;
  }

  // ── Reports ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createReport(Map<String, dynamic> report) async {
    final res = await _dio.post('/reports', data: report);
    return res.data;
  }

  Future<Map<String, dynamic>> createReportWithMedia(
    Map<String, dynamic> fields, {
    String? imagePath,
    String? audioPath,
  }) async {
    final formData = FormData.fromMap({
      ...fields,
      if (imagePath != null)
        'photo': await MultipartFile.fromFile(imagePath, filename: 'photo.jpg'),
      if (audioPath != null)
        'voice_note': await MultipartFile.fromFile(audioPath,
            filename: 'voice_note.webm'),
    });
    final res = await _dio.post('/reports', data: formData);
    return res.data;
  }

  Future<Map<String, dynamic>> trackReport(String reference) async {
    final res = await _dio.get('/reports/track/$reference');
    return res.data;
  }

  // ── Directory ─────────────────────────────────────────────────────────────
  Future<List<dynamic>> getSosNumbers() async {
    final res = await _dio.get('/sos-numbers');
    return res.data;
  }

  Future<List<dynamic>> getServices({String? type, String? region}) async {
    final res = await _dio.get('/services', queryParameters: {
      if (type != null) 'type': type,
      if (region != null) 'region': region,
    });
    return res.data;
  }

  Future<List<dynamic>> getViolenceTypes() async {
    final res = await _dio.get('/violence-types');
    return res.data;
  }

  // ── Resources ─────────────────────────────────────────────────────────────
  Future<List<dynamic>> getResources({String? category}) async {
    final res = await _dio.get('/resources', queryParameters: {
      if (category != null && category != 'all') 'category': category,
    });
    return res.data is List ? res.data : (res.data['data'] ?? []);
  }

  Future<Map<String, dynamic>> getResource(int id) async {
    final res = await _dio.get('/resources/$id');
    return res.data is Map<String, dynamic> ? res.data : {};
  }

  // ── Announcements ─────────────────────────────────────────────────────────
  Future<List<dynamic>> getAnnouncements() async {
    final res = await _dio.get('/announcements');
    return res.data is List ? res.data : (res.data['data'] ?? []);
  }

  // ── Profile ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/me');
    return res.data is Map<String, dynamic> ? res.data : {};
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _dio.get('/dashboard');
    return res.data is Map<String, dynamic> ? res.data : {};
  }

  Future<List<dynamic>> getReports({
    String? status,
    String? region,
    String? priority,
  }) async {
    final res = await _dio.get('/reports', queryParameters: {
      if (status != null) 'status': status,
      if (region != null) 'region': region,
      if (priority != null) 'priority': priority,
    });
    return res.data is List ? res.data : (res.data['data'] ?? []);
  }

  Future<Map<String, dynamic>> getReport(int id) async {
    final res = await _dio.get('/reports/$id');
    return res.data is Map<String, dynamic> ? res.data : {};
  }

  Future<Map<String, dynamic>> updateReport(
      int id, Map<String, dynamic> data) async {
    final res = await _dio.put('/reports/$id', data: data);
    return res.data is Map<String, dynamic> ? res.data : {};
  }

  Future<List<dynamic>> getConversations() async {
    final res = await _dio.get('/conversations');
    return res.data is List ? res.data : (res.data['data'] ?? []);
  }

  Future<void> closeConversation(int convId) async {
    await _dio.post('/conversations/$convId/close');
  }

  // ── Observatory ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getObservatoryStats() async {
    final res = await _dio.get('/observatory/stats');
    return res.data is Map<String, dynamic> ? res.data : {};
  }

  Future<Map<String, dynamic>> getObservatoryReports({
    String? country,
    int page = 1,
  }) async {
    final res = await _dio.get('/observatory/reports', queryParameters: {
      'page': page,
      if (country != null && country != 'all') 'country': country,
    });
    return res.data is Map<String, dynamic> ? res.data : {};
  }

  // ── Conversations ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> startAnonymousChat() async {
    final res = await _dio.post('/conversations/anonymous');
    return res.data;
  }

  Future<List<dynamic>> getMessages(int convId) async {
    final res = await _dio.get('/conversations/$convId/messages');
    return res.data is List ? res.data : (res.data['data'] ?? []);
  }

  Future<void> sendMessage(int convId, String body, String token) async {
    await _dio.post('/conversations/$convId/messages', data: {
      'body': body,
      'is_from_visitor': true,
      'token': token,
    });
  }
}
