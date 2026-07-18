# WASM Extensibility & Decentralized Packaging — Research Brief

**Slug:** `wasm-extensibility-packaging`
**Researcher:** KNOWME_RESEARCHER (web research track)
**Date:** 2026-07-18
**Scope:** (a) WebAssembly Component Model / WIT / WASI 0.2–0.3 / Wasmtime embedding (incl. mobile) / Extism / wasmCloud / Spin / capability sandboxing / resource limits / wasm registries (OCI, ORAS, warg); (b) browser-side wasm plugins and settings-schema exposure patterns; (c) decentralized packaging/versioning (IPFS, iroh, gitoxide, Radicle, IPLD) and a recommended packaging standard for the KnowMe/Flint platform.
**Master-goal lens:** local-first + realtime platform where pglite (web) and pglite-oxide (Tauri) clients sync via flint-realtime-fabric to flint-forge postgres; WASM component model provides agent-harness skills, A2UI/AG-UI/HTMX UI modules, and settings schemas with synced client/server storage; decentralized distribution via IPFS or git-like Rust versioning.

---

## 0. Executive Summary

- The **WebAssembly Component Model is now the default path**, not an experiment: WASI 0.2 (2024-01-25) has been stable ground for 2.5 years, **WASI 0.3 was ratified 2026-06-11** adding native async (`future<T>`/`stream<T>`), and the Bytecode Alliance published *"The Road to Component Model 1.0"* on 2026-06-08. Wasmtime is a Bytecode Alliance Core Project with LTS releases; Wasmtime 45.0.0 (2026-05-21) added initial async support; **flint-forge already embeds wasmtime 46 with the component API** (`wasmtime::component::{Component, Linker}`, `wasmtime-wasi`, `wasmtime-wasi-http::p2`, epoch interruption).
- **The registry story flipped in 2025**: the warg reference registry was **archived 2025-07-28**; the ecosystem converged on **OCI artifacts via `wkg`/`wasm-pkg-tools`** (components publish to GHCR/Docker Hub/ECR; `config.mediaType: application/vnd.wasm.config.v0+json`, layer `application/wasm`). flint-forge's `fke-store-oci` is aligned with the winning horse.
- **Mobile is feasible but constrained**: iOS forbids JIT, so Wasmtime's **Pulley interpreter** (stable backend since 2024, default on non-Cranelift platforms since Wasmtime 29, 2025-01-20) is the mobile path; WAMR (~50–426 KB footprint, iOS/Android) is the ultra-light alternative. App Store guideline 2.5.2 (downloaded executable code) is a policy risk for consumer app-store plugin delivery.
- **Browser plugins**: browsers still lack native Component Model support; the practical routes are **jco transpile** (canonical JS path, jco 1.24.x) or **Extism's js-sdk** (core modules + WASI, runs in Web/Node/Deno/Bun). VS Code's `ms-vscode.wasm-wasi-core` + `@vscode/wasm-wasi` is the best production exemplar of WASM extensions in a web host.
- **Settings schemas**: VS Code's `contributes.configuration` (JSON Schema subset, scopes, no `$ref`) is the canonical declarative-settings pattern; Zod v4 has native `z.toJSONSchema()` (`zod-to-json-schema` deprecated Nov 2025); Rust side uses `schemars`; render with RJSF or JSON Forms on web. Obsidian/JetBrains are imperative — do not copy them.
- **IPFS in 2026**: Kubo is alive and much improved (Shipyard's 2025 year: Kubo 0.33–0.39, Provide Sweep default in 0.39, AutoTLS via `registration.libp2p.direct`, Helia v6). **rust-ipfs is dead** (archived 2022-10-23). The viable Rust strategies are: Kubo HTTP API server-side (exactly what flint-forge `fke-store-ipfs` does), or **iroh-blobs** (BLAKE3/bao-tree verified streaming over QUIC, redb store, `BlobTicket`s) embedded natively — iroh reached **1.0.0-rc** in 2026.
- **gitoxide** (gix 0.55) is mature enough as a library substrate (clone/fetch/push/merge implemented; production-tier crates `gix-lock`, `gix-tempfile`, `gix-ref`, `gix-config`…). **Radicle** (1.6.1, 2026-01-21) is a sovereign Git forge, useful as a distribution mirror, not a package registry.
- **Recommendation**: adopt a **Flint Component Package** standard — OCI artifact as canonical transport + content-addressed P2P mirrors via iroh-blobs (LAN/offline/WebRTC-adjacent) + Kubo for IPFS interop + a warg-inspired signed append-only release log per package + cosign/DID signing (already `fke-sign-cosign`/`fke-sign-did`) + a manifest carrying WIT world pin, settings JSON Schema, capabilities, and UI-module metadata.

---

## Part A — The WebAssembly Component Model and WIT (2025–2026)

### A.1 What exists (facts)

| Milestone | Date | Source |
|---|---|---|
| WASI 0.2 (Preview 2) stable | 2024-01-25 | bytecodealliance.org, wasi.dev |
| Wasmtime LTS program (2-year security maintenance) | 2025-04-22 | wasmhub.dev state-of-wasm-2026 |
| Wasmtime promoted to first Bytecode Alliance Core Project | 2025-04-30 | wasmhub.dev |
| **warg registry archived** | 2025-07-28 | github.com/bytecodealliance/registry |
| Wasm 3.0 became W3C standard (WasmGC, exn handling, tail calls, memory64…) | Sept 2025 | javacodegeeks.com 2026-02-25; platform.uno 2026-01-19 |
| Spin v3.5 ships first WASI 0.3 RC | Nov 2025 | dev.to/fermyon, javacodegeeks 2026-04-27 |
| Fermyon joins Akamai | Dec 2025 | iotdigitaltwinplm.com 2026-06-19 |
| Wasmtime 45.0.0: initial async, copying GC; requires Rust 1.93 | 2026-05-21 | wasmhub.dev |
| *"The Road to Component Model 1.0"* published | 2026-06-08 | wasmhub.dev |
| **WASI 0.3 ratified** (native async via `future<T>`/`stream<T>`) | 2026-06-11 | wasmhub.dev |
| Spin 4.0.1 (manifest v3; WASIp3 opt-in since 3.5) | 2026-06-09 | wasmhub.dev |
| wasmCloud 2.3.0 (CNCF Incubating; WASIp3 in `wash-runtime`; `wasi:tls` in production) | mid-2026 | wasmhub.dev |
| WASI 1.0 (full ratification) planned | late 2026 / early 2027 | platform.uno 2026-01-19; dev.to/instatunnel 2026-04-04 |

Key links:
- WASI spec hub: <https://wasi.dev/> (accessed 2026-07-18) — "To date, WASI has seen three milestone releases: 0.1, 0.2, and 0.3."
- Component Model docs: <https://component-model.bytecodealliance.org/>
- WASI repo (S authority): <https://github.com/webassembly/wasi> — "WASI 0.3 (Preview 3) is the current preview… replacing explicit streams and polling with the component model's native, composable `async`."
- State of WebAssembly 2026: <https://wasmhub.dev/blog/state-of-webassembly-2026> (2026-06-16)
- Uno Platform, "The State of WebAssembly – 2025 and 2026": <https://platform.uno/blog/the-state-of-webassembly-2025-2026/> (2026-01-19/27)
- Fermyon, "What's The State of WASI?": <https://dev.to/fermyon/whats-the-state-of-wasi-2ofl> (2025-05-16)

### A.2 How it works

- **WIT (Wasm Interface Types)** is the IDL: packages (`namespace:name@version`) declare interfaces, `world`s bundle imports/exports into a target contract. Rich types (strings, records, variants, resources, and in 0.3 `future<T>`/`stream<T>`) cross language boundaries with canonical-ABI lowering/lifting — no HTTP/serialization microservice overhead.
- **Toolchain per language (2026)**: Rust → `cargo-component` 0.21.x (component output is *cargo-component's* job, not `wasm-pack`'s); JS → `componentize-js` / `jco` 1.24.x (transpile, host, run); Python → `componentize-py` 0.24; C#/.NET → `componentize-dotnet`; MoonBit etc. via `wasm-tools component embed` + `wasm-tools component new`.
- **WASI 0.3 async** avoids function coloring: async imports connect to sync-exported functions; `wasi:http@0.3.0` needs 5 resource types vs 11 in 0.2.4 (javacodegeeks 2026-02-25). Go has a formal proposal for `GOOS=wasip3` (dev.to/instatunnel 2026-04).
- **Composition**: components link by imports/exports; hosts provide only the interfaces a component imports (typed capability surface). `wasm-tools compose` / `wac` for static composition.

### A.3 Runtimes and embedding

**Wasmtime** (Bytecode Alliance, Rust):
- Embedding docs incl. minimal builds for custom platforms: <https://docs.wasmtime.dev/examples-minimal.html> (2024-12-12) — disable default features, `*.cwasm` precompiled artifacts, `wasmtime-platform.h` symbols for unknown platforms.
- flint-forge already embeds **wasmtime 46**: `use wasmtime::component::{Component, HasSelf, Linker, ResourceTable}; use wasmtime_wasi::{WasiCtx, WasiCtxBuilder, WasiCtxView, WasiView}; use wasmtime_wasi_http::p2::…` (`crates/fke-runtime/src/lib.rs:55-62`), epoch-interruption trap detection (`is_epoch_trap`, lib.rs:456), and a first-class `CompilerBackend` config dimension keyed by `(source_digest, target_arch, wasmtime_version)` for AOT caching (`crates/fke-domain/src/lib.rs:62-80`). Wasmtime 46 made async support default (comment at fke-runtime lib.rs:135).
- **Pulley** — Wasmtime's portable bytecode interpreter ("Portable, Universal, Low-Level Execution strategY"): stable backend since 2024; **default on platforms Cranelift doesn't support since Wasmtime 29 (2025-01-20)**; explicitly aimed at iOS, W^X-constrained embedded, no-JIT policies. Security hardening analysis: <https://www.systemshardening.com/articles/wasm/wasmtime-pulley-interpreter-security/> (2026-05-08) — notes three Pulley-specific advisories in 2025, bytecode validation is `wasmparser`'s job, and fuel/epoch limiting is *more* critical under interpretation. Crate: `pulley-interpreter` (~240 K downloads/mo; lib.rs/crates/pulley-interpreter).
- Performance note: interpreter ≈ 2–10× slower than Cranelift JIT; on mobile, pair Pulley with AOT-`.cwasm` where policy allows.

**Other runtimes** (runtime survey, withbighair.com 2025-05-11):
- **WAMR** (Intel/Bytecode Alliance): ~29–59 KB AOT runtime; iOS, Android, FreeBSD, Zephyr…; production at Amazon Prime Video/Xiaomi scale; no Component Model yet (WASI p1 focus). <https://github.com/bytecodealliance/wasm-micro-runtime>
- **Wasmer 7.x**: defaults to WASI 0.2, WASIX superset on top (wasmhub.dev).
- **WasmEdge** (CNCF, C++): edge/cloud focus, own extensions.
- **Chicory** (pure-Java, JVM): Extism's suggested route for Android.

**Spin / wasmCloud / Extism**:
- **Spin 4.0.1** (2026-06-09): manifest v3, WASIp3 opt-in; SpinKube accepted to CNCF sandbox Jan 2025; Fermyon→Akamai Dec 2025. Good server-side component DX (spin.toml, triggers), but a server framework, not an embedding library.
- **wasmCloud 2.3.0** (CNCF Incubating): distributed lattice over NATS, capability providers, `wash`; WASIp3 in `wash-runtime`, `wasi:tls` in production. wasmCloud Q1 2025 roadmap: <https://wasmcloud.com/community/2025-01-15-community-meeting/>.
- **Extism** ("the framework for building with WebAssembly"): core-module (not full Component Model) plugin ABI over JSON/msgpack with host functions; SDKs for Rust, JS (Web/Node/Deno/Bun), Go, Python, Java, .NET, Zig, C…; CLI 1.6.2 current (May 2026). **Helm 4 adopted Extism as its plugin sandbox** (HIP-0026, <https://helm.sh/community/hips/hip-0026/>, Helm v4.0.0 Nov 2025) — the strongest third-party validation of Extism as "the most mature and well-supported Wasm plugin system today". <https://github.com/extism/extism>

### A.4 Capability-based sandboxing and resource limits

The 2025 security model (safeguard.sh 2025-11-05, "WebAssembly WASI Security Model in 2025"): core-wasm sandbox (linear memory, structured control flow) + WIT typed boundaries + WASI capability APIs + host-supplied imports only.
- **WASI capabilities are structural**: a component that imports `wasi:http/outgoing-handler` but not `wasi:filesystem` cannot touch the filesystem; the host (`WasiCtxBuilder`) grants preopens, env, sockets, HTTP selectively. Deny-by-default linking.
- **Resource limits in Wasmtime**: `Config::consume_fuel(true)` + `Store::set_fuel` (instruction metering), `Config::epoch_interruption(true)` + `Engine::increment_epoch` (deadline preemption — flint-forge already detects epoch traps), `StoreLimits`/`StoreLimitsBuilder` via `Store::limiter` (linear memory/table caps), pooling allocator (`PoolingAllocationConfig`) for dense multi-tenant instances, `Config::memory_reservation`/`memory_guard_size` tuning.
- Pulley-specific: interpreter loops tighten, so a runaway module steals more host CPU/sec; three Pulley advisories landed in 2025 (systemshardening.com 2026-05-08).
- Supply-chain side: wasm binaries are small (1–5 MB vs 50–500 MB OCI images — flint-forge's own `research-wasm-sandboxing-comparison.md` notes the registry must accommodate both artifact types).

### A.5 How registries distribute wasm

- **warg**: federated, transparency-log ("package transparency" à la Certificate Transparency), content-storage-agnostic registry protocol; ECDSA-P256 signing keys in OS keychain; namespaces federate. Reference impl at github.com/bytecodealliance/registry — **archived 2025-07-28**. The protocol lives on at **wa.dev** (community warg registry; publish via `warg publish --registry wa.dev`; zenn.dev walkthrough 2025-12-28). Do not build new infrastructure on warg-the-implementation; its *ideas* (signed append-only package logs, transparency) remain worth copying.
- **OCI artifacts** (the winner): `wasm-pkg-tools` / `wkg` (<https://github.com/bytecodealliance/wasm-pkg-tools>) fetch/publish components and WIT packages to any OCI registry (GHCR, Docker Hub, ECR, Harbor). Media types: config `application/vnd.wasm.config.v0+json` (embeds component imports/exports/`target` — searchable metadata!), layer `application/wasm`, `architecture: "wasm"`, `os: "wasip2"`. Walkthrough: Microsoft Open Source blog, "Distributing WebAssembly components using OCI registries" (2024-09-25). `wkg` config via `/.well-known/wasm-pkg/registry.json` (`preferredProtocol`, `warg.url`, `oci.registry`+`namespacePrefix`). wasmCloud deprecated `wit-deps` for `wkg` in wash v0.36 (2024-11-08).
- **ORAS**: the general OCI-artifact plumbing (`oras push/pull`); `wasm-to-oci` (engineerd, 2019) is historical; Helm 4's roadmap includes plugins as OCI artifacts via ORAS conventions.
- **wasi.dev namespace packages** live at `ghcr.io/webassembly/wasi/http:0.2.1` style refs — proving the GHCR-backed public namespace pattern.

### A.6 Implications for the master goal

1. **Plugin ABI**: the Component Model + WIT is the correct contract for "native skills for agent harnesses, A2UI/AG-UI/HTMX UI modules, settings schemas". One WIT world per extension point; `gen_ui_core`/flint hosts implement the imports; untrusted code runs as components. flint-forge's `wit/flint/host/world.wit` + `fke-runtime` is already this shape — keep it pinned to WASI p2 worlds and track p3 behind a feature flag (wasmCloud does exactly this gating).
2. **Runtime placement**: server/Tauri desktop → wasmtime (Cranelift); iOS/Android → wasmtime+Pulley or WAMR; web → jco-transpiled components or Extism core modules. Design host bindings so the *same* component runs in all three where feasible (pure compute components), with platform-specific host capabilities declared as separate WIT interfaces.
3. **Distribution**: OCI-first is settled — `fke-store-oci` + `wkg`-compatible well-known metadata makes Flint packages installable by standard tooling and mirroring trivial (any Harbor/GHCR/S3-backed registry).
4. **Version pin discipline**: the wasmtime 45→46 API churn (async default, error types) shows the host-embedding API is still moving; isolate behind `fke-runtime`'s existing abstraction and record `wasmtime_version` in the compile cache key (already done in `fke-domain`).

### A.7 Gaps/risks (Part A)

- Component Model 1.0 not yet ratified; WIT/world versioning churn possible until ~2027.
- Browsers have **no native Component Model** — JS glue via jco adds size/complexity; WASI shims in-browser are partial.
- iOS: no JIT (Pulley interpreter perf), and **App Store guideline 2.5.2** restricts downloading executable code — consumer-app plugin marketplaces on iOS carry store-review risk; enterprise/TestFlight or in-app-bundled components are safer.
- WASI 0.3 async is weeks old (ratified 2026-06-11); runtime support is "initial/experimental" (Wasmtime 45+, Spin 3.5+ opt-in) — target 0.2 worlds for production now.
- No standardized threads in WASI yet; multi-threaded guest code remains limited.

---

## Part B — Browser-side WASM plugins and settings-schema exposure

### B.1 Browser-side wasm plugin patterns (what exists)

- **VS Code WebAssembly Extension Host** — the best production exemplar. `ms-vscode.wasm-wasi-core` supplies the wasm execution engine wiring WASI to the VS Code API; extensions load `.wasm` via `@vscode/wasm-wasi` (`Wasm.load()`, `wasm.createProcess(name, module, {stdio})`). Blogs: "Run WebAssemblies in VS Code for the Web" (2023-06-05) and "Using WebAssembly for Extension Development" (2024-05-08, component-model bindings generation between WIT and TS: `calculator._.imports.create(service, wasmContext)`). Sync-WASI-over-async-API bridging uses `SharedArrayBuffer`+`Atomics` in a separate worker — requires cross-origin isolation (`?vscode-coi=on`). <https://code.visualstudio.com/blogs/2024/05/08/wasm>
- **jco** (`@bytecodealliance/jco` 1.24.x): transpiles components to JS+core-wasm with WASI shims for browser/Node; canonical path for running real components in browsers today (wasmhub.dev).
- **Extism js-sdk**: runs Extism plugins (core modules + WASI) directly in browsers; simplest browser embedding story, no component model.
- **componentize-js / StarlingMonkey**: build JS code *into* components (SpiderMonkey-based) — relevant if KnowMe skills are authored in JS/TS and must run as components server-side too.
- Precedents: Figma/Shopify Functions-style "untrusted compute at the edge", Helm 4's wasm CLI/post-render plugins, sql.js/duckdb-wasm pattern of shipping heavy compute as wasm in-browser.

### B.2 Settings-schema exposure patterns (what exists)

**VS Code `contributes.configuration`** — the canonical declarative model (<https://code.visualstudio.com/api/references/contribution-points>, updated 2026-06):
- `package.json` contributes a **JSON Schema object**: `title`, `properties` keyed by dotted setting IDs, per-property `type`/`default`/`description`/`markdownDescription`, `enum`, `minimum/maximum`, `pattern`, `format` (date/ipv4/email/uri), `deprecationMessage`, `editPresentation`, `tags` (e.g. `usesOnlineServices`).
- **Scopes**: `application`, `machine`, `machine-overridable`, `window`, `resource`, `language-overridable` — machine-scoped values never sync. This maps directly onto KnowMe's "synced client/server storage": scope decides what CRDT-syncs vs stays local vs goes to the vault.
- Constraints worth copying: **no `$ref`/`definitions`** (schemas must be self-contained), simple object/array rendering rules; complex values fall back to JSON editing.
- Runtime read: `workspace.getConfiguration('myExtension')`.
- New in recent VS Code: `contributes.languageModelChatProviders[].configuration` — a JSON schema for provider settings with **`"secret": true`** marking for secure storage. Directly relevant to BYOK in the KnowMe plan.

**Schema-generation tooling**:
- **Zod v4**: native `z.toJSONSchema()`; the community bridge `zod-to-json-schema` was **deprecated Nov 2025** ("switch to the new major"; npm page, v3.25.2 published ~June 2026). No official `fromJSONSchema` (open issue colinhacks/zod#5233, 2025-09-13) — so JSON Schema → runtime validator needs `json-schema-to-zod` or ajv.
- **Rust**: `schemars` (`#[derive(JsonSchema)]`, `schema_for!`) — server-side single source of truth; emit schemas from the same Rust types flint-forge already stores. Experimental `schemars-zod` exists for Rust→Zod codegen.
- **Form renderers**: **RJSF** (`react-jsonschema-form`, `@rjsf/core` + `@rjsf/utils`, theme packs for MUI/antd/Chakra/Bootstrap/shadcn-ish custom themes) — actively maintained, v6 line; **JSON Forms** (`@jsonforms/core/react`, renderer sets, rules engine for show/hide); **Angular**: `ngx-formly`; Svelte community options. VS Code itself renders settings UI from the same schema — proof the pattern scales to thousands of settings.
- **Obsidian**: settings are imperative — plugins build DOM via `PluginSettingTab`/`Setting` API; `manifest.json` declares only id/name/version/minAppVersion. No declarative schema → don't copy.
- **JetBrains**: `PersistentStateComponent` + `Configurable` (imperative Kotlin UI); `plugin.xml` extension points. Also imperative.
- **Home Assistant / Backstage / JupyterLab**: all use JSON-Schema-ish config declarations (HA `config_flow` + selectors; Backstage `config.d.ts` JSON Schema; JupyterLab setting registry uses JSON Schema files per plugin) — JupyterLab is a second strong precedent for schema-file-per-plugin.

### B.3 Implications for the master goal

1. **Declare settings in the package manifest as a VS Code-style JSON Schema subset** (self-contained, no `$ref`, scopes extended with `sync` semantics: `synced` (CRDT via flint-realtime-fabric), `local` (pglite/pglite-oxide only), `secret` (vault/flint-gate, never synced)). This one declaration drives: web settings UI (RJSF/JSON Forms), Tauri settings UI, server validation (schemars-derived Rust types), and agent-facing introspection (MCP tools that read/write settings).
2. **Browser plugin sandbox**: adopt the VS Code worker+SAB pattern or Extism js-sdk for untrusted UI-adjacent compute; require cross-origin isolation on the web shell. Keep HTMX/A2UI modules declarative (JSON component trees) so most "UI modules" never need wasm at all — wasm is for *skills/compute*, JSON is for *UI*.
3. **Schema provenance**: generate JSON Schemas server-side from Rust (`schemars`) and client-side from Zod v4 where TS owns the type; store the schema *inside* the component package so registry, client, and agent all validate against the same artifact.

### B.4 Gaps/risks (Part B)

- No cross-framework schema-driven settings standard exists; you will write one thin convention (VS Code subset + sync scopes) — low cost, high leverage.
- RJSF custom-widget integration has a learning curve; budget for a shadcn renderer set (none official as of 2026).
- ajv draft-2020-12 support vs VS Code's draft-07-ish subset: pin one draft (2020-12) and lint package manifests against it.
- Secret handling must bypass CRDT sync entirely — the sync layer will happily replicate anything you hand it.

---

## Part C — Decentralized packaging and versioning

### C.1 IPFS ecosystem status in 2026

**Kubo — alive and substantially improved.** IPFS Shipyard (the Protocol Labs successor team) "2025 Year in Review" (<https://ipshipyard.com/blog/2025-shipyard-ipfs-year-in-review/>, 2025-12-19):
- Seven Kubo releases in 2025: **v0.33 → v0.39**.
- **Provide Sweep**: DHT provider system rebuilt; 97% fewer lookups when providing many CIDs; hundreds of thousands of CIDs on residential connections; experimental in 0.38, **default in 0.39** — "update to Kubo 0.39 or later."
- **AutoTLS**: automatic WSS certs via `registration.libp2p.direct` (opt-in 0.33, default 0.34) — browsers can connect to home nodes.
- Gateway resource protection (504/429) in 0.37; diagnostic error pages 0.38; CDN-friendly range handling 0.39.
- **Delegated routing** (`someguy`, `delegated-ipfs.dev`) for browsers/mobile that can't run DHT; IPIP-476 closest-peers API; HTTP block providers enabling trustless-gateway retrieval over plain HTTPS.
- Helia v5.2→v6 (JS), `@helia/verified-fetch` v3→v5 (in-browser content verification), service-worker-gateway v2.1, Rainbow (HTTP gateway saturn-style) v1.21, ipfs-cluster 1.1.5.
- **go-libp2p maintenance transitioned to the community** after Sept 2025 (Shipyard's final releases were v0.40–v0.42) — a governance risk note.

**rust-ipfs — dead.** <https://github.com/rs-ipfs/rust-ipfs> **archived 2022-10-23** ("Project Status: Not Maintained"; IPFS forum confirmation 2024-06). The listed alternatives are: `rust-ipfs-api` (HTTP client to a Kubo node — what flint-forge effectively reimplemented), `ipfs-embed` (sled-based, dormant), `rust-ipld` (basic codecs). There is **no maintained full IPFS node in Rust**. Options for Rust apps: talk to Kubo's HTTP API (`:5001/api/v0/...`), use Helia in JS contexts, or use iroh (below) which is Rust-native but is its own protocol family (not IPFS-compatible out of the box; `iroh` does content addressing without the public DHT/IPLD stack).

**flint-forge status check**: `crates/fke-store-ipfs/src/lib.rs` is already a **Kubo HTTP API adapter** (`StoreIpfs`, `FLINT_IPFS_URL`, default `http://localhost:5001`, `POST /api/v0/add`) — the correct, future-proof choice. Keep it.

**Security caveat**: IPFS DHT remains Sybil-attackable — active content-eclipse attack on recent Kubo with ~80% lookup denial, plus proposed SR-DHT-Store mitigation (arXiv:2505.01139v2, updated 2026-04-22). For a package registry, never rely on raw public-DHT discovery for integrity — content addressing + signatures cover integrity, but *availability/lookup* should use delegated routing, HTTP retrieval, and pinned mirrors.

### C.2 iroh blobs — the modern Rust alternative

<https://github.com/n0-computer/iroh> (S authority), <https://docs.rs/iroh> (updated 2026-07-01):
- **iroh**: dial-by-public-key QUIC connectivity with hole-punching + encrypted relay fallback (`Endpoint`, `Router`, ALPN dispatch; `EndpointId` = Ed25519 public key). Reached **1.0.0-rc** in 2026 (iroh-blobs 0.102 depends on `iroh =1.0.0-rc.1`).
- **iroh-blobs**: BLAKE3 content-addressed blobs, **bao-tree verified streaming** (range requests verified incrementally), request/response protocol over one QUIC stream; concepts: `Blob`, `Link` (32-byte hash), `HashSeq`, `BlobTicket` (addr+hash+format); stores: `MemStore`, redb-backed `fs-store` (redb 4.1). **Version caveat on crates.io: "this version of iroh-blobs is not yet considered production quality. For now, if you need production quality, use iroh-blobs 0.35"** — the 0.9x/0.10x line is a mid-migration API; pin carefully.
- **iroh-gossip**: pub/sub overlays light enough for phones — directly relevant to CRDT sync transport (and a better citizen over WebRTC-like constraints than a DHT).
- **iroh-docs**: eventually-consistent key-value store over blobs (authors/replicas, sync) — a ready-made CRDT-ish document layer if wanted.
- FFI bindings repo (`iroh-ffi`) for non-Rust hosts.
- Why it fits the master goal: native Rust (embeds in `gen_ui_core`/flint clients), works on LAN/offline (mdns address lookup), relay-assisted NAT traversal for global sync, BLAKE3 addressing matches content-addressed packaging, and the ticket model is exactly how you share a component release between devices.

### C.3 gitoxide — pure-Rust git

<https://github.com/GitoxideLabs/gitoxide> (S authority; repo renamed to GitoxideLabs org 2026-06):
- `gix` 0.55.0 current (Homebrew, 2026-05; MSRV rust 1.97). Entry crate `gix`; fine-grained plumbing crates.
- **Implemented**: clone, fetch, push, status, commit, merge (blobs/trees/commits), rebase plumbing, worktree checkout/stream, reset, object/ref/index/config read+write, commit-graph, pathspecs, revspecs, submodules, shallow, archive, blame (early).
- **Stability tiers**: production `gix-lock`, `gix-tempfile`; stabilization candidates `gix-ref`, `gix-config`, `gix-actor`, `gix-hash`, `gix-glob`, `gix-mailmap`, `gix-chunk`; most others "usable".
- Deliberate non-goals: not a drop-in `git` CLI replacement; sync I/O by design with interrupt hooks.
- Verdict: mature enough to build a **git-backed package index/version store** (source-of-truth release history, tags = versions, signed commits/tags) without libgit2's C dependency — important for iOS/Android/wasm32 targets where gitoxide's pure-Rust-ness wins.

### C.4 Radicle

- Heartwood (3rd protocol iteration): sovereign P2P forge; gossip replication + Git smart-HTTP; issues/patches stored as CRDT-ish data in special Git refs; identity via `did:key` delegates + threshold; Tor-compatible. LWN overview 2024-03-29.
- **1.6.1 released 2026-01-21** (FOSDEM 2026 talk + slides, <https://fosdem.org/2026/schedule/event/TMQZTP-radicle/>; ArchWiki updated 2026-05-25).
- Limitations (ArchWiki): web UI read-only, **no releases/packages** (git tags only), no kanban, **no package registries** — "you will have to use separate programs."
- Verdict: excellent *source* mirror/collaboration layer; not a component distribution mechanism. Optional integration later.

### C.5 IPLD / content addressing notes

- IPFS/IPLD: CID = multihash(+codec) over dag-pb/dag-cbor blocks; UnixFS for files; IPNS for mutable names (slow unless delegated). Heavy but maximally interoperable.
- iroh: BLAKE3 + bao-tree; simpler; no global DHT; tickets replace name resolution; better fit for app-scoped distribution.
- OCI: sha256 digests, manifest-addressed — already the packaging canonical form.
- Practical rule: **all three are content-addressed**; design the Flint registry so the *digest is the join key* across transports (OCI digest ↔ IPFS CID ↔ iroh `Hash`), with a manifest that records all representations. Multi-transport, one identity.

### C.6 What a git-like decentralized component registry in Rust should look like

Synthesis of the above (warg's ideas + gitoxide's substrate + iroh's transport + OCI's universality):

1. **Package identity**: `namespace:name` (warg/oci convention, e.g. `prometheus:content-block-markdown`), semver versions, WIT world pins for interface compatibility checks.
2. **Release log (the "git-like" part)**: per-package **append-only, signed log** of releases (init/release/yank entries — exactly warg's model), each entry referencing content digests. Store the log itself as a **git repository** (gitoxide-managed): commits = releases, tags = versions, signed tags/commits = publisher signatures. Transparency/mirroring = git fetch. This gives offline verification, cheap mirroring, and audit history with zero new crypto.
3. **Content storage**: blobs addressed by digest; canonical transport OCI (`wkg` media types); P2P mirrors via iroh-blobs tickets and IPFS/Kubo for public goods; S3/fs for enterprise (`fke-store-*` trait already abstracts this).
4. **Index/discovery**: a postgres-backed index in flint-forge (extends the existing A2UI registry spec's JSONB+embeddings model) plus a replicated git index repo for offline clients; vector search is a server-side luxury, not a sync requirement.
5. **Signing & trust**: cosign/sigstore for OCI (already `fke-sign-cosign`), DID-based signatures for offline/keyless-free verification (`fke-sign-did`), transparency via the git release log + optional Rekor anchoring when online.
6. **Offline install**: resolve from local mirror (iroh ticket / LAN peer / USB git bundle), verify signature + digest against the release log head you trust, install from content store. No central service required.
7. **Revocation**: yank entries in the log; clients refuse new installs of yanked versions but keep cached copies runnable (local-first ethics).

### C.7 Recommended packaging standard — **Flint Component Package (FCP)**

A concrete standard for distributing WASM components + agent skills + UI modules for the owner's platform:

**Package layout** (an OCI artifact, `wkg`-compatible):

```
config:  application/vnd.wasm.config.v0+json          # standard wasm config (imports/exports)
layers:
  application/wasm                                    # the component (single .wasm)
  application/vnd.flint.component.manifest.v1+json    # flint-component.json (below)
  application/vnd.flint.component.wit.v1+tar          # WIT package (world + deps)
  application/vnd.flint.component.assets.v1+tar       # optional: HTMX templates, A2UI fragments, icons, SKILL.md assets
annotations:
  org.opencontainers.image.source / .revision / .created
  sh.flint.signature = cosign bundle ref / DID sig
```

**`flint-component.json` manifest** (the heart):

```jsonc
{
  "apiVersion": "flint.sh/v1",
  "kind": "ComponentPackage",          // SkillPackage | UiModulePackage share the envelope
  "name": "prometheus:content-block-markdown",
  "version": "1.4.0",
  "world": "flint:host/extension@0.3.0",        // pinned WIT world
  "requires": { "host": ">=0.9 <2.0", "capabilities": ["wasi:http/outgoing-handler", "flint:kv/read"] },
  "settings": { /* VS Code-style JSON Schema, self-contained, no $ref;
                   each property annotated: "scope": "synced|local|machine|secret" */ },
  "ui": { "a2ui": "assets/a2ui.json", "htmx": "assets/templates/", "designTokens": "assets/tokens.json" },
  "skill": { "manifest": "assets/SKILL.md", "harness": ["claude-code", "kimi", "opencode"] },
  "digests": { "wasm": "sha256:…", "ipfs": "bafy…", "iroh": "blake3:…" },
  "signatures": [{ "kind": "did", "key": "did:key:z6Mk…", "sig": "…" }]
}
```

**Distribution planes** (multi-transport, digest-joined):
1. **Canonical**: OCI registry (GHCR/Harbor/ECR) — `wkg oci push/pull` compatible; `.well-known/wasm-pkg/registry.json` on `registry.flint.sh` pointing at both OCI and (optional) warg endpoints.
2. **P2P/local-first**: iroh-blobs tickets for device↔device and LAN/offline install (aligns with WebRTC/lora transport ambitions); Kubo HTTP API + delegated routing for IPFS-public mirroring of releases (`fke-store-ipfs` stays, add `Provide Sweep`-era Kubo ≥0.39 in deployment docs).
3. **Source/audit**: git release-log repos (gitoxide) mirrored to Radicle and GitHub; signed tags.
4. **Index**: flint-forge postgres (JSONB + embeddings per FLINT-A2UI-REGISTRY-SPEC) as the query/discovery layer over the above.

**Client behavior**:
- Tauri/web clients resolve `name@version` → manifest → pick best available transport (local iroh peer → LAN Kubo → OCI registry) → verify digest + signature → cache in content-addressed store (BLAKE3) → load via wasmtime (native) / jco-or-Extism (browser) → register settings schema into the settings service (sync rules per scope) → register A2UI/HTMX assets into the UI registry.
- Updates: watch release-log head (git fetch over iroh-gossip topic or plain HTTPS); prompt or auto-update per policy.

**Why this and not alternatives**: OCI alone = no offline/P2P story; IPFS alone = no maintained Rust node + DHT Sybil risk + operational heaviness; warg = archived reference impl (protocol ideas good, adoption dead); Radicle = source forge only. FCP takes the strongest piece of each and matches the crates flint-forge already has (`fke-store-oci/ipfs/s3/fs`, `fke-sign-cosign/did`, `fke-registry`, `fke-runtime`).

### C.8 Gaps/risks (Part C)

- **iroh API churn**: 1.0.0-rc era; iroh-blobs self-declares non-production on latest line (pin 0.35 for prod or budget migration work).
- **go-libp2p community maintenance transition** (post-Sept 2025) is a long-tail governance risk for the IPFS plane.
- **Public-DHT availability attacks** (arXiv:2505.01139): use delegated routing + pinned mirrors + HTTP retrieval; never integrity-by-DHT.
- **Two hash universes** (BLAKE3 vs SHA-256 vs IPFS multihash) require the manifest's digest map — build digest translation/verification tooling early.
- **wkg well-known discovery** assumes a domain you control; decentralized installs need out-of-band trust bootstrapping (first-use TOFU of publisher DIDs + transparency log).
- **Mobile app-store policy** (2.5.2) for downloadable executable plugins remains a distribution-policy risk independent of tech.
- **gitoxide gaps**: LFS unimplemented (`gix-lfs` is an idea-stage placeholder) — keep large blobs out of git; blobs belong in the content stores, only logs/manifests in git.
- **No existing standard covers "settings schema inside a wasm package"** — FCP's manifest is a small invention; socialize it as a flint-specific media type (that's fine — OCI annotations/media types are designed for this).

---

## Appendix — Source list (accessed 2026-07-18 unless noted)

1. WASI.dev introduction — https://wasi.dev/
2. WebAssembly/WASI repo — https://github.com/webassembly/wasi
3. "The State of WebAssembly in 2026" — https://wasmhub.dev/blog/state-of-webassembly-2026 (2026-06-16)
4. "The State of WebAssembly – 2025 and 2026" (Uno Platform) — https://platform.uno/blog/the-state-of-webassembly-2025-2026/ (2026-01)
5. "What's The State of WASI?" (Fermyon) — https://dev.to/fermyon/whats-the-state-of-wasi-2ofl (2025-05-16)
6. "WebAssembly in 2026…" (JavaCodeGeeks) — https://www.javacodegeeks.com/2026/04/webassembly-in-2026-where-it-has-landed-what-wasi-0-2-changes-and-why-java-and-kotlin-developers-should-pay-attention-now.html (2026-04-27)
7. "The WASM Component Model: Software from LEGO Bricks" — https://www.javacodegeeks.com/2026/02/the-wasm-component-model-software-from-lego-bricks.html (2026-02-25)
8. "No Install, No Risk: WebAssembly-Native Tunneling" (WASI roadmap accuracy) — https://dev.to/instatunnel/no-install-no-risk-the-rise-of-webassembly-native-tunneling-16b8 (2026-04-04)
9. "WebAssembly WASI Security Model in 2025" — https://safeguard.sh/resources/blog/webassembly-wasi-security-model-2025 (2025-11-05)
10. "WASI and the WebAssembly Component Model: Current Status" — https://eunomia.dev/blog/2025/02/16/wasi-and-the-webassembly-component-model-current-status/ (2025-02-28)
11. Wasmtime minimal embedding — https://docs.wasmtime.dev/examples-minimal.html
12. Wasmtime v29.0.0 release notes — https://newreleases.io/project/github/bytecodealliance/wasmtime/release/v29.0.0 (2025-01-20)
13. "Wasmtime Pulley Interpreter Security Hardening" — https://www.systemshardening.com/articles/wasm/wasmtime-pulley-interpreter-security/ (2026-05-08)
14. pulley-interpreter crate — https://lib.rs/crates/pulley-interpreter
15. WAMR — https://github.com/bytecodealliance/wasm-micro-runtime
16. Runtime choices for embedded wasm — https://withbighair.com/webassembly/2025/05/11/Runtime-choices.html (2025-05-11)
17. Extism — https://github.com/extism/extism ; Helm HIP-0026 — https://helm.sh/community/hips/hip-0026/ ; Extism embedding example — https://thejeshgn.com/2026/05/19/embedding-user-code-in-your-app-using-extism/ (2026-05-19)
18. wasmCloud Q1 2025 roadmap — https://wasmcloud.com/community/2025-01-15-community-meeting/
19. warg registry (archived) — https://github.com/bytecodealliance/registry (archived 2025-07-28); warg.io
20. wa.dev publishing walkthrough — https://zenn.dev/mizchi/articles/wasm-component-wadev?locale=en (2025-12-28)
21. wasm-pkg-tools / wkg — https://github.com/bytecodealliance/wasm-pkg-tools
22. "Distributing WebAssembly components using OCI registries" (Microsoft) — https://opensource.microsoft.com/blog/2024/09/25/distributing-webassembly-components-using-oci-registries/ (2024-09-25)
23. wasmCloud WIT package mgmt update — https://wasmcloud.com/blog/2024-11-08-update-to-wit-package-management-in-wasmcloud/ (2024-11-08)
24. VS Code wasm blogs — https://code.visualstudio.com/blogs/2023/06/05/vscode-wasm-wasi , https://code.visualstudio.com/blogs/2024/05/08/wasm
25. VS Code contribution points — https://code.visualstudio.com/api/references/contribution-points (updated 2026-06)
26. zod-to-json-schema deprecation — https://www.npmjs.com/package/zod-to-json-schema (notice dated Nov 2025); zod#5233 — https://github.com/colinhacks/zod/issues/5233 (2025-09-13)
27. IPFS Shipyard 2025 year in review — https://ipshipyard.com/blog/2025-shipyard-ipfs-year-in-review/ (2025-12-19)
28. rust-ipfs (archived) — https://github.com/rs-ipfs/rust-ipfs (archived 2022-10-23); status thread — https://discuss.ipfs.tech/t/status-of-rust-ipfs/18080
29. IPFS DHT Sybil attack paper — https://arxiv.org/abs/2505.01139 (v2 2026-04-22)
30. iroh — https://github.com/n0-computer/iroh , https://docs.rs/iroh ; iroh-blobs — https://lib.rs/crates/iroh-blobs
31. gitoxide — https://github.com/GitoxideLabs/gitoxide (gix 0.55.0, 2026-05)
32. Radicle — https://radicle.xyz , https://github.com/radicle-dev , FOSDEM 2026 — https://fosdem.org/2026/schedule/event/TMQZTP-radicle/ (1.6.1, 2026-01-21); LWN — https://lwn.net/Articles/966869/ (2024-03-29); ArchWiki — https://wiki.archlinux.org/title/Radicle (2026-05-25)
33. Local context inspected: `/Users/gqadonis/Projects/prometheus/flint-forge/crates/{fke-registry,fke-store-ipfs,fke-store-oci,fke-store-s3,fke-store-fs,fke-sign-cosign,fke-sign-did,fke-runtime,fke-domain}/`, `wit/flint/host/world.wit`, `docs/FLINT-A2UI-REGISTRY-SPEC.md`, `research-wasm-sandboxing-comparison.md`
