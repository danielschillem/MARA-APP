import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';
import 'package:mara_flutter/core/services/api_service.dart';
import 'package:mara_flutter/core/services/offline_service.dart';
import 'package:mara_flutter/shared/models/alert_model.dart';
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
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  void _startPress() {
    HapticFeedback.mediumImpact();
    setState(() {
      _pressing = true;
      _pressProgress = 0.0;
    });

    _pressTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      setState(() {
        _pressProgress += 30 / 2500; // 2.5s hold
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

    // Get location
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_isOnline) _buildOfflineBanner(),
            Expanded(
              child: _sent ? _buildSentState() : _buildSosButton(),
            ),
            _buildQuickActions(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bonjour,',
                  style: TextStyle(fontSize: 13, color: AppColors.muted)),
              Text('Êtes-vous en sécurité ?',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
            ],
          ),
          _buildLocationBadge(),
        ],
      ),
    );
  }

  Widget _buildLocationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.green),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 5),
          Text('GPS actif',
              style: TextStyle(fontSize: 11, color: AppColors.green)),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.orange,
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Text('Mode hors-ligne — alertes sauvegardées localement',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSosButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('ALERTE URGENTE',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.14,
                color: AppColors.red)),
        const SizedBox(height: 16),

        // SOS ring + button
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress arc
              SizedBox.expand(
                child: CustomPaint(
                  painter: _ArcPainter(progress: _pressProgress),
                ),
              ),
              // Halo
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 168,
                  height: 168,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: _pressing
                        ? []
                        : [
                            BoxShadow(
                              color: AppColors.red.withOpacity(
                                  0.06 + 0.04 * _pulseController.value),
                              blurRadius: 14 + 14 * _pulseController.value,
                              spreadRadius: 14 + 14 * _pulseController.value,
                            ),
                            BoxShadow(
                              color: AppColors.red.withOpacity(
                                  0.03 + 0.02 * _pulseController.value),
                              blurRadius: 28 + 28 * _pulseController.value,
                              spreadRadius: 28 + 28 * _pulseController.value,
                            ),
                          ],
                  ),
                ),
              ),
              // Button
              GestureDetector(
                onLongPressStart: (_) => _startPress(),
                onLongPressEnd: (_) => _cancelPress(),
                onLongPressCancel: _cancelPress,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: _pressing ? 110 : 128,
                  height: _pressing ? 110 : 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFC8143E), Color(0xFF8C0C2A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.red.withOpacity(_pressing ? 0.3 : 0.4),
                        blurRadius: _pressing ? 14 : 36,
                        offset: Offset(0, _pressing ? 4 : 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_rounded, color: Colors.white, size: 28),
                      const SizedBox(height: 4),
                      const Text('SOS',
                          style: TextStyle(
                              fontFamily: 'Playfair Display',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        AnimatedOpacity(
          opacity: _pressing ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            'Maintenez appuyé — ${(( 1 - _pressProgress) * 2.5).toStringAsFixed(1)}s',
            style: const TextStyle(fontSize: 12, color: AppColors.red),
          ),
        ),
        if (!_pressing)
          const Text(
            'Maintenez appuyé 2,5 secondes pour déclencher',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildSentState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: AppColors.greenLight),
          child: const Icon(Icons.check_rounded, color: AppColors.green, size: 36),
        ),
        const SizedBox(height: 16),
        const Text('Alerte envoyée',
            style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.green)),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text('Les coordinateurs ont été notifiés',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.sub)),
        ),
        if (_reference != null) ...[
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F0),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Référence',
                    style: TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: 0.06)),
                Text(_reference!,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        color: AppColors.ink)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton(
            onPressed: () => setState(() {
              _sent = false;
              _reference = null;
              _pressProgress = 0;
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Retour à l\'accueil', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actions rapides',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12,
                  color: AppColors.muted)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: [
              _QuickBtn(
                label: 'Appel\nd\'urgence',
                color: AppColors.greenLight,
                textColor: AppColors.green,
                icon: Icons.call,
                onTap: () {},
              ),
              _QuickBtn(
                label: 'Capturer\nune preuve',
                color: AppColors.navyLight,
                textColor: AppColors.navy,
                icon: Icons.camera_alt,
                onTap: () {},
              ),
              _QuickBtn(
                label: 'Enregistrer\naudio',
                color: AppColors.purpleLight,
                textColor: AppColors.purple,
                icon: Icons.mic,
                onTap: () {},
              ),
              _QuickBtn(
                label: 'SMS · USSD\nsans internet',
                color: AppColors.amberLight,
                textColor: AppColors.amber,
                icon: Icons.smartphone,
                onTap: () => context.go('/ussd'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 11, color: Color(0xFFCCCCCC)),
          const SizedBox(width: 4),
          Text('Signalement chiffré · Anonymat disponible',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

// ── Quick action button ────────────────────────────────────────────────────────

class _QuickBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickBtn({
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Arc painter for press progress ────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final double progress;

  _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFF0D4DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    // Arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2,
        2 * 3.14159 * progress,
        false,
        Paint()
          ..color = AppColors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
