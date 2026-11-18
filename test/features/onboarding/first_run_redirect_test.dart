import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/legal/providers/legal_provider.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:atlas_flutter_app/router/app_router.dart';

const _signedOut = AuthState(isInitializing: false);
const _signedIn = AuthState(isInitializing: false, isAuthenticated: true);
const _newDevice = OnboardingState(loaded: true, introSeen: true);
const _setUp = OnboardingState(loaded: true, introSeen: true, setupComplete: true);
const _notAccepted = LegalState(loaded: true);
const _accepted = LegalState(loaded: true, acceptedVersion: kLegalVersion);
const _olderAccepted = LegalState(loaded: true, acceptedVersion: kLegalVersion - 1);

String? _go(
  String location, {
  AuthState auth = _signedOut,
  OnboardingState onboarding = _newDevice,
  LegalState legal = _notAccepted,
}) =>
    firstRunRedirect(location: location, auth: auth, onboarding: onboarding, legal: legal);

void main() {
  group('a new person', () {
    test('who taps "Create your account" reaches sign-up, not the documents', () {
      expect(_go('/signup'), isNull);
    });

    test('who skips the intro lands on sign-up, not "Welcome back"', () {
      expect(_go('/'), '/signup');
      expect(_go('/legal'), '/signup');
    });

    test('can still choose to log in', () {
      expect(_go('/login'), isNull);
    });

    test('can read the documents before having an account', () {
      expect(_go('/legal-docs'), isNull);
    });

    test('goes to setup once signed in (having agreed on the sign-in screen)', () {
      expect(_go('/signup', auth: _signedIn, legal: _accepted), '/setup');
    });
  });

  test('the intro still comes first on a fresh install', () {
    expect(
      _go('/signup', onboarding: const OnboardingState(loaded: true)),
      '/intro',
    );
  });

  test('someone who has used Atlas on this device is sent to log in', () {
    expect(_go('/', onboarding: _setUp, legal: _accepted), '/login');
  });

  group('the full documents screen', () {
    test('appears when the documents changed since they were accepted', () {
      expect(_go('/login', legal: _olderAccepted), '/legal');
      expect(_go('/', auth: _signedIn, onboarding: _setUp, legal: _olderAccepted), '/legal');
    });

    test('appears for someone signed in who never accepted', () {
      expect(_go('/', auth: _signedIn, onboarding: _setUp), '/legal');
    });

    test('lets an accepted, set-up person through to Home', () {
      expect(_go('/legal', auth: _signedIn, onboarding: _setUp, legal: _accepted), '/');
      expect(_go('/grow', auth: _signedIn, onboarding: _setUp, legal: _accepted), isNull);
    });
  });

  test('holds on the splash while signing in is still being checked', () {
    expect(_go('/signup', auth: const AuthState()), '/splash');
  });
}
