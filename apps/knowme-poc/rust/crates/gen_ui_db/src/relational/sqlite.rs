// TJ-ARCH-MOB-001 compliant
//! Mobile SQLite store. sqlite-vec is registered before any SQLx connection opens.

use std::{path::Path, str::FromStr, sync::Once};

use sqlx::{SqlitePool, sqlite::{SqliteConnectOptions, SqlitePoolOptions}};

use super::{RelationalResult, startup::StartupStore};

static MIGRATOR: sqlx::migrate::Migrator = sqlx::migrate!("./migrations/sqlite");
static REGISTER_VEC: Once = Once::new();

#[derive(Clone)]
pub struct SqliteStore { pool: SqlitePool }

impl SqliteStore {
    pub async fn open(path: impl AsRef<Path>) -> RelationalResult<Self> {
        REGISTER_VEC.call_once(|| {
            // SAFETY: sqlite-vec exposes SQLite's documented extension entry point.
            // Register it once, before SQLx opens any connection; both crates link
            // the same libsqlite3-sys version through Cargo feature unification.
            unsafe {
                libsqlite3_sys::sqlite3_auto_extension(Some(std::mem::transmute::<
                    *const (),
                    unsafe extern "C" fn(
                        *mut libsqlite3_sys::sqlite3,
                        *mut *mut std::ffi::c_char,
                        *const libsqlite3_sys::sqlite3_api_routines,
                    ) -> std::ffi::c_int,
                >(
                    sqlite_vec::sqlite3_vec_init as *const (),
                )));
            }
        });
        let options = SqliteConnectOptions::from_str(&format!("sqlite://{}", path.as_ref().display()))?
            .create_if_missing(true)
            .foreign_keys(true);
        let pool = SqlitePoolOptions::new().max_connections(1).connect_with(options).await?;
        Ok(Self { pool })
    }

    pub fn pool(&self) -> &SqlitePool { &self.pool }
}

#[async_trait::async_trait]
impl StartupStore for SqliteStore {
    async fn migrate(&self) -> RelationalResult<()> { MIGRATOR.run(&self.pool).await.map_err(Into::into) }
    async fn execute_seed(&self, sql: &str) -> RelationalResult<()> {
        sqlx::raw_sql(sql).execute(&self.pool).await?;
        Ok(())
    }
}
