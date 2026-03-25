import 'package:json_annotation/json_annotation.dart';

part 'app_notification.g.dart';

@JsonSerializable()
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? data;
  final bool isRead;
  final DateTime? readAt;
  final String? entityType;
  final String? entityId;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.isRead = false,
    this.readAt,
    this.entityType,
    this.entityId,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    String? data,
    bool? isRead,
    DateTime? readAt,
    String? entityType,
    String? entityId,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
