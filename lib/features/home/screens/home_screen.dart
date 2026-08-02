import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/aurora/providers/aurora_providers.dart';
import 'package:atlas_flutter_app/features/aurora/widgets/aurora_nudge_card.dart';
import 'package:atlas_flutter_app/features/home/providers/home_provider.dart';
import 'package:atlas_flutter_app/features/onboarding/widgets/coach_marks.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';
import 'package:atlas_flutter_app/shared/providers/theme_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/brand/living_horizon.dart';

/// Home — the showpiece. A time-aware greeting, the living-world hero that
/// flourishes as you tend to today, and a gentle list of today's rituals.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final home = ref.watch(homeProvider);

    // Checking off today's rituals visibly greens your world.
    final worldProgress =
        (home.worldProgress * 0.7 + home.dayProgress * 0.3).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.bottomNavSpace),
          children: [
            _GreetingHeader(name: home.greetingName, isDark: isDark)
                .animate()
                .fadeIn(duration: AppMotion.medium),
            const AuroraNudgeCard(),
            AppSpacing.gapLg,
            _Hero(
              key: ref.watch(coachMarkKeysProvider).hero,
              home: home,
              worldProgress: worldProgress,
            )
                .animate()
                .fadeIn(duration: AppMotion.medium, delay: 80.ms)
                .slideY(begin: 0.06, end: 0, curve: AppMotion.standard),
            AppSpacing.gapMd,
            _StatStrip(home: home)
                .animate()
                .fadeIn(duration: AppMotion.medium, delay: 160.ms),
            AppSpacing.gapMd,
            _AuroraHomeHero(streak: home.streak)
                .animate()
                .fadeIn(duration: AppMotion.medium, delay: 200.ms)
                .slideY(begin: 0.06, end: 0, curve: AppMotion.standard),
            AppSpacing.gapMd,
            Row(
              children: [
                Expanded(
                  child: _HomeLink(
                    icon: Icons.insights_rounded,
                    label: 'Insights',
                    onTap: () => context.push('/analytics'),
                  ),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: _HomeLink(
                    icon: Icons.calendar_today_rounded,
                    label: 'Progress',
                    onTap: () => context.push('/progress'),
                  ),
                ),
              ],
            ),
            AppSpacing.gapXl,
            _TodayHeader(done: home.doneCount, total: home.today.length),
            AppSpacing.gapMd,
            if (home.today.isEmpty)
              _TodayEmpty(onTap: () => context.go('/grow')),
            ...List.generate(home.today.length, (i) {
              final item = home.today[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _TodayTile(
                  item: item,
                  onTap: () =>
                      ref.read(taskActionsProvider).toggleById(item.id),
                )
                    .animate()
                    .fadeIn(
                        duration: AppMotion.medium, delay: (220 + i * 60).ms)
                    .slideY(begin: 0.08, end: 0, curve: AppMotion.standard),
              );
            }),
            AppSpacing.gapMd,
            _WorldNudge(progress: worldProgress, onTap: () => context.go('/world')),
          ],
        ),
      ),
    );
  }
}

// ─── Greeting header ────────────────────────────────────────────────

class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader({required this.name, required this.isDark});
  final String name;
  final bool isDark;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 5) return 'Rest well';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(name, style: theme.textTheme.displaySmall),
            ],
          ),
        ),
        _CircleButton(
          icon: Icons.notifications_none_rounded,
          badge: true,
          onTap: () => context.push('/notifications'),
        ),
        const SizedBox(width: AppSpacing.xs),
        _CircleButton(
          icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap, this.badge = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: theme.colorScheme.surfaceContainerHighest,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Icon(icon, size: 22, color: theme.colorScheme.onSurface),
            ),
          ),
        ),
        if (badge)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.streakFlame,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Hero: the living world + level/XP ──────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({super.key, required this.home, required this.worldProgress});
  final HomeState home;
  final double worldProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xpFrac = (home.xp / home.xpForNext).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Stack(
        children: [
          LivingHorizon(
            height: 260,
            progress: worldProgress,
            borderRadius: BorderRadius.zero,
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.surfaceDark.withValues(alpha: 0.66),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _GoldChip('Level ${home.level}'),
                    const Spacer(),
                    Text(
                      'Lvl ${home.level + 1}',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                _XpBar(fraction: xpFrac),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${home.xp} / ${home.xpForNext} XP · ${home.xpForNext - home.xp} to go',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.82)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldChip extends StatelessWidget {
  const _GoldChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs + 2),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 13, color: Color(0xFF3A2A00)),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF3A2A00),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  const _XpBar({required this.fraction});
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Stack(
        children: [
          Container(height: 10, color: Colors.white.withValues(alpha: 0.22)),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: AppMotion.slow,
            curve: AppMotion.standard,
            builder: (context, value, _) => FractionallySizedBox(
              widthFactor: value == 0 ? 0.001 : value,
              child: Container(
                height: 10,
                decoration: const BoxDecoration(gradient: AppColors.auroraGradient),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quiet stat strip ───────────────────────────────────────────────

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.home});
  final HomeState home;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatPill(
            icon: Icons.local_fire_department_rounded,
            color: AppColors.streakFlame,
            value: '${home.streak}',
            label: 'day streak',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatPill(
            icon: Icons.bolt_rounded,
            color: AppColors.xpPrimary,
            value: '+${home.xpToday}',
            label: 'XP today',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatPill(
            icon: Icons.spa_rounded,
            color: AppColors.secondary,
            value: '${home.dueCount}',
            label: 'to tend',
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ─── Today ──────────────────────────────────────────────────────────

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.done, required this.total});
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('Today', style: theme.textTheme.headlineSmall),
        const Spacer(),
        Text(
          '$done of $total tended',
          style: theme.textTheme.labelLarge
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _TodayTile extends StatelessWidget {
  const _TodayTile({required this.item, required this.onTap});
  final TodayItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = item.done;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: done ? 0.10 : 0.16),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(item.icon,
                    color: item.color.withValues(alpha: done ? 0.6 : 1), size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      done ? 'Tended · +${item.xp} XP' : item.note,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _CheckCircle(done: done, color: item.color),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.done, required this.color});
  final bool done;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? color : Colors.transparent,
        border: Border.all(
          color: done ? color : theme.colorScheme.outline,
          width: 2,
        ),
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
          : null,
    );
  }
}

// ─── Quick links (Insights / Progress) ─────────────────────────────

class _HomeLink extends StatelessWidget {
  const _HomeLink({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: theme.textTheme.titleSmall),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Aurora home hero (living AI presence) ──────────────────────────

/// A living Aurora moment on Home: a gentle check-in and, when it exists, a
/// snippet of this week's reflection. Sourced from real cached data. The card
/// opens the Aurora tab; the inline "Chat" opens the conversation.
class _AuroraHomeHero extends ConsumerWidget {
  const _AuroraHomeHero({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reflection = ref.watch(latestReflectionProvider).value;
    const ink = Color(0xFF10243B);

    final hasReflection = reflection != null;
    final snippet = hasReflection ? _plainSnippet(reflection.content) : null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/aurora'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: AppColors.auroraGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: ink, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('Aurora',
                        style: theme.textTheme.titleLarge?.copyWith(
                            color: ink, fontWeight: FontWeight.w700)),
                  ),
                  if (hasReflection)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs + 2, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text('This week',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: ink, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                snippet ?? _checkIn(streak),
                maxLines: snippet != null ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: ink, height: 1.45),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _HeroAction(
                      icon: Icons.spa_rounded,
                      label: hasReflection ? 'Read reflection' : 'Reflect',
                      filled: true,
                      onTap: () => context.go('/aurora'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _HeroAction(
                      icon: Icons.forum_rounded,
                      label: 'Chat',
                      filled: false,
                      onTap: () => context.push('/aurora-chat'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _checkIn(int streak) {
    if (streak >= 3) {
      return 'You’re on a $streak-day streak — a lovely moment to pause and '
          'reflect on how it’s going.';
    }
    return 'How are you feeling today? I can reflect on your week or just '
        'talk it through.';
  }

  /// Turn markdown into a short, clean plain-text snippet for the card.
  static String _plainSnippet(String md) {
    final plain = md
        .replaceAll(RegExp(r'[#>*_`~\-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return plain.length > 150 ? '${plain.substring(0, 150).trim()}…' : plain;
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF10243B);
    return Material(
      color: filled ? Colors.white.withValues(alpha: 0.9) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: filled
                ? null
                : Border.all(color: ink.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: ink),
              const SizedBox(width: AppSpacing.xs),
              Text(label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: ink, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Today empty state ──────────────────────────────────────────────

class _TodayEmpty extends StatelessWidget {
  const _TodayEmpty({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppColors.secondary, size: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nothing to tend yet',
                        style: theme.textTheme.titleMedium),
                    Text('Add a task or habit in Grow to begin',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── World nudge ────────────────────────────────────────────────────

class _WorldNudge extends StatelessWidget {
  const _WorldNudge({required this.progress, required this.onTap});
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (progress * 100).round();
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: LivingHorizon(
                    height: 52,
                    progress: progress,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your world is $pct% alive',
                        style: theme.textTheme.titleMedium),
                    Text('Keep tending it to watch it grow',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
