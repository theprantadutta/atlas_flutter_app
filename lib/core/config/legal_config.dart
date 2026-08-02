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

  /// Shown next to the purchase buttons. Apple requires the length of the
  /// subscription and the auto-renewal behaviour to be stated up front.
  static const String subscriptionDisclosure =
      'Subscriptions renew automatically unless cancelled at least 24 hours '
      'before the end of the current period. Your Apple ID is charged on '
      'confirmation of purchase, and renewals are billed to the same account. '
      'Manage or cancel any time in your App Store account settings.';
}
