// TJ-ARCH-MOB-001 compliant
//! Local-first sync engine (C-005).
//!
//! Native path (desktop/mobile): a Rust Electric **shape consumer** long-polls the
//! Electric HTTP API and writes rows into a [`LocalStore`]; a DIY **write queue**
//! replays local mutations through a [`WriteSink`] (forge Quarry API) with idempotent
//! keys, exponential backoff, and a poison handler. A [`SyncStatus`] broadcast drives
//! the UI sync chip.
//!
//! Web path: the browser uses `@electric-sql/pglite-sync` (JS side) — see
//! `sync/README.md`. This module compiles to a documented no-op on `wasm32` so the
//! workspace still builds for the browser leaf.
//!
//! Everything sits behind the frozen [`gen_ui_types::sync::SyncTransport`] seam, so
//! PES (PSyncV1) can replace the engine later without touching callers.

mod status;

#[cfg(not(target_arch = "wasm32"))]
mod config;
#[cfg(not(target_arch = "wasm32"))]
mod seam;
#[cfg(not(target_arch = "wasm32"))]
mod shapes;
#[cfg(not(target_arch = "wasm32"))]
mod write_queue;
#[cfg(not(target_arch = "wasm32"))]
mod engine;
#[cfg(not(target_arch = "wasm32"))]
mod frf_transport;
// Needs sqlx::PgPool → `pg`. Desktop/web only; mobile's local store is SurrealDB
// (gen_ui_db_graph), matching how `relational` is gated.
#[cfg(all(not(target_arch = "wasm32"), feature = "pg"))]
mod local_store;

pub use status::{SyncStatusHandle, SyncStatusStream};
// Re-export the frozen seam types so callers use one import path.
pub use gen_ui_types::sync::{SyncStatus, SyncTransport};

#[cfg(not(target_arch = "wasm32"))]
pub use config::{ShapeSpec, SyncConfig};
#[cfg(not(target_arch = "wasm32"))]
pub use engine::SyncEngine;
// C-106: the FRF-backed transport (the substrate the PoC actually runs) + the concrete
// read-path store. `SyncEngine` above stays for the Electric lane until it is removed.
#[cfg(not(target_arch = "wasm32"))]
pub use frf_transport::{row_change_from_payload, FrfSyncConfig, FrfSyncTransport};
#[cfg(all(not(target_arch = "wasm32"), feature = "pg"))]
pub use local_store::PgLocalStore;
#[cfg(not(target_arch = "wasm32"))]
pub use seam::{LocalStore, PendingWrite, RowChange, RowOp, WriteOutcome, WriteSink};

/// wasm32 stub. The browser sync path is `pglite-sync` (JS); no Rust engine runs
/// in-browser. Kept so `cargo check --target wasm32-unknown-unknown -p gen_ui_wasm`
/// stays green and callers get a clear compile error if they try to build the
/// native engine for the web.
#[cfg(target_arch = "wasm32")]
pub mod web_note {
    //! Browser sync is configured JS-side via `@electric-sql/pglite-sync`.
    //! See `crates/gen_ui_db/src/sync/README.md`.
}
