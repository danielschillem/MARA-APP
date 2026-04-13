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
              leading: _step > 0
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 18),
                      onPressed: _prevStep,
                    )
                  : null,
              title: const Text('Signaler'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _StepIndicator(current: _step, total: 4),
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
        const SizedBox(height: 8),
        const Text('Votre identité',
            style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Comment soumettre ce signalement ?',
            style: TextStyle(fontSize: 13, color: AppColors.sub)),
        const SizedBox(height: 20),
        _IdentityCard(
          icon: Icons.visibility_off,
          title: 'Anonyme total',
          desc: 'Aucune donnée vous identifiant n\'est transmise.',
          badge: 'Recommandé si risque personnel',
          badgeColor: AppColors.green,
          selected: _identity == 'anonymous',
          onTap: () {
            setState(() => _identity = 'anonymous');
            _nextStep();
          },
        ),
        const SizedBox(height: 10),
        _IdentityCard(
          icon: Icons.remove_red_eye,
          title: 'Avec un pseudonyme',
          desc: 'Recevez des mises à jour sans révéler votre identité.',
          badge: 'Suivi possible',
          badgeColor: AppColors.navy,
          selected: _identity == 'pseudo',
          onTap: () {
            setState(() => _identity = 'pseudo');
            _nextStep();
          },
        ),
        const SizedBox(height: 10),
        _IdentityCard(
          icon: Icons.person,
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
        const Text('Type de violence',
            style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Sélectionnez la nature des faits',
            style: TextStyle(fontSize: 13, color: AppColors.sub)),
        const SizedBox(height: 16),
        ...kViolenceTypes.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _TypeItem(
                id: e.key,
                label: e.value['label']!,
                sub: e.value['sub']!,
                selected: _selectedType == e.key,
                onTap: () => setState(() => _selectedType = e.key),
              ),
            )),
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
        const Text('La victime',
            style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Qui semble être la personne concernée ?',
            style: TextStyle(fontSize: 13, color: AppColors.sub)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 11,
          mainAxisSpacing: 11,
          children: kVictimTypes.entries
              .map((e) => _VictimCard(
                    id: e.key,
                    label: e.value['label']!,
                    selected: _selectedVictim == e.key,
                    onTap: () => setState(() => _selectedVictim = e.key),
                  ))
              .toList(),
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
        const Text('Enrichir le signalement',
            style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Informations optionnelles mais précieuses',
            style: TextStyle(fontSize: 13, color: AppColors.sub)),
        const SizedBox(height: 16),
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
                const Icon(Icons.info_outline, size: 13, color: AppColors.muted),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'En danger immédiat : 17 (Police) · 3919 (Violences Femmes) · 119 (Enfants)',
                    style: TextStyle(fontSize: 12, color: AppColors.sub, height: 1.6),
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

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) => Container(
            margin: const EdgeInsets.only(left: 5),
            width: 22,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: i <= current ? AppColors.red : AppColors.border,
            ),
          )),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final String badge;
  final Color badgeColor;
  final bool selected;
  final VoidCallback onTap;

  const _IdentityCard({
    required this.icon,
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
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color: selected ? AppColors.red : AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.redLight, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: AppColors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  const SizedBox(height: 3),
                  Text(desc,
                      style: const TextStyle(fontSize: 11, color: AppColors.sub)),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(20),
                      color: badgeColor.withValues(alpha: 0.08),
                    ),
                    child: Text(badge,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeColor)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 14),
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
  final bool selected;
  final VoidCallback onTap;

  const _TypeItem(
      {required this.id,
      required this.label,
      required this.sub,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.redLight : Colors.white,
          border: Border.all(
              color: selected ? AppColors.red : AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: selected ? AppColors.red : const Color(0xFFF2F2EF),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(Icons.warning_rounded,
                  size: 18,
                  color: selected ? Colors.white : AppColors.muted),
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
                          color: selected ? AppColors.red : AppColors.ink)),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.red, size: 18),
          ],
        ),
      ),
    );
  }
}

class _VictimCard extends StatelessWidget {
  final String id;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _VictimCard(
      {required this.id,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.redLight : const Color(0xFFFAFAFA),
          border: Border.all(
              color: selected ? AppColors.red : AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: selected ? AppColors.red : const Color(0xFFF0F0EC),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.person,
                  size: 24,
                  color: selected ? Colors.white : AppColors.muted),
            ),
            const SizedBox(height: 9),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? AppColors.red : AppColors.sub)),
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
          color: AppColors.greenLight,
          borderRadius: BorderRadius.circular(13)),
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
