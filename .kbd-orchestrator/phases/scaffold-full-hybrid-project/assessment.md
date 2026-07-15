# Assessment — scaffold-full-hybrid-project

> Phase: `scaffold-full-hybrid-project` · Generated 2026-07-15
> Goal: design and scaffold the perfect hybrid Flutter → Rust FFI → Tauri implementation with
> business/networking logic shared across ALL platforms including web (WASM), engineered for
> development speed (compile-time optimization) and correctness (skills + type-system-first),
> supporting concurrent worktree development and publishable shared libraries.

---

## 1. Current state

The repo is a skill package (scaffolding scripts + references), not an application. What exists:

| Asset | State |
|---|---|
| `scripts/scaffold-hybrid.sh` | Creates workspace with single `rust/gen_ui_core` crate + `mobile/` + `desktop/` |
| `scripts/scaffold-rust-core.sh` | Monolithic crate; only `[profile.release]`; deps hardwired native-only |
| `scripts/scaffold-flutter.sh`, `scaffold-tauri.sh` | Per-surface scaffolds |
| `references/` | Solid patterns for Flutter/Riverpod, Tauri/Zustand, Rust core, auth |
| `references/*/testing.md` | mockall/proptest-heavy unit testing guidance — **conflicts with new philosophy** |
| ContentBlock contract | 11-variant sealed union, 7-step add procedure — sound, keep |
| `openspec/specs/` | Empty — no specs authored yet |

## 2. Gap analysis

### GAP-1 — No WASM target support (blocking the "ALL platforms" goal)

`gen_ui_core` as scaffolded cannot compile to `wasm32-unknown-unknown`:

- `tokio = { features = ["full"] }` — net/fs/signal drivers don't exist on wasm
- `surrealdb = { features = ["kv-rocksdb"] }` — RocksDB is native-only (wasm needs `kv-indxdb`)
- `candle-core = { features = ["metal", "accelerate"] }` — native accelerators
- `reqwest` native TLS stack — wasm needs its fetch-based backend
- `runtime.rs` global Tokio runtime — wasm has no threads; needs `wasm-bindgen-futures::spawn_local`

**Root cause: the crate is monolithic.** Per-target salvage is impossible without a layered split.

### GAP-2 — Monolithic crate defeats compile speed AND worktree concurrency

One crate means: one incremental compilation unit chain, serialized rebuilds of everything on
any edit, proc-macro expansion (serde, frb, async-trait) re-run broadly, and every concurrent
worktree colliding in the same files. The two phase goals (fast compiles, concurrent
development) have the **same fix**: a feature-decoupled workspace split.

### GAP-3 — Zero compile-speed engineering

No dev-profile tuning, no `.cargo/config.toml`, no Cranelift option, no sccache, no
check-first workflow, no `bacon`. Research findings (full report in §5):

- **Cranelift**: nightly-only; works on aarch64-macOS (host dev loop) — **not** for
  iOS/Android cross-compilation or wasm32. Enable via a custom `dev-fast` profile so
  mobile/WASM builds never see it. Caveat: panics abort on macOS under Cranelift.
- **Linker**: macOS Xcode 15+ "ld-prime" is already fast; mold/sold are dead on macOS.
  The real macOS link win is `split-debuginfo = "unpacked"` + `debug = "line-tables-only"`.
  Linux CI gets rust-lld by default since Rust 1.90.
- **`panic = "abort"` trap**: the current scaffold sets `panic = "abort"` in release —
  **this breaks flutter_rust_bridge**, which converts Rust panics to Dart `PanicException`
  via `catch_unwind`. With abort, any panic hard-kills the entire mobile app process.
  Must be `panic = "unwind"` for FFI targets; `abort` only in the wasm profile.
- **Dep-optimization**: `[profile.dev.package."*"] opt-level = 2` + `build-override
  opt-level = 3` (proc-macros) — compile deps well once, iterate on app code at opt 0.
- **`hint-mostly-unused`** (stable since ~1.90) for huge-API deps.
- **Check-first loop**: `cargo clippy` as the single loop driver (clippy and check don't
  share fingerprint caches — alternating recompiles twice). `bacon clippy` for continuous
  checking. Cross-target `cargo check --target wasm32-unknown-unknown` catches cfg errors
  in seconds without full builds.
- **sccache**: CI + branch-switching only; can't cache incremental crates, so it's not an
  inner-loop tool. Per-surface `CARGO_TARGET_DIR` (target/ios, target/android, target/wasm)
  prevents feature-unification cache thrash between surfaces.
- **cargo-hakari** (workspace-hack) pins one unified feature set across desktop/mobile/wasm
  invocations, stopping dependency rebuild churn.

### GAP-4 — Testing guidance actively fights the new philosophy

`references/*/testing.md` push mockall, proptest, per-module unit tests, and global rules
mandate TDD + 80% coverage. Research evidence (MSR 2026 study of 1.2M commits: agents write
23% test commits vs 13% for humans, 36% add mocks vs 26%; matklad's testing canon; Rust
linking economics — every `tests/*.rs` file is a separately linked binary) supports the
features-first policy. Codified as the 12-rule Testing Philosophy now in CLAUDE.md/AGENTS.md.

### GAP-5 — No publishing surface for reusable libraries

Nothing is structured for publishing crates, pub.dev packages, or NPM packages. Everything
is scaffold-inline. The architecture goal requires named, versioned, publishable artifacts.

### GAP-6 — No UI/UX skill wiring

No project-local skills, no skill-activation hooks, no references to the high-value external
skill ecosystem. Research shows baseline skill auto-activation is ~50% or worse; directive
descriptions + UserPromptSubmit hooks raise it to ~84–100%.

---

## 3. Proposed target architecture

### 3.1 Layered workspace (solves GAP-1, GAP-2, GAP-5 together)

```
crates/
  gen_ui_types/       # L0 — pure types: ContentBlock, StreamEvent, A2UI/AG-UI enums, config.
                      #      serde only. NO tokio, NO IO. Compiles everywhere incl. wasm32.
  gen_ui_runtime/     # L1 — runtime abstraction: native = global Tokio (one per process),
                      #      wasm = wasm-bindgen-futures spawn_local. cfg-gated, tiny.
  gen_ui_protocol/    # L1 — A2UI/AG-UI adapters + ProtocolPipeline over futures channels.
                      #      Pure transformation; wasm-safe.
  gen_ui_client/      # L2 — Anthropic HTTP/SSE client behind a Transport trait:
                      #      native → reqwest+rustls HTTP/2; wasm → fetch/EventSource backend.
  gen_ui_mcp/         # L2 — MCP client. SSE transport wasm-safe; stdio transport cfg(native).
  gen_ui_db/          # L2 — SurrealDB: kv-rocksdb (native) / kv-indxdb (wasm), feature-gated.
                      #      (pglite-oxide alternative stays native-only, documented.)
  gen_ui_inference/   # L2 — candle GGUF engine. metal/accelerate behind native features;
                      #      wasm build possible with default-features off (CPU/WebGPU), or
                      #      stubbed behind `inference` feature on wasm.
  gen_ui_agent/       # L3 — PMPO loop (UAR embedded/external) over L0–L2 abstractions.
  gen_ui_ffi/         # LEAF — flutter_rust_bridge surface (api.rs). Thin; editing app
                      #      logic no longer retriggers frb codegen.
  tauri-plugin-gen-ui/# LEAF — Tauri 2 plugin: commands, events, permissions + NPM guest-js.
  gen_ui_wasm/        # LEAF — wasm-bindgen/web surface for browser embedding.
  workspace-hack/     # cargo-hakari feature-unification pin.
```

Layer rule: L(n) depends only on L(<n). Leaves depend on anything. **Each L-crate is a
worktree-parallelizable work unit** — protocol, client, mcp, db, inference, and agent can be
built concurrently by separate agents with conflicts only at published trait boundaries
(defined first in `gen_ui_types`).

### 3.2 Published artifacts (GAP-5)

| Registry | Package | Contents |
|---|---|---|
| crates.io | `gen_ui_types`, `gen_ui_protocol`, `gen_ui_client`, `gen_ui_mcp`, `gen_ui_agent` | Reusable core |
| crates.io | `tauri-plugin-gen-ui` | Tauri plugin (Rust half) |
| npm | `@prometheus-ags/tauri-plugin-gen-ui` | Plugin guest-js bindings |
| npm | `@prometheus-ags/gen-ui-react` | ContentBlock React components + hooks (works in Tauri, plain web, and Flutter webview embeds) |
| npm | `@prometheus-ags/gen-ui-wasm` | wasm-pack output of `gen_ui_wasm` for browser use |
| pub.dev | `gen_ui_flutter` | Flutter plugin: frb bindings + build tooling (XCFramework/.so) |
| pub.dev | `gen_ui_widgets` | ContentBlock widget set (shadcn_flutter/Material 3) |

The React package is the bridge that lets one component implementation serve Tauri desktop,
web (via `gen_ui_wasm`), and embedded webviews in Flutter where artifact rendering needs it.

### 3.3 Compile-speed configuration (GAP-3) — to be emitted by scaffolds

```toml
# workspace Cargo.toml
[profile.dev]
opt-level = 0
debug = "line-tables-only"
split-debuginfo = "unpacked"

[profile.dev.package."*"]
opt-level = 2
debug = false

[profile.dev.build-override]
opt-level = 3

[profile.release]
opt-level = 3
lto = "thin"
codegen-units = 1
strip = "symbols"
panic = "unwind"        # REQUIRED for flutter_rust_bridge PanicException; abort kills the app

[profile.wasm-release]
inherits = "release"
opt-level = "z"
lto = true
panic = "abort"
strip = "debuginfo"
```

Plus: optional nightly `dev-fast` profile with `codegen-backend = "cranelift"` (host-native
only), `bacon.toml` with clippy + per-target check jobs, sccache in CI, per-surface
`CARGO_TARGET_DIR`, cargo-hakari, `resolver = "3"`.

Loop discipline: `bacon clippy` continuous → `cargo check --target <t>` cross-target gates →
full build only when running the app. Never alternate bare check and clippy.

### 3.4 UI/UX skill wiring (GAP-6)

**External shortlist (install/reference — full research in phase notes):**
1. `frontend-design` (Anthropic; already in anthropic-skills plugin) — biggest first-shot lift
2. shadcn MCP server (already connected) + official shadcn/ui skill
3. `theme-factory` (Anthropic; already available) — one token source → Tailwind + Flutter themes
4. vercel-labs/agent-skills: `react-best-practices` + `web-design-guidelines`
5. `ui-ux-pro-max` (nextlevelbuilder) — only high-adoption skill covering React AND Flutter
6. Dart & Flutter MCP server (already connected) — hot-reload/widget-inspector verify loop
7. flutter/skills (official) — responsive layout, layout-fix, go_router
8. VGV golden-test workflow (vgv-ai-flutter-plugin) — Flutter visual regression
9. nank1ro `shadcn-ui-flutter` skill — correct shadcn_flutter APIs
10. Community-Access/accessibility-agents + airowe/claude-a11y-skill — WCAG 2.2 AA

**Project-local skills to author (in scaffolded projects' `.claude/skills/`):**
- `content-block-ui` — the 11-variant contract + per-variant UI conventions (Dart + React)
- `hybrid-design-tokens` — theme-factory tokens → Tailwind config AND shadcn_flutter theme
- `tauri-ui-review` — screenshot-driven review loop at 320/768/1024/1440
- `flutter-golden-ui` — golden-test scaffolding + dart-mcp hot-reload verification
- `a11y-gate` — cross-surface WCAG checklist backed by PostToolUse hook

**Activation discipline:** directive skill descriptions ("ALWAYS invoke when…"), folder name
= frontmatter name, UserPromptSubmit hook matching trigger words (raises hits from ~50% to
~84–100% per published studies).

---

## 4. Recommended changes (input to /kbd-plan)

| # | Change | Serves | Size |
|---|---|---|---|
| C-1 | Rewrite `scaffold-rust-core.sh` → layered workspace (`gen_ui_types` … leaves), wasm-ready cfg-gating, fixed profiles (unwind!), `.cargo/config.toml`, bacon.toml, hakari | GAP-1,2,3,5 | L |
| C-2 | New `scaffold-wasm.sh` + `gen_ui_wasm` leaf + wasm-pack/wasm-opt pipeline + web demo host | GAP-1 | M |
| C-3 | Extract `tauri-plugin-gen-ui` (Rust + guest-js NPM), update `scaffold-tauri.sh` to consume it | GAP-5 | M |
| C-4 | Flutter packaging: `gen_ui_flutter` plugin + `gen_ui_widgets` package structure in `scaffold-flutter.sh` | GAP-5 | M |
| C-5 | React packaging: `@prometheus-ags/gen-ui-react` component library structure | GAP-5 | M |
| C-6 | Rewrite `references/*/testing.md` to features-first/snapshot/boundary testing; add `references/rust/compile-speed.md` | GAP-3,4 | S |
| C-7 | Author 5 project-local skill templates + skill-activation hook, emitted by scaffolds into generated projects | GAP-6 | M |
| C-8 | CLAUDE.md + AGENTS.md philosophy sections | GAP-4,6 | S — **done in this assessment** |

Worktree concurrency of the plan itself: C-2…C-5 are independent once C-1 lands (they
consume the workspace layout). C-6, C-7 are independent of everything.

## 5. Research artifacts

Three deep-research reports were produced for this assessment (compile-speed configuration
with per-target compatibility matrix and sources; testing-philosophy evidence base incl.
MSR 2026 over-mocking study and matklad canon; UI/UX skills landscape with adoption
signals). Their distilled conclusions are embedded above and in CLAUDE.md/AGENTS.md; key
sources are cited inline in `references/rust/compile-speed.md` when C-6 lands.

## 6. Risks / open questions

1. **Cranelift is nightly-only** — offer as opt-in `dev-fast` profile, never default.
2. **candle on wasm** — CPU-only wasm inference is slow; decide whether wasm builds stub
   inference behind a feature (recommended default: `inference` off for wasm).
3. **SurrealDB indxdb maturity** on wasm — validate early in C-2; pglite-oxide has no wasm
   path (ElectricSQL PGlite covers browser if relational is needed).
4. **frb codegen across a split workspace** — `gen_ui_ffi` must re-export a clean surface;
   validate frb 2.x handles cross-crate types (it does via mirrors, but confirm early).
5. **Publishing cadence** — marketplace artifacts (`plugin.json`) require version bumps when
   scaffold outputs change (constraints.md WARNING tier).
