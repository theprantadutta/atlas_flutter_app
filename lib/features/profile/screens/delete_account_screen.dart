import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';
import 'package:atlas_flutter_app/shared/widgets/feedback/atlas_toast.dart';

/// Permanently delete the Atlas account.
///
/// Required by App Store Review Guideline 5.1.1(v): an app that creates
/// accounts must offer in-app deletion of the account itself, not merely a
/// deactivation or a "contact support" instruction.
///
/// The tone stays in character — this is a caring app, and someone leaving
/// deserves clarity rather than a scare screen — but the consequences are
/// stated plainly and the action is deliberately hard to trigger by accident.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmController = TextEditingController();
  bool _deleting = false;

  static const _confirmWord = 'DELETE';

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canDelete =>
      _confirmController.text.trim().toUpperCase() == _confirmWord;

  Future<void> _onDelete() async {
    setState(() => _deleting = true);
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      // The router's auth redirect takes over from here and lands on login.
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      AtlasToast.error(
        context,
        "We couldn't delete your account just now. "
        'Check your connection and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            AtlasHeader(
              title: 'Delete account',
              subtitle: 'This one cannot be undone',
              onBack: _deleting ? null : () => context.pop(),
            ),
            AppSpacing.gapLg,
            AtlasCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What gets removed',
                    style: theme.textTheme.titleMedium,
                  ),
                  AppSpacing.gapSm,
                  ...const [
                    'Your profile, avatar, level and XP',
                    'Every task, habit and goal you have created',
                    'Your world, achievements and progress history',
                    'Your Aurora conversations and reflections',
                    'All data stored on this device',
                  ].map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6, right: 10),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurfaceVariant,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              line,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapMd,
            // Deleting the account does not cancel a store subscription — only
            // Apple/Google can do that, and saying so here heads off both a
            // support burden and a billing complaint.
            AtlasCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'If you have an Atlas Aurora subscription, cancel it separately '
                      'in your App Store account settings. Deleting your account '
                      'here does not stop billing.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapLg,
            Text(
              'Type $_confirmWord to confirm',
              style: theme.textTheme.labelLarge,
            ),
            AppSpacing.gapXs,
            TextField(
              controller: _confirmController,
              enabled: !_deleting,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: _confirmWord,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
            ),
            AppSpacing.gapLg,
            AppButton(
              label: 'Delete my account',
              icon: Icons.delete_forever_rounded,
              isLoading: _deleting,
              onPressed: _canDelete && !_deleting ? _onDelete : null,
            ),
            AppSpacing.gapSm,
            Center(
              child: TextButton(
                onPressed: _deleting ? null : () => context.pop(),
                child: const Text('Keep my account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
