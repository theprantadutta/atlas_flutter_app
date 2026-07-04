import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart' show AvatarsCompanion;
import 'package:atlas_flutter_app/data/database/daos/avatar_dao.dart';
import 'package:atlas_flutter_app/data/models/avatar.dart';
import 'package:atlas_flutter_app/data/repositories/base_repository.dart';

/// Offline-first avatar repository.
///
/// Drift is the source of truth. Reads come from the local DAO only; writes go
/// to Drift first and mark the row dirty (`isDirty = true`) so the row-based
/// sync engine (`OfflineManager._pushAvatar`) picks them up when — and only
/// when — cloud sync is enabled and the user is entitled. There is no network
/// in the read or write path.
class AvatarRepository extends BaseRepository {
  final AvatarDao _avatarDao;
  final _uuid = const Uuid();

  AvatarRepository(
    super.apiService,
    super.offlineManager,
    this._avatarDao,
  );

  // ─── READ operations ─────────────────────────────────────────

  /// Get the current user's avatar from the local database.
  Future<Avatar> getAvatar() async {
    final local = await _avatarDao.getAvatarByUserId(currentUserId);
    if (local == null) {
      throw Exception('Avatar not found');
    }
    return Avatar.fromJson(_driftAvatarToJson(local));
  }

  /// Get avatar statistics computed from the local avatar. There is no separate
  /// local stats store, so this returns a snapshot of the avatar's attributes.
  Future<Map<String, dynamic>> getAvatarStats() async {
    final local = await _avatarDao.getAvatarByUserId(currentUserId);
    if (local == null) return {};
    final avatar = Avatar.fromJson(_driftAvatarToJson(local));
    return {
      'level': avatar.level,
      'current_xp': avatar.currentXp,
      'strength': avatar.strength,
      'wisdom': avatar.wisdom,
      'intelligence': avatar.intelligence,
      'progress_to_next_level': avatar.progressToNextLevel,
    };
  }

  // ─── WRITE operations (local-first, mark dirty) ──────────────

  /// Create an avatar for the current user, written to Drift as a dirty row.
  Future<Avatar> createAvatar(Map<String, dynamic> data) async {
    final now = DateTime.now();
    final id = data['id']?.toString() ?? _uuid.v4();
    final userId = data['user_id']?.toString() ??
        data['userId']?.toString() ??
        currentUserId;
    final avatar = Avatar(
      id: id,
      userId: userId,
      name: data['name']?.toString() ?? 'Adventurer',
      level: (data['level'] as num?)?.toInt() ?? 1,
      currentXp: (data['current_xp'] as num?)?.toInt() ??
          (data['currentXp'] as num?)?.toInt() ??
          0,
      strength: (data['strength'] as num?)?.toInt() ?? 0,
      wisdom: (data['wisdom'] as num?)?.toInt() ?? 0,
      intelligence: (data['intelligence'] as num?)?.toInt() ?? 0,
      appearance: data['appearance'] as Map<String, dynamic>?,
      unlockedItems: (data['unlocked_items'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      createdAt: now,
      updatedAt: now,
    );
    await _avatarDao.upsertAvatar(_toCompanion(avatar));
    return avatar;
  }

  /// Update the avatar's appearance locally and mark the row dirty.
  Future<Avatar> updateAppearance(Map<String, dynamic> data) async {
    final now = DateTime.now();
    final local = await _avatarDao.getAvatarByUserId(currentUserId);
    if (local == null) {
      throw Exception('Avatar not found');
    }
    final current = Avatar.fromJson(_driftAvatarToJson(local));
    final updated = current.copyWith(appearance: data, updatedAt: now);
    await _avatarDao.upsertAvatar(_toCompanion(updated));
    return updated;
  }

  /// Unlock an item for the avatar locally and mark the row dirty.
  Future<Map<String, dynamic>> unlockItem(Map<String, dynamic> data) async {
    final now = DateTime.now();
    final local = await _avatarDao.getAvatarByUserId(currentUserId);
    if (local != null) {
      final current = Avatar.fromJson(_driftAvatarToJson(local));
      final items = <String>{...?current.unlockedItems};
      final itemId = data['item_id']?.toString() ??
          data['item']?.toString() ??
          data['id']?.toString();
      if (itemId != null) items.add(itemId);
      final updated = current.copyWith(
        unlockedItems: items.toList(),
        updatedAt: now,
      );
      await _avatarDao.upsertAvatar(_toCompanion(updated));
    }
    return {'unlocked': true, ...data};
  }

  // ─── DB Persistence Helpers ────────────────────────────────

  /// Builds a companion for the avatars table. Always marks the row dirty with a
  /// fresh sync marker so `OfflineManager._pushAvatar` will push it.
  AvatarsCompanion _toCompanion(Avatar avatar) {
    return AvatarsCompanion(
      id: Value(avatar.id),
      userId: Value(avatar.userId),
      name: Value(avatar.name),
      level: Value(avatar.level),
      currentXp: Value(avatar.currentXp),
      strength: Value(avatar.strength),
      wisdom: Value(avatar.wisdom),
      intelligence: Value(avatar.intelligence),
      appearanceData: Value(
        avatar.appearance != null ? jsonEncode(avatar.appearance) : null,
      ),
      unlockedItems: Value(
        avatar.unlockedItems != null ? jsonEncode(avatar.unlockedItems) : null,
      ),
      createdAt: Value(avatar.createdAt),
      updatedAt: Value(avatar.updatedAt),
      isDirty: const Value(true),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────

  /// Converts a Drift avatar row into the JSON shape [Avatar.fromJson] expects.
  /// The row stores `appearance`/`unlocked_items` as encoded JSON strings, so
  /// they are decoded back into a map/list here.
  Map<String, dynamic> _driftAvatarToJson(dynamic driftAvatar) {
    Map<String, dynamic>? appearance;
    final appearanceData = driftAvatar.appearanceData as String?;
    if (appearanceData != null && appearanceData.isNotEmpty) {
      try {
        appearance = jsonDecode(appearanceData) as Map<String, dynamic>;
      } catch (_) {
        // Malformed appearance — leave null.
      }
    }
    List<dynamic>? unlocked;
    final unlockedItems = driftAvatar.unlockedItems as String?;
    if (unlockedItems != null && unlockedItems.isNotEmpty) {
      try {
        unlocked = jsonDecode(unlockedItems) as List<dynamic>;
      } catch (_) {
        // Malformed list — leave null.
      }
    }
    return {
      'id': driftAvatar.id,
      'user_id': driftAvatar.userId,
      'name': driftAvatar.name,
      'level': driftAvatar.level,
      'current_xp': driftAvatar.currentXp,
      'strength': driftAvatar.strength,
      'wisdom': driftAvatar.wisdom,
      'intelligence': driftAvatar.intelligence,
      'appearance': appearance,
      'unlocked_items': unlocked,
      'created_at': driftAvatar.createdAt.toIso8601String(),
      'updated_at': driftAvatar.updatedAt.toIso8601String(),
    };
  }
}
