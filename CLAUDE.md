# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## What this repository is

A skill package and reference library for **TJ-ARCH-MOB-001** — the Prometheus AGS hybrid mobile architecture. It contains no runnable application code. Its outputs are:

- Scaffolding scripts that generate new Flutter/Tauri/Rust projects
- Reference documents that agents and developers must read before writing code
- Templates used by the scaffolding scripts

The actual application code lives in projects scaffolded _from_ this repository, not inside it.

---

## Prometheus Base Rules

This repository follows the Prometheus Base Rules 1–40. **The canonical, complete rule
text lives in [AGENT_BASE_RULES.md](AGENT_BASE_RULES.md) at the repo root — read it
before substantial work.** Three binding requirements layered on top:

1. **Our own work in this repo follows all 40 rules.**
2. **Code generators must propagate the rules**: every scaffolded project receives a
   copy of `AGENT_BASE_RULES.md` at its root, and its generated CLAUDE.md/AGENTS.md
   must reference it as binding (scaffold-hybrid.sh emits this).
3. **Skills must follow the rules when activated**: every skill authored in this repo
   (templates/project-skills/*, .claude/skills/*, and the parallel harness skill dirs)
   operates under these rules; skill templates reference AGENT_BASE_RULES.md explicitly.

Key invariants (summary — the file is authoritative):

- **Rule 2 (Simplicity First):** Write minimum code. No speculative abstractions.
- **Rule 3 (Surgical Changes):** Touch only what is necessary. Match existing conventions.
- **Rule 9 (Architectural Consistency):** All generated code must follow TJ-ARCH-MOB-001 patterns exactly.
- **Rule 12 (Open Standards First):** MCP, A2UI/AG-UI, OpenAI-compatible APIs, WASM, PostgreSQL-compatible storage, IPFS-compatible distribution preferred.
- **Rule 15 (Feature-Based Clean Architecture):** Organize by business capability — `features/<name>/data|domain|presentation`.
- **Rule 16 (Strict Layering):** `UI → Hooks → Stores → Services/API`. No skipping layers in either direction.
- **Rule 29 (Strong Typing):** No implicit `any`. All business objects typed. Generated types from schemas preferred.
- **Rule 30 (Tests Are Part of Completion):** Run type checks and linters after every change.
- **Rule 40 (Stop When Done):** Do not add unrequested features or cleanup.

---

## Development Philosophy: Speed AND Correctness

Our philosophy combines development speed with correctness. Both are achieved by moving
verification *earlier* (type system, lints, skills) and testing *later* (when there is a
complete feature worth testing). These rules override any global rules that mandate TDD,
80% coverage, or test-first workflows.

### Correctness through first-shot quality

- Lean on the 40 Prometheus Base Rules (Karpathy-derived) as the primary correctness
  discipline for generated code.
- Maintain and consult the LLM wiki (`pk` knowledge base) over time via our skills —
  lessons learned become durable context, not repeated mistakes.
- **Use Rust skills heavily** (rust-skills plugin: m01–m15 modules, domain-* skills,
  rust-patterns, axum-patterns, actor-model, async-patterns) so we emit good code the
  first time. Invoke them BEFORE writing Rust, not after errors appear.
- The compiler is the harness: encode invariants in types (enums over booleans, newtypes
  with validated constructors, exhaustive `match`, make illegal states unrepresentable).
  A state the type system forbids needs no test and no debugging session.

### Speed through minimal compilation

- **Limit the number of compilations above all else.** The inner loop is `cargo check` /
  `cargo clippy` — never full builds. Pick `cargo clippy` as the single loop driver
  (check and clippy do not share caches; alternating recompiles everything twice).
- Use `bacon clippy` for continuous checking; `cargo check --target wasm32-unknown-unknown`
  / `--target aarch64-apple-ios` to gate cross-target cfg errors in seconds.
- Heavy caching in dev profiles: `[profile.dev.package."*"] opt-level = 2`,
  `build-override opt-level = 3`, `debug = "line-tables-only"`,
  `split-debuginfo = "unpacked"` — dependencies compile well once, app code iterates fast.
- Cranelift backend (`dev-fast` profile, nightly) for host-native inner loops; LLVM stays
  for iOS/Android/WASM (Cranelift does not support them). sccache in CI. Per-surface
  `CARGO_TARGET_DIR` to avoid cross-target cache thrash. cargo-hakari to pin feature
  unification.
- **Never set `panic = "abort"` on FFI release profiles** — flutter_rust_bridge needs
  unwinding to convert panics into Dart `PanicException`; abort kills the whole app.

### Testing: features first, tests later

- **FEATURES first. Code first. Test later.** We are in the business of building useful
  software fast, not making tests pass. Do not write tests until a feature is complete,
  compiles clean under clippy, and has been exercised end-to-end once.
- Unit tests are the lowest-value test form; passing unit tests prove nothing about the
  system working. Test USEFUL COMBINATIONS of components at public API boundaries
  (FFI surface, Tauri commands, protocol pipeline) — behavior a user can observe.
- No mocks of internal code — ever. Mocking in Rust demands trait-injection ceremony that
  distorts the design and bloats compile time. Fakes only at real IO boundaries (wiremock
  for HTTP, tempdir/in-memory for DB).
- Prefer snapshot tests (`insta`/`expect-test`): input in, snapshot out; behavior changes
  cost one `cargo insta accept`, not a test-rewriting session.
- One integration-test binary per crate (`tests/it/` with modules) — every separate
  `tests/*.rs` file is a separately linked binary and linking dominates the cycle.
- Test budget: 3–5 behavior tests per completed feature unless explicitly told otherwise.
  Coverage percentage is NOT a goal in this repo or its scaffolded projects.
- **If you fail to fix the same test twice, STOP.** Report the discrepancy. Do not loop
  on tests. Never modify, delete, or `#[ignore]` a failing test to escape a red state
  without explicit approval.

### Architecture for concurrent development

- Design for parallel worktrees: split functionality so full parts of the system can be
  built simultaneously. The Rust workspace is layered (`gen_ui_types` → protocol/client/
  mcp/db/inference → agent → ffi/tauri-plugin/wasm leaves); trait boundaries are defined
  first in `gen_ui_types` so downstream crates develop concurrently without conflicts.
- Feature-based clean architecture everywhere (Rule 15): features decouple through
  `app/`/`shared/` only — never feature-to-feature imports. Minimal cross-dependencies =
  maximal parallel work.

### UI/UX skills are mandatory, not optional

Use the available UI/UX skills aggressively — they are the difference between generic AI
output and intentional design (see `references/ui-skills.md` when it lands, and the
assessment in `.kbd-orchestrator/phases/scaffold-full-hybrid-project/assessment.md` §3.4):

- React/web: `frontend-design` (Anthropic), shadcn MCP + shadcn/ui skill, `theme-factory`
  (single token source → Tailwind AND Flutter themes), vercel `react-best-practices` +
  `web-design-guidelines`, `ui-ux-pro-max` (covers React and Flutter).
- Flutter: Dart & Flutter MCP (hot-reload/widget-inspector verify loop), flutter/skills
  (official), VGV golden-test workflow, `shadcn-ui-flutter`.
- Accessibility: a11y agents (WCAG 2.2 AA) on both surfaces.
- Scaffolded projects receive project-local skills (`content-block-ui`,
  `hybrid-design-tokens`, `tauri-ui-review`, `flutter-golden-ui`, `a11y-gate`) plus a
  skill-activation hook — directive descriptions and prompt-matching hooks raise skill
  activation from ~50% to ~84–100%.

### Shared libraries across all platforms

The architecture exposes reusable, publishable libraries — plan every change with this in
mind:

- **Rust (crates.io):** `gen_ui_types`, `gen_ui_protocol`, `gen_ui_client`, `gen_ui_mcp`,
  `gen_ui_agent`, `tauri-plugin-gen-ui`. Core crates compile to native AND wasm32.
- **Flutter (pub.dev):** `gen_ui_flutter` (FFI plugin), `gen_ui_widgets` (ContentBlock
  widget set).
- **React/npm:** `@prometheus-ags/gen-ui-react` (ContentBlock components — used in Tauri,
  plain web, and Flutter webview embeds), `@prometheus-ags/gen-ui-wasm`,
  `@prometheus-ags/tauri-plugin-gen-ui` (guest-js).
- New Tauri plugins that make the hybrid fluid are encouraged — structure them as
  publishable `tauri-plugin-*` crates with npm guest bindings from day one.

---

## Architecture decision authority

**Before any substantial work, read:** `references/arch-standard.md`

Platform selection is non-negotiable:

| Target | Platform | Status |
|---|---|---|
| iOS / Android (consumer or healthcare) | Flutter + Rust FFI | **Mandatory** |
| macOS / Windows / Linux (desktop) | Tauri + React 19 | Recommended |
| Both mobile + desktop for same product | Hybrid (Flutter mobile + Tauri desktop) | Default |

---

## The invariant: `gen_ui_core`

All networking, LLM interaction, inference, MCP, agent logic, and persistence live in the shared Rust crate `gen_ui_core`. **Never re-implement these in Dart or TypeScript.**

`gen_ui_core` compiles to:
- `staticlib` → XCFramework (iOS) + `cdylib` → `.so` (Android JNI) for Flutter via `flutter_rust_bridge`
- Tauri plugin (cdylib/staticlib) for desktop

One global Tokio runtime per process. Never create additional runtimes. CPU-bound work (GGUF loading, inference forward passes) uses `spawn_blocking`.

### gen_ui_core module structure

```
gen_ui_core/src/
  lib.rs              # module declarations
  api.rs              # FFI surface for Flutter (frb codegen target)
                      # OR Tauri commands/events for desktop
  api_http.rs         # Anthropic HTTP/2 client (reqwest + rustls + SSE)
  runtime.rs          # global Tokio runtime
  streaming.rs        # SSE parser → StreamEvent sealed enum
  config.rs           # UarMode enum, AppConfig
  protocol/
    mod.rs            # ProtocolPipeline (dual broadcast channels)
    a2ui.rs           # A2UI adapter + 27-variant event enum
    agui.rs           # AG-UI adapter + bidirectional events
  agent/mod.rs        # PMPO loop (UAR embedded mode)
  inference/
    mod.rs            # InferenceEngine, ModelId, ChatTemplate
    sampler.rs        # temperature/top-p/top-k
  mcp/
    mod.rs            # McpClient + McpRegistry
    sse_transport.rs
    stdio_transport.rs
  db/mod.rs           # SurrealDB (MemoryStore, ToolCache, EntityGraph)
```

---

## ContentBlock: the cross-platform UI contract

Every A2UI event maps to exactly one `ContentBlock` variant. This is the contract between Rust and all UIs. The Dart and TypeScript compilers enforce exhaustiveness at the switch/match site — missing a case is a compile error.

Variants: `text`, `thinking`, `code`, `citation`, `memory`, `toolUse`, `toolResult`, `skill`, `artifact`, `image`, `divider`

When adding a new ContentBlock type, follow all 7 steps in `references/rust/new-block-type.md`. Skipping steps produces compile errors by design.

---

## State management — layer contracts

### Flutter (Riverpod 2.6+)

```
Widget (ConsumerWidget) → @riverpod provider → Repository/Service (via FFI) → gen_ui_core
```

- Use `@riverpod` codegen annotations exclusively — never manual `Provider(...)` declarations
- `AsyncNotifier` for async state; `Notifier` for sync state
- `autoDispose` on all streaming providers
- `ContentBlock` mutations happen only via `ChatNotifier.streamBlock()` — never direct state assignment
- `ref.watch` in build/provider bodies; `ref.read` in callbacks

### Tauri + React 19 (Zustand 5 + TanStack)

```
Component → Hook → Store → [Rust invoke() / external API]
```

- **Components** import only hooks (`useFeatureName` pattern). No direct store imports. No `invoke()` calls.
- **Hooks** compose from Zustand stores and TanStack Query. No `invoke()` calls.
- **Stores** are the only layer that calls `invoke()` / `listen()`.
- **Zustand** owns client-side state (UI, selection, filters, streaming).
- **TanStack Query** owns server-side / async data (queries, mutations, caching).
- **TanStack Router** handles routing with `beforeLoad` auth guards.

---

## Feature directory structure

Both Flutter and React use the same feature-based layout:

### Flutter

```
lib/features/<feature-name>/
  data/repositories/        # Implements domain interfaces
  data/datasources/         # Remote (Rust FFI) + local
  data/models/              # DTOs, JSON serialization
  domain/entities/          # Core business objects (freezed)
  domain/repositories/      # Abstract interfaces
  domain/usecases/          # Single-responsibility use cases
  presentation/providers/   # @riverpod annotated providers
  presentation/screens/     # Screen widgets
  presentation/widgets/     # Feature-specific widgets
```

### Tauri/React

```
src/features/<feature-name>/
  api/          # Tauri invoke() wrappers (called only from stores)
  stores/       # Zustand stores (client-side state)
  queries/      # TanStack Query hooks (server-side state)
  hooks/        # Composed hooks (what components import)
  components/   # Feature UI components
  types.ts      # Feature-specific types
```

Cross-feature dependencies go through `app/` or `shared/` — never direct feature-to-feature imports.

---

## Scaffolding commands

```bash
# Verify environment and install missing tools
bash scripts/check-env.sh
bash scripts/check-env.sh --install

# New hybrid project (Flutter mobile + Tauri desktop + shared Rust)
bash scripts/scaffold-hybrid.sh <project-name>

# Single surface scaffolds
bash scripts/scaffold-flutter.sh <project-name>
bash scripts/scaffold-tauri.sh <project-name>
bash scripts/scaffold-rust-core.sh <project-name>

# Add authentication to existing project
bash scripts/add-auth.sh supabase flutter ./<mobile-dir>
bash scripts/add-auth.sh kratos tauri ./<desktop-dir>

# Add a feature module
bash scripts/new-feature.sh <feature-name> flutter ./<mobile-dir>
bash scripts/new-feature.sh <feature-name> tauri ./<desktop-dir>

# Audit architecture compliance
bash scripts/audit.sh flutter ./<mobile-dir>
bash scripts/audit.sh tauri ./<desktop-dir>
bash scripts/audit.sh rust ./rust/gen_ui_core
```

---

## Build and test commands (in scaffolded projects)

### Flutter

```bash
# Run code generation (required after any @riverpod or freezed change)
dart run build_runner build
dart run build_runner watch   # continuous

# Re-run flutter_rust_bridge codegen (after api.rs changes)
flutter_rust_bridge_codegen generate \
  --rust-input rust/gen_ui_core/src/api.rs \
  --dart-output lib/bridge/generated_api.dart

# Run tests
flutter test
flutter test test/features/chat/providers/chat_provider_test.dart  # single file

# Linting
flutter analyze
```

### Rust (gen_ui_core)

```bash
# Build
cargo build
cargo build --release

# Tests
cargo test
cargo test -- --nocapture                    # with stdout
cargo test protocol::a2ui_tests              # specific module
cargo test --test integration                # integration tests only
cargo tarpaulin --out Html --output-dir coverage/

# Quality
cargo fmt
cargo clippy -- -D warnings
```

### Tauri/React

```bash
# Install dependencies
npm install    # or pnpm install

# Type check
npx tsc --noEmit

# Unit tests (Vitest)
npm test
npm run test -- src/features/chat/stores/__tests__/chatStore.test.ts  # single file

# Lint
npx eslint src/

# Dev server (Tauri desktop)
npm run tauri dev

# Production build
npm run tauri build
```

---

## UAR integration modes

Configure in `gen_ui_core/src/config.rs`:

```rust
pub enum UarMode {
    Embedded,    // PMPO loop runs in-process (default for standalone apps)
    External {   // Connect to shared UAR service via HTTP
        url: String,
        api_key: Option<String>,
    },
}
```

Use **Embedded** for KnowMe, TribeHealth mobile, standalone field tools. Use **External** for enterprise deployments where UAR is shared infrastructure.

---

## Authentication strategy

Read `references/auth/patterns.md` before implementing auth.

| Scenario | Strategy |
|---|---|
| Enterprise / SSO / compliance | Ory Kratos (self-hosted) |
| Consumer app + managed DB | Supabase Auth |
| Enterprise identity + managed DB | Kratos (identity) + Supabase (database only) |

When combining: Kratos issues session token → Rust backend in `gen_ui_core` exchanges it for a Supabase JWT → client uses JWT for all DB operations. The service role key never leaves the Rust layer.

Enable RLS on every Supabase table. Never expose the service role key to clients.

---

## Required tool versions

| Tool | Minimum |
|---|---|
| Rust + Cargo | 1.95+ |
| Flutter SDK | 3.29+ |
| Dart | 3.4+ |
| Node.js | 22+ LTS |
| Tauri CLI | 2.10.3 |
| flutter_rust_bridge_codegen | 2.3+ |

---

## Code generation markers

All generated files must include `// TJ-ARCH-MOB-001 compliant` at the top.

---

## Reference index

| File | Read when |
|---|---|
| `references/arch-standard.md` | Platform selection, UAR mode choice, ContentBlock table |
| `references/flutter/patterns.md` | Any Flutter work — Riverpod, clean arch, FFI wiring, shadcn_flutter, GoRouter |
| `references/flutter/auth.md` | Flutter Kratos/Supabase implementation |
| `references/flutter/testing.md` | Riverpod test, widget tests, golden tests |
| `references/tauri/patterns.md` | Any Tauri/React work — Zustand, TanStack, IPC, layer contract |
| `references/tauri/auth.md` | React Kratos/Supabase implementation |
| `references/tauri/eslint-config.md` | ESLint 9 flat config, tsconfig strict, Prettier, Vitest setup |
| `references/tauri/testing.md` | Vitest, RTL, layer contract enforcement tests |
| `references/rust/patterns.md` | gen_ui_core module structure, FFI rules, Tauri commands, UAR modes |
| `references/rust/new-block-type.md` | 7-step guide for adding a new ContentBlock variant |
| `references/rust/testing.md` | cargo test, tokio::test, wiremock, SurrealDB integration tests |
| `references/rust/wasm-targets.md` | Any web/WASM work — SurrealDB kv-indxdb, fetch/EventSource, PGlite interop, wasm MSRV (C-002 spike findings) |
| `references/auth/patterns.md` | Auth strategy selection, full Kratos + Supabase examples |
| `docs/pglite-oxide-tauri-hybrid.md` | Embedded PostgreSQL via pglite-oxide (alternative to SurrealDB for relational needs) |
| `docs/tj-arch-mob-001.html` | Full architectural standard |
| `docs/gen_ui_spec.html` | Full gen_ui technical specification and SVG architecture diagrams |

---

## Embedded PostgreSQL (pglite-oxide)

For applications needing full PostgreSQL semantics on-device (vector search via `pgvector`, full-text search via `pg_trgm`, JSONB operators, triggers), use **pglite-oxide** — a real PostgreSQL 17.5 binary packaged as a Rust crate. It exposes a standard connection string, making it compatible with SQLx, tokio-postgres, Diesel, or SeaORM.

Distinct from ElectricSQL's PGlite (WASM for browsers). pglite-oxide is Rust-native and runs in the Tauri/Flutter Rust layer.

The recommended abstraction — a `prometheus-db` crate — selects the backend automatically:
- Browser → Electric PGlite (WASM)
- Mobile/Desktop → pglite-oxide
- Cloud → PostgreSQL 18 / Supabase

---

## Products built on this architecture

- **KnowMe** (`know-me.tools`) — Flutter mobile (iOS/Android) + Tauri desktop
- **Prometheus AGS** — Tauri desktop primary + Flutter field mobile
- **TribeHealth.ai** — Flutter mobile (healthcare, non-negotiable per `references/arch-standard.md`)
