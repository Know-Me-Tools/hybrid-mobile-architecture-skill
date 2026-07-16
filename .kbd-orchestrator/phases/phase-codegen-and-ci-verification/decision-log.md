### 2026-07-15 — kbd-analyze (bootstrap pillars) verdicts
- ADOPT: prometheus-skill-system (public; full install flow documented; verify via pk doctor
  + mcp-health + required binaries), @fission-ai/openspec 1.6.0 (bare 'openspec' npm is
  squatted — scoped name mandatory; channel-aware upgrade), Flutter beta 3.47.0 (releases-JSON
  currency check; dart mcp-server gate; our install-flutter.sh must be fixed — shallow stable
  clone), node@24 pinned (NOT --lts) + bun + pnpm + typescript@latest.
- USER REVISION: TypeScript pillar 6.0+ → 7.0.2 (latest). Scaffold pins updated ^5.x→^7.0.0
  (stale pins = live Rule-22 violation in our own generators, fixed).
- USER DIRECTIVE: 40 Prometheus Base Rules → canonical AGENT_BASE_RULES.md, wired into
  CLAUDE/AGENTS/dispatch-preamble/scaffold-emission/skill-templates. Provenance: user.
- BUILD (extend own): check-env.sh → 4-pillar bootstrap with operational gates; 7-item delta.
- Open: remediation aggressiveness default (recommend check-only default, --install, --full
  for long ops); skill-system clone location; staleness warn-vs-fail (recommend warn).

### 2026-07-15 — Inference architecture revision (user-directed, post-C-102)
- USER DIRECTIVE: replace bespoke Anthropic SSE with **liter-llm gateway**
  (git@github.com:GQAdonis/liter-llm.git fork — 142+ providers, streaming, tool calling;
  crates verified: liter-llm core with native-http feature, liter-llm-ffi, liter-llm-wasm
  → one dependency covers desktop/mobile/web). Requires a **config DB** for provider/model
  settings + administration: pglite-oxide (Tauri/mobile, Rust core) + PGlite (web).
  Folded into C-103 (schema+gateway) and C-109 (admin UI). Provenance: user.
- USER DIRECTIVE: local model inference + download via **mistral.rs fork**
  (git@github.com:GQAdonis/mistral.rs.git — mistralrs library crate: HF download,
  GGUF/ISQ load, Metal/CPU, candle-based; crates verified). Replaces candle-direct in
  C-105 native + C-109 mobile. Fork extras (audio/vision/mcp crates) noted, out of scope.
- RESEARCH (firecrawl, 2026-07): web local-model lane → **WebLLM (MLC)** on WebGPU —
  consensus in-browser chat engine (OpenAI-compatible streaming, curated MLC models incl.
  Qwen2.5-1.5B-Instruct-q4f16_1 matching the native model family, browser-cached).
  wllama (llama.cpp WASM) rejected as primary (CPU speeds don't demo well);
  transformers.js reserved for embeddings/whisper-class web tasks. Documented exception
  to the Rust-core invariant: TS adapter in the web surface behind the same intent seam.
  Sources: webllm.mlc.ai; lofttools.com/blog/browser-llms-2026-webllm-transformers-js;
  localmode.dev/blog/compare/webllm-vs-wllama.
- Memory plan (C-104) explicitly unchanged ("memory is good"). Cargo git deps pinned to
  SHAs at C-103/C-105 implementation time (Rule 22/23).

### 2026-07-16 — C-103 execution (T4-T12): live chat e2e + real defects found (Rule 22/23 provenance)
- **Pinned SHA (verified)**: liter-llm — `git@github.com:GQAdonis/liter-llm.git`, rev
  `78b7496ca7b09a1aa6c3c666af0a149bbdf5249f` (`liter-llm v1.9.3` per Cargo resolution).
  mistral.rs is NOT part of C-103 (deferred to C-105) — no SHA pinned here.
- **USER CORRECTION mid-execution**: no sqlite anywhere in this codebase. Desktop/Tauri
  uses pglite-oxide; web uses PGlite (TypeScript-side, unreachable from Rust on wasm);
  mobile uses embedded SurrealDB (gen_ui_db_graph). The pre-existing sqlite scaffold
  (SqliteStore, `sqlite` feature, sqlite-vec/libsqlite3-sys) was removed entirely from
  both the live app (`gen_ui_db`) and the scaffold script (`scripts/scaffold-rust-core.sh`)
  — verified via `grep -n "sqlite\|Sqlite"` returning zero hits in either.
- **Architecture gap found + fixed**: mobile (gen_ui_ffi) and desktop (tauri-plugin-gen-ui)
  were two disconnected command surfaces with no shared chat logic — desktop's `src-tauri`
  had its own ad-hoc `commands.rs` duplicating a subset of intents with different
  signatures, never wired to the pre-existing `tauri-plugin-gen-ui` plugin crate. Fixed by
  building the ONE shared `gen_ui_agent` crate (chat/config/state/secrets modules) that
  both platforms call into identically, deleting the duplicate stub layer, and wiring the
  plugin into `src-tauri/src/lib.rs` via `.plugin(tauri_plugin_gen_ui::init())`.
- **frb-streams Cargo feature removed**: `flutter_rust_bridge_codegen generate` only sees
  function signatures under features passed via its own `--rust-features` CLI flag (not a
  persistent Cargo feature toggle). The pre-existing `#[cfg(feature = "frb-streams")]` gate
  on `gen_ui_ffi::api::streams` created a chicken-and-egg bug: codegen needed the feature
  on to see `StreamSink<T>` functions, but `frb_generated.rs` then unconditionally
  referenced the module regardless of the gate. Resolved (user-approved) by removing the
  Cargo feature entirely — the module is now always compiled; codegen still needs a
  one-time `--rust-features frb-streams`-style flag only if this pattern recurs for a new
  gated module (documented in `api.rs`'s doc comment). Propagated to
  `scripts/scaffold-rust-core.sh` so new scaffolds don't reintroduce the same gate.
- **Recurring `pub use` vs `use` glob-import bug** (3rd occurrence in this repo): private
  `use` imports inside a frb API submodule are invisible to `frb_generated.rs`'s
  `use crate::api::<module>::*;` glob re-export. Hit again in `streams.rs` for
  `A2uiEvent`/`SyncStatus`/`ChangeEvent`; fixed identically to the two prior occurrences
  (`chat.rs`/`entity.rs`).
- **PEM type-shape mismatch** (tracked separately, task_18b27751): the real
  `prometheus-entity-management` `ListResult`/`EntityTransport` shape differs from the
  Tauri plugin's wire-level `gen_ui_types::transport::ListResult`/`EntityRecord` — required
  an adapter function (`toEntityRow`) in `entityRuntime.ts`. Also flagged: `memory_search`
  currently returns `Vec<String>` (a C-104 stub) not the frontend's expected
  `MemoryHit{id,name,score,snippet}` shape — spun off as its own follow-up task.
- **T10 (macOS Tauri)**: first-time full 999-crate build (SurrealDB + liter-llm +
  pglite-oxide + tauri-plugin-gen-ui all compiling fresh) succeeded clean in 6m46s; app
  booted and ran stably; `chat_send` gracefully degrades to `NoProvider` with no configured
  LLM provider (expected — empty config DB in a fresh app).
- **T11 (iOS simulator, first-ever on-target run for this PoC, G-6)**: succeeded on iPhone
  17 (iOS 26.4 simulator) after fixing a chain of real, previously-undiscovered gaps:
  1. A vestigial `flutter_packages/gen_ui_flutter` package declared `flutter: plugin:
     platforms: ios/android/macos: ffiPlugin: true` with NO platform folders or podspec at
     all — not imported by any Dart code, but CocoaPods' plugin-discovery still tried to
     resolve its podspec and failed. Fixed by stripping the `flutter: plugin:` block
     entirely (kept as a plain Dart-only package).
  2. Mobile had NO native-build wiring at all connecting `gen_ui_ffi`'s compiled Rust to
     the iOS/Android app — the frb-generated Dart bindings existed
     (`mobile/lib/bridge/`) but nothing built+linked the Rust cdylib/staticlib. Fixed via
     `flutter_rust_bridge_codegen integrate --rust-crate-name gen_ui_ffi --rust-crate-dir
     ../rust/crates/gen_ui_ffi`, which generated a proper cargokit-based `rust_builder/`
     plugin (podspec `script_phase` invoking `cargokit/build_pod.sh`; Android
     `build.gradle` with the matching `manifestDir`). NOTE: `mobile/lib/bridge/
     rust_bridge_provider.dart` may still contain pre-codegen `UnimplementedError` stubs
     not wired to the real generated `GenUiCore` bindings — flagged as a follow-up, not
     blocking (the app boots; full chat wiring through that specific file wasn't verified
     this session).
  3. `keyring` 4.1's default `v1` feature only enables `apple-native-keyring-store`'s
     `keychain` backend (macOS-only) — iOS has ONLY the `protected` (Data Protection)
     backend, and `apple-native-keyring-store` hard-`compile_error!`s on iOS without it.
     `keyring` itself doesn't re-export a standalone `protected` feature (only bundled
     inside its heavyweight `cli` feature), so fixed by declaring
     `apple-native-keyring-store` directly as a `cfg(target_os = "ios")`-scoped dependency
     in `gen_ui_agent` with `default-features = false, features = ["protected"]`.
  4. This machine's Xcode 26.6 had no matching iOS 26.5 simulator platform installed —
     `xcodebuild -showdestinations` reported zero eligible simulator destinations (only
     the "Any iOS Device" placeholder) even with iOS 18.4/26.2/26.4 runtimes present.
     Fixed via `xcodebuild -downloadPlatform iOS` (multi-GB download, one-time
     machine-level fix, not a repo/code issue).
  5. Three successive rounds of missing native-library linking for the C-107 whisper-rs/
     cpal dependencies newly added to `gen_ui_ffi`'s transitive graph: libc++ (whisper.cpp's
     C++ code — `whisper-rs-sys`'s build.rs correctly emits `cargo:rustc-link-lib=dylib=
     c++`, but that only reaches a linker when cargo itself performs a final link; a
     staticlib artifact, which is what cargokit builds, never does — so nothing tells
     Xcode's own linker to pull in libc++ when IT performs the final link of Runner
     against the vendored `.a`), then CoreAudio/AudioToolbox/Accelerate (cpal's mic APIs +
     whisper.cpp's Accelerate-backed BLAS ops, same root cause), then AVFoundation (cpal's
     `AVAudioSession*` route-change notifications, same root cause again). Fixed by adding
     `-lc++ -framework CoreAudio -framework AudioToolbox -framework Accelerate -framework
     AVFoundation` to `OTHER_LDFLAGS` in both `mobile/rust_builder/ios/gen_ui_ffi.podspec`
     and the macOS counterpart. **General lesson**: any new native Rust dependency with its
     own `cargo:rustc-link-lib`/`#[link(...)]` directives will need its system
     frameworks/libraries added explicitly to this podspec — cargokit's staticlib artifact
     can never carry that requirement forward to Xcode's linker on its own. Android's NDK
     toolchain was NOT verified for the equivalent gap (no Android build attempted this
     session) — flagged as an open follow-up.
  6. `prometheus_entity_management`'s freezed classes (`EntityRecord`, `ListResult`,
     `FilterSpec`, `SortSpec`, `ViewDescriptor`) were declared as plain `class Foo with
     _$Foo` — a freezed 2.x pattern. freezed 3.0's official migration guide requires
     `abstract class Foo with _$Foo` (or `sealed class` for unions) as a breaking change;
     without it, the compiler correctly reports the class as missing implementations of
     every abstract getter/method the generated mixin declares. Fixed all five
     declarations; `ChangeEvent` (already `sealed class`) needed no change.
  App confirmed running stably post-fix via `xcrun simctl listapps`/`launchctl list`
  (stable PID, no crash) — a live LLM round-trip wasn't exercised (no provider configured
  in this fresh app, consistent with T10's scope).
- **C-107 (whisper-scribe) landed alongside**: new `gen_ui_audio` crate (whisper-rs +
  cpal, native-only — no wasm story yet, documented as a follow-up requiring a
  MediaRecorder+wasm-STT web adapter mirroring C-105's WebLLM precedent), wired into both
  `gen_ui_ffi::api::scribe` (mobile) and `tauri-plugin-gen-ui::commands::scribe_start/
  scribe_stop` (desktop) via the same process-global single-recording-slot pattern used
  by `gen_ui_agent::state` for chat.
- **C-110 (CI) landed alongside**: `.github/workflows/knowme-poc-ci.yml` — Rust
  clippy+test, `audit.sh all` against a scratch-scaffolded app, desktop Vitest +
  `tsc --noEmit`, mobile `dart analyze` (post-codegen, via a fresh
  `flutter_rust_bridge_codegen generate`), and a combined build job (`tauri build
  --no-bundle` + `flutter build ios --simulator --no-codesign`).
- Verified clean before commit: `cargo clippy --workspace -- -D warnings`,
  `flutter analyze`, `npx tsc --noEmit` (desktop) — all zero warnings/errors.

### 2026-07-16 — C-105 "research wait-state" resolved; C-112/C-113 UI scope added (user-directed)
- **C-105 wait-state was stale, not blocking.** The wiki note
  (`knowme-poc-phase-goals-and-c-105-research-wait-state`) recorded a phase snapshot, not
  an open question: the research it waited on was already decided on 2026-07-15 (mistral.rs
  GQAdonis fork native + WebLLM/MLC on web, both with sources in this log). A concurrent
  session has since landed T1-T8 on main (`79bb7af`, `dddfe85`) — fork pinned at
  `b7746a85cb2e78fb2cf11cfb6ea9abd0a167d1f3`, regex + safetensors/candle conflicts
  resolved, `MistralEngine` + WebLLM lane implemented, design.md written. **Remaining:
  T9-T12** (plugin commands, agent lane selection, cloud↔local toggle + tok/s, e2e smoke).
  C-105 marked `in_progress`, NOT taken up here, to avoid racing that session.
- **C-112 (new, delivered)**: the PoC's custom Tauri title bar
  (`decorations: false` + `Titlebar.tsx`) extracted into a reusable project-local skill,
  `tauri-custom-titlebar`. Captures the two non-obvious defects the PoC already solved:
  `data-tauri-drag-region` alone leaves dead zones (explicit `startDragging()` needed for
  the whole bar), and Tauri API imports throw at module scope in a plain web page
  (`isTauri()` guard). Per user direction the skill treats **surface gating as a
  first-class decision** — it must NOT default the desktop bar onto web/mobile, and offers
  the alternatives (no bar / plain web header / mobile app bar) instead.
- **C-113 (new, pending)**: mobile navigation must follow platform convention — iOS bottom
  tab bar (HIG); Android top-or-bottom per Material 3 — across BOTH React and Flutter, and
  extending to mobile-web PWA. Per user direction the PWA-by-platform rule must be a single
  **consistent** documented choice (adaptive vs. one convention), recorded here at execute
  time, not left to whichever component an agent reaches for. Research (T1) precedes the
  decision (T2) precisely because the 2026 conventions are what bind the choice.

### 2026-07-16 — C-106 execution: infra landed (T1-T3); TWO BLOCKERS surfaced
- **T2/T3 delivered**: `apps/knowme-poc/infra/` — docker-compose.yml (Postgres 18-alpine
  + Electric 1.7.7 pinned by multi-arch digest), postgres.conf (Electric's own required
  settings), init.sql (notes/memories with client-generated UUID PKs + soft-delete, both
  dictated by the shape contract). `docker compose config` validates.
- **BLOCKER 1 (environment, user action needed)**: cannot verify the stack actually runs
  — Docker registry auth on this machine is broken. `docker pull hello-world` fails with
  the same "authentication required - incorrect username or password"; `docker info`
  shows no logged-in user. This is a stale credential in the host's Docker config, NOT a
  defect in the compose file. `docker login` (or clearing the stale credsStore entry)
  unblocks T7's live demo. The pins themselves were verified against the Docker Hub API.
- **BLOCKER 2 (scope, decision needed)**: **the sync engine has no body.** `impl
  LocalStore` and `impl WriteSink` have ZERO hits workspace-wide; neither trait is
  referenced outside `gen_ui_db::sync`. `SyncEngine::new(cfg, store, sink)` is therefore
  uncallable — C-005 delivered the engine + seams, but no concrete store/sink ever
  landed. The plan's C-106 entry ("Electric read-path + DIY write queue") reads as if
  this existed. Added as T3b/T3c; they are the bulk of the remaining work, NOT the
  30-minute wiring the plan implies.
- **Write-target question (must be decided before T3c)**: the plan says the write path
  flushes through the "forge Quarry API", but the demo's Postgres is directly reachable
  and no forge instance is part of `infra/`. Either add forge to the compose or point
  the sink at Postgres for the PoC and label it. NOT decided unilaterally.
- Plan decision-2 fallback (SyncStatus + write queue proven by boundary tests, shape
  lane labeled honestly) remains available if T3b/T3c overrun.
### 2026-07-16 — C-106 (T1) sync infra research + pins (Rule 22/23 provenance)
- **Pinned (verified against Docker Hub API, 2026-07-16)**: `electricsql/electric:1.7.7`,
  multi-arch digest `sha256:15e9a25d5f6c515ad9113392291e34c6751b8b31d563ee4c496fde499a5ce14f`
  (arm64 + amd64 both present → runs on the dev Mac AND CI). 1.7.7 is the current release
  (2026-07-08); `latest` points at the same build. `canary` deliberately NOT used.
- **Wire-protocol compatibility CONFIRMED**: 1.7.x is the v1.x line our C-005 shape
  consumer already targets (`/v1/shape`, `offset=-1` initial sync, `electric-handle` /
  `electric-offset` headers, `must-refetch`/409 rotation). No consumer changes needed —
  the engine was written against this contract.
- **Postgres floor**: `postgres:18-alpine` per Electric's own dev compose
  (`packages/sync-service/dev/docker-compose.yml` @ main). Matches the CLAUDE.md cloud
  tier (PostgreSQL 18 / Supabase), so the PoC's local infra and its cloud target agree.
- **Required PG settings** (from Electric's own `dev/postgres.conf`, not invented):
  `wal_level = logical`, `max_replication_slots = 100`, `max_connections = 200`,
  `listen_addresses = '*'`. Logical replication is Electric's hard requirement (README).
- Sources: hub.docker.com/v2/repositories/electricsql/electric (tags + digest);
  github.com/electric-sql/electric @ main — README.md, packages/sync-service/dev/
  docker-compose.yml, packages/sync-service/dev/postgres.conf.
- **Scope finding**: C-106's gap is NOT the engine. `gen_ui_db::sync` (C-005) already has
  a real shape consumer, write queue (idempotent keys, backoff, poison handler),
  SyncStatus broadcast, and the LocalStore/WriteSink seams. The gap is (a) no infra to
  sync against and (b) BOTH `attach_sync_shapes` entry points are no-op `Ok(())` stubs
  (`tauri-plugin-gen-ui::commands`, `gen_ui_ffi::api::boot`). Tasks scoped accordingly.

### 2026-07-16 — DECISION (user, option B): FRF replaces ElectricSQL as the realtime substrate
- **Decision**: flint-realtime-fabric (FRF) is the realtime substrate for C-106 and for
  realtime generally. **ElectricSQL is dropped from this codebase.** C-106's T1-T3
  (Electric compose/pins/schema, merged in PR #5) are SUPERSEDED, not reverted for
  history's sake — `infra/` is rewritten onto FRF's own stack.
- **The premise that prompted this was false, and the evidence is unambiguous.** The ask
  was to "add ElectricSQL support to FRF, which also supports Electric SQL realtime
  integration." Verified against a freshly-pulled FRF (`git pull`; branch
  `sovereign-sfu-decode-proof` @ `9ba04ae`, 14 ahead of `origin/main` @ `d263ede`, 0
  behind): **`grep -rli 'electric'` returns ZERO files** across the entire repo — no code,
  no docs, no compose, no proto. FRF has never integrated Electric.
- **Why it shouldn't**: `frf-postgres-cdc` opens a logical replication slot and reads
  **`pgoutput`** directly via `tokio-postgres`/`pg_walstream`, publishing each decoded row
  change onto the Iggy spine. That is *the same Postgres mechanism Electric itself
  consumes*. FRF and Electric are alternative implementations of one job, not layers that
  stack. Adding Electric would mean two CDC paths contending for replication slots on the
  same WAL, for zero capability gain (`pgoutput` is `pgoutput` either way).
- **Why the pivot is cheap**: `gen_ui_client/src/flint/frf.rs` ALREADY exists — a
  `FrfSpine` façade over `frf-sdk-rust` documenting the SDK entry points as VERIFIED
  against FRF HEAD and pinned at rev `9ba04ae`, which is *exactly* the HEAD pulled today.
  The `frf` feature is stubbed (`frf = []`, dep commented out). The frozen
  `gen_ui_types::sync::SyncTransport` seam is UNCHANGED by the swap — which is what
  freezing it at C-001 was for.
- **VERIFIED FRF mapping (read from FRF source, not assumed)**:
  * READ = CDC → spine channel → `FrfClient::subscribe(channel_id, consumer_id, from)`
    → `EventEnvelope` stream. **NOT `EntityService::WatchEntity`** — that takes a single
    `entity_id` and watches ONE entity, not a table/shape feed. Easy and costly trap.
  * WRITE = `FrfClient::publish(&EventEnvelope) -> Offset`, `ack(offset)` to consume.
    Offsets replace Electric's `(handle, offset)` cursor.
  * AUTH = gate-minted Bearer via the SDK `AuthInterceptor`; per-message `tenant_id`.
    Strictly better than the `ELECTRIC_INSECURE=true` posture T2's compose shipped.
- **Accepted cost**: the web lane's documented browser path was `@electric-sql/pglite-sync`
  (`gen_ui_db/src/sync/README.md`); FRF's browser story is frf-wasm / Connect-web. Tracked
  as T7b. Native desktop↔mobile is the demo's critical path, so this is not blocking.
  `gen_ui_db::sync::shapes.rs` (the Electric HTTP shape consumer) becomes dead weight.
- **Still true after the pivot**: C-005 left the engine with NO body — `impl LocalStore` /
  `impl WriteSink` still have zero hits workspace-wide, so `SyncEngine::new` remains
  uncallable. That work does not disappear with Electric; it moves to T5b/T6b and remains
  the bulk of C-106.
- **NOT done, deliberately**: FRF's own phase-36 / sovereign-SFU-decode work was left
  untouched. Its `SFU_MODE=sovereign` gate is held OFF across phases 16→35 by an explicit
  honesty discipline (no receiver has observed a decoded frame; `framesDecoded=0`), and
  FRF's CLAUDE.md mandates halting at phase boundaries for approval. That work is WebRTC
  media decode — unrelated to realtime *data* sync and of no use to the skills repo.
