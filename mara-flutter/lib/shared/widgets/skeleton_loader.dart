import 'package:flutter/material.dart';
import 'package:mara_flutter/core/theme/app_theme.dart';

// ── Animated shimmer skeleton ─────────────────────────────────────────────────
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? radius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.radius ?? AppRadius.sm,
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: const [
              Color(0xFFECEFF4),
              Color(0xFFF8F9FC),
              Color(0xFFECEFF4),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

// ── Card skeleton (liste génériques) ─────────────────────────────────────────
class SkeletonCard extends StatelessWidget {
  final double iconSize;
  final int lines;
  const SkeletonCard({super.key, this.iconSize = 48, this.lines = 2});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
            width: iconSize,
            height: iconSize,
            radius: BorderRadius.circular(14),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(height: 13, radius: BorderRadius.circular(6)),
                const SizedBox(height: 8),
                if (lines >= 2) ...[
                  SkeletonLoader(
                    width: double.infinity,
                    height: 11,
                    radius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 6),
                ],
                if (lines >= 3)
                  SkeletonLoader(
                    width: 120,
                    height: 11,
                    radius: BorderRadius.circular(6),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat card skeleton ────────────────────────────────────────────────────────
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});

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
          SkeletonLoader(
              width: 44, height: 44, radius: BorderRadius.circular(12)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                    width: 48, height: 22, radius: BorderRadius.circular(6)),
                const SizedBox(height: 6),
                SkeletonLoader(
                    width: 80, height: 10, radius: BorderRadius.circular(4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── List skeleton builder ─────────────────────────────────────────────────────
class SkeletonList extends StatelessWidget {
  final int count;
  final double spacing;
  const SkeletonList({super.key, this.count = 5, this.spacing = 12});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: count,
      separatorBuilder: (_, __) => SizedBox(height: spacing),
      itemBuilder: (_, __) => const SkeletonCard(),
    );
  }
}
