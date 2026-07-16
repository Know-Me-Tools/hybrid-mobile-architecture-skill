# Tasks — 2026-07-15-c106-sync-local-first

> **PIVOTED 2026-07-16 (user decision, option B): ElectricSQL is OUT; flint-realtime-fabric
> (FRF) is the realtime substrate.** Rationale + evidence in decision-log.md. Summary:
> FRF is the intended way this org does realtime, and it is not an Electric *consumer* —
> `frf-postgres-cdc` opens its own logical-replication slot and reads `pgoutput` directly,
> i.e. the same Postgres mechanism Electric consumes. Running both would mean two CDC
> paths contending for slots on one WAL for zero gain. Keeping Electric would have meant
> building, maintaining, and later removing a second realtime stack.
>
> **T1-T3 (Electric compose/schema, merged in PR #5) are hereby SUPERSEDED**, not deleted:
> `infra/` gets rewritten onto FRF's stack. That is sunk cost accepted at 3 tasks rather
> than at 9 — the seams below were never written against Electric.
>
> **What already exists (do not rebuild):**
>   * `gen_ui_client/src/flint/frf.rs` — a `FrfSpine` façade over `frf-sdk-rust`, already
>     documenting the SDK entry points as VERIFIED against FRF HEAD, pinned at rev
>     `9ba04ae` (confirmed 2026-07-16 to be FRF's current HEAD). The `frf` feature is a
>     STUB: `frf = []` with the dep commented out in both Cargo.tomls. Un-stub it.
>   * `gen_ui_db::sync` (C-005) — shape consumer, write queue (idempotent keys, backoff,
>     poison handler), SyncStatus broadcast, LocalStore/WriteSink seams. The Electric
>     HTTP shape consumer (`shapes.rs`) is now dead weight on the native path.
>   * Frozen `gen_ui_types::sync::SyncTransport` — start/enqueue_write/status. UNCHANGED
>     by this pivot: that is exactly what the seam being frozen was for.
>
> **VERIFIED FRF read/write mapping (read from FRF source 2026-07-16, not assumed):**
>   * READ path is **CDC → spine channel → `FrfClient::subscribe(channel_id, consumer_id,
>     from)`** yielding `EventEnvelope`s. `frf-postgres-cdc` publishes each decoded row
>     change to a `channel_path` (e.g. `"entity/changes"`).
>     **NOT `EntityService::WatchEntity`** — that takes a single `entity_id` and watches ONE
>     entity; it is not a table/shape feed. This distinction is the main trap here.
>   * WRITE path is `FrfClient::publish(&EventEnvelope) -> Offset`, with `ack(offset)` for
>     consumption. Offsets replace Electric's `(handle, offset)` cursor.
>   * Auth: gate-minted Bearer via the SDK's `AuthInterceptor`; tenant scoping is
>     first-class (`tenant_id` on every message) — strictly better than the
>     `ELECTRIC_INSECURE=true` demo posture T2 shipped.
>
> **Known cost of the pivot (accepted):** the web lane's documented browser path was
> `@electric-sql/pglite-sync` (`gen_ui_db/src/sync/README.md`). FRF's browser story is
> frf-wasm / Connect-web instead. T7b covers rewriting that doc; the web surface is NOT
> in this change's critical path (native desktop↔mobile is the demo).
>
> **Fallback (plan decision 2) still stands:** if the FRF integration overruns, ship
> SyncStatus + the write queue proven by boundary tests and label the realtime lane
> honestly. Do NOT fake a sync demo.

- [x] T1 — ~~Electric image/Postgres pin research~~ **SUPERSEDED by the FRF pivot.**
      Kept for provenance: the Electric 1.7.7 + Postgres 18 findings are in the
      decision-log and were correct; they are simply no longer the target.
- [x] T2 — ~~infra/docker-compose.yml (Postgres + Electric)~~ **SUPERSEDED** — replaced
      by T2b below. Landed in PR #5; rewritten here.
- [x] T3 — ~~Electric shape schema~~ **SUPERSEDED** by T3d. The notes/memories table
      design (client-generated UUID PKs, soft-delete) SURVIVES the pivot: those choices
      were driven by replay/idempotency, which FRF needs identically.
- [x] T2b — RESEARCH + PIN (Rule 22): stand `infra/` up on FRF's own compose. FRF ships
      `compose.yml` + `compose.override.example.yml`; pin the images/rev it expects
      (Postgres + Iggy broker + frf-gateway) and record SHAs. Reuse FRF's compose rather
      than hand-rolling a second one — it is the maintained artifact.
- [x] T3d — Postgres schema + CDC publication: notes/memories tables (carry T3's PK and
      soft-delete design forward) + the `CREATE PUBLICATION` / replication-slot config
      `frf-postgres-cdc` requires, and the `channel_path` its rows land on.
- [ ] T4b — Un-stub the `frf` feature: real `frf-sdk-rust` git dep at the pinned rev
      (`9ba04ae…`, Rule 22/23) in the workspace + gen_ui_client Cargo.tomls; keep it
      native-only and wasm-excluded (tonic/HTTP-2 does not build for wasm32 — the
      existing cfg-gating already anticipates this). Verify wasm32 still checks clean.
- [ ] T5b — **`impl SyncTransport` for an FRF-backed engine** — the crux, and the work
      C-005 left undone (there is still NO concrete LocalStore/WriteSink anywhere):
        * `start()` → `subscribe(channel_id, consumer_id, from)`, decode `EventEnvelope`
          → `RowChange`, apply via `LocalStore::apply_batch` in one txn per batch.
        * `enqueue_write()` → existing write queue → `publish()`, carrying the
          idempotency key so retries dedupe; map outcomes onto `WriteOutcome`.
        * `status()` → the existing SyncStatus broadcast.
      Reuse `engine.rs`'s queue/backoff/poison machinery — do NOT write a second one.
- [ ] T6b — `impl LocalStore` over the local relational store (pglite-oxide desktop /
      mobile store): apply RowChange batches atomically, upsert on PK, soft-delete rows.
- [ ] T4 — Wire the desktop seam: `tauri-plugin-gen-ui::commands::attach_sync_shapes`
      constructs and starts the FRF engine (currently a no-op `Ok(())`), reading endpoint
      + tenant + token from the config DB the way other settings are supplied.
- [ ] T5 — Wire the mobile seam: `gen_ui_ffi::api::boot::attach_sync_shapes` likewise
      (also a no-op `Ok(())` today).
- [ ] T6 — SyncChip live on both surfaces: subscribe to the existing SyncStatus broadcast
      (do not poll). React via Hooks→Stores; Flutter via a `@riverpod` autoDispose stream.
- [ ] T7 — Airplane-mode demo: offline edit → queue → reconnect → replay → row lands on
      the other surface, desktop ↔ iOS sim. Record what was OBSERVED, not intended.
      **Blocked on Docker registry auth on this host** (`docker pull hello-world` fails
      identically — stale credential, not our compose).
- [ ] T7b — Rewrite `gen_ui_db/src/sync/README.md`: the browser path is frf-wasm /
      Connect-web, not `@electric-sql/pglite-sync`. Remove the Electric shape-consumer
      docs from the native path or mark `shapes.rs` dead.
- [ ] T8 — Boundary tests (3-5 per CLAUDE.md, not coverage-driven): write-queue replay
      after reconnect, idempotent-key dedupe, poison handling. Fakes only at the IO
      boundary — no mocks of internal code.
- [ ] T9 — Verify: `cargo clippy --workspace -D warnings`, `tsc --noEmit`, `dart analyze`
      clean; wasm32 still builds (FRF stays compiled out there).
