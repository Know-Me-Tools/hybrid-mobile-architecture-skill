## 1. Implementation

- [x] 1.0 BLOCKING: define what 'replay' means mechanically, or conclude it is infeasible
- [x] 1.1 `--verify` re-executes the replay field against the affected skill
- [x] 1.2 Fail Verify when the failure still reproduces
- [x] 1.3 ~~Assert an eval case covering the evidence exists~~ — **NOT IMPLEMENTED, by decision D-1.** Eval cases are generated (3 per skill, templated from the description by `generate-skill-evals.mjs`), the shape asserts skill *activation* rather than a bug, and no runner executes them. A hand-added case is erased on the next regeneration. The promise was removed from `SKILL.md` with the reason recorded there, rather than faked in the script.
- [x] 1.4 If 1.0 concluded infeasible: amend `SKILL.md` Stage 4 to match the script

## 2. Verification

- [x] 2.1 Ticket whose evidence still reproduces → `--verify` non-zero
- [x] 2.2 Genuine fix (replay succeeds) → exits 0. ~~+ eval case~~ — the eval-case clause is **NOT APPLICABLE, by decision D-1**; verified as: a ticket whose `--replay` command exits 0 verifies and is marked `replayed: true`.
- [x] 2.3 ~~Fixed ticket with NO eval case → non-zero naming the gap~~ — **NOT APPLICABLE, by decision D-1** (no eval-coverage gate exists; see 1.3). Replaced by the behavior actually shipped and verified: a ticket with **no recorded replay** verifies but prints `replay: NOT RECORDED` and keeps `replayed: false`, so silence is visible rather than implied success.
- [x] 2.4 REGRESSION: `--ship` still refuses a ticket that has not passed Verify
- [x] 2.5 No promise in `SKILL.md` the script does not keep
