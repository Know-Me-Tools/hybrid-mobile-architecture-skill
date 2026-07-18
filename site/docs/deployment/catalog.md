---
sidebar_position: 1
title: Deployment catalog
---

# From source commit to promoted digest

The catalog pins every first-party repository to a full commit, builds through one
Buildx Bake graph, publishes signed multi-architecture images with SBOM and
provenance, mirrors the approved digest to cloud registries, and commits that digest
to an external GitOps repository.

GitHub Actions never applies Kubernetes resources. Terraform/OpenTofu creates
clusters, networks, registries, and cloud identities. ArgoCD owns live cluster state.

Compose profiles are additive: `core`, `realtime`, `authenticated`, and
`full-agentic`. Kubernetes uses cloud-neutral bases, GKE/AKS/EKS integration layers,
and staging/production overlays. CloudNativePG owns production PostgreSQL 18.

The Prometheus PostgreSQL distribution includes the Flint extensions, pg_net,
pg_cron, pgvector, pgcrypto, and WAL-G when the pinned source build proves each
extension compatible with PostgreSQL 18. Unsupported extensions remain explicit
gaps; a catalog must never claim a build it has not produced.
