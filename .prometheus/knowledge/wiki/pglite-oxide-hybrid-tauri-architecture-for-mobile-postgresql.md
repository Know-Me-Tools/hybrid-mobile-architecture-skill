---
type: Reference
id: pglite-oxide-hybrid-tauri-architecture-for-mobile-postgresql
title: pglite-oxide Hybrid Tauri Architecture for Mobile PostgreSQL
tags:
- pglite-oxide
- tauri
- mobile-postgresql
- rust
- database-abstraction
- electric-pglite
- supabase
sources:
- stdin
- docs/pglite-oxide-tauri-hybrid.md
timestamp: 2026-07-13T16:38:38.311549+00:00
created_at: 2026-07-13T16:38:38.311549+00:00
updated_at: 2026-07-13T16:38:38.311549+00:00
revision: 0
---

## Summary

A new document was created at `docs/pglite-oxide-tauri-hybrid.md` describing a hybrid mobile PostgreSQL architecture for Tauri applications using `pglite-oxide` on native platforms and alternate backends elsewhere.

## Covered Areas

### Platform Support

- Defines iOS and Android execution paths through Tauri.
- Documents platform-specific storage locations for embedded database files.
- Covers native mobile usage rather than attempting to run browser-oriented PGlite inside Rust-side Tauri code.

### Architecture

The document includes diagrams for both primary mobile stacks:

- **iOS:** SwiftUI → Tauri → `pglite-oxide` → PostgreSQL
- **Android:** Android UI/JNI → Tauri → `pglite-oxide` → PostgreSQL

The architecture positions `pglite-oxide` as the native embedded PostgreSQL layer used from the Rust side of a Tauri application.

### Performance

- Includes a benchmark table based on README data.
- Captures expected overhead of approximately **10–20% versus native PostgreSQL**.
- Frames the overhead as acceptable for the target workload given the benefit of embedded PostgreSQL semantics.

### Bundled Extensions

The extension inventory documented as bundled with the stack includes:

- `pgvector`
- `pg_trgm`
- `citext`
- `hstore`
- `ltree`

These extensions are part of the rationale for preferring PostgreSQL-compatible storage over SQLite for the workload.

## Unified Abstraction Design

The document proposes a `prometheus-db` crate abstraction that routes multiple database implementations behind one trait surface:

| Runtime target | Backend |
|---|---|
| Browser | Electric PGlite |
| Native Tauri/mobile | `pglite-oxide` |
| Cloud | Supabase |

The intent is to expose a common application-facing API while selecting the appropriate persistence implementation per deployment target.

## Decision Rationale

### Why `pglite-oxide` over SQLite

`pglite-oxide` is preferred for this workload because it provides embedded PostgreSQL behavior and access to PostgreSQL extensions such as vector search, trigram search, case-insensitive text, key-value structures, and tree paths. This better matches workloads that depend on PostgreSQL semantics and extension compatibility.

### Why Electric PGlite is not the Rust-side Tauri backend

Electric PGlite is treated as the browser-oriented option. The document identifies it as the wrong choice for the Rust side of Tauri, where `pglite-oxide` is the native embedded backend.

## Next Step

Start the next build phase with:

```bash
/kbd-new-phase <next-phase-name>
```

# Citations

1. [1] stdin
2. [2] docs/pglite-oxide-tauri-hybrid.md
