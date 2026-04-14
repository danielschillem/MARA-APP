import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      icon: Icons.shield_rounded,
      gradientColors: [Color(0xFFC8143E), Color(0xFF8C0C2A)],
      title: 'Signalez en toute sécurité',
      subtitle:
          'Déclarez une violence en quelques secondes, de manière anonyme ou identifiée. Vos données sont chiffrées de bout en bout.',
      badge: 'CONFIDENTIEL',
      badgeColor: Color(0xFFB5103C),
    ),
    _Slide(
      icon: Icons.forum_rounded,
      gradientColors: [Color(0xFF1D61B0), Color(0xFF0D3B7A)],
      title: 'Un soutien humain immédiat',
      subtitle:
          'Tchattez en direct avec un conseiller qualifié. Pas de jugement, juste de l\'écoute et de l\'aide concrète.',
      badge: 'DISPONIBLE 24/7',
      badgeColor: Color(0xFF1D61B0),
    ),
    _Slide(
      icon: Icons.explore_rounded,
      gradientColors: [Color(0xFF2D6A4F), Color(0xFF1B4332)],
      title: 'Des ressources près de vous',
      subtitle:
          'Annuaire des ONG, services de santé, juridiques et de police. Guides et lois accessibles hors connexion.',
      badge: 'BURKINA FASO',
      badgeColor: Color(0xFF2D6A4F),
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/');
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    return Scaffold(
      body: Stack(
        children: [
          // Full page view
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _slides.length,
            itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _page == i ? 24 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _page == i
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // CTA button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: slide.gradientColors[0],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(
                          _page < _slides.length - 1
                              ? 'Suivant'
                              : 'Commencer',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    // Skip
                    if (_page < _slides.length - 1) ...[
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _finish,
                        child: Text(
                          'Passer',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.65),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide view ────────────────────────────────────────────────────────────────
class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            slide.gradientColors[0],
            slide.gradientColors[1],
            const Color(0xFF0D1117),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 160),
          child: Column(
            children: [
              // Decorative rings
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      Container(
                        width: h * 0.28,
                        height: h * 0.28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                      ),
                      // Middle ring
                      Container(
                        width: h * 0.22,
                        height: h * 0.22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      // Icon circle
                      Container(
                        width: h * 0.16,
                        height: h * 0.16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.1),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          slide.icon,
                          size: h * 0.06,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  slide.badge,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2),
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.25,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                slide.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Slide data model ──────────────────────────────────────────────────────────
class _Slide {
  final IconData icon;
  final List<Color> gradientColors;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;

  const _Slide({
    required this.icon,
    required this.gradientColors,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
  });
}
