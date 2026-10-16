import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/shared/widgets/layout/adaptive_layout.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// A pushed settings page: canvas, the 42 back button with a 30 title, and
/// a scrolling column of groups.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: readableInsets(context, top: AppSpacing.xs, bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl,
          ),
          children: [
            ScreenHeader(
              title: title,
              subtitle: subtitle,
              onBack: onBack,
              trailing: trailing,
            ),
            const SizedBox(height: AppSpacing.lg),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Space between groups on a settings page.
const settingsGap = SizedBox(height: AppSpacing.lg);

/// A muted kicker above a block that isn't a [RowGroup].
class SettingsLabel extends StatelessWidget {
  const SettingsLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, AppSpacing.xs),
        child: Text(text.toUpperCase(),
            style: AppTypography.kicker.copyWith(color: context.palette.textMuted)),
      );
}

/// Small print under a group.
class SettingsFootnote extends StatelessWidget {
  const SettingsFootnote(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, AppSpacing.xs, 4, 0),
        child: Text(text,
            style: AppTypography.sans(size: 13, height: 1.5, color: context.palette.textMuted)),
      );
}

/// A calm inline note: a paper row with a tinted icon.
class SettingsNote extends StatelessWidget {
  const SettingsNote({super.key, required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRow),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtlasIcon(icon, size: 20, filled: true, color: p.category(color ?? AppColors.amber)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text,
                style: AppTypography.sans(size: 14, height: 1.45, color: p.textBody)),
          ),
        ],
      ),
    );
  }
}

/// A [GroupRow] with a switch on the right; tapping the row flips it.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.iconColor,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? iconColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: GroupRow(
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        onTap: enabled ? () => onChanged(!value) : null,
        showChevron: false,
        trailing: Switch.adaptive(value: value, onChanged: enabled ? onChanged : null),
      ),
    );
  }
}

/// A radio-style choice row inside a [RowGroup]: a sunrise check when
/// selected, a quiet outline when not.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      scale: .98,
      haptic: PressHaptic.selection,
      semanticLabel: subtitle == null ? title : '$title, $subtitle',
      child: Semantics(
        selected: selected,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: AppMotion.fast,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: selected ? AppColors.sunrise : null,
                    border: selected ? null : Border.all(color: p.outline, width: 2),
                  ),
                  child: selected
                      ? const AtlasIcon(Symbols.check_rounded,
                          size: 16, color: AppColors.white, weight: 600)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: AppTypography.rowTitle.copyWith(color: p.textPrimary)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: AppTypography.meta.copyWith(color: p.textMuted)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
