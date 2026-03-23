import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:atlas_flutter_app/core/config/app_config.dart';
import 'package:atlas_flutter_app/core/errors/app_exception.dart';
import 'package:atlas_flutter_app/data/models/user.dart';
import 'package:atlas_flutter_app/data/services/api_service.dart';
import 'package:atlas_flutter_app/data/services/token_service.dart';

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

    return getCurrentUser();
  }

  // ─── Email / Password Login ─────────────────────────────────────

  Future<User> login({
    required String email,
    required String password,
  }) async {
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

    return getCurrentUser();
  }

  // ─── Google Sign-In ─────────────────────────────────────────────

  Future<void> _ensureGoogleInitialized() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: AppConfig.googleWebClientId,
      );
      _googleInitialized = true;
    }
  }

  Future<User> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final GoogleSignInAccount googleUser;
    try {
      googleUser = await GoogleSignIn.instance.authenticate();
    } catch (e) {
      throw AuthException('Google sign-in failed: $e');
    }

    // The idToken from Google Sign-In is available via authentication
    final googleIdToken = googleUser.authentication.idToken;

    // Sign in to Firebase with a Google credential using the idToken
    final credential = firebase_auth.GoogleAuthProvider.credential(
      idToken: googleIdToken,
    );

    final firebaseUserCredential =
        await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);

    // Get the Firebase ID token to send to our backend
    final firebaseIdToken = await firebaseUserCredential.user?.getIdToken();
    if (firebaseIdToken == null) {
      throw const AuthException('Failed to obtain Firebase ID token');
    }

    // Authenticate with our backend using the Firebase ID token
    final response = await _apiService.post(
      '/auth/google',
      data: {'firebase_id_token': firebaseIdToken},
    );

    final tokenData = response.data as Map<String, dynamic>;
    await _tokenService.saveTokens(
      accessToken: tokenData['access_token'] as String,
      refreshToken: tokenData['refresh_token'] as String,
    );

    return getCurrentUser();
  }

  // ─── Get Current User ───────────────────────────────────────────

  Future<User> getCurrentUser() async {
    final response = await _apiService.get('/auth/me');
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Logout ─────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _apiService.post('/auth/logout');
    } catch (_) {
      // Best-effort — continue logout even if the server call fails
    } finally {
      await _tokenService.deleteTokens();
      await firebase_auth.FirebaseAuth.instance.signOut();
      try {
        await _ensureGoogleInitialized();
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Ignore Google sign-out errors
      }
    }
  }

  // ─── Token Check ────────────────────────────────────────────────

  Future<bool> isAuthenticated() => _tokenService.hasTokens();
}
