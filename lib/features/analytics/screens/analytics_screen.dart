import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/shared/widgets/layout/adaptive_layout.dart';
import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/features/analytics/providers/analytics_view_provider.dart';
import 'package:atlas_flutter_app/features/aurora/data/year_in_review.dart';
import 'package:atlas_flutter_app/features/check_in/providers/check_in_providers.dart';
import 'package:atlas_flutter_app/features/check_in/widgets/check_in_sheet.dart';
import 'package:atlas_flutter_app/features/check_in/widgets/mood_strip.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/billing/widgets/premium_widgets.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Insights · Your week: one big number, ink bars with the best day in the
/// sunrise, then completion and where the XP came from.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  /// Weeks a free account can look back on (the current one plus three).
  static const freeWeeks = 4;

  Future<void> _pickWeek(BuildContext context, WidgetRef ref) async {
    final today = ref.read(todayProvider);
    final current = ref.read(selectedWeekProvider);
    final deep = ref.read(canDeepInsightsProvider);
    final thisWeek = startOfWeek(today);
    final picked = await showAtlasSheet<DateTime>(
      context,
      builder: (context) {
        final p = context.palette;
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * .6,
          child: ListView(
            padding: readableInsets(context, top: 0, bottom: AppSpacing.md),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, AppSpacing.md),
                child: Text('Pick a week', style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary)),
              ),
              for (var i = 0; i < 12; i++)
                () {
                  final monday = addDays(thisWeek, -7 * i);
                  final locked = !deep && i >= freeWeeks;
                  final selected = isSameDay(monday, current);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Consumer(builder: (context, ref, _) {
                      final xp = ref.watch(weekInsightsProvider(monday)).totalXp;
                      return AtlasRow(
                        minHeight: 58,
                        color: selected ? p.action : null,
                        leading: Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? p.onAction.withValues(alpha: .12) : p.track,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusIcon),
                          ),
                          child: Text('${isoWeek(monday)}',
                              style: AppTypography.chip.copyWith(color: selected ? p.onAction : p.textPrimary)),
                        ),
                        title: i == 0 ? 'This week' : (i == 1 ? 'Last week' : 'Week ${isoWeek(monday)}'),
                        titleStyle: AppTypography.rowTitle.copyWith(color: selected ? p.onAction : null),
                        metaWidget: Text(
                          dayRange(monday, addDays(monday, 6)),
                          style: AppTypography.meta.copyWith(
                              color: selected ? p.onAction.withValues(alpha: .7) : p.textMuted),
                        ),
                        trailing: locked
                            ? AtlasIcon(Symbols.lock_rounded, size: 18, color: p.textMuted)
                            : Text('$xp XP',
                                style: AppTypography.metaStrong
                                    .copyWith(color: selected ? p.onAction : p.textMuted)),
                        onTap: () {
                          if (locked) {
                            Navigator.of(context).pop();
                            context.push('/paywall');
                          } else {
                            Navigator.of(context).pop(monday);
                          }
                        },
                      );
                    }),
                  );
                }(),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      HapticFeedback.selectionClick();
      ref.read(selectedWeekProvider.notifier).set(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final week = ref.watch(selectedWeekProvider);
    final data = ref.watch(weekInsightsProvider(week));
    final deep = ref.watch(canDeepInsightsProvider);
    final best = data.bestIndex;
    final today = ref.watch(todayProvider);
    // The mood strip is the last 7 days, so it belongs with this week only.
    final thisWeek = isSameDay(week, startOfWeek(today));
    final moods = thisWeek ? ref.watch(weekMoodsProvider) : null;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: readableInsets(context, top: AppSpacing.xs, bottom: AppSpacing.xxl),
          children: [
            ScreenHeader(
              title: 'Your week',
              onBack: () => context.pop(),
              trailing: AtlasChip(
                label: 'Week ${data.isoWeekNumber}',
                onTap: () => _pickWeek(context, ref),
              ),
            ),
            if (YearInReview.inSeason(today)) ...[
              const SizedBox(height: 14),
              _YearCard(year: today.year),
            ],
            const SizedBox(height: 14),
            _HeroChart(data: data),
            const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: AtlasTile.raised(
                      context,
                      radius: AppSpacing.radiusLg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Best day',
                              style: AppTypography.metaStrong.copyWith(color: p.onRaised.withValues(alpha: .6))),
                          const SizedBox(height: 12),
                          best < 0
                              ? Text('Not yet', style: AppTypography.cardNumber.copyWith(color: p.onRaised))
                              : FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: GradientText(weekdayName(data.dayAt(best)),
                                      style: AppTypography.cardNumber),
                                ),
                          const SizedBox(height: 12),
                          Text(
                            best < 0
                                ? 'Your first tend sets it'
                                : '${data.xpByDay[best]} XP · ${data.tendedByDay[best]} tended',
                            style: AppTypography.meta.copyWith(color: p.onRaised.withValues(alpha: .7)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AtlasTile(
                      radius: AppSpacing.radiusLg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Completion', style: AppTypography.metaStrong.copyWith(color: p.textMuted)),
                          const SizedBox(height: 12),
                          CountUpText(
                            value: (data.completion * 100).round(),
                            suffix: '%',
                            animateFromZero: true,
                            style: AppTypography.cardNumber.copyWith(color: p.textPrimary),
                          ),
                          const Spacer(),
                          const SizedBox(height: 12),
                          GradientBar(value: data.completion),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Breakdown(data: data),
            if (moods != null) ...[
              const SizedBox(height: 14),
              WeekMoodStrip(
                moods: moods,
                today: today,
                onCheckIn: () => showCheckInSheet(context),
              ),
            ],
            const SizedBox(height: 14),
            AtlasTile(
              radius: AppSpacing.radiusLg,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  GroupRow(
                    icon: Symbols.calendar_view_day_rounded,
                    title: 'Day by day',
                    subtitle: 'Every day, with what you tended',
                    onTap: () => context.push('/progress'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: Divider(height: 1, color: p.hairline),
                  ),
                  GroupRow(
                    key: const ValueKey('your-year-row'),
                    icon: Symbols.auto_awesome_rounded,
                    title: 'Your year',
                    subtitle: 'Your ${today.year} in one card',
                    onTap: () => context.push('/year-in-review'),
                  ),
                ],
              ),
            ),
            if (!deep) ...[
              const SizedBox(height: 14),
              const UpgradeCtaCard(
                icon: Symbols.insights_rounded,
                title: 'See every week',
                subtitle: 'Full history, long-term trends and export.',
                actionLabel: 'Upgrade',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// December's invitation to "Your year": a compact ink card, shown from
/// December 1st (the Your year row below is there all year).
class _YearCard extends StatelessWidget {
  const _YearCard({required this.year});
  final int year;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      key: const ValueKey('your-year-card'),
      onTap: () => context.push('/year-in-review'),
      haptic: PressHaptic.selection,
      semanticLabel: 'Your $year, in one card',
      child: InkHeroCard(
        radius: AppSpacing.radiusTile,
        glowLevel: .4,
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GradientText('$year', style: AppTypography.cardNumber),
                  const SizedBox(height: 6),
                  Text('Your year, in one card',
                      style: AppTypography.rowTitle.copyWith(color: p.onRaised)),
                  const SizedBox(height: 2),
                  Text('Days tended, places found, how it felt',
                      style: AppTypography.meta
                          .copyWith(color: p.onRaised.withValues(alpha: .62))),
                ],
              ),
            ),
            AtlasIcon(Symbols.chevron_right_rounded,
                size: 22, color: p.onRaised.withValues(alpha: .62)),
          ],
        ),
      ),
    );
  }
}

class _HeroChart extends StatefulWidget {
  const _HeroChart({required this.data});
  final WeekInsights data;

  @override
  State<_HeroChart> createState() => _HeroChartState();
}

class _HeroChartState extends State<_HeroChart> {
  int? _selected;

  @override
  void didUpdateWidget(_HeroChart old) {
    super.didUpdateWidget(old);
    if (!isSameDay(old.data.weekStart, widget.data.weekStart)) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final data = widget.data;
    final trend = data.trendPercent;
    final best = data.bestIndex;
    final maxXp = data.xpByDay.fold<int>(0, (a, b) => a > b ? a : b);

    return GestureDetector(
      onTap: () => setState(() => _selected = null),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 18, 16),
        decoration: BoxDecoration(
          color: p.paper,
          borderRadius: BorderRadius.circular(AppSpacing.radiusChart),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CountUpText(
                        key: ValueKey(data.weekStart),
                        value: data.totalXp,
                        animateFromZero: true,
                        style: AppTypography.statNumber.copyWith(color: p.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text('XP earned this week',
                          style: AppTypography.sans(size: 13, weight: FontWeight.w600, color: p.textMuted)),
                    ],
                  ),
                ),
                if (trend != null)
                  TweenAnimationBuilder<double>(
                    key: ValueKey('trend-${data.weekStart}'),
                    tween: Tween(begin: 0, end: 1),
                    duration: AppMotion.medium,
                    curve: const Interval(.6, 1),
                    builder: (_, t, child) => Opacity(opacity: t, child: child),
                    child: trend >= 0
                        ? AtlasChip.success(context, '$trend%', icon: Symbols.arrow_upward_rounded)
                        : AtlasChip(label: '${-trend}% lighter week', background: p.track, dense: true),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _Bar(
                        index: i,
                        value: maxXp == 0 ? 0 : data.xpByDay[i] / maxXp,
                        best: i == best,
                        dim: _selected != null && _selected != i,
                        label: weekdayLetter(data.dayAt(i)),
                        weekKey: data.weekStart,
                        selected: _selected == i,
                        tooltip:
                            '${weekdayName(data.dayAt(i))}: ${data.xpByDay[i]} XP · ${data.tendedByDay[i]} tended',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selected = _selected == i ? null : i);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.index,
    required this.value,
    required this.best,
    required this.dim,
    required this.label,
    required this.weekKey,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final int index;
  final double value;
  final bool best;
  final bool dim;
  final String label;
  final DateTime weekKey;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  static const _maxBar = 128.0;
  static const _minBar = 10.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduce = AppMotion.reduceMotion(context);
    final target = value <= 0 ? _minBar : _minBar + (_maxBar - _minBar) * value;

    Widget bar(double h) => AnimatedOpacity(
          duration: AppMotion.fast,
          opacity: dim ? .4 : 1,
          child: Container(
            height: h,
            decoration: BoxDecoration(
              color: best ? null : (value <= 0 ? p.track : p.chartBar),
              gradient: best ? AppColors.sunriseVertical : null,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );

    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                reduce
                    ? bar(target)
                    // Grows from 0 on first appear (staggered); a week change
                    // just tweens to the new height.
                    : TweenAnimationBuilder<double>(
                        key: ValueKey('bar-$index'),
                        tween: Tween(begin: 0, end: target),
                        duration: AppMotion.slow + AppMotion.barStagger * index,
                        curve: Interval(index * .05, 1, curve: AppMotion.standard),
                        builder: (_, h, _) => bar(h),
                      ),
                const SizedBox(height: 8),
                Text(label,
                    style: AppTypography.metaStrong.copyWith(
                      color: best ? AtlasPalette.accent : p.textMuted,
                    )),
              ],
            ),
            if (selected)
              Positioned(
                bottom: target + 30,
                child: _Tooltip(text: tooltip, alignRight: index > 3),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tooltip extends StatelessWidget {
  const _Tooltip({required this.text, required this.alignRight});
  final String text;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return FractionalTranslation(
      translation: Offset(alignRight ? -.35 : .35, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: p.raised,
          border: p.raisedBorderSide,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text,
            maxLines: 1,
            softWrap: false,
            style: AppTypography.metaStrong.copyWith(color: p.onRaised)),
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.data});
  final WeekInsights data;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final total = data.categories.fold<int>(0, (a, c) => a + c.xp);
    return AtlasTile(
      radius: AppSpacing.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where your XP came from',
              style: AppTypography.sans(size: 14, weight: FontWeight.w700, color: p.textPrimary)),
          const SizedBox(height: 12),
          if (total == 0)
            Text('Tend something and it shows up here.',
                style: AppTypography.meta.copyWith(color: p.textMuted))
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < data.categories.length; i++) ...[
                      if (i > 0) const SizedBox(width: 3),
                      Expanded(
                        flex: (data.categories[i].xp * 1000 / total).round().clamp(1, 1000),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: AppMotion.slow,
                          curve: AppMotion.standard,
                          builder: (_, t, _) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: AppMotion.reduceMotion(context) ? 1 : t,
                            child: ColoredBox(color: p.category(data.categories[i].color)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                for (final c in data.categories)
                  LegendDot(color: p.category(c.color), label: '${c.label} ${c.xp}'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
