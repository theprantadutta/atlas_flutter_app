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
    final account = isApple ? 'Apple ID' : 'Google Play account';
    final store = isApple ? 'App Store' : 'Google Play';

    final trial = trialDays > 0
        ? '${trialEligibilityKnown ? 'Your' : 'The'} $trialDays-day free trial'
            '${trialEligibilityKnown ? '' : ', available to new subscribers,'} '
            'converts to a paid subscription unless you cancel at least 24 hours '
            'before it ends. '
        : '';

    return '${trial}Subscriptions renew automatically unless cancelled at least '
        '24 hours before the end of the current period. Your $account is charged '
        'on confirmation of purchase, and renewals are billed to the same '
        'account. Manage or cancel any time in your $store account settings.';
  }
}
