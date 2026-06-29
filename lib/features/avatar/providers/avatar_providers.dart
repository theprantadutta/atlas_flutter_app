import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/avatar_dao.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';
import 'package:atlas_flutter_app/features/tasks/providers/task_providers.dart'
    show currentUserIdProvider;

/// Reactive stream of the current user's avatar from Drift (source of truth).
/// Avatar is 1:1 per user, so this emits a single nullable row.
final avatarStreamProvider = StreamProvider.autoDispose<Avatar?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final dao = ref.read(avatarDaoProvider);
  // Seed a default avatar once so a fresh offline DB has something to show.
  ref.read(avatarActionsProvider).ensureExists(userId);
  return dao.watchAvatar(userId);
});

final avatarActionsProvider = Provider<AvatarActions>((ref) {
  return AvatarActions(ref.read(avatarDaoProvider));
});

// ─── Appearance encoding ──────────────────────────────────────────────
// The customization studio works in palette indices (skin/hair/outfit). On
// the wire the appearance is the backend's structured shape (skin_tone,
// hair_style, hair_color, eye_color, clothing, accessory) so it stays
// field-for-field with the .NET entity. We carry the three editable indices
// inside skin_tone / hair_color / clothing as strings; the rest keep defaults.

/// Decode the stored appearance JSON into the three editable palette indices.
({int skin, int hair, int outfit}) avatarIndicesFromJson(
    String? appearanceData) {
  var skin = 1, hair = 0, outfit = 0;
  if (appearanceData != null && appearanceData.isNotEmpty) {
    try {
      final m = jsonDecode(appearanceData) as Map<String, dynamic>;
      skin = int.tryParse('${m['skin_tone']}') ?? skin;
      hair = int.tryParse('${m['hair_color']}') ?? hair;
      outfit = int.tryParse('${m['clothing']}') ?? outfit;
    } catch (_) {
      // Malformed appearance — fall back to defaults.
    }
  }
  return (skin: skin, hair: hair, outfit: outfit);
}

/// Build the canonical appearance map from the three editable indices.
Map<String, dynamic> avatarAppearanceMap({
  required int skin,
  required int hair,
  required int outfit,
}) {
  return {
    'skin_tone': '$skin',
    'hair_style': 'short',
    'hair_color': '$hair',
    'eye_color': 'brown',
    'clothing': '$outfit',
    'accessory': 'none',
  };
}

String avatarAppearanceJson({
  required int skin,
  required int hair,
  required int outfit,
}) {
  return jsonEncode(avatarAppearanceMap(skin: skin, hair: hair, outfit: outfit));
}

/// Local-first avatar mutations: every write lands in Drift first and is
/// marked dirty for later (premium) sync.
class AvatarActions {
  AvatarActions(this._dao);
  final AvatarDao _dao;
  final _uuid = const Uuid();
  final _seeded = <String>{};

  Future<void> ensureExists(String userId) async {
    if (_seeded.contains(userId)) return;
    _seeded.add(userId);
    if (await _dao.getAvatarByUserId(userId) != null) return;
    final now = DateTime.now();
    await _dao.insertAvatar(AvatarsCompanion(
      id: Value(_uuid.v4()),
      userId: Value(userId),
      name: const Value('Adventurer'),
      level: const Value(1),
      currentXp: const Value(0),
      strength: const Value(12),
      wisdom: const Value(18),
      intelligence: const Value(15),
      appearanceData:
          Value(avatarAppearanceJson(skin: 1, hair: 0, outfit: 0)),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDirty: const Value(true),
    ));
  }

  Future<void> saveAppearance(
    String userId, {
    required int skin,
    required int hair,
    required int outfit,
  }) async {
    final avatar = await _dao.getAvatarByUserId(userId);
    if (avatar == null) return;
    await _dao.updateFields(
      avatar.id,
      AvatarsCompanion(
        appearanceData:
            Value(avatarAppearanceJson(skin: skin, hair: hair, outfit: outfit)),
        updatedAt: Value(DateTime.now()),
        isDirty: const Value(true),
      ),
    );
  }

  Future<void> rename(String userId, String name) async {
    final avatar = await _dao.getAvatarByUserId(userId);
    if (avatar == null) return;
    await _dao.updateFields(
      avatar.id,
      AvatarsCompanion(
        name: Value(name),
        updatedAt: Value(DateTime.now()),
        isDirty: const Value(true),
      ),
    );
  }
}
