---
type: Reference
id: karpathy-progress-20260717T233336Z-mobile-local-chat
title: "First-run Flutter local chat completed end to end"
tags:
- karpathy-progress
- mobile-local-chat
- verified
sources:
- conversation:operator-agent
timestamp: 2026-07-17T23:33:36Z
created_at: 2026-07-17T23:33:36Z
updated_at: 2026-07-17T23:33:36Z
revision: 1
---

## Intent

Added an iOS integration boundary test that submits through the real Flutter chat screen and waits for a finalized assistant bubble through Riverpod, FRB, gen_ui_agent, llama.cpp, and A2UI. Reduced the mobile default response cap to 128 tokens for phone latency.

## Observed state and verification

A clean simulator run downloaded the 491400032-byte pinned Qwen2.5 0.5B Q4_K_M artifact, the engine accepted it only after its built-in SHA-256 verification, and flutter test integration_test/local_chat_test.dart on the iPhone 17 simulator passed in 2m50s with a non-empty finalized assistant message and no warning block.

## Decision and lesson

Status: verified. Preserve evidence, distinguish compile proof from runtime proof, and do not narrow the active goal.

## Next experiment

Run the repository-wide Flutter, React, Rust, architecture, deployment, and clean-scaffold gates; then reconcile durable wiki indexes and prepare the single main commit/push.
