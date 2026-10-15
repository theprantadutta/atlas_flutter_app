import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/config/sync_config.dart';
import 'package:atlas_flutter_app/data/models/user.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/avatar/providers/avatar_providers.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/feedback/widgets/feedback_sheet.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:atlas_flutter_app/features/profile/widgets/settings_widgets.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// You: the person behind the world. A big avatar, one ink card with level,
/// total XP and streaks (from the local ledger, not the server copy), then
/// calm groups of settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return const Scaffold(body: Center(child: AtlasSpark(size: 48, busy: true)));
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.xs,
            AppSpacing.gutter,
            MediaQuery.paddingOf(context).bottom + AppSpacing.xxl,
          ),
          children: [
            Row(children: [
              CircleIconButton.back(onTap: () => context.go('/')),
              const Spacer(),
            ]),
            const SizedBox(height: AppSpacing.sm),
            _Identity(user: user),
            const SizedBox(height: AppSpacing.lg),
            const EntryFade(id: 'profile-hero', index: 0, child: _StatsHero()),
            const SizedBox(height: 14),
            const EntryFade(id: 'profile-premium', index: 1, child: _PremiumTile()),
            settingsGap,
            RowGroup(
              title: 'Aurora and you',
              children: [
                GroupRow(
                  icon: Symbols.auto_awesome_rounded,
                  iconColor: AppColors.violet,
                  title: 'Aurora’s voice',
                  subtitle: 'How she speaks, and what she keeps in mind',
                  onTap: () => context.push('/profile/aurora'),
                ),
                const _AvatarRow(),
              ],
            ),
            settingsGap,
            RowGroup(
              title: 'App',
              children: [
                GroupRow(
                  icon: Symbols.contrast_rounded,
                  iconColor: AppColors.amber,
                  title: 'Display',
                  subtitle: 'Light, dark and smooth motion',
                  onTap: () => context.push('/profile/display'),
                ),
                GroupRow(
                  icon: Symbols.notifications_rounded,
                  iconColor: AppColors.coral,
                  title: 'Notifications',
                  subtitle: 'Choose what reaches you',
                  onTap: () => context.push('/profile/notifications'),
                ),
                const _SyncRow(),
              ],
            ),
            settingsGap,
            RowGroup(
              title: 'Your progress',
              children: [
                GroupRow(
                  icon: Symbols.insights_rounded,
                  iconColor: AppColors.sky,
                  title: 'Your week',
                  subtitle: 'XP, best day and where it came from',
                  onTap: () => context.push('/analytics'),
                ),
                GroupRow(
                  icon: Symbols.calendar_view_day_rounded,
                  iconColor: AppColors.leaf,
                  title: 'Day by day',
                  subtitle: 'Every day, with what you tended',
                  onTap: () => context.push('/progress'),
                ),
              ],
            ),
            settingsGap,
            RowGroup(
              title: 'Help',
              children: [
                GroupRow(
                  icon: Symbols.explore_rounded,
                  iconColor: AppColors.amber,
                  title: 'Replay the tour',
                  subtitle: 'Walk through Atlas again',
                  onTap: () => _replayTour(context, ref),
                ),
                GroupRow(
                  icon: Symbols.favorite_rounded,
                  iconColor: AppColors.rose,
                  title: 'Send feedback',
                  subtitle: 'Tell us how Atlas is going',
                  onTap: () => showFeedbackSheet(context),
                ),
                // Reachable from inside the app, not just the store listing
                // (Guideline 5.1.1). Shows the exact documents this user
                // accepted, and works offline.
                GroupRow(
                  icon: Symbols.shield_rounded,
                  iconColor: AppColors.sky,
                  title: 'Legal',
                  subtitle: 'Privacy, terms and refunds',
                  onTap: () => context.push('/profile/legal'),
                ),
                GroupRow(
                  icon: Symbols.info_rounded,
                  iconColor: AppColors.violet,
                  title: 'About Atlas',
                  subtitle: 'Version, and who built this',
                  onTap: () => context.push('/profile/about'),
                ),
              ],
            ),
            settingsGap,
            RowGroup(
              title: 'Account',
              children: [
                GroupRow(
                  icon: Symbols.logout_rounded,
                  title: 'Sign out',
                  subtitle: user.email,
                  onTap: () => _signOut(context, ref),
                ),
                // Required by App Store Guideline 5.1.1(v).
                GroupRow(
                  icon: Symbols.delete_rounded,
                  title: 'Delete account',
                  subtitle: 'Permanently erase your world',
                  destructive: true,
                  onTap: () => context.push('/profile/delete-account'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text('Atlas keeps your data on this device first.',
                  style: AppTypography.meta.copyWith(color: p.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  /// Re-arm the Home coach marks and go to the tab that hosts them, so the
  /// tour starts straight away instead of waiting for the next visit.
  Future<void> _replayTour(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingProvider.notifier).replayCoachMarks();
    if (!context.mounted) return;
    context.go('/');
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final syncing = ref.read(canSyncProvider) && SyncConfig.enabled;
    final ok = await confirmSheet(
      context,
      title: 'Sign out?',
      body: syncing
          ? 'Your world is backed up to your account, and stays on this device '
              'too. Sign back in any time to pick up where you left off.'
          : 'Everything you’ve tended stays on this device. Sign back in with '
              'the same account here to pick up where you left off. Without '
              'cloud sync, it isn’t copied anywhere else.',
      confirmLabel: 'Sign out',
      cancelLabel: 'Stay',
    );
    if (!ok) return;
    await ref.read(authProvider.notifier).logout();
  }
}

// ─── Identity ───────────────────────────────────────────────────────

class _Identity extends StatelessWidget {
  const _Identity({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final name = user.fullName.trim().isEmpty ? 'You' : user.fullName.trim();
    return Column(
      children: [
        AvatarRing(name: name, size: 96, ring: 3),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(name,
              textAlign: TextAlign.center,
              style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary)),
        ),
        const SizedBox(height: 4),
        Text(user.email,
            textAlign: TextAlign.center,
            style: AppTypography.dateLine.copyWith(color: p.textMuted)),
      ],
    );
  }
}

// ─── Stats hero ─────────────────────────────────────────────────────

class _StatsHero extends ConsumerWidget {
  const _StatsHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final stats = ref.watch(playerStatsProvider);
    final tended = ref.watch(ledgerDaysProvider).fold<int>(0, (a, d) => a + d.count);
    final lvl = stats.level;
    final on = p.onRaised;

    return InkHeroCard(
      glowLevel: lvl.fraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Text('Level ${lvl.level}',
                style: AppTypography.dateLine.copyWith(color: on.withValues(alpha: .7))),
            const Spacer(),
            AtlasChip(
              label: lvl.xpToNext == 0 ? 'Top level' : '${lvl.xpToNext} XP to Level ${lvl.level + 1}',
              background: on.withValues(alpha: .12),
              foreground: on,
              dense: true,
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CountUpText(
                value: stats.totalXp,
                animateFromZero: true,
                style: AppTypography.statNumber.copyWith(color: on),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GradientText('XP', style: AppTypography.cardNumber),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GradientBar(
            value: lvl.fraction,
            height: 8,
            gradient: AppColors.sunriseBar,
            trackColor: on.withValues(alpha: .15),
          ),
          const SizedBox(height: AppSpacing.lg - 4),
          Row(children: [
            _Stat(value: stats.streak, label: 'day streak'),
            _Stat(value: stats.bestStreak, label: 'best streak'),
            _Stat(value: tended, label: 'tended'),
          ]),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final on = context.palette.onRaised;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CountUpText(value: value, style: AppTypography.display(size: 24, color: on)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.meta.copyWith(color: on.withValues(alpha: .65))),
        ],
      ),
    );
  }
}

// ─── Premium ────────────────────────────────────────────────────────

/// An invitation when free; a calm status when subscribed. Always opens the
/// paywall, never the store: a subscriber goes there to see their plan and
/// switch, and being thrown out to the store page is a jarring exit.
class _PremiumTile extends ConsumerWidget {
  const _PremiumTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final isPremium = ref.watch(isPremiumProvider);
    final onTrial = ref.watch(isOnTrialProvider);
    final trialLeft = ref.watch(trialDaysRemainingProvider);
    // Only advertise a trial the store says this user can still start.
    final trialOffer = ref.watch(availableTrialDaysProvider);
    final isLifetime = ref.watch(entitlementsProvider).entitlements?.isLifetime ?? false;

    final subtitle = () {
      if (isPremium) {
        if (!onTrial) return isLifetime ? 'Founder. Premium, yours forever' : 'Premium is on';
        return trialLeft == null
            ? 'Free trial active'
            : 'Free trial · $trialLeft day${trialLeft == 1 ? '' : 's'} left';
      }
      return trialOffer > 0
          ? 'Start with $trialOffer days free: unlimited Aurora and cloud sync'
          : 'Unlimited Aurora, cloud sync and deeper insights';
    }();

    return AtlasTile(
      gradient: p.letter,
      onTap: () => context.push('/paywall'),
      semanticLabel: '${isPremium ? 'Atlas Aurora' : 'Go Premium'}, $subtitle',
      child: Row(
        children: [
          const AtlasSpark(size: 34, animated: true),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isPremium ? 'Atlas Aurora' : 'Go Premium',
                    style: AppTypography.rowTitle.copyWith(color: p.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.meta.copyWith(color: p.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // A chevron promises somewhere to go; premium gets a quiet mark
          // that the thing is on instead.
          if (isPremium)
            AtlasIcon(Symbols.check_circle_rounded, filled: true, size: 22, color: p.success)
          else
            AtlasIcon(Symbols.arrow_forward_rounded, size: 20, color: p.textMuted),
        ],
      ),
    );
  }
}

// ─── Rows with live detail ──────────────────────────────────────────

class _AvatarRow extends ConsumerWidget {
  const _AvatarRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Attributes come from the local-first avatar (Drift).
    final avatar = ref.watch(avatarStreamProvider).value;
    final sub = avatar == null
        ? 'Make this world yours'
        : 'Strength ${avatar.strength} · Wisdom ${avatar.wisdom} · Mind ${avatar.intelligence}';
    return GroupRow(
      icon: Symbols.face_rounded,
      iconColor: AppColors.leaf,
      title: 'Your avatar',
      subtitle: sub,
      onTap: () => context.push('/profile/avatar'),
    );
  }
}

class _SyncRow extends ConsumerWidget {
  const _SyncRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final syncing = ref.watch(canSyncProvider) && SyncConfig.enabled;
    return GroupRow(
      icon: Symbols.cloud_sync_rounded,
      iconColor: AppColors.pine,
      title: 'Sync and data',
      subtitle: syncing ? 'Backed up to your account' : 'Kept safe on this device',
      onTap: () => context.push('/profile/sync'),
      trailing: syncing
          ? AtlasChip.success(context, 'On', icon: Symbols.check_rounded)
          : AtlasChip(label: 'Local', background: p.track, dense: true),
    );
  }
}
