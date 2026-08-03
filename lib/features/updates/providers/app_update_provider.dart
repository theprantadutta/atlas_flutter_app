import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';

/// Play in-app updates.
///
/// Two paths, chosen by the priority you set on the release in Play Console:
///
/// * **Priority 4–5** — a blocking, full-screen immediate update. Reserve this
///   for releases people genuinely must take (a data-loss fix, a broken auth
///   flow). It interrupts, so it should be rare.
/// * **Anything lower** — a flexible update: Play downloads it quietly in the
///   background and we surface one calm, dismissible banner once it's ready.
///   Nothing is forced and nothing restarts underneath the user.
///
/// The API only exists on Android, and only works for builds actually
/// installed by Play — a locally-signed or sideloaded build always reports no
/// update available, which is expected and not a failure.
const int _kCriticalPriority = 4;

enum AppUpdateStage {
  /// Nothing to do, or we haven't looked yet.
  idle,

  /// Play is downloading the update in the background.
  downloading,

  /// Downloaded and waiting for the user to say go.
  readyToInstall,
}

class AppUpdateState {
  const AppUpdateState({
    this.stage = AppUpdateStage.idle,
    this.dismissed = false,
    this.installing = false,
  });

  final AppUpdateStage stage;

  /// The user waved the banner away — respect that for the rest of the session.
  final bool dismissed;

  final bool installing;

  bool get showBanner =>
      stage == AppUpdateStage.readyToInstall && !dismissed;

  AppUpdateState copyWith({
    AppUpdateStage? stage,
    bool? dismissed,
    bool? installing,
  }) {
    return AppUpdateState(
      stage: stage ?? this.stage,
      dismissed: dismissed ?? this.dismissed,
      installing: installing ?? this.installing,
    );
  }
}

class AppUpdateController extends Notifier<AppUpdateState> {
  bool _checking = false;
  bool _handledThisSession = false;

  @override
  AppUpdateState build() => const AppUpdateState();

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Look for an update. Safe to call on every resume — it does nothing once
  /// an update has already been picked up this session.
  Future<void> check() async {
    if (!_supported || _checking || _handledThisSession) return;
    _checking = true;
    try {
      final info = await InAppUpdate.checkForUpdate();

      // A flexible update from an earlier run may already be sitting on disk.
      if (info.installStatus == InstallStatus.downloaded) {
        _handledThisSession = true;
        state = state.copyWith(stage: AppUpdateStage.readyToInstall);
        return;
      }

      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      final priority = info.updatePriority;

      if (priority >= _kCriticalPriority && info.immediateUpdateAllowed) {
        _handledThisSession = true;
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.flexibleUpdateAllowed) {
        _handledThisSession = true;
        state = state.copyWith(stage: AppUpdateStage.downloading);
        // Resolves once Play has finished downloading in the background.
        await InAppUpdate.startFlexibleUpdate();
        state = state.copyWith(stage: AppUpdateStage.readyToInstall);
      }
    } catch (_) {
      // No Play install, no network, user declined — none of it is worth
      // interrupting someone's day over. Stay quiet and try again next launch.
      state = const AppUpdateState();
    } finally {
      _checking = false;
    }
  }

  /// Restart into the downloaded update.
  Future<void> install() async {
    if (!_supported || state.installing) return;
    state = state.copyWith(installing: true);
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (_) {
      state = state.copyWith(installing: false, dismissed: true);
    }
  }

  /// Hide the banner until the next launch.
  void dismiss() => state = state.copyWith(dismissed: true);
}

final appUpdateProvider =
    NotifierProvider<AppUpdateController, AppUpdateState>(
  AppUpdateController.new,
);
