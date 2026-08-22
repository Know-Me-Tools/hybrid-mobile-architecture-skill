# PLAN: hma-companion-consumer-integration

Project: Hybrid Mobile Architecture Skill (TJ-ARCH-MOB-001 / KnowMe builder)
Date: 2026-08-22
Assessment: `assessment.md` (adversarially vetted, 5 findings applied)
Change backend: **OpenSpec** (`openspec/` present; 40+ archived changes)
Changes: **6** (c300–c305), strictly ordered

## User decisions folded into this plan

| Question | Decision | Effect |
|---|---|---|
| B-1 fork | **Adopt 1.10.0** (user, 2026-08-22) | c300 brings `.codex/` and `.kimi/` up to 1.10.0 and bumps `versions.toml:43`; it does *not* re-pin to 1.6.0 |
| c303 fork | **not yet answered** | c303 carries both options; the change's first task is the decision |
| Phase rename | **not yet answered** | Name kept; `hma-producer-stabilisation` noted in c305 as a reflect-time item |

The adopt decision is corroborated by evidence found while planning: **the
installed CLI is `openspec 1.10.0`**. The `versions.toml` pin of `1.6.0` was
already stale relative to the tool in daily use, so adopting reconciles the pin
with reality rather than forcing the tool backwards.

## Two findings that reshape c300

Both were surfaced by the adversarial review of this plan's first draft and
verified by executing `openspec update --force` against a clean `git archive
HEAD` tree.

### 1. `.kimi` → `.kimi-code` is a migration, not a deletion

The assessment's B-1(c) — "`.kimi/`'s ten openspec directories were deleted" —
is a **misdiagnosis**. The tool prints:

```
$ openspec update --force
Migrated 10 skills: .kimi → .kimi-code
Force updating 4 tool(s): claude, kimi, opencode, agents
```

`.kimi-code/` gains the 10 directories `.kimi/` loses. This is an intentional
upstream rename. Restoring `.kimi/` would recreate an artifact the tool deletes
on every run, and would make the idempotence criterion permanently unsatisfiable.

**c300 accepts the migration** and drops `.kimi` from the managed set.

### 2. Only four harnesses are managed; `.codex` is not one of them

The same run reports `Force updating 4 tool(s): claude, kimi, opencode, agents`
and touches `.codex/` **zero** times. `.codex/` is not in the project's OpenSpec
tool set, so no documented command brings it to 1.10.0. "Bring `.codex/` to
1.10.0" had no mechanism in the first draft.

**c300 must first decide** whether `.codex` becomes a managed target
(`openspec init --tools codex`) or is dropped from the contract check's harness
list. Both are defensible; leaving it stranded at 1.6.0 is not.

### What still holds

`internal: true` appears nowhere in `openspec/config.yaml` or the CLI's
vocabulary. It is a repo-local requirement `check-skill-contracts.mjs` imposes
on files an external tool writes, so `openspec update` strips it on **every run
for every managed tool**. Adopting 1.10.0 fixes today's red gate; only a
repo-owned normalization step stops the recurrence.

## c300 — Repair and defend the vendored openspec mirrors

**Addresses:** B-1 (a)(b)(c) · **Blocks:** every other change
**Agent:** claude · **Backend:** `openspec/changes/2026-08-22-c300-openspec-mirror-repair/`

### Why first

No change in this phase can be verified while a repo gate is red. "Did my change
break it?" is unanswerable against an already-failing baseline. Every other
change's acceptance criteria include "gates green", which is unreachable until
this lands.

### Tasks

1. Bump `versions.toml:43` `openspec = "1.6.0"` → `"1.10.0"`, with a comment
   recording that the pin follows the installed CLI and why (adopt decision).
2. **Decide `.codex`** (blocks 3): make it a managed OpenSpec target via
   `openspec init --tools codex`, **or** drop it from
   `check-skill-contracts.mjs`'s harness list as unmanaged. Record the choice.
3. Apply the decision from (2).
4. **Accept the `.kimi` → `.kimi-code` migration.** `git rm` the 10
   `.kimi/skills/openspec-*` directories and remove `.kimi` from the harness
   list at `check-skill-contracts.mjs:93`. Do **not** restore them.
5. Re-apply `metadata.internal: true` to the vendored `openspec-*` mirrors in
   every harness that remains managed after (2)–(4).
6. **Add `scripts/normalize-vendored-skills.sh`** — idempotent, repo-owned;
   re-applies `internal: true` and asserts per-harness completeness after any
   `openspec update`. It **derives the managed tool set from the OpenSpec
   config**, not a hardcoded list, so a future tool addition or migration does
   not silently fall outside it. This is the recurrence fix, not step 5.
7. **Replace the union count check.** `check-skill-contracts.mjs:107` asserts
   `internalNames.size !== 20` over a set unioned across harnesses; `.agents/`
   alone satisfies it, so a harness can lose its entire mirror set silently.
   Replace with a per-harness assertion that encodes the **non-uniform expected
   shape**: `.agents/` = 10 `openspec-*` + 10 `source-command-opsx-*`; every
   other managed harness = 10 `openspec-*` + 0 `source-command-opsx-*`. A
   uniform check would fail on `.agents/`.
8. **Make `audit.sh` reject unknown modes.** `bash scripts/audit.sh
   zzznonsense` currently prints "✓ No violations" and exits 0 — every
   acceptance criterion in this phase that invokes `audit.sh <mode>` can
   therefore pass by typo. Exit non-zero on an unrecognised platform argument.
9. **Fix `check-git-url-discovery.sh`** — see B-2 below.
10. Document the `openspec update` → `normalize-vendored-skills.sh` sequence in
    `CLAUDE.md` so the next upgrade does not reintroduce the drift.

### B-2 — a second red gate, missed by the assessment

`bash scripts/check-git-url-discovery.sh` fails **on clean HEAD**, not merely on
the working tree:

```
expected 30 public skills, found 36
```

A hardcoded count that the pack outgrew. The assessment's §3 baseline table
omitted this gate entirely, so its "9 of 10 green" was wrong in two directions:
the denominator was short by one, and the extra gate is red. There are **11**
local gates and **2** are red going into this phase, both pre-existing.

Fixing it inside c300 rather than as its own change is deliberate: c300's whole
purpose is restoring a trustworthy baseline, and a second red gate defeats that
purpose exactly as the first does.

### Acceptance criteria

- [ ] `node scripts/check-skill-contracts.mjs` exits 0 on the **working tree**
- [ ] `bash scripts/check-git-url-discovery.sh` exits 0 (B-2)
- [ ] `bash scripts/audit.sh zzznonsense` exits **non-zero** (task 8)
- [ ] Every managed harness reports a single `generatedBy` value of `1.10.0`;
      the set of managed harnesses matches the OpenSpec config, and `.codex`'s
      status matches the task-2 decision
- [ ] `ls -d .kimi/skills/openspec-* 2>/dev/null | wc -l` → **0**, and
      `.kimi-code` holds 10 — the migration accepted, not reverted
- [ ] **Negative fixture:** delete one managed harness's `openspec-*`
      directories in a scratch copy → `check-skill-contracts.mjs` **fails**
      naming that harness. Today it passes.
- [ ] **Negative fixture:** remove `internal: true` from a single mirror →
      the gate fails naming that file
- [ ] **Idempotence:** on a scratch clone,
      `openspec update --force && bash scripts/normalize-vendored-skills.sh`
      → gate green, and a **second** run leaves `git diff --exit-code` clean
- [ ] `bash scripts/audit.sh doc-consistency` still passes with the bumped pin

The negative fixture is non-negotiable. The prior phase's lesson — *"a checker
that only passes is not a checker"* — was learned when `verify-skill-manifest.sh`
passed its happy path while reading the wrong file. This change edits a checker;
it gets a failing fixture before the passing run is trusted.

---

## c301 — Simulated-consumer install proof (G1′)

**Depends on:** c300 · **Agent:** claude
**Backend:** `openspec/changes/2026-08-22-c301-simulated-consumer-proof/`

### Scope correction carried from assessment

G1 as written ("have `prometheus-companion` install this package end to end") is
**not executable**: the Companion is a 2-commit scaffold — 148 files, 3 `.rs`
files, zero references to this package. G1″ (the genuine cross-repo proof) moves
to the Companion's roadmap. This change is the executable half.

### Tasks

1. `scripts/test-consumer-install.sh` — clone this repo to a scratch dir, run
   `verify-skill-manifest.sh`, then assert all 6 v0.2.0 skills resolve **through
   the harness registry path a third party would use**, not by file existence.
2. Assert the 4 install-contract conditions hold from the clone's perspective.
3. Add ≥3 negative fixtures: undeclared skill dir; missing `plugin.json`;
   marketplace manifest naming a skill that does not resolve.

### Acceptance criteria

- [ ] Script exits 0 against a fresh clone of `HEAD`
- [ ] Each negative fixture exits non-zero **for its own stated reason** (assert
      on the message, not just the exit code)
- [ ] The script never reads the source working tree — path-isolated, so it
      cannot accidentally prove the local checkout instead of the clone

### Explicitly not claimed

Passing this does **not** demonstrate that the Companion can consume the
package. It demonstrates that a generic consumer following the documented
contract can. The reflection must state that distinction rather than let c301
stand in for G1″.

---

## c302 — Make the refiner's Verify stage honest (G5)

**Depends on:** c300 · **Agent:** claude
**Backend:** `openspec/changes/2026-08-22-c302-refiner-verify-replay/`

### The gap, precisely

`skills/realtime-skill-refiner/SKILL.md:83-84` promises: *"Then re-run the
recorded failing input and confirm the outcome changed. Add an eval case
covering it."* `scripts/refiner-loop.sh:118-149` runs four repo gates and a
`git diff` drift check, and does neither.

The plumbing already exists: `evidence` is persisted per ticket
(`refiner-loop.sh:211`) and `ticket_field` extracts it. The Verify stage simply
never reads it. That makes the fix small and the omission harder to excuse.

### Tasks

0. **Define what "replay" means mechanically — blocks task 1.** `--evidence`
   is free text (`refiner-loop.sh:12`), enforced only as non-empty (line 189)
   and stored as an opaque string (line 211). Nothing records an executable
   input or an expected outcome, so "replay" has no meaning yet. Either add a
   structured field (a command plus an expected-failure marker) or conclude
   replay is infeasible and take task 3. **c302's outcome is indeterminate
   until this task is answered**, and answering it may legitimately turn the
   change into a documentation-only fix.
1. `--verify` reads the ticket's replay field and re-executes it against the
   affected skill; a replay that still reproduces the failure **fails** Verify.
2. Assert an eval case covering the evidence exists; absent → fail with the
   command to add it.
3. If replay proves infeasible for some evidence class, **amend the skill body
   to match the script** — do not leave the doc claiming more than the code does.

### Acceptance criteria

- [ ] A ticket whose evidence still reproduces → `--verify` exits non-zero
- [ ] A ticket with a genuine fix and an eval case → exits 0
- [ ] A fixed ticket with **no** eval case → exits non-zero naming the gap
- [ ] `--ship` still refuses a ticket that has not passed Verify (existing gate
      unbroken — regression check, since c302 rewrites its precondition)
- [ ] Skill body and script agree: no promise in `SKILL.md` the script does not keep

---

## c303 — Resolve tauri-tray template rot (G3)

**Depends on:** c300 · **Agent:** claude · **DECISION REQUIRED — task 1**
**Backend:** `openspec/changes/2026-08-22-c303-tauri-tray-template-rot/`

### Artifact correction

There is no `tray.rs` in this repo and no `crates/`. The artifacts are
`assets/templates/tauri-tray/tray.rs.template` and
`assets/templates/tauri-tray/health-aggregator/` — both **templates**. The prior
phase's "health-aggregator compiles, 6/6 tests, clippy clean" describes a
one-time render during that phase; nothing re-renders it now.

This makes the debt one item, not two: **no gate re-renders these templates.**
It also makes the fix harder than the reflection implies — compile-checking a
template means rendering it into a scratch Tauri project with the right
dependency graph, not running `cargo check` on a file.

### Task 1 — the decision (blocks tasks 2+)

| Option | Cost | Benefit |
|---|---|---|
| **A — render-and-build gate** | A scratch Tauri project + `cargo` build per run; the slowest gate in the repo | The scaffold keeps a working tray feature and cannot rot |
| **B — delete the template, keep the skill body** | Loses `scaffold-tauri-tray.sh`'s rendered output | Removes an unverifiable artifact; the skill still teaches the pattern |

B is legitimate, not a cop-out: an uncompiled template that claims to work is
worse than prose that claims nothing.

### Tasks (A)

2A. `scripts/verify-tray-templates.sh` — render both templates into a scratch
    project, `cargo clippy -D warnings`, tear down.
3A. Wire into `audit.sh` as a named mode (not `all`, given the cost).
4A. Implement `toggle_pause` (`tray.rs.template:82-84` is an empty body) or
    document why the stub is the correct scaffold output.

### Tasks (B)

2B. Delete `assets/templates/tauri-tray/`; remove **all three** render steps in
    `scaffold-tauri-tray.sh` — lines **87** (`Cargo.toml`), **88** (`lib.rs`)
    and **91** (`tray.rs`) — or the script. Removing only 88 and 91 leaves
    line 87 rendering a `Cargo.toml` for a crate with no `src/lib.rs`.
3B. Move the pattern into `skills/tauri-tray-app/SKILL.md` as reference code,
    explicitly marked as illustrative and uncompiled.
4B. Update `docs/06-tauri-tray-app-spec.md` DoD to match.

### Acceptance criteria

- [ ] Task 1's decision is recorded in the change with its rationale
- [ ] (A) The gate **fails** on a deliberately broken template — negative fixture
      before the passing run
- [ ] (B) No file references the deleted templates; `generator-purity` passes
- [ ] Either way: no artifact remains that claims to compile but is never compiled

---

## c304 — Decide W6.7 / W6.8 (G4)

**Depends on:** c300 · **Agent:** claude · **DECISION REQUIRED**
**Backend:** `openspec/changes/2026-08-22-c304-hook-dispatch-decision/`

### The numbering problem is an offset, not a disagreement

The first draft said the two specs "disagree" on one label. They do not — the
**whole W6.6–W6.9 sequence is offset by one**:

| Label | `docs/03-hooks-reliability.md` | `docs/05-…-architecture.md:594-597` |
|---|---|---|
| W6.6 | No structured hook-result log | `exec 2>>"$LOG"` first in every hook script |
| W6.7 | Inline `bash -c` unfixable → **prom-hook-dispatch** | Add structured hook-result log |
| W6.8 | `sessionstart-*` matchers too broad | **prom-hook-dispatch** |
| W6.9 | `UserPromptSubmit` has no `matcher` | Tighten `sessionstart-*` matchers |

Both files legitimately contain W6.7 *and* W6.8 with different meanings. A grep
over the two labels can never "show one consistent numbering" — the fix is to
renumber one document's whole sequence so the two lists align end to end.

### Tasks

1. Decide: build `prom-hook-dispatch`, or drop it from spec 03's DoD. It has
   been advisory text across two phases; a third is a decision by default.
2. **Renumber the full W6.x sequence in one document** so both lists map the
   same label to the same remedy end to end. Renumbering `docs/03` (W6.6→W6.7,
   W6.7→W6.8, W6.8→W6.9) aligns it with `docs/05`; pick one direction and apply
   it to the whole run, not to individual labels.
3. Add a mechanical check asserting the W6.x label→remedy mapping is identical
   in both files, so the offset cannot silently return.
4. If dropped: `verify-hooks-reliability.sh` must stop reporting it as a pending
   human-decision item.
5. If built: it is a new Rust crate — scope it as its own change and defer, so
   c304 stays a decision rather than silently becoming an implementation.

### Acceptance criteria

- [ ] The check from task 3 exits 0, and **exits non-zero** when one label is
      deliberately perturbed in either file (negative fixture)
- [ ] Every W6.x label resolves to the same remedy in `docs/03` and `docs/05`
- [ ] `verify-hooks-reliability.sh` output matches the task-1 decision — no
      phantom pending item if dropped
- [ ] The decision and its rationale are recorded in the change, not only in a
      commit message

---

## c305 — Cut `v2.0.0-alpha.3` (G2)

**Depends on:** c300, c301, c302, c303, c304 (**last**) · **Agent:** claude
**Backend:** `openspec/changes/2026-08-22-c305-first-release-tag/`

### Why last

`connected-skill-packages` tells consumers to pin tags because branch HEAD is
unstable. B-1 is a live proof that it is. The first tag consumers are told to
pin must therefore point at a tree whose gates are green — tagging earlier
publishes the instability the guidance warns about.

`builder.manifest.json` already carries `2.0.0-alpha.3`; the tag does not exist
(`git tag -l | wc -l` → 0).

### Tasks

1. **Add `scripts/run-all-gates.sh`** enumerating every local gate, and run it.
   The first draft said "10 of 10" without listing them; the real inventory is
   **11**, and the eleventh (`check-git-url-discovery.sh`) was red on HEAD —
   see c300 B-2. A named script makes "all gates" testable instead of a count
   the reader must reconstruct from the assessment.

   | # | Gate |
   |---|---|
   | 1 | `check-builder-authority.mjs --release` |
   | 2 | `check-skill-contracts.mjs` |
   | 3 | `check-prometheus-boundary.mjs` |
   | 4 | `check-runtime-security.mjs` |
   | 5 | `check-git-url-discovery.sh` |
   | 6 | `sync-harness-skills.sh --check` |
   | 7 | `sync-skill-resources.mjs --check` |
   | 8 | `audit.sh doc-consistency` |
   | 9 | `audit.sh generator-purity` |
   | 10 | `verify-skill-manifest.sh` |
   | 11 | `verify-hooks-reliability.sh` |

2. **Validate all six published manifests** against the tagged version —
   `marketplace.json`, `plugin.json`, `.claude-plugin/marketplace.json`,
   `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`,
   `.agents/plugins/marketplace.json`. The first draft cited the constraint but
   discharged it with no task.
3. **Test a clean marketplace install** from the tag (constraints.md WARNING:
   "validate both Claude and Codex manifests and test clean marketplace
   installation").
4. Tag `v2.0.0-alpha.3` at that commit; push the tag.
5. Verify `connected-skill-packages`' pin-a-tag guidance now resolves against a
   real tag — clone at the tag and run `test-consumer-install.sh` from c301.
6. Record for reflect: whether the phase should be renamed
   `hma-producer-stabilisation`, since G1″ deferred and nothing consumer-side
   ships.

### Acceptance criteria

- [ ] `bash scripts/run-all-gates.sh` exits 0 at the tagged commit, and exits
      **non-zero** when any single gate is made to fail (negative fixture)
- [ ] All six manifests carry `2.0.0-alpha.3` and validate
- [ ] A clean marketplace install from the tag succeeds for both Claude and
      Codex
- [ ] `git tag -l` → `v2.0.0-alpha.3`, pushed
- [ ] A clone **at the tag** passes `test-consumer-install.sh`
- [ ] No `.prometheus/` session-log changes left uncommitted (standing rule)

---

## Ordering rationale

```
c300 ──┬── c301 ──┐
       ├── c302 ──┤
       ├── c303 ──┼── c305
       └── c304 ──┘
```

c300 is a hard barrier: it restores the green baseline every other change's
criteria depend on. c301–c304 are mutually independent and may be executed in
any order or in parallel worktrees. c305 is a hard barrier on the other end: it
publishes a tag, which is the only outward-facing act in the phase.

## Constraints applied

- **Local-only validation.** No GitHub Actions started, watched, or cited.
- `AGENT_BASE_RULES.md` — all 40 rules.
- Kebab-case for every new shell and TypeScript filename
  (`normalize-vendored-skills.sh`, `test-consumer-install.sh`,
  `verify-tray-templates.sh`).
- **WARNING (constraints.md):** c300 and c303 modify `scripts/` and
  `assets/templates/` — downstream projects consume these, so fixes propagate
  to the responsible generator and are exercised against a scratch scaffold.
- **WARNING (constraints.md):** c305 changes published marketplace metadata —
  validate both Claude and Codex manifests and test a clean marketplace install.
- Every change that edits a checker ships a **negative fixture first**
  (c300, c301, c303-A).
- Commit per change, conventional prefixes.

## Open decisions carried into execute

1. **c303 task 1** — render-and-build gate (A) or delete the template (B)?
2. **c304 task 1** — build `prom-hook-dispatch` or drop it from the DoD?
3. **Phase rename** — deferred to reflect (c305 task 4).

## Warnings carried from adversarial review of the assessment

- The assessment's own review ran **harness-native (judge == producer)** because
  the `:8181` gateway returned `HTTP 401 token_expired`. A gateway is listening;
  the credential is expired. Repair with `/liter-llm-bridge configure` before
  vetting this plan for a genuine cross-model review.
- **`audit.sh layer-contract` is not a mode.** `scripts/audit.sh:4` declares
  `flutter|tauri|rust|doc-consistency|generator-purity|all`, and the script
  exits 0 for *any* unrecognised argument — `bash scripts/audit.sh zzznonsense`
  prints "✓ No violations". The assessment listed `layer-contract` as an
  unmeasured mode; it never existed. c300 task 8 makes unknown modes fail,
  because otherwise any acceptance criterion invoking `audit.sh <mode>` can
  pass by typo. `audit.sh all` remains genuinely unmeasured.

---

## Corrections applied after adversarial review

The harness-native judge returned **4 CRITICAL, 5 WARNING, 1 SUGGESTION** on
this plan's first draft. All ten reproduced when checked; all are applied. Two
corrected **factual errors inherited from `assessment.md`**, which this plan had
carried forward without re-verifying:

1. **`.kimi` → `.kimi-code` is a migration, not a deletion.** `openspec update
   --force` prints `Migrated 10 skills: .kimi → .kimi-code`. The first draft
   ordered `.kimi/` restored — recreating an artifact the tool deletes on every
   run, and making the idempotence criterion permanently unsatisfiable.
2. **Only 4 tools are managed** (`claude, kimi, opencode, agents`); `.codex` is
   in no OpenSpec tool set. "Bring `.codex/` to 1.10.0" had **no mechanism**.
   c300 now decides `.codex`'s status before acting on it.
3. **`audit.sh` passes any unknown mode.** `bash scripts/audit.sh zzznonsense`
   → "✓ No violations", exit 0. `layer-contract` was never a mode. Every
   criterion in this phase invoking `audit.sh <mode>` could pass by typo.
4. **The W6.x lists are offset by one**, not disagreeing on a single label. The
   original criterion (`grep` "shows one consistent numbering") was both
   unsatisfiable and not a mechanical predicate.

And one blocker **neither the assessment nor the first draft found**:
`check-git-url-discovery.sh` fails **on clean HEAD** with `expected 30 public
skills, found 36`. The assessment's "9 of 10 green" was wrong twice over — the
inventory is 11 gates, and 2 are red. Recorded as B-2 and folded into c300.

A c300 written against the first draft would have restored `.kimi/`, chased a
`.codex` upgrade with no mechanism, and declared victory against a gate
inventory that was both short by one and already failing.

**Both adversarial reviews in this phase ran harness-native (judge == producer)**
because the `:8181` gateway returns `HTTP 401 token_expired`. Same-family
self-review found 15 real defects across two artifacts — but it is a weaker
guarantee than a cross-model judge, and the count is a reason to fix the
credential (`/liter-llm-bridge configure`), not evidence that it does not matter.
