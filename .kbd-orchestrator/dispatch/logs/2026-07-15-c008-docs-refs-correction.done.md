# c008-docs-refs-correction — COMPLETE

Doc-corrections + reference updates for TJ-ARCH-MOB-001, per plan.md C-008 and analysis.md
§1.1–1.3, §1.6. No runnable code — all deliverables are markdown reference/doc files, so the
features-first testing policy applies trivially (nothing to compile or test). Verified factual
accuracy against analysis.md's web-verified library verdicts and confirmed all internal
cross-references resolve.

## Files modified
- **docs/pglite-oxide-tauri-hybrid.md** — Full rewrite of the two verified errors: (1)
  pglite-oxide is a WASM-runtime host of ElectricSQL's PGlite WASI build (PostgreSQL 17.5
  guest), **not** a native Rust Postgres binary; (2) **no iOS/Android support** (desktop/web/
  cloud only). Added the authoritative per-target data-layer matrix (mobile = SQLite +
  sqlite-vec), corrected the platform-comparison table, architecture diagrams, per-target
  mapping, and all Key-Decision-Points prose. Added a correction banner citing analysis.md.
- **CLAUDE.md** — Rewrote the "Embedded PostgreSQL (pglite-oxide)" section → "On-device data
  layer (per-target)": Postgres SQL spans web/desktop/cloud, mobile uses SQLite+sqlite-vec;
  pglite-oxide is WASM-guest/Rust-host, no iOS/Android. Updated the reference index: pglite
  row reworded, testing.md rows reworded to "features-first", patterns.md row → SurrealDB 3.2,
  and **two new rows** for compile-speed.md and ui-skills.md.
- **references/rust/patterns.md** — Header → SurrealDB 3.2 / frb 2.12. Added the **layered
  workspace layout** (11 crates, gen_ui_types frozen seam, gen_ui_db isolated for the #6954
  build.rs compile-cache issue), updated workspace Cargo.toml (surrealdb 3.2, frb 2.12, wasm32
  kv-indxdb target block). New **SurrealDB 3.2 section**: 2.x→3.x breaking-change table
  (MTREE→HNSW, SEARCH ANALYZER→FULLTEXT, type::record, rand::id, LET, `<|K,EF|>`), 3.2 DDL,
  graph-RAG pattern (HNSW recall → RELATE expansion → BM25 → RRF in Rust), and the
  FFI-intent-only layer contract (Dart never sees raw SurrealQL).
- **references/flutter/patterns.md** — Header → Riverpod 3.3 / frb 2.12; deps bumped
  (flutter_riverpod 3.3.2, riverpod_annotation 4.0.3, generator 4.0.4, +riverpod_sqflite).
  Added Riverpod 3 migration notes (unified Ref, sealed AsyncValue, ref.mounted, pause),
  **CRITICAL FFI retry opt-out** pattern (`@Riverpod(retry: _noRetry)` returning null),
  Mutations API pattern, and the ref.mounted-guarded ContentBlock stream-fold pattern.
- **references/rust/testing.md** — Full rewrite to features-first: no mockall/tarpaulin,
  boundary tests at public surfaces, insta/expect-test snapshots, wiremock/tempdir fakes at IO
  boundaries only, one integration binary per crate (tests/it/), 3–5 tests/feature, clippy is
  the inner loop, no coverage gate.
- **references/flutter/testing.md** — Full rewrite to features-first: no mockito/mocktail,
  override only the FFI-edge provider (mock nothing internal), golden tests (VGV/alchemist),
  boundary notifier/screen tests, flutter analyze + hot-reload as the inner loop, no coverage
  gate.
- **references/tauri/testing.md** — Full rewrite to features-first: stub invoke / MSW at IO
  boundaries only (never mock internal stores/hooks), inline/file snapshots, kept the cheap
  static layer-contract guards, tsc+eslint+`tauri dev` as the inner loop, no coverage
  threshold.

## Files created
- **references/rust/compile-speed.md** — Inner-loop discipline: clippy-only (never alternated
  with bare check), no full builds in the loop, cross-target `cargo check`, workspace caching
  (gen_ui_db isolation for #6954), dev-profile settings, Cranelift host-only, per-surface
  CARGO_TARGET_DIR, cargo-hakari/sccache, and the never-`panic="abort"`-on-FFI rule.
- **references/ui-skills.md** — Catalog of mandatory UI/UX skills (React: frontend-design,
  shadcn MCP, theme-factory, vercel packs, ui-ux-pro-max; Flutter: Dart&Flutter MCP,
  flutter/skills, VGV goldens, shadcn-ui-flutter; a11y WCAG 2.2 AA), the 5 scaffold-emitted
  project-local skills, and the "activate before writing" rule.

## Compliance / deviations
- All edits respect the layer contracts and BLOCKING constraints (FFI-intent-only SurrealDB
  surface; invoke() only in stores; @riverpod codegen only; panic=unwind on FFI).
- Generated-file marker (`// TJ-ARCH-MOB-001 compliant`) not applied — these are markdown
  reference/doc files, not generated code files; the marker convention targets emitted code.
- Left OUT OF SCOPE per Rule 40: `references/flutter/auth.md` header still reads "Riverpod
  2.6+" (auth.md is c008-adjacent but not in the assigned change list); CLAUDE.md required-
  tool floor `flutter_rust_bridge_codegen 2.3+` left as a minimum floor (bumping risks
  scaffold backward-compat, a WARNING-tier constraint) — the reference docs correctly show the
  current pinned frb 2.12.
- No blockers.
