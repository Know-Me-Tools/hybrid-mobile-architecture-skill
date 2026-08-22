# EXECUTION: hma-companion-consumer-integration

Date: 2026-08-22
Plan: `plan.md` (adversarially vetted; 10 findings applied)
Changes: 6 (c300–c305), all validating under `openspec validate`

## Backend selection

**Selected: `openspec`**

| Criterion | Finding |
|---|---|
| OpenSpec present | Yes — `openspec/` with `config.yaml`, `specs/`, 40+ archived changes |
| CLI available | Yes — `openspec 1.10.0` on PATH |
| Spec traceability required | Yes — every change adds enforceable requirements, not just edits |
| Repo convention | Real spec deltas, not `skip_specs` (checked across archived changes) |

All six changes carry `specs/<capability>/spec.md` deltas and pass
`openspec validate`. Five new capabilities are introduced:
`vendored-skill-integrity`, `package-install-contract`, `skill-refiner-loop`,
`generator-template-integrity`, `hook-reliability-contract`, `release-tagging`.

## Runtime mode — why the ledger is file-based here

`prometheus kbd status` reports:

```
Control plane unavailable: error sending request for url (http://127.0.0.1:7892/…)
KBD mode: legacy (run `prometheus kbd migrate --apply`)
```

Typed commands (`prometheus kbd change register`, `stage transition`) are
rejected with `runtime has not been initialized`. **In legacy mode the
file-based ledger is the canonical source of truth**, so `progress.json` is
written directly — that is the sanctioned path for this mode, not a workaround
of the typed interface.

`prometheus kbd migrate` (inventory only) reports
`journalMigrationRequired: false`, `uncertainRows: 0`, `invalidFiles: 0`,
`staleProjections: 0` — the legacy ledgers are current and valid.

**`migrate --apply` was NOT run.** Migrating the project's state model is well
outside this phase's scope and was not requested. It is recorded here as an
operator decision, not silently skipped.

## Dispatch contract

**Driver: `/kbd-apply`** — never bare `/opsx:apply`. Upstream `/opsx:apply` has
no KBD awareness: it fires no `task:before`/`task:after` hooks, updates no
`progress.json`, and refreshes no waypoint. Driving it directly is the seam that
breaks plan→execute.

```
/kbd-apply hma-companion-consumer-integration 2026-08-22-c300-openspec-mirror-repair
```

### Order

```
c300 ──┬── c301 ──┐
       ├── c302 ──┤
       ├── c303 ──┼── c305
       └── c304 ──┘
```

c300 is a hard barrier — **two gates are red going into this phase**, so no
other change can be verified until it lands. c301–c304 are mutually independent
and may run in parallel worktrees. c305 is a hard barrier on the far end: it
publishes the only outward-facing artifact in the phase.

### Per-change gate chain

Per change, after `implementation_status: COMPLETE`:

1. `/refine-validate "<change-id>"` — deterministic checklist against
   `.kbd-orchestrator/constraints.md`
2. On ALL PASS → `/adversarial-review --mode diff "<change-id>"`
3. On verdict PASS → `/opsx:verify` → `/opsx:archive`
4. On any FAIL or BLOCK → certification `BLOCKED`; fix and re-run **both** gates

## Red baseline — the execution precondition

Two gates fail before any work starts. Both are pre-existing and neither was
introduced by this phase:

| Gate | State | Where |
|---|---|---|
| `check-skill-contracts.mjs` | **RED** — 40 errors | working tree only (HEAD passes) |
| `check-git-url-discovery.sh` | **RED** — `expected 30 public skills, found 36` | **clean HEAD** |

c300 closes both. Until it does, "did my change break it?" is unanswerable, and
every other change's acceptance criteria are unreachable.

## Blocking decisions inside changes

These are first tasks, not preconditions to starting — each change opens by
answering its own question:

| Change | Task | Question |
|---|---|---|
| c300 | 1.2 | Is `.codex` a managed OpenSpec target, or dropped from the contract check? It is in no tool set today. |
| c302 | 1.0 | Define "replay the evidence" mechanically, or conclude infeasible and amend the skill body? May turn c302 into a docs-only change. |
| c303 | 1.1 | Render-and-build gate (A), or delete the templates (B)? |
| c304 | 1.1 | Build `prom-hook-dispatch`, or drop it from spec 03's DoD? |

## Carried warnings

- **Adversarial review is degraded.** Both reviews this phase ran
  harness-native (judge == producer) because `:8181` returns
  `HTTP 401 token_expired`. A gateway is listening; the credential is expired.
  The per-change diff-mode gates will inherit this until
  `/liter-llm-bridge configure` is run.
- **`audit.sh` fails open.** `bash scripts/audit.sh zzznonsense` prints
  "✓ No violations" and exits 0. Until c300 task 1.8 lands, no acceptance
  criterion invoking `audit.sh <mode>` is trustworthy — including ones in this
  phase's own changes.
- **Working tree is dirty**: 63 modified, 10 deleted, 16 untracked. The
  modified/deleted set is the OpenSpec 1.10.0 drift that c300 exists to resolve;
  it must not be reverted wholesale (constraints.md: never delete or revert
  unrelated dirty work).

## Constraints in force

- Local-only validation. No GitHub Actions started, watched, or cited.
- `AGENT_BASE_RULES.md` — all 40 rules.
- Kebab-case for every new shell/TS filename.
- c300/c303 modify `scripts/` and `assets/templates/` — downstream consumers;
  propagate to the generator and exercise a scratch scaffold.
- c305 changes published marketplace metadata — validate all six manifests and
  test a clean install on both harnesses.
- Every change editing a checker ships a **negative fixture before** the
  passing run.
- One commit per change, conventional prefixes.
- `.prometheus/` session logs are always committed (standing authorization).
