# Tasks — 2026-07-15-c106-sync-local-first

> Expanded at execute time (2026-07-16) after surveying what C-005 already built.
> **The sync engine is NOT the gap.** `gen_ui_db::sync` already ships a real Electric
> shape consumer, DIY write queue (idempotent keys, exponential backoff, poison
> handler), `SyncStatus` broadcast, and the `LocalStore`/`WriteSink` trait seams behind
> the frozen `gen_ui_types::sync::SyncTransport`. wasm32 is a documented no-op (the
> browser path is `@electric-sql/pglite-sync` on the JS side).
>
> The real gap is **three-part**, confirmed by grep on 2026-07-16:
>   1. **No infra to sync against** — `apps/knowme-poc/infra/` did not exist. (T2: done.)
>   2. **NOTHING IMPLEMENTS THE SEAMS.** `impl LocalStore` and `impl WriteSink` return
>      *zero* hits across the whole workspace, and `LocalStore`/`WriteSink` are
>      referenced nowhere outside `gen_ui_db::sync` itself. The engine is a complete
>      skeleton with no body: `SyncEngine::new(cfg, store, sink)` cannot be called
>      because neither argument can be constructed. `PgliteStore`/`PostgresStore`
>      (relational/postgres.rs) exist but implement neither trait. **This is the bulk of
>      C-106 and was not visible from the plan.**
>   3. Both `attach_sync_shapes` entry points are no-op `Ok(())` stubs
>      (`tauri-plugin-gen-ui::commands`, `gen_ui_ffi::api::boot`) — but they cannot be
>      wired until (2) exists.
>
> **Fallback (plan decision 2):** if Electric integration overruns, ship SyncStatus +
> the write queue proven by boundary tests and label the shape lane honestly. Do NOT
> fake a sync demo.

- [x] T1 — RESEARCH + PIN (Rule 22): verified ElectricSQL image tag and its Postgres
      version floor; confirm the HTTP shape API our C-005 consumer targets still
      matches the pinned image. Record findings + sources in decision-log.md.
- [x] T2 — `apps/knowme-poc/infra/docker-compose.yml`: Postgres (logical replication
      enabled) + Electric, pinned by digest/tag per T1, with a documented
      `docker compose up` one-liner. Must run on one machine (desktop + iOS sim).
- [x] T3 — Schema + shapes: the `notes`/`memories` tables Electric publishes, and the
      shape definitions the consumer subscribes to. Reuse the existing `shapes.rs`
      contract — do not invent a second one.
- [ ] T3b — **`impl LocalStore` for the local relational store** (read path): apply
      `RowChange` batches in ONE transaction per shape message boundary; upsert on the
      shape key; `truncate_shape` for `must-refetch` rotation. Desktop = pglite-oxide
      (`PgliteStore`), mobile = the same seam over its own store. Soft-delete rows carry
      `deleted = true` (a shape cannot ship an absent row).
- [ ] T3c — **`impl WriteSink`** (write path): replay a `PendingWrite` to the server,
      carrying its idempotency key so retries dedupe; map HTTP outcomes onto
      `WriteOutcome` (success / retryable / poison). Decide + record the write target:
      the plan says "forge Quarry API", but the demo's Postgres is reachable directly —
      pick ONE and log why (Rule 22).
- [ ] T4 — Wire the desktop seam: `tauri-plugin-gen-ui::commands::attach_sync_shapes`
      constructs `SyncEngine::new(cfg, store, sink)` from T3b/T3c and starts it
      (currently `Ok(())`), reading endpoint config the same way the config DB supplies
      other settings. No new command surface.
- [ ] T5 — Wire the mobile seam: `gen_ui_ffi::api::boot::attach_sync_shapes` likewise;
      mobile resolves its data dir the way C-103's boot already does.
- [ ] T6 — SyncChip live on both surfaces: subscribe to the existing `SyncStatus`
      broadcast (do not poll). React via the Hooks→Stores contract; Flutter via a
      `@riverpod` autoDispose stream provider.
- [ ] T7 — Airplane-mode demo: offline edit → queue → reconnect → replay → row lands on
      the other surface. Verify by hand, desktop ↔ iOS sim, and record what was
      observed (not what was intended).
- [ ] T8 — Boundary tests (3-5 per CLAUDE.md, not coverage-driven): write-queue replay
      after reconnect, idempotent-key dedupe, poison-message handling. Fakes only at
      the IO boundary — no mocks of internal code.
- [ ] T9 — Verify: `cargo clippy --workspace -D warnings`, `tsc --noEmit`,
      `dart analyze` clean; wasm32 still builds (sync stays a no-op there).
