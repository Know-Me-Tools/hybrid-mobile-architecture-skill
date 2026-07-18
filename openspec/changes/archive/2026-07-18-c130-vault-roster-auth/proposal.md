# c130-vault-roster-auth

> Phase: pem-sync-bridge-and-mobile-tier · Status: proposed
> Assigned harness/model: claude/fable-5
> Depends on: NONE
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

Vault pairing hardening: Ed25519 device roster in the doc (private keys never), pre-delta challenge-response, revocation propagation via CRDT; unauthenticated frames dropped (protocol v2).

Derived from plan.md and assessment.md. Doctrine: references/sync/* + ADR-LFS-1..5.
All work sits behind the frozen seams established in c120–c125.

## What changes

See the plan.md entry for this change ID. Tasks expanded at execute time via /kbd-apply.

## Impact

- App-side changes flow back to scaffolds on completion (c125 pattern); generated
  files carry the TJ-ARCH-MOB-001 marker.
