import 'package:json_annotation/json_annotation.dart';

part 'sync_operation.g.dart';

@JsonSerializable()
class SyncOperation {
  final String id;
  final String operationType;
  final String entityType;
  final String entityId;
  final String? data;
  final DateTime timestamp;
  final int retryCount;
  final int maxRetries;

  const SyncOperation({
    required this.id,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.maxRetries = 3,
  });

  factory SyncOperation.fromJson(Map<String, dynamic> json) =>
      _$SyncOperationFromJson(json);

  Map<String, dynamic> toJson() => _$SyncOperationToJson(this);

  SyncOperation copyWith({
    String? id,
    String? operationType,
    String? entityType,
    String? entityId,
    String? data,
    DateTime? timestamp,
    int? retryCount,
    int? maxRetries,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
    );
  }
}
