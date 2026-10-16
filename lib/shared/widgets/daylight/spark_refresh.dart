import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:atlas_flutter_app/shared/themes/app_motion.dart';
import 'package:atlas_flutter_app/shared/widgets/brand/atlas_logo.dart';

/// Scroll physics for screens with [SparkRefresh]: always scrollable, with
/// a gentle bounce so there is something to pull.
const sparkRefreshPhysics =
    BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

/// Pull to refresh with the Atlas spark instead of a spinner: the spark
/// fades in and turns with the pull, then spins while [onRefresh] runs.
/// The child scroll view must use [sparkRefreshPhysics].
class SparkRefresh extends StatefulWidget {
  const SparkRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.topOffset = 8,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final double topOffset;

  @override
  State<SparkRefresh> createState() => _SparkRefreshState();
}

class _SparkRefreshState extends State<SparkRefresh> with SingleTickerProviderStateMixin {
  static const _trigger = 80.0;

  double _pull = 0;
  bool _armed = false;
  bool _refreshing = false;
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: AppMotion.ambientSparkBusy);

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    final m = n.metrics;
    final over = math.max(0.0, m.minScrollExtent - m.pixels);
    if (!_refreshing && over != _pull) {
      setState(() => _pull = over);
      final armed = over >= _trigger;
      if (armed != _armed) {
        _armed = armed;
        if (armed) HapticFeedback.mediumImpact();
      }
    }
    if (n is ScrollEndNotification || (n is ScrollUpdateNotification && n.dragDetails == null)) {
      if (_armed && !_refreshing) _run();
    }
    return false;
  }

  Future<void> _run() async {
    setState(() => _refreshing = true);
    if (!AppMotion.reduceMotion(context)) _spin.repeat();
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _spin.stop();
        setState(() {
          _refreshing = false;
          _armed = false;
          _pull = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _refreshing ? 1.0 : (_pull / _trigger).clamp(0.0, 1.0);
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(onNotification: _onScroll, child: widget.child),
        Positioned(
          top: widget.topOffset,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Opacity(
                opacity: t,
                child: AnimatedBuilder(
                  animation: _spin,
                  builder: (context, child) => Transform.rotate(
                    angle: _refreshing ? _spin.value * 2 * math.pi : t * math.pi,
                    child: Transform.scale(scale: .6 + .4 * t, child: child),
                  ),
                  child: const AtlasSpark(size: 28),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
