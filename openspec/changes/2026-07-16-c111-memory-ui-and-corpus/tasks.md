# Tasks — 2026-07-16-c111-memory-ui-and-corpus

> Carried forward from C-104 (T7-T9), which delivered backend wiring only per the
> user-directed scope decision of 2026-07-16.
>
> **The premise "backend is done and verified" turned out to be false.** C-104's live
> verification ran through the *Ollama chat* path, which never touches memory search. The
> first test that actually exercised `memory_search` found it broken at parse time on
> every call. See below — that discovery reshaped this change.

- [x] T0 — **Corrected the proposal's three stale claims** (user-ratified). It said
      "UI-only, no backend change" (false — the hybrid-vs-vector toggle needs a new
      vector-only lane, and the backend turned out to be broken outright); it specified
      `MemoryHit{id,name,score,snippet}` (the real type is `{id,text,kind,score}`); and
      T1's React half had already landed in C-113.

- [x] T2 — **Seed corpus** (`gen_ui_db_graph::corpus`): curated notes authored from
      `docs/reference-app/` (KnowMe FUNC-SPEC v1.0 + moodboard/user journeys), so search
      demos land on the product's real domain vocabulary — Hands, BossFang, Cedar, WASM
      plugins, on-device inference — rather than lorem ipsum that proves nothing about
      ranking. Stable seed ids make `seed_corpus` idempotent, so `load_seeds` can run on
      every start. Wired into **both** surfaces through the same
      `gen_ui_agent::memory::seed_demo_corpus` (desktop `load_seeds` command + mobile FFI
      `load_seeds`), which were both no-op stubs before.
      Deliberately NOT reusing `gen_ui_db::relational::SeedBundle`: that emits SQL for the
      relational config store, while memory lives in SurrealDB and must be embedded at
      ingest. Sized for a demo, not padded to the plan's "few hundred" — every note embeds
      at boot, so filler costs startup time for no signal.

## Backend bugs found — the memory layer did not work at all

The integration tests had been **failing silently**, and each failure masked the next:

- [x] **Test harness never initialised the runtime.** Every embedding path panicked with
      `runtime not initialised`: the tests use a `HashEmbedder` fake to avoid ONNX, but
      `embed_blocking` still calls `gen_ui_runtime::spawn_blocking`, and `#[tokio::test]`
      builds its *own* runtime the crate's global `OnceCell` knows nothing about. This
      looked like broken search rather than missing setup — and it hid everything below.
- [x] **Hybrid search failed on EVERY call.** `embedding <|$k,64|> $qvec` —
      SurrealDB's KNN operator parses its args at query-parse time and rejects a bound
      parameter (`Unexpected token 'a parameter', expected an unsigned integer`). `$k` is
      fine in `LIMIT $k`, not inside `<|…|>`. Now a literal `<|64,64|>`; both lanes feed
      RRF up to 64 candidates and only the fused output is cut to `$k` — which is what
      fusion wants anyway. **`memory_search` had never once succeeded in production.**
- [x] **`type::thing` does not exist in SurrealDB 3.2** (verified against
      surrealdb-core's own source, which names `type::record` as the replacement and
      keeps the same `(table, key)` arg order). 8 call sites across `store.rs` and
      `config.rs` — so entity creation, relations, graph expansion, **and the entire
      config store** (providers, model prefs, app settings) were all broken at runtime.
- [x] **`RELATE` rejects a function call at its endpoints** — `type::record(...)` parses
      fine in UPSERT/SELECT but not there. Uses the parameterized record-literal form
      `entity:⟨$from⟩`: table stays a compile-time constant, id stays bound.

**Result: hybrid search works.** `ingest_then_search_finds_the_memory` and
`lexical_lane_matches_rare_term` (a rare term only BM25 could surface) both pass, plus
the two corpus tests.

## Deferred — not started, and not claimed

- [ ] T1 — Flutter memory UI + tappable citation/memory ContentBlocks. The **React half
      landed in C-113** (route surfaced, orphaned `MemoryPanel` mounted and styled,
      desktop `memory_search`/`graph_expand` un-stubbed). Flutter's side is untouched.
- [ ] T3 — Vector-only lane + hybrid-vs-vector dev toggle. Needs a real backend addition
      threaded store → `gen_ui_agent::memory` → both command surfaces → UI;
      `memory_search` is hybrid-only, so there is nothing to toggle against yet.
- [ ] **Verify the corpus end-to-end.** The seeding path compiles and its unit tests
      pass, but no app has actually booted and searched the seeded corpus. Given this
      change's own history — a backend declared "verified" that had never worked — that
      distinction is worth keeping explicit.
