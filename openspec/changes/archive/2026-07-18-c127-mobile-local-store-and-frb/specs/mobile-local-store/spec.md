## ADDED Requirements

### Requirement: Mobile SurrealDB LocalStore
Mobile SHALL implement the frozen `gen_ui_db::sync::LocalStore` seam over the
SAME embedded SurrealDB connection its config/memory backend already opens
(`SurrealLocalStore`), in a module distinct from the crate's intent-level
memory/graph API, resolving the tracked C-106 T5 gap. It SHALL NOT introduce
a second embedded database for sync.

#### Scenario: Batch apply persists and refuses unknown tables
- **WHEN** a row-change batch targets a declared table
- **THEN** the rows persist retrievably; a batch targeting an undeclared table
  fails rather than silently applying (fail closed, mirroring PgLocalStore)

#### Scenario: Truncate is scoped per table
- **WHEN** one table's shape is truncated for re-materialization
- **THEN** rows belonging to other tables are unaffected

### Requirement: Mobile boot-order sync attach and one-time loads
`gen_ui_ffi::api::boot` SHALL expose `attach_sync_scopes` (declaring
partial-replication scopes over a `LoopbackSyncTransport` wrapping the
SurrealDB `LocalStore`) and `run_one_time_loads` (wrapping
`gen_ui_db::relational::run_one_time_loads`), both callable after
`run_migrations`. Desktop SHALL gain equivalent Tauri parity commands
(`attach_sync_scopes`, `run_one_time_loads`) alongside the existing
`attach_sync_shapes`, which becomes a scope-less compatibility wrapper.

#### Scenario: Scopes attach after migrations
- **WHEN** `attach_sync_scopes` is called after `run_migrations` on mobile
- **THEN** the loopback transport starts with the declared scopes validated
  (fail-closed on a tenantless user-subset scope, per LFS-INV-7)

#### Scenario: Desktop parity preserves prior behavior
- **WHEN** the legacy `attach_sync_shapes` Tauri command is invoked
- **THEN** it behaves identically to `attach_sync_scopes` with an empty scope
  list (no behavior change for existing callers)
