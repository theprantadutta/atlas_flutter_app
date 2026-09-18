import 'package:flutter/widgets.dart';

/// How much horizontal room a screen actually has.
///
/// Atlas was designed phone-first, as a single vertical column. On an iPad that
/// column either stretches into unreadable full-width rows or strands itself at
/// the top of a mostly empty page — which is what App Review means by "not
/// optimised for iPad".
///
/// Rather than sprinkle width checks through twenty-one screens, everything
/// keys off this one enum. The thresholds follow Material's window size classes
/// so they line up with what the OS itself considers a phone, a split-view pane
/// and a full tablet.
enum AppWindowSize {
  /// Phones, and iPad slide-over / narrow split view. The original design.
  compact,

  /// Large phones in landscape, iPad half-split. Content gets a little room.
  medium,

  /// iPad full screen and desktop. Side navigation, real multi-column layouts.
  expanded;

  bool get isCompact => this == AppWindowSize.compact;
  bool get isMedium => this == AppWindowSize.medium;
  bool get isExpanded => this == AppWindowSize.expanded;

  /// True once there's room for side navigation instead of a bottom bar.
  bool get usesSideNav => this != AppWindowSize.compact;

  /// True when a list and its detail can sit side by side.
  bool get usesTwoPane => this == AppWindowSize.expanded;
}

class AppBreakpoints {
  AppBreakpoints._();

  /// Below this, treat it as a phone.
  static const double medium = 640;

  /// At or above this, there's room for two panes.
  static const double expanded = 1000;

  /// The widest a single column of text or cards should ever get. Beyond this
  /// rows become hard to scan — the eye loses the start of the next line.
  static const double readingColumn = 720;

  /// Width of the side navigation once [AppWindowSize.usesSideNav] is true.
  static const double navRailWidth = 96;

  /// Width of the list pane in a two-pane layout.
  static const double listPaneWidth = 380;

  static AppWindowSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static AppWindowSize fromWidth(double width) {
    if (width >= expanded) return AppWindowSize.expanded;
    if (width >= medium) return AppWindowSize.medium;
    return AppWindowSize.compact;
  }

  /// How many columns a grid of cards should use at this width.
  static int gridColumns(AppWindowSize size) => switch (size) {
        AppWindowSize.compact => 1,
        AppWindowSize.medium => 2,
        AppWindowSize.expanded => 3,
      };
}

/// Convenience so screens can read `context.windowSize` inline.
extension AppWindowSizeContext on BuildContext {
  AppWindowSize get windowSize => AppBreakpoints.of(this);
  bool get isCompactWindow => windowSize.isCompact;
  bool get isWideWindow => !windowSize.isCompact;
}
