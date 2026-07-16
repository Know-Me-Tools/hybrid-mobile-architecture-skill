// TJ-ARCH-MOB-001 compliant
//! Feature-gated relational storage and ordered application startup.
//! Enable exactly one of `pg` or `sqlite`; add `pglite` for embedded desktop PG.

mod error;
mod seed;
mod startup;

#[cfg(feature = "pg")]
mod postgres;
#[cfg(feature = "sqlite")]
mod sqlite;

pub use error::{RelationalError, RelationalResult};
#[cfg(feature = "pglite")]
pub use postgres::PgliteStore;
#[cfg(feature = "pg")]
pub use postgres::PostgresStore;
pub use seed::{SeedBundle, SeedSource};
#[cfg(feature = "sqlite")]
pub use sqlite::SqliteStore;
pub use startup::{Migrated, Ready, Startup, Uninitialized};

#[cfg(all(feature = "pg", feature = "sqlite"))]
compile_error!("gen_ui_db relational dialect features are mutually exclusive");
