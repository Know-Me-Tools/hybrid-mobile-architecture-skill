// TJ-ARCH-MOB-001 compliant
//! Mobile local inference behind the shared `InferenceProvider` seam.
//! Web uses WebLLM and desktop may add its selected native engine without
//! changing callers; Flutter opts into `local-llama`.

#[cfg(feature = "local-llama")]
pub mod llama;

#[cfg(feature = "local-llama")]
pub use llama::LlamaCppEngine;
