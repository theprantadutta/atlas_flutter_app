import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The app's own identity, read from the platform bundle at runtime.
///
/// This is the single source of truth for the version Atlas shows anywhere.
/// It comes from the real installed bundle, which is generated from the
/// `version:` line in pubspec.yaml, so it cannot drift the way a hand-written
/// constant does. Never hard-code a version string alongside this.
class AppInfo {
  const AppInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  /// Display name, as installed on the device.
  final String appName;

  /// Application id / bundle identifier.
  final String packageName;

  /// Marketing version, e.g. "1.0.8".
  final String version;

  /// Build number, e.g. "9".
  final String buildNumber;

  /// "1.0.8 (9)", or just "1.0.8" where the platform reports no build number.
  String get display =>
      buildNumber.isEmpty ? version : '$version ($buildNumber)';
}

/// Reads the bundle once per app run. The platform channel call is cheap but
/// not free, and the answer cannot change while the app is running.
final appInfoProvider = FutureProvider<AppInfo>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return AppInfo(
    appName: info.appName,
    packageName: info.packageName,
    version: info.version,
    buildNumber: info.buildNumber,
  );
});
