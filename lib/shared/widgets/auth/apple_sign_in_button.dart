import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' show AppleLogoPainter;

import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// "Continue with Apple", styled as a peer of the Google button: the same
/// 56pt paper pill and label style.
///
/// Apple permits a custom-styled button provided it uses Apple's own logo,
/// one of the approved titles ("Continue with Apple" here), keeps the mark
/// clear of other imagery and stays legible. The mark is painted with Apple's
/// [AppleLogoPainter] and is never recoloured: black on light, white on dark,
/// which is the one thing here that could risk a Guideline 4.8 rejection.
///
/// Renders nothing off Apple platforms, where the flow isn't offered.
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({
    super.key,
    required this.onPressed,
    this.label = 'Continue with Apple',
    this.height = 56,
  });

  final VoidCallback? onPressed;
  final String label;
  final double height;

  /// Whether this platform offers Sign in with Apple at all.
  static bool get isSupported => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  @override
  Widget build(BuildContext context) {
    if (!isSupported) return const SizedBox.shrink();
    final p = context.palette;
    final logoColor = p.isDark ? Colors.white : Colors.black;

    return Pressable(
      onTap: onPressed,
      haptic: PressHaptic.light,
      semanticLabel: label,
      child: AnimatedOpacity(
        duration: AppMotion.instant,
        opacity: onPressed == null ? .5 : 1,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Apple's mark, sized to sit optically level with the label. Its
              // visual centre is slightly low, so it lifts by a hair.
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: SizedBox(
                  width: 17,
                  height: 20,
                  child: CustomPaint(painter: AppleLogoPainter(color: logoColor)),
                ),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: AppTypography.sans(size: 15, weight: FontWeight.w700, color: p.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
