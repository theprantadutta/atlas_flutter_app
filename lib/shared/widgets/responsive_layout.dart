import 'package:flutter/material.dart';

/// Responsive layout helper with breakpoints and adaptive builders.
///
/// Features:
/// - Static breakpoints: mobile (0-600), tablet (600-900), desktop (900+)
/// - Responsive padding based on screen width
/// - isMobile, isTablet, isDesktop getters
/// - Builder pattern for adaptive layouts
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Widget to display on mobile screens (< 600px).
  final Widget mobile;

  /// Widget to display on tablet screens (600-900px).
  /// Falls back to [mobile] if null.
  final Widget? tablet;

  /// Widget to display on desktop screens (> 900px).
  /// Falls back to [tablet] or [mobile] if null.
  final Widget? desktop;

  // ─── Breakpoints ───
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  // ─── Static Helpers ───

  /// Returns true if the screen width is in the mobile range.
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  /// Returns true if the screen width is in the tablet range.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Returns true if the screen width is in the desktop range.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  /// Returns the current device category.
  static DeviceCategory deviceCategory(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileBreakpoint) return DeviceCategory.mobile;
    if (width < tabletBreakpoint) return DeviceCategory.tablet;
    return DeviceCategory.desktop;
  }

  /// Returns responsive horizontal padding based on screen width.
  ///
  /// - Mobile: 16px
  /// - Tablet: 24px
  /// - Desktop: 32px
  static EdgeInsets responsivePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 16);
    }
    if (width < tabletBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 32);
  }

  /// Returns a symmetric horizontal padding value (just the number).
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileBreakpoint) return 16;
    if (width < tabletBreakpoint) return 24;
    return 32;
  }

  /// Returns the number of columns to use in grid layouts.
  static int gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileBreakpoint) return 2;
    if (width < tabletBreakpoint) return 3;
    return 4;
  }

  /// Returns a constrained max width suitable for content.
  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileBreakpoint) return width;
    if (width < tabletBreakpoint) return 720;
    return 1080;
  }

  /// Convenience: wraps [child] in a centered, max-width constrained container.
  static Widget constrained({
    required Widget child,
    required BuildContext context,
    double? maxWidth,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? maxContentWidth(context),
        ),
        child: child,
      ),
    );
  }

  /// Select a value based on the current screen size.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= tabletBreakpoint) return desktop ?? tablet ?? mobile;
    if (width >= mobileBreakpoint) return tablet ?? mobile;
    return mobile;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= tabletBreakpoint) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= mobileBreakpoint) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

/// Device size category.
enum DeviceCategory { mobile, tablet, desktop }

/// A builder version of [ResponsiveLayout] that provides the device category.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  /// Builder that receives the current [DeviceCategory] and constraints.
  final Widget Function(
    BuildContext context,
    DeviceCategory category,
    BoxConstraints constraints,
  ) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        DeviceCategory category;
        if (constraints.maxWidth >= ResponsiveLayout.tabletBreakpoint) {
          category = DeviceCategory.desktop;
        } else if (constraints.maxWidth >=
            ResponsiveLayout.mobileBreakpoint) {
          category = DeviceCategory.tablet;
        } else {
          category = DeviceCategory.mobile;
        }
        return builder(context, category, constraints);
      },
    );
  }
}
