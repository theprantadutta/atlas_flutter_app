import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/onboarding/providers/starter_seeder.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';
import 'package:atlas_flutter_app/shared/providers/core_providers.dart';

const _kChoiceMade = 'atlas_starter_choice_made';
const _kSeeded = 'atlas_starter_seeded';

/// Whether the one-time "add example data?" choice has been made, and whether
/// starter content currently exists (so Settings can offer to remove it).
class StarterDataState {
  const StarterDataState({
    this.loaded = false,
    this.choiceMade = false,
    this.hasStarterData = false,
  });

  final bool loaded;
  final bool choiceMade;
  final bool hasStarterData;

  StarterDataState copyWith({
    bool? loaded,
    bool? choiceMade,
    bool? hasStarterData,
  }) {
    return StarterDataState(
      loaded: loaded ?? this.loaded,
      choiceMade: choiceMade ?? this.choiceMade,
      hasStarterData: hasStarterData ?? this.hasStarterData,
    );
  }
}

class StarterDataController extends Notifier<StarterDataState> {
  @override
  StarterDataState build() {
    _load();
    return const StarterDataState();
  }

  StarterSeeder get _seeder => StarterSeeder(ref.read(databaseProvider));

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = ref.read(currentUserIdProvider);
    // Older builds gave example rows ids the server rejects; fix them once.
    try {
      await _seeder.migrateLegacyIds(userId);
    } catch (_) {/* best effort; nothing depends on it */}
    final has = await _seeder.hasSeed(userId);
    state = StarterDataState(
      loaded: true,
      choiceMade: prefs.getBool(_kChoiceMade) ?? false,
      hasStarterData: has || (prefs.getBool(_kSeeded) ?? false),
    );
  }

  /// Record the first-run choice. When [wantStarter] is true, seed example
  /// content across the personal stores; otherwise start with a clean slate.
  Future<void> choose({required bool wantStarter}) async {
    final userId = ref.read(currentUserIdProvider);
    if (wantStarter) await _seedAll(userId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kChoiceMade, true);
    await prefs.setBool(_kSeeded, wantStarter);
    ref.invalidate(localItemCountProvider);
    state = state.copyWith(
      loaded: true,
      choiceMade: true,
      hasStarterData: wantStarter,
    );
  }

  /// Remove the example content the user asked for earlier.
  Future<void> deleteStarterData() async {
    final userId = ref.read(currentUserIdProvider);
    await _deleteAll(userId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSeeded, false);
    ref.invalidate(localItemCountProvider);
    state = state.copyWith(hasStarterData: false);
  }

  Future<void> _seedAll(String userId) => _seeder.seed(userId);

  Future<void> _deleteAll(String userId) => _seeder.remove(userId);
}

final starterDataProvider =
    NotifierProvider<StarterDataController, StarterDataState>(
  StarterDataController.new,
);

/// Total number of locally-stored items for the current user, summed across the
/// core stores — a real figure for the "Sync & data" screen.
final localItemCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final counts = await Future.wait([
    ref.read(taskDaoProvider).countForUser(userId),
    ref.read(habitDaoProvider).countForUser(userId),
    ref.read(goalDaoProvider).countForUser(userId),
    ref.read(progressDaoProvider).countForUser(userId),
    ref.read(notificationDaoProvider).countForUser(userId),
    ref.read(worldDaoProvider).countForUser(userId),
    ref.read(achievementDaoProvider).countForUser(userId),
  ]);
  return counts.fold<int>(0, (sum, c) => sum + c);
});
