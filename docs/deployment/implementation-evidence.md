# Deployment, documentation, and prompting implementation evidence

Verified: 2026-07-17 (America/Chicago)

This record distinguishes implementation evidence from release evidence. A local build
proves a Dockerfile and pinned source revision; it does not prove that a protected GitHub
release published, signed, mirrored, or promoted an image. Those registry facts belong in
`deploy/images.lock.yaml` only after the release workflow returns immutable digests.

## Deployment catalog

| Criterion | Evidence | Status |
|---|---|---|
| Full source revisions | `deploy/sources.lock.yaml` rejects abbreviated or floating revisions | Verified |
| Immutable third-party images | `deploy/third-party.lock.yaml` contains digest-qualified references | Verified |
| One multi-architecture graph | `docker buildx bake -f deploy/docker-bake.hcl --print` | Verified |
| Compose topology | `docker compose config` renders `core`, `realtime`, `authenticated`, and `full-agentic` | Verified |
| Kubernetes packaging | Every Kustomize base, cloud layer, overlay, edge component, and certificate component renders | Verified |
| Architecture policy | `bash scripts/audit.sh all apps/knowme-poc` reports zero violations | Verified |
| CI policy | `actionlint` passes; workflows contain no direct cluster deployment | Verified |
| Registry release | Protected release must publish, attest, sign, scan, mirror, and promote the resulting digests | Pending release |

Native AMD64 completion is intentionally deferred to the Intel/AMD Linux builder. The exact
remaining targets and resume commands are recorded in
[`intel-amd64-build-handoff.md`](intel-amd64-build-handoff.md). This handoff does not weaken
the release gate or convert local development-image digests into release evidence.

The validation entry points are:

```bash
bash deploy/scripts/validate-catalog.sh
bash deploy/scripts/validate-gitops.sh
actionlint
```

## Kubernetes edge and certificate matrix

Every mode routes the same `knowme-web` Service and is selected as a mutually exclusive
Kustomize component.

| Edge mode | API | Component |
|---|---|---|
| F5 NGINX Ingress Controller | `Ingress` | `edge/nginx-ingress` |
| NGINX Gateway Fabric | `Gateway` and `HTTPRoute` | `edge/nginx-gateway` |
| Traefik Kubernetes Ingress | `Ingress` | `edge/traefik-ingress` |
| Traefik Gateway provider | `Gateway` and `HTTPRoute` | `edge/traefik-gateway` |
| Envoy Gateway | `Gateway` and `HTTPRoute` | `edge/envoy-gateway` |

The retired community `kubernetes/ingress-nginx` controller is intentionally excluded
from new-deployment components. TLS examples prove cert-manager HTTP-01 for one hostname,
cert-manager DNS-01 for wildcard certificates on Cloud DNS, Azure DNS, and Route 53, and
an external Certbot DNS-01 workflow. Certificate and DNS credentials never enter Git.

## KnowMe documentation site

- A frozen install and production Docusaurus 3.10.1 build passed.
- Public-content sanitization passed before every build.
- The only high-severity npm advisory was removed with a narrow
  `serialize-javascript` lock override; the remaining audit findings are moderate
  development-server transitive findings.
- The non-root container served the home, architecture, deployment, and prompting routes
  with HTTP 200 responses.
- Browser verification covered desktop light, desktop dark, and 390-pixel mobile dark.
- The accessibility snapshot exposed the skip link, navigation, search, theme control,
  and primary calls to action.
- Computed styles found no shadows and no visible borders. The two search-key hints use
  transparent borders and therefore do not create visual separators.

## Prompting system and reusable skills

- `docs/prompting/model-registry.yaml` validates 14 dated entries with official sources.
- The guide covers Codex, Claude Code, OpenCode, Kimi Code CLI, Antigravity, and Zed.
- Ten staged scenario packs contain prerequisites, phase prompts, artifacts, verification,
  reflection, authority boundaries, and stop conditions.
- `build-branded-docusaurus` and `orchestrate-prometheus-application` pass the official
  skill validator and are copied to all six repository harness skill directories.
- Phase intent, observations, failures, decisions, evidence, and follow-up work are stored
  in the project and private Karpathy wikis.

## Release gate

Do not replace the placeholder digests or mark the initiative complete merely because the
workflow files exist. Completion requires a protected release run that publishes all
approved images, records GHCR digests, verifies attestations and signatures, mirrors the
same digests to configured cloud registries, and commits the digest promotion to the
external ArgoCD repository.
