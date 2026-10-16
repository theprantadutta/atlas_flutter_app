// Hide Flutter's Notification widget: we use the Drift Notification row here.
import 'package:flutter/material.dart' hide Notification;
import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/shared/widgets/layout/adaptive_layout.dart';
import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/notifications/providers/notification_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart'
    show currentUserIdProvider;
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Notifications: a calm feed backed by the local store. Unread items carry
/// a small coral dot; tapping one marks it read and opens what it's about.
/// Swipe to dismiss (with Undo). Nothing here shames the user.
class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, Notification n) async {
    if (!n.isRead) await ref.read(notificationActionsProvider).markRead(n.id);
    final route = notificationRoute(n);
    if (route != null && context.mounted) context.go(route);
  }

  Future<void> _dismiss(BuildContext context, WidgetRef ref, Notification n) async {
    HapticFeedback.selectionClick();
    await ref.read(notificationActionsProvider).dismiss(n.id);
    if (!context.mounted) return;
    AtlasToast.undo(context, 'Notification removed',
        onUndo: () => restoreNotification(ref.read(databaseProvider), n.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsStreamProvider);
    final rows = async.value ?? const <Notification>[];
    final unread = rows.where((n) => !n.isRead).length;
    final today = dateOnly(clock.now());

    final groups = <(String, List<Notification>)>[];
    for (final n in rows) {
      final d = dateOnly(n.createdAt);
      final label = isSameDay(d, today)
          ? 'Today'
          : daysBetween(d, today) < 7
              ? 'This week'
              : 'Earlier';
      if (groups.isEmpty || groups.last.$1 != label) groups.add((label, []));
      groups.last.$2.add(n);
    }

    var index = 0;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: readableInsets(context, top: AppSpacing.xs, bottom: AppSpacing.xxl),
          children: [
            ScreenHeader(
              title: 'Notifications',
              subtitle: rows.isEmpty
                  ? null
                  : unread > 0
                      ? '$unread new'
                      : 'You’re all caught up',
              onBack: () => context.pop(),
            ),
            const SizedBox(height: AppSpacing.md),
            if (async.isLoading && rows.isEmpty)
              const SkeletonList(count: 4, height: 84)
            else if (async.hasError && rows.isEmpty)
              ErrorRow(
                message: 'Your notifications didn’t load.',
                onRetry: () => ref.invalidate(notificationsStreamProvider),
              )
            else if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xxl),
                child: EmptyState(
                  title: 'All clear.',
                  body: 'Nothing needs your attention right now.',
                ),
              )
            else
              for (final (label, items) in groups) ...[
                SectionTitle(
                  label,
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  // "Mark all read" rides on the first section, so the title
                  // keeps the whole width.
                  action: unread > 0 && label == groups.first.$1 ? 'Mark all read' : null,
                  onAction: () => ref
                      .read(notificationActionsProvider)
                      .markAllRead(ref.read(currentUserIdProvider)),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final n in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: EntryFade(
                      id: 'notif-${n.id}',
                      index: index++,
                      child: Dismissible(
                        key: ValueKey(n.id),
                        onDismissed: (_) => _dismiss(context, ref, n),
                        background: const _DismissBackground(alignment: Alignment.centerLeft),
                        secondaryBackground: const _DismissBackground(alignment: Alignment.centerRight),
                        child: _NotificationRow(
                          notification: n,
                          onTap: () => _open(context, ref, n),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }
}

String _timeAgo(DateTime t) {
  final diff = clock.now().difference(t);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return weekdayName(t);
  return '${t.day} ${monthShort(t)}';
}

CategoryStyle _styleFor(String type) => switch (type) {
      'achievement' => const CategoryStyle(Symbols.trophy_rounded, AppColors.amber),
      'place' => const CategoryStyle(Symbols.public_rounded, AppColors.leaf),
      'level' => const CategoryStyle(Symbols.auto_awesome_rounded, AppColors.violet),
      'letter' => const CategoryStyle(Symbols.mail_rounded, AppColors.rose),
      'account' => const CategoryStyle(Symbols.credit_card_rounded, AppColors.sky),
      'achievementUnlocked' || 'achievement_unlocked' =>
        const CategoryStyle(Symbols.trophy_rounded, AppColors.amber),
      'levelUp' || 'level_up' => const CategoryStyle(Symbols.auto_awesome_rounded, AppColors.rose),
      'streakAlert' || 'streak_alert' =>
        const CategoryStyle(Symbols.local_fire_department_rounded, AppColors.coral),
      'habitReminder' || 'habit_reminder' =>
        const CategoryStyle(Symbols.self_improvement_rounded, AppColors.violet),
      'taskReminder' || 'task_reminder' => const CategoryStyle(Symbols.task_alt_rounded, AppColors.sky),
      'goalDeadline' || 'goal_deadline' => const CategoryStyle(Symbols.flag_rounded, AppColors.amber),
      'dailySummary' || 'daily_summary' => const CategoryStyle(Symbols.today_rounded, AppColors.sky),
      _ => const CategoryStyle(Symbols.notifications_rounded, AppColors.leaf),
    };

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.onTap});
  final Notification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = notification;
    final unread = !n.isRead;
    return Pressable(
      onTap: onTap,
      semanticLabel: '${unread ? 'Unread. ' : ''}${n.title}. ${n.body}. ${_timeAgo(n.createdAt)}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: p.paper,
          borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(style: _styleFor(n.type), size: 42),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: AppTypography.sans(
                            size: 15,
                            weight: unread ? FontWeight.w700 : FontWeight.w600,
                            height: 1.3,
                            color: p.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(_timeAgo(n.createdAt),
                            style: AppTypography.meta.copyWith(color: p.textMuted)),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 6),
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AtlasPalette.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(size: 13, height: 1.45, color: p.textSecondary),
                  ),
                ],
              ),
            ),
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
    final p = context.palette;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.track,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
      ),
      child: AtlasIcon(Symbols.delete_rounded, color: p.textMuted, size: 22),
    );
  }
}
