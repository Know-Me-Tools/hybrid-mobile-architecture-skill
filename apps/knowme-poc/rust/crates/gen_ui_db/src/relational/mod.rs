// TJ-ARCH-MOB-001 compliant
//! Feature-gated relational storage and ordered application startup.
//! Postgres (`pg`; add `pglite` for embedded desktop PG via pglite-oxide) backs
//! desktop/hosted data. SQLite backs mobile entity envelopes while SurrealDB
//! remains the mobile memory/graph-RAG store.

pub mod config;
mod error;
mod loads;
mod lookup;
mod seed;
#[cfg(feature = "sqlite")]
mod sqlite_entity;
mod startup;

#[cfg(feature = "pg")]
mod postgres;

pub use config::{AppSetting, ConfigStore, ModelPref, Provider};
pub use error::{RelationalError, RelationalResult};
pub use loads::{run_one_time_loads, LoadResult, LoadStage, OneTimeLoad, LOAD_LEDGER_DDL};
pub use lookup::{
    bump_needs_refetch, revalidate_lookup, LookupLedger, LookupOutcome, LookupVersion,
    MemoryLookupLedger, LOOKUP_VERSIONS_DDL,
};
#[cfg(feature = "pglite")]
pub use postgres::PgliteStore;
#[cfg(feature = "pg")]
pub use postgres::PostgresStore;
pub use seed::{SeedBundle, SeedSource};
#[cfg(feature = "sqlite")]
pub use sqlite_entity::SqliteEntityStore;
pub use startup::{Migrated, PreOnboarded, Ready, Seeded, Startup, StartupStore, Uninitialized};
