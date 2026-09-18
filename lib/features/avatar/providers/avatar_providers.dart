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

  /// The server owns the avatar — it creates the 1:1 row at registration. This
  /// only gives the UI something to draw on a device that has not pulled yet.
  ///
  /// It is therefore written *clean* and stamped at the epoch, and both matter:
  ///
  ///  * dirty, and the sync engine pushes this invented 10/10/10 row over the
  ///    real one, so reinstalling the app silently reset a real avatar;
  ///  * stamped `now`, and last-write-wins rejects the server's genuinely older
  ///    avatar on pull, so the placeholder could never be replaced either.
  ///
  /// Together those two made the placeholder permanent and destructive. An
  /// epoch stamp loses every comparison, which is exactly what a stand-in
  /// should do; the first real edit marks the row dirty in the normal way.
  static final _placeholderStamp = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> ensureExists(String userId) async {
    if (_seeded.contains(userId)) return;
    _seeded.add(userId);
    if (await _dao.getAvatarByUserId(userId) != null) return;
    await _dao.insertAvatar(AvatarsCompanion(
      id: Value(_uuid.v4()),
      userId: Value(userId),
      name: const Value('Adventurer'),
      level: const Value(1),
      currentXp: const Value(0),
      strength: const Value(10),
      wisdom: const Value(10),
      intelligence: const Value(10),
      appearanceData:
          Value(avatarAppearanceJson(skin: 1, hair: 0, outfit: 0)),
      createdAt: Value(_placeholderStamp),
      updatedAt: Value(_placeholderStamp),
      isDirty: const Value(false),
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
