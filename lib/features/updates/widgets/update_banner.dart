import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/features/updates/providers/app_update_provider.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// A quiet note that a downloaded update is waiting. Renders nothing until
/// Play has the update on disk, and disappears for the session once dismissed —
/// an update should never feel like a demand.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(appUpdateProvider);
    if (!update.showBanner) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: NoticeRow(
        icon: Symbols.download_rounded,
        iconColor: AppColors.sunriseB,
        title: 'A new Atlas is ready',
        body: 'Restart to bring it in. It takes a moment.',
        actionLabel: 'Restart',
        busy: update.installing,
        onAction: () => ref.read(appUpdateProvider.notifier).install(),
        onDismiss: update.installing
            ? null
            : () => ref.read(appUpdateProvider.notifier).dismiss(),
      ),
    );
  }
}
