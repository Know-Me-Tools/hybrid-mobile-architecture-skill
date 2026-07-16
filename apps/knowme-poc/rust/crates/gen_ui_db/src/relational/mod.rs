// TJ-ARCH-MOB-001 compliant
//! Feature-gated relational storage and ordered application startup.
//! Postgres dialect only (`pg`; add `pglite` for embedded desktop PG via
//! pglite-oxide) — desktop and web. Mobile uses embedded SurrealDB instead
//! (gen_ui_db_graph), not this crate's relational store.

pub mod config;
mod error;
mod seed;
mod startup;

#[cfg(feature = "pg")]
mod postgres;

pub use config::{AppSetting, ConfigStore, ModelPref, Provider};
pub use error::{RelationalError, RelationalResult};
#[cfg(feature = "pglite")]
pub use postgres::PgliteStore;
#[cfg(feature = "pg")]
pub use postgres::PostgresStore;
pub use seed::{SeedBundle, SeedSource};
pub use startup::{Migrated, Ready, Startup, Uninitialized};
