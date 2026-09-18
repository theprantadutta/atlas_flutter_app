/// Compile-time switch for driving the app unattended.
///
/// Enabled only with an explicit `--dart-define`, so it cannot reach a store
/// build:
///
/// ```
/// flutter run --dart-define=ATLAS_DEMO=true \
///             --dart-define=ATLAS_DEMO_EMAIL=... \
///             --dart-define=ATLAS_DEMO_PASSWORD=...
/// ```
///
/// When on, the app signs itself in with the supplied throwaway account and
/// seeds starter content, so screens can be laid out and captured without a
/// human typing into a simulator. It exists because App Store screenshots and
/// tablet layout work both need a populated, signed-in app on several device
/// sizes — doing that by hand for every rebuild is where the time goes.
class DemoConfig {
  DemoConfig._();

  static const bool enabled =
      bool.fromEnvironment('ATLAS_DEMO', defaultValue: false);

  static const String email = String.fromEnvironment('ATLAS_DEMO_EMAIL');

  static const String password = String.fromEnvironment('ATLAS_DEMO_PASSWORD');

  /// Skip the intro, legal gate and personalisation flow so the app lands
  /// straight on Home.
  static const bool skipOnboarding =
      bool.fromEnvironment('ATLAS_DEMO_SKIP_ONBOARDING', defaultValue: true);

  /// Whether we have everything needed to actually attempt the auto sign-in.
  static bool get isUsable => enabled && email.isNotEmpty && password.isNotEmpty;
}
