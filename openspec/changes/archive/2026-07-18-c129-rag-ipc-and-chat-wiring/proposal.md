# c129-rag-ipc-and-chat-wiring

> Phase: pem-sync-bridge-and-mobile-tier · Status: proposed
> Assigned harness/model: claude/fable-5
> Depends on: NONE
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

Expose RagEngine over IPC (rag_retrieve Tauri command + frb fn, serde-typed chunks) and wire desktop chat retrieval through the layer contract (store-only invoke, hook composition, recall chips in the composer).

Derived from plan.md and assessment.md. Doctrine: references/sync/* + ADR-LFS-1..5.
All work sits behind the frozen seams established in c120–c125.

## What changes

See the plan.md entry for this change ID. Tasks expanded at execute time via /kbd-apply.

## Impact

- App-side changes flow back to scaffolds on completion (c125 pattern); generated
  files carry the TJ-ARCH-MOB-001 marker.
