import 'package:flutter/material.dart';
import 'package:mara_flutter/core/services/api_service.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = ApiService();
  List<dynamic> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getAnnouncements();
      setState(() {
        _announcements = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
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
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : _announcements.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _announcements.length,
                            itemBuilder: (_, i) => _AnnouncementCard(
                                announcement: _announcements[i]),
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
              Text('Annonces',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.title,
                      letterSpacing: -0.3)),
              Text('Informations et alertes de MARA',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_rounded,
              size: 56, color: AppColors.border),
          const SizedBox(height: 16),
          const Text('Aucune annonce pour le moment',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted)),
          const SizedBox(height: 6),
          const Text('Revenez bientôt.',
              style: TextStyle(fontSize: 12, color: AppColors.placeholder)),
        ],
      ),
    );
  }
}

// ── Announcement card ─────────────────────────────────────────────────────────
class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> announcement;
  const _AnnouncementCard({required this.announcement});

  (Color, Color, IconData) _levelInfo(String? level) {
    switch (level) {
      case 'urgent':
        return (AppColors.danger, AppColors.dangerLight, Icons.warning_rounded);
      case 'important':
        return (AppColors.warning, AppColors.warningLight,
            Icons.info_outline_rounded);
      default:
        return (AppColors.info, AppColors.infoLight,
            Icons.campaign_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = announcement['title'] as String? ?? '';
    final body = announcement['body'] as String? ??
        announcement['content'] as String? ??
        '';
    final level = announcement['level'] as String?;
    final createdAt = (announcement['created_at'] as String? ?? '');
    final dateLabel =
        createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;

    final (color, bg, icon) = _levelInfo(level);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top band
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  (level ?? 'info').toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.8),
                ),
                const Spacer(),
                Text(dateLabel,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.title)),
                if (title.isNotEmpty && body.isNotEmpty)
                  const SizedBox(height: 6),
                if (body.isNotEmpty)
                  Text(body,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.body,
                          height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
