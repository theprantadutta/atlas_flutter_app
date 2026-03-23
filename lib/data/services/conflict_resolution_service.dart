class ConflictResolutionService {
  /// Resolves a conflict between local and remote data using last-write-wins.
  ///
  /// Compares 'updated_at' timestamps. If both are equal, the server (remote)
  /// version wins to maintain consistency.
  Map<String, dynamic> resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) {
    final localUpdatedAt = _parseTimestamp(local['updated_at']);
    final remoteUpdatedAt = _parseTimestamp(remote['updated_at']);

    if (localUpdatedAt == null && remoteUpdatedAt == null) {
      return remote;
    }
    if (localUpdatedAt == null) return remote;
    if (remoteUpdatedAt == null) return local;

    // Server wins on tie
    if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
      return local;
    }
    return remote;
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
