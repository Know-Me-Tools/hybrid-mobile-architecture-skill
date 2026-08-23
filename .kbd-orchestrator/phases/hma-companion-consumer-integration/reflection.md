# REFLECTION: hma-companion-consumer-integration

Project: Hybrid Mobile Architecture Skill (TJ-ARCH-MOB-001 / KnowMe builder)
Date: 2026-08-23
Changes delivered: 6/6 implemented, verified locally, merged to `main`
Commits: 92adb05 (c300) · 19b4136 (c301) · 01065e1 (c302) · 6087c36 (c303) · 4aac116 (c304) · b1934d7 (c305) · plus 6 archive commits
Released: `v2.0.0-alpha.3` → `b1934d7` (**moved once — see Debt D-1**)

## Goal achievement

The phase opened with 6 candidate goals marked *subject to assessment*. Assessment
downgraded two of them before any work started, which is the honest baseline for
scoring the rest.

1. **G1 — prove the install contract from the consumer side**: **PARTIAL, and the
   plan was wrong about what was possible.** `prometheus-companion` is a two-commit
   scaffold: 148 files, 3 `.rs` files, zero references to this package. The consumer
   the goal names does not exist. What shipped is G1′ — `test-consumer-install.sh`,
   which clones the package and exercises the documented contract from a *simulated*
   consumer's position, with path isolation proven empirically (breaking the source
   tree leaves the proof passing). **This does not demonstrate the Companion can
   consume the package.** G1″ stays on the Companion's roadmap.

2. **G2 — close the pin-a-tag contradiction**: **MET, with a serious caveat.**
   `v2.0.0-alpha.3` exists and resolves; a fresh clone from GitHub at the tag passes
   the consumer proof. But it was first published at a commit with a **red gate** and
   had to be force-moved. Recorded as Debt D-1 rather than presented as a clean cut.

3. **G3 — resolve `tray.rs`**: **MET, and the debt was worse than recorded.** The
   prior phase called this "a template no build touches will rot silently". It had
   already rotted: `tray.rs.template` did not compile (E0596 — `apply_accessory_policy`
   took `&App` where `set_activation_policy` needs `&mut App`), and every project
   scaffolded by `scaffold-tauri-tray.sh` received code that cannot build. Fixing it
   surfaced a second defect the new gate caught immediately (`clippy::let_unit_value`).

4. **G4 — decide W6.7**: **MET, and the scope was four times larger than planned.**
   The plan assumed two lists offset by one. There were **four** sequences: the
   architecture review, `docs/03`, the shipped skill, and a `docs/05` table that
   turned out to be a *remedy* index mislabelled with weakness numbers. Relabelling
   it `R6.x` removed the collision at its root. `prom-hook-dispatch` was dropped from
   this repo's DoD — it is owned by `prometheus-skill-system`, and this repo has no
   `crates/`.

5. **G5 — make the refiner's Verify honest**: **MET, by splitting the promise.**
   "Re-run the recorded failing input" was buildable and now is (`--replay`, which
   fails Verify when the failure still reproduces). "Add an eval case covering it"
   was **not** buildable and was removed rather than faked: evals are templated
   three-per-skill from each skill's own description, the shape asserts skill
   *activation*, and no runner executes them.

6. **G6 — re-verify the 2026-07-16 assessment**: **RETIRED at assessment.** Six of
   eight recommendations were already closed with evidence; two are out of scope by
   subject matter. Kept as a table so the document is not re-mined by a future phase.

## Artifact Quality Summary

No `artifact-refiner` logs exist for this phase — `.refiner/artifacts/` holds only
`knowme-reference-ui` from a prior phase. QA was **compensating**: an adversarial
diff-mode review per change, a full gate suite per change, and a negative fixture
suite for every checker written.

| Metric | Value |
| --- | --- |
| Changes with QA | 6/6 (compensating; no artifact-refiner runs) |
| artifact-refiner runs | 0 |
| Adversarial reviews | 8 (assess, plan, and one per change) |
| **CRITICAL findings** | **19** |
| WARNING findings | 24 |
| SUGGESTION findings | 8 |
| Findings reproduced before fixing | 51/51 |
| Findings accepted as limitations | 3 (recorded, not silently dropped) |
| Negative fixtures written | 14 scripted (5 + 2 + 7 across 3 suites, each with a positive control) + 2 ad-hoc in c300 |
| Local gates | 12 → **20** |
| First-pass pass rate | **0/8** — every review found at least one CRITICAL or WARNING |

### The number that matters

**19 CRITICAL findings across 8 reviews, and not one review came back clean.**
Every artifact this phase produced — including the assessment and the plan that
governed it — shipped a defect that would have caused wrong downstream work.

### Recurring defect classes

- **A checker that cannot fail** — 5 changes. The negative suite passed against a
  stub that read no input (c301); `--fast` printed "PASS" over a broken template
  (c303) and over skipped gates (c305); a mapping check validated numbers rather
  than meaning, twice (c304).
- **Hardcoded literals rotting silently** — 4 instances: `check-git-url-discovery`'s
  `30`, `test-harness-installer`'s `2.0.0-alpha.2`, the builder crate version, and
  `verify-scaffold`'s `29 companions`. All now derived.
- **Documentation outliving the code** — 4 changes. A skill body promising a replay
  the script never ran; a spec delta adding a normative `SHALL` that was false on
  landing; `design.md` contradicting its own change; docs claiming "all 9 fixes"
  against three.

## Technical debt introduced or left standing

**D-1 · The tag was published with a red gate, then moved.** The most serious
process failure of the phase. `v2.0.0-alpha.3` was cut and pushed at `23abd02` on a
"16/16 gates green" claim that was false — the roster omitted `verify-scaffold.sh`,
which CI runs and which was red there. The tag was force-moved to `b1934d7` by user
decision and its message records the move. Anyone who pinned `23abd02` in the
intervening hours has a tree with a red gate.

**D-2 · 43 ungated Rust template files.** `assets/templates/rust/` holds 43 `.rs`
files across 4 crates that no build touches — the same class c303 fixed for the tray
templates, at 15× the scale. A 108-line template shipped two defects; the rate across
43 files is unknown because nothing measures it.

**D-3 · The W6.x mapping check cannot reach its own source of truth.** It freezes
agreement between local artifacts; the architecture review lives in another repo. A
remap all three local artifacts shared would pass.

**D-4 · `audit.sh all` has no local gate.** Covered indirectly by `verify-scaffold`,
which scaffolds and audits a project, but not asserted directly.

**D-5 · Adversarial review ran same-model throughout.** All 8 reviews were
harness-native because the `:8181` gateway returns `HTTP 401 token_expired`. The
guarantee is weaker than a cross-model judge — and 19 CRITICALs is an argument for
repairing the credential, not against it.

## Lessons captured

- **Measure before framing a decision.** c303 was planned as a cost tradeoff — a slow
  gate versus deleting a feature. Building the template first revealed it *did not
  compile*, which settled the question on evidence rather than preference. The same
  move in c304 turned "reconcile two labels" into "four sequences, one of them
  mislabelled at the root". **Every decision this phase changed shape once the facts
  were gathered.**

- **A checker that only passes is not a checker — and this phase proved it needs a
  positive control too.** The prior phase learned the first half. c301 showed the
  second: a negative suite where *every* assertion demands a non-zero exit scores a
  perfect run against a stub that always fails. The missing assertion is "an
  unbroken input passes".

- **Prose is not a machine-readable signal.** Twice a `--fast` mode printed a warning
  and exited 0, so anything reading the exit code recorded a green gate. Both now
  exit 2 PARTIAL. If a mode degrades coverage, the *exit code* must say so.

- **An unlisted gate is an unrun gate — and the roster is not exempt.** The claim is
  not asserted; it was demonstrated twice in one change. `verify-scaffold.sh` was
  absent from the roster and had been red since before the phase began — no one saw
  it because nothing ran it. `test-harness-installer.sh` was likewise unrun and
  likewise red, on a stale version literal. Both were invisible for exactly as long
  as they were unlisted, and c305 then repeated the pattern at one remove: its
  roster shipped incomplete, declared a commit green that was not, and a tag was
  published on that claim. The corrective is mechanical rather than cultural —
  cross-checking against `.github/workflows/` is written into the script's header,
  because the lesson did not survive being merely understood.

- **Derive counts and versions; never write them down.** Four instances this phase.
  Every one was invisible until something else forced the gate to run.

- **The plan is a hypothesis; the repo is the spec.** This is the *third consecutive
  phase* to record this lesson. G1's consumer did not exist, G6 was already closed,
  `.kimi` was migrated rather than deleted, `.codex` had no mechanism to upgrade, and
  the W6.x offset was four sequences. Recording it again has not made it stick —
  what did work was checking each premise against the artifact it names *before*
  writing anything, which is what assessment and every blocking task-0 now do.

## Recommended Next Phase

**Rename this phase to `hma-producer-stabilisation`** in the record. Nothing
consumer-side shipped and nothing could have; the name overstates the outcome.

**`hma-companion-consumer-integration` (the real one)** becomes the next phase, and
should not start until `prometheus-companion` has an install surface to prove
against. Ordered by value:

1. **Repair the `:8181` gateway credential** (`/liter-llm-bridge configure`) before
   any further review-gated work. 19 CRITICALs came from a same-model judge; a
   cross-model one is strictly better and the phase's own refiner skill treats
   producer-grades-own-work as a halt condition.
2. **Gate the 43 Rust template files** (D-2). The tray templates proved the class is
   live, not theoretical.
3. **G1″ — the genuine cross-repo proof.** Requires Companion work first.
4. **Audit the remaining hardcoded literals.** Four found by accident; a deliberate
   sweep for baked-in counts and versions is cheap and this phase shows the yield.

## Sycophancy check

Self-check S-02/S-03/S-06 applied.

- **The headline metric is the worst one.** First-pass pass rate is 0/8 and 19
  CRITICALs lead the quality section, rather than "6/6 delivered, 20 gates green".
- **The tag failure is stated as a process failure, first in the debt list**, with
  the false claim I made quoted plainly — not softened into "the tag was refined".
- **G1 is scored PARTIAL, not MET**, and the reflection repeats that the consumer
  proof does *not* show the Companion can consume the package.
- **G2 is MET "with a serious caveat"** rather than clean.
- **Three findings are recorded as accepted limitations**, not quietly closed.
- **The repeated lesson is named as repeated** — third consecutive phase — instead of
  presented as a fresh insight.
- **No claim rests on assertion.** Every defect cited was reproduced before it was
  fixed (51/51), and the gate counts come from `run-all-gates.sh --list`.
