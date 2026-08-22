# ASSESSMENT: hma-companion-consumer-integration

Project: Hybrid Mobile Architecture Skill (TJ-ARCH-MOB-001 / KnowMe builder)
Date: 2026-08-22
Assessed at: `e76c29b` (HEAD, `main`) — **working tree dirty: 79 modified files**
Previous phase: `v0.2.0-hma-companion-skills` (6/6 merged, reflected)

## 0 · Method and its limits

Every claim below is grounded in an executed command, not in reading the prior
phase's reflection. That choice was forced: **the adversarial-review model
preflight returned `no_gateway`** (no OpenAI-compatible endpoint answered;
`liter-llm` config exists at `~/.config/liter-llm/liter-llm-proxy.toml` but no
gateway is listening). The step-8 adversarial vet therefore runs as
**self-review — judge equals producer**, which is the exact failure mode the
`realtime-skill-refiner` skill halts on ("producer never grades its own work").

Treat the *judgments* in §3 as provisional. The *facts* in §1–§2 are not — each
is reproducible from the command shown.

To restore a real second voice: start the local proxy (`openai-proxy` on `:8181`)
or `liter-llm api --config ~/.config/liter-llm/liter-llm-proxy.toml`, then re-run
`/kbd-assess`. Not a blocker; a stated weakening.

---

## 1 · BLOCKER found during assessment (not in the phase goals)

### B-1 — The working tree is red. HEAD is green. Three symptoms, one cause.

```
$ node scripts/check-skill-contracts.mjs                 # working tree
FAIL — 40 errors
$ T=$(mktemp -d); git archive HEAD | tar -x -C "$T"      # non-destructive HEAD repro
$ (cd "$T" && node scripts/check-skill-contracts.mjs)
Validated 36 public Agent Skills and 108 evaluation cases.   # exit 0
```

An external OpenSpec CLI upgrade wrote into this repo's vendored skill mirrors.
It did **not** do so uniformly, and the damage has three distinct shapes. Any
fix addressing only the first leaves the other two in place:

**(a) Four harnesses regenerated to 1.10.0, losing `internal: true`.** 40
errors, 10 each in `.agents/`, `.claude/`, `.kimi-code/`, `.opencode/`:

```diff
 metadata:
-  internal: true
   author: openspec
-  generatedBy: "1.6.0"
+  generatedBy: "1.10.0"
```

**(b) `.codex/` was skipped entirely — the mirror set is now internally
inconsistent.**

```
$ grep -h 'generatedBy' .codex/skills/openspec-*/SKILL.md | sort -u
  generatedBy: "1.6.0"
$ git status --porcelain | grep -c '\.codex'      → 0
```

Five harnesses at 1.10.0 sitting beside one at 1.6.0 is a worse state than a
clean upgrade or a clean revert. "Adopt 1.10.0" does not fix this by itself.

**(c) `.kimi/`'s ten openspec skill directories were deleted, and the gate
cannot see it.**

```
$ git status --porcelain | grep -c '^ D .kimi/skills/openspec'   → 10
$ ls .kimi/skills | grep -c openspec                             → 0
$ git ls-tree -d --name-only HEAD .kimi/skills/ | grep -c openspec → 10
$ node scripts/check-skill-contracts.mjs 2>&1 | grep -c '^error: \.kimi/'  → 0
```

**The gate is structurally blind to (c).** `check-skill-contracts.mjs:92-108`
accumulates directory names into a single `internalNames` **union** across all
six harnesses, then asserts `internalNames.size !== 20`. `.agents/` alone holds
20 qualifying directories — 10 `openspec-*` plus 10 `source-command-opsx-*`, a
second family that exists only there — so the union is satisfied by `.agents/`
regardless of what any other harness lost. A harness can lose its **entire**
mirror set and the count check still passes. It emits zero errors for `.kimi/`
today, which is exactly what it did.

Three compounding facts:

1. **`versions.toml:43` pins `openspec = "1.6.0"`.** Five harnesses now say
   `1.10.0`. A pinned dependency was upgraded out from under the pin by an
   external tool writing into this repo.
2. **`audit.sh doc-consistency` passes anyway.** It reads authority *docs*
   against `versions.toml`; it never reads `generatedBy` in vendored skill
   frontmatter. The pin has no enforcement on this path.
3. **These skills are vendored, not owned.** `skills/` contains zero
   `openspec-*` entries and `builder.manifest.json` `skills[]` declares zero —
   yet the contract check judges all 40 mirrors. The repo is gated on artifacts
   it does not generate and cannot regenerate.

This predates the phase and is un-triaged. It outranks every goal in
`goals.md`: **no change in this phase can be verified while a repo gate is
red**, and "did my change break it?" is unanswerable against an already-failing
baseline.

The fix fork is genuinely open, and per-harness completeness is the part none of
the obvious options covers:

- *Re-pin to 1.6.0* — must also regenerate `.kimi/` from scratch; the
  directories no longer exist.
- *Adopt 1.10.0* — leaves `.codex/` stranded at 1.6.0.
- *Exclude un-owned vendored trees from the contract check* — stops the
  recurrence class, but makes the gate blind to the `.kimi/` deletion it already
  fails to catch.
- *Repo-owned idempotent mirror generation* — one script re-derives all six
  harness trees from a single source and asserts **per-harness** completeness
  rather than a union count. The only option that closes (a), (b) and (c)
  together.

Whichever wins must restore `.kimi/` and reconcile `.codex/`.

---

## 2 · Goal-by-goal verification against HEAD

Each candidate goal from `goals.md` was checked against the artifact it names.
Two do not survive contact.

### G1 — Prove the install contract from the consumer side · **NOT EXECUTABLE AS WRITTEN**

```
$ cd ~/Projects/prometheus/prometheus-companion && git log --oneline
773aa5e feat: implement the AGENTS.md §19 audit gate
19e2f08 chore: initialize repo with OpenSpec, context bootstrap, and KBD orchestrator
$ git ls-files | wc -l          → 148
$ git ls-files '*.rs' | wc -l   → 3      (build.rs, lib.rs, main.rs)
$ grep -rn 'hybrid-mobile-architecture\|skill-packages' --include='*.rs' --include='*.tsx' .
                                → (no matches)
```

`prometheus-companion` is a two-commit scaffold. There is no install surface, no
Tauri command, no "Connected Skill Packages" page, and no reference to this
package anywhere in it. **The consumer this goal proposes to prove against does
not exist yet.**

This is the phase's stated centrepiece, and it is the goal least able to be
executed. The prior phase's reflection asserted the producer side was "unproven
against a real consumer" — accurate, but it did not say the consumer was
unbuilt. Restating that recommendation without checking the consumer repo would
have put a quarter of the phase behind a dependency in another repository that
nobody has started.

Two honest reframings, both smaller than G1:
- **G1′ (in-repo, executable now):** prove the contract from a *simulated*
  consumer — a throwaway clone plus a scripted harness registration that asserts
  all 6 skills resolve. This is a real strengthening of the existing smoke test
  (which proved the repo's scripts run from a clone, not that a third party can
  register them) and needs nothing outside this repo.
- **G1″ (cross-repo, deferred):** the genuine end-to-end proof, blocked until
  the Companion has an install surface. This belongs on the Companion's roadmap,
  not this phase's.

### G2 — Cut a tag · **CONFIRMED OPEN, and it is the cheapest real fix here**

```
$ git tag -l | wc -l                              → 0
$ jq -r '.package.version' builder.manifest.json  → 2.0.0-alpha.3
```

Zero tags. `connected-skill-packages` tells consumers to pin tags because branch
HEAD is unstable — and B-1 is a live demonstration that branch HEAD is exactly
as unstable as that guidance claims. The version string already exists; the tag
does not. Tag **after** B-1 is resolved, or the first tag consumers are told to
pin points at a tree with a red gate.

### G3 — Resolve `tray.rs` · **CONFIRMED OPEN, but the goal misnames the artifact**

```
$ find . -name 'tray.rs'   → (nothing)
$ find assets/templates/tauri-tray -type f
assets/templates/tauri-tray/tray.rs.template
assets/templates/tauri-tray/health-aggregator/Cargo.toml.template
assets/templates/tauri-tray/health-aggregator/src/lib.rs.template
$ ls crates/               → (does not exist)
```

There is no `tray.rs` in this repo, and no `crates/` directory. The artifact is
`tray.rs.template`, rendered by `scaffold-tauri-tray.sh:91` into a *scaffolded
project's* `src-tauri/tray.rs`. `goals.md` inherited "`tray.rs` is never
compiled" verbatim from the reflection; the phrasing implies a source file in
this tree that would be trivially compile-checked.

The debt is real and the correction makes it *harder*, not easier: compile-
checking a template means rendering it into a scratch Tauri project with the
right dependency graph, not running `cargo check` on a file. The `toggle_pause`
stub is confirmed at `tray.rs.template:82-84` — an empty body with a comment
where the aggregator wiring belongs.

Verified: the health-aggregator crate the prior phase reports as tested is also
a *template*. Its "compiles, 6/6 tests, clippy clean" result came from rendering
it during that phase, and nothing re-renders it now. Both tray artifacts share
one debt, not two: **no gate re-renders these templates.**

### G4 — Decide W6.7 (`prom-hook-dispatch`) · **CONFIRMED OPEN**

```
$ grep -rn 'prom-hook-dispatch' docs/
docs/03-hooks-reliability.md:199   Rust binary `prom-hook-dispatch` (or fold into
docs/03-hooks-reliability.md:204   // crates/prom-hook-dispatch/src/main.rs
docs/03-hooks-reliability.md:219   **Verify:** the JSON has `command: "prom-hook-dispatch"`
docs/05-hma-pmp-companion-architecture.md:596  | W6.8 | Replace the `bash -c` with a Rust binary …
```

Present in two specs' DoD, absent from the tree, recorded in the prior phase's
`out_of_scope`. A genuine binary decision. Note the spec inconsistency surfaced
while checking: `docs/03` numbers this W6.7, `docs/05:596` numbers the same
remedy W6.8 — whichever way the decision goes, the two specs must agree, or the
next reader re-opens this.

### G5 — Make `refiner-loop.sh`'s Verify honest · **CONFIRMED OPEN, and precisely so**

`skills/realtime-skill-refiner/SKILL.md:73-83` promises:

> "Then re-run the recorded failing input and confirm the outcome changed. Add an
> eval case covering it, so the regression cannot return silently."

`scripts/refiner-loop.sh:118-149` (the entire `--verify` body) runs exactly four
repo gates — `generate-skill-metadata`, `generate-skill-evals`,
`check-skill-contracts`, `sync-harness-skills --check` — then a `git diff`
drift check. It never reads the ticket's `evidence` field, and it never adds an
eval case. Both promises are unimplemented.

Sharper than "no replay step": the script *can* read the evidence — `evidence`
is persisted per-ticket at `refiner-loop.sh:211` and `ticket_field` already
exists to extract it. The plumbing is there; the Verify stage simply does not
use it. That makes the fix small and the omission harder to excuse.

### G6 — Re-verify the 2026-07-16 assessment · **SUBSTANTIALLY CLOSED — retire this goal**

Seven of the eight recommendations were checked against HEAD:

| # | Recommendation | Status | Evidence |
|---|---|---|---|
| 1 | Fix CLAUDE.md pglite-oxide (the "actively harmful" item) | **CLOSED** | `CLAUDE.md:476` — "**Mobile (iOS/Android) → SQLite + sqlite-vec** (not pglite-oxide)"; §467 states "not a natively-compiled PostgreSQL binary" |
| 2 | Unify stack authority; doc-consistency in audit | **CLOSED** | `versions.toml` exists and is self-describing as the single source; `audit.sh doc-consistency` and `generator-purity` both PASS |
| 3 | Run C-103 iOS on-device frb test | **OUT OF SCOPE** | Belongs to the KnowMe PoC track, not this skill-package phase |
| 4 | Swap mobile inference to llama.cpp | **CLOSED, differently** | `versions.toml:89-94` — desktop `llama-cpp-2`, iOS `MLX-Swift`, `mistral.rs` demoted to optional behind `InferenceProvider`. Resolved the risk via a different route than recommended |
| 5 | Benchmark-gate SurrealDB 3.2 | **CLOSED as a decision** | `knowme-local-first-realtime-master-plan.md:1562` OD-6 → option (b): optional module behind a benchmark gate, fallback sqlite-vec + FTS5 + recursive CTEs, never on the sync critical path. Decision recorded; gate not yet executed (PoC track) |
| 6 | Collapse the DB matrix | **CLOSED** | `versions.toml:67-76` assigns one engine per tier with rationale per pin |
| 7 | Reclassify sync as custom code | **CLOSED** | `versions.toml:74` — "Electric read-path FALLBACK only (ADR-LFS-1: FRF/PES is the lane)" |
| 8 | Validate the $200/mo tier with buyers | **OUT OF SCOPE** | Business validation; no engineering artifact in this repo |

**The 2026-07-16 assessment is not a live work source for this phase.** Six of
eight are closed with evidence; two are out of scope by subject matter. G6
should be retired, and this table kept as the record of *why* — so the document
is not re-mined by a future phase.

One caveat worth stating rather than burying: recs 4, 5 and 6 are closed *as
decisions recorded in `versions.toml` and the master plan*, not as verified
runtime behaviour. Nothing here proves llama.cpp runs on-device or that
SurrealDB meets a mobile RAM budget. Those are PoC-track facts and this phase
cannot establish them.

---

## 3 · Gap summary and recommended phase shape

Baseline gate run (working tree, this session):

| Gate | Result |
|---|---|
| `check-builder-authority.mjs --release` | PASS |
| `check-skill-contracts.mjs` | **FAIL — 40 errors** (B-1) |
| `sync-harness-skills.sh --check` | PASS |
| `sync-skill-resources.mjs --check` | PASS |
| `audit.sh doc-consistency` | PASS |
| `audit.sh generator-purity` | PASS |
| `verify-skill-manifest.sh` | PASS |
| `verify-hooks-reliability.sh` | PASS |
| `check-prometheus-boundary.mjs` | PASS |
| `check-runtime-security.mjs` | PASS |

9 of 10 green; the one red is the un-triaged B-1. The `audit.sh` `layer-contract`
and `all` modes remain unmeasured going into the phase.

### What this phase should actually be

The phase as framed is **~40% not executable**. G1's consumer does not exist and
G6 is already closed. What remains is a coherent, smaller phase: *stabilise the
producer and make its own guarantees true*, which is a different thing from
"prove it against a consumer."

Recommended change set (6, ordered by dependency):

1. **c300 — Resolve B-1 (all three symptoms).** Decide vendored-skill
   ownership; restore `.kimi/`; reconcile `.codex/`'s 1.6.0 against the others'
   1.10.0; replace the union count check with a **per-harness completeness
   assertion** so a harness losing its whole mirror set cannot pass; add
   enforcement so an external CLI upgrade cannot silently un-pin
   `versions.toml` again. **Blocks everything else.** A fix that only re-adds
   `internal: true` to the 40 failing directories leaves (b) and (c) live and
   the gate still blind.
2. **c301 — G1′ simulated-consumer proof.** Clone → `verify-skill-manifest.sh`
   → assert all 6 skills resolve in the harness registry. In-repo, executable.
3. **c302 — G5 refiner Verify.** Read `evidence` in `--verify`, replay it, or
   amend the skill body. The ticket plumbing already exists.
4. **c303 — G3 template rot.** One gate that re-renders `tauri-tray` templates
   and builds them; covers `tray.rs.template` and health-aggregator together.
   Or delete the tray template and keep the skill body — a legitimate outcome.
5. **c304 — G4 decide W6.7.** Build or drop. Reconcile the W6.7/W6.8 numbering
   between `docs/03` and `docs/05:596` either way.
6. **c305 — G2 cut `v2.0.0-alpha.3`.** Last, so the first tag consumers pin
   points at a tree whose gates are green.

Retire G6 (closed, §2). Move G1″ to the Companion's roadmap.

### Open questions for plan

- **B-1 fork:** re-pin to 1.6.0, adopt 1.10.0, exclude un-owned vendored trees,
  or make mirror generation repo-owned and idempotent with per-harness
  completeness? Only the fourth closes all three symptoms; the first three each
  leave at least one of (b) `.codex` divergence, (c) `.kimi` deletion, or the
  union-count blindness in place.
- **c303 fork:** build a template-render gate, or delete the tray template? The
  gate costs real CI-equivalent time locally; deletion costs the scaffold a
  feature. This is a scope call for the user, not a default.
- **Should this phase be renamed?** With G1″ deferred, "consumer-integration"
  overstates what ships. `hma-producer-stabilisation` describes the actual work.
  Left as-is pending the user's call — renaming mid-phase costs waypoint churn.

## 4 · Sycophancy check

Applied to every evaluative claim in §2–§3.

- **Two of six goals were downgraded, not validated.** G1 is marked NOT
  EXECUTABLE with the command output showing a two-commit consumer; G6 is marked
  closed with a per-recommendation evidence table. Accepting the phase's own
  framing would have been the agreeable outcome and the wrong one.
- **A blocker outranking every stated goal is placed first**, not appended. It
  was found by running the gates rather than by reading the reflection — and the
  reflection, which is the most flattering available source about the prior
  phase, does not mention it.
- **The prior phase's reflection is corrected twice**: `tray.rs` does not exist
  (it is `tray.rs.template`), and the health-aggregator "compiles, 6/6 tests" is
  a template that nothing re-renders. Both corrections make the debt worse.
- **The method's own weakness is stated up front, not buried**: `no_gateway`
  means judge equals producer, which the repo's own refiner skill treats as a
  halt condition. §3's judgments are marked provisional as a result.
- **G6's closures are qualified** — recorded decisions, not verified runtime
  behaviour. Reporting "6 of 8 closed" without that line would overstate.
- **No claim rests on the reflection alone.** Every §2 verdict cites a command
  and its output.

### Corrections applied after adversarial review

The harness-native judge returned 2 CRITICAL, 2 WARNING, 1 SUGGESTION. All five
reproduced when checked; all five are applied above. The two CRITICALs corrected
a **wrong root cause** in the first draft, which had described B-1 as a uniform
regeneration of "the vendored skill mirrors":

- `.codex/` was never regenerated (still 1.6.0) — the mirror set is internally
  inconsistent, not uniformly upgraded.
- `.kimi/`'s ten openspec directories were **deleted**, and the union-based
  count check at `check-skill-contracts.mjs:107` cannot detect it.

A c300 written against the first draft would have re-added `internal: true` to
40 directories, watched the gate go green, and shipped with `.codex/` diverged,
`.kimi/` empty, and the blindness intact. That is the concrete downstream harm
the review prevented, and it is worth recording that self-review did not find
it — the assessment's own §0 predicted this weakness and was right.

Also corrected: the first draft's `git stash push -u` transcript did not
demonstrate what it appeared to (the phase directory it would have stashed is
still present); the HEAD-is-green conclusion holds but is now reproduced
non-destructively via `git archive HEAD`. And the §3 baseline table omitted
`check-prometheus-boundary.mjs` and `check-runtime-security.mjs` — both since
run (PASS) and added.
