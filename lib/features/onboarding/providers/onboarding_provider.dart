import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas_flutter_app/features/habits/providers/habit_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart';
import 'package:atlas_flutter_app/shared/themes/app_colors.dart';

/// Device-level: the value-proposition intro shown *before* sign-in. Kept per
/// device (not per account) because it is what earns the sign-up.
const _kIntroSeen = 'atlas_intro_seen';

/// Account-level: the personalisation step shown after sign-in.
const _kSetupComplete = 'atlas_setup_complete';
const _kCoachMarksSeen = 'atlas_coach_marks_seen';

/// A gentle starting intention the user can pick during onboarding. Each area
/// seeds a couple of matching habits so the world has something to tend on day
/// one — the user's own choice, not example data.
class FocusArea {
  const FocusArea({
    required this.id,
    required this.label,
    required this.blurb,
    required this.icon,
    required this.color,
    required this.category,
    required this.habits,
  });

  final String id;
  final String label;
  final String blurb;
  final IconData icon;
  final Color color;

  /// Drift habit category these seed into.
  final String category;

  /// (title, gentle note) pairs seeded when this area is chosen.
  final List<(String, String)> habits;
}

const kFocusAreas = <FocusArea>[
  FocusArea(
    id: 'calm',
    label: 'Calm',
    blurb: 'Quiet the noise',
    icon: Icons.self_improvement_rounded,
    color: AppColors.categoryMindfulness,
    category: 'mindfulness',
    habits: [
      ('Take 10 quiet minutes', 'Breathe, sit, just be'),
      ('Wind down before bed', 'Let the day settle'),
    ],
  ),
  FocusArea(
    id: 'move',
    label: 'Move',
    blurb: 'Feel good in your body',
    icon: Icons.directions_walk_rounded,
    color: AppColors.categoryFitness,
    category: 'fitness',
    habits: [
      ('Move your body', 'Any movement counts'),
      ('Stretch for 10 minutes', 'Loosen up'),
    ],
  ),
  FocusArea(
    id: 'health',
    label: 'Health',
    blurb: 'Small daily care',
    icon: Icons.favorite_rounded,
    color: AppColors.categoryHealth,
    category: 'health',
    habits: [
      ('Drink enough water', 'A glass at a time'),
      ('Rest properly tonight', 'Sleep is self-care'),
    ],
  ),
  FocusArea(
    id: 'learn',
    label: 'Learn',
    blurb: 'Grow your mind',
    icon: Icons.menu_book_rounded,
    color: AppColors.categoryLearning,
    category: 'learning',
    habits: [
      ('Read for 20 minutes', 'A few pages is plenty'),
    ],
  ),
  FocusArea(
    id: 'connect',
    label: 'Connect',
    blurb: 'Stay close to people',
    icon: Icons.people_alt_rounded,
    color: AppColors.categorySocial,
    category: 'social',
    habits: [
      ('Reach out to someone', 'A message is enough'),
    ],
  ),
  FocusArea(
    id: 'create',
    label: 'Create',
    blurb: 'Make something',
    icon: Icons.brush_rounded,
    color: AppColors.categoryCreative,
    category: 'creative',
    habits: [
      ('Make something small', 'Progress over polish'),
    ],
  ),
];

/// Tracks the three first-run stages: the pre-auth intro, the post-auth
/// personalisation, and the Home walkthrough.
class OnboardingState {
  const OnboardingState({
    this.loaded = false,
    this.introSeen = false,
    this.setupComplete = false,
    this.coachMarksSeen = false,
  });

  final bool loaded;
  final bool introSeen;
  final bool setupComplete;
  final bool coachMarksSeen;

  OnboardingState copyWith({
    bool? loaded,
    bool? introSeen,
    bool? setupComplete,
    bool? coachMarksSeen,
  }) {
    return OnboardingState(
      loaded: loaded ?? this.loaded,
      introSeen: introSeen ?? this.introSeen,
      setupComplete: setupComplete ?? this.setupComplete,
      coachMarksSeen: coachMarksSeen ?? this.coachMarksSeen,
    );
  }
}

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    _load();
    return const OnboardingState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = OnboardingState(
      loaded: true,
      introSeen: prefs.getBool(_kIntroSeen) ?? false,
      setupComplete: prefs.getBool(_kSetupComplete) ?? false,
      coachMarksSeen: prefs.getBool(_kCoachMarksSeen) ?? false,
    );
  }

  /// The pre-auth pitch has been read; the sign-in screens can take over.
  Future<void> markIntroSeen() async {
    if (state.introSeen) return;
    state = state.copyWith(introSeen: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIntroSeen, true);
  }

  /// Finish setup, seeding habits for each chosen focus area. Everything is
  /// written to Drift first (offline-first) and marked dirty for later sync.
  /// Passing an empty set simply starts with a clean slate.
  Future<void> completeSetup({Set<String> focusIds = const {}}) async {
    if (focusIds.isNotEmpty) {
      final userId = ref.read(currentUserIdProvider);
      final habits = ref.read(habitActionsProvider);
      for (final area in kFocusAreas.where((a) => focusIds.contains(a.id))) {
        for (final (title, note) in area.habits) {
          await habits.create(
            userId: userId,
            title: title,
            note: note,
            category: area.category,
          );
        }
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSetupComplete, true);
    state = state.copyWith(loaded: true, setupComplete: true);
  }

  /// Remember that the Home coach marks have been shown.
  Future<void> markCoachMarksSeen() async {
    if (state.coachMarksSeen) return;
    state = state.copyWith(coachMarksSeen: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCoachMarksSeen, true);
  }

  /// Replay the whole first run — intro, personalisation and walkthrough
  /// (offered in Settings).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIntroSeen, false);
    await prefs.setBool(_kSetupComplete, false);
    await prefs.setBool(_kCoachMarksSeen, false);
    state = state.copyWith(
      introSeen: false,
      setupComplete: false,
      coachMarksSeen: false,
    );
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);
