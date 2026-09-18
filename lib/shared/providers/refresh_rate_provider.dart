import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:refresh_rate/refresh_rate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/core/logging/app_logger.dart';

/// Whether Atlas asks the display for its highest refresh rate.
///
/// Flutter's engine never calls the platform's rate-setting APIs, so a 120 Hz
/// phone renders Atlas at 60 Hz unless we opt in. Every animation in the app —
/// the living horizon, the aurora nav bar, the toasts — is smoother when we do.
///
/// Stored per device rather than per account: whether smooth motion is worth
/// the battery depends on the hardware in your hand, so a phone and a tablet
/// should be able to disagree. That is the same store the theme uses.
const _prefKey = 'atlas_high_refresh_rate';

/// On by default — someone who paid for a high-refresh screen should see the
/// app use it without hunting through settings first.
const _defaultEnabled = true;

final _log = AppLog('Display');

class RefreshRateState {
  const RefreshRateState({
    this.loaded = false,
    this.enabled = _defaultEnabled,
    this.info,
  });

  final bool loaded;
  final bool enabled;
  final DisplayInfo? info;

  /// A display that can only do one rate has nothing to offer here.
  bool get deviceSupportsHighRate {
    final i = info;
    if (i == null) return false;
    return i.maxRate > 61 || i.supportedRates.length > 1;
  }

  /// The platform throttles the display when the battery is low, whatever we
  /// ask for. Worth saying out loud rather than looking broken.
  bool get throttledByBattery => info?.isLowPowerMode ?? false;

  bool get throttledByHeat =>
      info != null && info!.thermalState != ThermalState.nominal;

  RefreshRateState copyWith({bool? loaded, bool? enabled, DisplayInfo? info}) {
    return RefreshRateState(
      loaded: loaded ?? this.loaded,
      enabled: enabled ?? this.enabled,
      info: info ?? this.info,
    );
  }
}

class RefreshRateController extends Notifier<RefreshRateState> {
  @override
  RefreshRateState build() {
    _load();
    return const RefreshRateState();
  }

  Future<void> _load() async {
    bool enabled = _defaultEnabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(_prefKey) ?? _defaultEnabled;
    } catch (e, s) {
      _log.e('Could not read the refresh-rate preference', error: e, stackTrace: s);
    }
    state = state.copyWith(loaded: true, enabled: enabled);
    await apply();
  }

  /// Push the current preference to the platform and re-read what it did.
  ///
  /// Safe to call repeatedly. Worth calling on resume: Android drops the
  /// window's preferred display mode when the app goes to the background, so
  /// without this the app quietly falls back to 60 Hz after a task switch.
  Future<void> apply() async {
    try {
      if (state.enabled) {
        RefreshRate.enable();
        RefreshRate.preferMax();
      } else {
        RefreshRate.disable();
      }
    } catch (e, s) {
      // An unsupported device is not a failure worth bothering anyone about.
      _log.e('Could not set the refresh rate', error: e, stackTrace: s);
    }
    await refreshInfo();
  }

  /// Re-read what the display is actually doing right now.
  Future<void> refreshInfo() async {
    try {
      final info = await RefreshRate.refresh();
      state = state.copyWith(info: info);
    } catch (e, s) {
      _log.e('Could not read display info', error: e, stackTrace: s);
    }
  }

  Future<void> setEnabled(bool value) async {
    if (state.enabled == value) return;
    state = state.copyWith(enabled: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (e, s) {
      _log.e('Could not save the refresh-rate preference',
          error: e, stackTrace: s);
    }
    await apply();
  }
}

final refreshRateProvider =
    NotifierProvider<RefreshRateController, RefreshRateState>(
  RefreshRateController.new,
);
