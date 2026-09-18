import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Where Atlas lives on each store.
///
/// Feedback is routed to the store review flow rather than to our own servers:
/// a review reaches the next person deciding whether to try Atlas, which a
/// private support ticket never does.
class StoreConfig {
  StoreConfig._();

  /// Android application id, and the `id=` parameter of the Play listing.
  static const String androidPackage = 'com.pranta.atlas';

  /// Apple's numeric App Store id. Empty until Atlas is live on iOS; while it
  /// is empty [listingUrl] falls back to a name search so the button still
  /// lands somewhere sensible.
  static const String appleAppId = '';

  /// True on the two platforms that actually have a store to send people to.
  static bool get hasStore =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// The store this device belongs to, for button labels.
  static String get storeName {
    if (kIsWeb) return 'the store';
    return Platform.isIOS ? 'the App Store' : 'Google Play';
  }

  /// A web URL for the listing. Used as the fallback when the native review
  /// flow cannot be opened.
  static String get listingUrl {
    if (!kIsWeb && Platform.isIOS) {
      return appleAppId.isEmpty
          ? 'https://apps.apple.com/search?term=atlas%20self%20care'
          : 'https://apps.apple.com/app/id$appleAppId';
    }
    return 'https://play.google.com/store/apps/details?id=$androidPackage';
  }
}
