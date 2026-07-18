---
type: Reference
id: karpathy-progress-20260718T034621Z-deployment-edge-verification
title: "Deployment catalog edge routing and TLS verification"
tags:
- karpathy-progress
- deployment-edge-verification
- in-progress
sources:
- conversation:operator-agent
timestamp: 2026-07-18T03:46:21Z
created_at: 2026-07-18T03:46:21Z
updated_at: 2026-07-18T03:46:21Z
revision: 1
---

## Intent

Implemented the pinned image catalog, Compose and GitOps packaging, and mandatory Kubernetes edge choices: active NGINX Ingress, NGINX Gateway Fabric, Traefik Ingress and Gateway API, and Envoy Gateway, with wildcard DNS-01 and external Certbot examples.

## Observed state and verification

Catalog and GitOps validators passed; actionlint passed; every Compose profile rendered; the KnowMe-branded documentation image built with an SBOM attestation, ran as UID 101, and served the edge-and-TLS and prompting routes. Flint Gate, Flint Forge Gateway, and Flint Realtime Fabric built from pinned sources as non-root images. A native KnowMe image build exposed a Debian Bookworm C++ ABI incompatibility in ONNX Runtime; the Dockerfile now pins Trixie builder/runtime digests and libstdc++6. The corrected source build requires the post-commit self-pin before it can be re-run from the immutable Git context.

## Decision and lesson

Status: in-progress. Preserve evidence, distinguish compile proof from runtime proof, and do not narrow the active goal.

## Next experiment

Commit the implementation, pin the repository-backed image contexts to that commit, rebuild KnowMe and PostgreSQL targets, record immutable release digests through the protected release workflow, then synchronize project and private wikis.
