import 'dart:io' show Platform;

/// Public legal documents.
///
/// App Review checks these: the privacy policy must be reachable from inside
/// the app (Guideline 5.1.1) and the paywall must link both the privacy policy
/// and the terms/EULA alongside the price and renewal terms (Guideline 3.1.2).
/// The same privacy-policy URL also goes in the App Store Connect listing.
///
/// HTTPS is deliberate — App Review flags plain-HTTP legal pages.
class LegalConfig {
  LegalConfig._();

  static const String privacyPolicyUrl =
      'https://legal.pranta.dev/privacy?projectName=atlas';

  static const String termsOfUseUrl =
      'https://legal.pranta.dev/terms?projectName=atlas';

  /// Shown next to the purchase buttons. Both stores require the subscription
  /// length and the auto-renewal behaviour up front, and both require a free
  /// trial to state that it converts to a paid subscription unless cancelled —
  /// omitting that is a common cause of review rejection.
  ///
  /// [trialDays] is the trial the user is actually eligible for (0 when there
  /// isn't one), so this never promises a trial to somebody who already used it.
  /// [trialEligibilityKnown] is false on iOS, where StoreKit exposes the
  /// introductory offer without telling us whether this Apple ID has already used
  /// it. In that case the disclosure has to say the trial is for new subscribers,
  /// so a returning subscriber who is charged immediately was told up front.
  static String subscriptionDisclosure({
    int trialDays = 0,
    bool trialEligibilityKnown = true,
  }) {
    final isApple = Platform.isIOS || Platform.isMacOS;
    final store = isApple ? 'App Store' : 'Google Play';

    // Kept to what the stores actually require, because this sits on the
    // purchase screen and every line of it pushes the benefits out of view.
    // The long version stated the cancel-24-hours rule twice (once for the
    // trial, once for the renewal) and spent a sentence on the account being
    // charged on confirmation, which no guideline asks for and no reader needs.
    final trial = trialDays > 0
        ? '${trialEligibilityKnown ? 'Your' : 'A'} $trialDays-day free trial'
            '${trialEligibilityKnown ? '' : ' for new subscribers'} '
            'converts to a paid subscription unless cancelled 24h before it '
            'ends. '
        : '';

    // With a trial, the conversion sentence above already carries the renewal
    // terms; without one they still have to be stated.
    final renewal = trialDays > 0
        ? ''
        : 'Renews automatically until cancelled. ';

    return '$trial${renewal}Cancel any time in $store.';
  }
}
