EXECUTION: local-first-realtime-sync
Project: Hybrid Mobile Architecture Skill (TJ-ARCH-MOB-001 / KnowMe builder)
Date: 2026-07-18
Selected backend: openspec
Dispatched to: SELF (Claude Code, claude-fable-5)
Backend rationale: OpenSpec directory exists at project root with 17 prior changes archived/active in the same convention; the phase demands spec-backed traceability (six changes with cross-round dependencies); Claude Code is the hosting harness and the plan assigns it five of six changes. Task execution routed through /kbd-apply per the corrected contract — never bare /opsx:apply.
Backend entrypoint: /kbd-apply against openspec/changes/2026-07-18-c1XX-*, one task at a time
OpenSpec available: YES
Source plan: .kbd-orchestrator/phases/local-first-realtime-sync/plan.md

EXECUTION SCOPE

- c120-sync-doctrine-refs: sync doctrine reference docs + ADRs (Round 1)
- c121-local-first-skills: four project-local skills + hooks (Round 2)
- c122-partial-replication-slice: buckets/lookup-currency/onboarding slice (Round 2)
- c123-client-rag-slice: client vector + chat RAG slice (Round 2)
- c124-peer-profile-vault: Loro vault + WebRTC device-to-device (Round 2)
- c125-scaffold-audit-propagation: fold patterns into generators/gates (Round 3)

DISPATCH CONTRACTS

- c120 → SELF (Claude Code)
  Entry: /kbd-apply c120-sync-doctrine-refs
  Model class: frontier
  Concrete model: claude-fable-5 (session model; no model_policy registry in project.json)
  Model rationale: design authority for the phase — authors the goal-5 peer-CRDT design absent from the master plan; wrong doctrine here amplifies cost in every Round-2 change.
  Progress file: .kbd-orchestrator/phases/local-first-realtime-sync/progress.json
  Handoff: Report completion by updating progress.json and committing

- c121 → SELF (Claude Code)
  Entry: /kbd-apply c121-local-first-skills
  Model class: medium
  Concrete model: claude-fable-5 (session model)
  Model rationale: skill authoring follows the 14 existing exemplars and the c120 docs; pattern-following, not novel design.
  Progress file / Handoff: as above

- c122 → SELF (Claude Code)
  Entry: /kbd-apply c122-partial-replication-slice
  Model class: frontier
  Concrete model: claude-fable-5
  Model rationale: crosses gen_ui_types/gen_ui_db/desktop store layers; new scope-descriptor abstraction on a frozen seam.
  Progress file / Handoff: as above

- c123 → SELF (Claude Code)
  Entry: /kbd-apply c123-client-rag-slice
  Model class: frontier
  Concrete model: claude-fable-5
  Model rationale: cross-language (Rust FFI + TS), new retrieval-loop abstraction, per-tier vector matrix.
  Progress file / Handoff: as above

- c124 → SELF (Claude Code)
  Entry: /kbd-apply c124-peer-profile-vault
  Model class: frontier
  Concrete model: claude-fable-5
  Model rationale: highest-novelty change (greenfield WebRTC+CRDT with fail-closed privacy semantics).
  Progress file / Handoff: as above

- c125 → SELF (Claude Code; Codex acceptable for parallel worktree execution if delegated later)
  Entry: /kbd-apply c125-scaffold-audit-propagation
  Model class: medium
  Concrete model: claude-fable-5
  Model rationale: mechanical propagation of proven patterns into shell generators + audit checks.
  Progress file / Handoff: as above

APPROVAL GATES

- NONE within the phase. Standing note: c120's ADRs ratify recommendations for OD-2/OD-3/OD-4 consistent with the user's recorded c106 pivot; if the owner rules differently later, c122 scope descriptors re-shape at the seam (accepted risk from plan.md).

FALLBACK CONDITIONS

- If /kbd-apply or the openspec CLI is unavailable or refuses a change, fall back to driving the tasks directly from openspec/changes/<id>/tasks.md while keeping progress.json + waypoint in sync manually (documented in-line), then reconcile with openspec validate/archive when available.

VERIFICATION REQUIREMENTS

- Rust: cargo clippy -- -D warnings (workspace, --exclude gen_ui_ffi when frb codegen absent); cargo check --workspace
- Desktop TS: npx tsc --noEmit; npx eslint src/ (in apps/knowme-poc/desktop)
- Flutter: flutter analyze (mobile stubs only this phase)
- Docs-only changes (c120): markdown lint by inspection; CLAUDE.md reference-index consistency; audit.sh doc-consistency where applicable
- Per plan: 3–5 behavior tests per completed feature slice at public API boundaries; no mocks of internal code

PROGRESS LEDGER

- [DONE] c120-sync-doctrine-refs — SELF (archived 2026-07-18; QA skipped: docs-only)
- [DONE] c121-local-first-skills — SELF (archived 2026-07-18; QA skipped: skill-content-only)
- [PENDING] c122-partial-replication-slice — SELF
- [PENDING] c123-client-rag-slice — SELF
- [PENDING] c124-peer-profile-vault — SELF
- [PENDING] c125-scaffold-audit-propagation — SELF

OUTPUTS

- references/sync/{doctrine,partial-replication,peer-crdt,client-rag}.md + ADRs (c120)
- templates/project-skills/{sync-doctrine,pem-local-first,client-rag,peer-profile-sync}/ + mirrors (c121)
- knowme-poc slices: scope descriptors + lookup currency + load ledger (c122), vector/RAG loop (c123), profile vault (c124)
- scaffold/audit/versions.toml propagation (c125)

BLOCKERS

- NONE at dispatch. Known environmental: gen_ui_ffi requires frb codegen before full-workspace clippy (cold worktree).

REFLECTION HANDOFF

- Per-change QA results (artifact-refiner where ≥3 files), the OD-2/OD-3/OD-4 ADR texts, the dev-loopback-vs-PES seam decision record, deferred-item list (mobile sync client, production signaling, PSyncV2 gateway) for next-phase seeding.

EXECUTION READY
