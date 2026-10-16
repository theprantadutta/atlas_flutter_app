import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:atlas_flutter_app/shared/widgets/layout/adaptive_layout.dart';
import 'package:atlas_flutter_app/core/logging/app_logger.dart';
import 'package:atlas_flutter_app/features/about/providers/app_info_provider.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// The person behind Atlas, and which build you are holding.
const _developerName = 'Pranta Dutta';
const _developerSite = 'https://pranta.dev';

/// About: what Atlas is, who made it, and the exact version you are running.
///
/// The version is read from the installed bundle via [appInfoProvider], never
/// hard-coded, so it is always the truth rather than a number someone forgot
/// to bump.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final info = ref.watch(appInfoProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: readableInsets(context, top: AppSpacing.xs, bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl,
          ),
          children: [
            ScreenHeader(title: 'About', onBack: () => context.pop()),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Column(
                children: [
                  const AtlasAppIcon(size: 96, animated: true),
                  const SizedBox(height: AppSpacing.lg),
                  const AtlasLockup(height: 34),
                  const SizedBox(height: AppSpacing.sm),
                  _VersionChip(info: info),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Every day is a small sunrise. Tend your habits, tasks and goals, and '
              'over time discover a whole world. Calm by design, and yours offline.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: p.textBody),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _DeveloperCard(),
            const SizedBox(height: AppSpacing.lg),
            _BuildDetails(info: info),
          ],
        ),
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip({required this.info});
  final AsyncValue<AppInfo> info;

  @override
  Widget build(BuildContext context) {
    final label = info.when(
      data: (i) => 'Version ${i.display}',
      loading: () => 'Reading version',
      // A version we could not read is not worth an error state on a page
      // whose whole job is calm.
      error: (_, _) => 'Version unavailable',
    );
    return AnimatedSwitcher(
      duration: AppMotion.fast,
      child: AtlasChip(key: ValueKey(label), label: label),
    );
  }
}

/// The developer, in the one place a name deserves the display face.
class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard();

  static final _log = AppLog('About');

  Future<void> _openSite(BuildContext context) async {
    var opened = false;
    try {
      opened = await launchUrl(Uri.parse(_developerSite), mode: LaunchMode.externalApplication);
    } catch (e) {
      _log.w('Could not open $_developerSite: $e');
    }
    if (!context.mounted || opened) return;
    // No browser to hand it to, so leave the address somewhere useful.
    await Clipboard.setData(const ClipboardData(text: _developerSite));
    if (!context.mounted) return;
    AtlasToast.info(context, 'Link copied: $_developerSite');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = p.onRaised;
    return InkHeroCard(
      glowLevel: .4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Developed and maintained by',
              style: AppTypography.dateLine.copyWith(color: on.withValues(alpha: .7))),
          const SizedBox(height: AppSpacing.xs),
          GradientText(_developerName, style: AppTypography.display(size: 32)),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            link: true,
            child: PillButton(
              label: 'pranta.dev',
              icon: Symbols.north_east_rounded,
              variant: PillVariant.onRaised,
              height: 44,
              haptic: PressHaptic.selection,
              onTap: () => _openSite(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// The details you would be asked for in a bug report, in one place.
class _BuildDetails extends StatelessWidget {
  const _BuildDetails({required this.info});
  final AsyncValue<AppInfo> info;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(children: [
            Text(label, style: AppTypography.sans(size: 14, weight: FontWeight.w600, color: p.textMuted)),
            const Spacer(),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: AppTypography.sans(
                      size: 14, weight: FontWeight.w700, tabular: true, color: p.textPrimary)),
            ),
          ]),
        );
    return info.when(
      loading: () => const Skeleton(height: 150),
      error: (_, _) => const _InfoBox(text: 'Build details are unavailable on this device.'),
      data: (i) => RowGroup(
        title: 'This build',
        children: [
          row('Version', i.version),
          if (i.buildNumber.isNotEmpty) row('Build', i.buildNumber),
          row('Package', i.packageName),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => AtlasTile(
        child: Text(text, style: AppTypography.body.copyWith(color: context.palette.textMuted)),
      );
}
