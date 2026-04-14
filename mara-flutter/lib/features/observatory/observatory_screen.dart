import 'package:flutter/material.dart';
import 'package:mara_flutter/core/services/api_service.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';
import 'package:mara_flutter/shared/widgets/skeleton_loader.dart';

class ObservatoryScreen extends StatefulWidget {
  const ObservatoryScreen({super.key});

  @override
  State<ObservatoryScreen> createState() => _ObservatoryScreenState();
}

class _ObservatoryScreenState extends State<ObservatoryScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late final TabController _tab;

  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _reports;
  bool _loadingStats = true;
  bool _loadingReports = true;
  int _page = 1;
  String _country = 'all';

  static const _countries = [
    ('all', 'Tous pays'),
    ('BF', 'Burkina Faso'),
    ('CI', 'Côte d\'Ivoire'),
    ('ML', 'Mali'),
    ('NE', 'Niger'),
    ('SN', 'Sénégal'),
    ('GN', 'Guinée'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadStats();
    _loadReports();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final data = await _api.getObservatoryStats();
      setState(() {
        _stats = data;
        _loadingStats = false;
      });
    } catch (_) {
      setState(() => _loadingStats = false);
    }
  }

  Future<void> _loadReports() async {
    setState(() => _loadingReports = true);
    try {
      final data = await _api.getObservatoryReports(
        country: _country == 'all' ? null : _country,
        page: _page,
      );
      setState(() {
        _reports = data;
        _loadingReports = false;
      });
    } catch (_) {
      setState(() => _loadingReports = false);
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
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildStatsTab(),
                  _buildReportsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: AppColors.surface,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
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
                Text('Observatoire',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title,
                        letterSpacing: -0.3)),
                Text('Données humanitaires · ReliefWeb',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 6, color: AppColors.success),
                SizedBox(width: 5),
                Text('Live',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tab,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.muted,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Statistiques'),
          Tab(text: 'Rapports'),
        ],
      ),
    );
  }

  // ── Stats tab ─────────────────────────────────────────────────────────────

  Widget _buildStatsTab() {
    if (_loadingStats) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: const [
              Expanded(child: SkeletonStatCard()),
              SizedBox(width: 12),
              Expanded(child: SkeletonStatCard()),
            ]),
            const SizedBox(height: 12),
            Row(children: const [
              Expanded(child: SkeletonStatCard()),
              SizedBox(width: 12),
              Expanded(child: SkeletonStatCard()),
            ]),
          ],
        ),
      );
    }
    if (_stats == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signal_wifi_off_rounded,
                size: 48, color: AppColors.border),
            const SizedBox(height: 12),
            const Text('Données non disponibles',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
    final s = _stats!;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main stats
            Row(
              children: [
                Expanded(
                  child: _ObsStatCard(
                    label: 'Rapports totaux',
                    value: '${s['total_reports'] ?? 0}',
                    icon: Icons.article_rounded,
                    color: AppColors.primary,
                    bg: AppColors.primarySurface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ObsStatCard(
                    label: 'Pays couverts',
                    value: '${s['countries_count'] ?? 0}',
                    icon: Icons.public_rounded,
                    color: AppColors.success,
                    bg: AppColors.successLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ObsStatCard(
                    label: 'Crises actives',
                    value: '${s['active_crises'] ?? 0}',
                    icon: Icons.crisis_alert_rounded,
                    color: AppColors.danger,
                    bg: AppColors.dangerLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ObsStatCard(
                    label: 'Personnes affectées',
                    value: _formatLarge(s['affected_people']),
                    icon: Icons.people_rounded,
                    color: AppColors.warning,
                    bg: AppColors.warningLight,
                  ),
                ),
              ],
            ),
            // Region breakdown
            if (s['by_region'] != null) ...[
              const SizedBox(height: 24),
              const Text('PAR RÉGION',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.muted)),
              const SizedBox(height: 12),
              ...(s['by_region'] as Map<String, dynamic>).entries.map(
                    (e) => _RegionBar(
                      region: e.key,
                      count: (e.value as num).toInt(),
                      total: (s['total_reports'] as num? ?? 1).toInt(),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatLarge(dynamic value) {
    if (value == null) return '—';
    final n = (value as num).toInt();
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  // ── Reports tab ───────────────────────────────────────────────────────────

  Widget _buildReportsTab() {
    final items = (_reports?['data'] as List<dynamic>?) ??
        (_reports?['items'] as List<dynamic>?) ??
        [];

    return Column(
      children: [
        // Country filter
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            children: _countries.map((c) {
              final isSelected = _country == c.$1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _country = c.$1;
                    _page = 1;
                  });
                  _loadReports();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(c.$2,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.sub)),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _loadingReports
              ? const SkeletonList(count: 5)
              : items.isEmpty
                  ? const Center(
                      child: Text('Aucun rapport disponible.',
                          style: TextStyle(color: AppColors.muted)))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _loadReports,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: items.length,
                        itemBuilder: (_, i) => _ObsReportCard(report: items[i]),
                      ),
                    ),
        ),
      ],
    );
  }
}

// ── Observatory stat card ─────────────────────────────────────────────────────
class _ObsStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  const _ObsStatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.muted, height: 1.3)),
        ],
      ),
    );
  }
}

// ── Region bar ────────────────────────────────────────────────────────────────
class _RegionBar extends StatelessWidget {
  final String region;
  final int count;
  final int total;
  const _RegionBar(
      {required this.region, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(region,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sub))),
              Text('$count',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.title)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.borderLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Observatory report card ───────────────────────────────────────────────────
class _ObsReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ObsReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final title = report['title'] as String? ?? 'Sans titre';
    final country = report['country'] as String? ?? '';
    final date =
        (report['date'] as String? ?? report['created_at'] as String? ?? '')
            .substring(
                0,
                10 < (report['date'] as String? ?? '').length
                    ? 10
                    : (report['date'] as String? ?? '').length);
    final type = report['type'] as String? ?? 'rapport';
    final url = report['url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.public_rounded,
                color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (country.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(country,
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(type.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                            letterSpacing: 0.3)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.title,
                        height: 1.3),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(date,
                    style:
                        const TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          if (url != null)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.open_in_new_rounded,
                  size: 16, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}
