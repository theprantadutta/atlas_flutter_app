import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/core/constants/gamification_constants.dart';
import 'package:atlas_flutter_app/features/avatar/providers/avatar_provider.dart';
import 'package:atlas_flutter_app/features/avatar/widgets/avatar_display.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/widgets/app_button.dart';
import 'package:atlas_flutter_app/shared/widgets/app_card.dart';
import 'package:atlas_flutter_app/shared/widgets/app_error_widget.dart';
import 'package:atlas_flutter_app/shared/widgets/loading_shimmer.dart';
import 'package:atlas_flutter_app/shared/widgets/xp_progress_bar.dart';

class AvatarScreen extends ConsumerStatefulWidget {
  const AvatarScreen({super.key});

  @override
  ConsumerState<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends ConsumerState<AvatarScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['Skin', 'Hair', 'Eyes', 'Clothing', 'Accessories'];
  static const _tabIcons = [
    Icons.face_rounded,
    Icons.content_cut_rounded,
    Icons.visibility_rounded,
    Icons.checkroom_rounded,
    Icons.watch_rounded,
  ];

  // Placeholder customization options
  static const _skinColors = [
    Color(0xFFFADCBC), Color(0xFFF0C8A0), Color(0xFFD4A574),
    Color(0xFFC08C5A), Color(0xFF8D5524), Color(0xFF6B3A1F),
    Color(0xFFFFF3E0), Color(0xFFFFE0B2),
  ];

  static const _hairColors = [
    Color(0xFF2C1810), Color(0xFF4A2C17), Color(0xFF8B4513),
    Color(0xFFD4A574), Color(0xFFFFD700), Color(0xFFFF6347),
    Color(0xFF4A90D9), Color(0xFF8B5CF6),
  ];

  static const _eyeColors = [
    Color(0xFF4A90D9), Color(0xFF2E7D32), Color(0xFF8D6E63),
    Color(0xFF455A64), Color(0xFF6A1B9A), Color(0xFFFF8F00),
    Color(0xFF37474F), Color(0xFF1B5E20),
  ];

  final Map<String, int> _selectedOptions = {
    'skin': 0,
    'hair': 0,
    'eyes': 0,
    'clothing': 0,
    'accessories': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(avatarProvider.notifier).setTab(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveAppearance() {
    ref.read(avatarProvider.notifier).updateAppearance(_selectedOptions.map(
          (key, value) => MapEntry(key, value),
        ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Appearance saved!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final avatarState = ref.watch(avatarProvider);
    final avatar = avatarState.avatar;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Avatar',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: avatarState.isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingShimmer.avatar(size: 100),
                  const SizedBox(height: 24),
                  LoadingShimmer.card(height: 80),
                ],
              ),
            )
          : avatarState.error != null && avatar == null
              ? AppErrorDisplay(
                  message: avatarState.error!,
                  onRetry: () =>
                      ref.read(avatarProvider.notifier).loadAvatar(),
                )
              : Column(
                  children: [
                    // Avatar preview section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _buildPreviewSection(theme, isDark, avatar),
                    ),
                    const SizedBox(height: 16),

                    // Attribute bars
                    if (avatar != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildAttributes(theme, avatar),
                      ),
                    const SizedBox(height: 16),

                    // Tab bar
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      indicatorColor: AppColors.primary,
                      tabAlignment: TabAlignment.start,
                      tabs: List.generate(_tabs.length, (i) {
                        return Tab(
                          icon: Icon(_tabIcons[i], size: 20),
                          text: _tabs[i],
                        );
                      }),
                    ),

                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildColorGrid('skin', _skinColors, avatar),
                          _buildColorGrid('hair', _hairColors, avatar),
                          _buildColorGrid('eyes', _eyeColors, avatar),
                          _buildItemGrid('clothing', 12, avatar),
                          _buildItemGrid('accessories', 8, avatar),
                        ],
                      ),
                    ),

                    // Save button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: AppButton(
                        label: 'Save Changes',
                        icon: Icons.save_rounded,
                        onPressed: _saveAppearance,
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPreviewSection(ThemeData theme, bool isDark, dynamic avatar) {
    final level = avatar?.level ?? 1;
    final currentXp = avatar?.currentXp ?? 0;
    final requiredXp = GamificationConstants.xpRequiredForLevel(level + 1);
    final name = avatar?.name ?? 'Adventurer';

    return Column(
      children: [
        AvatarDisplay(
          avatar: avatar,
          size: 100,
          showLevel: true,
          showXpRing: true,
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.tertiary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Level $level',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.tertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        XpProgressBar(
          currentXp: currentXp,
          requiredXp: requiredXp > 0 ? requiredXp : 100,
          currentLevel: level,
          height: 16,
          showLabels: true,
          showXpText: true,
        ),
      ],
    );
  }

  Widget _buildAttributes(ThemeData theme, dynamic avatar) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _AttributeRow(
            label: 'Strength',
            value: avatar.strength,
            color: AppColors.streakFlame,
            icon: Icons.fitness_center_rounded,
          ),
          const SizedBox(height: 10),
          _AttributeRow(
            label: 'Wisdom',
            value: avatar.wisdom,
            color: AppColors.info,
            icon: Icons.auto_stories_rounded,
          ),
          const SizedBox(height: 10),
          _AttributeRow(
            label: 'Intelligence',
            value: avatar.intelligence,
            color: AppColors.badgeEpic,
            icon: Icons.psychology_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildColorGrid(String key, List<Color> colors, dynamic avatar) {
    final unlockedItems = avatar?.unlockedItems ?? <String>[];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final isSelected = _selectedOptions[key] == index;
        final isLocked = index > 4 && !unlockedItems.contains('${key}_$index');

        return GestureDetector(
          onTap: isLocked ? null : () {
            setState(() => _selectedOptions[key] = index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: colors[index],
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 3)
                  : Border.all(
                      color: Colors.grey.withValues(alpha: 0.3), width: 1),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isLocked
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  )
                : isSelected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                    : null,
          ),
        );
      },
    );
  }

  Widget _buildItemGrid(String key, int itemCount, dynamic avatar) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unlockedItems = avatar?.unlockedItems ?? <String>[];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final isSelected = _selectedOptions[key] == index;
        final isLocked = index > 3 && !unlockedItems.contains('${key}_$index');

        return GestureDetector(
          onTap: isLocked ? null : () {
            setState(() => _selectedOptions[key] = index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.cardBorderDark
                        : AppColors.cardBorderLight),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  _itemIcon(key, index),
                  size: 28,
                  color: isLocked
                      ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                      : (isSelected ? AppColors.primary : theme.colorScheme.onSurfaceVariant),
                ),
                if (isLocked)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                if (isSelected && !isLocked)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _itemIcon(String key, int index) {
    if (key == 'clothing') {
      const icons = [
        Icons.checkroom_rounded, Icons.dry_cleaning_rounded,
        Icons.accessibility_new_rounded, Icons.shield_rounded,
        Icons.security_rounded, Icons.military_tech_rounded,
        Icons.auto_awesome_rounded, Icons.star_rounded,
        Icons.diamond_rounded, Icons.workspace_premium_rounded,
        Icons.local_fire_department_rounded, Icons.bolt_rounded,
      ];
      return icons[index % icons.length];
    } else {
      const icons = [
        Icons.watch_rounded, Icons.headphones_rounded,
        Icons.sports_esports_rounded, Icons.emoji_events_rounded,
        Icons.pets_rounded, Icons.music_note_rounded,
        Icons.palette_rounded, Icons.flare_rounded,
      ];
      return icons[index % icons.length];
    }
  }
}

class _AttributeRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _AttributeRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (value / 100).clamp(0.0, 1.0);

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
