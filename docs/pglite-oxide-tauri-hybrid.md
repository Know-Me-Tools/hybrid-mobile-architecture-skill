# Embedded Postgres (pglite-oxide) in the Hybrid Architecture

## Overview

This document captures architectural notes on using **pglite-oxide** as an embedded
relational database layer for the **desktop and web tiers** of a hybrid application built
on TJ-ARCH-MOB-001 — and, critically, on where it does **not** apply (iOS / Android).

> **Correction (2026-07-15):** Earlier revisions of this document claimed pglite-oxide was
> a "real PostgreSQL binary, Rust-native, not WebAssembly" that ran on iOS and Android via
> Tauri. Both claims were wrong. This revision states the verified reality. See
> `.kbd-orchestrator/phases/scaffold-full-hybrid-project/analysis.md` §1.1.

**What pglite-oxide actually is:** a Rust crate (published **0.5.1**, 2026-06-04) that runs
ElectricSQL's **PGlite WASI build inside a WASM runtime** on the host. The guest is
PostgreSQL 17.5 compiled to WASM; the crate hosts it and exposes `PgliteServer` speaking the
real PostgreSQL wire protocol, so SQLx / tokio-postgres / Diesel / SeaORM connect to it
unchanged. It is **not** a natively-compiled PostgreSQL binary, and it is **not** a browser
library — it is the WASM PGlite guest wrapped in a Rust host process.

**Where it runs (verified):** AOT runtime assets are published for **Linux x64/arm64,
macOS arm64, and Windows x64 only**. There is **no iOS or Android support**. iOS
structurally cannot run stock PostgreSQL (no child processes, no JIT). The successor project
"Oliphaunt" *claims* future native-mobile Postgres but is pre-release (0.0.0, ~90 stars) —
do not architect against it.

- pglite-oxide repo: <https://github.com/f0rr0/pglite-oxide>
- ElectricSQL PGlite repo: <https://github.com/electric-sql/pglite>

**Consequence for TJ-ARCH-MOB-001:** "the same PostgreSQL SQL everywhere" holds for
**web, desktop, and cloud** — but **not mobile**. On iOS/Android the relational + vector
layer is **SQLite (via `sqlx-sqlite` / rusqlite in `gen_ui_core`) + sqlite-vec**. Plan the
data layer per-target; do not assume one dialect spans all four tiers.

---

## Platform comparison

| Project | What runs | Runtime host | Target environments |
|---|---|---|---|
| pglite-oxide 0.5.1 | PostgreSQL 17.5 (PGlite WASI guest) | WASM runtime inside a Rust host process | macOS arm64, Windows x64, Linux x64/arm64 — **desktop/server only** |
| Electric PGlite | PostgreSQL compiled to WASM | JS/WASM (browser, Node/Bun/Deno, Tauri WebView) | Browsers + JS runtimes |
| SQLite + sqlite-vec | SQLite engine (native lib) | Native, in-process | **iOS, Android** (and anywhere) |
| PostgreSQL / Supabase | Full server | Native server | Cloud, self-hosted |

---

## Per-target data layer matrix (authoritative)

This table supersedes the old "pglite-oxide everywhere" mapping. It matches
`references/rust/patterns.md` and analysis.md §1.2.

| Platform | Relational | Vector (RAG) | Graph RAG | Sync client |
|---|---|---|---|---|
| **Web** | PGlite 0.5.4 (`idb://` + relaxedDurability, multi-tab worker) | pgvector ext (HNSW works in WASM) | SurrealDB `kv-indxdb` (wasm32) or `@surrealdb/wasm` | `@electric-sql/pglite-sync` shapes |
| **Desktop (Tauri)** | pglite-oxide 0.5.1 (`PgliteServer` → sqlx `PgPool`; macOS arm64 / Linux / Win x64) | pgvector (same SQL as cloud) | SurrealDB 3.2 `kv-rocksdb` | Rust Electric shape consumer |
| **iOS / Android (Flutter)** | **SQLite via `sqlx-sqlite` in `gen_ui_core`** | **sqlite-vec** (prebuilt iOS/Android libs) | SurrealDB 3.2 `kv-rocksdb` | Rust sync client |
| **Cloud** | Postgres 18 / Supabase (RLS) | pgvector | SurrealDB server | Electric sync-service 1.7.x |

Embedding dims: standardize on **384** (all-MiniLM / bge-small class) or truncated-768
(matryoshka) so vectors replicate cleanly across engines; generate on-device via
fastembed-rs / candle in `gen_ui_core`.

---

## Where pglite-oxide fits: desktop (Tauri)

pglite-oxide owns the relational + vector layer on **desktop only**. It lives in the Rust
layer (`gen_ui_core` / a `gen_ui_db`-style crate), never in the WebView.

```
React 19 (Tauri WebView)
   │  invoke() — only from Zustand stores (layer contract)
   ▼
Tauri / Rust (gen_ui_core)
   │
   ▼
pglite-oxide 0.5.1  →  PgliteServer (PG wire protocol)
   │
   ▼
sqlx PgPool  →  PGlite WASI guest (PostgreSQL 17.5 + pgvector)
```

The desktop backend and cloud backend speak identical PostgreSQL SQL, so a single sqlx query
set targets both — swapped by connection string at configuration time, not compile time.

## Mobile does NOT use pglite-oxide

On iOS / Android the relational + vector layer is SQLite. The mechanism (Rust owns the data
layer; UI never touches it directly) is identical; only the engine and dialect differ.

```
Flutter (Widget → @riverpod provider → repository → FFI)
   │
   ▼
gen_ui_core (Rust, via flutter_rust_bridge)
   │
   ▼
sqlx-sqlite  +  sqlite-vec extension
```

Graph RAG is uniform across all targets via embedded **SurrealDB 3.2** (`kv-rocksdb` native
on iOS/Android/desktop, `kv-indxdb` on web). See `references/rust/patterns.md`.

---

## Bundled extensions (desktop/web via PGlite guest)

The PGlite guest bundles PostgreSQL extensions that most embedded stores cannot offer:

- `pgvector` — vector similarity search (HNSW)
- `pg_trgm` — trigram-based full-text search
- `citext` — case-insensitive text
- `hstore` — key-value store
- `ltree` — hierarchical label trees

On **mobile**, the equivalent capabilities come from a different stack: `sqlite-vec` for
vector search, FTS5 for full-text, JSON1 for JSON — with SurrealDB 3.2 providing graph RAG
across every tier.

---

## Compatibility

pglite-oxide exposes a standard PostgreSQL connection string, so any Rust PostgreSQL client
works against it: SQLx, tokio-postgres, Diesel, SeaORM. No business-logic changes are
required when switching between pglite-oxide (embedded desktop) and a remote PostgreSQL /
Supabase server — the backend swaps at configuration time.

This portability is **desktop/web/cloud-scoped**. Mobile code paths target the SQLite dialect
through the same repository interfaces, so the seam is the repository trait in `gen_ui_core`,
not the connection string.

---

## Unified database abstraction

For a "run anywhere" hybrid, a `prometheus-db`-style abstraction in `gen_ui_core` selects the
correct backend per target — but note the mobile branch is **not** Postgres:

```
                 Universal Database API (repository traits in gen_ui_core)
                        │
      ┌─────────────────┼──────────────────┬─────────────────┐
      │                 │                  │                 │
   Browser          Desktop            Mobile             Cloud
      │                 │                  │                 │
Electric PGlite    pglite-oxide     SQLite + sqlite-vec  PostgreSQL 18
 (WASM, JS)        (WASM guest,      (native, Rust)      / Supabase
      │             Rust host)            │                 │
      └─────────────────┴──────────────────┴─────────────────┘
                        │
                Common Rust repository traits
                        │
      PostgreSQL SQL on web/desktop/cloud · SQLite SQL on mobile
```

### Per-target mapping

| Platform | Relational backend |
|---|---|
| Browser | Electric PGlite (WASM) |
| macOS (desktop) | pglite-oxide |
| Windows (desktop) | pglite-oxide |
| Linux (desktop) | pglite-oxide |
| **iOS** | **SQLite + sqlite-vec** (not pglite-oxide) |
| **Android** | **SQLite + sqlite-vec** (not pglite-oxide) |
| Server / Cloud | PostgreSQL 18 / Supabase |

---

## Recommended `prometheus-db` capabilities

The abstraction layer should provide:

- Automatic database initialization and per-dialect schema migrations (sqlx `migrate!` /
  refinery for Postgres and SQLite; drizzle-kit bundled JSON for web PGlite)
- Backend selection by target (connection string on Postgres tiers; SQLite path on mobile)
- Read-path sync via ElectricSQL shapes (Rust consumer native; `pglite-sync` on web)
- Integration with the SurrealDB 3.2 graph layer for entity relationships (all tiers)
- On-device embedding generation (fastembed-rs / candle) feeding pgvector (Postgres tiers)
  or sqlite-vec (mobile)
- Full-text search (pg_trgm on Postgres tiers; FTS5 on mobile)
- Database snapshots (PGlite `dumpDataDir()`/`loadDataDir()` on web; IPFS content-addressed
  seed snapshots per Rule 12) — see analysis.md §1.8
- A single repository trait surface spanning all four tiers, dialect differences absorbed
  inside `gen_ui_core`

---

## Key decision points

**Why pglite-oxide over SQLite on desktop?**
On desktop the PGlite guest gives the full PostgreSQL extension ecosystem (pgvector, pg_trgm,
JSONB operators, triggers, views) with identical SQL to the cloud tier — so desktop and cloud
share one query set. SQLite would fork the SQL.

**Why NOT pglite-oxide on mobile?**
It has no iOS/Android runtime assets, and iOS cannot run stock PostgreSQL (no child
processes, no JIT). Mobile uses SQLite + sqlite-vec, reached through the same repository
traits in `gen_ui_core`.

**Why not Electric PGlite (browser build) on mobile?**
It runs in a JS/WASM context. Inside a Tauri WebView it is viable, but it cannot be driven
from the Rust side without a bridge — and the mobile surface is Flutter + Rust FFI, where the
Rust runtime owns the data layer. SQLite is the correct native choice there.

**Standard connection string means zero lock-in — on the Postgres tiers.**
Any code that connects with `sqlx::PgPool::connect(&url)` works identically against
pglite-oxide (desktop) and Supabase (cloud). Mobile is the deliberate exception; treat the
repository trait, not the connection string, as the portability seam.

---

## Related documents

- `references/rust/patterns.md` — `gen_ui_core` module + workspace layout, SurrealDB 3.2
- `references/rust/compile-speed.md` — isolating SurrealDB / DB crates for compile caching
- [tj-arch-mob-001.html](./tj-arch-mob-001.html) — Tauri hybrid mobile architecture reference
- [gen_ui_spec.html](./gen_ui_spec.html) — generated UI specification
