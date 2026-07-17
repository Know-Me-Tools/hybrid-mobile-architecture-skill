---
type: Reference
id: prometheus-entity-sync-v4-transport-progress-and-pes-server-blocker
title: Prometheus entity sync v4 transport progress and PES server blocker
tags:
- prometheus-entity-sync
- prometheus-entity-management
- pglite
- sync-transport
- pes-server
- typescript-sdk
- dart-sdk
links:
- pglite-oxide-hybrid-tauri-architecture-for-mobile-postgresql
sources:
- stdin
- manual:prometheus-entity-management/phase-v4-prometheus-entity-sync
timestamp: 2026-07-17T02:43:40.767814+00:00
created_at: 2026-07-17T02:43:40.767814+00:00
updated_at: 2026-07-17T02:43:40.767814+00:00
revision: 0
---

## Context

- **Project:** `prometheus-entity-management`
- **Phase:** `phase-v4-prometheus-entity-sync`
- **KBD root:** `$HOME/Projects/prometheus/prometheus-entity-management`
- **Captured:** `2026-07-17T02:39:59Z`
- **Position/source phase:** `manual:prometheus-entity-management/phase-v4-prometheus-entity-sync`

## Phase goal

Build `prometheus-entity-sync`: a **Rust-native, MIT-licensed, bidirectional sync engine** connecting:

- Postgres
- PGlite in browser
- SQLite on mobile/desktop
- `pglite-oxide` in Tauri desktop, consistent with the local embedded PostgreSQL direction described in [pglite-oxide Hybrid Tauri Architecture for Mobile PostgreSQL](/pglite-oxide-hybrid-tauri-architecture-for-mobile-postgresql.md)

The intended feature level is comparable to PowerSync, but without license restrictions and with Rust, Dart, and TypeScript SDK surfaces.

## Planned work

### P0 — Sync server core

- `pes-core` crate:
  - `SyncRule` types
  - `BucketOp`
  - LSN cursors
  - entity change model
- `pes-rules` crate:
  - TOML sync rules DSL parser
  - `BucketAssigner`
  - per-user bucket membership evaluation from JWT claims plus lookup queries against Postgres
- `pes-oplog` crate:
  - per-bucket ordered op log
  - checksum support
  - backed by `frf-store-redb`
- `pes-snapshot` crate:
  - chunked initial sync from Postgres
  - target batch size: **10,000 rows/batch**
  - uses `frf-postgres-cdc`
- `pes-protocol` crate:
  - `PSyncV1` wire protocol
  - WebSocket transport
  - MessagePack binary framing
- `pes-gateway` crate:
  - WebSocket server using `tokio-tungstenite`
  - extends `frf-gateway`
- `pes-server` binary:
  - config file
  - health endpoint
  - Prometheus-format metrics
  - Docker image
- Integrate with `frf-postgres-cdc` for WAL streaming; do **not** reimplement WAL streaming.
- Integrate with `frf-crdt` / Loro for CRDT write path and conflict resolution.

### P1 — TypeScript client SDK and PEM integration

- `@prometheus-ags/entity-sync-core`:
  - protocol client
  - reconnect with exponential backoff
  - JWT refresh
  - LSN tracking
- `@prometheus-ags/entity-sync-pglite`:
  - PGlite extension
  - `syncBucket()` applies delta ops to local PGlite
- `@prometheus-ags/entity-sync-react`:
  - `useEntitySync()`
  - `useSyncStatus()`
- PEM transport registry integration:
  - `registerEntityTransport`
  - `prometheusSync(config)` transport factory
- PEM Vite example app must demonstrate bidirectional sync of the `entities` table.

### P2 — Dart / Flutter SDK

- `prometheus_entity_sync` Dart package
- Pure Dart WebSocket client; no FFI
- SQLite backend via `drift`

## Session outcome

`v4-pem-sync-transport` reached **9 of 11 tasks complete**.

Implemented `prometheusSyncTransport`, an `EntityTransport<T>` bridge from `prometheus-entity-sync` into PEM's transport registry.

### Transport behavior

- `list()` reads entities from PGlite.
- `get()` reads a single entity from PGlite.
- `subscribe()` streams `Delta` operations as `ChangeEvent`s.
- `subscribe()` includes a post-merge PGlite readback for `CrdtPatch` operations that would otherwise be silently dropped by the engine subscribe handler.
- `write()` sends `ClientMessage::Write`, enabling `useEntityMutation` wiring.
- Added a lightweight Zustand-shaped status store.

### Example integration

- Wired demonstration registration into both example apps in `prometheus-entity-management`.
- Fixed a real `WebSocket.send()` type error surfaced during integration.

### Commits

- Sync repository: `8f8c057`
- PEM repository: `50bc24a`

## Decisions and judgment calls

- Chose the proposal's `EntityTransport<T>` design instead of the architecturally closer `SyncProvider` interface already built for realtime CRDT sync.
- Confirmed the proposal's example-wiring paths no longer exist after `v3.0.0-restructure`; implemented new files matching current project conventions instead.

## Blocker

Tasks 9–10 remain deferred because two-tab integration tests require a running `pes-gateway` server, while `pes-server` is still a stub.

The same blocker now affects three changes:

1. `v4-entity-sync-ts-sdk`
2. `v4-pem-sync-transport`
3. `v4-dart-sdk` entirely

## Recommended next change

Prioritize `v4-pes-server-binary` next to unblock integration testing and avoid accumulating further deferred work.

# Citations

1. stdin
2. manual:prometheus-entity-management/phase-v4-prometheus-entity-sync
