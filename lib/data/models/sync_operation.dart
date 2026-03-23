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

  // ─── Computed Properties ─────────────────────────────────────

  /// Whether this operation has exceeded the maximum number of retries.
  bool get hasExceededMaxRetries => retryCount >= maxRetries;

  /// Exponential backoff delay: 1s, 2s, 4s, 8s, ... capped at 5 minutes.
  Duration get nextRetryDelay =>
      Duration(seconds: (1 << retryCount).clamp(1, 300));

  /// Whether enough time has passed since the last attempt to retry.
  bool get isReadyForRetry {
    if (hasExceededMaxRetries) return false;
    return DateTime.now().isAfter(timestamp.add(nextRetryDelay));
  }

  /// Returns a copy with an incremented retry count and a fresh timestamp.
  SyncOperation withRetry() =>
      copyWith(retryCount: retryCount + 1, timestamp: DateTime.now());

  // ─── JSON ──────────────────────────────────────────────────────

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
