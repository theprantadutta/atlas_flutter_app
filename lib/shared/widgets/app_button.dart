import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../themes/app_colors.dart';

/// Button variants available in the design system.
enum AppButtonVariant { primary, secondary, outline, ghost }

/// A modern, animated button with multiple style variants.
///
/// Features:
/// - Four variants: primary (gradient), secondary (tinted), outline, ghost
/// - Loading state with spinner
/// - Optional leading icon
/// - Haptic feedback on tap
/// - Scale animation on press
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.height = 52,
    this.borderRadius = 28,
    this.fontSize,
  });

  /// The text displayed on the button.
  final String label;

  /// Called when the button is tapped. Disabled when null or [isLoading].
  final VoidCallback? onPressed;

  /// The visual style variant.
  final AppButtonVariant variant;

  /// Optional leading icon shown before the label.
  final IconData? icon;

  /// When true, shows a spinner and disables interaction.
  final bool isLoading;

  /// When true, the button expands to fill available width.
  final bool isExpanded;

  /// Minimum height of the button.
  final double height;

  /// Border radius of the button.
  final double borderRadius;

  /// Optional font size override for the label.
  final double? fontSize;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (_isEnabled) _scaleController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  void _onTap() {
    if (!_isEnabled) return;
    HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isEnabled ? 1.0 : 0.5,
          child: _buildButton(theme, isDark),
        ),
      ),
    );
  }

  Widget _buildButton(ThemeData theme, bool isDark) {
    return switch (widget.variant) {
      AppButtonVariant.primary => _buildPrimaryButton(theme, isDark),
      AppButtonVariant.secondary => _buildSecondaryButton(theme, isDark),
      AppButtonVariant.outline => _buildOutlineButton(theme, isDark),
      AppButtonVariant.ghost => _buildGhostButton(theme, isDark),
    };
  }

  // ─── Primary: Gradient Background ───
  Widget _buildPrimaryButton(ThemeData theme, bool isDark) {
    return Container(
      constraints: BoxConstraints(
        minHeight: widget.height,
        minWidth: widget.isExpanded ? double.infinity : 0,
      ),
      decoration: BoxDecoration(
        gradient: _isEnabled
            ? (isDark ? AppColors.secondaryGradient : AppColors.primaryGradient)
            : null,
        color: _isEnabled ? null : theme.colorScheme.onSurface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: _isEnabled
            ? [
                BoxShadow(
                  color: (isDark ? AppColors.secondaryLight : AppColors.primary)
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isEnabled ? _onTap : null,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: _buildContent(
              Colors.white,
              theme,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Secondary: Tinted Background ───
  Widget _buildSecondaryButton(ThemeData theme, bool isDark) {
    final tintColor = isDark ? AppColors.secondaryLight : AppColors.primary;

    return Container(
      constraints: BoxConstraints(
        minHeight: widget.height,
        minWidth: widget.isExpanded ? double.infinity : 0,
      ),
      decoration: BoxDecoration(
        color: tintColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isEnabled ? _onTap : null,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          splashColor: tintColor.withValues(alpha: 0.15),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: _buildContent(tintColor, theme),
          ),
        ),
      ),
    );
  }

  // ─── Outline: Border Only ───
  Widget _buildOutlineButton(ThemeData theme, bool isDark) {
    final borderColor = isDark ? AppColors.secondaryLight : AppColors.primary;

    return Container(
      constraints: BoxConstraints(
        minHeight: widget.height,
        minWidth: widget.isExpanded ? double.infinity : 0,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isEnabled ? _onTap : null,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          splashColor: borderColor.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: _buildContent(borderColor, theme),
          ),
        ),
      ),
    );
  }

  // ─── Ghost: No Background ───
  Widget _buildGhostButton(ThemeData theme, bool isDark) {
    final textColor = isDark ? AppColors.secondaryLight : AppColors.primary;

    return Container(
      constraints: BoxConstraints(
        minHeight: widget.height,
        minWidth: widget.isExpanded ? double.infinity : 0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isEnabled ? _onTap : null,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          splashColor: textColor.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: _buildContent(textColor, theme),
          ),
        ),
      ),
    );
  }

  // ─── Inner Content ───
  Widget _buildContent(Color foreground, ThemeData theme) {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(foreground),
          ),
        ),
      );
    }

    final labelWidget = Text(
      widget.label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: foreground,
        fontSize: widget.fontSize,
      ),
      textAlign: TextAlign.center,
    );

    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize:
            widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(widget.icon, color: foreground, size: 20),
          const SizedBox(width: 10),
          labelWidget,
        ],
      );
    }

    return Center(child: labelWidget);
  }
}
