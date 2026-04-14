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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D61B0), Color(0xFF1A2E4A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VeilleProtect · Urgence',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        letterSpacing: 0.2)),
                const Text('Êtes-vous en sécurité ?',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.title)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusDot(
                  on: _isOnline, label: _isOnline ? 'En ligne' : 'Hors-ligne'),
              const SizedBox(height: 4),
              const _StatusDot(
                  on: true, label: 'GPS actif', color: AppColors.info),
            ],
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ALERTE URGENTE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
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
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 10),
            child: Text(
              'ACTIONS RAPIDES',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.muted),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _QuickBtn(
                  label: 'Appel urgence',
                  sub: '17 · Police',
                  icon: Icons.phone_in_talk_rounded,
                  color: AppColors.successLight,
                  textColor: AppColors.success,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickBtn(
                  label: 'Soutien chat',
                  sub: 'Anonyme',
                  icon: Icons.forum_rounded,
                  color: AppColors.accentLight,
                  textColor: AppColors.accent,
                  onTap: () => context.go('/chat'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _QuickBtn(
                  label: 'Enregistrer audio',
                  sub: 'Preuve vocale',
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
                  sub: '*115#',
                  icon: Icons.dialpad_rounded,
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bgAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, size: 11, color: AppColors.muted),
            SizedBox(width: 6),
            Text(
              'Chiffré de bout en bout  ·  Anonymat garanti',
              style: TextStyle(
                  fontSize: 10, color: AppColors.muted, letterSpacing: 0.1),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status dot indicator ─────────────────────────────────────────────────────
class _StatusDot extends StatelessWidget {
  final bool on;
  final String label;
  final Color? color;
  const _StatusDot({required this.on, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? (on ? AppColors.success : AppColors.muted);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c)),
      ],
    );
  }
}

// ── Quick action button ───────────────────────────────────────────────────────
class _QuickBtn extends StatelessWidget {
  final String label;
  final String sub;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _QuickBtn({
    required this.label,
    required this.sub,
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
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: textColor.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: textColor, size: 16),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                        fontSize: 9, color: textColor.withValues(alpha: 0.7)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
