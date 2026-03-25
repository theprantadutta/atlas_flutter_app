import 'package:drift/drift.dart';

class Notifications extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get type => text()();
  TextColumn get data => text().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get readAt => dateTime().nullable()();
  TextColumn get entityType => text().nullable()();
  TextColumn get entityId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
