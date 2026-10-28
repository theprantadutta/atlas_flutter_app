import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/features/aurora/widgets/aurora_nudge_card.dart';
import 'package:atlas_flutter_app/features/check_in/data/check_in_repository.dart';
import 'package:atlas_flutter_app/features/check_in/providers/check_in_providers.dart';
import 'package:atlas_flutter_app/features/check_in/widgets/check_in_sheet.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// The one Aurora-ish card under the hero on Home. The check-in card wins
/// when it's due; the nudge waits its turn (it isn't dismissed, just held
/// back), so Home never has two cards asking for attention at once.
class HomeAuroraSlot extends ConsumerStatefulWidget {
  const HomeAuroraSlot({super.key});

  @override
  ConsumerState<HomeAuroraSlot> createState() => _HomeAuroraSlotState();
}

class _HomeAuroraSlotState extends ConsumerState<HomeAuroraSlot> {
  late final AppLifecycleListener _lifecycle;
  Timer? _boundary;

  @override
  void initState() {
    super.initState();
    // The prompt reads the clock only when it rebuilds: refresh it when the
    // app comes back and when the morning or evening window opens or closes.
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    _scheduleBoundary();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _boundary?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    ref.invalidate(checkInPromptProvider);
    _scheduleBoundary();
  }

  void _scheduleBoundary() {
    _boundary?.cancel();
    final now = DateTime.now();
    final next = nextCheckInBoundary(now);
    _boundary = Timer(next.difference(now), _refresh);
  }

  @override
  Widget build(BuildContext context) {
    final moment = ref.watch(checkInPromptProvider);
    if (moment == null) return const AuroraNudgeCard();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: CheckInCard(
        moment: moment,
        onOpen: () => showCheckInSheet(context, moment: moment),
        onDismiss: () =>
            ref.read(checkInDismissalsProvider.notifier).dismiss(moment),
      ),
    );
  }
}

/// The next time the check-in window changes after [now]: 12:00, 17:00 or
/// midnight (plus a second, so the clock has clearly moved on).
DateTime nextCheckInBoundary(DateTime now) {
  final day = DateTime(now.year, now.month, now.day);
  for (final h in const [12, 17, 24]) {
    final at = day.add(Duration(hours: h, seconds: 1));
    if (at.isAfter(now)) return at;
  }
  return day.add(const Duration(hours: 24, seconds: 1));
}

/// "How are you starting the day?": a calm paper row with a gentle way in
/// and a way out for today.
class CheckInCard extends StatelessWidget {
  const CheckInCard({
    super.key,
    required this.moment,
    required this.onOpen,
    required this.onDismiss,
  });

  final CheckInMoment moment;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final morning = moment == CheckInMoment.morning;
    final title = morning ? 'Morning check-in' : 'Evening check-in';
    final question =
        morning ? 'How are you starting the day?' : 'How did today feel?';
    return Pressable(
      key: const ValueKey('check-in-card'),
      onTap: onOpen,
      haptic: PressHaptic.selection,
      semanticLabel: '$title. $question',
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        decoration: BoxDecoration(
          color: p.paper,
          borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
        ),
        child: Row(
          children: [
            IconTile(
              style: morning
                  ? const CategoryStyle(
                      Symbols.wb_twilight_rounded, AppColors.amber)
                  : const CategoryStyle(
                      Symbols.bedtime_rounded, AppColors.violet),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(question,
                      style: AppTypography.sans(
                          size: 14,
                          weight: FontWeight.w700,
                          height: 1.3,
                          color: p.textPrimary)),
                  const SizedBox(height: 2),
                  Text(title,
                      style: AppTypography.meta.copyWith(color: p.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            PillButton(label: 'Check in', height: 36, onTap: onOpen),
            Pressable(
              key: const ValueKey('check-in-dismiss'),
              onTap: onDismiss,
              circle: true,
              haptic: PressHaptic.selection,
              semanticLabel: 'Not today',
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: AtlasIcon(Symbols.close_rounded,
                    size: 18, color: p.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
