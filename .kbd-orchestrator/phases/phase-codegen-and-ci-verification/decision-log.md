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

### 2026-07-16 — C-106 T4/T5: the write path, and a task I dropped
- **MY ERROR, corrected**: rewriting the task list for the FRF pivot silently dropped
  **T3c (`impl WriteSink`)**. T4/T5 cannot construct a transport without one —
  `FrfSyncTransport::new(cfg, store, sink)` needs it — so the gap surfaced immediately.
  Restored as T3c below. There is still no production `WriteSink` in the workspace (only
  the test `NoopSink` in frf_transport.rs's tests).
- **VERIFIED, and it settles the write-target question the pivot left open**: the write
  path is **forge/Quarry, NOT the FRF spine**. Evidence:
  * `SpineService` (envelope.proto) is `Publish`/`Subscribe`/`Ack`. `Publish` writes to
    the **Iggy broker only** — `frf-app::publish` takes a `broker: Arc<L>` (LogBroker)
    and there is **no spine→Postgres writer anywhere in the FRF workspace**.
  * `EntityService` (entity.proto) is **read-only**: `GetEntity` + `WatchEntity`. FRF
    exposes no entity-write RPC at all.
  * Therefore CDC is strictly one-directional: **Postgres → spine**. Publishing a row
    change to the spine would fan it out to subscribers but never persist it, so the
    row would vanish on the next re-materialisation and never reach other devices.
    Using the spine as the write path would have looked like it worked in a demo and
    silently lost data.
  * Our `gen_ui_client::flint::forge` already implements the full `EntityTransport`
    CRUD surface (`create`/`update`/`delete`) over **Quarry's PostgREST grammar**
    (`/<schema>/<table>`) — i.e. writes land in Postgres, where CDC picks them up and
    fans them back out. That closes the loop. The original plan's "DIY write queue ->
    forge Quarry API" was right; the pivot does not change the write lane at all.
- **OPEN CONFIG REQUIREMENT (blocks the T7 demo, not the code)**: the loop only closes
  if forge/Quarry is pointed at **the same Postgres that FRF's CDC slot reads**. FRF's
  compose runs its own Postgres (`frf` db, port 15432) and no forge service. So the demo
  needs either (a) forge added to the compose against FRF's Postgres, or (b) forge
  configured at FRF's Postgres. Recorded rather than guessed — it is a deployment
  decision, and T7 is blocked on Docker auth regardless.

### 2026-07-16 — C-106 T3c/T4 landed; T5 (mobile) blocked on a gen_ui_db_graph contract decision
- **T3c (WriteSink) DONE** — `gen_ui_agent::sync_sink::ForgeWriteSink`, 5/5 tests. Placed
  at **L3** because the trait lives in `gen_ui_db` (L2) and the client in
  `gen_ui_client` (L2) — siblings that must not depend on each other, so L3 is the first
  layer that legitimately sees both. `forge_write_sink()` constructor also lives there so
  the platform leaves don't each grow reqwest/parking_lot deps just to build a client.
- **Bug caught in my own code before it shipped**: the first `forge_write_sink` took a
  `bearer` argument and never applied it — it logged and built an `Unauthenticated`
  state. A sync engine that silently writes as anon when told to authenticate is a
  data-leak shape. Now parses the token into `AuthState::Authenticated` and returns
  `Result` (a malformed token is an error, not a silent downgrade).
- **T4 (desktop) DONE** — `attach_sync_shapes` starts a real `FrfSyncTransport`:
  `PgLocalStore` over the same pglite singleton `run_migrations` opened, forge write
  queue, config read from `sync.frf` in the config DB. **Sync is opt-in**: absent config
  logs and returns Ok (local-only), because failing startup over an unconfigured optional
  backend would make the app unrunnable for everyone not doing sync work today. A
  *malformed* setting is still an error — someone tried and got it wrong.
- **T5 (mobile) BLOCKED — decision needed, and it is not an effort question.** Mobile has
  **no Postgres**: `gen_ui_ffi::api::boot::run_migrations` registers embedded SurrealDB as
  BOTH config and memory backend (`ConfigBackend::Surreal`), because pglite-oxide is
  structurally unsupported on iOS/Android (no child processes, no JIT). Therefore:
  * `PgLocalStore` (needs `sqlx::PgPool`) cannot serve mobile at all.
  * A `SurrealLocalStore` needs row-level upsert/truncate against SurrealDB — but
    `gen_ui_db_graph`'s public surface is **INTENT-LEVEL by explicit design** ("never raw
    SurrealQL"; the FFI contract depends on it, since there is no Dart SurrealDB SDK).
    Adding row persistence changes that crate's contract. **That is a design decision for
    the owner, not something to smuggle in under a sync task.**
  * The write path is NOT blocked — `forge_write_sink` is platform-agnostic. Once a
    mobile `LocalStore` exists, the wiring mirrors desktop's exactly.
  * Honest state: **desktop syncs, mobile does not yet.** Documented at the seam itself
    so the next reader finds it where they'd look.

### 2026-07-16 — CI repair: three separate root causes, two fixed, one upstream
Chasing T9's gate turned up three independent reasons CI could never be green. All were
pre-existing; none were C-106's doing.
1. **Rust job — FIXED.** `clippy --workspace` from a bare checkout cannot compile:
   `gen_ui_ffi`'s `mod frb_generated;` is auto-injected by flutter_rust_bridge and the
   generated file is not committed (E0583 on every run, incl. main). Added the codegen
   step the Mobile job already had — plus `flutter-action`, because codegen shells out to
   `flutter --version` and formats the Dart it emits. Verified by running codegen with a
   Flutter-free PATH: "Dart/Flutter toolchain not available".
2. **Desktop job, part 1 — FIXED.** `pnpm/action-setup` ran with no version and the repo
   has no `packageManager` field → "No pnpm version is specified", every run. Pinned.
3. **Desktop job, part 2 — PARTIALLY FIXED (12 errors → 3).** The `file:` sibling
   packages (`gen-ui-react`, `tauri-plugin-gen-ui/guest-js`) publish their types from
   `dist/`, and **pnpm hard-copies a `file:` dep at install time** — so installing before
   those packages are built snapshots them WITHOUT `dist/`, and no later build can fix it.
   Order is load-bearing: build siblings, THEN install. Verified end-to-end from a clean
   `node_modules`.
4. **`@flint/react` — UPSTREAM, NOT FIXABLE HERE.** It is a git dep
   (`Know-Me-Tools/flint-forge#1cae090`, `path:packages/flint-react`) whose package.json
   declares `files: ["dist", "SKILL.md"]` and `types: ./dist/index.d.ts`. The fetched
   package contains **only package.json and SKILL.md** — no `dist/` (not prebuilt in the
   repo) and no `src/` (excluded by `files`). It is therefore structurally unusable as a
   git dep: nothing to import, nothing to build from. Fixing it means changing
   flint-forge (commit a built `dist/`, add `src` to `files`, or publish to a registry).
   3 residual tsc errors, all from this one module. NOT worked around here — a stub or a
   `skipLibCheck` hack would hide a real packaging defect in another repo.

### 2026-07-16 — C-105 execution: the fork does not work as planned (evidence-backed)
- **CORRECTION to the 2026-07-15 inference decision**: that entry recorded mistral.rs
  (GQAdonis fork) as the C-105 native lane on the strength of "crates verified". Building
  and *running* it found the fork unusable as-pinned without two fixes. Recording this
  because the earlier entry reads as more settled than it was — crate-existence is not
  build-verification, and neither is build-verification run-verification.
- **PIN**: mistralrs @ `b7746a85cb2e78fb2cf11cfb6ea9abd0a167d1f3` (Rule 22). MSRV 1.88,
  clears our 1.95 floor.
- **FIX 1 — the fork's own crates do not compile together.** It declares
  `safetensors = "0.7"`, but the candle fork it tracks by floating `branch = "main"` has
  moved to `"0.8"` — semver-incompatible, so `candle-core::Dtype` stopped unifying with
  `mistralrs-quant`'s (E0308). Resolved with the fallback the fork's OWN Cargo.toml
  documents: `[patch]` candle → upstream `huggingface/candle` rev `5404348` (verified:
  declares 0.7). Side benefit: removes a floating branch ref from our graph.
- **FIX 2 — regex conflict.** mistral.rs (via serde-saphyr) needs `regex <1.13`; the lock
  held 1.13.1 (pulled by liter-llm as a loose `^1`). Pinned 1.12.4 — satisfies both lanes.
- **DECISION (reverses the plan) — Q4_K_M → Q4_0.** The plan named Qwen2.5-1.5B **Q4_K_M**.
  It produces garbage on this fork. Isolated by driving mistral.rs's own API directly,
  bypassing all our code:
    Qwen2.5 Q4_K_M → repetition loop | Qwen2.5 Q5_K_M → garbage
    Qwen2.5 Q4_0 → "Hello" ✓ | Qwen2.5 Q8_0 → "Hello" ✓ | TinyLlama Q4_K_M → "Ho!" ✓
  So: Qwen-architecture-specific K-quant dequantization, almost certainly the same candle
  skew as FIX 1 (the patch made it compile; the quant kernels are still mismatched).
  Ships **Q4_0** (same ~1GB class). Re-test K-quants on any candle/mistral.rs bump.
  Provenance: measured, not recalled.
- **FIX 3 — `top_k`.** `RequestBuilder::new()` defaults to `SamplingParams::deterministic()`
  → `top_k = 1` (greedy), silently overriding temperature/top_p. `SampleParams` is frozen
  and carries no top_k, so the lane sets `DEFAULT_TOP_K = 40` explicitly.
- **FIX 4 (pre-existing, C-103) — the desktop A2UI wire contract was broken.** The plugin
  emits `A2uiEvent` verbatim (`{"type":"block"}` / `{"type":"run_finished"}`), but
  `driver.ts` switched on `contentBlock`/`messageComplete` — matching neither, so the
  desktop lane rendered NO streamed response and had not since C-103. An `as never` cast
  hid it from tsc. Added `createA2uiWireAdapter` + 5 tests over that contract.
- **PROCESS LESSON**: the T12 live test initially PASSED on the Q4_K_M garbage, because it
  only asserted `!text.is_empty()` — which a well-formed stream of nonsense satisfies. A
  test that cannot fail on garbage verifies nothing. It now asserts the answer doesn't
  echo the prompt, isn't a repetition loop, and actually greets.
- **DECISION — commit dependency lockfiles.** `apps/knowme-poc/.gitignore` had a blanket
  `*.lock` that silently dropped `Cargo.lock`/`pubspec.lock`/`Podfile.lock`. Cargo.lock is
  the ONLY pin holding mistral.rs's floating `turboquant-rs#main` to a reviewed SHA, and it
  carries the regex resolution above — without it CI re-resolves and breaks. Rule narrowed
  to genuine build-tool scratch locks (Gradle, build_runner).
- **Open**: T12c (WebLLM generation in a real browser) — probe confirmed WebGPU, module
  import, HF reachability, and that the model id is in the live catalog, but
  `CreateMLCEngine` stalls in the automated pane without fetching. Not claimed as verified.

### 2026-07-16 — C-113 mobile navigation: the premise was wrong; one convention, no detection
- **RESEARCH (T1, sourced from live pages — WebFetch returned JS shells, re-fetched via
  Firecrawl; every claim below is quoted guidance, not recall):**
  - iOS HIG, *Tab bars*: a tab bar "lets people navigate between **top-level sections**"
    and "floats above content at the **bottom of the screen**". Top-placed tab bars on
    iPhone aren't discouraged — they're never contemplated. The explicit prohibition is
    about purpose, not position: "Use a tab bar to support navigation, not to provide
    actions." No hard tab count; "avoid overflow tabs"; ≤5 only as iPad-customization
    guidance.
  - M3, *Navigation bar*: "always placed at the **bottom**"; "**three to five**
    destinations"; "On mobile or tablet, navigation bars should be used for **top-level
    destinations**"; <3 destinations → use tabs; >5 → tabs or a modal rail.
  - M3, *Tabs*: "primary tabs are placed at the **top** of the content pane under an app
    bar"; "tabs organize groups of **related content at the same level of hierarchy**".
- **CORRECTION — the C-113 proposal's premise is false.** It states the platforms
  "disagree" about top-vs-bottom. They do not. On phones both converge on **bottom**
  placement for top-level destinations. M3's own decisive line: "**Use navigation for
  distinct pages and tabs for related content within a page**" — Android's top tabs are a
  *different component for a different purpose* (in-screen content switching), not a rival
  placement for app-level navigation. M3 illustrates tabs living *inside* a nav-bar
  destination. Provenance: sourced research, contradicting the proposal's framing.
- **DECISION (T2) — mobile web/PWA uses ONE convention: bottom navigation, no platform
  detection.** Rationale, in order of weight:
  1. It follows from the convergence above — a single bottom nav satisfies **both** HIG and
     M3 phone guidance simultaneously, so "adaptive" would buy nothing.
  2. **No authority exists** for the adaptive alternative. web.dev's PWA *App design*
     chapter (the closest candidate) doesn't address navigation placement at all; its only
     platform-adaptation advice is cosmetic, and it is internally inconsistent (icons
     platform-*agnostic*, fonts platform-*native*). Recording the negative result rather
     than citing something weak.
  3. Reliable OS detection on the web is UA-sniffing — fragile, and Client Hints
     deliberately reduce the signal. Adaptive nav means shipping and testing two nav trees
     keyed off an unreliable input, for no guidance-backed benefit.
  Satisfies the user's directive that the PWA rule be a single deliberate choice.
- **QUALIFICATIONS (recorded so this isn't over-read):**
  - The real divergence is **by form factor, not by OS**. Apple moves the tab bar to the
    **top** on iPadOS; M3 swaps the bottom bar for a **rail** at expanded widths. Both
    abandon bottom placement as windows widen — they differ on what they move *to*. The
    decision above is scoped to **phone-width** top-level navigation.
  - M3 also says primary tabs "display the app's main content destinations", so the
    tabs-are-never-navigation split is a simplification of M3's actual wording. The
    convergence claim holds firmly at phone width; don't generalize past it.
- **STATE FOUND**: Flutter already ships a bottom M3 `NavigationBar` (3 destinations:
  Chat/Notes/Memory) — already conformant, no change needed. The **React surface has no
  navigation at all** (single `/` route → ChatScreen), so C-113's React/PWA work is
  greenfield, not a retrofit.
- **USER RATIFIED (2026-07-16)**: both the T2 rule (one convention — bottom nav, no
  platform detection) and the T5 scope (React matches Flutter's 3 destinations, responsive:
  bottom nav at phone width, desktop-appropriate layout above it, since Tauri desktop
  shares the bundle and both HIG/M3 abandon bottom placement as windows widen).
  Provenance: user.

## C-111 follow-up: graph_expand root cause found (2026-07-16)

- **BUG CLOSED**: `graph_expand` returned `[]` because `relate()` never wrote real edges.
  The C-111 note framed this as either/or — edges not persisted **or** traversal not
  reading them back under 3.2. It was the first. **The traversal query was correct all
  along** and needed no change.
- **ROOT CAUSE**: `RELATE entity:⟨$from⟩->relates_to->entity:⟨$to⟩`. The `⟨ ⟩` chevrons
  are SurrealDB's escaped-**IDENTIFIER** syntax, not parameter interpolation, so every
  edge was written between two junk records literally keyed `$from`/`$to`.
  - Live probe: `SELECT * FROM relates_to` → `in: entity:$from`, `out: entity:$to`.
  - Source (surrealdb-core-3.2.1): `syn/lexer/char.rs:16` lexes `⟨` as a surrounded
    ident; `syn/parser/record_id.rs::parse_record_id_key` has **no `$param` arm** — its
    default arm returns `RecordIdKeyLit::String(ident)` verbatim.
- **FIX**: parenthesize the endpoints —
  `RELATE (type::record('entity', $from))->relates_to->(type::record('entity', $to))`.
  Per `syn/parser/stmt/relate.rs::parse_relate_expr`, endpoints accept a bare `$param`
  or a parenthesized expression; a *bare* `type::record(...)` falls through to
  `parse_record_id` and dies on `::` — which is what drove the original chevron
  workaround. Parens chosen over `LET`-bound params: one statement, matches the
  `type::record` idiom already used across store.rs.
- **WHY IT HID**: `relate()` calls `.query().await?` and never checks
  `Response::take_errors()`. SurrealDB reports statement failures per-statement, not as a
  query-level `Err`, so `relate()` structurally cannot report a failed write — it wrote
  plausible garbage and returned `Ok`. `init()` already guards this correctly. Spawned as
  follow-up work (audit the other `.query()` sites in store.rs/config.rs the same way).
- **`#[ignore]` REMOVED** from `graph_expand_traverses_relate_edges`; test unweakened.
- **METHOD NOTE**: two moves beat guessing at 3.x syntax — probe the live DB and read
  the `in`/`out` keys, and read surrealdb-core's parser source (its own error text names
  the sanctioned route). Recorded in the wiki as
  `surrealdb-relate-endpoints-need-parenthesized-type-record`.
- **VERIFIED (2026-07-16)**: `cargo test -p gen_ui_db_graph --test it` →
  `5 passed; 0 failed; 0 ignored`. `graph_expand_traverses_relate_edges` passes with the
  `#[ignore]` removed and no assertion weakened (the `0 ignored` count is the proof the
  test actually ran rather than being skipped). The memory lane's 4 tests — including the
  concurrent session's new `vector_mode_returns_scored_hits` — stay green alongside it.
