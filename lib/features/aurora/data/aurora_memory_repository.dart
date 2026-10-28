import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/core/utils/prose.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/aurora_memory_dao.dart';

/// Where a memory came from.
enum AuroraMemorySource {
  /// Proposed by Aurora in chat and saved with a tap.
  aurora,

  /// Typed by the user on "What Aurora remembers".
  you;

  String get wire => name;
}

/// Things Aurora remembers (premium). Local only, deliberately never synced.
class AuroraMemoryRepository {
  AuroraMemoryRepository(this._dao, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final AuroraMemoryDao _dao;
  final DateTime Function() _clock;
  static const _uuid = Uuid();

  static const maxLength = 200;

  /// Newest first.
  Stream<List<AuroraMemory>> watch(String userId) => _dao.watchAll(userId);

  Future<List<AuroraMemory>> list(String userId, {int? limit}) =>
      _dao.getAll(userId, limit: limit);

  /// Saves a memory. Blank text is ignored and an existing memory with the
  /// same text (ignoring case) is returned instead of a duplicate. Text is
  /// trimmed, dash-free and capped at [maxLength].
  Future<AuroraMemory?> add(String userId, String text,
      {AuroraMemorySource source = AuroraMemorySource.you}) async {
    var clean = stripLongDashes(text.replaceAll(RegExp(r'\s+'), ' ').trim());
    if (clean.isEmpty) return null;
    if (clean.length > maxLength) {
      clean = clean.substring(0, maxLength).trimRight();
    }
    final existing = await _dao.getAll(userId);
    for (final m in existing) {
      if (m.content.toLowerCase() == clean.toLowerCase()) return m;
    }
    final now = _clock();
    final row = AuroraMemory(
      id: _uuid.v4(),
      userId: userId,
      content: clean,
      source: source.wire,
      createdAt: now,
      updatedAt: now,
    );
    await _dao.insert(row.toCompanion(true));
    return row;
  }

  /// Hard delete (local only, nothing to sync).
  Future<void> delete(String id) => _dao.deleteById(id);

  /// Removes every memory for [userId].
  Future<void> clear(String userId) => _dao.deleteAllFor(userId);

  /// Puts a deleted memory back (Undo).
  Future<void> restore(AuroraMemory memory) =>
      _dao.insert(memory.toCompanion(true));
}
