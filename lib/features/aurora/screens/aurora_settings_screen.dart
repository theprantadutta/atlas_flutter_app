import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/aurora/providers/aurora_preferences_provider.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/app_text_field.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

/// Aurora's voice: what she calls you, how she speaks, how much she says, and
/// what she should keep in mind.
///
/// Everything here is stored on the device and sent with each Aurora request,
/// so the settings apply immediately to the next reply and to the next weekly
/// reflection. Nothing is kept on the server.
class AuroraSettingsScreen extends ConsumerStatefulWidget {
  const AuroraSettingsScreen({super.key});

  @override
  ConsumerState<AuroraSettingsScreen> createState() =>
      _AuroraSettingsScreenState();
}

class _AuroraSettingsScreenState extends ConsumerState<AuroraSettingsScreen> {
  final _name = TextEditingController();
  final _intention = TextEditingController();

  /// The text fields are seeded once, when the stored preferences first land.
  /// After that the controllers own their text, so typing is never fought over
  /// by a rebuild.
  bool _seeded = false;

  @override
  void dispose() {
    _name.dispose();
    _intention.dispose();
    super.dispose();
  }

  void _seed(AuroraPreferences prefs) {
    if (_seeded || !prefs.loaded) return;
    _seeded = true;
    _name.text = prefs.preferredName;
    _intention.text = prefs.intention;
  }

  Future<void> _reset() async {
    await ref.read(auroraPreferencesProvider.notifier).resetVoice();
    if (!mounted) return;
    _name.clear();
    _intention.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = ref.watch(auroraPreferencesProvider);
    final controller = ref.read(auroraPreferencesProvider.notifier);
    _seed(prefs);

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
            AtlasHeader(title: 'Aurora', onBack: () => context.pop()),
            AppSpacing.gapLg,

            const _VoicePreview()
                .animate()
                .fadeIn(duration: AppMotion.medium)
                .slideY(begin: 0.05, end: 0, curve: AppMotion.standard),

            AppSpacing.gapXl,
            const SectionHeader(title: 'What to call you'),
            AtlasCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _name,
                    hint: 'Your name, or a nickname',
                    prefixIcon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    maxLength:
                        AuroraPreferencesController.maxNameLength,
                    onChanged: controller.setPreferredName,
                  ),
                  Text(
                    'Leave this empty and Aurora simply will not use a name.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            AppSpacing.gapXl,
            const SectionHeader(title: 'How she speaks'),
            for (final tone in AuroraTone.values) ...[
              _ChoiceRow(
                label: tone.label,
                blurb: tone.blurb,
                selected: prefs.tone == tone,
                onTap: () => controller.setTone(tone),
              ),
              AppSpacing.gapXs,
            ],

            AppSpacing.gapMd,
            const SectionHeader(title: 'How much she says'),
            for (final length in AuroraLength.values) ...[
              _ChoiceRow(
                label: length.label,
                blurb: length.blurb,
                selected: prefs.length == length,
                onTap: () => controller.setLength(length),
              ),
              AppSpacing.gapXs,
            ],

            AppSpacing.gapMd,
            const SectionHeader(title: 'What matters right now'),
            AtlasCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _intention,
                    hint: 'Sleeping better, being kinder to myself, '
                        'finishing my thesis...',
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength:
                        AuroraPreferencesController.maxIntentionLength,
                    onChanged: controller.setIntention,
                  ),
                  Text(
                    'Aurora keeps this in mind when she writes to you. Change '
                    'it whenever the season of your life changes.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            AppSpacing.gapXl,
            const SectionHeader(title: 'Nudges'),
            _NudgeTile(
              value: prefs.nudgesEnabled,
              onChanged: controller.setNudgesEnabled,
            ),
            AppSpacing.gapSm,
            Text(
              'Nudges are the one thing Aurora does without being asked: a '
              'single caring line on Home when something is worth noticing. '
              'They are worked out on your device from your own data.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            if (prefs.isPersonalised) ...[
              AppSpacing.gapXl,
              Center(
                child: TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Back to Aurora’s default voice'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Live preview ───────────────────────────────────────────────────

/// Shows the settings as a sentence rather than a form, so the effect of a
/// change is visible without leaving the screen.
class _VoicePreview extends ConsumerWidget {
  const _VoicePreview();

  String _greeting(AuroraPreferences p) {
    final name = p.preferredName.isEmpty ? '' : ', ${p.preferredName}';
    return switch (p.tone) {
      AuroraTone.gentle => 'Hello$name. No rush today.',
      AuroraTone.warm => 'Hey$name, so glad you came back.',
      AuroraTone.direct => 'Morning$name. One thing to start with?',
      AuroraTone.playful => 'Well hello$name. Ready when you are.',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefs = ref.watch(auroraPreferencesProvider);

    return AtlasCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.auroraGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFF10243B), size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Aurora sounds like this',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          AppSpacing.gapSm,
          AnimatedSwitcher(
            duration: AppMotion.fast,
            child: Text(
              _greeting(prefs),
              key: ValueKey('${prefs.tone}-${prefs.preferredName}'),
              style: theme.textTheme.titleLarge?.copyWith(height: 1.35),
            ),
          ),
          AppSpacing.gapXs,
          Text(
            '${prefs.tone.label} · ${prefs.length.label}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Rows ───────────────────────────────────────────────────────────

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.blurb,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String blurb;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AtlasCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppMotion.fast,
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: selected ? AppColors.auroraGradient : null,
              border: selected
                  ? null
                  : Border.all(color: theme.colorScheme.outline, width: 2),
            ),
            child: selected
                ? const Icon(Icons.check_rounded,
                    size: 14, color: Color(0xFF10243B))
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleMedium),
                Text(
                  blurb,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class _NudgeTile extends StatelessWidget {
  const _NudgeTile({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AtlasCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.auroraLilac.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.spa_rounded,
                color: AppColors.auroraLilac, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gentle nudges', style: theme.textTheme.titleMedium),
                Text(
                  'A caring line on Home when it helps',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
