import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/shared/themes/app_breakpoints.dart';
import 'package:atlas_flutter_app/shared/themes/app_spacing.dart';

/// Caps a scrolling column at a comfortable reading width and centres it.
///
/// Screens keep their existing phone-first `ListView`/`Column` bodies; wrapping
/// the *padding* rather than the scroll view means the scrollbar still runs
/// full height and nothing has to be restructured.
///
/// On a phone this is a no-op — [AppBreakpoints.readingColumn] is wider than
/// any phone, so the padding stays exactly as it was.
class AdaptiveContentPadding extends StatelessWidget {
  const AdaptiveContentPadding({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.readingColumn,
    this.horizontal = AppSpacing.gutter,
  });

  final Widget child;
  final double maxWidth;
  final double horizontal;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final slack = width - maxWidth;
    // Split the leftover space evenly, on top of the normal gutter.
    final side = slack > 0 ? slack / 2 : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal + side),
      child: child,
    );
  }
}

/// The standard padding for a screen's main scroll view.
///
/// One call replaces the `EdgeInsets.fromLTRB(gutter, top, gutter,
/// bottomNavSpace)` that every screen used to hardcode, and folds in two
/// things that only matter off a phone:
///
///  * **Side slack.** Above [AppBreakpoints.readingColumn] the leftover width
///    is split evenly left and right, so a row that was designed at 390pt
///    doesn't stretch to 1900pt on a 13" iPad.
///  * **Bottom space.** The 112pt reserved for the floating nav capsule is
///    dead space once navigation moves to the rail, so wide layouts get a
///    normal gutter back.
EdgeInsets adaptiveScreenPadding(
  BuildContext context, {
  double top = AppSpacing.md,
  double maxWidth = AppBreakpoints.readingColumn,
}) {
  final size = AppBreakpoints.of(context);
  final width = MediaQuery.sizeOf(context).width;

  // The rail already occupies its own column, so only the content width counts.
  final slack = width - maxWidth;
  final side = slack > 0 ? slack / 2 : 0.0;

  return EdgeInsets.fromLTRB(
    AppSpacing.gutter + side,
    top,
    AppSpacing.gutter + side,
    size.usesSideNav ? AppSpacing.xxl : AppSpacing.bottomNavSpace,
  );
}

/// Centres a fixed-width column of content, filling the rest with the scaffold
/// background. For screens that are a single card or form rather than a list.
class AdaptiveCenteredColumn extends StatelessWidget {
  const AdaptiveCenteredColumn({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.readingColumn,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

/// Lays children out in one column on a phone and a responsive grid on wider
/// screens, so card lists fill an iPad instead of running as one long ribbon.
///
/// Uses a `Wrap` rather than a `GridView` deliberately: cards in Atlas have
/// intrinsic heights (a habit row is shorter than an achievement card), and a
/// grid would force them all to the tallest cell.
class AdaptiveCardGrid extends StatelessWidget {
  const AdaptiveCardGrid({
    super.key,
    required this.children,
    this.spacing = AppSpacing.sm,
    this.minColumnWidth = 320,
  });

  final List<Widget> children;
  final double spacing;

  /// A column narrower than this reads as cramped, so we drop a column instead.
  final double minColumnWidth;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        // How many columns fit, capped by the window size class so an
        // ultra-wide window doesn't produce five thin columns.
        final fits = ((available + spacing) / (minColumnWidth + spacing))
            .floor()
            .clamp(1, 3);
        final columns =
            fits.clamp(1, AppBreakpoints.gridColumns(context.windowSize));

        if (columns <= 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }

        final itemWidth = (available - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

/// A list pane beside a detail pane on wide screens; on a phone only the list
/// shows and the detail is reached by navigation as before.
///
/// [detail] is built lazily so a screen with nothing selected can show a
/// placeholder without constructing a real detail view.
class AdaptiveTwoPane extends StatelessWidget {
  const AdaptiveTwoPane({
    super.key,
    required this.list,
    required this.detail,
    this.listWidth = AppBreakpoints.listPaneWidth,
  });

  final Widget list;
  final WidgetBuilder detail;
  final double listWidth;

  @override
  Widget build(BuildContext context) {
    if (!context.windowSize.usesTwoPane) return list;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: listWidth, child: list),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: .5),
        ),
        Expanded(child: Builder(builder: detail)),
      ],
    );
  }
}

/// Daylight's screen padding: the gutter, plus whatever side slack holds the
/// content to [maxWidth] on a wide window. On a phone it is exactly
/// `EdgeInsets.fromLTRB(gutter, top, gutter, bottom)`.
///
/// Inside the app shell on a wide window, the shell already holds the tabs to
/// a reading column and reports that width through [MediaQuery], so tab
/// screens and the pages pushed over them get the same measure without
/// counting the nav rail twice.
EdgeInsets readableInsets(
  BuildContext context, {
  required double top,
  required double bottom,
  double maxWidth = AppBreakpoints.readingColumn,
}) {
  final slack = MediaQuery.sizeOf(context).width - maxWidth;
  final side = AppSpacing.gutter + (slack > 0 ? slack / 2 : 0.0);
  return EdgeInsets.fromLTRB(side, top, side, bottom);
}

