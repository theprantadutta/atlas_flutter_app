import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/database/daos/notification_dao.dart';

/// What an inbox entry is about. The inbox keeps moments worth coming back
/// to; reminders ("now" messages) never go in it.
class InboxKind {
  InboxKind._();
  static const achievement = 'achievement';
  static const place = 'place';
  static const level = 'level';
  static const letter = 'letter';
  static const account = 'account';
}

/// Where each kind leads. Every value is a real route.
String? routeForInboxKind(String kind) => switch (kind) {
      InboxKind.achievement => '/world/achievements',
      InboxKind.place => '/world',
      InboxKind.level => '/profile',
      InboxKind.letter => '/aurora/letter',
      InboxKind.account => '/paywall',
      _ => null,
    };

/// Files moments into the inbox: the local Drift table, which is the inbox's
/// only source. Entries are written the moment something happens on this
/// device (free or premium, online or not), never synced (each device keeps
/// its own), and keyed so the same moment is filed once however often it is
/// reported.
class Inbox {
  Inbox(this._dao);
  final NotificationDao _dao;
  static const _uuid = Uuid();

  /// The id for [key]: the same moment always maps to the same row.
  static String idFor(String userId, String key) =>
      _uuid.v5(Namespace.url.value, 'atlas:inbox:$userId:$key');

  Future<void> add({
    required String userId,
    required String kind,
    required String key,
    required String title,
    required String body,
    String? entityType,
    String? entityId,
    DateTime? at,
    String? id,
  }) async {
    final when = at ?? DateTime.now();
    await _dao.insertIfAbsent(NotificationsCompanion.insert(
      id: id ?? idFor(userId, key),
      userId: userId,
      title: title,
      body: body,
      type: kind,
      data: Value(jsonEncode({'kind': kind})),
      entityType: Value(entityType),
      entityId: Value(entityId),
      createdAt: when,
      updatedAt: Value(when),
      // Local only: the sync engine never sends inbox rows.
      isDirty: const Value(false),
    ));
  }
}
