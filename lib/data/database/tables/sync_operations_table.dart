import 'package:drift/drift.dart';

class SyncOperations extends Table {
  TextColumn get id => text()();
  TextColumn get operationType => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get data => text().nullable()();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get maxRetries => integer().withDefault(const Constant(3))();

  @override
  Set<Column> get primaryKey => {id};
}
