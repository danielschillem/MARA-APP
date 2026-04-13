import 'package:go_router/go_router.dart';
import 'package:mara_flutter/core/services/auth_service.dart';
import 'package:mara_flutter/features/auth/login_screen.dart';
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
    // /login is always accessible
    if (state.matchedLocation == '/login') return null;
    // /counselor and sub-routes require auth
    if (state.matchedLocation.startsWith('/counselor')) {
      if (!AuthService.instance.isLoggedIn) return '/login';
    }
    return null;
  },
  routes: [
    // Auth — outside shell (full-screen)
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

    // Main app shell
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
