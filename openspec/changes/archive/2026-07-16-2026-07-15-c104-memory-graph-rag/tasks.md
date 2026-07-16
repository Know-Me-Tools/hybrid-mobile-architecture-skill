# Tasks — 2026-07-15-c104-memory-graph-rag

> Scope decision (2026-07-16, user-directed): this pass delivers backend wiring only.
> The Memory tile UI, seed corpus, and hybrid-vs-vector dev toggle are deferred to a
> follow-up change — tracked as T7-T9 below, left unchecked intentionally.

- [x] T1 — `gen_ui_db_graph::embed` FastEmbedder (384-dim) wired for native targets;
      `unnecessary_to_owned` clippy fix on `embed()` call.
- [x] T2 — Fixed pre-existing SurrealDB 3.2 schema bugs surfaced by first real
      `GraphStore` construction: `FLEXIBLE` keyword position (`TYPE option<object>
      FLEXIBLE`) and `SCHEMAFULL` requirement for `entity`/`model_pref`/`app_setting`
      tables (FLEXIBLE fields error on SCHEMALESS tables in 3.x).
- [x] T3 — `gen_ui_agent::state`: `AgentState.memory: Arc<GraphStore>` field;
      `init(config, memory)` signature; `state::memory()` accessor. Memory/graph-RAG
      is SurrealDB-embedded on every platform regardless of config-DB engine choice.
- [x] T4 — `gen_ui_agent::memory` module: `ingest`/`search`/`graph_expand` delegating
      to `state::memory()`, mirroring the established `gen_ui_agent::chat` pattern.
- [x] T5 — Desktop (`tauri-plugin-gen-ui::commands::run_migrations`): opens a real
      RocksDB-backed `GraphStore` at `data_dir/memory-db` via `FastEmbedder` in
      `spawn_blocking`; passes both config store and memory store to `state::init`.
- [x] T6 — Mobile bootstrap gap closed: `gen_ui_ffi::api::boot` (`run_migrations`,
      `load_seeds`, `attach_sync_shapes`) — mobile previously had no equivalent of
      desktop's Tauri migration commands, so `state::init` was never called and
      `chat_send` always failed with `NotInitialised`. Mobile resolves its own data
      directory via Dart `path_provider` and passes it in as a string.
- [x] T4b — `memory_search`/`memory_ingest`/`graph_expand` FFI functions
      (`gen_ui_ffi::api::chat`) rewired from stub/empty-`Vec<String>` returns to real
      `gen_ui_agent::memory::*` delegation.
- [x] T4c — Verified end-to-end via a real passing Ollama live test
      (`gen_ui_agent/tests/ollama_live.rs`, ported from a competing branch during
      merge-conflict resolution) exercising a real `GraphStore` for the first time
      this session — this is what surfaced the SurrealDB schema bugs in T2.
- [x] T7 — Memory tile UI: ingest form → hybrid search results → tappable
      citation/memory blocks. **Deferred — carried forward to
      `2026-07-16-c111-memory-ui-and-corpus` T1 (not delivered here).**
- [x] T8 — Seed corpus (few hundred curated notes) for demo-quality search results.
      **Deferred — carried forward to `2026-07-16-c111-memory-ui-and-corpus` T2.**
- [x] T9 — Hybrid-vs-vector dev toggle. **Deferred — carried forward to
      `2026-07-16-c111-memory-ui-and-corpus` T3.**
