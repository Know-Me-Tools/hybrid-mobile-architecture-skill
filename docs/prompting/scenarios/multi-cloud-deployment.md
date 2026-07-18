---
sidebar_position: 9
title: Source-built multi-cloud deployment
description: Staged prompts for pinned source builds, attestations, digest promotion, Compose/CNPG, GKE/AKS/EKS GitOps, NGINX, Traefik, Envoy Gateway, and TLS proof.
---

# Source-built multi-cloud deployment

Use this recipe when an operator wants source-built Prometheus images and
multi-cloud Kubernetes deployment packages. CI builds and promotes immutable
digests. ArgoCD owns live cluster state. Terraform/OpenTofu owns clusters,
registries, networks, and cloud IAM.

## Prerequisites

```text
Verify source repositories, full commit SHAs, GHCR ownership, cloud registry
targets, OIDC trust, external GitOps repository, BuildKit/buildx, Kustomize,
Compose, and CloudNativePG version.
```

## Discovery and Feynman prompts

```text
Read deployment catalog docs, Docker/BuildKit source context docs, GitHub
attestations docs, CNPG docs, Kustomize overlays, ingress/gateway docs,
cert-manager/certbot notes, and TJ-CICD-001 ownership.
```

```text
Explain the split between reproducible image build, digest publication, GitOps
promotion, ArgoCD reconciliation, and Terraform-owned infrastructure.
```

## KBD prompts

```text
/kbd-assess multi-cloud-deployment
Assess image inventory, third-party digests, Compose profiles, Kubernetes
services, cloud overlays, ingress/gateway options, TLS methods, CI authority,
and smoke tests.
```

```text
/kbd-analyze multi-cloud-deployment
Analyze deploy catalog, Dockerfiles, docker-bake graph, lock files, Compose
profiles, CNPG catalog, Kustomize overlays, GitHub Actions, and no-direct-deploy
checks.
```

```text
/kbd-spec multi-cloud-deployment
Specify pinned locks, BuildKit contexts, SBOM/provenance, GHCR digests, cloud
mirrors, Compose profiles, CNPG catalogs, GKE/AKS/EKS overlays,
NGINX/Traefik/Envoy examples, wildcard and Let's Encrypt TLS, and direct-deploy
prohibition.
```

```text
/kbd-plan multi-cloud-deployment
Plan lock validation first, then local builds, Compose readiness, Kustomize
rendering, ingress/gateway/TLS variants, CI attestations, promotion PR, critic,
and retention.
```

## Ingress, gateway, and TLS coverage

Every Kubernetes deployment guide must include examples for:

- NGINX Ingress Controller with host routing and wildcard certificate reference;
- Traefik IngressRoute or Gateway-compatible configuration;
- pure Envoy Gateway using Kubernetes Gateway API resources;
- wildcard certificates from a managed secret or cert-manager issuer;
- Let’s Encrypt HTTP-01/DNS-01 flow notes, including certbot examples where the
  environment uses certbot outside cert-manager.

## Implementation and verification

```text
Implement catalog changes without copying upstream source. Use pinned Git
contexts or source locks. Keep CI publishing digests and opening GitOps
promotions; do not run kubectl apply, helm upgrade, or ArgoCD sync.
```

```text
Validate lock schemas, build amd64 images, render Compose profiles, query
readiness, render all GKE/AKS/EKS overlays, scan for inline secrets and direct
deploy commands, and verify ingress/gateway/TLS examples compile.
```

## Stop evidence

Stop for floating refs, missing digests, unpinned third-party images, inline
secrets, direct deployment commands, non-rendering overlays, unsupported
PostgreSQL extension claims, or missing TLS option coverage.
