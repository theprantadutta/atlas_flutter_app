import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

import 'package:atlas_flutter_app/core/config/app_config.dart';
import 'package:atlas_flutter_app/core/errors/app_exception.dart';
import 'package:atlas_flutter_app/data/models/user.dart';
import 'package:atlas_flutter_app/data/services/api_service.dart';
import 'package:atlas_flutter_app/data/services/token_service.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

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
    } catch (e) {
      _log.e('[Auth] Google Sign-In failed', error: e);
      throw AuthException('Google sign-in failed: $e');
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

  // ─── Token Check ────────────────────────────────────────────────

  Future<bool> isAuthenticated() => _tokenService.hasTokens();
}
