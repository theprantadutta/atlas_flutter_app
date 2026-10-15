import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/features/avatar/providers/avatar_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart'
    show currentUserIdProvider;
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// The avatar palettes. Stored as indices, so the lengths and order must
/// stay stable; the outfit hues are the Daylight category colors.
class AvatarPalettes {
  AvatarPalettes._();

  static const skin = [
    Color(0xFFF6D5B8),
    Color(0xFFE8B98E),
    Color(0xFFC68A5E),
    Color(0xFF8D5A3C),
    Color(0xFF5C3A29),
  ];

  static const hair = [
    Color(0xFF2B2B2B),
    Color(0xFF6B4423),
    Color(0xFFC58B3B),
    Color(0xFF8E6CFF),
    Color(0xFFFF6A4D),
  ];

  static const outfit = [
    AppColors.violet,
    AppColors.leaf,
    AppColors.amber,
    AppColors.coral,
    AppColors.sky,
  ];
}

/// Your avatar: a small studio for skin, hair and outfit, with the stats
/// it has grown from what you tend.
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
  bool _initialized = false;
  bool _dirty = false;

  static const _segments = ['Skin', 'Hair', 'Outfit'];

  /// Seed the editor from the stored appearance the first time it loads, so
  /// in-progress edits aren't clobbered by later stream emissions.
  void _maybeInit(Avatar? avatar) {
    if (_initialized || avatar == null) return;
    final idx = avatarIndicesFromJson(avatar.appearanceData);
    _skin = idx.skin.clamp(0, AvatarPalettes.skin.length - 1);
    _hair = idx.hair.clamp(0, AvatarPalettes.hair.length - 1);
    _outfit = idx.outfit.clamp(0, AvatarPalettes.outfit.length - 1);
    _initialized = true;
  }

  List<Color> get _activePalette => switch (_segment) {
        0 => AvatarPalettes.skin,
        1 => AvatarPalettes.hair,
        _ => AvatarPalettes.outfit,
      };

  int get _activeIndex => switch (_segment) {
        0 => _skin,
        1 => _hair,
        _ => _outfit,
      };

  void _select(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _dirty = true;
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

  Future<void> _save() async {
    final userId = ref.read(currentUserIdProvider);
    await ref.read(avatarActionsProvider).saveAppearance(
          userId,
          skin: _skin,
          hair: _hair,
          outfit: _outfit,
        );
    if (!mounted) return;
    setState(() => _dirty = false);
    AtlasToast.success(context, 'Looking good');
  }

  Future<void> _rename(String current) async {
    final controller = TextEditingController(text: current);
    final name = await showAtlasSheet<String>(
      context,
      builder: (context) {
        final p = context.palette;
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Name your avatar',
                  style: AppTypography.subScreenTitle.copyWith(color: p.textPrimary)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 24,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (v) => Navigator.of(context).pop(v),
                style: AppTypography.sans(size: 16, weight: FontWeight.w600, color: p.textPrimary),
                decoration: const InputDecoration(hintText: 'A name', counterText: ''),
              ),
              const SizedBox(height: AppSpacing.md),
              PillButton(
                label: 'Save name',
                height: 56,
                expand: true,
                onTap: () => Navigator.of(context).pop(controller.text),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == current) return;
    await ref.read(avatarActionsProvider).rename(ref.read(currentUserIdProvider), trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final async = ref.watch(avatarStreamProvider);
    final avatar = async.value;
    _maybeInit(avatar);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.xxl),
          children: [
            ScreenHeader(title: 'Your avatar', onBack: () => context.pop()),
            const SizedBox(height: AppSpacing.md),
            if (avatar == null && async.isLoading)
              const Skeleton(height: 320, radius: AppSpacing.radiusXl)
            else ...[
              Container(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                decoration: BoxDecoration(
                  gradient: p.letter,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Column(
                  children: [
                    _AvatarPreview(
                      skin: AvatarPalettes.skin[_skin],
                      hair: AvatarPalettes.hair[_hair],
                      outfit: AvatarPalettes.outfit[_outfit],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Pressable(
                      onTap: avatar == null ? null : () => _rename(avatar.name),
                      semanticLabel: 'Rename ${avatar?.name ?? 'avatar'}',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(avatar?.name ?? 'Adventurer',
                              style: AppTypography.section.copyWith(color: p.textPrimary)),
                          const SizedBox(width: 6),
                          AtlasIcon(Symbols.edit_rounded, size: 18, color: p.textMuted),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Level ${avatar?.level ?? 1}',
                        style: AppTypography.metaStrong.copyWith(color: p.textMuted)),
                    const SizedBox(height: AppSpacing.md),
                    if (avatar != null) _Stats(avatar: avatar),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg - 4),
              SegmentedPill(
                labels: _segments,
                index: _segment,
                onChanged: (i) => setState(() => _segment = i),
              ),
              const SizedBox(height: AppSpacing.md),
              AtlasTile(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: Row(
                    key: ValueKey(_segment),
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (var i = 0; i < _activePalette.length; i++)
                        _Swatch(
                          color: _activePalette[i],
                          selected: i == _activeIndex,
                          label: '${_segments[_segment]} ${i + 1}',
                          onTap: () => _select(i),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedSwitcher(
                duration: AppMotion.fast,
                child: _dirty
                    ? PillButton(
                        key: const ValueKey('save'),
                        label: 'Save',
                        height: 56,
                        expand: true,
                        onTap: _save,
                      )
                    : Container(
                        key: const ValueKey('saved'),
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p.track,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          AtlasIcon(Symbols.check_rounded, size: 18, color: p.textMuted),
                          const SizedBox(width: 6),
                          Text('Saved', style: AppTypography.button.copyWith(color: p.textMuted)),
                        ]),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.avatar});
  final Avatar avatar;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget stat(String label, int value, IconData icon, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: p.letterSecondaryButton,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(children: [
              AtlasIcon(icon, size: 20, filled: true, color: p.category(color)),
              const SizedBox(height: 6),
              CountUpText(
                value: value,
                style: AppTypography.display(size: 22, color: p.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(label, style: AppTypography.tiny.copyWith(color: p.textMuted)),
            ]),
          ),
        );
    return Row(children: [
      stat('Body', avatar.strength, Symbols.directions_run_rounded, AppColors.coral),
      const SizedBox(width: 8),
      stat('Mind', avatar.wisdom, Symbols.self_improvement_rounded, AppColors.violet),
      const SizedBox(width: 8),
      stat('Craft', avatar.intelligence, Symbols.menu_book_rounded, AppColors.sky),
    ]);
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.skin, required this.hair, required this.outfit});

  final Color skin;
  final Color hair;
  final Color outfit;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      width: 164,
      height: 164,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(shape: BoxShape.circle, color: hair),
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.standard,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(outfit, Colors.white, .25)!, outfit],
          ),
        ),
        child: Container(
          width: 120,
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: skin.withValues(alpha: .35)),
          child: AtlasIcon(Symbols.face_rounded, size: 88, filled: true, color: skin),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      circle: true,
      semanticLabel: '$label${selected ? ', selected' : ''}',
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.emphasized,
        width: 52,
        height: 52,
        padding: EdgeInsets.all(selected ? 4 : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: selected ? p.action : Colors.transparent, width: 2.5),
        ),
        child: Container(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: selected
              ? const AtlasIcon(Symbols.check_rounded, size: 20, color: AppColors.white, weight: 600)
              : null,
        ),
      ),
    );
  }
}
