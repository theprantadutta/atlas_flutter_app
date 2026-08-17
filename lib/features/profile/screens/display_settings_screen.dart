import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:refresh_rate/refresh_rate.dart';

import 'package:atlas_flutter_app/shared/providers/refresh_rate_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

/// Display — how smoothly Atlas moves, and what the screen is actually doing.
class DisplaySettingsScreen extends ConsumerStatefulWidget {
  const DisplaySettingsScreen({super.key});

  @override
  ConsumerState<DisplaySettingsScreen> createState() =>
      _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState
    extends ConsumerState<DisplaySettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Read the live rate when the screen opens, so the number is current.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(refreshRateProvider.notifier).refreshInfo(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(refreshRateProvider);
    final info = state.info;

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
            AtlasHeader(title: 'Display', onBack: () => context.pop()),
            AppSpacing.gapLg,

            _RateCard(state: state)
                .animate()
                .fadeIn(duration: AppMotion.medium)
                .slideY(begin: 0.05, end: 0, curve: AppMotion.standard),
            AppSpacing.gapMd,

            _SmoothMotionTile(
              value: state.enabled,
              enabled: state.deviceSupportsHighRate,
              onChanged: (v) =>
                  ref.read(refreshRateProvider.notifier).setEnabled(v),
            ).animate().fadeIn(duration: AppMotion.medium, delay: 80.ms),

            if (state.throttledByBattery) ...[
              AppSpacing.gapSm,
              const _Note(
                icon: Icons.battery_saver_rounded,
                color: AppColors.streakFlame,
                text: 'Battery saver is on, so your display may stay at its '
                    'standard rate until you turn it off.',
              ),
            ],
            if (state.throttledByHeat) ...[
              AppSpacing.gapSm,
              const _Note(
                icon: Icons.thermostat_rounded,
                color: AppColors.streakFlame,
                text: 'Your device is warm. It may hold a lower rate for a '
                    'while to cool down, which is normal.',
              ),
            ],
            if (state.loaded && !state.deviceSupportsHighRate) ...[
              AppSpacing.gapSm,
              const _Note(
                icon: Icons.info_outline_rounded,
                color: AppColors.auroraLilac,
                text: 'This screen runs at a single refresh rate, so there is '
                    'nothing to unlock here. Atlas is already as smooth as it '
                    'gets on this device.',
              ),
            ],

            AppSpacing.gapMd,
            Text(
              'Higher refresh rates make scrolling and animation feel smoother, '
              'and use a little more battery. Atlas leaves this on by default '
              'and never overrides your device’s power saving.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),

            if (info != null && info.supportedRates.length > 1) ...[
              AppSpacing.gapXl,
              const SectionHeader(title: 'This display'),
              _SupportedRates(info: info),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Live rate readout ──────────────────────────────────────────────

class _RateCard extends StatelessWidget {
  const _RateCard({required this.state});
  final RefreshRateState state;

  String _fmt(double hz) =>
      hz % 1 == 0 ? '${hz.toInt()}' : hz.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = state.info;
    final current = info == null ? '…' : _fmt(info.currentRate);
    final max = info == null ? null : _fmt(info.maxRate);
    final live = info != null && state.enabled && state.deviceSupportsHighRate;

    return AtlasCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                current,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1,
                  foreground: live
                      ? (Paint()
                        ..shader = AppColors.auroraGradient.createShader(
                          const Rect.fromLTWH(0, 0, 180, 60),
                        ))
                      : null,
                  color: live ? null : theme.colorScheme.onSurface,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text('Hz',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
              const Spacer(),
              if (max != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'up to $max Hz',
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            info == null
                ? 'Reading your display…'
                : 'What your screen is refreshing at right now.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─── Toggle ─────────────────────────────────────────────────────────

class _SmoothMotionTile extends StatelessWidget {
  const _SmoothMotionTile({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AtlasCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.xpPrimary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(Icons.motion_photos_on_rounded,
                  color: AppColors.xpPrimary, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Smooth motion', style: theme.textTheme.titleMedium),
                  Text(
                    'Use the highest refresh rate this screen supports',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Supported rates ────────────────────────────────────────────────

class _SupportedRates extends StatelessWidget {
  const _SupportedRates({required this.info});
  final DisplayInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rates = [...info.supportedRates]..sort();
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final r in rates)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Text(
              '${r % 1 == 0 ? r.toInt() : r.toStringAsFixed(1)} Hz',
              style: theme.textTheme.labelMedium,
            ),
          ),
      ],
    );
  }
}

// ─── Inline note ────────────────────────────────────────────────────

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
