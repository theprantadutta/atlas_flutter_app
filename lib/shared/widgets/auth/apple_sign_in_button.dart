import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' show AppleLogoPainter;

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

/// "Continue with Apple", styled as a peer of the Google button.
///
/// Apple permits a custom-styled button provided it uses Apple's own logo,
/// one of the approved titles ("Continue with Apple" here), keeps the mark
/// clear of other imagery and stays legible — so this mirrors [AppButton]'s
/// outline variant (same 52pt height, 28pt radius, 1.5pt border, label style)
/// and paints the official mark via Apple's [AppleLogoPainter] rather than a
/// look-alike glyph. The result reads as one family with "Continue with
/// Google" instead of a black slab dropped into the layout.
///
/// Renders nothing off Apple platforms, where the flow isn't offered.
class AppleSignInButton extends StatefulWidget {
  const AppleSignInButton({
    super.key,
    required this.onPressed,
    this.label = 'Continue with Apple',
    this.height = 52,
    this.borderRadius = 28,
  });

  final VoidCallback? onPressed;
  final String label;
  final double height;
  final double borderRadius;

  /// Whether this platform offers Sign in with Apple at all.
  static bool get isSupported =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  @override
  State<AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends State<AppleSignInButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  bool get _isEnabled => widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    // Matches AppButton's press feel exactly.
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

  void _onTap() {
    if (!_isEnabled) return;
    HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppleSignInButton.isSupported) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Same accent AppButton.outline uses, so the pair matches in both themes.
    final foreground = isDark ? AppColors.secondaryLight : AppColors.primary;
    // The border and label follow the design system, but Apple's guidelines
    // forbid recolouring the mark itself — it stays black on light, white on
    // dark. Tinting it accent-purple is the one thing here that risks a
    // Guideline 4.8 rejection, so it doesn't.
    final logoColor = isDark ? Colors.white : Colors.black;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: GestureDetector(
        onTapDown: (_) {
          if (_isEnabled) _scaleController.forward();
        },
        onTapUp: (_) => _scaleController.reverse(),
        onTapCancel: () => _scaleController.reverse(),
        onTap: _onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isEnabled ? 1.0 : 0.5,
          child: Container(
            constraints: BoxConstraints(
              minHeight: widget.height,
              minWidth: double.infinity,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: foreground, width: 1.5),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isEnabled ? _onTap : null,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                splashColor: foreground.withValues(alpha: 0.1),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Apple's mark, sized to sit optically level with the
                      // 20pt icons the sibling buttons use. The logo's visual
                      // centre is slightly low, so it lifts by a hair.
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: SizedBox(
                          width: 17,
                          height: 20,
                          child: CustomPaint(
                            painter: AppleLogoPainter(color: logoColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.label,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: foreground),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
