// TJ-ARCH-MOB-001 compliant
//! Scope-aware dev loopback transport (C-122). Runs the partial-replication
//! contract — scope validation, attach, row-op streaming into a [`LocalStore`],
//! write enqueueing — without any gateway, so slices and tests run today and the
//! PES/FRF client drops in behind the same seam later (ADR-LFS-1).
//!
//! The paired [`LoopbackFeed`] plays the server role: push [`RowChange`]s and
//! they apply to the store exactly as a gateway stream would; enqueued writes
//! are inspectable instead of being sent anywhere.

use super::seam::{LocalStore, RowChange};
use super::status::{SyncStatusHandle, SyncStatusStream};
use async_trait::async_trait;
use gen_ui_types::error::{CoreError, CoreResult};
use gen_ui_types::sync::{SyncScope, SyncStatus, SyncTransport};
use std::sync::{Arc, Mutex};
use tokio::sync::mpsc;

/// Server-side handle: feed row changes and inspect enqueued writes.
#[derive(Clone)]
pub struct LoopbackFeed {
    tx: mpsc::UnboundedSender<Vec<RowChange>>,
    writes: Arc<Mutex<Vec<String>>>,
    scopes: Arc<Mutex<Vec<SyncScope>>>,
}

impl LoopbackFeed {
    /// Push one batch of row changes ("one transaction" at the seam).
    pub fn push(&self, changes: Vec<RowChange>) -> CoreResult<()> {
        self.tx
            .send(changes)
            .map_err(|_| CoreError::Terminal("loopback transport stopped".into()))
    }

    /// Writes enqueued by the client side, in order (change_json payloads).
    pub fn enqueued_writes(&self) -> Vec<String> {
        self.writes.lock().expect("loopback writes lock").clone()
    }

    /// Scopes the client attached (validated).
    pub fn attached_scopes(&self) -> Vec<SyncScope> {
        self.scopes.lock().expect("loopback scopes lock").clone()
    }
}

pub struct LoopbackSyncTransport {
    store: Arc<dyn LocalStore>,
    status: SyncStatusHandle,
    rx: Mutex<Option<mpsc::UnboundedReceiver<Vec<RowChange>>>>,
    writes: Arc<Mutex<Vec<String>>>,
    scopes: Arc<Mutex<Vec<SyncScope>>>,
}

impl LoopbackSyncTransport {
    pub fn new(store: Arc<dyn LocalStore>) -> (Arc<Self>, LoopbackFeed) {
        let (tx, rx) = mpsc::unbounded_channel();
        let writes = Arc::new(Mutex::new(Vec::new()));
        let scopes = Arc::new(Mutex::new(Vec::new()));
        let transport = Arc::new(Self {
            store,
            status: SyncStatusHandle::new(),
            rx: Mutex::new(Some(rx)),
            writes: Arc::clone(&writes),
            scopes: Arc::clone(&scopes),
        });
        (transport, LoopbackFeed { tx, writes, scopes })
    }

    /// Subscribe to status transitions (drives the SyncChip in slices).
    pub fn status_stream(&self) -> SyncStatusStream {
        self.status.subscribe()
    }

    fn spawn_pump(&self) -> CoreResult<()> {
        let mut rx = self
            .rx
            .lock()
            .expect("loopback rx lock")
            .take()
            .ok_or_else(|| CoreError::Terminal("loopback transport already started".into()))?;
        let store = Arc::clone(&self.store);
        let status = self.status.clone();
        status.set(SyncStatus::Live);
        tokio::spawn(async move {
            while let Some(batch) = rx.recv().await {
                if let Err(error) = store.apply_batch(&batch).await {
                    status.set(SyncStatus::Error {
                        message: error.to_string(),
                    });
                    return;
                }
                status.set(SyncStatus::Live);
            }
            status.set(SyncStatus::Offline);
        });
        Ok(())
    }
}

#[async_trait]
impl SyncTransport for LoopbackSyncTransport {
    async fn start(&self) -> CoreResult<()> {
        self.spawn_pump()
    }

    async fn start_scopes(&self, scopes: &[SyncScope]) -> CoreResult<()> {
        for scope in scopes {
            scope.validate()?;
        }
        *self.scopes.lock().expect("loopback scopes lock") = scopes.to_vec();
        self.spawn_pump()
    }

    async fn enqueue_write(&self, change_json: &str) -> CoreResult<()> {
        let mut writes = self.writes.lock().expect("loopback writes lock");
        writes.push(change_json.to_string());
        self.status.set(SyncStatus::Syncing {
            pending_writes: writes.len() as u32,
        });
        Ok(())
    }

    fn status(&self) -> SyncStatus {
        self.status.current()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use gen_ui_types::sync::{ScopeKind, SyncScope};
    use std::collections::BTreeMap;
    use tokio::sync::Mutex as AsyncMutex;

    struct MemStore {
        applied: AsyncMutex<Vec<RowChange>>,
    }

    #[async_trait]
    impl LocalStore for MemStore {
        async fn apply_batch(&self, changes: &[RowChange]) -> CoreResult<()> {
            self.applied.lock().await.extend_from_slice(changes);
            Ok(())
        }
        async fn truncate_shape(&self, _table: &str) -> CoreResult<()> {
            Ok(())
        }
    }

    fn row(table: &str, key: &str) -> RowChange {
        RowChange {
            table: table.into(),
            op: super::super::seam::RowOp::Insert,
            key: format!("\"{key}\""),
            value_json: format!("{{\"id\":\"{key}\"}}"),
        }
    }

    // The partial-replication contract end-to-end without a gateway: attach
    // validated scopes, stream a batch, observe it applied and status Live.
    #[tokio::test]
    async fn scoped_attach_streams_rows_into_the_store() {
        let store = Arc::new(MemStore {
            applied: AsyncMutex::new(Vec::new()),
        });
        let (transport, feed) = LoopbackSyncTransport::new(store.clone());
        let scopes = vec![
            SyncScope::user_subset("user-notes", "user-1"),
            SyncScope::shared_lookup("lookup-metatypes"),
        ];
        transport.start_scopes(&scopes).await.expect("attach");
        assert_eq!(feed.attached_scopes().len(), 2);

        feed.push(vec![row("notes", "n1"), row("notes", "n2")])
            .expect("push");
        // Yield until the pump applies (bounded, no sleeps-forever).
        for _ in 0..100 {
            if store.applied.lock().await.len() == 2 {
                break;
            }
            tokio::task::yield_now().await;
        }
        assert_eq!(store.applied.lock().await.len(), 2);
        assert_eq!(transport.status(), SyncStatus::Live);
    }

    // Fail closed at the seam: a tenantless user-subset scope never attaches.
    #[tokio::test]
    async fn tenantless_scope_is_refused() {
        let store = Arc::new(MemStore {
            applied: AsyncMutex::new(Vec::new()),
        });
        let (transport, feed) = LoopbackSyncTransport::new(store);
        let bad = SyncScope {
            name: "user-notes".into(),
            params: BTreeMap::new(),
            kind: ScopeKind::UserSubset,
        };
        assert!(transport.start_scopes(&[bad]).await.is_err());
        assert!(feed.attached_scopes().is_empty());
    }

    // Writes enqueue durably-inspectably and drive Syncing{pending_writes}.
    #[tokio::test]
    async fn enqueued_writes_are_inspectable_and_counted() {
        let store = Arc::new(MemStore {
            applied: AsyncMutex::new(Vec::new()),
        });
        let (transport, feed) = LoopbackSyncTransport::new(store);
        transport
            .enqueue_write("{\"op\":\"insert\"}")
            .await
            .expect("enqueue");
        transport
            .enqueue_write("{\"op\":\"update\"}")
            .await
            .expect("enqueue");
        assert_eq!(feed.enqueued_writes().len(), 2);
        assert_eq!(
            transport.status(),
            SyncStatus::Syncing { pending_writes: 2 }
        );
    }
}
