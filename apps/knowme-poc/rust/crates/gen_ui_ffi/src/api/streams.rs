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
use crate::frb_generated::StreamSink;
use gen_ui_types::events::A2uiEvent;
use gen_ui_types::sync::SyncStatus;
use gen_ui_types::transport::ChangeEvent;

/// Subscribe to the A2UI event stream for a chat run. The core produces
/// ContentBlock-bearing events; the transport layer (`@flint/react`, flint_genui)
/// is bypassed by contract.
pub fn chat_events(run_id: String, sink: StreamSink<A2uiEvent>) {
    // Wave-1 (C-006) registers `sink` with the ProtocolPipeline broadcast for this
    // run. C-007 proves the type crosses the bridge.
    let _ = (run_id, sink);
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
