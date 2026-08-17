import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:atlas_flutter_app/core/logging/app_logger.dart';
import 'package:atlas_flutter_app/features/about/providers/app_info_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/brand/atlas_logo.dart';
import 'package:atlas_flutter_app/shared/widgets/feedback/atlas_toast.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

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
    final theme = Theme.of(context);
    final info = ref.watch(appInfoProvider);

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
            AtlasHeader(title: 'About', onBack: () => context.pop()),
            AppSpacing.gapXl,

            // ─── Mark, name, version ───
            Center(
              child: Column(
                children: [
                  const AtlasLogo(size: 88, glow: true),
                  AppSpacing.gapMd,
                  Text('Atlas', style: theme.textTheme.displaySmall),
                  AppSpacing.gapXs,
                  _VersionPill(info: info),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: AppMotion.medium)
                .slideY(begin: 0.06, end: 0, curve: AppMotion.standard),

            AppSpacing.gapXl,
            Text(
              'A world that grows as you care for yourself. Tend your habits, '
              'tasks and goals, and watch your horizon turn greener. Calm by '
              'design, and yours offline.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.55,
              ),
            ),

            AppSpacing.gapXl,
            const SectionHeader(title: 'Made by'),
            const _DeveloperCard(),

            AppSpacing.gapXl,
            const SectionHeader(title: 'This build'),
            _BuildDetails(info: info),
          ],
        ),
      ),
    );
  }
}

// ─── Version ────────────────────────────────────────────────────────

class _VersionPill extends StatelessWidget {
  const _VersionPill({required this.info});
  final AsyncValue<AppInfo> info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = info.when(
      data: (i) => 'Version ${i.display}',
      loading: () => 'Reading version…',
      // A version we could not read is not worth an error state on a page
      // whose whole job is calm.
      error: (_, _) => 'Version unavailable',
    );

    return AnimatedSwitcher(
      duration: AppMotion.fast,
      child: Container(
        key: ValueKey(label),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs + 2,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─── Developer ──────────────────────────────────────────────────────

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard();

  static final _log = AppLog('About');

  Future<void> _openSite(BuildContext context) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(_developerSite),
        mode: LaunchMode.externalApplication,
      );
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
    final theme = Theme.of(context);

    return AtlasCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Developed & Maintained by',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          // The one place a name deserves the display face.
          Text(
            _developerName,
            style: theme.textTheme.headlineSmall?.copyWith(
              foreground: Paint()
                ..shader = AppColors.auroraGradient.createShader(
                  const Rect.fromLTWH(0, 0, 260, 40),
                ),
            ),
          ),
          AppSpacing.gapMd,
          _SiteLink(onTap: () => _openSite(context)),
        ],
      ),
    );
  }
}

/// The website, as an obviously tappable link rather than decorated text.
class _SiteLink extends StatelessWidget {
  const _SiteLink({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      link: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.auroraLilac.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: AppColors.auroraLilac.withValues(alpha: 0.38),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language_rounded,
                    size: 18, color: AppColors.auroraLilac),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'pranta.dev',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.auroraLilac,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                const Icon(Icons.north_east_rounded,
                    size: 15, color: AppColors.auroraLilac),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Build details ──────────────────────────────────────────────────

/// The details you would be asked for in a bug report, in one place.
class _BuildDetails extends StatelessWidget {
  const _BuildDetails({required this.info});
  final AsyncValue<AppInfo> info;

  @override
  Widget build(BuildContext context) {
    return info.when(
      loading: () => const AtlasCard(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const AtlasCard(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Text('Build details are unavailable on this device.'),
      ),
      data: (i) => AtlasCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          children: [
            _DetailRow(label: 'Version', value: i.version),
            if (i.buildNumber.isNotEmpty)
              _DetailRow(label: 'Build', value: i.buildNumber),
            _DetailRow(label: 'Package', value: i.packageName, last: true),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: theme.colorScheme.outline),
              ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
