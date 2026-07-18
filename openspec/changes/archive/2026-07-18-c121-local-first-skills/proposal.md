# c121-local-first-skills

> Phase: local-first-realtime-sync · Status: proposed
> Assigned harness/model: claude/fable-5
> Depends on: c120
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

Four new project-local skills (sync-doctrine, pem-local-first, client-rag, peer-profile-sync) with activation hooks, propagation via add-project-skills.sh, and .claude/skills mirror — the skill package's core deliverable for this phase.

Derived from plan.md (full description, decisions, success criteria) and assessment.md
(seven-goal gap analysis). Follows the CLAUDE.md Development Philosophy: features first,
clippy-only inner loop, boundary tests at completion, verified dependency versions (Rule 22).
Sync-lane constraint: FRF is the realtime substrate (c106 pivot) — no new Electric work;
all slices sit behind the frozen SyncTransport/LocalStore/PEM-transport seams.

## What changes

See the plan.md entry for this change ID. Tasks expanded at execute time via /kbd-apply.

## Impact

- scripts/ changes stay backward-compatible (WARNING tier); generated files carry the
  TJ-ARCH-MOB-001 marker; slice patterns proven in apps/knowme-poc flow back to the
  scaffolds in c125.
