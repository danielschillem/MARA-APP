import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mara_flutter/core/services/api_service.dart';
import 'package:mara_flutter/core/services/auth_service.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';

class CounselorDashboard extends StatefulWidget {
  const CounselorDashboard({super.key});

  @override
  State<CounselorDashboard> createState() => _CounselorDashboardState();
}

class _CounselorDashboardState extends State<CounselorDashboard>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late final TabController _tab;

  Map<String, dynamic>? _stats;
  List<dynamic> _reports = [];
  List<dynamic> _conversations = [];
  bool _loadingStats = true;
  bool _loadingReports = true;
  bool _loadingConvs = true;
  String _reportFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
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
    _loadConvs();
  }

  Future<void> _loadStats() async {
    try {
      final data = await _api.getDashboard();
      setState(() {
        _stats = data;
        _loadingStats = false;
      });
    } catch (_) {
      setState(() => _loadingStats = false);
    }
  }

  Future<void> _loadReports() async {
    try {
      final data = await _api.getReports(
          status: _reportFilter == 'all' ? null : _reportFilter);
      setState(() {
        _reports = data;
        _loadingReports = false;
      });
    } catch (_) {
      setState(() => _loadingReports = false);
    }
  }

  Future<void> _loadConvs() async {
    try {
      final data = await _api.getConversations();
      setState(() {
        _conversations = data;
        _loadingConvs = false;
      });
    } catch (_) {
      setState(() => _loadingConvs = false);
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
                  _buildConvsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final name = user?['name'] as String? ?? 'Conseiller';
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tableau de bord',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title,
                        letterSpacing: -0.3)),
                Text('Bonjour, $name',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.person_rounded,
                  size: 20, color: AppColors.primary),
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
          Tab(text: 'Stats'),
          Tab(text: 'Signalements'),
          Tab(text: 'Chats'),
        ],
      ),
    );
  }

  // ── Stats tab ─────────────────────────────────────────────────────────────

  Widget _buildStatsTab() {
    if (_loadingStats) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_stats == null) {
      return const Center(
          child: Text('Impossible de charger les stats.',
              style: TextStyle(color: AppColors.muted)));
    }
    final s = _stats!;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Signalements',
                    value: '${s['total_reports'] ?? 0}',
                    icon: Icons.description_rounded,
                    color: AppColors.primary,
                    bg: AppColors.primarySurface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'En cours',
                    value: '${s['in_progress_reports'] ?? 0}',
                    icon: Icons.pending_actions_rounded,
                    color: AppColors.info,
                    bg: AppColors.infoLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Résolus',
                    value: '${s['resolved_reports'] ?? 0}',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    bg: AppColors.successLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Conversations',
                    value: '${s['total_conversations'] ?? 0}',
                    icon: Icons.forum_rounded,
                    color: AppColors.accent,
                    bg: AppColors.accentLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Urgents',
                    value: '${s['urgent_reports'] ?? 0}',
                    icon: Icons.warning_rounded,
                    color: AppColors.danger,
                    bg: AppColors.dangerLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Utilisateurs',
                    value: '${s['total_users'] ?? 0}',
                    icon: Icons.people_rounded,
                    color: AppColors.purple,
                    bg: AppColors.purpleLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Reports tab ───────────────────────────────────────────────────────────

  Widget _buildReportsTab() {
    return Column(
      children: [
        // Filter chips
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            children: [
              for (final f in [
                ('all', 'Tous'),
                ('pending', 'En attente'),
                ('in_progress', 'En cours'),
                ('resolved', 'Résolus'),
                ('urgent', 'Urgents'),
              ])
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _reportFilter = f.$1;
                      _loadingReports = true;
                    });
                    _loadReports();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _reportFilter == f.$1
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _reportFilter == f.$1
                              ? AppColors.primary
                              : AppColors.border),
                    ),
                    child: Text(f.$2,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _reportFilter == f.$1
                                ? Colors.white
                                : AppColors.sub)),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _loadingReports
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _reports.isEmpty
                  ? const Center(
                      child: Text('Aucun signalement.',
                          style: TextStyle(color: AppColors.muted)))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _loadReports,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _reports.length,
                        itemBuilder: (_, i) => _ReportTile(report: _reports[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  // ── Conversations tab ─────────────────────────────────────────────────────

  Widget _buildConvsTab() {
    if (_loadingConvs) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_conversations.isEmpty) {
      return const Center(
          child: Text('Aucune conversation active.',
              style: TextStyle(color: AppColors.muted)));
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadConvs,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _conversations.length,
        itemBuilder: (_, i) => _ConvTile(conv: _conversations[i]),
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  const _StatCard(
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(label,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Report tile ───────────────────────────────────────────────────────────────
class _ReportTile extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ReportTile({required this.report});

  (Color, Color) _statusColor(String? status) {
    switch (status) {
      case 'in_progress':
        return (AppColors.info, AppColors.infoLight);
      case 'resolved':
        return (AppColors.success, AppColors.successLight);
      case 'urgent':
        return (AppColors.danger, AppColors.dangerLight);
      default:
        return (AppColors.warning, AppColors.warningLight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = report['reference'] as String? ?? '#';
    final type = report['type_id'] as String? ?? '';
    final status = report['status'] as String?;
    final createdAt = (report['created_at'] as String? ?? '');
    final date =
        createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;
    final (color, bg) = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.description_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ref,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        color: AppColors.title)),
                const SizedBox(height: 2),
                Text(type,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(8)),
                child: Text(status ?? 'pending',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
              const SizedBox(height: 4),
              Text(date,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Conversation tile ─────────────────────────────────────────────────────────
class _ConvTile extends StatelessWidget {
  final Map<String, dynamic> conv;
  const _ConvTile({required this.conv});

  @override
  Widget build(BuildContext context) {
    final id = conv['id'];
    final status = conv['status'] as String? ?? 'open';
    final createdAt = (conv['created_at'] as String? ?? '');
    final date =
        createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;
    final isOpen = status == 'open';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isOpen ? AppColors.successLight : AppColors.bgAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.forum_rounded,
                color: isOpen ? AppColors.success : AppColors.muted, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conversation #$id',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.title)),
                const SizedBox(height: 2),
                Text(date,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isOpen ? AppColors.successLight : AppColors.bgAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isOpen ? 'Ouvert' : 'Fermé',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isOpen ? AppColors.success : AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
