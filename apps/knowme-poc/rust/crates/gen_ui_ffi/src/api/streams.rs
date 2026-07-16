// TJ-ARCH-MOB-001 compliant
//! Rust->Dart event streams via frb `StreamSink<T>`. Dart consumes each as a
//! broadcast `Stream` behind a Riverpod `@riverpod` stream provider (remember:
//! FFI providers must opt out of Riverpod 3 auto-retry).
//!
//! Three feeds map to the three UI chrome elements:
//!   * A2uiEvent   -> chat transcript (ContentBlock folding)
//!   * ChangeEvent -> entity cache invalidation (ref.invalidate bridge)
//!   * SyncStatus  -> the sync status chip
//!
//! C-007 lands the sink plumbing; Wave-1 lanes push real events into these sinks
//! from the agent loop (C-006) and sync engine (C-005). Until then the streams
//! open and stay idle.
//!
//! `StreamSink<T>` is the per-crate type emitted by codegen into
//! `frb_generated.rs` and brought into crate-root scope; this module compiles
//! only with the `frb-streams` feature (enabled after codegen runs). The bare
//! unqualified `StreamSink` name is the idiomatic frb 2.x form (see the frb
//! README's streaming example).
//!
//! `chat_events` streams `A2uiEvent` as a JSON `String` rather than a native
//! frb type. `A2uiEvent`/`ContentBlock` are enums with data-carrying variants,
//! which frb's codegen classifies as needing `freezed` on the Dart side — and
//! this project's `riverpod_generator` (already pinned) and stable `freezed`
//! have disjoint `analyzer` version requirements (no published version of
//! either resolves against the other; freezed's own prerelease line that
//! *would* resolve is itself rejected by flutter_rust_bridge_codegen 2.12.0's
//! own `>=1.0.0` semver gate, which excludes prereleases). JSON-over-the-wire
//! sidesteps frb's type-mirroring path entirely and matches the hand-written
//! `A2uiEvent.fromWire` parser already built in `mobile/lib/bridge/a2ui/
//! a2ui_event.dart` in anticipation of exactly this shape (T8 finding,
//! 2026-07-16 — see the dependency-conflict note in decision-log.md).
use crate::frb_generated::StreamSink;
// `pub use` (not `use`) — frb_generated.rs glob-imports `crate::api::streams::*`
// and references these by bare name in its opaque-refcounting boilerplate; a
// plain (non-`pub`) `use` does not re-export them.
pub use gen_ui_types::sync::SyncStatus;
pub use gen_ui_types::transport::ChangeEvent;

/// Subscribe to the A2UI event stream for a chat run. The core produces
/// ContentBlock-bearing events, serialized to JSON (see module doc for why);
/// the transport layer (`@flint/react`, flint_genui) is bypassed by contract.
///
/// Subscribes to gen_ui_agent's per-run broadcast channel (registered by
/// `chat::chat_send` before it returns the run_id) and forwards every event,
/// JSON-encoded, into the frb `StreamSink` until the run's producer task
/// closes the channel (terminal `RunFinished`/`RunError`, after which
/// `RunRegistry::remove` drops the sender). If `run_id` is unknown (never
/// started, or already finished before this subscription attached), the sink
/// is dropped immediately — there is nothing to stream. A serialization
/// failure (should be unreachable — `A2uiEvent` is `Serialize`-derived with
/// no non-serializable fields) is logged and the event is skipped rather than
/// panicking the forwarder task.
pub fn chat_events(run_id: String, sink: StreamSink<String>) {
    let Some(mut rx) = gen_ui_agent::global_chat_agent().registry().subscribe(&run_id) else {
        return;
    };
    gen_ui_runtime::spawn(async move {
        loop {
            match rx.recv().await {
                Ok(event) => {
                    let json = match serde_json::to_string(&event) {
                        Ok(json) => json,
                        Err(err) => {
                            log::error!("chat_events: failed to serialize A2uiEvent: {err}");
                            continue;
                        }
                    };
                    if sink.add(json).is_err() {
                        // Dart side unsubscribed; stop forwarding.
                        break;
                    }
                }
                Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => {
                    // Subscriber fell behind the producer; skip ahead and keep
                    // streaming rather than terminating the whole run.
                    continue;
                }
                Err(tokio::sync::broadcast::error::RecvError::Closed) => break,
            }
        }
    });
}

/// Subscribe to entity change events. One Dart listener fans these into
/// `ref.invalidate` calls per the PEM-Flutter cascade-invalidation design.
pub fn entity_changes(sink: StreamSink<ChangeEvent>) {
    // Wave-1 (C-003) forwards EntityTransport change notifications here.
    let _ = sink;
}

/// Subscribe to the sync status feed that drives the UI sync chip.
pub fn sync_status(sink: StreamSink<SyncStatus>) {
    // Wave-1 (C-005) forwards SyncTransport status transitions here.
    let _ = sink;
}
