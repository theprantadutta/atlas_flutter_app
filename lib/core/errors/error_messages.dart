import 'dart:async' show TimeoutException;
import 'dart:io' show SocketException, HttpException;

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/services.dart' show PlatformException;

import 'app_exception.dart';
import 'error_handler.dart';

/// Turns anything throwable into one calm sentence a person can act on.
///
/// This is the **only** thing that should ever reach a user. Never put
/// `e.toString()` in UI state — it leaks class names, status codes and stack
/// frames ("AuthException: Invalid credentials (statusCode: 401)"), which
/// tells the user nothing and looks broken. Log the raw error instead; that is
/// what [AppLog] is for.
class AppErrors {
  AppErrors._();

  /// The fallback when we genuinely don't recognise a failure. Deliberately
  /// gentle — a person hitting an unknown error is already having a bad time.
  static const String generic =
      'Something went wrong. Please try again in a moment.';

  static const String offline =
      'You appear to be offline. Check your connection and try again.';

  static const String slow =
      'That took too long to respond. Please try again.';

  /// True when the user themselves backed out — a cancelled sign-in is not a
  /// failure and should not raise an error message at all.
  static bool isCancellation(Object? error) {
    if (error is AppException) {
      return error.message.toLowerCase().contains('cancel');
    }
    if (error is FirebaseAuthException) {
      return error.code == 'web-context-cancelled' ||
          error.code == 'cancelled-popup-request' ||
          error.code == 'popup-closed-by-user';
    }
    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      return code.contains('cancel') || code == 'sign_in_canceled';
    }
    final text = error?.toString().toLowerCase() ?? '';
    return text.contains('cancel') || text.contains('aborted');
  }

  /// Map any error to something worth showing.
  static String message(Object? error) {
    if (error == null) return generic;

    // Ours already carries a curated, human sentence.
    if (error is AppException) return _clean(error.message);

    if (error is DioException) {
      return _clean(ErrorHandler.handleDioError(error).message);
    }

    if (error is FirebaseAuthException) return _firebase(error);

    if (error is SocketException) return offline;
    if (error is TimeoutException) return slow;
    if (error is HttpException) return generic;

    if (error is PlatformException) return _platform(error);

    // Anything else is a bug on our side, not something to narrate.
    return generic;
  }

  static String _firebase(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-login-credentials':
        return 'That email or password doesn’t look right.';
      case 'invalid-email':
        return 'That doesn’t look like a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please get in touch.';
      case 'email-already-in-use':
        return 'An account already exists with that email. Try signing in.';
      case 'weak-password':
        return 'Please choose a longer, less predictable password.';
      case 'requires-recent-login':
        return 'Please sign in again to confirm it’s you, then retry.';
      case 'account-exists-with-different-credential':
        return 'You’ve signed in before using a different method. '
            'Try that one instead.';
      case 'network-request-failed':
        return offline;
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'invalid-verification-code':
        return 'That code didn’t work. Please request a new one.';
      case 'operation-not-allowed':
      default:
        return generic;
    }
  }

  static String _platform(PlatformException error) {
    // Google Sign-In surfaces a bare "10" for DEVELOPER_ERROR, which means the
    // signing certificate isn't registered — a build problem, not a user one.
    if (error.code == '10' || error.code == 'sign_in_failed') {
      return 'We couldn’t sign you in with that method. '
          'Please try another way to sign in.';
    }
    if (error.code.toLowerCase().contains('network')) return offline;
    return generic;
  }

  /// Guard against a "user-facing" string that is really a raw error. Anything
  /// carrying a class name, a stack frame or an exception prefix is replaced.
  static String _clean(String message) {
    final text = message.trim();
    if (text.isEmpty) return generic;
    final looksRaw = text.contains('Exception:') ||
        text.contains('Error:') ||
        text.contains('#0') ||
        text.contains('statusCode:') ||
        text.startsWith('[') ||
        text.contains('package:');
    if (looksRaw) return generic;
    // A stray backend string shouldn't become a wall of text either.
    return text.length > 180 ? generic : text;
  }
}
