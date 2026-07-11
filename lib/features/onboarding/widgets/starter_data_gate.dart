import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/features/onboarding/providers/starter_data_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';

/// An invisible gate that, on first run, asks whether to preload example data.
/// Drop it into a screen's tree (it renders nothing) — it shows the prompt once
/// as soon as the stored choice is known and no choice has been made yet.
class StarterDataGate extends ConsumerStatefulWidget {
  const StarterDataGate({super.key});

  @override
  ConsumerState<StarterDataGate> createState() => _StarterDataGateState();
}

class _StarterDataGateState extends ConsumerState<StarterDataGate> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    final starter = ref.watch(starterDataProvider);
    if (starter.loaded && !starter.choiceMade && !_shown) {
      _shown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _prompt());
    }
    return const SizedBox.shrink();
  }

  Future<void> _prompt() async {
    if (!mounted) return;
    final want = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _StarterSheet(),
    );
    if (want == null) return; // safety: re-armed for next build
    await ref
        .read(starterDataProvider.notifier)
        .choose(wantStarter: want);
  }
}

class _StarterSheet extends StatelessWidget {
  const _StarterSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AppColors.auroraGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Color(0xFF10243B), size: 28),
                ),
              ),
              AppSpacing.gapMd,
              Text(
                'Start with example data?',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              AppSpacing.gapSm,
              Text(
                'We can fill your tasks, habits, goals and history with a few '
                'examples so you can explore Atlas right away. You can remove '
                'them anytime from Settings → Sync & data.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              AppSpacing.gapLg,
              _PrimaryButton(
                label: 'Add example data',
                onTap: () => Navigator.of(context).pop(true),
              ),
              AppSpacing.gapSm,
              _SecondaryButton(
                label: 'No thanks, start fresh',
                onTap: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.auroraGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF10243B),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
