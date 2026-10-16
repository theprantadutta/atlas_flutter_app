import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/profile/widgets/settings_widgets.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Permanently delete the Atlas account.
///
/// Required by App Store Review Guideline 5.1.1(v): an app that creates
/// accounts must offer in-app deletion of the account itself, not merely a
/// deactivation or a "contact support" instruction.
///
/// The tone stays in character (someone leaving deserves clarity rather than
/// a scare screen), but the consequences are stated plainly and the action is
/// deliberately hard to trigger by accident.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
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

  bool get _canDelete => _confirmController.text.trim().toUpperCase() == _confirmWord;

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
        "We couldn't delete your account just now. Check your connection and try again.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SettingsPage(
      title: 'Delete account',
      subtitle: 'This one cannot be undone',
      onBack: _deleting ? null : () => context.pop(),
      children: [
        AtlasTile(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What gets removed', style: AppTypography.rowTitle.copyWith(color: p.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              for (final line in const [
                'Your profile, avatar, level and XP',
                'Every task, habit and goal you have created',
                'Your world, achievements and progress history',
                'Your Aurora conversations and reflections',
                'All data stored on this device',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3, right: 10),
                        child: AtlasIcon(Symbols.remove_rounded, size: 16, color: p.textMuted),
                      ),
                      Expanded(
                        child: Text(line, style: AppTypography.body.copyWith(color: p.textBody, height: 1.4)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Deleting the account does not cancel a store subscription; only
        // Apple or Google can, and saying so here heads off a billing surprise.
        const SettingsNote(
          icon: Symbols.info_rounded,
          color: AppColors.sky,
          text: 'If you have an Atlas Aurora subscription, cancel it separately in your '
              'App Store or Google Play account. Deleting your account here does not stop billing.',
        ),
        settingsGap,
        SettingsLabel('Type $_confirmWord to confirm'),
        TextField(
          controller: _confirmController,
          enabled: !_deleting,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          style: AppTypography.sans(size: 16, weight: FontWeight.w700, color: p.textPrimary, spacingEm: .08),
          decoration: const InputDecoration(hintText: _confirmWord),
        ),
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: 'Delete my account',
          icon: Symbols.delete_forever_rounded,
          height: 56,
          expand: true,
          haptic: PressHaptic.heavy,
          busy: _deleting,
          onTap: _canDelete && !_deleting ? _onDelete : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        PillButton(
          label: 'Keep my account',
          variant: PillVariant.track,
          height: 56,
          expand: true,
          haptic: PressHaptic.selection,
          onTap: _deleting ? null : () => context.pop(),
        ),
      ],
    );
  }
}
