import 'package:drift/drift.dart';

/// A daily mood check-in (morning or evening). Synced entity `CheckIn`: every
/// column here must match the backend entity/DTO field-for-field (snake_case on
/// the wire, entity type `check_in`).
///
/// At most one live row per (user, date, moment); the repository upserts.
/// There is deliberately no unique index: two offline devices can each make a
/// row for the same moment, and a pull must never fail on that. Reads pick the
/// most recently updated row.
class CheckIns extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  /// The local day, stored like ledger days (local midnight).
  DateTimeColumn get date => dateTime()();

  /// `morning` | `evening`
  TextColumn get moment => text()();

  /// 1 heavy, 2 low, 3 okay, 4 good, 5 bright.
  IntColumn get mood => integer()();

  /// Max 200 chars.
  TextColumn get note => text().nullable()();

  /// Aurora's reply, kept so it shows again.
  TextColumn get auroraReply => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  // ─── Sync metadata (offline-first) ───
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
