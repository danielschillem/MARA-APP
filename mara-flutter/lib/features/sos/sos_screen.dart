import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';
import 'package:mara_flutter/core/services/api_service.dart';
import 'package:mara_flutter/core/services/offline_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with TickerProviderStateMixin {
  bool _pressing = false;
  double _pressProgress = 0.0;
  Timer? _pressTimer;
  bool _sent = false;
  String? _reference;
  bool _isOnline = true;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _checkConnectivity();
  }

  @override
  void dispose() {
    _pressTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() => _isOnline = !result.contains(ConnectivityResult.none));
  }

  void _startPress() {
    HapticFeedback.mediumImpact();
    setState(() {
      _pressing = true;
      _pressProgress = 0.0;
    });
    _pressTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      setState(() {
        _pressProgress += 30 / 2500;
        if (_pressProgress >= 1.0) {
          _pressProgress = 1.0;
          _pressTimer?.cancel();
          _triggerSOS();
        }
      });
    });
  }

  void _cancelPress() {
    _pressTimer?.cancel();
    setState(() {
      _pressing = false;
      _pressProgress = 0.0;
    });
  }

  Future<void> _triggerSOS() async {
    HapticFeedback.heavyImpact();
    setState(() => _pressing = false);

    Position? position;
    try {
      final permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      }
    } catch (_) {}

    final alert = {
      '_type': 'alert',
      'type_id': 'physical',
      'victim_type': 'unknown',
      'lat': position?.latitude ?? 0.0,
      'lng': position?.longitude ?? 0.0,
      'zone': '',
      'is_ongoing': true,
      'channel': 'app',
      'is_anonymous': true,
      'has_photo': false,
      'has_audio': false,
      'notes': 'Alerte SOS urgente',
    };

    final api = ApiService();
    final offline = OfflineService(api);

    if (_isOnline) {
      try {
        final res = await api.createAlert(alert);
        setState(() {
          _sent = true;
          _reference = res['reference'];
        });
      } catch (_) {
        await offline.enqueue(alert);
        setState(() {
          _sent = true;
          _reference = 'Sauvegardé hors-ligne';
        });
      }
    } else {
      await offline.enqueue(alert);
      setState(() {
        _sent = true;
        _reference = 'Sauvegardé hors-ligne';
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            // Scale SOS button relative to available height, clamped to safe range
            final sosSize = (h * 0.30).clamp(110.0, 190.0);
            return CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      _buildGreeting(),
                      if (!_isOnline) _buildOfflineBanner(),
                      Expanded(
                        child:
                            _sent ? _buildSentState() : _buildSosArea(sosSize),
                      ),
                      _buildQuickGrid(context),
                      _buildFooter(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header / Greeting ─────────────────────────────────────────────────────

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bonjour,',
                    style: TextStyle(fontSize: 13, color: AppColors.muted)),
                Text('Êtes-vous en sécurité ?',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.title)),
              ],
            ),
          ),
          // GPS badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 5),
                Text('GPS actif',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      color: AppColors.warning,
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Mode hors-ligne · alertes sauvegardées localement',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── SOS Button ────────────────────────────────────────────────────────────

  Widget _buildSosArea(double size) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ALERTE URGENTE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(height: size * 0.08),
          // Ring + button
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress arc
                SizedBox.expand(
                  child: CustomPaint(
                    painter: _ArcPainter(progress: _pressProgress),
                  ),
                ),
                // Pulse halo
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Container(
                    width: size * 0.84,
                    height: size * 0.84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: _pressing
                          ? []
                          : [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                    alpha:
                                        0.06 + 0.05 * _pulseController.value),
                                blurRadius: (12 + 16 * _pulseController.value),
                                spreadRadius: (8 + 12 * _pulseController.value),
                              ),
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                    alpha:
                                        0.03 + 0.02 * _pulseController.value),
                                blurRadius: (24 + 24 * _pulseController.value),
                                spreadRadius:
                                    (20 + 20 * _pulseController.value),
                              ),
                            ],
                    ),
                  ),
                ),
                // Press button
                GestureDetector(
                  onLongPressStart: (_) => _startPress(),
                  onLongPressEnd: (_) => _cancelPress(),
                  onLongPressCancel: _cancelPress,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: _pressing ? size * 0.7 : size * 0.8,
                    height: _pressing ? size * 0.7 : size * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFC8143E), Color(0xFF8C0C2A)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary
                              .withValues(alpha: _pressing ? 0.25 : 0.45),
                          blurRadius: _pressing ? 10 : 32,
                          offset: Offset(0, _pressing ? 3 : 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_rounded,
                            color: Colors.white, size: size * 0.15),
                        SizedBox(height: size * 0.02),
                        Text('SOS',
                            style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: size * 0.09,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: size * 0.07),
          // Instruction
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _pressing
                ? Text(
                    'Maintenez appuyé · ${((1 - _pressProgress) * 2.5).toStringAsFixed(1)}s',
                    key: const ValueKey('pressing'),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  )
                : Text(
                    'Maintenez appuyé 2,5 s pour déclencher',
                    key: const ValueKey('idle'),
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),
          ),
        ],
      ),
    );
  }

  // ── Sent state ────────────────────────────────────────────────────────────

  Widget _buildSentState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.success,
                    AppColors.success.withValues(alpha: 0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 38),
            ),
            const SizedBox(height: 20),
            const Text('Alerte envoyée !',
                style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success)),
            const SizedBox(height: 8),
            Text('Les coordinateurs ont été notifiés.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.sub)),
            if (_reference != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Référence',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted)),
                    Text(_reference!,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: AppColors.primary)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() {
                  _sent = false;
                  _reference = null;
                  _pressProgress = 0;
                }),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Nouvelle alerte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick actions grid ────────────────────────────────────────────────────

  Widget _buildQuickGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'ACTIONS RAPIDES',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.muted),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _QuickBtn(
                  label: 'Appel urgence',
                  icon: Icons.call_rounded,
                  color: AppColors.successLight,
                  textColor: AppColors.success,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickBtn(
                  label: 'Photo preuve',
                  icon: Icons.camera_alt_rounded,
                  color: AppColors.accentLight,
                  textColor: AppColors.accent,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _QuickBtn(
                  label: 'Audio',
                  icon: Icons.mic_rounded,
                  color: AppColors.purpleLight,
                  textColor: AppColors.purple,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickBtn(
                  label: 'SMS · USSD',
                  icon: Icons.smartphone_rounded,
                  color: AppColors.warningLight,
                  textColor: AppColors.warning,
                  onTap: () => context.go('/ussd'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 10, color: AppColors.placeholder),
          const SizedBox(width: 4),
          Text(
            'Chiffré de bout en bout · Anonymat garanti',
            style: TextStyle(fontSize: 10, color: AppColors.placeholder),
          ),
        ],
      ),
    );
  }
}

// ── Quick action button ───────────────────────────────────────────────────────
class _QuickBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _QuickBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Arc painter ───────────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double progress;
  _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    const strokeW = 5.0;

    // Track circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFEEDDE3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );
    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2,
        2 * 3.14159 * progress,
        false,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

