// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      data: json['data'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$AppNotificationToJson(AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'body': instance.body,
      'type': instance.type,
      'data': instance.data,
      'is_read': instance.isRead,
      'read_at': instance.readAt?.toIso8601String(),
      'entity_type': instance.entityType,
      'entity_id': instance.entityId,
      'created_at': instance.createdAt.toIso8601String(),
    };
