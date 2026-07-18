# Flint as a Supabase-Like Application Platform: Research and Deployment Contract

**Status:** researched architecture baseline
**Local revisions inspected (2026-07-17):** Flint Forge `4d5f97f`, Flint Realtime
Fabric `edbb215`, Flint Gate `057d64d`

## Finding

“Flint is a Supabase-like platform” is a useful product mental model, but not a claim
that its components or security boundaries are interchangeable with Supabase.
[Supabase describes its platform](https://supabase.com/docs/guides/getting-started/architecture)
as a set of open-source services centered on a Postgres database. Its
[Realtime architecture](https://supabase.com/docs/guides/realtime/architecture) streams
Postgres changes through a separately scalable realtime cluster. The local Flint
repositories intentionally follow the same compositional shape:

| Supabase mental-model role | Flint/KnowMe responsibility |
|---|---|
| Project Postgres and database extensions | Flint Forge Postgres 18 + Flint Anvil extensions |
| Generated data API / metadata plane | Flint Quarry reflection and `fdb-gateway` |
| Realtime change distribution | Flint Realtime Fabric |
| Authentication | Ory Kratos, optionally enforced at Flint Gate |
| Authorization and row filtering | Flint Gate + Keto/Cedar + authoritative Postgres RLS |
| Vault/secrets | Flint Vault; KnowMe stores only opaque secret references |
| Product-specific server functions | KnowMe Axum service and shared `gen_ui_host` |

The KnowMe Axum server remains the product boundary. React does not orchestrate Forge,
Fabric, Gate, Liter-LLM, or secret storage directly.

## Security conclusions

- Postgres WAL and ordinary change feeds do not automatically enforce application RLS.
  Forge/Fabric must re-authorize every emitted row or event for the requesting tenant.
- The current Forge README already names four layers: Kratos authentication, Gate/Keto
  authorization, Postgres RLS, and per-event realtime re-check. The KnowMe integration
  must preserve all four and fail closed.
- Anonymous BYOK is process/session memory only. Durable BYOK requires authenticated
  identity plus an encrypted Flint Vault record; PGlite, Zustand, logs, URLs, ordinary
  database columns, images, Compose files, and ConfigMaps never contain a provider key.
- [Ory Kratos is headless and API-first](https://www.ory.com/kratos), so KnowMe retains
  its own Shadcn/Flutter-branded identity UI when authentication is enabled.
- SSE is the correct first public streaming transport: Axum provides typed
  [`Sse`, `Event`, and `KeepAlive`](https://docs.rs/axum/latest/axum/response/sse/), and
  Flint Gate already treats AG-UI/A2UI streaming as a first-class proxy workload.

## Versioned realtime contract

Do not mutate Fabric's frozen v1 `EntityService`. Add a v2, tenant-scoped entity-type
watch operation with:

1. authenticated tenant and actor context;
2. entity type plus optional resume cursor;
3. stable event id, revision, operation, and server timestamp;
4. per-event authorization re-check before payload release;
5. explicit lag, cursor-expired, authorization-revoked, and dependency-unavailable
   terminal events;
6. reconnect/resume proof and cross-tenant denial proof.

Forge keeps LISTEN/NOTIFY as the small/local baseline. Selecting Fabric is explicit and
must fail readiness when its compatible pinned endpoint is unavailable; it never silently
falls back and changes delivery guarantees.

## Deployment decisions

- `local`: no infrastructure; browser PGlite/WebLLM, Tauri pglite-oxide/native model,
  Flutter SQLite/native model.
- `web`: non-root KnowMe Axum image with the React bundle embedded or mounted through
  `KNOWME_WEB_ROOT`.
- `realtime`: Forge + Fabric and their required Postgres/Iggy/Keto dependencies.
- `authenticated`: Flint Gate + Kratos and migration jobs.
- `full-agentic`: web + realtime + authenticated + durable Vault-backed BYOK.

Compose is the local/operator example. Kustomize is the primary Kubernetes interface;
Kubernetes supports composing resources and targeted overlays through
[`kustomization.yaml`](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/).
Secrets are referenced from an external secret source and are not generated with real
values in this repository.

## Open integration work

- Pin component image digests after CI publishes compatible Forge/Fabric/Gate images.
- Implement the Fabric v2 watch operation and Forge adapter together.
- Add hosted PostgreSQL conversation repositories behind the same `gen_ui_host` ports.
- Add Gate/Kratos identity propagation and Flint Vault secret-reference operations.
- Prove per-event RLS/Keto re-check, cursor resume, revocation, and dependency failure.
