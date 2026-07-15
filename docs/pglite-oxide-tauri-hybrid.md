# pglite-oxide in Tauri Hybrid Mobile Applications

## Overview

This document captures architectural notes on using **pglite-oxide** as the embedded relational database layer in Tauri-based hybrid mobile applications — specifically in the context of a "run anywhere" platform like Prometheus UAR.

**pglite-oxide** is a Rust crate that packages a real PostgreSQL runtime (not an emulator, not WebAssembly) for use inside native applications. It is entirely distinct from ElectricSQL's PGlite, which is PostgreSQL compiled to WASM for browsers.

- pglite-oxide repo: <https://github.com/f0rr0/pglite-oxide>
- ElectricSQL PGlite repo: <https://github.com/electric-sql/pglite>

---

## Platform Comparison

| Project | Runtime | Target Environments |
|---|---|---|
| pglite-oxide | Real PostgreSQL binary, Rust-native | macOS, Windows, Linux, iOS, Android (via Tauri) |
| Electric PGlite | PostgreSQL compiled to WASM | Browsers, Node.js, Bun, Deno, Tauri frontend |
| PostgreSQL / Supabase | Full server | Cloud, self-hosted servers |

---

## Mobile Platform Support

### iOS

Supported via Tauri + Swift Package Manager. PostgreSQL binaries run inside the application sandbox. The database is stored under:

```
<app>/Documents/
<app>/Application Support/
```

Apple's sandbox model allows this. The `Package.swift` included in pglite-oxide confirms Swift Package Manager integration.

### Android

Supported via Tauri's Rust JNI layer. PostgreSQL binaries are bundled with the application. Storage lives at:

```
/data/data/<package>/files/
/data/data/<package>/databases/
```

---

## Architecture Layers

### iOS / macOS

```
SwiftUI
   │
   ▼
Tauri / Rust
   │
   ▼
pglite-oxide
   │
   ▼
Embedded PostgreSQL 17.5
```

### Android

```
Jetpack Compose
      │
      ▼
Rust JNI Layer (Tauri)
      │
      ▼
pglite-oxide
      │
      ▼
Embedded PostgreSQL
```

---

## Performance Characteristics

From the pglite-oxide README benchmarks — performance is close to native PostgreSQL:

| Operation | Native PostgreSQL | pglite-oxide |
|---|---|---|
| INSERT | 132 ms | 149 ms |
| Bulk INSERT | 46 ms | 59 ms |
| Indexed SELECT | 81 ms | 125 ms |

This overhead is acceptable for local-first mobile workloads.

---

## Bundled Extensions

pglite-oxide bundles PostgreSQL extensions that most embedded databases cannot offer:

- `pgvector` — vector similarity search
- `pg_trgm` — trigram-based full-text search
- `citext` — case-insensitive text
- `hstore` — key-value store
- `ltree` — hierarchical label trees

This means a mobile application gets vector search, JSONB, full-text search, PostgreSQL indexing, triggers, and views with no server dependency.

---

## Compatibility

pglite-oxide exposes a standard PostgreSQL connection string, making it compatible with any Rust PostgreSQL client:

- SQLx
- tokio-postgres
- Diesel
- SeaORM

No code changes are required in business logic when switching between pglite-oxide (embedded) and a remote PostgreSQL server.

---

## Unified Database Abstraction

For a "run anywhere" platform, the recommended architecture is a `prometheus-db` crate that selects the correct backend automatically:

```
                 Universal Database API
                        │
      ┌─────────────────┼─────────────────┐
      │                 │                 │
 Browser          Mobile/Desktop         Cloud
      │                 │                 │
Electric PGlite     pglite-oxide      PostgreSQL
 (WASM)             (native Rust)     (Supabase)
      │                 │                 │
      └─────────────────┼─────────────────┘
                        │
                Common Rust Traits
                        │
                Same SQL Everywhere
```

### Per-Target Mapping

| Platform | Backend |
|---|---|
| Browser | Electric PGlite (WASM) |
| macOS | pglite-oxide |
| Windows | pglite-oxide |
| Linux | pglite-oxide |
| iOS | pglite-oxide |
| Android | pglite-oxide |
| Server / Cloud | PostgreSQL 18 / Supabase |

---

## Recommended `prometheus-db` Capabilities

The abstraction layer crate should provide:

- Automatic database initialization and schema migrations
- Seamless switching between embedded and remote PostgreSQL via connection string
- Built-in CRDT replication and offline-first synchronization
- Integration with SurrealDB graph layer for entity relationships
- Automatic embedding generation via `pgvector`
- Full-text search over JSONB documents
- Database snapshots via IPFS
- Unified API surface for all three tiers (browser, native, cloud)

---

## Key Decision Points

**Why pglite-oxide over SQLite?**

SQLite lacks the PostgreSQL extension ecosystem. Vector search, full-text search with trigrams, JSONB operators, and triggers all require workarounds or separate libraries. pglite-oxide gives you the full PostgreSQL feature set on device.

**Why not Electric PGlite on mobile?**

Electric PGlite runs in a JavaScript/WASM context. Inside Tauri's WebView it is viable, but it cannot be used from the Rust side of the application without a bridge. pglite-oxide is the correct choice when the Rust runtime owns the data layer.

**Standard connection string means zero lock-in.**

Any code that connects with `sqlx::PgPool::connect(&url)` or equivalent works identically against pglite-oxide locally and against Supabase in the cloud. The backend is swapped at configuration time, not at compile time.

---

## Related Documents

- [tj-arch-mob-001.html](./tj-arch-mob-001.html) — initial Tauri hybrid mobile architecture reference
- [gen_ui_spec.html](./gen_ui_spec.html) — generated UI specification
