import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    ('/', 'SOS', Icons.warning_rounded),
    ('/report', 'Signaler', Icons.edit_note),
    ('/chat', 'Discuter', Icons.chat_bubble_outline_rounded),
    ('/map', 'Carte', Icons.map_outlined),
    ('/offline', 'Hors-ligne', Icons.wifi_off_outlined),
    ('/ussd', 'SMS·USSD', Icons.smartphone),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int selectedIndex = _tabs.indexWhere((t) => t.$1 == location);
    if (selectedIndex < 0) selectedIndex = 0;

    return Scaffold(
      body: Stack(
        children: [
          child,
          // Status bar area - role logo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: _buildRoleBar(context),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: _tabs.asMap().entries.map((e) {
              final i = e.key;
              final tab = e.value;
              final active = selectedIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.go(tab.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Notification dot for offline tab
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Icon(
                              tab.$3,
                              size: 22,
                              color: active ? AppColors.red : AppColors.muted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.$2,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.06,
                            color: active ? AppColors.red : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      color: AppColors.bg,
      child: Row(
        children: [
          const Text('VEILLE',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.red,
                  letterSpacing: 0.1,
                  fontFamily: 'Playfair Display')),
          const Text('PROTECT',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: 0.1,
                  fontFamily: 'Playfair Display')),
          const SizedBox(width: 6),
          const Text('CITOYEN',
              style: TextStyle(
                  fontSize: 9, letterSpacing: 0.16, color: AppColors.muted)),
        ],
      ),
    );
  }
}
