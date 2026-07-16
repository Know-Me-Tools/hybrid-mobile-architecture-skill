// TJ-ARCH-MOB-001 compliant
//! frb codegen root. Intent-level functions only (no raw SurrealQL / SQL across
//! the bridge). init + submodules for streams and CRUD.
//!
//! `streams` is gated behind the `frb-streams` feature: its `StreamSink<T>`
//! signatures reference the per-crate `StreamSink` type that
//! `flutter_rust_bridge_codegen generate` emits into `frb_generated.rs`. Enable
//! the feature after running codegen (the project build does this). The scaffold's
//! pre-codegen `cargo check` gate leaves it off so the workspace checks clean.
#[cfg(feature = "frb-streams")]
pub mod streams;
pub mod entity;
pub mod chat;

use flutter_rust_bridge::frb;

/// Initialise the shared core (global Tokio runtime + platform loggers).
/// Called once from Dart at app start. `#[frb(init)]` also wires frb's own
/// default utilities.
#[frb(init)]
pub fn init_core(worker_threads: Option<usize>) {
    #[cfg(target_os = "android")]
    let _ = android_logger::init_once(
        android_logger::Config::default().with_max_level(log::LevelFilter::Info),
    );
    #[cfg(not(target_arch = "wasm32"))]
    gen_ui_runtime::init(worker_threads);
    let _ = worker_threads;
}
