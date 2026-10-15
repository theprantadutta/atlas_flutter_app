import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/data/models/user.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/auth/screens/login_screen.dart';
import 'package:atlas_flutter_app/features/auth/screens/signup_screen.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/billing/screens/paywall_screen.dart';
import 'package:atlas_flutter_app/features/onboarding/screens/intro_screen.dart';
import 'package:atlas_flutter_app/features/onboarding/screens/setup_screen.dart';

import '../helpers/golden.dart';

class _SignedOut extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isInitializing: false);
}

class _SignedIn extends AuthNotifier {
  @override
  AuthState build() => AuthState(
        isInitializing: false,
        isAuthenticated: true,
        user: User(id: 'u', email: 'k@example.com', fullName: 'KDS', createdAt: DateTime(2025)),
      );
}

class _FreeUser extends EntitlementNotifier {
  @override
  EntitlementState build() => const EntitlementState();
}

final _billing = [
  entitlementsProvider.overrideWith(_FreeUser.new),
  isPremiumProvider.overrideWithValue(false),
  offersProvider.overrideWith((ref) async => {}),
  currentSubscriptionProvider.overrideWith((ref) async => null),
];

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final cases = <String, (Widget, List)>{
    'auth_login': (const LoginScreen(), [authProvider.overrideWith(_SignedOut.new)]),
    'auth_signup': (const SignupScreen(), [authProvider.overrideWith(_SignedOut.new)]),
    'onboarding_intro': (const IntroScreen(), [authProvider.overrideWith(_SignedOut.new)]),
    'onboarding_setup': (const SetupScreen(), [authProvider.overrideWith(_SignedIn.new)]),
    'paywall': (const PaywallScreen(), [authProvider.overrideWith(_SignedIn.new), ..._billing]),
  };

  for (final e in cases.entries) {
    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';
      testWidgets('${e.key} $mode', (tester) async {
        await pumpPhone(tester, e.value.$1, dark: dark, overrides: e.value.$2);
        await settle(tester);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${e.key}_$mode.png'));
      });
    }
  }
}
