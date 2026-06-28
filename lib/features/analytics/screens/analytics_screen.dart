import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/sample/sample_extra.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

/// Insights — a calm, hand-built read of the user's week. A bar chart, a
/// completion ring and a category breakdown, all on the Aurora kit.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(analyticsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.bottomNavSpace,
          ),
          children: [
            AtlasHeader(
              title: 'Insights',
              subtitle: 'Your week at a glance',
              onBack: () => context.pop(),
            ),
            AppSpacing.gapLg,
            _StatRow(data: data),
            AppSpacing.gapLg,
            _WeeklyXpCard(data: data)
                .animate()
                .fadeIn(duration: AppMotion.medium)
                .slideY(
                  begin: 0.04,
                  end: 0,
                  duration: AppMotion.medium,
                  curve: AppMotion.standard,
                ),
            AppSpacing.gapMd,
            _CompletionCard(rate: data.completionRate)
                .animate(delay: AppMotion.fast)
                .fadeIn(duration: AppMotion.medium)
                .slideY(
                  begin: 0.04,
                  end: 0,
                  duration: AppMotion.medium,
                  curve: AppMotion.standard,
                ),
            AppSpacing.gapMd,
            _CategoryCard(categories: data.categories)
                .animate(delay: AppMotion.medium)
                .fadeIn(duration: AppMotion.medium)
                .slideY(
                  begin: 0.04,
                  end: 0,
                  duration: AppMotion.medium,
                  curve: AppMotion.standard,
                ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.data});
  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatTile(
              icon: Icons.bolt_rounded,
              color: AppColors.xpPrimary,
              value: '${data.totalXpWeek}',
              label: 'XP this week',
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: StatTile(
              icon: Icons.wb_twilight_rounded,
              color: AppColors.tertiary,
              value: data.bestDay,
              label: 'Best day',
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: StatTile(
              icon: Icons.check_circle_rounded,
              color: AppColors.secondary,
              value: '${(data.completionRate * 100).round()}%',
              label: 'Completion',
            ),
          ),
        ],
      ),
    );
  }
}

/// A title used at the top of a content card.
class _CardTitle extends StatelessWidget {
  const _CardTitle(this.title, {this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _WeeklyXpCard extends StatelessWidget {
  const _WeeklyXpCard({required this.data});
  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    return AtlasCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('XP this week', subtitle: 'Earned each day'),
          AppSpacing.gapLg,
          _WeeklyBars(values: data.weeklyXp, labels: data.weekdayLabels),
        ],
      ),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.values, required this.labels});
  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxV = values.fold<double>(0, (p, e) => e > p ? e : p);

    return SizedBox(
      height: 172,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final frac = maxV == 0 ? 0.0 : values[i] / maxV;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              child: Column(
                children: [
                  Expanded(child: _Bar(fraction: frac, index: i)),
                  AppSpacing.gapXs,
                  Text(
                    labels[i],
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.index});
  final double fraction;
  final int index;

  @override
  Widget build(BuildContext context) {
    final f = fraction.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: f),
      duration: AppMotion.slow + Duration(milliseconds: index * 60),
      curve: AppMotion.standard,
      builder: (context, v, _) => Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: v <= 0 ? 0.02 : v,
          widthFactor: 0.62,
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.auroraGradient,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusSm),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.rate});
  final double rate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (rate * 100).round();

    return AtlasCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          ProgressRing(
            progress: rate,
            size: 96,
            stroke: 9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$pct%',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'done',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          AppSpacing.hGapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardTitle('Completion'),
                AppSpacing.gapXs,
                Text(
                  'You finished $pct% of the tasks you set this week. Steady and kind to yourself.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.categories});
  final List<CategorySlice> categories;

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<double>(0, (p, e) => p + e.value);

    return AtlasCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Where your XP goes',
              subtitle: 'By category, this week'),
          AppSpacing.gapLg,
          for (var i = 0; i < categories.length; i++) ...[
            if (i > 0) AppSpacing.gapMd,
            _CategoryRow(slice: categories[i], total: total),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.slice, required this.total});
  final CategorySlice slice;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = total == 0 ? 0.0 : slice.value / total;
    final pct = (fraction * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: slice.color,
                shape: BoxShape.circle,
              ),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Text(
                slice.label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$pct%',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        AppSpacing.gapXs,
        AtlasProgressBar(fraction: fraction, height: 8, color: slice.color),
      ],
    );
  }
}
