import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:refresh_rate/refresh_rate.dart';

import 'package:atlas_flutter_app/features/profile/widgets/settings_widgets.dart';
import 'package:atlas_flutter_app/shared/providers/refresh_rate_provider.dart';
import 'package:atlas_flutter_app/shared/providers/theme_provider.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Display: light or dark, and how smoothly Atlas moves.
class DisplaySettingsScreen extends ConsumerStatefulWidget {
  const DisplaySettingsScreen({super.key});

  @override
  ConsumerState<DisplaySettingsScreen> createState() => _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState extends ConsumerState<DisplaySettingsScreen> {
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
    final mode = ref.watch(themeProvider);

    return SettingsPage(
      title: 'Display',
      onBack: () => context.pop(),
      children: [
        const SettingsLabel('Appearance'),
        SegmentedPill(
          labels: const ['System', 'Light', 'Dark'],
          index: switch (mode) {
            ThemeMode.system => 0,
            ThemeMode.light => 1,
            ThemeMode.dark => 2,
          },
          onChanged: (i) => ref
              .read(themeProvider.notifier)
              .setThemeMode([ThemeMode.system, ThemeMode.light, ThemeMode.dark][i]),
        ),
        const SettingsFootnote('System follows your phone, switching after dark if it does.'),
        settingsGap,
        const SettingsLabel('Motion'),
        _RateCard(state: state),
        const SizedBox(height: AppSpacing.xs),
        RowGroup(children: [
          SwitchRow(
            icon: Symbols.motion_photos_on_rounded,
            iconColor: AppColors.leaf,
            title: 'Smooth motion',
            subtitle: 'Use the highest refresh rate this screen supports',
            value: state.enabled,
            enabled: state.deviceSupportsHighRate,
            onChanged: (v) => ref.read(refreshRateProvider.notifier).setEnabled(v),
          ),
        ]),
        if (state.throttledByBattery) ...[
          const SizedBox(height: AppSpacing.xs),
          const SettingsNote(
            icon: Symbols.battery_saver_rounded,
            text: 'Battery saver is on, so your display may stay at its standard rate '
                'until you turn it off.',
          ),
        ],
        if (state.throttledByHeat) ...[
          const SizedBox(height: AppSpacing.xs),
          const SettingsNote(
            icon: Symbols.thermostat_rounded,
            text: 'Your device is warm. It may hold a lower rate for a while to cool '
                'down, which is normal.',
          ),
        ],
        if (state.loaded && !state.deviceSupportsHighRate) ...[
          const SizedBox(height: AppSpacing.xs),
          const SettingsNote(
            icon: Symbols.info_rounded,
            color: AppColors.violet,
            text: 'This screen runs at a single refresh rate, so there is nothing to '
                'unlock here. Atlas is already as smooth as it gets on this device.',
          ),
        ],
        const SettingsFootnote(
          'Higher refresh rates make scrolling and animation feel smoother, and use '
          'a little more battery. Atlas leaves this on by default and never overrides '
          'your device’s power saving.',
        ),
        if (info != null && info.supportedRates.length > 1) ...[
          settingsGap,
          const SettingsLabel('This display'),
          _SupportedRates(info: info),
        ],
      ],
    );
  }
}

/// The live refresh rate, big, in the sunrise when Atlas is running fast.
class _RateCard extends StatelessWidget {
  const _RateCard({required this.state});
  final RefreshRateState state;

  String _fmt(double hz) => hz % 1 == 0 ? '${hz.toInt()}' : hz.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final info = state.info;
    final current = info == null ? '…' : _fmt(info.currentRate);
    final max = info == null ? null : _fmt(info.maxRate);
    final live = info != null && state.enabled && state.deviceSupportsHighRate;
    final number = AppTypography.statNumber;

    return AtlasTile(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              live
                  ? GradientText(current, style: number)
                  : Text(current, style: number.copyWith(color: p.textPrimary)),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 6),
                child: Text('Hz', style: AppTypography.section.copyWith(color: p.textMuted)),
              ),
              const Spacer(),
              if (max != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('up to $max Hz',
                      style: AppTypography.metaStrong.copyWith(color: p.textMuted)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            info == null ? 'Reading your display' : 'What your screen is refreshing at right now.',
            style: AppTypography.meta.copyWith(color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SupportedRates extends StatelessWidget {
  const _SupportedRates({required this.info});
  final DisplayInfo info;

  @override
  Widget build(BuildContext context) {
    final rates = [...info.supportedRates]..sort();
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final r in rates)
          AtlasChip(label: '${r % 1 == 0 ? r.toInt() : r.toStringAsFixed(1)} Hz'),
      ],
    );
  }
}
