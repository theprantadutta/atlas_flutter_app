import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The version of the legal document set. **Bump this whenever any of the
/// documents in `assets/legal/` changes materially** — every user is then asked
/// to review and accept again before they can continue using the app. Keep the
/// `Document version:` line inside each markdown file in step with it.
const int kLegalVersion = 1;

const _kAcceptedVersion = 'atlas_legal_accepted_version';

/// One of the documents the user must accept.
class LegalDoc {
  const LegalDoc({
    required this.id,
    required this.label,
    required this.title,
    required this.icon,
    required this.asset,
  });

  final String id;
  final String label;
  final String title;
  final IconData icon;
  final String asset;
}

const kLegalDocs = <LegalDoc>[
  LegalDoc(
    id: 'privacy',
    label: 'Privacy',
    title: 'Privacy Policy',
    icon: Icons.shield_outlined,
    asset: 'assets/legal/privacy.md',
  ),
  LegalDoc(
    id: 'terms',
    label: 'Terms',
    title: 'Terms of Service',
    icon: Icons.gavel_rounded,
    asset: 'assets/legal/terms.md',
  ),
  LegalDoc(
    id: 'refund',
    label: 'Refunds',
    title: 'Refund Policy',
    icon: Icons.receipt_long_rounded,
    asset: 'assets/legal/refund.md',
  ),
];

/// Loads a document's markdown from the bundle. Cached by asset path.
final legalDocContentProvider =
    FutureProvider.family<String, String>((ref, asset) async {
  return rootBundle.loadString(asset);
});

class LegalState {
  const LegalState({this.loaded = false, this.acceptedVersion = 0});

  final bool loaded;
  final int acceptedVersion;

  /// True once the user has accepted the current document set.
  bool get isAccepted => acceptedVersion >= kLegalVersion;

  /// True when they accepted an older set and must review the changes.
  bool get needsReacceptance => acceptedVersion > 0 && !isAccepted;

  LegalState copyWith({bool? loaded, int? acceptedVersion}) => LegalState(
        loaded: loaded ?? this.loaded,
        acceptedVersion: acceptedVersion ?? this.acceptedVersion,
      );
}

class LegalController extends Notifier<LegalState> {
  @override
  LegalState build() {
    _load();
    return const LegalState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = LegalState(
      loaded: true,
      acceptedVersion: prefs.getInt(_kAcceptedVersion) ?? 0,
    );
  }

  /// Record acceptance of the current document set.
  Future<void> accept() async {
    state = state.copyWith(loaded: true, acceptedVersion: kLegalVersion);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAcceptedVersion, kLegalVersion);
  }
}

final legalProvider =
    NotifierProvider<LegalController, LegalState>(LegalController.new);
