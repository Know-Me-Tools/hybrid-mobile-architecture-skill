# Tasks — 2026-07-15-c103-chat-live-e2e

> Derived from plan.md's C-103 entry (revised scope) + the inference-architecture
> decision log. Walked one at a time via /kbd-apply.
>
> CORRECTED mid-execution (user-directed): storage backends are pglite-oxide
> (desktop/Tauri), PGlite (web, TypeScript-side only — not reachable from Rust
> on wasm), and embedded SurrealDB (mobile, reusing gen_ui_db_graph) — NOT
> sqlite. The pre-existing sqlite scaffold (SqliteStore, sqlite feature,
> sqlite-vec/libsqlite3-sys) was removed entirely from gen_ui_db and from
> scaffold-rust-core.sh. T4/T5 below are folded into T3's actual landing and
> T6/T8's web wiring respectively.

- [x] T1. Vendor liter-llm as a pinned git dependency in gen_ui_client; confirm
      native-http feature builds for the workspace's native targets (macOS/iOS/Android)
- [x] T2. Add liter-llm's wasm-http feature as the web-target inference dependency
      (gen_ui_wasm leaf) and confirm it builds for wasm32-unknown-unknown
      (required a getrandom_backend="wasm_js" cfg fix — liter-llm's ahash dep pulls
      in getrandom 0.3, which needs this explicitly for wasm32)
- [x] T3. Design and land config DB schema v1 (providers, model_prefs, app_settings):
      Postgres-dialect migrations + ConfigStore trait/impls in gen_ui_db (desktop via
      pglite-oxide, web schema shared for the TS PGlite path); SurrealDB schema +
      CRUD in gen_ui_db_graph (mobile). Removed the sqlite scaffold entirely
      (Cargo.toml, relational/sqlite.rs, migrations/sqlite/, tests/it.rs test,
      scaffold-rust-core.sh) per user correction.
- [ ] T4. (folded into T3 — desktop config store is pglite-oxide via ConfigStore,
      done)
- [ ] T5. (folded into T6/T8 — web config store is PGlite on the TS side; wire
      alongside the web chat feature, not as separate Rust work)
- [ ] T6. Replace chat.rs's stub chat_send with a real liter-llm-backed call reading
      provider/model selection from the config DB; graceful degrade when no provider
      is enabled (no hardcoded API keys/env vars)
- [ ] T7. Wire ProtocolPipeline -> ContentBlock streaming over frb (mobile) and Tauri
      events (desktop) for the live liter-llm response stream
- [ ] T8. Update Flutter chat feature + Tauri chat feature to consume the live stream
      end-to-end (replacing any remaining placeholder wiring); wire the web PGlite
      config store (T5) here
- [ ] T9. Verify: cargo check --workspace, flutter analyze, tsc --noEmit all clean
- [ ] T10. Run live on macOS Tauri (first real provider round-trip) and capture the
      result
- [ ] T11. Run live on iOS simulator (first-ever on-target Flutter run for this PoC,
      G-6) and capture the result
- [ ] T12. Update decision-log.md / wiki with pinned SHAs for both forks and any
      defects found (Rule 22/23 provenance)
