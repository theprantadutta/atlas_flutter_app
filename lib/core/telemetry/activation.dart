import 'package:shared_preferences/shared_preferences.dart';

/// Measures how quickly a new account gets going, the number that best
/// predicts whether someone comes back the next day.
///
/// The clock starts when first-run setup finishes, which only a new account
/// goes through, so people who were already using Atlas never produce these
/// events. Within the first 24 hours after setup it reports:
/// * `first_tend`: the first habit or task done, with the minutes it took.
/// * `day0_three_tends`: the third one, a sign the day actually got used.
class Activation {
  Activation(this._prefs, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  static const _kSetupAt = 'activation_setup_at';
  static const _kTends = 'activation_day0_tends';
  static const window = Duration(hours: 24);

  /// Start the clock. Only the first call counts.
  Future<void> setupFinished() async {
    if (_prefs.containsKey(_kSetupAt)) return;
    await _prefs.setInt(_kSetupAt, _now().millisecondsSinceEpoch);
    await _prefs.setInt(_kTends, 0);
  }

  /// Record one habit or task done. Returns the event to log, if any, as
  /// `(name, parameters)`.
  Future<(String, Map<String, Object>)?> tended() async {
    final setupAt = _prefs.getInt(_kSetupAt);
    if (setupAt == null) return null;
    final elapsed = _now().difference(DateTime.fromMillisecondsSinceEpoch(setupAt));
    if (elapsed.isNegative || elapsed > window) return null;

    final count = (_prefs.getInt(_kTends) ?? 0) + 1;
    if (count > 3) return null;
    await _prefs.setInt(_kTends, count);
    if (count == 1) return ('first_tend', <String, Object>{'minutes': elapsed.inMinutes});
    if (count == 3) return ('day0_three_tends', <String, Object>{'minutes': elapsed.inMinutes});
    return null;
  }
}
