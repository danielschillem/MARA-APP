import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';

class UssdScreen extends StatefulWidget {
  const UssdScreen({super.key});

  @override
  State<UssdScreen> createState() => _UssdScreenState();
}

class _UssdScreenState extends State<UssdScreen> {
  final List<String> _input = [];
  int _ussdStep = 0;
  String _display = _mainMenu;

  static const String _mainMenu = '''Bienvenue sur VeilleProtect
─────────────────
1. Signalement urgent
2. Informations et ressources
3. Suivi de mon dossier
4. Parler à un coordinateur
─────────────────
Saisissez votre choix :''';

  void _keyPress(String key) {
    HapticFeedback.lightImpact();
    setState(() => _input.add(key));
  }

  void _send() {
    final val = _input.join();
    _input.clear();
    setState(() {
      _ussdStep++;
      _display = _getResponse(val);
    });
  }

  void _backspace() {
    if (_input.isNotEmpty) setState(() => _input.removeLast());
  }

  String _getResponse(String input) {
    switch (_ussdStep) {
      case 1:
        switch (input) {
          case '1':
            return '''TYPE DE VIOLENCE
─────────────────
1. Physique / Coups
2. Sexuelle
3. Domestique
4. Verbale / Menaces
5. Psychologique
─────────────────
Votre choix :''';
          case '2':
            return '''RESSOURCES D'AIDE
─────────────────
• Police : 17
• SAMU : 15
• Ligne Verte : 80000001
• VeilleProtect : *115#
─────────────────
0. Retour menu principal''';
          case '3':
            return '''SUIVI DE DOSSIER
─────────────────
Entrez votre référence
(ex: VLP-0941-7743)
─────────────────
Votre référence :''';
          case '4':
            return '''COORDINATEUR
─────────────────
Un coordinateur vous
rappellera sous 30min.

Confirmez votre demande :
1. Confirmer
2. Annuler''';
          default:
            return _mainMenu;
        }
      case 2:
        if (_ussdStep == 2) {
          return '''SIGNALEMENT ENREGISTRÉ
─────────────────
✓ Votre alerte a été
  transmise aux équipes.

Référence : VLP-${DateTime.now().millisecond.toString().padLeft(4, '0')}-${DateTime.now().second.toString().padLeft(4, '0')}

1. Nouveau signalement
0. Quitter''';
        }
        return _mainMenu;
      default:
        return _mainMenu;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SMS · USSD')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // USSD hero
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1A2E4A), Color(0xFF2A4870)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('*115#',
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'Playfair Display')),
                  const SizedBox(height: 8),
                  const Text(
                    'Code USSD universel · Fonctionne sans internet\nSur tous les réseaux · Même en prépayé',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Simulator
            const Text('SIMULATEUR USSD',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.12,
                    color: AppColors.muted)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  // Header bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('USSD · VeilleProtect',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70)),
                        Text(_ussdStep == 0 ? 'Menu principal' : 'Étape ${_ussdStep + 1}',
                            style: const TextStyle(fontSize: 11, color: Colors.white38)),
                      ],
                    ),
                  ),
                  // Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      _display,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF00FF88),
                          height: 1.7),
                    ),
                  ),
                  // Input row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2E),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              _input.isNotEmpty ? _input.join() : 'Ex: 1',
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  color: _input.isNotEmpty
                                      ? Colors.white
                                      : Colors.white24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _input.isNotEmpty ? _send : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _input.isNotEmpty
                                  ? AppColors.green
                                  : const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Envoyer',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Keypad
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      children: [
                        _buildKeyRow(['1', '2', '3']),
                        const SizedBox(height: 6),
                        _buildKeyRow(['4', '5', '6']),
                        const SizedBox(height: 6),
                        _buildKeyRow(['7', '8', '9']),
                        const SizedBox(height: 6),
                        _buildKeyRow(['*', '0', '#']),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // SMS templates
            const Text('MODÈLES SMS',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.12,
                    color: AppColors.muted)),
            const SizedBox(height: 10),
            _SmsCard(
              title: 'Alerte urgente',
              icon: Icons.warning_rounded,
              iconColor: AppColors.red,
              content:
                  'SOS VLP [TYPE] [ZONE]\nEx: SOS VLP PHYSIQUE COCODY\nEnvoyez au : +225 07 00 115 115',
            ),
            const SizedBox(height: 10),
            _SmsCard(
              title: 'Suivi de dossier',
              icon: Icons.access_time,
              iconColor: AppColors.amber,
              content:
                  'SUIVI [NUMÉRO-DOSSIER]\nEx: SUIVI VLP-0941-7743\nEnvoyez au : +225 07 00 115 115',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      children: keys
          .map((k) => Expanded(
                child: GestureDetector(
                  onTap: () => _keyPress(k),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(k,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _SmsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String content;

  const _SmsCard(
      {required this.title,
      required this.icon,
      required this.iconColor,
      required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 13),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 8),
          Text(content,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppColors.sub,
                  height: 1.7)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Modèle copié'),
                    duration: Duration(seconds: 2)),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Copier le modèle',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sub)),
            ),
          ),
        ],
      ),
    );
  }
}
