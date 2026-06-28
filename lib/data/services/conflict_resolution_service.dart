class ConflictResolutionService {
  /// Resolves a conflict between local and remote data using last-write-wins,
  /// with **local winning ties** (the offline-first rule): the server only wins
  /// when its `updated_at` is *strictly* newer than the local one.
  Map<String, dynamic> resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) {
    final localUpdatedAt = _parseTimestamp(local['updated_at']);
    final remoteUpdatedAt = _parseTimestamp(remote['updated_at']);

    // Missing timestamps: prefer local (it's the source of truth).
    if (remoteUpdatedAt == null) return local;
    if (localUpdatedAt == null) return remote;

    // Server wins ONLY if strictly newer; otherwise local wins (incl. ties).
    return remoteUpdatedAt.isAfter(localUpdatedAt) ? remote : local;
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
