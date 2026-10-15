import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/features/aurora/widgets/aurora_nudge_card.dart';
import 'package:atlas_flutter_app/features/aurora/widgets/quick_add_sheet.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/grow/widgets/item_actions.dart';
import 'package:atlas_flutter_app/features/home/providers/home_prefs.dart';
import 'package:atlas_flutter_app/features/home/providers/home_provider.dart';
import 'package:atlas_flutter_app/features/notifications/providers/notification_providers.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/starter_data_provider.dart';
import 'package:atlas_flutter_app/features/onboarding/widgets/coach_marks.dart';
import 'package:atlas_flutter_app/features/onboarding/widgets/starter_choice_sheet.dart';
import 'package:atlas_flutter_app/features/updates/widgets/update_banner.dart';
import 'package:atlas_flutter_app/shared/widgets/aurora_nav_bar.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Home: how today is going, and the next thing to tend.
///
/// One ink hero card with a drifting glow, XP and Aurora's letter side by
/// side, then only what's up next, each with a one-tap Tend.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Items mid-exit from "Up next": shown done (tended) or plain (later),
  /// then collapsed, then dropped.
  final Map<String, ({TodayItem item, bool tended})> _leaving = {};
  final Set<String> _collapsing = {};
  final Map<String, GlobalKey> _rowKeys = {};

  bool _celebrating = false;
  int _burst = 0;
  int _streakPulse = 0;
  int? _lastTended;

  GlobalKey _keyFor(String id) => _rowKeys.putIfAbsent(id, GlobalKey.new);

  /// The first-run "examples or empty?" question, asked once.
  static bool _starterAsked = false;

  void _maybeAskStarter() {
    if (_starterAsked) return;
    final starter = ref.read(starterDataProvider);
    final onboarding = ref.read(onboardingProvider);
    if (!starter.loaded || starter.choiceMade || !onboarding.setupComplete) return;
    _starterAsked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showStarterChoiceSheet(context, ref);
    });
  }

  Future<void> _leave(TodayItem item, {required bool tended}) async {
    setState(() => _leaving[item.id] = (item: item, tended: tended));
    await Future<void>.delayed(tended ? const Duration(milliseconds: 400) : AppMotion.instant);
    if (!mounted) return;
    setState(() => _collapsing.add(item.id));
    await Future<void>.delayed(AppMotion.fast);
    if (!mounted) return;
    setState(() {
      _leaving.remove(item.id);
      _collapsing.remove(item.id);
    });
  }

  Future<void> _tend(TodayItem item) async {
    final tend = ref.read(tendControllerProvider);
    final key = _keyFor(item.id);
    XpFloat.fromKey(context, key, item.xp);
    unawaited(_leave(item, tended: true));
    final outcome = item.task != null
        ? await tend.tendTask(item.task!)
        : await tend.tendHabit(item.habit!);
    await ref.read(snoozeProvider.notifier).clear(item.id);
    if (!mounted || outcome == null) return;
    final level = outcome.leveledUpTo;
    AtlasToast.undo(
      context,
      level != null ? 'Level $level. +${outcome.xp} XP' : 'Tended · +${outcome.xp} XP',
      onUndo: outcome.undo,
    );
    if (level != null) HapticFeedback.mediumImpact();
  }

  Future<void> _later(TodayItem item) async {
    unawaited(_leave(item, tended: false));
    await ref.read(snoozeProvider.notifier).snooze(item.id);
    if (!mounted) return;
    final until = ref.read(snoozeProvider)[item.id];
    AtlasToast.undo(
      context,
      until == null ? 'Later' : 'Back at ${clockLabel(until.hour, until.minute)}',
      onUndo: () => ref.read(snoozeProvider.notifier).clear(item.id),
    );
  }

  void _maybeCelebrate(HomeView view) {
    final notifier = ref.read(dayCompleteProvider.notifier);
    if (!view.dayComplete || !notifier.loaded || notifier.celebratedOn(view.today)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await notifier.markCelebrated(view.today);
      HapticFeedback.heavyImpact();
      setState(() {
        _celebrating = true;
        _burst++;
      });
      await Future<void>.delayed(const Duration(milliseconds: 2600));
      if (mounted) setState(() => _celebrating = false);
    });
  }

  void _maybePulseStreak(HomeView view) {
    final n = view.stats.tendedToday;
    if (_lastTended == 0 && n > 0) _streakPulse++;
    _lastTended = n;
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(homeProvider);
    ref.watch(dayCompleteProvider);
    ref.watch(dailyRolloverProvider);
    ref.watch(starterDataProvider);
    _maybeAskStarter();
    _maybeCelebrate(view);
    _maybePulseStreak(view);
    final unread = ref.watch(unreadNotificationCountProvider).value ?? 0;
    final coachKeys = ref.watch(coachMarkKeysProvider);

    // Up next: what's leaving stays in place while it animates out.
    final remaining = view.remaining.where((i) => !_leaving.containsKey(i.id)).toList();
    final shown = <({TodayItem item, bool tended})>[
      ..._leaving.values,
      for (final i in remaining) (item: i, tended: false),
    ].take(2 + _leaving.length).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          controller: ref.watch(tabScrollControllersProvider).of(0),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.sm,
            AppSpacing.gutter,
            navScrollPadding(context),
          ),
          children: [
            _Header(
              date: longDate(view.today),
              name: view.firstName,
              unread: unread > 0,
              onBell: () => context.push('/notifications'),
              onAvatar: () => context.go('/profile'),
            ),
            const SizedBox(height: 14),
            const UpdateBanner(),
            _Hero(
              key: coachKeys.hero,
              view: view,
              celebrating: _celebrating,
              burst: _burst,
              streakPulse: _streakPulse,
              onTap: () => context.push('/progress'),
            ),
            const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _XpTile(
                      stats: view.stats,
                      onTap: () => context.push('/analytics'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LetterTile(
                      state: view.letter,
                      onTap: () => context.go('/aurora'),
                    ),
                  ),
                ],
              ),
            ),
            const AuroraNudgeCard(),
            const SizedBox(height: 14),
            if (view.total == 0)
              EmptyState(
                title: 'Nothing planned for today.',
                body: 'Add one small thing you’d like to tend.',
                actionLabel: 'Add something',
                onAction: () => showQuickAddSheet(context),
              )
            else if (shown.isEmpty)
              _DayDone(onAdd: () => showQuickAddSheet(context))
            else ...[
              SectionTitle(
                'Up next',
                action: 'See all ${view.remaining.length}',
                onAction: () => context.go('/grow'),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < shown.length; i++)
                CollapseOut(
                  key: ValueKey('upnext-${shown[i].item.id}'),
                  collapsed: _collapsing.contains(shown[i].item.id),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: EntryFade(
                      id: 'home-${shown[i].item.id}',
                      index: i,
                      child: _UpNextRow(
                        key: _keyFor(shown[i].item.id),
                        item: shown[i].item,
                        primary: i == 0,
                        tended: shown[i].tended,
                        onTend: () => _tend(shown[i].item),
                        onLater: () => _later(shown[i].item),
                        onLongPress: () => showItemMenu(
                          context,
                          ref,
                          task: shown[i].item.task,
                          habit: shown[i].item.habit,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  const _Header({
    required this.date,
    required this.name,
    required this.unread,
    required this.onBell,
    required this.onAvatar,
  });

  final String date;
  final String name;
  final bool unread;
  final VoidCallback onBell;
  final VoidCallback onAvatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.headerInset),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: AppTypography.dateLine.copyWith(color: p.textMuted)),
                const SizedBox(height: 2),
                Semantics(
                  header: true,
                  child: Text(
                    'Hey $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.greeting.copyWith(color: p.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          CircleIconButton(
            icon: Symbols.notifications_rounded,
            badge: unread,
            semanticLabel: unread ? 'Notifications, unread' : 'Notifications',
            onTap: onBell,
          ),
          const SizedBox(width: AppSpacing.xs),
          AvatarRing(name: name, onTap: onAvatar),
        ],
      ),
    );
  }
}

// ─── Hero ───────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({
    super.key,
    required this.view,
    required this.celebrating,
    required this.burst,
    required this.streakPulse,
    required this.onTap,
  });

  final HomeView view;
  final bool celebrating;
  final int burst;
  final int streakPulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = p.onRaised;
    final streak = view.stats.streak;

    return Pressable(
      onTap: onTap,
      scale: .98,
      semanticLabel: view.total == 0
          ? 'Today, nothing planned yet'
          : 'Today, ${view.percent} percent, ${view.done} of ${view.total} tended',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 236),
        child: InkHeroCard(
          glowLevel: view.progress,
          celebrate: celebrating,
          child: SizedBox(
            height: 236 - 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('Today',
                        style: AppTypography.dateLine.copyWith(color: on.withValues(alpha: .7))),
                    const Spacer(),
                    if (streak > 0)
                      _Pulse(
                        trigger: streakPulse,
                        child: AtlasChip(
                          label: '$streak ${streak == 1 ? 'day' : 'days'}',
                          icon: Symbols.local_fire_department_rounded,
                          iconColor: AppColors.sunriseA,
                          background: on.withValues(alpha: .12),
                          foreground: on,
                          dense: true,
                        ),
                      ),
                  ],
                ),
                if (view.total == 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('A fresh day.',
                          style: AppTypography.display(size: 40, color: on)),
                      const SizedBox(height: 8),
                      Text('Add one small thing to tend.',
                          style: AppTypography.subtitle.copyWith(color: on.withValues(alpha: .75))),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CountUpText(
                                value: view.percent,
                                style: AppTypography.heroNumber.copyWith(color: on),
                              ),
                              GradientText('%', style: AppTypography.heroNumber),
                              const SizedBox(width: 10),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: AnimatedSwitcher(
                                  duration: AppMotion.fast,
                                  child: Text(
                                    view.dayComplete
                                        ? 'All\ntended'
                                        : '${view.done} of ${view.total}\ntended',
                                    key: ValueKey(view.dayComplete),
                                    style: AppTypography.sans(
                                      size: 15,
                                      weight: FontWeight.w600,
                                      height: 1.3,
                                      tabular: true,
                                      color: on.withValues(alpha: .75),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            left: -20,
                            top: -40,
                            child: SparkBurst(trigger: burst),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ProgressSegments(total: view.total, done: view.done),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Scales its child 1 → 1.08 → 1 once each time [trigger] changes.
class _Pulse extends StatelessWidget {
  const _Pulse({required this.trigger, required this.child});
  final int trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (trigger == 0 || AppMotion.reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(trigger),
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.medium,
      builder: (_, t, child) => Transform.scale(
        scale: 1 + .08 * (t < .5 ? t * 2 : (1 - t) * 2),
        child: child,
      ),
      child: child,
    );
  }
}

// ─── Tiles ──────────────────────────────────────────────────────────

class _XpTile extends StatelessWidget {
  const _XpTile({required this.stats, required this.onTap});
  final PlayerStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lvl = stats.level;
    final meta = AppTypography.metaStrong.copyWith(color: p.textMuted);
    return AtlasTile(
      onTap: onTap,
      semanticLabel:
          'Level ${lvl.level}, ${lvl.xpInLevel} of ${lvl.xpForLevel} XP. ${stats.xpToday} XP today. Open your week.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Text('Level ${lvl.level}', style: meta),
            const Spacer(),
            Text('${lvl.xpInLevel}/${lvl.xpForLevel}', style: meta),
          ]),
          const SizedBox(height: 10),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: CountUpText(
              value: stats.xpToday,
              prefix: '+',
              suffix: ' XP',
              style: AppTypography.cardNumber.copyWith(color: p.textPrimary),
            ),
          ),
          const SizedBox(height: 10),
          GradientBar(value: lvl.fraction),
        ],
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({required this.state, required this.onTap});
  final LetterTileState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final unread = state == LetterTileState.unread;
    final title = unread ? 'Your weekly letter is ready' : 'Talk to Aurora';
    final sub = unread ? 'from Aurora' : 'She knows your week';
    return AtlasTile(
      gradient: p.letter,
      onTap: onTap,
      semanticLabel: '$title, $sub',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AtlasSpark(size: 30, animated: unread),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTypography.sans(
                      size: 15, weight: FontWeight.w700, height: 1.2, color: p.textPrimary)),
              const SizedBox(height: 2),
              Text(sub, style: AppTypography.meta.copyWith(color: p.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Up next ────────────────────────────────────────────────────────

class _UpNextRow extends StatelessWidget {
  const _UpNextRow({
    super.key,
    required this.item,
    required this.primary,
    required this.tended,
    required this.onTend,
    required this.onLater,
    required this.onLongPress,
  });

  final TodayItem item;
  final bool primary;
  final bool tended;
  final VoidCallback onTend;
  final VoidCallback onLater;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final Widget trailing;
    if (tended) {
      trailing = const _TendedCheck();
    } else if (primary) {
      trailing = PillButton(label: 'Tend', onTap: onTend, haptic: PressHaptic.light);
    } else {
      trailing = PillButton(
        label: 'Later',
        variant: PillVariant.track,
        haptic: PressHaptic.selection,
        onTap: onLater,
      );
    }
    return AtlasRow(
      leading: IconTile(style: item.style),
      title: item.title,
      meta: item.meta,
      semanticsValue: tended ? 'done' : 'not done',
      trailing: AnimatedSwitcher(
        duration: AppMotion.fast,
        switchInCurve: AppMotion.emphasized,
        transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
        child: KeyedSubtree(key: ValueKey(tended ? 'done' : 'todo'), child: trailing),
      ),
      onSwipeRight: tended ? null : onTend,
      onSwipeLeft: tended ? null : onLater,
      onLongPress: onLongPress,
    );
  }
}

class _TendedCheck extends StatelessWidget {
  const _TendedCheck();

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.sunrise),
        child: const AtlasIcon(Symbols.check_rounded, color: AppColors.white, size: 22, weight: 600),
      );
}

class _DayDone extends StatelessWidget {
  const _DayDone({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          const AtlasSpark(size: 72, animated: true),
          const SizedBox(height: AppSpacing.md),
          Text('That’s everything for today.',
              textAlign: TextAlign.center,
              style: AppTypography.section.copyWith(color: p.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          PillButton(
            label: 'Add something',
            variant: PillVariant.track,
            height: 46,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}
