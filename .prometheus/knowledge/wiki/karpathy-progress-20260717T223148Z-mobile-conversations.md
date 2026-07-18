---
type: Reference
id: karpathy-progress-20260717T223148Z-mobile-conversations
title: "Flutter conversations persist through Rust SQLite"
tags:
- karpathy-progress
- mobile-conversations
- in-progress
sources:
- conversation:operator-agent
timestamp: 2026-07-17T22:31:48Z
created_at: 2026-07-17T22:31:48Z
updated_at: 2026-07-17T22:31:48Z
revision: 1
---

## Intent

Replaced the mobile FFI entity CRUD stubs with a Rust sqlx SQLite EntityTransport. Added typed conversation/message repositories through Prometheus entity management and Riverpod, a Shadcn Flutter conversation sheet, filled chat bubbles, create/select/delete/reopen flows, ContentBlock persistence, and selected-thread history passed to the shared Rust agent. FRB outputs were regenerated from source.

## Observed state and verification

gen_ui_db SQLite public-boundary tests 5/5; gen_ui_ffi clippy -D warnings; flutter_rust_bridge_codegen generate; flutter analyze; Flutter tests 6/6

## Decision and lesson

Status: in-progress. Preserve evidence, distinguish compile proof from runtime proof, and do not narrow the active goal.

## Next experiment

Prove the mobile store and UI on the iOS simulator, then finish zero-config native mobile/Tauri inference and hosted BYOK configuration.
