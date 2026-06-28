// Generates the Atlas app-icon / splash assets (the "Living World" mark):
// a twilight squircle scene with a warm sun and layered hills.
//
//   dart run tool/gen_icon.dart
//
// Produces assets/brand/{atlas_icon,atlas_icon_fg,atlas_splash}.png, which are
// then consumed by flutter_launcher_icons + flutter_native_splash.

import 'dart:io';
import 'package:image/image.dart' as img;

List<int> _lerp(List<int> a, List<int> b, double t) =>
    [for (var i = 0; i < 3; i++) (a[i] + (b[i] - a[i]) * t).round()];

bool _outsideRounded(int x, int y, int s, double r) {
  final dx = x < r
      ? r - x
      : (x > s - r ? x - (s - r) : 0).toDouble();
  final dy = y < r
      ? r - y
      : (y > s - r ? y - (s - r) : 0).toDouble();
  return dx * dx + dy * dy > r * r;
}

void _scene(img.Image im, int ox, int oy, int size, {bool rounded = false}) {
  const top = [0x14, 0x1A, 0x33];
  const mid = [0x24, 0x30, 0x5C];
  const bot = [0x35, 0x61, 0x7E];

  // Twilight sky gradient.
  for (var y = 0; y < size; y++) {
    final t = y / (size - 1);
    final col = t < 0.5 ? _lerp(top, mid, t / 0.5) : _lerp(mid, bot, (t - 0.5) / 0.5);
    for (var x = 0; x < size; x++) {
      im.setPixelRgba(ox + x, oy + y, col[0], col[1], col[2], 255);
    }
  }

  // Sun with a soft opaque halo (rings lerping sky->sun).
  final sx = ox + (size * 0.66).round();
  final sy = oy + (size * 0.40).round();
  const sun = [251, 227, 176];
  const sky = bot;
  final maxR = (size * 0.22).round();
  final coreR = (size * 0.10).round();
  for (var ring = maxR; ring >= coreR; ring--) {
    final t = (ring - coreR) / (maxR - coreR); // 1 at edge, 0 at core
    final col = _lerp(sun, sky, t * 0.85);
    img.fillCircle(im,
        x: sx, y: sy, radius: ring, color: img.ColorRgb8(col[0], col[1], col[2]));
  }
  img.fillCircle(im,
      x: sx, y: sy, radius: coreR, color: img.ColorRgb8(sun[0], sun[1], sun[2]));

  // Layered hills.
  void hill(double baseFrac, List<int> c) {
    final by = oy + (baseFrac * size).round();
    img.fillPolygon(im, vertices: [
      img.Point(ox, oy + size),
      img.Point(ox, by),
      img.Point(ox + (size * 0.30).round(), by - (size * 0.05).round()),
      img.Point(ox + (size * 0.58).round(), by + (size * 0.04).round()),
      img.Point(ox + size, by - (size * 0.03).round()),
      img.Point(ox + size, oy + size),
    ], color: img.ColorRgb8(c[0], c[1], c[2]));
  }

  hill(0.66, [44, 74, 110]);
  hill(0.78, [31, 110, 102]);
  hill(0.90, [21, 70, 63]);

  // Round the corners into a squircle badge.
  if (rounded) {
    final r = size * 0.28;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        if (_outsideRounded(x, y, size, r)) {
          im.setPixelRgba(ox + x, oy + y, 0, 0, 0, 0);
        }
      }
    }
  }
}

void _write(String path, img.Image im) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(im));
  stdout.writeln('wrote $path');
}

void main() {
  Directory('assets/brand').createSync(recursive: true);

  // Full-bleed icon (system applies its own mask).
  final icon = img.Image(width: 1024, height: 1024, numChannels: 4);
  _scene(icon, 0, 0, 1024);
  _write('assets/brand/atlas_icon.png', icon);

  // Adaptive foreground: badge inside the safe zone, transparent around.
  final fg = img.Image(width: 1024, height: 1024, numChannels: 4);
  _scene(fg, 192, 192, 640, rounded: true);
  _write('assets/brand/atlas_icon_fg.png', fg);

  // Splash: a smaller centered badge on transparent.
  final sp = img.Image(width: 1024, height: 1024, numChannels: 4);
  const s = 460;
  const o = (1024 - s) ~/ 2;
  _scene(sp, o, o, s, rounded: true);
  _write('assets/brand/atlas_splash.png', sp);
}
