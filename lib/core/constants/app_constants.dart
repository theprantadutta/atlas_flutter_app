/// Values the local database is built on. These are load-bearing: changing
/// either one changes which file Drift opens, or forces a migration.
///
/// Deliberately not here: an app name or version string. The display name
/// lives in the Android manifest and Info.plist, and the version lives in
/// pubspec.yaml. A copy in Dart is a second source of truth that nothing keeps
/// honest, and the last one had already drifted a full eight patch versions
/// behind. If the app ever needs its own version at runtime, read the real one
/// with `package_info_plus` rather than reintroducing a constant.
class AppConstants {
  static const String databaseName = 'atlas.db';
  static const int databaseVersion = 11;
}
