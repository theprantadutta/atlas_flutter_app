import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:atlas_flutter_app/shared/themes/app_colors.dart';
import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/themes/app_typography.dart';
import 'package:atlas_flutter_app/shared/widgets/brand/atlas_logo.dart';

/// Rows fade and rise 12px on first appear, staggered by 40ms and capped at
/// 8 rows. Each [id] animates only once per app session, so rebuilds and tab
/// round trips never replay it.
class EntryFade extends StatefulWidget {
  const EntryFade({
    super.key,
    required this.id,
    required this.index,
    required this.child,
    this.offset = 12,
    this.stagger = AppMotion.listStagger,
    this.duration = AppMotion.medium,
  });

  final String id;
  final int index;
  final Widget child;
  final double offset;
  final Duration stagger;
  final Duration duration;

  static final Set<String> _seen = {};

  /// For tests.
  @visibleForTesting
  static void resetSeen() => _seen.clear();

  @override
  State<EntryFade> createState() => _EntryFadeState();
}

class _EntryFadeState extends State<EntryFade>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void initState() {
    super.initState();
    if (EntryFade._seen.add(widget.id)) {
      final c = _c = AnimationController(vsync: this, duration: widget.duration);
      final delay = widget.stagger * math.min(widget.index, 8);
      Future<void>.delayed(delay, () {
        if (mounted) c.forward();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) _c?.value = 1;
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) return widget.child;
    return AnimatedBuilder(
      animation: c,
      child: widget.child,
      builder: (context, child) {
        final t = AppMotion.standard.transform(c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Collapses its child to zero height (and fades it) when [collapsed] turns
/// true; used for the row that slides out of "Up next" after a tend.
class CollapseOut extends StatelessWidget {
  const CollapseOut({
    super.key,
    required this.collapsed,
    required this.child,
    this.duration = AppMotion.fast,
  });

  final bool collapsed;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: collapsed ? 0 : 1),
        duration: AppMotion.reduceMotion(context) ? AppMotion.instant : duration,
        curve: AppMotion.standard,
        child: child,
        builder: (context, t, child) => ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: t,
            child: Opacity(opacity: t, child: child),
          ),
        ),
      );
}

/// The "+20 XP" chip that rises 28px and fades over 600ms from a point on
/// screen, in sunrise gradient text. Shown in the root overlay.
class XpFloat {
  XpFloat._();

  /// Float from the center of the widget behind [anchor].
  static void fromKey(BuildContext context, GlobalKey anchor, int xp) {
    final box = anchor.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    show(context, center, xp);
  }

  static void show(BuildContext context, Offset globalCenter, int xp) {
    if (xp <= 0) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final reduce = AppMotion.reduceMotion(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _XpFloatChip(
        center: globalCenter,
        xp: xp,
        reduce: reduce,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _XpFloatChip extends StatefulWidget {
  const _XpFloatChip({
    required this.center,
    required this.xp,
    required this.reduce,
    required this.onDone,
  });
  final Offset center;
  final int xp;
  final bool reduce;
  final VoidCallback onDone;

  @override
  State<_XpFloatChip> createState() => _XpFloatChipState();
}

class _XpFloatChipState extends State<_XpFloatChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AppMotion.slow)
        ..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.center.dx - 60,
      top: widget.center.dy - 16,
      width: 120,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = AppMotion.standard.transform(_c.value);
            final fade = _c.value < .5 ? 1.0 : 1 - (_c.value - .5) * 2;
            return Opacity(
              opacity: fade.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, widget.reduce ? 0 : -28 * t),
                child: child,
              ),
            );
          },
          child: Center(
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => AppColors.sunrise.createShader(b),
              child: Text(
                '+${widget.xp} XP',
                style: AppTypography.display(size: 20, color: AppColors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Eight small sparks bursting radially from the center, then fading
/// (900ms). Played once by toggling [play] to a new value (e.g. a counter).
class SparkBurst extends StatefulWidget {
  const SparkBurst({super.key, required this.trigger, this.radius = 70});

  /// Change this value to play the burst again. 0 means "never played".
  final int trigger;
  final double radius;

  @override
  State<SparkBurst> createState() => _SparkBurstState();
}

class _SparkBurstState extends State<SparkBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AppMotion.deliberate);

  @override
  void didUpdateWidget(SparkBurst old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger && widget.trigger > 0) {
      if (AppMotion.reduceMotion(context)) return;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          if (!_c.isAnimating) return const SizedBox.shrink();
          final t = AppMotion.standard.transform(_c.value);
          final fade = (1 - _c.value).clamp(0.0, 1.0);
          return SizedBox(
            width: widget.radius * 2 + 20,
            height: widget.radius * 2 + 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (var i = 0; i < 8; i++)
                  Transform.translate(
                    offset: Offset.fromDirection(
                      i * math.pi / 4 - math.pi / 2,
                      widget.radius * t,
                    ),
                    child: Opacity(
                      opacity: fade,
                      child: Transform.rotate(
                        angle: t * math.pi / 3,
                        child: AtlasSpark(size: i.isEven ? 14 : 10),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
