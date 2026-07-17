---
type: Reference
id: pes-v4-server-binary-completion-and-sync-engine-scope
title: PES v4 server binary completion and sync engine scope
tags:
- prometheus-entity-sync
- pes-server
- rust
- postgres-cdc
- pglite
- docker
- sync-engine
links:
- pglite-oxide-hybrid-tauri-architecture-for-mobile-postgresql
- hybrid-scaffold-analysis-integrates-pem-and-pes-sync-findings
sources:
- stdin
- manual:prometheus-entity-management/phase-v4-prometheus-entity-sync
timestamp: 2026-07-17T04:31:36.709622+00:00
created_at: 2026-07-17T04:31:36.709622+00:00
updated_at: 2026-07-17T04:31:36.709622+00:00
revision: 0
---

## Context

- **Project:** `prometheus-entity-management`
- **Phase:** `phase-v4-prometheus-entity-sync`
- **KBD root:** `$HOME/Projects/prometheus/prometheus-entity-management`
- **Captured:** `2026-07-17T04:20:37Z`
- **Status:** `v4-pes-server-binary` complete; 13/13 tasks done

## Phase objective

Build `prometheus-entity-sync`: a Rust-native, MIT-licensed, bidirectional sync engine connecting Postgres to:

- PGlite in browsers
- SQLite on mobile/desktop
- `pglite-oxide` in Tauri desktop; see [pglite-oxide Hybrid Tauri Architecture for Mobile PostgreSQL](/pglite-oxide-hybrid-tauri-architecture-for-mobile-postgresql.md)

The target feature set is comparable to PowerSync, but without license restrictions, and with Rust, Dart, and TypeScript SDK surfaces. This work is part of the broader PEM/PES sync direction captured in [Hybrid scaffold analysis integrates PEM and PES sync findings](/hybrid-scaffold-analysis-integrates-pem-and-pes-sync-findings.md).

## Planned architecture

### P0 — Sync server core

- `pes-core` crate:
  - `SyncRule` types
  - `BucketOp`
  - LSN cursors
  - entity change model
- `pes-rules` crate:
  - TOML sync-rules DSL parser
  - `BucketAssigner` for per-user bucket membership evaluation from JWT claims and Postgres lookup queries
- `pes-oplog` crate:
  - per-bucket ordered op log
  - checksum support
  - `frf-store-redb` backing store
- `pes-snapshot` crate:
  - chunked initial sync from Postgres
  - 10,000 rows per batch
  - uses `frf-postgres-cdc`
- `pes-protocol` crate:
  - `PSyncV1` wire protocol
  - WebSocket transport
  - MessagePack binary framing
- `pes-gateway` crate:
  - WebSocket server using `tokio-tungstenite`
  - extends `frf-gateway`
- `pes-server` binary:
  - config file support
  - health endpoint
  - Prometheus-format metrics
  - Docker image
- Integration boundaries:
  - `frf-postgres-cdc` supplies WAL streaming; no WAL reimplementation in PES
  - `frf-crdt`/Loro supplies CRDT write path and conflict resolution

### P1 — TypeScript client SDK and PEM integration

- `@prometheus-ags/entity-sync-core`:
  - protocol client
  - exponential-backoff reconnect
  - JWT refresh
  - LSN tracking
- `@prometheus-ags/entity-sync-pglite`:
  - PGlite extension
  - `syncBucket()` applies delta ops to local PGlite
- `@prometheus-ags/entity-sync-react`:
  - `useEntitySync()`
  - `useSyncStatus()`
- PEM transport integration:
  - `registerEntityTransport`
  - `prometheusSync(config)` transport factory
- Validation target:
  - PEM Vite example app
  - bidirectional sync of the `entities` table

### P2 — Dart / Flutter SDK

- `prometheus_entity_sync` Dart package:
  - pure Dart WebSocket client
  - no FFI requirement
- SQLite backend through `drift`

## Completed server-binary work

`v4-pes-server-binary` completed all 13 planned tasks without deferrals.

### Gateway API changes

`pes-gateway` was extended with production graceful-shutdown support:

- `CancellationToken` integration
- `connection_count()` API

This closed a design gap: the proposal implied graceful shutdown behavior but did not specify the gateway API required to implement it.

### Server binary implementation

The `pes-server` binary now includes:

- configuration loading
- `${VAR}` environment interpolation in config values
- health endpoint
- readiness endpoint
- Prometheus-format metrics endpoint
- WAL pipeline wiring
- SIGTERM handling
- Docker image packaging

### Broker decision

The implementation uses an in-process `LogBroker` instead of the Iggy-dependent broker. Rationale: the proposal's `docker-compose` scope did not provision Iggy, so requiring it would make the composed stack incomplete.

## Docker and runtime fixes found by live verification

Live Docker build and runtime testing found and fixed three concrete issues:

1. **MSRV/image mismatch**
   - Original base image: `rust:1.87-slim`
   - Fixed base image: `rust:1.94-slim`
2. **`.dockerignore` gap**
   - Build context attempted to copy approximately 27 GB of build artifacts into the image.
   - Fixed by excluding generated/build artifacts from the Docker context.
3. **Missing `libpq` runtime dependency**
   - Distroless runtime crashed due to absent `libpq`.
   - Runtime image changed to `debian:bookworm-slim`.

Final image size: **36.76 MB**, below the 100 MB budget.

## Verification results

The real `docker-compose` stack was brought up and verified live:

- `/health` works
- `/ready` works
- `/metrics` works
- SIGTERM graceful shutdown works against the running container
  - observed clean shutdown in approximately 1 second
  - logs showed full drain sequence

Test status:

- **31 tests passing** across `pes-gateway` and `pes-server`

## Pending follow-up

A security review was running after implementation, covering:

- config secret handling
- `/metrics` information leakage
- non-root container user behavior
- shutdown denial-of-service surface

Completion of that review is expected to unblock two previously deferred integration-test tasks.

# Citations

1. stdin
2. manual:prometheus-entity-management/phase-v4-prometheus-entity-sync
