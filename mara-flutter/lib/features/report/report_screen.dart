import 'package:flutter/material.dart';
import 'package:mara_flutter/core/services/api_service.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';
import 'package:mara_flutter/shared/models/alert_model.dart';
import 'package:mara_flutter/shared/widgets/app_button.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _step = 0; // 0=identity, 1=type, 2=victim, 3=enrich, 4=confirm
  String? _identity; // anonymous|pseudo|identified
  String? _selectedType;
  String? _selectedVictim;
  bool _isOngoing = false;
  bool _hasPhoto = false;
  bool _hasAudio = false;
  final _descCtrl = TextEditingController();
  bool _loading = false;
  String? _reference;

  static const _stepLabels = [
    'Votre identité',
    'Type de violence',
    'La victime',
    'Détails',
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  void _nextStep() => setState(() => _step++);
  void _prevStep() => setState(() {
        if (_step > 0) _step--;
      });

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final api = ApiService();
      final res = await api.createAlert({
        'type_id': _selectedType ?? 'physical',
        'victim_type': _selectedVictim ?? 'unknown',
        'is_ongoing': _isOngoing,
        'channel': 'app',
        'is_anonymous': _identity == 'anonymous',
        'has_photo': _hasPhoto,
        'has_audio': _hasAudio,
        'notes': _descCtrl.text,
      });
      setState(() {
        _reference = res['reference'];
        _step = 4;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _step < 4
          ? AppBar(
              elevation: 0,
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              leading: _step > 0
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      onPressed: _prevStep,
                    )
                  : null,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Signalement',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(_stepLabels[_step],
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.muted)),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(6),
                child: _ProgressBar(current: _step, total: 4),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      '${_step + 1}/4',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: IndexedStack(
          index: _step,
          children: [
            _buildIdentity(),
            _buildType(),
            _buildVictim(),
            _buildEnrich(),
            _buildConfirm(),
          ],
        ),
      ),
    );
  }

  // ── Step 0: Identity ──────────────────────────────────────────────────────
  Widget _buildIdentity() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 4),
        const Text('Comment soumettre ce signalement ?',
            style: TextStyle(fontSize: 13, color: AppColors.sub)),
        const SizedBox(height: 20),
        _IdentityCard(
          icon: Icons.visibility_off_rounded,
          iconBg: const Color(0xFF2D6A4F),
          title: 'Anonyme total',
          desc: 'Aucune donnée vous identifiant n\'est transmise.',
          badge: 'Recommandé si risque personnel',
          badgeColor: AppColors.success,
          selected: _identity == 'anonymous',
          onTap: () {
            setState(() => _identity = 'anonymous');
            _nextStep();
          },
        ),
        const SizedBox(height: 10),
        _IdentityCard(
          icon: Icons.badge_outlined,
          iconBg: AppColors.accent,
          title: 'Avec un pseudonyme',
          desc: 'Recevez des mises à jour sans révéler votre identité.',
          badge: 'Suivi possible',
          badgeColor: AppColors.accent,
          selected: _identity == 'pseudo',
          onTap: () {
            setState(() => _identity = 'pseudo');
            _nextStep();
          },
        ),
        const SizedBox(height: 10),
        _IdentityCard(
          icon: Icons.person_rounded,
          iconBg: AppColors.purple,
          title: 'Identifié(e)',
          desc: 'Un coordinateur peut vous contacter directement.',
          badge: 'Témoignage officiel',
          badgeColor: AppColors.purple,
          selected: _identity == 'identified',
          onTap: () {
            setState(() => _identity = 'identified');
            _nextStep();
          },
        ),
      ],
    );
  }

  // ── Step 1: Type ──────────────────────────────────────────────────────────
  Widget _buildType() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Sélectionnez la nature des faits',
            style: TextStyle(fontSize: 13, color: AppColors.sub)),
        const SizedBox(height: 16),
        ...kViolenceTypes.entries.map((e) {
          const typeIcons = <String, IconData>{
            'physical': Icons.personal_injury_rounded,
            'sexual': Icons.sentiment_very_dissatisfied_rounded,
            'domestic': Icons.home_rounded,
            'verbal': Icons.record_voice_over_rounded,
            'psychological': Icons.psychology_rounded,
            'economic': Icons.account_balance_wallet_rounded,
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _TypeItem(
              id: e.key,
              label: e.value['label']!,
              sub: e.value['sub']!,
              icon: typeIcons[e.key] ?? Icons.warning_rounded,
              selected: _selectedType == e.key,
              onTap: () => setState(() => _selectedType = e.key),
            ),
          );
        }),
        const SizedBox(height: 16),
        AppButton(
          label: 'Continuer',
          onPressed: _selectedType != null ? _nextStep : null,
        ),
      ],
    );
  }

  // ── Step 2: Victim ────────────────────────────────────────────────────────
  Widget _buildVictim() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Qui semble être la personne concernée ?',
            style: TextStyle(fontSize: 13, color: AppColors.sub)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 11,
          mainAxisSpacing: 11,
          children: kVictimTypes.entries.map((e) {
            const victimIcons = <String, IconData>{
              'woman': Icons.woman_rounded,
              'man': Icons.man_rounded,
              'child': Icons.child_care_rounded,
              'elderly': Icons.elderly_rounded,
              'unknown': Icons.help_outline_rounded,
            };
            return _VictimCard(
              id: e.key,
              label: e.value['label']!,
              icon: victimIcons[e.key] ?? Icons.person_rounded,
              selected: _selectedVictim == e.key,
              onTap: () => setState(() => _selectedVictim = e.key),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Continuer',
          onPressed: _selectedVictim != null ? _nextStep : null,
        ),
      ],
    );
  }

  // ── Step 3: Enrich ────────────────────────────────────────────────────────
  Widget _buildEnrich() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Informations optionnelles mais précieuses',
            style: TextStyle(fontSize: 13, color: AppColors.sub)),
        const SizedBox(height: 18),
        const Text('EST-CE EN COURS ?',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.12,
                color: AppColors.muted)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ToggleBtn(
                label: 'Oui, en cours',
                active: _isOngoing,
                activeColor: AppColors.red,
                onTap: () => setState(() => _isOngoing = true),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _ToggleBtn(
                label: 'Après les faits',
                active: !_isOngoing,
                activeColor: AppColors.navy,
                onTap: () => setState(() => _isOngoing = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('PREUVES',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.12,
                color: AppColors.muted)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MediaBtn(
                icon: Icons.camera_alt,
                label: 'Photo / Vidéo',
                active: _hasPhoto,
                activeColor: AppColors.navy,
                onTap: () => setState(() => _hasPhoto = !_hasPhoto),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MediaBtn(
                icon: Icons.mic,
                label: 'Enregistrement',
                active: _hasAudio,
                activeColor: AppColors.purple,
                onTap: () => setState(() => _hasAudio = !_hasAudio),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('DESCRIPTION',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.12,
                color: AppColors.muted)),
        const SizedBox(height: 8),
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Décrivez brièvement ce que vous avez observé…',
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Envoyer le signalement complet',
          isLoading: _loading,
          onPressed: _submit,
          icon: const Icon(Icons.send, color: Colors.white, size: 16),
        ),
        const SizedBox(height: 8),
        AppOutlineButton(
          label: 'Ignorer et terminer',
          onPressed: _submit,
        ),
      ],
    );
  }

  // ── Step 4: Confirm ───────────────────────────────────────────────────────
  Widget _buildConfirm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.greenLight,
              boxShadow: [
                BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.07),
                    blurRadius: 0,
                    spreadRadius: 14),
              ],
            ),
            child: const Icon(Icons.shield, color: AppColors.green, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Signalement complet',
              style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green)),
          const SizedBox(height: 10),
          const Text(
            'Votre signalement a été transmis et sera traité dans les plus brefs délais.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.sub, height: 1.7),
          ),
          const SizedBox(height: 20),
          _InfoCard(label: 'Temps de réponse estimé', value: '< 30 minutes'),
          const SizedBox(height: 8),
          _InfoCard(label: 'Confidentialité', value: 'Garantie & chiffrée'),
          if (_reference != null) ...[
            const SizedBox(height: 8),
            _InfoCard(label: 'Référence', value: _reference!),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F0),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 13, color: AppColors.muted),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'En danger immédiat : 17 (Police) · 3919 (Violences Femmes) · 119 (Enfants)',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.sub, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Retour à l\'accueil',
            onPressed: () => setState(() {
              _step = 0;
              _identity = null;
              _selectedType = null;
              _selectedVictim = null;
              _isOngoing = false;
              _hasPhoto = false;
              _hasAudio = false;
              _descCtrl.clear();
              _reference = null;
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting widgets ────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      child: Row(
        children: List.generate(
          total,
          (i) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
              height: 4,
              decoration: BoxDecoration(
                color: i <= current ? AppColors.primary : AppColors.borderLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String desc;
  final String badge;
  final Color badgeColor;
  final bool selected;
  final VoidCallback onTap;

  const _IdentityCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.desc,
    required this.badge,
    required this.badgeColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected ? AppShadows.sm : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: selected ? AppColors.primary : AppColors.ink)),
                  const SizedBox(height: 3),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.sub, height: 1.4)),
                  const SizedBox(height: 7),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: badgeColor.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(20),
                      color: badgeColor.withValues(alpha: 0.08),
                    ),
                    child: Text(badge,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: badgeColor)),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.chevron_right,
              color: selected ? AppColors.primary : AppColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeItem extends StatelessWidget {
  final String id;
  final String label;
  final String sub;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeItem({
    required this.id,
    required this.label,
    required this.sub,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1.5),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.bgAlt,
                  borderRadius: BorderRadius.circular(11)),
              child: Icon(icon,
                  size: 20, color: selected ? Colors.white : AppColors.sub),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected ? AppColors.primary : AppColors.ink)),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _VictimCard extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _VictimCard({
    required this.id,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1.5),
          borderRadius: BorderRadius.circular(15),
          boxShadow: selected ? AppShadows.sm : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.bgAlt,
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(icon,
                  size: 26, color: selected ? Colors.white : AppColors.sub),
            ),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.sub)),
            if (selected) ...[
              const SizedBox(height: 4),
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleBtn(
      {required this.label,
      required this.active,
      required this.activeColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.08)
              : const Color(0xFFFAFAFA),
          border: Border.all(
              color: active ? activeColor : AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? activeColor : AppColors.sub)),
        ),
      ),
    );
  }
}

class _MediaBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _MediaBtn(
      {required this.icon,
      required this.label,
      required this.active,
      required this.activeColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.08)
              : const Color(0xFFFAFAFA),
          border: Border.all(
              color: active ? activeColor : AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Icon(icon, color: active ? activeColor : AppColors.muted, size: 20),
            const SizedBox(height: 7),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? activeColor : AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
          color: AppColors.greenLight, borderRadius: BorderRadius.circular(13)),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.green, size: 14),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF888888),
                      letterSpacing: 0.05)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green)),
            ],
          ),
        ],
      ),
    );
  }
}
