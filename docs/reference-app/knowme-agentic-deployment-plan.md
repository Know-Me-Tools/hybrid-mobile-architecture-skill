# KnowMe Reference App and Agentic Deployment Plan

> Execution authority for the post-consolidation KnowMe reference application. This
> extends the original PoC plan; it does not replace its verified history.

## 1. Outcome

Deliver one clean `main` containing a working KnowMe reference application and the
scaffolds, skills, deployment assets, and durable learning record needed to reproduce it.
The reference implementation must demonstrate:

- React 19/Vite web and Tauri desktop from the same frontend source;
- Flutter mobile with the same product behavior and design system;
- one host-neutral Rust service layer shared by Tauri, Flutter FFI, and Axum;
- zero-configuration local chat plus optional hosted Liter-LLM BYOK;
- durable multi-conversation chat, rich AG-UI events, RAG citations, and media;
- browser PGlite, desktop pglite-oxide, mobile SQLite/sqlite-vec, and hosted PostgreSQL;
- optional Flint Forge/Fabric/Gate and Ory Kratos deployment profiles;
- lossless project and private Prometheus/Karpathy learning histories.

## 2. Non-negotiable product and architecture decisions

### React and Flutter UI

- React chat uses Assistant UI for thread, composer, streaming, attachments, message
  actions, and thread list. General controls prefer Shadcn UI.
- Flutter uses the shared design tokens and appropriate shadcn_flutter primitives.
- User and assistant messages render as actual filled chat bubbles.
- Flat 2.0 is strict: no visible borders, divider lines, decorative outlines, or layout
  shadows. Background-color steps alone separate regions in light and dark themes.
- Screens follow the KnowMe mood board's compact product shell, model management,
  reasoning disclosure, operator settings, and conversation density.

### State and persistence

- TanStack Query is prohibited. `@prometheus-ags/prometheus-entity-management` 3.x is
  the normalized entity/async layer everywhere the module is used.
- React components call hooks; hooks compose PEM 3.x and Zustand; stores call transports.
- Zustand owns transient selection/composer/stream assembly only.
- Conversation, message, ContentBlock, citation, attachment, artifact, and protocol-event
  entities persist in PGlite (web), pglite-oxide (Tauri), SQLite/sqlite-vec (mobile), or
  PostgreSQL/Forge (hosted) behind a common repository contract.
- Conversations can be created, reopened, searched, renamed, archived, and deleted.

### Model and secret behavior

- Local chat works without credentials: WebLLM in a capable browser and the downloaded
  Rust model in Tauri/mobile. Explicit on-device selection never silently falls back.
- Hosted providers and capabilities are generated from Liter-LLM's registry.
- Anonymous hosted BYOK keys are session-memory-only. Durable hosted BYOK requires an
  authenticated identity and an encrypted Flint Vault reference.
- Local secrets use platform secure storage. Secret values never enter PEM, PGlite,
  Zustand, logs, URLs, ordinary PostgreSQL columns, Compose, ConfigMaps, or images.

## 3. Runtime architecture

```text
React web -> optional Gate -> Axum adapters --+
Tauri commands/events ------------------------+--> gen_ui_host AppServices
Flutter FFI ----------------------------------+       |-- conversation persistence
                                                      |-- inference / Liter-LLM
                                                      |-- agent + MCP + memory/RAG
                                                      `-- sync / provider configuration
```

Add these Rust packages:

- `gen_ui_host`: host-neutral typed application services and ports;
- `gen_ui_server_axum`: reusable Axum router, AG-UI SSE, validation, OpenAPI, probes,
  metrics, and static-site adapter;
- `knowme-web-server`: thin executable configuration and deployment composition root.

Tauri, Flutter, and Axum consume the same `AppServices`. Networking, inference, MCP,
agent logic, and persistence are never reimplemented in Dart or TypeScript.

### Axum public boundary

Expose typed operations for conversation/message/artifact CRUD, model/provider catalog,
write-only secret-reference create/rotate/delete/validate, memory search/citations,
run/cancel with AG-UI SSE, health, readiness, metrics, and OpenAPI. Hosted React calls
this boundary; it does not directly orchestrate Flint or Liter-LLM.

### React asset modes

- Embedded mode: `build.rs` consumes compile-time `KNOWME_WEB_DIST_DIR` or invokes the
  tracked frontend build into `OUT_DIR`. It never installs packages or edits sources.
- External mode: runtime `KNOWME_WEB_ROOT` points to a validated compiled bundle. An
  invalid explicit path fails readiness; an unset path uses embedded assets.
- Hashed assets use immutable caching; `index.html` is no-cache; client routes receive
  SPA fallback; unknown API paths remain 404.

## 4. Flint coordinated changes

The researched component mapping, inspected revisions, security boundary, and v2 watch
contract are recorded in
[`flint-supabase-deployment-research.md`](flint-supabase-deployment-research.md).

Use the Supabase mental model carefully: Forge is a PostgreSQL-centered data/edge plane,
Fabric is the realtime plane, Gate is the optional policy/auth boundary, and the KnowMe
Axum service remains the product API/orchestrator.

- Preserve Fabric's frozen v1 `EntityService`.
- Add a tenant-scoped v2 entity-type watch contract rather than mutating v1.
- Implement the corresponding Fabric stream and Forge client support.
- Make Forge re-check row-level access for each realtime event before emission.
- Keep LISTEN/NOTIFY as a supported baseline and fail closed when Fabric is selected but
  unavailable or incompatible.
- Integrate Gate as an optional public boundary; use Ory Kratos for durable identities.
- Pin compatible Forge/Fabric/Gate commits and image digests in generated deployments.

## 5. Delivery profiles

| Profile | Services |
|---|---|
| `local` | local apps, embedded services, local model/storage |
| `web` | React bundle, Axum, PostgreSQL-compatible storage |
| `realtime` | `web`, Forge, Fabric, required event infrastructure |
| `authenticated` | Gate, Kratos, identity datastore/migrations |
| `full-agentic` | web, realtime, auth, Liter-LLM BYOK, observability |

Provide a multi-stage non-root Dockerfile, profile-based `docker-compose.yaml`, and
Kustomize base/overlays. Existing maintained component Helm charts may be referenced,
but Kustomize is the primary application packaging interface. Keep credentials external.

Scaffolding exposes `--mobile flutter|tauri|both|none` with Flutter as the default.
Application fixes must land in the responsible templates and skills, not only the PoC.

## 6. Continuous learning contract

Maintain three projections:

1. committed project history in `.prometheus`;
2. a private project superset under
   `~/.prometheus/knowledge/private/hybrid-mobile-architecture-src`;
3. reviewed, project-independent lessons under `~/.prometheus/knowledge/shared`.

Use `karpathy-progress-memory` at task/phase boundaries. Record intent, observed evidence,
decision, failure/lesson, and next experiment. Run the full
`prometheus learn --capture-session --compile --lint` pipeline at verified phase gates.
Never place secret values in any projection. Preserve divergent imported history with
provenance rather than overwriting it.

## 7. Execution phases and gates

### Phase A — freeze the contract and learning loop

- Commit this plan, the UI/UX standard, deployment skill, Karpathy recorder, and activation
  rules to all six harness templates.
- Backfill the conversation decisions into project/private wiki records.
- Verify Metal toolchain discovery and rerun the real local inference workflow.

### Phase B — finish the local-first reference experience

- Complete Assistant UI/Shadcn chat, filled bubbles, conversation library, rich renderers,
  PEM 3.x persistence, Flat 2.0 themes, and matching Flutter screens.
- Prove local streamed chat, restart persistence, memory citation, and both themes.

### Phase C — shared host and Axum

- Add `gen_ui_host`, Axum library, server binary, build-script asset modes, API schema,
  and Docker image.
- Prove the same workflow through Tauri, FFI, and HTTP without duplicated domain logic.

Status 2026-07-17: the host, Axum SSE run boundary, embedded/external asset server,
container image, probes, generated Liter-LLM provider catalog, desktop keychain BYOK, and
anonymous request-scoped browser BYOK are implemented. Live HTTP validation passed. Hosted
entity/config administration, OpenAPI generation, and full public-workflow proof remain.

### Phase D — hosted realtime, BYOK, and identity options

- Coordinate v2 realtime changes across Forge/Fabric, integrate Gate/Kratos, add encrypted
  durable BYOK, and retain anonymous session-only BYOK.
- Prove authorization re-check, reconnect/resume, secret non-disclosure, and provider
  capability discovery.

Status 2026-07-17: Compose profiles and initial Gate/Kratos/Keto/Fabric/Forge configuration
exist and render. They have not yet passed live profile launch, authorization, reconnect, or
durable-vault verification, so this phase remains open.

### Phase E — scaffolds, deployment, and final consolidation

- Apply every repair to templates and generated-project skills.
- Verify all Compose profiles and Kustomize renders.
- From a clean checkout: frozen installs, TypeScript/Vitest/Vite/Tauri, clippy/tests,
  Flutter generation/analyze/tests/iOS launch, architecture audit, scratch scaffold, web
  server launch, persistence, memory search, streamed local and hosted chat.
- Commit and push only after required gates pass. Finish with one clean `main` worktree,
  no auxiliary branches/stashes/orphaned processes, and `main == origin/main`.

## 8. Evidence required for completion

Compilation is not launch proof. Unit tests are not public-boundary proof. The plan is
complete only when current-state evidence demonstrates every named surface, storage mode,
deployment option, secret rule, realtime boundary, scaffold output, and learning record.
Any missing or indirect evidence keeps the goal active.
