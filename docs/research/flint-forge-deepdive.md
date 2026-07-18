# Research Brief: flint-forge Deep-Dive — Postgres Backbone + WASM Extension Registry

**Slug:** flint-forge-deepdive
**Author role:** KNOWME_RESEARCHER (deep-research swarm)
**Date:** 2026-07-18
**Repo inspected:** `/Users/gqadonis/Projects/prometheus/flint-forge` (read-only; no files modified there)
**Lens:** How flint-forge serves as the central Postgres backbone and extension/component registry for a local-first + realtime KnowMe architecture (pglite/pglite-oxide clients syncing through flint-realtime-fabric to flint-forge; WASM component model for agent skills, A2UI/AG-UI/HTMX UI modules, settings schemas; decentralized component distribution).

---

## 1. What Exists (Facts)

### 1.1 Repo identity and status

Flint Forge is "the sovereign data & edge-compute plane of the Flint platform" — a Rust workspace that sits behind `flint-gate` (ingress/auth, Kratos/Keto/Cedar) and consumes `flint-realtime-fabric` (FRF: CDC, Iggy spine) to serve structured data, run in-database compute, and execute signed WASM edge functions (`README.md`, lines 1–15). The master spec is **RFC-FORGE-001** at `docs/FLINT-FORGE-SPEC.md`.

**Status:** README declares "v1.0-ready"; `docs/ROADMAP.md` marks **v1.0.0 (p15) Released** (Anvil stabilization, migration integrity, operator CLI, E2E/perf validation, Helm chart) and v1.1.0 in planning with 4 items (cloud k6 baselines, **publish SDK packages** — `packages/flint-react`, `packages/flint_genui`, `crates/flint-skill`, `forge-cli` to crates.io/registries, sqlx 0.9 upgrade, `cargo deny` gate). Note: `CLAUDE.md` is stale — it still says "Status: Scaffold… bodies are stubbed with `todo!()`" and claims pgrx 0.12/PG17 for ext-flint-auth, while README/code say all five pgrx extensions target **Postgres 18 with pgrx 0.18.1** (`README.md` lines 144–156).

Four subsystems (the forge metaphor: quarry → anvil → kiln):

| Subsystem | Flint name | Crate prefix | Role |
|---|---|---|---|
| REST/GraphQL DB API gateway | **Flint Quarry** | `fdb-*` | PostgREST-compatible REST + hybrid GraphQL over Postgres 18 |
| pgrx extension suite | **Flint Anvil** | `ext-flint-*` (`flint_*` in DB) | auth context, webhooks, in-DB LLM, secrets, metadata cache |
| WASM edge-function gateway | **Flint Kiln** | `fke-*` | Compile and run signed WASM Component Model functions |
| Shared core | Forge core | `forge-*` | `forge-domain` (pure types), `forge-identity` (JWKS/RlsContext), `forge-policy` (Cedar PEP), `forge-cli` (`forge` binary) |

Toolchain: Rust edition 2021, MSRV 1.96 (`rust-toolchain.toml`), Axum 0.8.8, Tokio, sqlx + deadpool-postgres, async-graphql 7, tonic 0.12, pgvector 0.4, **wasmtime 46**, arc-swap (`README.md` lines 175–178). CI gates: no `unwrap`/`expect` in libs, `clippy::pedantic -D warnings`, `#[non_exhaustive]` public enums, `#[repr(transparent)]` newtype IDs, no file >500 lines, never log JWTs/tenant IDs.

### 1.2 Hexagonal architecture

Layering is enforced at the Cargo dependency level (`README.md` lines 86–101):

```
forge-domain          Layer 0: pure types, serde only, zero infra deps
  ▲
forge-ports / *-app   Layer 1: trait seams (ports) + use-cases
  ▲
adapters              fdb-postgres, fdb-realtime, fke-store-*, fke-sign-*, …
  ▲
interface crates      fdb-gateway, fke-server  (the only crates that import adapters)
```

Domain/app crates never import adapters; composition happens only in interface crates.

### 1.3 The WIT component model (`wit/flint/host/world.wit`)

Frozen package **`flint:host@0.1.0`** (spec phase P0 `p0-c003-wit-contract`: "freeze `flint:host@0.1.0` before SDK/bindings"). Key facts from the authoritative file:

- Interfaces: `db`, `llm`, `kv`, `identity`, `secrets`, each `@since(version = 0.1.0)`.
- `db`: `query: func(sql: string, params: list<string>) -> result<list<string>, host-error>` — governed DB access "routes through flint-gate under the origin JWT". WIT has no `json` type: params/rows are JSON-encoded strings; `host-error { code, message }` records replace bare `error`.
- `llm`: `embed(input, model) -> result<list<f32>, host-error>`, `complete(prompt, opts: string) -> result<string, host-error>` — routes through flint-gate/UAR; "the component never holds a provider key; the host injects credentials at the boundary via Flint Vault".
- `kv`: per-invocation ephemeral KV, "not durable across invocations. Use `flint:db` for persistent state."
- `identity`: `origin-jwt() -> option<string>`, `claims() -> string` (JSON-encoded claim set injected by Kiln from the verified origin JWT).
- `secrets`: `resource secret { reveal: func() -> result<string, host-error> }` + `get(name) -> result<secret, host-error>` — `get` returns an opaque handle, **not** the value; `reveal` is Cedar-gated, audited (`vault.access_log`), default-deny. High-value secrets are brokered at the host boundary (never enter WASM linear memory).
- `world edge-function`: `export wasi:http/incoming-handler@0.2.12; import wasi:http/outgoing-handler@0.2.12; import db; llm; kv; identity; secrets;` — every deployed component targets this world.
- `world host-bindings`: host-only aggregation world for `wasmtime::component::bindgen!` codegen in `fke-runtime` (avoids re-resolving `wasi:http`, already handled by `wasmtime-wasi-http`/`ProxyPre`).
- WIT deps vendored under `wit/flint/host/deps/` (clocks, cli, http, filesystem, io, sockets, random).
- Stability promise: "All interfaces in this world are stable as of `flint:host@0.1.0`. Breaking changes will increment the package minor version and be announced in `docs/api/kiln-abi.md`."

Spec §5.3: any toolchain producing a component targeting `wasi:http/proxy` runs unmodified — Rust (`cargo-component --proxy` + `wasm32-wasip2`, first-class), JS/TS (`jco`/`componentize-js`), Python (`componentize-py`), Go (TinyGo wasip2), C/C++ (wasi-sdk + wit-bindgen); components may be composed via WAC before signing. Sample: `examples/hello-component`.

### 1.4 Kiln runtime (`fke-runtime`)

`crates/fke-runtime/src/runtime/mod.rs` — `EdgeRuntime` (share via `Arc`):

- Wasmtime `Config`: `wasm_component_model(true)`, `consume_fuel(true)`, `epoch_interruption(true)`. Background epoch ticker increments every `KILN_EPOCH_INTERVAL_MS` (default 10 ms; 0 disables).
- Fuel: `DEFAULT_FUEL = 10_000_000` per invocation (~10M instructions), overridable via `with_fuel`.
- Per-request isolation: `ProxyPre<KilnHostState>` cache keyed by `ContentId`; each request builds a fresh `Store` + `WasiCtx` + `ResourceTable`, `set_fuel`, `set_epoch_deadline(1)`, instantiates via `ProxyPre::instantiate_async`, runs `wasi_http_incoming_handler().call_handle` in a spawned task. Fresh linear memory per invocation → no cross-request leakage; stateless/serverless semantics.
- Cedar gates: `kiln:invoke` checked per invocation when a PEP + caller are present; per-capability grants computed independently (`kiln:capability:<name>` for db/llm/kv/identity/secrets/http_outgoing) — granted = declared ∩ Cedar(publisher). `caller = None` (BGW/system) skips Cedar by convention.
- Metrics: `kiln_fuel_consumed_total`, `kiln_epoch_traps_total` (`metrics` crate).
- Host capability implementations live in `fke-runtime/src/{db_host,llm_host,kv_host,identity_host,secrets}.rs`; linker construction in `helpers.rs` (`build_linker`); codegen in `host_bindings.rs`.
- AOT: `crates/fke-runtime/src/compiler.rs` — `AotCompiler` behind the **`compiler` cargo feature** ("control-plane only… not part of the data-plane `EdgeRuntime`, which loads components JIT-style via `Component::from_binary`"). Domain types (`fke-domain`): `CompilationStrategy { CraneliftAot, Winch, Pulley }`, `TargetArch { X86_64Linux, Aarch64Linux, Aarch64Darwin }` (both `#[non_exhaustive]`). Spec §5.2 describes the full control/data-plane split: control plane precompiles `.cwasm` keyed `(source_digest, target_arch, wasmtime_version)`; data plane built with cranelift/winch **disabled**, deserialize-only. `.cwasm` trust model: sign the source `.wasm`, AOT only in the trusted control plane, optionally seal `.cwasm` with a runtime key.

### 1.5 Ports, registry, stores, signers

`crates/fke-ports/src/lib.rs` — four async traits:

- `ComponentStore { put(&[u8]) -> ContentId, get(&ContentId) -> Vec<u8>, exists(&ContentId) -> bool }` — content-addressed (sha256 digest or IPFS CID); `put` must be idempotent.
- `SignatureVerifier { verify(manifest, signature, artifact) }` — errors `Unsigned | Invalid | Expired`.
- `Compiler { precompile(artifact, target) -> Vec<u8> }` — control-plane only; `Unverified` if called before signature verification.
- `ComponentRegistry { resolve(name, version) -> FunctionManifest }`.

`crates/fke-domain/src/lib.rs` — `ContentId(pub String)` (`#[repr(transparent)]`); `Capability { Db, Llm, Kv, Identity, Secrets, HttpOutgoing }` with `as_str()` for Cedar action names; **`FunctionManifest { publisher_did, content_digest, capabilities, version, not_before, not_after, signature_b64: Option<String> }`** — the signed registration record (Ed25519 signature over manifest for `did:prometheus:`; cosign-signed components look the signature up in Rekor keyed by `content_digest` and leave `signature_b64 = None`).

`crates/fke-registry/src/lib.rs` — Postgres-backed:
- `PgRegistry`: `resolve` reads `flint_kiln.functions WHERE name=$1 AND version=$2 AND active=true`, returns the JSONB `manifest`.
- `PgComponentStore`: artifacts in `flint_kiln.artifacts (content_digest PK, bytes bytea)`, real SHA-256 (test-pinned to known vectors), `INSERT … ON CONFLICT DO NOTHING`.
- Schema: `migrations/0010_flint_kiln.sql` — `flint_kiln.functions (id, name, version, content_digest, manifest jsonb, active, registered_at, UNIQUE(name,version))`, `flint_kiln.artifacts`, `flint_kiln.invocations` (audit: fuel_used, duration_ms, status). `migrations/0011_flint_kiln_cedar_policies.sql` holds Cedar policies in DB.

Store adapters (all implement `ComponentStore`, all content-addressed):
- `fke-store-oci` — `oci_client`; pushes each artifact as a **single-layer OCI image** tagged `sha256-<hex>` (colon→hyphen since OCI tags forbid `:`); env `KILN_OCI_REGISTRY`/`KILN_OCI_REPO`(+`KILN_OCI_USER`/`KILN_OCI_TOKEN`); idempotent skip-if-exists; spec designates OCI as the **primary** store ("wkg/cosign/admission tooling; sign by digest never tag").
- `fke-store-ipfs` — plain Kubo HTTP API client: `POST /api/v0/add` (hand-built multipart; reqwest has no `multipart` feature), `POST /api/v0/cat?arg=<cid>`, `POST /api/v0/stat?arg=<cid>`; env `FLINT_IPFS_URL` (default `http://localhost:5001`); `exists` returns `Ok(false)` on any error including unreachable node.
- `fke-store-s3` — `object_store` 0.14 (S3/R2/MinIO), env-driven.
- `fke-store-fs` — local filesystem sharded `{root}/{sha256_prefix2}/{sha256_hex}` (dev).

Signers:
- `fke-sign-did` — sovereign default. `did:prometheus:<base64url(ed25519_pubkey_32B)>` inline (no network), else HTTP resolution `{FLINT_DID_RESOLVER_URL}/v1/did/{did}` (default placeholder `https://did.flint.example.com`) with 5-minute in-memory TTL cache. Signed message = `sha256(artifact_bytes) || content_digest_bytes`; `verify_strict`; validity window `[not_before, not_after]` enforced (`SignError::Expired`).
- `fke-sign-cosign` — Sigstore interop via Rekor (`FLINT_REKOR_URL`, default `https://rekor.sigstore.dev`). `FLINT_COSIGN_MODE=full` (default): Fulcio X.509 chain verification against pinned Sigstore root/intermediate (P-384 chain, P-256 leaf SPKI), **SCT verification** per RFC 6962 §3.2 against pinned CT log key, optional `FLINT_COSIGN_IDENTITY_ALLOWLIST` for OIDC issuer/subject; `legacy` mode = raw SEC1 P-256, no chain checks.

### 1.6 Kiln server (`fke-server`)

`crates/fke-server/src/main.rs` — Axum on `0.0.0.0:8090`; compile-time split: default **data-plane**, `control-plane` feature adds admin routes. Wires: `sqlx::PgPool` (env `DATABASE_URL`), `DbKilnPolicySource` (Cedar policies from `flint_kiln.cedar_policies`, deny-all `SourceUnavailable` fallback), `EdgeRuntime::with_pep(CedarPolicyEngine)`, `PgComponentStore`, `PgRegistry`, both verifiers; spawns **Kiln BGW** (`kiln_bgw.rs`) draining `flint.webhook_outbox WHERE target_type='kiln'`; Prometheus metric layer + `/metrics`, optional OTLP tracing.

Routes:
- `GET /healthz`, `GET /metrics`
- `ANY /functions/v1/{name_or_versioned}` — invoke (single route captures `{name}` and `{name}@{version}` due to axum 0.8 one-capture-per-segment rule; default version `"latest"`). Handler (`handlers/invoke.rs`): bearer **mandatory** (`fdb_auth::rls_from_bearer`), resolve manifest → on cold cache, fetch bytes → **verify signature at load** (`verify_manifest_signature`) → `load_wasm` → `handle_with_telemetry(content_id, manifest.capabilities, caller, request)`. Verify once per cache-load, not per request.
- `POST|GET /admin/functions` (control-plane feature; `handlers/admin.rs`): requires bearer + `service_role` role. Register: decode base64 wasm → verify signature **before** store/registry write → `store.put` → upsert `flint_kiln.functions`. Spec §5.7 calls this admin surface "the platform's highest-value attack target" (separate auth/Cedar, ideally separate listener).

### 1.7 `flint-skill` — guest SDK for skill authors

`crates/flint-skill/src/lib.rs` + modules `db/llm/kv/identity/secrets/types/error`. It is the **consumer-side ergonomic SDK** that skill authors use alongside `wit-bindgen` output:

- Traits `Database`, `Llm`, `Kv`, `Identity`, `Secrets`, `SecretHandle` mirror the five `flint:host@0.1.0` interfaces; authors implement each as a one-line adapter over generated `bindings::flint::host::*`.
- `SkillError` with `HostInterface` enum + machine-stable codes (metrics, Cedar-deny detection); helper types `LlmOptions`, `CompletionResult`, `EmbeddingResult`, `DbRow`.
- **Contains no WIT calls of its own** → compiles on any target incl. `wasm32-wasip2`.
- Version tracks `flint:host@0.1.0`; ROADMAP v1.1.0 P1 item: publish `flint-skill` + `forge-cli` to crates.io.
- Roadmap confirms "Kiln guest Rust SDK (`flint-skill`) ✅ Done".

### 1.8 `forge-cli` — operator CLI

`crates/forge-cli` — `forge` binary (clap): `forge fn register <path.wasm> [--version 1.0.0] [--admin-url http://localhost:8090]`, `forge hook add <schema.table> <url> [--events INSERT,UPDATE,DELETE] [--tier standard]`, `forge migrate [--source migrations]`, `forge token mint` (smoke-test JWT), `--container` flag (`FORGE_CONTAINER`) to run inside the flint-forge-cli container.

### 1.9 Postgres role: Quarry crates (`fdb-*`)

- `fdb-ports` — five traits: `DatabaseBackend` (acquire with RlsContext → issues three `SET LOCAL`s: `ROLE`, `request.jwt.claims`, `request.headers`), `SchemaProvider` (introspect + `subscribe_ddl` watch channel), `RestExecutor`, `GraphQlExecutor` (reversibility seam), `ChangeStreamSource` (`watch(spec, who) -> BoxStream<Result<ChangeEvent, _>>`).
- `fdb-postgres` — adapters `PgBackend`, `PgRest`, `PgGraphQl` (delegates to `graphql.resolve()` inside Postgres = pg_graphql passthrough under RLS), `PgVectorRpc` (pgvector similarity via `/rpc/<fn>`); `conn.rs` holds `PgConn` over deadpool-postgres.
- `fdb-query` — **pure, I/O-free PostgREST grammar → SQL translator**: parses filters/logical trees/select/order/pagination/writes into typed plans, renders `(sql, params)` with every user value bound (`$n`) and identifiers validated. No DB dep, no async; consumed by `fdb-reflection` and `fdb-postgres`.
- `fdb-reflection` — `StateManager` + `ArcSwap<CompiledState>`; compilers/passes; listens to Postgres NOTIFY `meta_runtime` and atomically rebuilds router/schema/OpenAPI/MCP/AG-UI state (zero-downtime hot-swap).
- `fdb-gateway` — Axum composition root (`bootstrap::run()`). Route groups under `src/routes/`: **`a2ui/`** (components, applications, catalog, surfaces), **`agui/`** (publish, stream, surface, state), **`mcp/`** (tools, dispatch, sse, native_tools, protocol), **`a2a/`** (agent_card, tasks, dispatch), **`htmx/`** (renderers), `design_import.rs`. Also `a2ui_embedder.rs`, `agui_hook_dispatcher.rs`, `keto_sync.rs` (background Keto tuple cache), `subscriptions.rs` (async-graphql `graphql-transport-ws`), `policy_source.rs`, `rls_layer.rs`, `telemetry.rs` (sqlx pool metrics: `sqlx_pool_connections_open`/`_idle`).
- `fdb-realtime` — two `ChangeStreamSource` adapters:
  - `ListenChangeSource` (**default**, `FLINT_CHANGE_SOURCE=listen`) — PostgreSQL LISTEN/NOTIFY; complete and working.
  - `FabricChangeSource` (`FLINT_CHANGE_SOURCE=fabric`) — tonic gRPC client of FRF `EntityService.WatchEntityType(tenant, entity_type, filter)`. **Currently fails closed** (`StreamError::Unavailable`) because FRF does not yet expose `WatchEntityType` — tracked as **OQ-FRF-1**. Before opening any stream: Keto HTTP check (`/relation-tuples/check?…relation=view`) — fails closed if Keto unreachable; `keto_subject` (PII) never logged. Per-event RLS re-query is designed-in and "NEVER removed or skipped" (WAL bypasses RLS; re-query the changed row as the subscriber — same technique as Supabase Realtime). `FabricChangeSource` must not be constructed with a service-role RlsContext.

### 1.10 Postgres role: Anvil pgrx extensions (`ext-flint-*`, workspace-excluded, PG18/pgrx 0.18.1)

- `ext-flint-auth` (`flint_auth`) — the GUC-injection contract + SQL vocabulary: `auth.jwt()`, `auth.uid()`, `auth.role()`, `auth.bearer()` reading `request.jwt.claims` / `request.headers`. Postgres **never verifies** JWT signatures (flint-gate does); ships no policies, only vocabulary.
- `ext-flint-hooks` (`flint_hooks`) — webhook dispatch: `flint.webhooks` registry + generic `SECURITY DEFINER` trigger per hooked table; payload `{type, table, schema, record, old_record}`; **Option-3 outbound** (ratified): `Authorization: Bearer <service-token>`, `X-Forge-Origin-JWT: <raw user jwt>`, `X-Forge-Signature: hmac_sha256(payload, secret)` (pgcrypto hmac, `sha256=` prefix); Option-1 (`forward_jwt=true`) forwards the raw user JWT. Two tiers: `standard` (pg_net `net.http_post`, best-effort) and `durable` (`flint.webhook_outbox` same-transaction insert, dispatcher delivers with `FOR UPDATE SKIP LOCKED` retry/ordering).
- `ext-flint-llm` (`flint_llm`, **Flint Ember**) — liter-llm bound into Postgres, routing **inward to flint-gate/UAR, never directly to providers**. Surface 1 (sync `llm.embed`/`llm.complete`): dedicated runtime thread, backend blocks under hard timeout + `CHECK_FOR_INTERRUPTS()`/`WaitLatch` (statement_timeout/pg_cancel safe), gated — "never the default in a write-path trigger". Surface 2 (async, default): triggers enqueue to `llm.jobs` (`origin_jwt` captured at enqueue for attribution + Cedar), pgrx background worker dequeues (`FOR UPDATE SKIP LOCKED`, PGMQ pattern), batches, calls model, writes back via SPI. Declarative `llm.enable_embedding(table, column, model, dim)` (provisions column + trigger + HNSW index) and `llm.enable_summary`. Modules: `worker.rs`, `jobs.rs`, `governor.rs` (rate-limit), `gate_client.rs`, `credentials.rs` (resolves keys via flint_vault, never plaintext config), `templates.rs`, `writeback.rs`, `sync.rs`.
- `ext-flint-vault` (`flint_vault`, **Flint Vault**) — sovereign secret store, any secret kind. XChaCha20-Poly1305 AEAD, row `id` bound as associated data, per-row working key `HKDF-SHA256(DEK, info = category ‖ key_id)`. **Envelope encryption**: DEK unwrapped at postmaster start from a KEK in external KMS (Azure Key Vault via managed identity / AWS KMS / GCP KMS / Vault Transit) via the EDB-TDE `PGDATAKEYUNWRAPCMD` stdin→stdout pattern; KMS kill-switch; KEK rotation only rewraps. `vault.secrets` (typed categories enum), `vault.access_log` (append-only), `vault.decrypted_secrets` view (revoked from PUBLIC). Access: in-process `SECURITY DEFINER` `vault.get_secret(name[,scope])` / `vault.resolve_api_key(provider[,scope])` granted only to `flint_secret_reader`; edge access brokered (host injects; never enters WASM memory) or Cedar-gated `reveal` (`kiln:secret:reveal` action, per-secret resource — see `forge-policy/src/kiln.rs`).
- `ext-flint-meta` (`flint_meta`) — reflection cache: `cache_tables/columns/relationships/functions/policies/types`, `schema_version` (version++ per DDL), DDL event triggers (`ddl_command_end`, `sql_drop`) → `pg_notify('meta_runtime', …)`, plus modules `keto.rs` (in-DB `keto_tuples` + `flint_meta.check_permission`), `vault_meta.rs` (per-column encryption key assignments), `agui.rs` (`flint_meta.agui_descriptor(schema, table, identity)` — permission-filtered AG-UI descriptor JSON), `functions.rs`, `triggers.rs`, `version.rs`, `schema.rs`.

### 1.11 A2UI registry (RFC-FORGE-A2UI-001, `docs/FLINT-A2UI-REGISTRY-SPEC.md`, June 2026, "Ready for Implementation")

Scope: a **global, metadata-driven, AI-searchable A2UI/AG-UI component registry in Postgres** — "not a static component library; a living, metadata-driven, AI-searchable component runtime". Industry framing: **constrained generation** (A2UI, Vercel AI SDK, Tambo — agents pick pre-registered components) as default, **unconstrained** (Claude Artifacts, MCP Apps — raw HTML/JS in sandboxed iframes) as escape hatch.

Schema `flint_a2ui` (DDL in `migrations/0002_flint_a2ui.sql`, `0003_a2ui_triggers.sql`, `0004_flint_a2ui_sdk_extensions.sql`, `0006_flint_a2ui_hybrid_search.sql`, `0008_flint_a2ui_application_model.sql`, `0009_flint_a2ui_design_systems.sql`, `0012_a2ui_change_notify.sql`, `0013_force_rls.sql`):

- `components` — `slug` unique, `category` (`layout|data-display|input|action|navigation|feedback|system` in migration; spec adds `agent|media|chart|custom`), `primitive_type` (A2UI catalog type string e.g. `DataGrid`, `TextInput`), `schema` JSONB (JSON Schema for props with `x-*` DB-binding extensions: `x-binding`, `x-table-name`, `x-column-name`, `x-ref`, `x-rls-policy`, `x-encrypted`, `x-keto-namespace`…), `ui_hints`, `platforms` (web/desktop/mobile/cli framework lists), `implementations` (per-framework package/import/props_map), `design_tokens`, `accessibility`, `examples`, `permissions`, `is_base`, `application_id`, `search_vector` tsvector + GIN, semver CHECK on version, soft delete. Migration 0004 adds **`renderers` (`{"react": true, "flutter": true, "htmx": true}`), `react_pkg`, `flutter_pkg`, `htmx_template`** — i.e., each component declares renderer availability + package overrides for the three client SDK surfaces.
- `component_overrides` (0004) — per-application/per-design-system prop defaults, css_class_map, css_vars, per-renderer component/widget/template overrides, `source` (`manual|design-md|w3c-tokens|claude-design`); `resolve_components_with_overrides()` SQL function.
- `applications` — slug, owner, `jwt_claims_template` (merged into tokens), `catalog_id` (URI for A2UI catalog reference), `is_system`, config JSONB (design system, features, auth, database schema, realtime channels).
- `design_systems` — ODSF-compatible: `odsf_version`, `source_url`, `design_md` (DESIGN.md contract), `tokens` JSONB (W3C Design Token format per migration comment), `component_tokens` (per-component token mappings), `css_output` per platform. Import: `flint_a2ui.import_odsf(bundle_url)`; export: `export_odsf(application_id)` — two-way bridge to Open Design (`/Users/gqadonis/Projects/references/open-design`).
- `embeddings` — polymorphic (`entity_type`, `entity_id`, `aspect` ∈ description/schema_props/usage_example/design_tokens/category_tags/full_text), `vector(1536)` (text-embedding-3-large), **HNSW index** (m=16, ef_construction=64); hybrid BM25+vector search (migration 0006); auto-embed on register/update via `fdb-gateway/src/a2ui_embedder.rs`.
- `schemas` — typed JSON Schema registry (`component_props|data_model|form_schema|api_request|api_response|event_payload|design_token|ui_schema`) + `ui_schema_json` + DB `binding`.
- `bindings` — DB object (table/view/function/column/relationship/enum) → component/schema with prop_mapping config; **auto-generated** by event triggers on `flint_meta.cache_tables` insert (default table→data-grid, confidence 0.95) with `ON CONFLICT … DO UPDATE`; `pg_notify('a2ui_event', …)`.
- `type_component_map` / `function_component_map` — pg_type→component defaults (text→text-field, boolean→switch, timestamptz→date-picker, jsonb→json-editor…).
- `events` — append-only (RLS-enforced no UPDATE/DELETE) event-sourcing log for registry changes and agent actions, with `actor_claims` for audit.
- `assembly_rules` — event_type + JSONPath-like filter → assembly_config (surface_type, root component, component tree, data_bindings) — the event-driven dynamic UI construction engine (tool call completion → A2UI surface within 500ms target).
- `roles` / `role_assignments` — hierarchical roles, JSONB permission matrices, Keto namespace/relation links, expiry, context (tenant/project).
- RLS policies: users see base components + components of applications where they hold a role assignment (claim path `current_setting('app.jwt_claims')::jsonb->'flint'->>'user_id'`). 0013 forces RLS; 0014 grants service_role BYPASSRLS.

Surfaces (§9–12 of the spec; implemented routes in `fdb-gateway/src/routes/`):
- **REST** `/api/v1/components|applications|bindings|design-systems|schemas` (+ `/semantic-search`, `/auto-generate`, `/import`, `/export`, `/from-table/{schema}/{table}`).
- **A2A tasks**: `a2ui.component.{register,update,discover,bind,assemble}`, `a2ui.application.{create,configure}`, `a2ui.design_system.{import,export}`, `a2ui.schema.{generate,validate}`, `a2ui.binding.auto`, `a2ui.surface.{render,update}`, `a2ui.search.semantic`, `a2ui.token.resolve` — task state machine Submitted→Working→InputRequired→Completed/Failed/Canceled.
- **MCP tools**: `a2ui_list_components`, `a2ui_get_component`, `a2ui_semantic_search`, `a2ui_generate_form`, `a2ui_generate_grid`, `a2ui_resolve_tokens`, `a2ui_assemble_surface` ("Claude Desktop can discover and use Flint components via MCP" is a Milestone-7 exit criterion).
- **AG-UI**: SSE stream surface for component rendering; **A2UI**: JSON output generation.
- **Hot-reload**: migration 0012 — triggers on `flint_a2ui.components/applications` DML emit `NOTIFY meta_runtime, 'a2ui_change'` (constant 12-byte payload, no row image/tenant data); `StateManager` recompiles full state; roadmap confirms "A2UI component hot-reload ✅ Done … StateManager version watcher + AG-UI broadcast".
- Component lifecycle: Design → Register → Discover (semantic search) → Compose (agent assembly) → Render (client) → Realtime push (Iggy topics `a2ui.events`, `a2ui.surfaces`) → Event trigger (reassemble) → Feedback.
- Base apps: `flint-admin`, `flint-playground`, `flint-monitoring`, `flint-registry`, `flint-gate-console`, `flint-platform-agent`.
- JWT claims model: `flint.{user_id, organization_id, roles, permissions, applications, tenant_id, keto_subject, keto_namespace, vault_key_id}` claim tree; `flint_a2ui.resolve_components(application_id, jwt_claims)` filters the catalog.
- Threat model: admin-only registration (audited), slug uniqueness/no shadowing, embedding injection sanitization, token poisoning scoped by app + RLS, A2UI injection → constrained generation only (iframe `sandbox="allow-scripts"` for opt-in unconstrained), append-only events.
- Roadmap (8 milestones, 26 weeks): core registry → embeddings → DB binding auto-gen → app model → design system/ODSF → event assembly → protocol surfaces → **Milestone 8 "Federation and Scale": CRDT-based component sync across nodes, multi-tenant embedding isolation, versioning with rollback, CDN distribution** (weeks 24–26, NOT yet built). §16 future ideas: component test harness, multi-modal embeddings (search by screenshot), composition rules, animations, state machines, i18n, theme variants, performance budgets, a11y engine, component marketplace.

### 1.12 Meta extension plan (RFC-FORGE-META-001, `docs/FLINT-META-EXTENSION-PLAN.md`)

PostgREST/postgres-meta replacement philosophy: "the database owns the metadata; Rust merely reflects it". `flint_meta` pgrx owns pre-computed reflection tables + event triggers + version counter; `flint-reflection` compiles an immutable IR (`DatabaseModel`) through normalization → validation → permission analysis → endpoint generation → Router → OpenAPI → SDL → MCP manifest → AG-UI descriptors, hot-swapped via `ArcSwap`. JWT propagation via `SET LOCAL app.jwt_claims / app.keto_subject / app.vault_key_id`. In-DB Keto tuple storage (`flint_meta.keto_tuples`, recursive `keto_check` with subject-set transitivity + effective time windows) and per-column Vault key assignments (`vault_keys`, `vault_key_assignments`, `rotate_key`, `reencrypt_column`, `vault_rotation` NOTIFY). `flint_meta.agui_descriptor()` generates permission-filtered AG-UI JSON (fields readable/writable per Keto, `ui_hint` from columns, actions from functions). NOTIFY channels: `meta_runtime`, `keto_changes`, `vault_rotation`, `agui_update`; fan-out via Iggy → WebSocket/SSE/gRPC/CRDT peers. Performance targets: schema reload <5ms, hot-swap 0ms downtime, Keto check <5ms, AG-UI descriptor <20ms. Status header: "Architecture Design — Not Yet Implemented" (but the crate layout exists: `ext-flint-meta` + `fdb-reflection` are the realized form).

### 1.13 WASM sandboxing research (`research-wasm-sandboxing-comparison.md`, June 2026)

- Compares WASM Component Model + Wasmtime vs **microsandbox** (libkrun microVMs, KVM/HVF, OCI images, ~100–200ms cold start, ~5MB+/instance, beta ~v0.5.10 as of June 2026, macOS-Apple-Silicon + Linux only, MCP support).
- Verdict: **WASM primary** (~0.5ms cold start, ~300KB–1MB/instance, 10K+ tenants/host, fine-grained capabilities); microsandbox as optional higher-isolation tier for untrusted AI-generated code / native binaries / long-running plugins / confidential computing (SEV/TDX). Suggested SDK split: `#[flint::edge]` (WASM) vs `#[flint::sandboxed]` (microVM).
- Platform survey: Cloudflare Workers (V8 isolates), Fastly Compute@Edge (Wasmtime, <1ms), Fermyon Spin (Wasmtime, CNCF, acquired by Akamai Dec 2025), Suborbital e2core, wasmCloud (actor model, NATS; Adobe/BMW), Supabase Edge Functions (Deno, NOT WASM), AWS Lambda WASM (~50ms).
- Key references (dated 2024–2026) at doc §5, incl. https://github.com/microsandbox/microsandbox, https://docs.wasmtime.dev/, https://wasmcloud.com/, https://github.com/supabase/edge-runtime, https://devclass.com/2025/12/04/akamai-acquires-fermyon/ (2025-12).

### 1.14 Four authorization layers (design contract)

1. **Kratos** (authn, at flint-gate, per session) → 2. **Keto** (coarse relationship check, subscribe-time cached) → 3. **Postgres RLS** (authoritative row filter, every query AND every subscription event) → 4. **Cedar** (action/capability policy: Quarry mutations, Kiln linker, Ember model-use). Cedar policies stored in DB (`flint_kiln.cedar_policies`, migration 0005/0011) and evaluated via `forge-policy` (`cedar.rs`, `kiln.rs` — `KILN_INVOKE`, `KILN_REGISTER`, `kiln:capability:<name>`, `KILN_SECRET_REVEAL` per-secret; `a2ui.rs` mirrors for A2UI).

### 1.15 Two convergence invariants (spec §2.4)

1. One in-transaction capture (record + origin JWT), two consumers: `flint_hooks` (webhooks) and `flint_llm` (LLM jobs) — shared durable outbox.
2. One Wasmtime component host (`fke-runtime`), two surfaces: **Flint Kiln (HTTP-triggered) and UAR Tier-2 WASM skills** — the same host primitives (engine config, ProxyPre cache, capability linker, fuel/epoch limits) serve agent-harness skills. This is the direct hook for "native skills for agent harnesses" in the master goal.

---

## 2. How It Works (end-to-end flows)

**Component publish/invoke (Kiln):** author builds a component targeting `wasi:http/proxy` + `flint:host` imports (Rust + `flint-skill`) → signs manifest `{publisher_did, content_digest, capabilities, version, not_before, not_after}` with Ed25519 (or cosign keyless) → `forge fn register` posts to Kiln control plane (`service_role` required) → server verifies signature → stores bytes (PgComponentStore/OCI/IPFS/S3/fs) → upserts `flint_kiln.functions` → data plane: `POST /functions/v1/name@version` with bearer → RlsContext built → manifest resolved → artifact fetched on cold cache → **signature re-verified at load** → `ProxyPre` cached → per-request Store with fuel+epoch → Cedar `kiln:invoke` + per-capability intersection → host capabilities (`flint:db` queries route back through flint-gate under origin JWT; `flint:llm` through gate/UAR; secrets brokered or Cedar-gated `reveal`) → response. AOT path: control plane `AotCompiler` precompiles `.cwasm` per (digest, arch, wasmtime-version) behind the `compiler` feature; data plane designed to deserialize-only.

**DB change → realtime client:** DML commits → `flint_hooks`/change-notify triggers fire → LISTEN/NOTIFY (`listen` source, default) or FRF CDC→Iggy (`fabric` source, gated on OQ-FRF-1) → Quarry subscription orchestration → Keto coarse check at subscribe → **per-event RLS re-query as subscriber** → async-graphql `graphql-transport-ws` delivery. DDL change → `flint_meta` event triggers → `schema_version++` → NOTIFY `meta_runtime` → `StateManager` recompiles (REST router, GraphQL sibling schema, OpenAPI, MCP manifest, AG-UI descriptors) → `ArcSwap` swap → new requests see new schema with zero downtime.

**A2UI dynamic UI:** table created → `flint_meta.cache_tables` row → A2UI trigger auto-generates binding (table→data-grid, confidence 0.95) → NOTIFY → agent queries registry (REST/MCP/A2A, semantic search over pgvector embeddings) → `assembly_rules` match agent events (tool_call_completed etc.) → A2UI surface JSON assembled with resolved design tokens (app design system + component overrides + user prefs) → pushed via Iggy/AG-UI SSE → client renders via React (`@flint/react` / `packages/flint-react`), Flutter (`flint_genui` / `packages/flint_genui`), or HTMX (Askama templates in `fdb-gateway/src/routes/htmx/renderers`).

**Secrets:** admin writes secret via `vault.create_secret` (statement logging disabled on that path) → ciphertext at rest (XChaCha20-Poly1305, KMS-wrapped DEK) → consumers: in-DB (`flint_llm` credentials via `vault.resolve_api_key`), host-mediated edge (Kiln injects into outbound calls), or WASM `flint:secrets.get` → opaque resource → `reveal()` gated by Cedar `kiln:secret:reveal` per-secret + audited in `vault.access_log`.

---

## 3. Implications for the Master Goal

1. **flint-forge is the server-side anchor of the target architecture.** It already provides: central Postgres 18 with pgvector, the REST/GraphQL API layer, webhook/CDC outbox patterns, the WASM component runtime+registry, the A2UI UI-module registry, and the secrets/governance plane. pglite/pglite-oxide client sync would terminate at Quarry/FRF; flint-forge's per-event RLS re-query pattern is the reference for safe fan-out to local-first replicas.
2. **The WIT world `flint:host@0.1.0` is the native-skill contract for agent harnesses.** Convergence invariant 2 explicitly shares the host between Kiln and UAR Tier-2 WASM skills; `flint-skill` is the guest SDK; the five governed capabilities (db/llm/kv/identity/secrets) are exactly the right minimal surface for sandboxed agent skills, and the brokered-secrets model solves BYOK for WASM skills without leaking keys into linear memory. A KnowMe "skill as WASM component" story can reuse this verbatim.
3. **The trust chain is well-designed and portable to decentralized distribution:** content-address (sha256/CID) → sign digest (Ed25519/did:prometheus or cosign/Rekor) → bind capabilities to publisher DID → Cedar intersection at instantiation. This chain does not depend on Postgres — the `FunctionManifest` could be replicated as signed documents over IPFS or a git-like store; only the name→digest resolution layer is currently centralized.
4. **The A2UI registry is the server counterpart for A2UI/AG-UI/HTMX UI modules.** Component JSONB + `renderers {react, flutter, htmx}` + package overrides maps 1:1 onto the hybrid architecture (Tauri React 19 desktop, Flutter mobile, HTMX modules). Its `schemas` table (typed JSON Schema registry) and `applications.jwt_claims_template/config` are the closest existing hooks for the "settings schemas with synced client/server storage" requirement — but no client-sync protocol exists for them yet.
5. **Settings/config storage**: `flint_a2ui.applications.config`, `component_overrides`, `design_systems.tokens` demonstrate the JSONB-settings pattern with RLS; a KnowMe settings schema can follow this pattern and ride the same change-notify → recompile → AG-UI broadcast pipeline.
6. **CRDT sync is explicitly deferred on this side of the boundary** (A2UI Milestone 8, "CRDT-based component sync across nodes", weeks 24–26; META plan §8.3 mentions CRDT fan-out to peer nodes as a fabric concern). CRDT/WebRTC/lora-rs transport will come from flint-realtime-fabric / prometheus-entity-sync; flint-forge contributes the server schema, outbox, and NOTIFY contracts those transports must honor.
7. **Registry-as-database vs registry-as-distribution:** the A2UI registry and Kiln registry are both Postgres-native (metadata + JSONB + embeddings). That is excellent for governance/search/RLS but is a *catalog*, not a *distribution* mechanism. The decentralized packaging layer (IPFS CIDs, git-like versioning) must be added at the artifact/manifest layer: `ComponentStore` is the port to extend (an `fke-store-ipfs` that pins + uses IPNS/pubsub, or a new git-backed store), with `FunctionManifest` documents replicated alongside artifacts.
8. **Microsandbox research** provides the fallback for skills that can't compile to WASM (native binaries, untrusted AI-generated code) — relevant if KnowMe agent harnesses need to run arbitrary user code beyond the WASM capability surface.

---

## 4. Gaps / Risks

| # | Gap / risk | Evidence | Severity for master goal |
|---|---|---|---|
| 1 | **FRF `WatchEntityType` RPC missing** — fabric change source fails closed; production subscriptions effectively LISTEN/NOTIFY-only (single-Postgres; no fabric-mediated fan-out yet) | `crates/fdb-realtime/src/lib.rs` OQ-FRF-1; `README.md` lines 42–44 | High — blocks the "clients sync through flint-realtime-fabric" path until FRF lands the RPC |
| 2 | **Name→digest resolution is centralized in Postgres** (`flint_kiln.functions`); mutable pointers, single-node truth; no replication/federation protocol for the registry | `fke-registry/src/lib.rs`, `migrations/0010_flint_kiln.sql` | High for decentralized distribution; Mitigation: manifests are self-certifying, so the DB row is only a discovery cache |
| 3 | **IPFS adapter is a minimal Kubo HTTP client** — no pinning services, no IPNS/pubsub, no cluster; `exists()` conflates "node unreachable" with "not stored"; CID returned by Kubo is trusted (not recomputed locally) | `fke-store-ipfs/src/lib.rs` | Medium — fine behind the port, insufficient as a *decentralized* standard alone |
| 4 | **AOT `.cwasm` data-plane not wired in `fke-server`** — `EdgeRuntime::load_wasm` uses `Component::from_binary` (JIT) at load; `AotCompiler` exists behind `compiler` feature but no handler/CLI path exercises it; spec's "data plane has no compiler" split is a build-flag intention, not yet the shipped default | `fke-runtime/src/compiler.rs`, `runtime/mod.rs`, `fke-server/src/main.rs` | Medium — security/perf win unrealized; also `.cwasm` sealing only "optional" in spec |
| 5 | **`did:prometheus` method is informal** — inline-key or single HTTP resolver (default URL is a placeholder `https://did.flint.example.com`); no DID method spec, no rotation/revocation, no Kaia VC implementation despite spec §5.5 mentioning VC issuance | `fke-sign-did/src/lib.rs` | Medium — trust chain works but the identity root is a stub |
| 6 | **CRDT federation of the A2UI registry is future work** (Milestone 8); `events` is an append-only log, not a CRDT; multi-tenant A2UI isolation explicitly deferred in ROADMAP ("Requires Cedar policy redesign") | `docs/FLINT-A2UI-REGISTRY-SPEC.md` §14.8; `docs/ROADMAP.md` "Not-in-scope" | High for the "components/skills distributed + synced" requirement — must be designed |
| 7 | **No client-side sync contract at all** — nothing in flint-forge models pglite/pglite-oxide replicas, subscription snapshots, delta catch-up, or offline writes; per-event RLS re-query assumes live Postgres access per subscriber | `fdb-realtime`, spec §3.3 | High — the local-first sync protocol must be specified (likely FRF + entity-sync repos) |
| 8 | **Settings-schema concept absent as a first-class entity** — nearest equivalents: `flint_a2ui.schemas`, `applications.config/jwt_claims_template`, `component_overrides`; no versioned settings-schema with synced client/server storage | A2UI spec §5 | Medium — pattern exists, productized contract doesn't |
| 9 | **Doc drift** — `CLAUDE.md` says "Scaffold, todo!() bodies, pgrx 0.12/PG17" while README/ROADMAP/code say v1.0.0 released, PG18/pgrx 0.18.1; A2UI spec's `components.category` CHECK list differs between spec (10 values) and migration 0002 (7 values) | `CLAUDE.md` vs `README.md`; spec §5.1.1 vs `migrations/0002_flint_a2ui.sql` | Low — trust code + migrations over prose |
| 10 | **Admin plane hardening incomplete vs spec** — admin routes share the same listener/port (8090) as data plane; spec §5.7 wants separate listener + signing-key custody in Kaia/Key Vault (not implemented); `require_admin` is role-claim based only | `fke-server/src/handlers/admin.rs`, spec §5.7 | Medium — registry write path is the highest-value target |
| 11 | **Predicate-pushdown for subscriptions is off by default** (operator-accepted leak risk) — fine, but means per-event re-query cost scales with event rate for hot tables | spec §3.3 | Low/Medium — capacity planning for sync fan-out |
| 12 | **`invoke` grants all manifest-declared caps when no PEP/caller** (comment: "Cedar gate is future p6-c005" path for granted set) — production wiring attaches PEP, but BGW path trusts wholesale | `fke-server/src/handlers/invoke.rs` line 101; `fke-runtime` `granted_capabilities` | Low — documented convention, watch it |

---

## 5. Key Artifacts Index (for the spec writer)

- Master spec: `docs/FLINT-FORGE-SPEC.md` (RFC-FORGE-001) — §2.2 JWT/RLS injection, §2.3 four auth layers, §2.4 convergence invariants, §4 Anvil, §5 Kiln (signing model §5.5, stores §5.6), §8 open items.
- Meta plan: `docs/FLINT-META-EXTENSION-PLAN.md` (RFC-FORGE-META-001) — reflection compiler, in-DB Keto/Vault, AG-UI descriptor fn.
- A2UI spec: `docs/FLINT-A2UI-REGISTRY-SPEC.md` (RFC-FORGE-A2UI-001) — registry schema §5, REST §9, A2A §10, MCP §11, assembly pipeline §12, roadmap §14 (M8 = CRDT federation).
- WIT: `wit/flint/host/world.wit` — frozen `flint:host@0.1.0` (`edge-function` + `host-bindings` worlds).
- Ports: `crates/fke-ports/src/lib.rs` (`ComponentStore`, `SignatureVerifier`, `Compiler`, `ComponentRegistry`).
- Manifest: `crates/fke-domain/src/lib.rs` (`FunctionManifest`, `Capability`).
- Registry/store: `crates/fke-registry/src/lib.rs` + `migrations/0010_flint_kiln.sql`.
- Signers: `crates/fke-sign-did/src/lib.rs` (did:prometheus Ed25519), `crates/fke-sign-cosign/src/lib.rs` (Rekor, Fulcio chain+SCT).
- Runtime: `crates/fke-runtime/src/runtime/mod.rs` (`EdgeRuntime`), `crates/fke-runtime/src/compiler.rs` (`AotCompiler`).
- Server: `crates/fke-server/src/main.rs`, `handlers/{admin,invoke}.rs`, `kiln_bgw.rs`.
- Guest SDK: `crates/flint-skill/src/lib.rs` (traits `Database/Llm/Kv/Identity/Secrets`, `SkillError`).
- CLI: `crates/forge-cli/src/cli.rs` (`forge fn register|hook add|migrate|token mint`).
- Quarry: `crates/fdb-postgres`, `crates/fdb-query` (pure PostgREST→SQL), `crates/fdb-reflection` (`StateManager`/ArcSwap), `crates/fdb-gateway/src/routes/{a2ui,agui,mcp,a2a,htmx}`, `crates/fdb-realtime` (Listen default / Fabric fail-closed).
- Anvil: `crates/ext-flint-{auth,hooks,llm,meta,vault}`; vault = XChaCha20-Poly1305 + KMS-wrapped DEK; Ember = in-DB LLM via gate/UAR with BGW queue.
- A2UI migrations: `migrations/0002–0009, 0012–0014`.
- WASM research: `research-wasm-sandboxing-comparison.md` (WASM primary; microsandbox optional tier; platform survey + 2024–2026 URLs).
- Client SDKs (to be published v1.1): `packages/flint-react`, `packages/flint_genui`.
- Roadmap: `docs/ROADMAP.md` (v1.0.0 released; v1.1.0 planning; multi-tenant A2UI + K8s operator deferred).
