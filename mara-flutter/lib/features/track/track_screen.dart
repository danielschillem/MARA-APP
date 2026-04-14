import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mara_flutter/core/services/api_service.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';

class TrackScreen extends StatefulWidget {
  final String? initialRef;
  const TrackScreen({super.key, this.initialRef});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  final _api = ApiService();
  late final TextEditingController _refCtrl;
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refCtrl = TextEditingController(text: widget.initialRef ?? '');
    if (widget.initialRef != null && widget.initialRef!.isNotEmpty) {
      _track();
    }
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final ref = _refCtrl.text.trim();
    if (ref.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final data = await _api.trackReport(ref);
      setState(() {
        _result = data;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Référence introuvable. Vérifiez la saisie.';
        _loading = false;
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
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  children: [
                    _buildSearchCard(),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      ),
                    if (_error != null) _buildError(),
                    if (_result != null) _buildResult(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppShadows.sm,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppColors.sub),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Suivi de dossier',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.title,
                      letterSpacing: -0.3)),
              Text('Entrez votre référence de signalement',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Référence',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.sub)),
          const SizedBox(height: 10),
          TextField(
            controller: _refCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: AppColors.title,
                letterSpacing: 1.5),
            decoration: InputDecoration(
              hintText: 'ex: MARA-2024-0001',
              hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.placeholder,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                  fontFamily: 'monospace'),
              filled: true,
              fillColor: AppColors.bg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_rounded,
                    size: 18, color: AppColors.muted),
                onPressed: () async {
                  final clip = await Clipboard.getData('text/plain');
                  if (clip?.text != null) _refCtrl.text = clip!.text!.trim();
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _track,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search_rounded, size: 18),
              label: const Text('Rechercher',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.danger, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    final status = r['status'] as String? ?? 'pending';
    final ref = r['reference'] as String? ?? '';
    final type = r['type_id'] as String? ?? '';
    final createdAt = (r['created_at'] as String? ?? '').substring(0, 10);
    final notes = r['notes'] as String? ?? '';

    final (statusLabel, statusColor, statusBg) = _statusInfo(status);

    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(statusLabel,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ref,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        color: statusColor,
                        letterSpacing: 0.8),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DetailRow(label: 'Type de violence', value: type),
                _DetailRow(label: 'Date de signalement', value: createdAt),
                if (notes.isNotEmpty)
                  _DetailRow(label: 'Notes', value: notes, multiline: true),
                // Timeline
                const SizedBox(height: 16),
                _buildTimeline(status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, Color) _statusInfo(String status) {
    switch (status) {
      case 'in_progress':
        return ('En cours de traitement', AppColors.info, AppColors.infoLight);
      case 'resolved':
        return ('Résolu', AppColors.success, AppColors.successLight);
      case 'closed':
        return ('Clôturé', AppColors.muted, AppColors.bgAlt);
      case 'urgent':
        return ('Urgent', AppColors.danger, AppColors.dangerLight);
      default:
        return ('En attente', AppColors.warning, AppColors.warningLight);
    }
  }

  Widget _buildTimeline(String status) {
    final steps = [
      ('Signalement reçu', 'pending', Icons.inbox_rounded),
      ('En cours de traitement', 'in_progress', Icons.pending_actions_rounded),
      ('Résolu', 'resolved', Icons.check_circle_rounded),
    ];

    final order = ['pending', 'in_progress', 'resolved'];
    final currentIdx = order.indexOf(status).clamp(0, 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Progression',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((e) {
          final idx = e.key;
          final step = e.value;
          final done = idx <= currentIdx;
          final current = idx == currentIdx;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: done ? AppColors.primary : AppColors.border,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(step.$3,
                        size: 14, color: done ? Colors.white : AppColors.muted),
                  ),
                  if (idx < steps.length - 1)
                    Container(
                        width: 2, height: 24, color: AppColors.borderLight),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  step.$1,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                      color: done ? AppColors.title : AppColors.muted),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool multiline;
  const _DetailRow(
      {required this.label, required this.value, this.multiline = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.title,
                    fontWeight: FontWeight.w600,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}
