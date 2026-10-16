import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/aurora/providers/nudge_provider.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// A gentle, dismissible note from Aurora derived from local data. Renders
/// nothing when there's no relevant nudge (the common case).
class AuroraNudgeCard extends ConsumerWidget {
  const AuroraNudgeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nudge = ref.watch(auroraNudgeProvider);
    if (nudge == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: NoticeRow(
        title: nudge.message,
        actionLabel: nudge.prompt == null ? null : 'Talk',
        onAction: nudge.prompt == null
            ? null
            : () => context.push('/aurora-chat', extra: nudge.prompt),
        onDismiss: () =>
            ref.read(dismissedNudgesProvider.notifier).dismiss(nudge.key),
      ),
    );
  }
}
