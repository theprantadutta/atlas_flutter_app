import 'package:flutter/widgets.dart';

/// Motion tokens: "calm by default, crisp on touch, joyful at milestones".
/// Gate every loop / ambient effect behind [reduceMotion].
class AppMotion {
  AppMotion._();

  static const Duration press = Duration(milliseconds: 90);
  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 360);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration deliberate = Duration(milliseconds: 900);

  static const Duration ambientGlow = Duration(seconds: 9);
  static const Duration ambientSpark = Duration(seconds: 5);
  static const Duration ambientSparkBusy = Duration(milliseconds: 1200);
  static const Duration ambientGlobe = Duration(seconds: 14);
  static const Duration ping = Duration(seconds: 2);
  static const Duration ambient = ambientGlobe; // legacy name

  static const Duration listStagger = Duration(milliseconds: 40);
  static const Duration barStagger = Duration(milliseconds: 50);
  static const Duration undoWindow = Duration(seconds: 4);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve gentle = Curves.easeInOut;
  static const Curve travel = Curves.easeInOutCubic;
  static const Curve celebrate = Curves.elasticOut;

  static const SpringDescription springSnappy = SpringDescription(mass: 1, stiffness: 420, damping: 30);

  static const double pressScaleRow = .96;
  static const double pressScaleCircle = .92;

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}
