import 'package:flutter/material.dart';
import 'package:mara_flutter/core/services/api_service.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';
import 'package:mara_flutter/shared/widgets/skeleton_loader.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final _api = ApiService();
  List<dynamic> _resources = [];
  bool _loading = true;
  String _selectedCategory = 'all';

  static const _categories = [
    ('all', 'Tous', Icons.apps_rounded),
    ('article', 'Articles', Icons.article_rounded),
    ('guide', 'Guides', Icons.menu_book_rounded),
    ('law', 'Lois', Icons.gavel_rounded),
    ('video', 'Vidéos', Icons.play_circle_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getResources(
        category: _selectedCategory == 'all' ? null : _selectedCategory,
      );
      setState(() {
        _resources = data;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildCategoryBar(),
            Expanded(
              child: _loading
                  ? const SkeletonList(count: 6)
                  : _resources.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _resources.length,
                            itemBuilder: (ctx, i) =>
                                _ResourceCard(resource: _resources[i]),
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
                Text('Ressources',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title,
                        letterSpacing: -0.3)),
                Text('Guides · Lois · Articles · Vidéos',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat.$1;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = cat.$1);
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
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                boxShadow: isSelected ? AppShadows.sm : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.$3,
                      size: 14,
                      color: isSelected ? Colors.white : AppColors.muted),
                  const SizedBox(width: 6),
                  Text(cat.$2,
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
          Icon(Icons.library_books_rounded, size: 56, color: AppColors.border),
          const SizedBox(height: 16),
          const Text('Aucune ressource disponible',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted)),
        ],
      ),
    );
  }
}

// ── Resource card ─────────────────────────────────────────────────────────────
class _ResourceCard extends StatelessWidget {
  final Map<String, dynamic> resource;
  const _ResourceCard({required this.resource});

  IconData _iconForType(String? type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_rounded;
      case 'law':
        return Icons.gavel_rounded;
      case 'guide':
        return Icons.menu_book_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'video':
        return AppColors.purple;
      case 'law':
        return AppColors.danger;
      case 'guide':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  Color _bgForType(String? type) {
    switch (type) {
      case 'video':
        return AppColors.purpleLight;
      case 'law':
        return AppColors.dangerLight;
      case 'guide':
        return AppColors.warningLight;
      default:
        return AppColors.infoLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = resource['category'] as String?;
    final title = resource['title'] as String? ?? 'Sans titre';
    final summary =
        resource['summary'] as String? ?? resource['content'] as String? ?? '';
    final id = resource['id'] as int?;
    final icon = _iconForType(type);
    final color = _colorForType(type);
    final bg = _bgForType(type);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResourceDetailScreen(
          resourceId: id ?? 0,
          title: title,
        ),
      )),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: AppShadows.card,
        ),
        child: Row(
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (type ?? 'article').toUpperCase(),
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: color,
                              letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.title),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      summary,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

// ── Resource detail screen ────────────────────────────────────────────────────
class ResourceDetailScreen extends StatefulWidget {
  final int resourceId;
  final String title;
  const ResourceDetailScreen(
      {super.key, required this.resourceId, required this.title});

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _resource;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.getResource(widget.resourceId);
      setState(() {
        _resource = data;
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
            // Header
            Padding(
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
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          SkeletonLoader(height: 16, radius: BorderRadius.all(Radius.circular(6))),
                          SizedBox(height: 12),
                          SkeletonLoader(height: 12, radius: BorderRadius.all(Radius.circular(6))),
                          SizedBox(height: 24),
                          SkeletonLoader(height: 200, radius: BorderRadius.all(Radius.circular(10))),
                        ],
                      ),
                    )
                  : _resource == null
                      ? const Center(
                          child: Text('Ressource introuvable.',
                              style: TextStyle(color: AppColors.muted)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                          child: _buildContent(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final r = _resource!;
    final type = r['category'] as String?;
    final title = r['title'] as String? ?? '';
    final content = r['content'] as String? ?? '';
    final source = r['source'] as String?;
    final updatedAt = r['updated_at'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            (type ?? 'ressource').toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: 14),
        Text(title,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.title,
                height: 1.3)),
        if (updatedAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'Mis à jour · ${updatedAt.substring(0, 10)}',
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
        const SizedBox(height: 20),
        const Divider(color: AppColors.borderLight),
        const SizedBox(height: 16),
        Text(
          content,
          style:
              const TextStyle(fontSize: 15, color: AppColors.body, height: 1.7),
        ),
        if (source != null && source.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.link_rounded,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Source : $source',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.accent, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
