You are executing ONE change in the KBD phase `scaffold-full-hybrid-project` for the
Hybrid Mobile Architecture skill package (TJ-ARCH-MOB-001).

AUTHORITY — read these first, in order:
1. CLAUDE.md (repo root) — Development Philosophy section is BINDING:
   FEATURES FIRST, code first, test later. Inner loop = `cargo clippy` only (never
   alternate with bare check). No unit tests of internals; no mocks of internal code.
   3-5 boundary tests per completed feature, at completion, snapshot-preferred. If you
   fail to fix the same test twice, STOP and report.
2. .kbd-orchestrator/constraints.md — BLOCKING rules (never re-implement networking/
   inference/persistence in Dart/TS; one Tokio runtime; panic=unwind for FFI; etc.)
3. .kbd-orchestrator/phases/scaffold-full-hybrid-project/plan.md — YOUR change's full
   description, libraries, dependencies.
4. .kbd-orchestrator/phases/scaffold-full-hybrid-project/analysis.md — library verdicts,
   per-platform data matrix, version pins.

SKILLS: the shared skill pack is at ~/Projects/prometheus/prometheus-skill-pack.
Invoke the skills named for your change BEFORE writing code (emit good code first-shot).

SCOPE DISCIPLINE (Rule 40): implement ONLY your assigned change. Do not touch
gen_ui_types trait definitions unless your change IS c001 — those seams are frozen after
c001 review. Do not start other changes.

DELIVERABLE: working scaffold/code for your change. Generated files begin with
`// TJ-ARCH-MOB-001 compliant`. When done, write a one-paragraph completion summary to
.kbd-orchestrator/dispatch/logs/<change-id>.done.md listing files created/modified and
any deviations or blockers. Then stop.

## YOUR CHANGE: 2026-07-15-c003-relational-store

Read openspec/changes/2026-07-15-c003-relational-store/proposal.md and the matching entry in plan.md.
Implement it fully per the philosophy above. Assigned model: gpt-5.6-sol (codex).
