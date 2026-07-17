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

- [x] T1 — **Memory UI on both surfaces.** Turned out to be mostly already built, once
      the backend actually worked:
      - **React**: landed in C-113 — route surfaced, the orphaned `MemoryPanel` mounted
        and styled, desktop `memory_search`/`graph_expand` un-stubbed.
      - **Flutter**: `memory_screen.dart` was already complete — ingest form, search,
        ranked hits rendering the real `text`/`kind`/`score` fields, driven through
        `MemoryNotifier` → bridge → the same `gen_ui_agent::memory`. It had simply never
        returned anything, because `memory_search` was broken at parse time. Verified
        `flutter analyze`: no issues.
      - Tappable citation/memory ContentBlocks are NOT done — the proposal's phrasing
        implies chat-transcript blocks, which belong with C-108's tool/citation work
        rather than this panel. Not claimed.

- [x] T3 — **Vector-only lane + hybrid/vector toggle.** Not "UI-only" as the proposal
      assumed: `memory_search` was hybrid-only, so there was nothing to toggle against.
      Added a real lane threaded `GraphStore::memory_search_with` →
      `gen_ui_agent::memory::search_with` → Tauri command → guest-js → store → hook → UI.
      `SearchMode` defaults to `Hybrid`; `memory_search` stays a defaulting wrapper, so
      no existing caller changed.
      Scores are **not comparable across modes** (RRF vs similarity are different
      scales) — defended three ways: documented on `MemoryHit`, the store clears hits on
      switch, and the UI labels each score `rrf`/`sim` rather than showing a bare number
      someone could compare. Verified: cargo test green, tsc clean, 7 vitest pass, and
      the toggle confirmed rendering + flipping state in a real browser.
      **Desktop/web only.** Mobile would need a `SearchMode` enum across the frb bridge
      and a codegen cycle; the toggle is a dev diagnostic and the surface it's useful on
      has it. Deliberate scope, not an oversight.

- [x] **Corpus verified end-to-end** (`tests/corpus_seed.rs`): seeds, re-seeds
      idempotently (proving `load_seeds` is safe on every start), and "BossFang" — a
      coined product term appearing in exactly one note — surfaces via the BM25 lane.
      Closes the gap between "the seeding code compiles" and "a fresh install's search
      returns something". Uses the HashEmbedder fake, so it proves the seeding and
      retrieval PLUMBING, not semantic ranking quality — that needs real embeddings and
      a human reading results.
      **In its own test binary, and that matters.** Seeding ~20 notes into the shared
      `tests/it` DB swamped the other tests' small-`k` searches and turned a green suite
      red (3-in-5 failures, moving around by execution order). `GraphStore::open` is a
      process-wide singleton, so one binary = one DB; a separate binary gets its own
      process and its own DB. Verified by stashing: without this test, `it` passed 5/5.
      Teaching five other tests to tolerate a corpus they never asked for would have been
      the wrong fix.

## Not done — stated plainly

- [ ] **`graph_expand_traverses_relate_edges` is FLAKY (~1-in-4).** The functional fix
      (merged from a separate session — `type::record`, RELATE record-literals) is
      correct; the test around it is order-dependent, same shared-singleton cause as
      above. **Verified pre-existing**: reproduced 1 pass / 3 fail on a clean checkout of
      main with every C-111 change stashed, so it is not fallout from this work. Spun off
      to its owner (task_daf7f70c) with `tests/corpus_seed.rs` as the isolation template.
      Not weakened or ignored — it caught two real SurrealDB 3.2 bugs and should keep
      being able to.
- [ ] **No app has booted, seeded, and searched in one run.** Every layer is tested and
      the corpus is proven searchable against a real embedded SurrealDB, but the full
      boot → seed → search path on a running desktop app is still unexercised. Given this
      change's history — a backend declared "verified" that had never once worked — that
      distinction stays explicit rather than rounded up.
- [ ] **Tappable citation/memory ContentBlocks in the chat transcript.** The proposal
      lists these under T1, but they belong with C-108's tool/citation block work rather
      than the memory panel. Not claimed here.
