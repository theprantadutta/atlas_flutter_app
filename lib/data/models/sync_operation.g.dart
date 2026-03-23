// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_operation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncOperation _$SyncOperationFromJson(Map<String, dynamic> json) =>
    SyncOperation(
      id: json['id'] as String,
      operationType: json['operation_type'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      data: json['data'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      maxRetries: (json['max_retries'] as num?)?.toInt() ?? 3,
    );

Map<String, dynamic> _$SyncOperationToJson(SyncOperation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'operation_type': instance.operationType,
      'entity_type': instance.entityType,
      'entity_id': instance.entityId,
      'data': instance.data,
      'timestamp': instance.timestamp.toIso8601String(),
      'retry_count': instance.retryCount,
      'max_retries': instance.maxRetries,
    };
