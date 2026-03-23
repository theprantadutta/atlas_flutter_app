import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/data/services/offline_manager.dart';
import 'package:atlas_flutter_app/shared/providers/connectivity_provider.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';
import 'package:atlas_flutter_app/shared/widgets/app_card.dart';

class SyncManagementScreen extends ConsumerStatefulWidget {
  const SyncManagementScreen({super.key});

  @override
  ConsumerState<SyncManagementScreen> createState() =>
      _SyncManagementScreenState();
}

class _SyncManagementScreenState extends ConsumerState<SyncManagementScreen> {
  Future<void> _syncNow() async {
    await ref.read(offlineManagerProvider).syncNow();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sync completed successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  String _formatLastSync(DateTime? lastSync) {
    if (lastSync == null) return 'Never';
    final diff = DateTime.now().difference(lastSync);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    final d = diff.inDays;
    return '$d ${d == 1 ? 'day' : 'days'} ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connectivityAsync = ref.watch(connectivityProvider);

    final isOnline = connectivityAsync.when(
      data: (online) => online,
      loading: () => true,
      error: (e, st) => false,
    );

    final pendingCount = ref.watch(pendingOperationsCountProvider).when(
      data: (count) => count,
      loading: () => 0,
      error: (e, st) => 0,
    );
    final lastSync = ref.watch(lastSyncTimeProvider).when(
      data: (time) => time,
      loading: () => null,
      error: (e, st) => null,
    );
    final syncStatus = ref.watch(syncStatusProvider).when(
      data: (status) => status,
      loading: () => SyncStatus.idle,
      error: (e, st) => SyncStatus.idle,
    );
    final isSyncing = syncStatus == SyncStatus.syncing;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sync Management',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connection status
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isOnline ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isOnline
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    color: isOnline ? AppColors.success : AppColors.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? AppColors.success
                                  : AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isOnline
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOnline
                            ? 'Connected to server. Data is syncing.'
                            : 'No internet connection. Changes saved locally.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pending operations
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pending_actions_rounded,
                    color: AppColors.warning,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Operations',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$pendingCount ${pendingCount == 1 ? 'operation' : 'operations'} pending',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Last sync time
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.info,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Sync',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatLastSync(lastSync),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Sync Now button
          AppButton(
            label: 'Sync Now',
            icon: Icons.sync_rounded,
            isLoading: isSyncing,
            onPressed: isOnline && !isSyncing ? _syncNow : null,
          ),

          if (!isOnline) ...[
            const SizedBox(height: 12),
            Text(
              'Sync is unavailable while offline. Please check your connection.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
