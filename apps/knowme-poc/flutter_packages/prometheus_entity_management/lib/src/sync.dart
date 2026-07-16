// TJ-ARCH-MOB-001 compliant
/// SyncStatus — Dart mirror of gen_ui_types::sync::SyncStatus. Drives the UI
/// sync chip. Sealed: a switch that misses a variant is a compile error.
sealed class SyncStatus {
  const SyncStatus();
  const factory SyncStatus.offline() = SyncOffline;
  const factory SyncStatus.syncing(int pendingWrites) = SyncSyncing;
  const factory SyncStatus.live() = SyncLive;
  const factory SyncStatus.error(String message) = SyncError;
}

class SyncOffline extends SyncStatus {
  const SyncOffline();
}

class SyncSyncing extends SyncStatus {
  final int pendingWrites;
  const SyncSyncing(this.pendingWrites);
}

class SyncLive extends SyncStatus {
  const SyncLive();
}

class SyncError extends SyncStatus {
  final String message;
  const SyncError(this.message);
}
