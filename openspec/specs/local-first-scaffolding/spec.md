# local-first-scaffolding Specification

## Purpose
TBD - created by archiving change c125-scaffold-audit-propagation. Update Purpose after archive.
## Requirements
### Requirement: Scaffolds generate the local-first surface
`scaffold-tauri.sh` SHALL generate the vault feature (Loro doc store, chunked-frame
duplex protocol, WebRTC + in-memory duplexes), pgvector wiring (extension at
PGlite.create, vector tables + HNSW in schema.sql, `@electric-sql/pglite-pgvector`
dependency), and SHALL NOT install `@electric-sql/pglite-sync` by default (Electric
is the recorded fallback, not the lane — ADR-LFS-1). `scaffold-flutter.sh` SHALL
emit the mobile-tier bridge surface (attachSyncScopes, runOneTimeLoads, SQLite +
sqlite-vec notes). `scaffold-rust-core.sh` emissions SHALL stay byte-identical to
the reference-app sources for the shared sync/relational modules.

#### Scenario: Generated heredocs match the reference app
- **WHEN** the propagated heredocs are replayed into a temp directory
- **THEN** the produced files are byte-identical to the apps/knowme-poc sources

### Requirement: Audit gates for local-first hygiene
`audit.sh tauri` SHALL warn on sync-related dependencies (loro-crdt, pglite-sync,
pglite-pgvector) that are declared but never imported, SHALL fail when vault
tables are wired into the entity/sync layer, and SHALL warn when a chat feature
lacks its pgvector surface. versions.toml SHALL carry the `[sync]` pin block.

#### Scenario: Dead sync dependency flagged
- **WHEN** a scaffolded project declares loro-crdt without importing it
- **THEN** the audit reports a WARNING naming the dependency

#### Scenario: Vault leaking into the sync layer is a failure
- **WHEN** `_vault_state` (or a vault transport) appears in the entities feature
- **THEN** the audit fails with a local-class violation

