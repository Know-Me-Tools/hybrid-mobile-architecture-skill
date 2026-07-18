# c128-sqlite-vec-vector-store

> Phase: pem-sync-bridge-and-mobile-tier · Status: proposed
> Assigned harness/model: claude/fable-5
> Depends on: c127
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

Mobile vector tier: SqliteVecStore behind the VectorStore seam (384-dim, Vault refusal, ordering parity with PgVectorStore) + sqlite backfill variant, via the sqlite-vec loadable extension.

Derived from plan.md and assessment.md. Doctrine: references/sync/* + ADR-LFS-1..5.
All work sits behind the frozen seams established in c120–c125.

## What changes

See the plan.md entry for this change ID. Tasks expanded at execute time via /kbd-apply.

## Impact

- App-side changes flow back to scaffolds on completion (c125 pattern); generated
  files carry the TJ-ARCH-MOB-001 marker.
