import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/core/gamification/days.dart';
import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/check_in_dao.dart';

/// The two check-in moments of a day.
enum CheckInMoment {
  morning,
  evening;

  String get wire => name;

  static CheckInMoment fromWire(String v) =>
      v == 'evening' ? CheckInMoment.evening : CheckInMoment.morning;
}

/// Moods, 1 to 5. Never graded: these are words, not scores.
abstract final class CheckInMood {
  static const heavy = 1;
  static const low = 2;
  static const okay = 3;
  static const good = 4;
  static const bright = 5;

  static const labels = {
    heavy: 'Heavy',
    low: 'Low',
    okay: 'Okay',
    good: 'Good',
    bright: 'Bright',
  };
}

/// Daily check-ins. Offline-first: every write lands in Drift and marks the
/// row dirty; the sync engine pushes it later (premium), as `check_in`.
class CheckInRepository {
  CheckInRepository(this._dao, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final CheckInDao _dao;
  final DateTime Function() _clock;
  static const _uuid = Uuid();

  static const maxNote = 200;

  /// Saves the check-in for (user, [day], [moment]). Saving again for the
  /// same moment updates that row (a deleted one is revived), so there is at
  /// most one per user, day and moment. A changed mood or note clears the old
  /// reply, which no longer fits.
  Future<CheckIn> save({
    required String userId,
    required CheckInMoment moment,
    required int mood,
    String? note,
    DateTime? day,
  }) async {
    final now = _clock();
    final d = dateOnly(day ?? now);
    final cleanNote = _cleanNote(note);
    final value = mood.clamp(CheckInMood.heavy, CheckInMood.bright);

    return _dao.attachedDatabase.transaction(() async {
      final existing =
          await _dao.findForMoment(userId, d, addDays(d, 1), moment.wire);
      if (existing == null) {
        final row = CheckIn(
          id: _uuid.v4(),
          userId: userId,
          date: d,
          moment: moment.wire,
          mood: value,
          note: cleanNote,
          auroraReply: null,
          createdAt: now,
          updatedAt: now,
          isDirty: true,
          isDeleted: false,
          deletedAt: null,
          lastSyncedAt: null,
        );
        await _dao.upsert(row.toCompanion(true));
        // Read back: Drift stores times to the second.
        return (await _dao.getById(row.id))!;
      }
      final unchanged = !existing.isDeleted &&
          existing.mood == value &&
          existing.note == cleanNote;
      await _dao.updateFields(
        existing.id,
        CheckInsCompanion(
          mood: Value(value),
          note: Value(cleanNote),
          auroraReply: Value(unchanged ? existing.auroraReply : null),
          isDeleted: const Value(false),
          deletedAt: const Value(null),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ),
      );
      return (await _dao.getById(existing.id))!;
    });
  }

  /// Keeps Aurora's reply on the row so it shows again (and syncs).
  Future<void> setReply(String id, String reply) async {
    await _dao.updateFields(
      id,
      CheckInsCompanion(
        auroraReply: Value(reply),
        updatedAt: Value(_clock()),
        isDirty: const Value(true),
      ),
    );
  }

  /// Soft delete: a tombstone that syncs, then is purged.
  Future<void> delete(String id) => _dao.softDelete(id, _clock());

  Future<CheckIn?> getById(String id) => _dao.getById(id);

  /// The live check-in for (user, [day], [moment]), or null.
  Future<CheckIn?> forMoment(
      String userId, DateTime day, CheckInMoment moment) async {
    final d = dateOnly(day);
    final row = await _dao.findForMoment(userId, d, addDays(d, 1), moment.wire);
    return row == null || row.isDeleted ? null : row;
  }

  /// Today's (or [day]'s) check-ins, morning first.
  Stream<List<CheckIn>> watchDay(String userId, DateTime day) {
    final d = dateOnly(day);
    return watchRange(userId, d, addDays(d, 1));
  }

  /// Check-ins whose day is in [start, end) (local days), oldest first, one
  /// per day and moment.
  Stream<List<CheckIn>> watchRange(
          String userId, DateTime start, DateTime end) =>
      _dao
          .watchRange(userId, dateOnly(start), dateOnly(end))
          .map(onePerMoment);

  Future<List<CheckIn>> getRange(
          String userId, DateTime start, DateTime end) async =>
      onePerMoment(
          await _dao.getRange(userId, dateOnly(start), dateOnly(end)));

  /// Collapses duplicates (two offline devices) to the most recently
  /// updated row per day and moment; sorted by day, morning first.
  static List<CheckIn> onePerMoment(List<CheckIn> rows) {
    final latest = <String, CheckIn>{};
    for (final c in rows) {
      final key = '${dayKey(c.date)}|${c.moment}';
      final prev = latest[key];
      if (prev == null || c.updatedAt.isAfter(prev.updatedAt)) latest[key] = c;
    }
    return latest.values.toList()
      ..sort((a, b) {
        final d = a.date.compareTo(b.date);
        if (d != 0) return d;
        return a.moment == b.moment ? 0 : (a.moment == 'morning' ? -1 : 1);
      });
  }

  static String? _cleanNote(String? note) {
    if (note == null) return null;
    var n = note.trim();
    if (n.isEmpty) return null;
    if (n.length > maxNote) n = n.substring(0, maxNote).trimRight();
    return n;
  }
}
