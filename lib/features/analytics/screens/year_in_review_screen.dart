import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/features/aurora/data/year_in_review.dart';
import 'package:atlas_flutter_app/features/aurora/providers/aurora_companion_providers.dart';
import 'package:atlas_flutter_app/features/check_in/data/check_in_repository.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';
import 'package:atlas_flutter_app/shared/widgets/layout/adaptive_layout.dart';

/// "Your year": computed on the device (no AI, free for everyone) and drawn
/// as one ink card that can be shared as an image.
class YearInReviewScreen extends ConsumerStatefulWidget {
  const YearInReviewScreen({super.key, this.year});

  /// Defaults to the current year.
  final int? year;

  @override
  ConsumerState<YearInReviewScreen> createState() =>
      _YearInReviewScreenState();
}

class _YearInReviewScreenState extends ConsumerState<YearInReviewScreen> {
  final _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share(int year) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/atlas-year-$year.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: 'My $year in Atlas',
        sharePositionOrigin: origin,
      ));
    } catch (_) {
      if (mounted) AtlasToast.info(context, "Couldn't share right now");
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final year = widget.year ?? ref.watch(todayProvider).year;
    final review = ref.watch(yearInReviewProvider(year));
    final data = review.value;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: readableInsets(context,
              top: AppSpacing.xs, bottom: AppSpacing.xxl),
          children: [
            ScreenHeader(
              title: 'Your year',
              onBack: () {
                if (context.canPop()) context.pop();
              },
            ),
            const SizedBox(height: 14),
            if (review.isLoading && data == null)
              const Skeleton(height: 520, radius: AppSpacing.radiusXl)
            else if (data == null)
              EmptyState(
                title: "Your year couldn't load.",
                body: 'Pull it up again in a moment.',
                actionLabel: 'Try again',
                onAction: () => ref.invalidate(yearInReviewProvider(year)),
              )
            else if (data.isEmpty)
              EmptyState(
                title: 'Your $year starts with one day.',
                body:
                    'Tend something, discover a place or check in, and your year fills in here.',
              )
            else ...[
              RepaintBoundary(
                key: _cardKey,
                child: YearInReviewCard(review: data),
              ),
              const SizedBox(height: AppSpacing.md),
              PillButton(
                label: 'Share your year',
                icon: Symbols.ios_share_rounded,
                height: 52,
                expand: true,
                haptic: PressHaptic.medium,
                busy: _sharing,
                onTap: () => _share(year),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Made on your phone from your own days. Only you see it unless you share it.',
                  textAlign: TextAlign.center,
                  style: AppTypography.meta.copyWith(color: p.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// The shareable card: ink, the sunrise glow, big Funnel Display numbers.
class YearInReviewCard extends StatelessWidget {
  const YearInReviewCard({super.key, required this.review});
  final YearInReview review;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final soft = p.onRaised.withValues(alpha: .62);
    final r = review;
    final best = r.bestMonth;

    return InkHeroCard(
      glowLevel: 1,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR ${r.year}',
              style: AppTypography.kicker.copyWith(color: soft)),
          const SizedBox(height: AppSpacing.lg),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(groupThousands(r.daysTended),
                key: const ValueKey('yir-days'),
                style: AppTypography.heroNumber.copyWith(color: p.onRaised)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(r.daysTended == 1 ? 'day tended' : 'days tended',
              style: AppTypography.subtitle.copyWith(color: soft)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                  child: _Stat(
                      value: groupThousands(r.totalXp), label: 'XP earned')),
              Expanded(
                child: _Stat(
                  value: '${r.longestStreak}',
                  label: r.longestStreak == 1
                      ? 'day, longest streak'
                      : 'days, longest streak',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  value: '${r.placesDiscovered}',
                  label: r.placesDiscovered == 1
                      ? 'place discovered'
                      : 'places discovered',
                ),
              ),
              Expanded(
                child: best == null
                    ? const _Stat(value: 'Soon', label: 'best month')
                    : _Stat(
                        value: monthName(DateTime(r.year, best)),
                        label: 'best month, ${groupThousands(r.bestMonthXp)} XP',
                        highlight: true,
                      ),
              ),
            ],
          ),
          if (r.topHabits.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _Divider(color: p.onRaised.withValues(alpha: .12)),
            const SizedBox(height: AppSpacing.md),
            Text('What you came back to',
                style: AppTypography.metaStrong.copyWith(color: soft)),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < r.topHabits.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text('${i + 1}',
                          style: AppTypography.metaStrong.copyWith(color: soft)),
                    ),
                    Expanded(
                      child: Text(r.topHabits[i].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.rowTitle
                              .copyWith(color: p.onRaised)),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                        '${r.topHabits[i].completions} ${r.topHabits[i].completions == 1 ? 'day' : 'days'}',
                        style: AppTypography.metaStrong.copyWith(color: soft)),
                  ],
                ),
              ),
          ],
          if (r.hasMoods) ...[
            const SizedBox(height: AppSpacing.md),
            _Divider(color: p.onRaised.withValues(alpha: .12)),
            const SizedBox(height: AppSpacing.md),
            Text('How it felt',
                style: AppTypography.metaStrong.copyWith(color: soft)),
            const SizedBox(height: AppSpacing.sm),
            _MoodSplit(split: r.moodSplit),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const AtlasSpark(size: 16),
              const SizedBox(width: 6),
              Text('Atlas',
                  style: AppTypography.display(
                      size: 15, weight: FontWeight.w700, color: p.onRaised)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.highlight = false});
  final String value;
  final String label;

  /// The best month is a best-day highlight: it gets the sunrise.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = AppTypography.cardNumber;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: highlight
                ? GradientText(value, style: style)
                : Text(value, style: style.copyWith(color: p.onRaised)),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: AppTypography.meta
                  .copyWith(color: p.onRaised.withValues(alpha: .62))),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: color);
}

/// The year's moods as one calm bar (no order of better or worse is implied
/// beyond the words themselves) with a legend.
class _MoodSplit extends StatelessWidget {
  const _MoodSplit({required this.split});
  final Map<int, int> split;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final moods = split.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          child: SizedBox(
            height: 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < moods.length; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Expanded(
                    flex: split[moods[i]]!.clamp(1, 1 << 20),
                    child: ColoredBox(color: p.mood(moods[i])),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 14,
          runSpacing: AppSpacing.xs,
          children: [
            for (final m in moods)
              _OnRaisedLegend(
                color: p.mood(m),
                label: '${CheckInMood.labels[m]} ${split[m]}',
              ),
          ],
        ),
      ],
    );
  }
}

class _OnRaisedLegend extends StatelessWidget {
  const _OnRaisedLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: AppTypography.metaStrong
                .copyWith(color: p.onRaised.withValues(alpha: .8))),
      ],
    );
  }
}

/// 12340 -> "12,340".
String groupThousands(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}
