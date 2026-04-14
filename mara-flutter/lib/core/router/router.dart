import 'package:go_router/go_router.dart';
import 'package:mara_flutter/core/services/auth_service.dart';
import 'package:mara_flutter/features/auth/login_screen.dart';
import 'package:mara_flutter/features/auth/register_screen.dart';
import 'package:mara_flutter/features/chat/chat_screen.dart';
import 'package:mara_flutter/features/sos/sos_screen.dart';
import 'package:mara_flutter/features/report/report_screen.dart';
import 'package:mara_flutter/features/map/map_screen.dart';
import 'package:mara_flutter/features/offline/offline_screen.dart';
import 'package:mara_flutter/features/ussd/ussd_screen.dart';
import 'package:mara_flutter/app_shell.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    if (state.matchedLocation == '/login') return null;
    if (state.matchedLocation == '/register') return null;
    if (state.matchedLocation.startsWith('/counselor')) {
      if (!AuthService.instance.isLoggedIn) return '/login';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SosScreen()),
        GoRoute(path: '/report', builder: (_, __) => const ReportScreen()),
        GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
        GoRoute(path: '/offline', builder: (_, __) => const OfflineScreen()),
        GoRoute(path: '/ussd', builder: (_, __) => const UssdScreen()),
        GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
      ],
    ),
  ],
);
