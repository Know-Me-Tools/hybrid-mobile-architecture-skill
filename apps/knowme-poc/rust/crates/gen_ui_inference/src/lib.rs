// TJ-ARCH-MOB-001 compliant
//! gen_ui_inference (L2) — local-inference engines behind the
//! `gen_ui_types::inference::InferenceProvider` trait. Per-lane engines
//! (see versions.toml [inference]): mistral.rs on desktop (Metal),
//! llama.cpp (`llama-cpp-2`) on mobile, WebLLM on web (host JS, bridged).
//! IMPLEMENTATION OWNER: future inference lane (see plan.md). This is the C-001 seam stub.
