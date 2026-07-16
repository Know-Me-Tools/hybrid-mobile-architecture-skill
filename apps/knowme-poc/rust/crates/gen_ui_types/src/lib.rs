// TJ-ARCH-MOB-001 compliant
//! gen_ui_types (L0) — pure types + ALL cross-crate trait seams.
//! NO tokio, NO IO. Compiles on every target including wasm32.
//!
//! FROZEN after C-001 review: changing a trait here requires cross-lane sign-off
//! because every downstream crate depends on these signatures.
#![forbid(unsafe_code)]

pub mod content_block;
pub mod events;
pub mod view;
pub mod transport;
pub mod sync;
pub mod config;
pub mod error;

pub use content_block::ContentBlock;
pub use error::{CoreError, CoreResult};
