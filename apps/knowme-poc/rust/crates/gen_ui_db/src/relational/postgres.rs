// TJ-ARCH-MOB-001 compliant
//! PostgreSQL store for cloud Postgres and pglite-oxide's local wire server.

// `Path` is only used by the pglite embedded-server constructor below; gating the
// import keeps a plain `pg` build (no `pglite`) warning-free under the clippy gate.
#[cfg(feature = "pglite")]
use std::path::Path;

use sqlx::{PgPool, postgres::PgPoolOptions};

use super::{RelationalResult, startup::StartupStore};

static MIGRATOR: sqlx::migrate::Migrator = sqlx::migrate!("./migrations/postgres");

#[derive(Clone)]
pub struct PostgresStore { pool: PgPool }

impl PostgresStore {
    pub async fn connect(url: &str) -> RelationalResult<Self> {
        let pool = PgPoolOptions::new().max_connections(5).connect(url).await?;
        Ok(Self { pool })
    }

    pub fn pool(&self) -> &PgPool { &self.pool }
}

#[async_trait::async_trait]
impl StartupStore for PostgresStore {
    async fn migrate(&self) -> RelationalResult<()> { MIGRATOR.run(&self.pool).await.map_err(Into::into) }
    async fn execute_seed(&self, sql: &str) -> RelationalResult<()> {
        sqlx::raw_sql(sql).execute(&self.pool).await?;
        Ok(())
    }
}

#[cfg(feature = "pglite")]
pub struct PgliteStore {
    store: PostgresStore,
    _server: pglite_oxide::PgliteServer,
}

#[cfg(feature = "pglite")]
impl PgliteStore {
    pub async fn open(path: impl AsRef<Path>) -> RelationalResult<Self> {
        let server = pglite_oxide::PgliteServer::builder().path(path.as_ref()).start()?;
        let url = server.database_url();
        let store = PostgresStore::connect(&url).await?;
        Ok(Self { store, _server: server })
    }

    pub fn store(&self) -> &PostgresStore { &self.store }
}
