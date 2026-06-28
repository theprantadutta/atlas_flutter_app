import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/sample/sample_extra.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

/// Notification Center — a gentle, swipe-to-dismiss feed. Unread items are
/// lightly emphasized; nothing here shames the user.
class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final unread = items.where((n) => !n.read).length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            AtlasHeader(
              title: 'Notifications',
              subtitle: unread > 0 ? '$unread new' : "You're all caught up",
              onBack: () => context.pop(),
              trailing: unread > 0
                  ? TextButton(
                      onPressed: notifier.markAllRead,
                      child: const Text('Mark all read'),
                    )
                  : null,
            ),
            AppSpacing.gapLg,
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxl),
                child: const AtlasEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'All clear',
                  message: 'Nothing needs your attention right now.',
                ),
              )
            else
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) AppSpacing.gapSm,
                Dismissible(
                  key: ValueKey(items[i].id),
                  onDismissed: (_) => notifier.dismiss(items[i].id),
                  background: const _DismissBackground(
                    alignment: Alignment.centerLeft,
                  ),
                  secondaryBackground: const _DismissBackground(
                    alignment: Alignment.centerRight,
                  ),
                  child: _NotificationCard(item: items[i])
                      .animate(delay: Duration(milliseconds: 40 * i))
                      .fadeIn(duration: AppMotion.medium)
                      .slideY(
                        begin: 0.06,
                        end: 0,
                        duration: AppMotion.medium,
                        curve: AppMotion.standard,
                      ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground({required this.alignment});
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: AppColors.error,
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});
  final SampleNotification item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = !item.read;

    return AtlasCard(
      color: unread ? theme.colorScheme.primary.withValues(alpha: 0.06) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (unread) ...[
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      AppSpacing.hGapXs,
                    ],
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight:
                              unread ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Text(
                      item.timeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  item.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
