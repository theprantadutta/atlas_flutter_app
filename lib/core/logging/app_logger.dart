// Atlas logging.
//
// Three modes, decided at compile time so the unused paths are stripped from
// the binary rather than merely skipped at runtime:
//
//   Debug build                      everything (trace and up), coloured
//   Release + ATLAS_DIAGNOSTICS=true errors only
//   Release (default)                completely silent
//
// The middle mode exists for closed/open testing, where you need to read a
// real device's failures over `adb logcat`. Public production builds ship with
// diagnostics off, so nothing about a user's session is ever written to the
// device log.
//
//   # testing track — errors reach logcat
//   flutter build appbundle --release --dart-define=ATLAS_DIAGNOSTICS=true
//
//   # public production — logs nothing
//   flutter build appbundle --release
//
// Output goes through `debugPrint`, which the engine forwards to logcat under
// the `flutter` tag, and every line starts with `ATLAS`:
//
//   adb logcat | grep ATLAS           # everything Atlas logged
//   adb logcat | grep "ATLAS E/Auth"  # only auth errors
//
// Use a scoped instance per subsystem rather than the root logger:
//
//   final _log = AppLog('Auth');
//   _log.i('Signed in');
//   _log.e('Login failed', error: e, stackTrace: s);

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Marker so the whole app can be pulled out of logcat with one grep.
const String _prefix = 'ATLAS';

/// Opt-in diagnostics for non-public builds. Compile-time const, so when it is
/// false the release logging paths are dead code and get removed.
const bool kDiagnosticsEnabled =
    bool.fromEnvironment('ATLAS_DIAGNOSTICS', defaultValue: false);

/// Debug logs everything; a diagnostics build logs errors and fatals only;
/// a public release logs nothing at all.
Level _levelForBuild() {
  if (kDebugMode) return Level.trace;
  return kDiagnosticsEnabled ? Level.error : Level.off;
}

/// One compact line per entry, so nothing wraps or interleaves badly in
/// logcat. Errors and stack frames are emitted as their own prefixed lines so
/// a `grep` for a tag still catches them.
class _AtlasPrinter extends LogPrinter {
  _AtlasPrinter({required this.colors});

  final bool colors;

  static const _levelChar = <Level, String>{
    Level.trace: 'T',
    Level.debug: 'D',
    Level.info: 'I',
    Level.warning: 'W',
    Level.error: 'E',
    Level.fatal: 'F',
  };

  static const _levelColor = <Level, String>{
    Level.trace: '\x1B[90m',
    Level.debug: '\x1B[36m',
    Level.info: '\x1B[32m',
    Level.warning: '\x1B[33m',
    Level.error: '\x1B[31m',
    Level.fatal: '\x1B[35m',
  };
  static const _reset = '\x1B[0m';

  @override
  List<String> log(LogEvent event) {
    final char = _levelChar[event.level] ?? '?';
    final message = event.message;
    final scope = message is _Scoped ? message.tag : 'App';
    final text = message is _Scoped ? message.text : '$message';

    final head = '$_prefix $char/$scope · $text';
    final lines = <String>[
      colors ? '${_levelColor[event.level] ?? ''}$head$_reset' : head,
    ];

    if (event.error != null) {
      lines.add('$_prefix $char/$scope   ↳ ${_describe(event.error!)}');
    }
    if (event.stackTrace != null) {
      // A handful of frames is enough to locate a fault; the rest is noise.
      final frames =
          event.stackTrace.toString().trim().split('\n').take(8);
      for (final frame in frames) {
        lines.add('$_prefix $char/$scope   ↳ ${frame.trim()}');
      }
    }
    return lines;
  }

  /// Errors are logged in full — this is the diagnostic channel, not the UI.
  String _describe(Object error) {
    final text = error.toString().trim();
    return text.isEmpty ? error.runtimeType.toString() : text;
  }
}

/// `debugPrint` reaches logcat in release builds; it also throttles, so a
/// burst of logging cannot stall the app.
class _DebugPrintOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      debugPrint(line);
    }
  }
}

/// Message wrapper so the printer knows which subsystem an entry came from.
class _Scoped {
  const _Scoped(this.tag, this.text);
  final String tag;
  final String text;
  @override
  String toString() => '$tag · $text';
}

/// `ProductionFilter` gates purely on level, in every build mode — unlike the
/// package default, which silently drops everything outside debug.
final Logger _root = Logger(
  filter: ProductionFilter(),
  printer: _AtlasPrinter(colors: kDebugMode),
  output: _DebugPrintOutput(),
  level: _levelForBuild(),
);

/// A logger scoped to one subsystem — `AppLog('Auth')`, `AppLog('Sync')`.
class AppLog {
  const AppLog(this.tag);

  final String tag;

  void t(String message, {Object? error, StackTrace? stackTrace}) =>
      _root.t(_Scoped(tag, message), error: error, stackTrace: stackTrace);

  void d(String message, {Object? error, StackTrace? stackTrace}) =>
      _root.d(_Scoped(tag, message), error: error, stackTrace: stackTrace);

  void i(String message, {Object? error, StackTrace? stackTrace}) =>
      _root.i(_Scoped(tag, message), error: error, stackTrace: stackTrace);

  void w(String message, {Object? error, StackTrace? stackTrace}) =>
      _root.w(_Scoped(tag, message), error: error, stackTrace: stackTrace);

  void e(String message, {Object? error, StackTrace? stackTrace}) =>
      _root.e(_Scoped(tag, message), error: error, stackTrace: stackTrace);

  void f(String message, {Object? error, StackTrace? stackTrace}) =>
      _root.f(_Scoped(tag, message), error: error, stackTrace: stackTrace);
}

/// Mask an email for logging — `someone@example.com` becomes `s••••@example.com`.
///
/// Logs are a diagnostic tool, not a place to accumulate personal data. Enough
/// survives to correlate a report with a session; not enough to read someone's
/// identity out of a log dump.
String redactEmail(String? email) {
  if (email == null || email.isEmpty) return '(none)';
  final at = email.indexOf('@');
  if (at <= 0) return '•••';
  return '${email[0]}••••${email.substring(at)}';
}

/// Mask a token or long opaque id, keeping just enough to match it up.
String redactToken(String? token) {
  if (token == null || token.isEmpty) return '(none)';
  if (token.length <= 8) return '••••';
  return '${token.substring(0, 6)}…(${token.length} chars)';
}
