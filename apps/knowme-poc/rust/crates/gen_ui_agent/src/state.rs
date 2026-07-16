// TJ-ARCH-MOB-001 compliant
//! Process-lifetime agent state: the config backend (platform-selected) and the
//! A2uiEvent broadcast channel every chat run publishes to. One instance per
//! process — callers `init()` once at startup (after migrations), then `send()`
//! and `subscribe()` freely.
use gen_ui_types::events::A2uiEvent;
use once_cell::sync::OnceCell;
use tokio::sync::broadcast;

use crate::config::ConfigBackend;
use crate::error::AgentError;

/// Ring-buffer depth for the A2uiEvent channel. Chat turns are short-lived and
/// consumed live; a slow/absent subscriber only misses backlog, never blocks
/// the sender (broadcast::Sender::send never awaits).
const EVENT_CHANNEL_CAPACITY: usize = 256;

pub struct AgentState {
    pub config: ConfigBackend,
    events: broadcast::Sender<A2uiEvent>,
}

static STATE: OnceCell<AgentState> = OnceCell::new();

/// Initialise process-lifetime agent state with the platform's config backend.
/// Call once at startup, after the config DB's own migrations have run.
/// Calling twice is a programming error (typestate would be nicer, but both
/// callers — the Tauri plugin's `setup` and the FFI's `run_migrations` — are
/// naturally single-shot per process already). A second call is a no-op: the
/// first-set state (and its broadcast channel, which may already have live
/// subscribers) keeps running rather than being silently replaced — but it is
/// now logged loudly, since silently swallowing it previously masked exactly
/// this kind of programming error during development.
pub fn init(config: ConfigBackend) {
    let (tx, _rx) = broadcast::channel(EVENT_CHANNEL_CAPACITY);
    if STATE.set(AgentState { config, events: tx }).is_err() {
        tracing::warn!(
            "gen_ui_agent::state::init called more than once in this process; \
             ignoring the second call and keeping the original config backend \
             and event broadcast channel"
        );
    }
}

pub(crate) fn get() -> Result<&'static AgentState, AgentError> {
    STATE.get().ok_or(AgentError::NotInitialised)
}

/// Subscribe to the live A2uiEvent feed. Each platform leaf (frb StreamSink,
/// Tauri emit) owns forwarding these into its own transport.
pub fn subscribe() -> Result<broadcast::Receiver<A2uiEvent>, AgentError> {
    Ok(get()?.events.subscribe())
}

pub(crate) fn publish(event: A2uiEvent) {
    if let Ok(state) = get() {
        // No subscribers is not an error — a run started before any UI attached
        // (or with devtools closed) still completes; it just has no listener.
        let _ = state.events.send(event);
    }
}

pub(crate) fn config() -> Result<&'static ConfigBackend, AgentError> {
    Ok(&get()?.config)
}
