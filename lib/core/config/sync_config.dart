/// Cloud sync configuration.
///
/// Sync is a **premium** feature. It is OFF by default — the app is fully
/// usable as a local-only (Drift) experience and never touches the network for
/// data. Billing/entitlement that flips this on per-user comes later; for now
/// it's a single build-time gate the sync engine checks before doing any
/// push/pull.
class SyncConfig {
  SyncConfig._();

  /// Master switch for the sync engine. Keep false until premium is wired.
  static const bool enabled = false;
}
