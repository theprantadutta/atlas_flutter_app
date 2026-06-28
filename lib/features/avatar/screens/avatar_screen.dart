import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/core/sample/sample_extra.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';
import 'package:atlas_flutter_app/shared/widgets/ui_kit.dart';

/// Your Avatar — a playful but tasteful colour studio. Compose skin, hair and
/// outfit hues and watch the little soul update live.
class AvatarScreen extends ConsumerStatefulWidget {
  const AvatarScreen({super.key});

  @override
  ConsumerState<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends ConsumerState<AvatarScreen> {
  int _segment = 0; // 0 = Skin, 1 = Hair, 2 = Outfit
  int _skin = 1;
  int _hair = 0;
  int _outfit = 0;

  static const _segments = ['Skin', 'Hair', 'Outfit'];

  List<Color> get _activePalette => switch (_segment) {
        0 => AvatarOptions.skin,
        1 => AvatarOptions.hair,
        _ => AvatarOptions.outfit,
      };

  int get _activeIndex => switch (_segment) {
        0 => _skin,
        1 => _hair,
        _ => _outfit,
      };

  void _select(int index) {
    setState(() {
      switch (_segment) {
        case 0:
          _skin = index;
        case 1:
          _hair = index;
        default:
          _outfit = index;
      }
    });
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Looking good!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
            AtlasHeader(title: 'Your Avatar', onBack: () => context.pop()),
            AppSpacing.gapLg,
            _AvatarPreview(
              skin: AvatarOptions.skin[_skin],
              hair: AvatarOptions.hair[_hair],
              outfit: AvatarOptions.outfit[_outfit],
            ).animate().fadeIn(duration: AppMotion.medium),
            AppSpacing.gapXl,
            SegmentedTabs(
              labels: _segments,
              index: _segment,
              onChanged: (i) => setState(() => _segment = i),
            ),
            AppSpacing.gapLg,
            Text(
              'Pick a ${_segments[_segment].toLowerCase()} tone',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapMd,
            _SwatchWrap(
              key: ValueKey(_segment),
              palette: _activePalette,
              selected: _activeIndex,
              onSelect: _select,
            ).animate().fadeIn(duration: AppMotion.fast),
            AppSpacing.gapXl,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  textStyle: theme.textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Preview ────────────────────────────────────────────────────────

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.skin,
    required this.hair,
    required this.outfit,
  });

  final Color skin;
  final Color hair;
  final Color outfit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.standard,
        width: 180,
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [outfit.withValues(alpha: 0.9), outfit],
          ),
          border: Border.all(color: hair, width: 6),
          boxShadow: [
            BoxShadow(
              color: outfit.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          width: 140,
          height: 140,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: skin.withValues(alpha: 0.28),
          ),
          child: Icon(Icons.face_rounded, size: 96, color: skin),
        ),
      ),
    );
  }
}

// ─── Swatches ───────────────────────────────────────────────────────

class _SwatchWrap extends StatelessWidget {
  const _SwatchWrap({
    super.key,
    required this.palette,
    required this.selected,
    required this.onSelect,
  });

  final List<Color> palette;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (var i = 0; i < palette.length; i++)
          _Swatch(
            color: palette[i],
            selected: i == selected,
            onTap: () => onSelect(i),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: selected ? 3 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
            : null,
      ),
    );
  }
}
