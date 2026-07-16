// TJ-ARCH-MOB-001 compliant
//! Run registry: routes a chat run's A2uiEvent stream from the task that drives
//! liter-llm's `chat_stream` to whatever subscribed for that run_id.
//!
//! DESIGN NOTE (T7, ambiguous in spec — "a simple registry ... is a reasonable
//! design, pick something correct and simple"): `chat_send` returns a run_id
//! immediately and spawns the streaming work (gen_ui_runtime::spawn, one global
//! Tokio runtime). The consumer (frb `chat_events(run_id, sink)` on mobile, or a
//! Tauri command + emit on desktop) subscribes AFTER `chat_send` returns, so the
//! producer side cannot assume a receiver exists yet. A
//! `tokio::sync::broadcast` channel per run_id (registered eagerly by
//! `chat_send` before the producer task starts pushing) lets any number of late
//! subscribers attach without the producer blocking on backpressure from a slow
//! consumer, and naturally drops events for runs nobody is listening to. Entries
//! are removed once the run reaches a terminal state (Done/Error) and the last
//! receiver is known to have been served, via `remove` called from the
//! producer's own terminal-event path — see `chat.rs`.
use std::sync::Arc;

use dashmap::DashMap;
use gen_ui_types::events::A2uiEvent;
use tokio::sync::broadcast;

/// Channel capacity for a single run's event broadcast. Chat turns are
/// short-lived (single request/response), so a bounded buffer large enough to
/// hold a burst of deltas ahead of a subscriber attaching is sufficient; a lagged
/// subscriber only misses the earliest deltas, never panics.
const RUN_CHANNEL_CAPACITY: usize = 256;

/// Registers one broadcast sender per in-flight run_id so `chat_send`'s spawned
/// producer task and `chat_events`'s (frb) / the Tauri emit bridge's consumer
/// side can rendezvous without either one needing to exist first.
#[derive(Clone, Default)]
pub struct RunRegistry {
    runs: Arc<DashMap<String, broadcast::Sender<A2uiEvent>>>,
}

impl RunRegistry {
    pub fn new() -> Self {
        Self::default()
    }

    /// Register a new run and return the sender half. Call this before spawning
    /// the producer task so subscribers racing the spawn never see a missing
    /// run_id.
    pub fn register(&self, run_id: impl Into<String>) -> broadcast::Sender<A2uiEvent> {
        let (tx, _rx) = broadcast::channel(RUN_CHANNEL_CAPACITY);
        self.runs.insert(run_id.into(), tx.clone());
        tx
    }

    /// Subscribe to an in-flight run's event stream. Returns `None` if the
    /// run_id is unknown (never registered, or already removed after
    /// completion).
    pub fn subscribe(&self, run_id: &str) -> Option<broadcast::Receiver<A2uiEvent>> {
        self.runs.get(run_id).map(|entry| entry.value().subscribe())
    }

    /// Remove a run's registration once it has reached a terminal state
    /// (`A2uiEvent::RunFinished` / `RunError`). Late subscribers after removal
    /// get `None` from `subscribe`, matching "the run already ended".
    pub fn remove(&self, run_id: &str) {
        self.runs.remove(run_id);
    }
}
