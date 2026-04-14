import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'api_service.dart';

/// Singleton auth service — persists JWT + user in Hive.
class AuthService {
  static const _boxName = 'mara_auth';
  static const _tokenKey = 'jwt_token';
  static const _userKey = 'user_data';

  static AuthService? _instance;
  static AuthService get instance => _instance!;

  late final Box _box;
  final ApiService _api = ApiService();

  AuthService._();

  static Future<AuthService> init() async {
    if (_instance != null) return _instance!;
    _instance = AuthService._();
    _instance!._box = await Hive.openBox(_boxName);
    return _instance!;
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  String? get token => _box.get(_tokenKey) as String?;

  Map<String, dynamic>? get currentUser {
    final raw = _box.get(_userKey) as String?;
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  bool get isLoggedIn => token != null;

  // ── Auth actions ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _api.login(email, password);
    final jwt = data['token'] as String?;
    final refreshTok = data['refresh_token'] as String?;
    final user = data['user'] as Map<String, dynamic>?;
    if (jwt == null) throw Exception('No token received');
    await _box.put(_tokenKey, jwt);
    if (refreshTok != null) await _box.put('refresh_token', refreshTok);
    if (user != null) await _box.put(_userKey, jsonEncode(user));
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data =
        await _api.register(name: name, email: email, password: password);
    final jwt = data['token'] as String?;
    final refreshTok = data['refresh_token'] as String?;
    final user = data['user'] as Map<String, dynamic>?;
    if (jwt == null) throw Exception('No token received');
    await _box.put(_tokenKey, jwt);
    if (refreshTok != null) await _box.put('refresh_token', refreshTok);
    if (user != null) await _box.put(_userKey, jsonEncode(user));
    return data;
  }

  Future<void> refreshToken() async {
    final refresh = _box.get('refresh_token') as String?;
    if (refresh == null) throw Exception('No refresh token');
    final data = await _api.refreshToken(refresh);
    final jwt = data['token'] as String?;
    final newRefresh = data['refresh_token'] as String?;
    if (jwt != null) await _box.put(_tokenKey, jwt);
    if (newRefresh != null) await _box.put('refresh_token', newRefresh);
  }

  Future<void> logout() async {
    await _box.deleteAll([_tokenKey, _userKey, 'refresh_token']);
  }
}
