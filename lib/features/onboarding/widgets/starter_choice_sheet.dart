import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/features/onboarding/providers/starter_data_provider.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Asked once, on the first visit to Home: start with a few examples to see
/// how Atlas feels, or start empty. Examples can be removed any time from
/// Sync and data.
Future<void> showStarterChoiceSheet(BuildContext context, WidgetRef ref) async {
  final want = await showAtlasSheet<bool>(
    context,
    builder: (context) {
      final p = context.palette;
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: AtlasSpark(size: 56, animated: true)),
            const SizedBox(height: AppSpacing.md),
            Text('How would you like to start?',
                textAlign: TextAlign.center,
                style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add a few example habits, tasks and a little history to see how Atlas feels. '
              'You can remove them in one tap from Sync and data.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: p.textBody),
            ),
            const SizedBox(height: AppSpacing.lg),
            PillButton(
              label: 'Show me with examples',
              height: 56,
              expand: true,
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.xs),
            PillButton(
              label: 'Start empty',
              variant: PillVariant.track,
              height: 56,
              expand: true,
              haptic: PressHaptic.selection,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      );
    },
  );
  // Dismissing the sheet counts as "start empty"; it never asks twice.
  await ref.read(starterDataProvider.notifier).choose(wantStarter: want ?? false);
}
