---
type: Reference
id: karpathy-progress-20260717T225317Z-byok-mobile-inference
title: "Liter-LLM BYOK and mobile llama.cpp vertical slice"
tags:
- karpathy-progress
- byok-mobile-inference
- in-progress
sources:
- conversation:operator-agent
timestamp: 2026-07-17T22:53:17Z
created_at: 2026-07-17T22:53:17Z
updated_at: 2026-07-17T22:53:17Z
revision: 1
---

## Intent

Implement secure provider configuration for Tauri, request-scoped hosted browser credentials, and the mobile llama.cpp engine behind the shared inference seam.

## Observed state and verification

Tauri provider administration compiles with warnings denied; TypeScript compiles; Axum live checks returned a generated provider catalog, structured 400 for malformed BYOK, and structured 422 without a configured provider. Prompt history now excludes the current turn. The Qwen 0.5B Q4 artifact is pinned to Hugging Face revision 9217f5db79a29953eb74d5343926648285ec7e67 and expected SHA-256 74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db. The llama engine check produced two feedback failures; both causes were corrected but the same check was not rerun a third time under the two-attempt rule.

## Decision and lesson

Status: in-progress. Preserve evidence, distinguish compile proof from runtime proof, and do not narrow the active goal.

## Next experiment

Wire the engine through Flutter boot, perform a distinct iOS target build after the external Xcode toolchain installation settles, propagate the implementation into scaffolds, and complete runtime verification.
