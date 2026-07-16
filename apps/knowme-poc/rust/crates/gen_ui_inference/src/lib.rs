// TJ-ARCH-MOB-001 compliant
//! gen_ui_inference (L2) — local-inference engines behind the
//! `gen_ui_types::inference::InferenceProvider` trait. Per-lane engines
//! (see versions.toml [inference]): mistral.rs on desktop (Metal),
//! llama.cpp (`llama-cpp-2`) on mobile, WebLLM on web (host JS, bridged).
//!
//! Callers (gen_ui_agent, the platform leaves) depend on the trait only — never
//! on an engine crate — so adding or swapping a lane never ripples past here.

#[cfg(all(
    feature = "local-mistral",
    not(any(target_os = "ios", target_os = "android", target_arch = "wasm32"))
))]
pub mod mistral;

#[cfg(all(
    feature = "local-mistral",
    not(any(target_os = "ios", target_os = "android", target_arch = "wasm32"))
))]
pub use mistral::MistralEngine;
