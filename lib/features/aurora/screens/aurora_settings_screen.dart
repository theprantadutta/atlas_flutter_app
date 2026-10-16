import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/features/aurora/providers/aurora_preferences_provider.dart';
import 'package:atlas_flutter_app/features/profile/widgets/settings_widgets.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// Aurora's voice: what she calls you, how she speaks, how much she says, and
/// what she should keep in mind.
///
/// Everything here is stored on the device and sent with each Aurora request,
/// so the settings apply immediately to the next reply and to the next weekly
/// letter. Nothing is kept on the server.
class AuroraSettingsScreen extends ConsumerStatefulWidget {
  const AuroraSettingsScreen({super.key});

  @override
  ConsumerState<AuroraSettingsScreen> createState() => _AuroraSettingsScreenState();
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
    final p = context.palette;
    final prefs = ref.watch(auroraPreferencesProvider);
    final controller = ref.read(auroraPreferencesProvider.notifier);
    _seed(prefs);
    final field = AppTypography.sans(size: 15, color: p.textPrimary);

    return SettingsPage(
      title: 'Aurora’s voice',
      onBack: () => context.pop(),
      children: [
        const _VoicePreview(),
        settingsGap,
        const SettingsLabel('What to call you'),
        TextField(
          controller: _name,
          style: field,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          maxLength: AuroraPreferencesController.maxNameLength,
          onChanged: controller.setPreferredName,
          decoration: InputDecoration(
            hintText: 'Your name, or a nickname',
            counterText: '',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: AtlasIcon(Symbols.person_rounded, size: 20, color: p.textMuted),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44),
          ),
        ),
        const SettingsFootnote('Leave this empty and Aurora simply won’t use a name.'),
        settingsGap,
        RowGroup(
          title: 'How she speaks',
          children: [
            for (final tone in AuroraTone.values)
              ChoiceRow(
                title: tone.label,
                subtitle: tone.blurb,
                selected: prefs.tone == tone,
                onTap: () => controller.setTone(tone),
              ),
          ],
        ),
        settingsGap,
        RowGroup(
          title: 'How much she says',
          children: [
            for (final length in AuroraLength.values)
              ChoiceRow(
                title: length.label,
                subtitle: length.blurb,
                selected: prefs.length == length,
                onTap: () => controller.setLength(length),
              ),
          ],
        ),
        settingsGap,
        const SettingsLabel('What matters right now'),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
          decoration: BoxDecoration(
            color: p.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
          ),
          child: TextField(
            controller: _intention,
            style: field.copyWith(height: 1.5),
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            maxLength: AuroraPreferencesController.maxIntentionLength,
            onChanged: controller.setIntention,
            decoration: const InputDecoration(
              hintText: 'Sleeping better, being kinder to myself, finishing my thesis...',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SettingsFootnote(
          'Aurora keeps this in mind when she writes to you. Change it whenever the '
          'season of your life changes.',
        ),
        settingsGap,
        RowGroup(
          title: 'Nudges',
          children: [
            SwitchRow(
              icon: Symbols.spa_rounded,
              iconColor: AppColors.violet,
              title: 'Gentle nudges',
              subtitle: 'A caring line on Home when it helps',
              value: prefs.nudgesEnabled,
              onChanged: controller.setNudgesEnabled,
            ),
          ],
        ),
        const SettingsFootnote(
          'Nudges are the one thing Aurora does without being asked: a single caring '
          'line on Home when something is worth noticing. They are worked out on your '
          'device from your own data.',
        ),
        if (prefs.isPersonalised) ...[
          settingsGap,
          Center(
            child: PillButton(
              label: 'Back to Aurora’s default voice',
              icon: Symbols.restart_alt_rounded,
              variant: PillVariant.track,
              height: 46,
              haptic: PressHaptic.selection,
              onTap: _reset,
            ),
          ),
        ],
      ],
    );
  }
}

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
    final p = context.palette;
    final prefs = ref.watch(auroraPreferencesProvider);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: p.letter,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -24,
            top: -24,
            child: Opacity(opacity: .5, child: AtlasSpark(size: 110, animated: true)),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AURORA SOUNDS LIKE THIS',
                    style: AppTypography.kicker.copyWith(color: p.textPrimary)),
                const SizedBox(height: AppSpacing.md),
                AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: Text(
                    _greeting(prefs),
                    key: ValueKey('${prefs.tone}-${prefs.preferredName}'),
                    style: AppTypography.letterHeadline.copyWith(color: p.textPrimary),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('${prefs.tone.label} · ${prefs.length.label}',
                    style: AppTypography.metaStrong.copyWith(color: p.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
