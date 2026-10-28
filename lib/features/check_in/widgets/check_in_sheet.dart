import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart' show CheckIn;
import 'package:atlas_flutter_app/features/check_in/data/check_in_repository.dart';
import 'package:atlas_flutter_app/features/check_in/providers/check_in_providers.dart';
import 'package:atlas_flutter_app/features/check_in/widgets/mood_orb.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Opens the daily check-in sheet for [moment] (by default the one that fits
/// the time of day). Saving again for a moment that's already done edits it.
Future<void> showCheckInSheet(BuildContext context, {CheckInMoment? moment}) {
  // A fresh sheet never shows the last one's reply.
  ProviderScope.containerOf(context, listen: false)
      .read(checkInControllerProvider.notifier)
      .reset();
  return showAtlasSheet<void>(
    context,
    builder: (_) => CheckInSheet(moment: moment),
  );
}

/// The moment a check-in opened at [now] is for: morning before 12:00,
/// evening from 17:00; in between, the morning until it's done.
CheckInMoment checkInMomentFor(DateTime now, {Set<CheckInMoment> done = const {}}) {
  if (now.hour < 12) return CheckInMoment.morning;
  if (now.hour >= 17) return CheckInMoment.evening;
  return done.contains(CheckInMoment.morning)
      ? CheckInMoment.evening
      : CheckInMoment.morning;
}

/// The quiet line shown when a reply isn't available (402 or offline).
const checkInPremiumLine = 'Aurora’s replies are part of Atlas Aurora';

class CheckInSheet extends ConsumerStatefulWidget {
  const CheckInSheet({super.key, this.moment, this.clock});

  final CheckInMoment? moment;

  /// Injectable for tests.
  final DateTime Function()? clock;

  @override
  ConsumerState<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends ConsumerState<CheckInSheet> {
  final _note = TextEditingController();
  int? _mood;
  bool _touched = false;
  bool _submitted = false;
  CheckInMoment? _resolvedMoment;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  CheckInMoment _moment(List<CheckIn> today) {
    if (widget.moment case final m?) return m;
    return _resolvedMoment ??= checkInMomentFor(
      (widget.clock ?? DateTime.now)(),
      done: {for (final c in today) CheckInMoment.fromWire(c.moment)},
    );
  }

  Future<void> _save(CheckInMoment moment) async {
    final mood = _mood;
    if (mood == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    await ref.read(checkInControllerProvider.notifier).save(
          mood: mood,
          moment: moment,
          note: _note.text,
        );
  }

  void _openPaywall() {
    final router = GoRouter.maybeOf(context);
    Navigator.of(context).pop();
    router?.push('/paywall');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final today = ref.watch(todayCheckInsProvider).value ?? const <CheckIn>[];
    final moment = _moment(today);
    final existing = today
        .where((c) => c.moment == moment.wire && !c.isDeleted)
        .firstOrNull;

    // Editing: start from what was saved, until the user changes something.
    if (!_touched && existing != null && _mood == null) {
      _mood = existing.mood;
      _note.text = existing.note ?? '';
    }

    final state = ref.watch(checkInControllerProvider);
    final reduce = AppMotion.reduceMotion(context);
    final showSaved = _submitted && !state.saving && state.checkIn != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
      child: AnimatedSwitcher(
        duration: reduce ? Duration.zero : AppMotion.medium,
        switchInCurve: AppMotion.standard,
        switchOutCurve: AppMotion.standard,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: showSaved
            ? _Saved(
                key: const ValueKey('saved'),
                state: state,
                onPremium: _openPaywall,
                onDone: () => Navigator.of(context).pop(),
              )
            : Column(
                key: const ValueKey('form'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Heading(moment: moment, editing: existing != null),
                  const SizedBox(height: AppSpacing.lg - 4),
                  _MoodChoices(
                    selected: _mood,
                    onSelect: (m) => setState(() {
                      _touched = true;
                      _mood = m;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _NoteField(
                    controller: _note,
                    onChanged: () => _touched = true,
                    onSubmit: () => _save(moment),
                  ),
                  const SizedBox(height: AppSpacing.lg - 4),
                  PillButton(
                    label: existing != null ? 'Save changes' : 'Save',
                    height: 52,
                    expand: true,
                    haptic: PressHaptic.medium,
                    busy: state.saving,
                    onTap: _mood == null ? null : () => _save(moment),
                  ),
                  if (_mood == null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text('Pick the word that fits best. Any answer is a good one.',
                        textAlign: TextAlign.center,
                        style: AppTypography.meta.copyWith(color: p.textMuted)),
                  ],
                ],
              ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.moment, required this.editing});
  final CheckInMoment moment;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final morning = moment == CheckInMoment.morning;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.headerInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(morning ? 'MORNING CHECK-IN' : 'EVENING CHECK-IN',
              style: AppTypography.kicker.copyWith(color: p.textMuted)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            morning ? 'How are you starting the day?' : 'How did today feel?',
            style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary),
          ),
          if (editing) ...[
            const SizedBox(height: 6),
            Text('You checked in earlier. Change anything you like.',
                style: AppTypography.meta.copyWith(color: p.textMuted)),
          ],
        ],
      ),
    );
  }
}

class _MoodChoices extends StatelessWidget {
  const _MoodChoices({required this.selected, required this.onSelect});
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var m = CheckInMood.heavy; m <= CheckInMood.bright; m++) ...[
          if (m > CheckInMood.heavy) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _MoodChoice(
              mood: m,
              selected: selected == m,
              onTap: () => onSelect(m),
            ),
          ),
        ],
      ],
    );
  }
}

class _MoodChoice extends StatelessWidget {
  const _MoodChoice({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final int mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = CheckInMood.labels[mood]!;
    final reduce = AppMotion.reduceMotion(context);
    return Semantics(
      selected: selected,
      child: Pressable(
        key: ValueKey('mood-$mood'),
        onTap: onTap,
        haptic: PressHaptic.selection,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : AppMotion.fast,
          curve: AppMotion.standard,
          height: 96,
          decoration: BoxDecoration(
            color: selected ? p.raised : p.paper,
            border: selected ? p.raisedBorderSide : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MoodOrb(
                // Rebuilding the orb on select lets the sun rise again.
                key: ValueKey('orb-$mood-$selected'),
                mood: mood,
                size: 42,
                animate: selected,
                horizon: selected ? p.onRaised.withValues(alpha: .35) : null,
              ),
              const SizedBox(height: 6),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: AppTypography.sans(
                    size: 12,
                    weight: FontWeight.w700,
                    height: 1,
                    color: selected ? p.onRaised : p.textSecondary,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteField extends StatefulWidget {
  const _NoteField({
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  /// The counter appears only as the note nears the cap.
  static const _counterFrom = 160;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final length = widget.controller.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: p.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: TextField(
            key: const ValueKey('check-in-note'),
            controller: widget.controller,
            maxLines: 1,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              LengthLimitingTextInputFormatter(CheckInRepository.maxNote),
            ],
            onChanged: (_) {
              widget.onChanged();
              setState(() {});
            },
            onSubmitted: (_) => widget.onSubmit(),
            style: AppTypography.sans(size: 15, color: p.textPrimary),
            decoration: InputDecoration(
              hintText: 'A few words, if you like',
              hintStyle: AppTypography.sans(size: 15, color: p.textFaint),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (length >= _counterFrom)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
            child: Text('$length/${CheckInRepository.maxNote}',
                style: AppTypography.tiny.copyWith(color: p.textMuted)),
          ),
      ],
    );
  }
}

/// After saving: the mood, then Aurora's reply as it arrives.
class _Saved extends StatelessWidget {
  const _Saved({
    super.key,
    required this.state,
    required this.onPremium,
    required this.onDone,
  });

  final CheckInState state;
  final VoidCallback onPremium;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final row = state.checkIn!;
    final label = CheckInMood.labels[row.mood] ?? '';
    final reduce = AppMotion.reduceMotion(context);

    final Widget reply;
    if (state.awaitingReply) {
      reply = _ReplyPanel(
        key: const ValueKey('awaiting'),
        busy: true,
        child: Text('Aurora is reading your check-in',
            style: AppTypography.sans(
                size: 14, weight: FontWeight.w600, color: p.textSecondary)),
      );
    } else if (state.reply case final text?) {
      reply = _ReplyPanel(
        key: const ValueKey('reply'),
        child: Text(text,
            style: AppTypography.bubble.copyWith(color: p.textPrimary)),
      );
    } else if (state.showRepliesArePremiumLine) {
      reply = Pressable(
        key: const ValueKey('premium'),
        onTap: onPremium,
        haptic: PressHaptic.selection,
        semanticLabel: checkInPremiumLine,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.headerInset, vertical: AppSpacing.xs),
          child: Row(
            children: [
              const AtlasSpark(size: 16, variant: SparkVariant.ink),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(checkInPremiumLine,
                    style: AppTypography.meta.copyWith(color: p.textMuted)),
              ),
              AtlasIcon(Symbols.chevron_right_rounded,
                  size: 18, color: p.chevron),
            ],
          ),
        ),
      );
    } else {
      reply = const SizedBox.shrink(key: ValueKey('none'));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.headerInset),
          child: Row(
            children: [
              MoodOrb(mood: row.mood, size: 56),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTypography.subScreenTitle
                            .copyWith(color: p.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Saved. Thank you for checking in.',
                        style: AppTypography.meta
                            .copyWith(color: p.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedSwitcher(
          duration: reduce ? Duration.zero : AppMotion.medium,
          switchInCurve: AppMotion.standard,
          child: reply,
        ),
        const SizedBox(height: AppSpacing.md),
        PillButton(
          label: 'Done',
          height: 52,
          expand: true,
          variant: PillVariant.track,
          onTap: onDone,
        ),
      ],
    );
  }
}

/// Aurora's reply on the soft letter tint, with her spark.
class _ReplyPanel extends StatelessWidget {
  const _ReplyPanel({super.key, required this.child, this.busy = false});
  final Widget child;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: p.letter,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtlasSpark(size: 22, busy: busy, animated: !busy),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: child),
        ],
      ),
    );
  }
}
