import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refresh_rate/refresh_rate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/core/gamification/ledger.dart';
import 'package:atlas_flutter_app/data/models/user.dart';
import 'package:atlas_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:atlas_flutter_app/features/avatar/providers/avatar_providers.dart';
import 'package:atlas_flutter_app/features/billing/providers/entitlement_provider.dart';
import 'package:atlas_flutter_app/features/gamification/providers/gamification_providers.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/starter_data_provider.dart';
import 'package:atlas_flutter_app/features/profile/screens/display_settings_screen.dart';
import 'package:atlas_flutter_app/features/profile/screens/profile_screen.dart';
import 'package:atlas_flutter_app/features/profile/screens/sync_management_screen.dart';
import 'package:atlas_flutter_app/shared/providers/refresh_rate_provider.dart';

import '../helpers/golden.dart';
import '../helpers/sample_data.dart';

final _user = User(
  id: 'u',
  email: 'kds@example.com',
  fullName: 'KDS Rahman',
  createdAt: DateTime(2025, 1, 1),
);

class _SignedIn extends AuthNotifier {
  @override
  AuthState build() =>
      AuthState(isInitializing: false, isAuthenticated: true, user: _user);
}

class _NoEntitlements extends EntitlementNotifier {
  @override
  EntitlementState build() => const EntitlementState();
}

class _Rate extends RefreshRateController {
  @override
  RefreshRateState build() => const RefreshRateState(
        loaded: true,
        enabled: true,
        info: DisplayInfo(
          currentRate: 120,
          maxRate: 120,
          minRate: 60,
          supportedRates: [60, 90, 120],
          isVariableRefreshRate: true,
          engineTargetRate: 120,
          thermalState: ThermalState.nominal,
        ),
      );

  @override
  Future<void> refreshInfo() async {}
}

class _Starter extends StarterDataController {
  @override
  StarterDataState build() => const StarterDataState(loaded: true, choiceMade: true, hasStarterData: true);
}

List common() => [
      authProvider.overrideWith(_SignedIn.new),
      entitlementsProvider.overrideWith(_NoEntitlements.new),
      isPremiumProvider.overrideWithValue(false),
      canSyncProvider.overrideWithValue(false),
      isOnTrialProvider.overrideWithValue(false),
      trialDaysRemainingProvider.overrideWithValue(null),
      availableTrialDaysProvider.overrideWithValue(7),
      auroraUsageProvider.overrideWithValue(null),
    ];

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets('profile $mode', (tester) async {
      await pumpPhone(tester, const ProfileScreen(), dark: dark, size: const Size(390, 1900), overrides: [
        ...common(),
        ledgerDaysProvider.overrideWithValue(sampleLedger()),
        playerStatsProvider.overrideWithValue(PlayerStats(
          totalXp: 1480,
          level: LevelInfo.of(1480),
          streak: 12,
          bestStreak: 21,
          xpToday: 175,
          tendedToday: 4,
        )),
        avatarStreamProvider.overrideWith((ref) => Stream.value(null)),
      ]);
      await settle(tester);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/profile_$mode.png'));
    });

    testWidgets('display settings $mode', (tester) async {
      await pumpPhone(tester, const DisplaySettingsScreen(), dark: dark, overrides: [
        ...common(),
        refreshRateProvider.overrideWith(_Rate.new),
      ]);
      await settle(tester);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/profile_display_$mode.png'));
    });

    testWidgets('sync management $mode', (tester) async {
      await pumpPhone(tester, const SyncManagementScreen(), dark: dark, overrides: [
        ...common(),
        starterDataProvider.overrideWith(_Starter.new),
        localItemCountProvider.overrideWith((ref) async => 42),
      ]);
      await settle(tester);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/profile_sync_$mode.png'));
    });
  }
}
