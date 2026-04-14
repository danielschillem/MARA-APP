import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mara_flutter/core/services/auth_service.dart';

void main() {
  group('AuthService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // Hive needs flutter binding in unit tests
      TestWidgetsFlutterBinding.ensureInitialized();
      await Hive.initFlutter();
      // Reset singleton
      // ignore: invalid_use_of_visible_for_testing_member
    });

    test('isLoggedIn is false when no token stored', () async {
      final auth = await AuthService.init();
      expect(auth.isLoggedIn, isFalse);
    });

    test('currentUser is null when no user stored', () async {
      final auth = await AuthService.init();
      expect(auth.currentUser, isNull);
    });

    test('logout clears all auth data', () async {
      final auth = await AuthService.init();
      await auth.logout();
      expect(auth.isLoggedIn, isFalse);
      expect(auth.currentUser, isNull);
    });
  });
}
