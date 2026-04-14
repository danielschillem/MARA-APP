import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';

// ── Navigation items ─────────────────────────────────────────────────────────
class _Tab {
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _Tab(this.path, this.label, this.icon, this.activeIcon);
}

const _tabs = [
  _Tab('/', 'Urgence', Icons.emergency_outlined, Icons.emergency_rounded),
  _Tab('/report', 'Signaler', Icons.description_outlined,
      Icons.description_rounded),
  _Tab('/chat', 'Soutien', Icons.forum_outlined, Icons.forum_rounded),
  _Tab('/map', 'Carte', Icons.location_on_outlined, Icons.location_on_rounded),
  _Tab('/offline', 'Hors-ligne', Icons.cloud_off_rounded,
      Icons.cloud_off_rounded),
  _Tab('/ussd', 'USSD', Icons.dialpad_outlined, Icons.dialpad_rounded),
];

// ── Shell ─────────────────────────────────────────────────────────────────────
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int idx = _tabs.indexWhere((t) => t.path == location);
    if (idx < 0) idx = 0;

    final w = MediaQuery.of(context).size.width;
    if (w >= 720) return _WideLayout(child: child, selectedIndex: idx);
    return _NarrowLayout(child: child, selectedIndex: idx);
  }
}

// ── Narrow layout (phones) ───────────────────────────────────────────────────
class _NarrowLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  const _NarrowLayout({required this.child, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _AppHeader(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: _BottomNav(selectedIndex: selectedIndex),
    );
  }
}

// ── Wide layout (tablet / web) ────────────────────────────────────────────────
class _WideLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  const _WideLayout({required this.child, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _SideRail(selectedIndex: selectedIndex),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// ── Header bar ────────────────────────────────────────────────────────────────
class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.borderLight, width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFC8143E), Color(0xFF8C0C2A)],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x30B5103C),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'VEILLE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextSpan(
                      text: 'PROTECT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.bgAlt,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'CITOYEN',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.muted,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onPressed: () {},
                color: AppColors.sub,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  const _BottomNav({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.nav,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: _tabs.asMap().entries.map((e) {
              return Expanded(
                child: _NavItem(
                  tab: e.value,
                  isActive: selectedIndex == e.key,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Individual nav item ───────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final _Tab tab;
  final bool isActive;
  const _NavItem({required this.tab, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(tab.path),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primarySurface : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isActive ? tab.activeIcon : tab.icon,
              size: 20,
              color: isActive ? AppColors.primary : AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.muted,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Side rail (tablets & web) ─────────────────────────────────────────────────
class _SideRail extends StatelessWidget {
  final int selectedIndex;
  const _SideRail({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFC8143E), Color(0xFF8C0C2A)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x28B5103C), blurRadius: 10),
              ],
            ),
            child:
                const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 24),
          const Divider(indent: 12, endIndent: 12),
          const SizedBox(height: 8),
          ..._tabs.asMap().entries.map((e) {
            final i = e.key;
            final tab = e.value;
            final active = selectedIndex == i;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Tooltip(
                message: tab.label,
                preferBelow: false,
                child: GestureDetector(
                  onTap: () => context.go(tab.path),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primarySurface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      active ? tab.activeIcon : tab.icon,
                      size: 22,
                      color: active ? AppColors.primary : AppColors.muted,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
