import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:atlas_flutter_app/core/config/app_config.dart';
import 'package:atlas_flutter_app/core/errors/app_exception.dart';
import 'package:atlas_flutter_app/core/errors/error_messages.dart';
import 'package:atlas_flutter_app/core/logging/app_logger.dart';
import 'package:atlas_flutter_app/data/models/user.dart';
import 'package:atlas_flutter_app/data/services/api_service.dart';
import 'package:atlas_flutter_app/data/services/token_service.dart';

final _log = AppLog('Auth');

class AuthService {
  final ApiService _apiService;
  final TokenService _tokenService;
  bool _googleInitialized = false;

  AuthService(this._apiService, this._tokenService);

  // ─── Email / Password Registration ──────────────────────────────

  Future<User> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _log.i('[Auth] Registering user: $email');
    final response = await _apiService.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      },
    );

    final tokenData = response.data as Map<String, dynamic>;
    await _tokenService.saveTokens(
      accessToken: tokenData['access_token'] as String,
      refreshToken: tokenData['refresh_token'] as String,
    );
    _log.i('[Auth] Registration successful, tokens saved');

    return getCurrentUser();
  }

  // ─── Email / Password Login ─────────────────────────────────────

  Future<User> login({
    required String email,
    required String password,
  }) async {
    _log.i('[Auth] Logging in user: $email');
    final response = await _apiService.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final tokenData = response.data as Map<String, dynamic>;
    await _tokenService.saveTokens(
      accessToken: tokenData['access_token'] as String,
      refreshToken: tokenData['refresh_token'] as String,
    );
    _log.i('[Auth] Login successful, tokens saved');

    return getCurrentUser();
  }

  // ─── Google Sign-In ─────────────────────────────────────────────

  Future<void> _ensureGoogleInitialized() async {
    if (!_googleInitialized) {
      _log.d('[Auth] Initializing Google Sign-In with clientId: ${AppConfig.googleWebClientId.substring(0, 20)}...');
      await GoogleSignIn.instance.initialize(
        serverClientId: AppConfig.googleWebClientId,
      );
      _googleInitialized = true;
    }
  }

  Future<User> signInWithGoogle() async {
    _log.i('[Auth] Starting Google Sign-In flow');
    await _ensureGoogleInitialized();

    // Step 1: Google Sign-In
    final GoogleSignInAccount googleUser;
    try {
      googleUser = await GoogleSignIn.instance.authenticate();
      _log.i('[Auth] Google Sign-In success: ${googleUser.email}');
    } catch (e, st) {
      // The raw cause goes to the log; the user gets a sentence they can act
      // on. Embedding `$e` here put class names on the login screen.
      _log.e('Google sign-in failed', error: e, stackTrace: st);
      if (AppErrors.isCancellation(e)) {
        throw const AuthException('Sign-in was cancelled.');
      }
      throw AuthException(AppErrors.message(e));
    }

    // Step 2: Get Google ID token
    final googleIdToken = googleUser.authentication.idToken;
    _log.d('[Auth] Google ID token obtained: ${googleIdToken != null ? "${googleIdToken.substring(0, 20)}..." : "NULL"}');

    // Step 3: Sign in to Firebase with Google credential
    _log.i('[Auth] Signing in to Firebase with Google credential');
    final credential = firebase_auth.GoogleAuthProvider.credential(
      idToken: googleIdToken,
    );

    final firebaseUserCredential =
        await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
    _log.i('[Auth] Firebase sign-in success: ${firebaseUserCredential.user?.email}');

    // Step 4: Get Firebase ID token
    final firebaseIdToken = await firebaseUserCredential.user?.getIdToken();
    if (firebaseIdToken == null) {
      _log.e('[Auth] Failed to obtain Firebase ID token');
      throw const AuthException('Failed to obtain Firebase ID token');
    }
    _log.d('[Auth] Firebase ID token obtained: ${firebaseIdToken.substring(0, 20)}...');

    // Step 5: Authenticate with our backend
    _log.i('[Auth] Sending Firebase token to backend /auth/google');
    final response = await _apiService.post(
      '/auth/google',
      data: {'firebase_id_token': firebaseIdToken},
    );
    _log.i('[Auth] Backend auth response status: ${response.statusCode}');

    final tokenData = response.data as Map<String, dynamic>;
    await _tokenService.saveTokens(
      accessToken: tokenData['access_token'] as String,
      refreshToken: tokenData['refresh_token'] as String,
    );
    _log.i('[Auth] Google Sign-In complete, tokens saved');

    return getCurrentUser();
  }

  // ─── Sign in with Apple ─────────────────────────────────────────

  /// Generates a cryptographically random nonce.
  ///
  /// Apple signs the SHA-256 of this value into the identity token; Firebase
  /// then re-hashes the raw nonce we hand it and compares. That round trip is
  /// what stops a stolen identity token from being replayed.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256OfString(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  Future<User> signInWithApple() async {
    _log.i('[Auth] Starting Sign in with Apple flow');

    final rawNonce = _generateNonce();
    final hashedNonce = _sha256OfString(rawNonce);

    // Step 1: Apple credential.
    final AuthorizationCredentialAppleID appleCredential;
    try {
      appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      _log.i('[Auth] Apple authorization granted for ${appleCredential.userIdentifier}');
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        _log.i('[Auth] Apple sign-in cancelled by user');
        throw const AuthException('Sign in with Apple was cancelled.');
      }
      _log.e('Apple sign-in failed', error: e);
      throw AuthException(AppErrors.message(e));
    } catch (e, st) {
      _log.e('Apple sign-in failed', error: e, stackTrace: st);
      if (AppErrors.isCancellation(e)) {
        throw const AuthException('Sign-in was cancelled.');
      }
      throw AuthException(AppErrors.message(e));
    }

    final identityToken = appleCredential.identityToken;
    if (identityToken == null) {
      throw const AuthException('Apple did not return an identity token.');
    }

    // Apple hands over the real name ONLY on the first authorization for this
    // app, and never again — so capture it here or lose it permanently.
    final appleFullName = [
      appleCredential.givenName,
      appleCredential.familyName,
    ].whereType<String>().where((p) => p.trim().isNotEmpty).join(' ').trim();

    // Step 2: Exchange for a Firebase credential.
    _log.i('[Auth] Signing in to Firebase with Apple credential');
    final oauthCredential = firebase_auth.OAuthProvider('apple.com').credential(
      idToken: identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    final firebaseUserCredential = await firebase_auth.FirebaseAuth.instance
        .signInWithCredential(oauthCredential);
    _log.i('[Auth] Firebase sign-in success: ${firebaseUserCredential.user?.uid}');

    // Firebase's own profile starts empty for Apple users; seed it once so the
    // name survives on this device even before the backend round trip.
    if (appleFullName.isNotEmpty &&
        (firebaseUserCredential.user?.displayName ?? '').isEmpty) {
      try {
        await firebaseUserCredential.user?.updateDisplayName(appleFullName);
      } catch (_) {/* cosmetic only */}
    }

    // Step 3: Firebase ID token → our backend.
    final firebaseIdToken = await firebaseUserCredential.user?.getIdToken();
    if (firebaseIdToken == null) {
      _log.e('[Auth] Failed to obtain Firebase ID token');
      throw const AuthException('Failed to obtain Firebase ID token');
    }

    _log.i('[Auth] Sending Firebase token to backend /auth/apple');
    final response = await _apiService.post(
      '/auth/apple',
      data: {
        'firebase_id_token': firebaseIdToken,
        if (appleFullName.isNotEmpty) 'full_name': appleFullName,
      },
    );

    final tokenData = response.data as Map<String, dynamic>;
    await _tokenService.saveTokens(
      accessToken: tokenData['access_token'] as String,
      refreshToken: tokenData['refresh_token'] as String,
    );
    _log.i('[Auth] Sign in with Apple complete, tokens saved');

    return getCurrentUser();
  }

  /// Whether the running platform can offer Sign in with Apple.
  static Future<bool> isAppleSignInAvailable() =>
      SignInWithApple.isAvailable();

  // ─── Get Current User ───────────────────────────────────────────

  Future<User> getCurrentUser() async {
    _log.d('[Auth] Fetching current user profile');
    final response = await _apiService.get('/auth/me');
    final user = User.fromJson(response.data as Map<String, dynamic>);
    _log.i('[Auth] Current user: ${user.email} (Level ${user.level})');
    return user;
  }

  // ─── Logout ─────────────────────────────────────────────────────

  Future<void> logout() async {
    _log.i('[Auth] Logging out');
    try {
      await _apiService.post('/auth/logout');
    } catch (e) {
      _log.w('[Auth] Server logout failed (continuing): $e');
    } finally {
      await _tokenService.deleteTokens();
      await firebase_auth.FirebaseAuth.instance.signOut();
      try {
        await _ensureGoogleInitialized();
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      _log.i('[Auth] Logout complete, tokens cleared');
    }
  }

  // ─── Delete Account ─────────────────────────────────────────────

  /// Permanently deletes the server-side account and all of its data.
  ///
  /// Required by App Store Review Guideline 5.1.1(v). Local Drift data and
  /// tokens are cleared by the caller once this succeeds.
  Future<void> deleteAccount() async {
    _log.w('[Auth] Deleting account');
    await _apiService.delete('/auth/me');
    _log.i('[Auth] Server account deleted');

    // Best-effort teardown of the federated identities; the account is already
    // gone server-side, so failures here must not surface as a failed deletion.
    try {
      await firebase_auth.FirebaseAuth.instance.currentUser?.delete();
    } catch (_) {/* stale credential — signOut below still clears the session */}
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
    } catch (_) {}
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    await _tokenService.deleteTokens();
  }

  // ─── Token Check ────────────────────────────────────────────────

  Future<bool> isAuthenticated() => _tokenService.hasTokens();
}
