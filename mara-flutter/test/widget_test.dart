import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mara_flutter/shared/widgets/app_button.dart';
import 'package:mara_flutter/shared/widgets/skeleton_loader.dart';
import 'package:mara_flutter/shared/widgets/error_banner.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();
    SharedPreferences.setMockInitialValues({});
  });

  group('AppButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(label: 'Tester', onPressed: () {}),
          ),
        ),
      );
      expect(find.text('Tester'), findsOneWidget);
    });

    testWidgets('shows spinner when isLoading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppButton(label: 'Chargement', isLoading: true),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Chargement'), findsNothing);
    });

    testWidgets('onPressed is called on tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(label: 'Appuyer', onPressed: () => tapped = true),
          ),
        ),
      );
      await tester.tap(find.text('Appuyer'));
      expect(tapped, isTrue);
    });

    testWidgets('button is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppButton(label: 'Désactivé', onPressed: null),
          ),
        ),
      );
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
    });
  });

  group('SkeletonLoader', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(height: 50),
          ),
        ),
      );
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('SkeletonCard renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonCard()),
        ),
      );
      expect(find.byType(SkeletonCard), findsOneWidget);
    });
  });

  group('ErrorBanner', () {
    testWidgets('displays message text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorBanner(message: 'Une erreur est survenue'),
          ),
        ),
      );
      expect(find.text('Une erreur est survenue'), findsOneWidget);
    });

    testWidgets('Réessayer button calls onRetry', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBanner(
              message: 'Erreur',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Réessayer'));
      expect(retried, isTrue);
    });

    testWidgets('no retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorBanner(message: 'Erreur sans retry'),
          ),
        ),
      );
      expect(find.text('Réessayer'), findsNothing);
    });
  });

  group('AppColors', () {
    test('primary color has expected value', () {
      expect(AppColors.primary.value, const Color(0xFFB5103C).value);
    });

    test('surface color is white', () {
      expect(AppColors.surface.value, const Color(0xFFFFFFFF).value);
    });
  });
}
