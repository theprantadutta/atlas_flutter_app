import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:atlas_flutter_app/features/world/providers/world_view.dart';
import 'package:atlas_flutter_app/shared/widgets/daylight/daylight.dart';

/// The Atlas globe: a sunrise sphere that turns slowly, with every place you
/// have discovered glowing on it and the next one pinging.
///
/// Rotation is a single angle θ: it advances 360° per 14s (ambient), follows
/// horizontal drags with momentum (friction 0.92 per frame), and eases to a
/// tapped pin. Meridians scroll with θ to sell the turn. Only this layer
/// repaints; nothing above it rebuilds per frame.
class AtlasGlobe extends StatefulWidget {
  const AtlasGlobe({
    super.key,
    required this.places,
    this.nextId,
    this.size = 300,
    this.onTapPlace,
    this.dropId,
  });

  final List<Place> places;
  final String? nextId;
  final double size;
  final ValueChanged<Place>? onTapPlace;

  /// A place that was just discovered: the globe turns to it and its pin
  /// drops in from above.
  final String? dropId;

  @override
  State<AtlasGlobe> createState() => AtlasGlobeState();
}

class AtlasGlobeState extends State<AtlasGlobe> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _repaint = ValueNotifier<int>(0);

  double _theta = 20; // degrees
  double _velocity = 0; // degrees per frame, from drags
  bool _dragging = false;
  Duration _last = Duration.zero;
  Duration _now = Duration.zero;
  double _ambientBlend = 1; // eases back to ambient after a drag

  // Easing to a target angle.
  double? _fromTheta, _toTheta;
  Duration? _focusStart;
  Duration _focusLength = AppMotion.slow;

  // Drop-in for a new discovery.
  String? _dropping;
  Duration? _dropStart;

  List<_PinHit> _hits = const [];

  static const _degPerSecond = 360 / 14;

  bool get _reduce => AppMotion.reduceMotion(context);

  @override
  void initState() {
    super.initState();
    // Open with the next place just right of centre; the ambient turn then
    // carries it across the face of the globe.
    final next = widget.places.where((p) => p.id == widget.nextId).firstOrNull;
    if (next != null) _theta = next.lon - 30;
    _ticker.start();
    if (widget.dropId != null) _startDrop(widget.dropId!);
  }

  @override
  void didUpdateWidget(AtlasGlobe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dropId != null && widget.dropId != oldWidget.dropId) _startDrop(widget.dropId!);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _startDrop(String id) {
    final p = widget.places.where((p) => p.id == id).firstOrNull;
    if (p == null) return;
    focusOn(p, duration: AppMotion.deliberate);
    _dropping = id;
    _dropStart = null; // starts once the turn finishes
  }

  /// Turn the globe so [p] faces the viewer.
  void focusOn(Place p, {Duration duration = AppMotion.slow}) {
    // Shortest way round.
    var target = p.lon;
    while (target - _theta > 180) {
      target -= 360;
    }
    while (target - _theta < -180) {
      target += 360;
    }
    _fromTheta = _theta;
    _toTheta = target;
    _focusStart = null;
    _focusLength = _reduce ? Duration.zero : duration;
    _velocity = 0;
    _ambientBlend = 0;
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _now = elapsed;

    if (_toTheta != null) {
      _focusStart ??= elapsed;
      final t = _focusLength == Duration.zero
          ? 1.0
          : ((elapsed - _focusStart!).inMicroseconds / _focusLength.inMicroseconds).clamp(0.0, 1.0);
      _theta = _fromTheta! + (_toTheta! - _fromTheta!) * AppMotion.travel.transform(t);
      if (t >= 1) {
        _toTheta = null;
        if (_dropping != null) _dropStart = elapsed;
      }
    } else if (!_dragging) {
      if (_velocity.abs() > .01) {
        _theta += _velocity;
        _velocity *= .92;
      } else if (!_reduce) {
        // Ease back into the ambient turn after a drag or focus.
        _ambientBlend = (_ambientBlend + dt / 1.5).clamp(0.0, 1.0);
        _theta += _degPerSecond * dt * _ambientBlend;
      }
    }

    if (_dropStart != null && elapsed - _dropStart! > AppMotion.deliberate * 2) {
      _dropping = null;
      _dropStart = null;
    }
    _repaint.value++;
  }

  double get _dropT {
    if (_dropping == null) return 1;
    if (_dropStart == null) return 0;
    return ((_now - _dropStart!).inMicroseconds / AppMotion.medium.inMicroseconds).clamp(0.0, 1.0);
  }

  void _onTapUp(TapUpDetails d) {
    final hit = _hits
        .where((h) => (h.center - d.localPosition).distance < 24)
        .fold<_PinHit?>(null, (best, h) =>
            best == null || (h.center - d.localPosition).distance < (best.center - d.localPosition).distance
                ? h
                : best);
    if (hit == null) return;
    HapticFeedback.selectionClick();
    focusOn(hit.place);
    widget.onTapPlace?.call(hit.place);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final pad = 40.0; // room for the halo and labels
    return Semantics(
      label: 'Globe with ${widget.places.where((p) => p.discovered).length} places discovered',
      child: GestureDetector(
        onTapUp: _onTapUp,
        onHorizontalDragStart: (_) {
          _dragging = true;
          _toTheta = null;
          _velocity = 0;
        },
        onHorizontalDragUpdate: (d) {
          // Dragging right turns the near side right: θ decreases.
          _theta -= d.delta.dx / (size / 2) * (180 / math.pi) * .6;
        },
        onHorizontalDragEnd: (d) {
          _dragging = false;
          _velocity = -(d.velocity.pixelsPerSecond.dx / 60) / (size / 2) * (180 / math.pi) * .6;
          _ambientBlend = 0;
        },
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size(size + pad * 2, size + pad * 2),
            painter: _GlobePainter(
              state: this,
              repaint: _repaint,
              radius: size / 2,
              textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinHit {
  const _PinHit(this.place, this.center);
  final Place place;
  final Offset center;
}

class _GlobePainter extends CustomPainter {
  _GlobePainter({
    required this.state,
    required Listenable repaint,
    required this.radius,
    required this.textScaler,
  }) : super(repaint: repaint);

  final AtlasGlobeState state;
  final double radius;
  final TextScaler textScaler;

  static const _meridianGap = 48.0;
  static const _latitudeGap = 42.0;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = radius;
    final sphere = Rect.fromCircle(center: c, radius: r);

    // Halo and drop shadow.
    canvas.drawCircle(
      c,
      r + 30,
      Paint()
        ..shader = RadialGradient(
          colors: [AppColors.sunriseB.withValues(alpha: .25), AppColors.sunriseB.withValues(alpha: 0)],
          stops: const [0, .65 / .92],
        ).createShader(Rect.fromCircle(center: c, radius: (r + 30) * 1.0)),
    );
    canvas.drawCircle(
      c + const Offset(0, 30),
      r * .86,
      Paint()
        ..color = const Color(0x595B3CC4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34),
    );

    // The sphere.
    canvas.save();
    canvas.clipPath(Path()..addOval(sphere));
    canvas.drawRect(sphere, Paint()..shader = AppColors.globe.createShader(sphere));

    // Meridians (scrolling with θ) and latitudes, faded toward the rim.
    canvas.saveLayer(sphere, Paint());
    final line = Paint()
      ..color = AppColors.white.withValues(alpha: .35)
      ..strokeWidth = 1.5;
    final offset = -(state._theta * (300 / 360)) % _meridianGap;
    for (var x = sphere.left + offset; x < sphere.right; x += _meridianGap) {
      canvas.drawLine(Offset(x, sphere.top), Offset(x, sphere.bottom), line);
    }
    final lat = Paint()
      ..color = AppColors.white.withValues(alpha: .3)
      ..strokeWidth = 1.5;
    for (var y = sphere.bottom - _latitudeGap; y > sphere.top; y -= _latitudeGap) {
      canvas.drawLine(Offset(sphere.left, y), Offset(sphere.right, y), lat);
    }
    canvas.drawRect(
      sphere,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = RadialGradient(
          colors: const [Color(0xFF000000), Color(0xFF000000), Color(0x33000000)],
          stops: const [0, .78, 1.0],
        ).createShader(sphere),
    );
    canvas.restore();

    // Inner shade toward the bottom right, then the specular highlight.
    canvas.drawRect(
      sphere,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.16, -.2),
          radius: .62,
          colors: const [Color(0x00281459), Color(0x00281459), Color(0x59281459)],
          stops: const [0, .72, 1],
        ).createShader(sphere),
    );
    canvas.drawRect(
      sphere,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.4, -.5),
          radius: .41,
          colors: [AppColors.white.withValues(alpha: .55), AppColors.white.withValues(alpha: 0)],
        ).createShader(sphere),
    );
    canvas.restore();

    _paintPins(canvas, c, r);
  }

  void _paintPins(Canvas canvas, Offset c, double r) {
    final theta = state._theta;
    final places = state.widget.places;
    final nextId = state.widget.nextId;
    final pings = !AppMotion.reduceMotion(state.context);
    final hits = <_PinHit>[];

    // Back to front, so nearer pins draw on top.
    final projected = <(Place, Offset, double)>[];
    for (final p in places) {
      if (!p.discovered && p.id != nextId) continue;
      final d = (p.lon - theta) * math.pi / 180;
      final la = p.lat * math.pi / 180;
      final z = math.cos(d) * math.cos(la);
      if (z <= 0.02) continue;
      final pos = Offset(c.dx + r * math.sin(d) * math.cos(la), c.dy - r * math.sin(la));
      projected.add((p, pos, z));
    }
    projected.sort((a, b) => a.$3.compareTo(b.$3));

    for (final (p, pos0, z) in projected) {
      final isNext = p.id == nextId;
      final scale = .55 + .45 * z;
      final alpha = (z * 1.6).clamp(0.0, 1.0);
      var pos = pos0;

      // A fresh discovery drops in from 40px above with a little overshoot.
      if (p.id == state._dropping) {
        final t = state._dropT;
        if (t <= 0) continue;
        pos = pos.translate(0, -40 * (1 - AppMotion.emphasized.transform(t)));
      }

      if (isNext) {
        if (pings) {
          final t = (state._now.inMilliseconds % 2000) / 2000;
          final s = .6 + 1.6 * Curves.easeOut.transform(t);
          canvas.drawCircle(
            pos,
            14 * s * scale,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = AppColors.white.withValues(alpha: (1 - t) * alpha),
          );
        }
        canvas.drawCircle(pos, 10 * scale, Paint()..color = AppColors.white.withValues(alpha: .3 * alpha));
        canvas.drawCircle(pos, 6 * scale, Paint()..color = AppColors.white.withValues(alpha: alpha));
        canvas.drawCircle(pos, 3.5 * scale, Paint()..color = AppColors.ink.withValues(alpha: alpha));
      } else {
        canvas.drawCircle(
          pos,
          9 * scale,
          Paint()
            ..color = AppColors.white.withValues(alpha: .8 * alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawCircle(pos, 6 * scale, Paint()..color = AppColors.white.withValues(alpha: alpha));
      }
      hits.add(_PinHit(p, pos));

      // Labels only where the surface faces us, so the rim stays clean.
      if (z > .45 || isNext) {
        _label(canvas, pos, isNext ? '${p.name} · next' : p.name, isNext, alpha);
      }
    }
    state._hits = hits;
  }

  void _label(Canvas canvas, Offset pin, String text, bool next, double alpha) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: AppTypography.pinLabel.copyWith(
          color: (next ? AppColors.white : AppColors.ink).withValues(alpha: alpha),
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pin.dx + 10, pin.dy - (tp.height + 8) / 2, tp.width + 16, tp.height + 8),
      const Radius.circular(999),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = next
            ? AppColors.ink.withValues(alpha: alpha)
            : AppColors.white.withValues(alpha: .85 * alpha),
    );
    tp.paint(canvas, Offset(rect.left + 8, rect.top + 4));
  }

  @override
  bool shouldRepaint(_GlobePainter old) =>
      old.radius != radius || old.state != state || old.textScaler != textScaler;
}
