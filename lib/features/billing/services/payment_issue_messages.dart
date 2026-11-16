/// When to ask Google Play to show its "fix your payment" message.
///
/// A renewal whose payment is declined puts the subscription in a grace
/// period, then on account hold, while Play keeps retrying the card. Play's
/// in-app messaging is how most of those are recovered: it shows its own
/// snackbar, and only to a Play account that actually has a payment issue,
/// so asking costs nothing for everyone else. Asking on every resume would
/// still be a billing call per app switch, so it is limited to once per
/// [interval], plus the first time the store connects in a session.
class PaymentIssueMessageThrottle {
  PaymentIssueMessageThrottle({this.interval = const Duration(hours: 6)});

  final Duration interval;
  DateTime? _lastShown;

  /// Whether to ask now; records the ask when it returns true.
  bool shouldShow(DateTime now) {
    final last = _lastShown;
    if (last != null && now.difference(last) < interval) return false;
    _lastShown = now;
    return true;
  }
}
