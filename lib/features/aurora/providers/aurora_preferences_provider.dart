// How Aurora sounds when she writes to you.
//
// These are device preferences, not user content: they live in
// SharedPreferences next to the theme and onboarding flags rather than in
// Drift, and they ride along with each Aurora request instead of being stored
// on the server. Nothing here needs to sync, and nothing here is worth keeping
// a server-side copy of.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPreferredName = 'atlas_aurora_preferred_name';
const _kTone = 'atlas_aurora_tone';
const _kLength = 'atlas_aurora_length';
const _kIntention = 'atlas_aurora_intention';
const _kNudges = 'atlas_aurora_nudges';

/// The register Aurora writes in.
enum AuroraTone {
  gentle('Gentle', 'Soft, reassuring, plenty of room to rest'),
  warm('Warm', 'Personal and glad to hear from you'),
  direct('Direct', 'Friendly, but straight to the next small step'),
  playful('Playful', 'Light on its feet, never flippant');

  const AuroraTone(this.label, this.blurb);
  final String label;
  final String blurb;

  /// The value sent to the backend. Matches the keys in `AuroraVoice`.
  String get wire => name;
}

/// How much Aurora says.
enum AuroraLength {
  brief('Brief', 'Two or three sentences'),
  balanced('Balanced', 'A short paragraph'),
  thoughtful('Thoughtful', 'Room for two paragraphs when it matters');

  const AuroraLength(this.label, this.blurb);
  final String label;
  final String blurb;

  String get wire => name;
}

class AuroraPreferences {
  const AuroraPreferences({
    this.loaded = false,
    this.preferredName = '',
    this.tone = AuroraTone.gentle,
    this.length = AuroraLength.balanced,
    this.intention = '',
    this.nudgesEnabled = true,
  });

  final bool loaded;

  /// What Aurora calls you. Empty means "no particular name".
  final String preferredName;

  final AuroraTone tone;
  final AuroraLength length;

  /// A sentence, in the user's own words, about what matters right now.
  final String intention;

  /// Whether the proactive nudge card appears on Home and the Aurora tab.
  final bool nudgesEnabled;

  /// True when anything has been changed from the defaults.
  bool get isPersonalised =>
      preferredName.isNotEmpty ||
      intention.isNotEmpty ||
      tone != AuroraTone.gentle ||
      length != AuroraLength.balanced;

  /// The `preferences` object sent with each Aurora request. Empty fields are
  /// left out entirely so the backend falls back to Aurora's default voice.
  Map<String, dynamic> toWire() => {
        if (preferredName.isNotEmpty) 'preferred_name': preferredName,
        'tone': tone.wire,
        'length': length.wire,
        if (intention.isNotEmpty) 'intention': intention,
      };

  AuroraPreferences copyWith({
    bool? loaded,
    String? preferredName,
    AuroraTone? tone,
    AuroraLength? length,
    String? intention,
    bool? nudgesEnabled,
  }) {
    return AuroraPreferences(
      loaded: loaded ?? this.loaded,
      preferredName: preferredName ?? this.preferredName,
      tone: tone ?? this.tone,
      length: length ?? this.length,
      intention: intention ?? this.intention,
      nudgesEnabled: nudgesEnabled ?? this.nudgesEnabled,
    );
  }
}

class AuroraPreferencesController extends Notifier<AuroraPreferences> {
  /// Long enough for a name or a sentence, short enough that the prompt stays
  /// mostly the user's week rather than their settings.
  static const maxNameLength = 40;
  static const maxIntentionLength = 200;

  @override
  AuroraPreferences build() {
    _load();
    return const AuroraPreferences();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AuroraPreferences(
      loaded: true,
      preferredName: prefs.getString(_kPreferredName) ?? '',
      tone: _toneFrom(prefs.getString(_kTone)),
      length: _lengthFrom(prefs.getString(_kLength)),
      intention: prefs.getString(_kIntention) ?? '',
      nudgesEnabled: prefs.getBool(_kNudges) ?? true,
    );
  }

  Future<void> setPreferredName(String value) async {
    final clean = _tidy(value, maxNameLength);
    if (clean == state.preferredName) return;
    state = state.copyWith(preferredName: clean);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPreferredName, clean);
  }

  Future<void> setIntention(String value) async {
    final clean = _tidy(value, maxIntentionLength);
    if (clean == state.intention) return;
    state = state.copyWith(intention: clean);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kIntention, clean);
  }

  Future<void> setTone(AuroraTone tone) async {
    if (tone == state.tone) return;
    state = state.copyWith(tone: tone);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTone, tone.name);
  }

  Future<void> setLength(AuroraLength length) async {
    if (length == state.length) return;
    state = state.copyWith(length: length);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLength, length.name);
  }

  Future<void> setNudgesEnabled(bool value) async {
    if (value == state.nudgesEnabled) return;
    state = state.copyWith(nudgesEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNudges, value);
  }

  /// Back to Aurora's default voice, leaving the nudge setting alone.
  Future<void> resetVoice() async {
    state = state.copyWith(
      preferredName: '',
      intention: '',
      tone: AuroraTone.gentle,
      length: AuroraLength.balanced,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPreferredName);
    await prefs.remove(_kIntention);
    await prefs.remove(_kTone);
    await prefs.remove(_kLength);
  }

  /// Collapse whitespace and cap the length, so what we store is what we would
  /// have been willing to send anyway.
  static String _tidy(String input, int maxLength) {
    final collapsed = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    return collapsed.length <= maxLength
        ? collapsed
        : collapsed.substring(0, maxLength).trimRight();
  }

  static AuroraTone _toneFrom(String? name) => AuroraTone.values.firstWhere(
        (t) => t.name == name,
        orElse: () => AuroraTone.gentle,
      );

  static AuroraLength _lengthFrom(String? name) =>
      AuroraLength.values.firstWhere(
        (l) => l.name == name,
        orElse: () => AuroraLength.balanced,
      );
}

final auroraPreferencesProvider =
    NotifierProvider<AuroraPreferencesController, AuroraPreferences>(
  AuroraPreferencesController.new,
);
