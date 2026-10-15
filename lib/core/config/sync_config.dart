/// Cloud sync configuration.
///
/// Sync is a **premium** feature: the engine only runs for users with the
/// cloud_sync entitlement (`canSyncProvider`). Everyone else stays a purely
/// local (Drift) experience that never touches the network for data. This
/// switch is the build-wide kill switch on top of that.
class SyncConfig {
  SyncConfig._();

  /// Master switch for the sync engine.
  static const bool enabled = true;
}
