import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mara_flutter/core/router/router.dart';
import 'package:mara_flutter/core/services/auth_service.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';

Future<bool> _isOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_done') ?? false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await AuthService.init();
  final onboardingDone = await _isOnboardingDone();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(MaraApp(showOnboarding: !onboardingDone));
}

class MaraApp extends StatelessWidget {
  final bool showOnboarding;
  const MaraApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MARA – VeilleProtect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: buildRouter(showOnboarding: showOnboarding),
    );
  }
}
