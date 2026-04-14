import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mara_flutter/core/services/api_service.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';
import 'package:mara_flutter/shared/widgets/skeleton_loader.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _api = ApiService();
  List<dynamic> _services = [];
  bool _loading = true;
  String _selectedType = 'all';
  String _search = '';

  static const _types = [
    ('all', 'Tous', Icons.apps_rounded),
    ('ngo', 'ONG', Icons.volunteer_activism_rounded),
    ('police', 'Police', Icons.local_police_rounded),
    ('health', 'Santé', Icons.local_hospital_rounded),
    ('legal', 'Juridique', Icons.balance_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getServices(
        type: _selectedType == 'all' ? null : _selectedType,
      );
      setState(() {
        _services = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered {
    if (_search.trim().isEmpty) return _services;
    final q = _search.toLowerCase();
    return _services.where((s) {
      final name = (s['name'] as String? ?? '').toLowerCase();
      final city = (s['city'] as String? ?? '').toLowerCase();
      final desc = (s['description'] as String? ?? '').toLowerCase();
      return name.contains(q) || city.contains(q) || desc.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            _buildTypeBar(),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const SkeletonList(count: 5)
                  : _filtered.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) =>
                                _ServiceCard(service: _filtered[i]),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Annuaire des services',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title,
                        letterSpacing: -0.3)),
                Text('ONG · Police · Santé · Juridique',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        style: const TextStyle(fontSize: 14, color: AppColors.title),
        decoration: InputDecoration(
          hintText: 'Chercher un service, une ville…',
          hintStyle:
              const TextStyle(fontSize: 13, color: AppColors.placeholder),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: AppColors.muted),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBar() {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        children: _types.map((t) {
          final isSelected = _selectedType == t.$1;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedType = t.$1);
              _load();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.$3,
                      size: 14,
                      color: isSelected ? Colors.white : AppColors.muted),
                  const SizedBox(width: 6),
                  Text(t.$2,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.sub)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.domain_disabled_rounded,
              size: 56, color: AppColors.border),
          const SizedBox(height: 16),
          const Text('Aucun service trouvé',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted)),
          const SizedBox(height: 6),
          const Text('Essayez un autre filtre ou une autre ville.',
              style: TextStyle(fontSize: 12, color: AppColors.placeholder)),
        ],
      ),
    );
  }
}

// ── Service card ──────────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  const _ServiceCard({required this.service});

  (IconData, Color, Color) _typeInfo(String? type) {
    switch (type) {
      case 'police':
        return (
          Icons.local_police_rounded,
          AppColors.accent,
          AppColors.accentLight
        );
      case 'health':
        return (
          Icons.local_hospital_rounded,
          AppColors.success,
          AppColors.successLight
        );
      case 'legal':
        return (
          Icons.balance_rounded,
          AppColors.warning,
          AppColors.warningLight
        );
      default:
        return (
          Icons.volunteer_activism_rounded,
          AppColors.primary,
          AppColors.primarySurface
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = service['type'] as String?;
    final name = service['name'] as String? ?? 'Service';
    final desc = service['description'] as String? ?? '';
    final city = service['city'] as String? ?? '';
    final phone = service['phone'] as String?;
    final email = service['email'] as String?;
    final (icon, color, bg) = _typeInfo(type);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.title)),
                    if (city.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 12, color: AppColors.muted),
                          const SizedBox(width: 3),
                          Text(city,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(desc,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.body, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
          if (phone != null || email != null) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.borderLight, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (phone != null)
                  _ContactBtn(
                    icon: Icons.phone_rounded,
                    label: phone,
                    onTap: () => HapticFeedback.lightImpact(),
                  ),
                if (phone != null && email != null) const SizedBox(width: 8),
                if (email != null)
                  _ContactBtn(
                    icon: Icons.email_rounded,
                    label: email,
                    onTap: () => HapticFeedback.lightImpact(),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ContactBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
