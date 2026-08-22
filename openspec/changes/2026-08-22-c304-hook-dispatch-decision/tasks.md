## 1. Implementation

- [ ] 1.1 DECIDE: build or drop `prom-hook-dispatch`
- [ ] 1.2 Renumber the full W6.6-W6.9 sequence in one document to align both lists
- [ ] 1.3 Add a check asserting the W6.x label→remedy mapping matches across both files
- [ ] 1.4 If dropped: remove the pending item from `verify-hooks-reliability.sh`
- [ ] 1.5 If built: open a separate change for the crate; do not implement here

## 2. Verification

- [ ] 2.1 The mapping check exits 0
- [ ] 2.2 NEGATIVE FIXTURE: perturb one label in either file → the check exits non-zero
- [ ] 2.3 Every W6.x label resolves to the same remedy in docs/03 and docs/05
- [ ] 2.4 `verify-hooks-reliability.sh` output matches the decision (no phantom item)
- [ ] 2.5 The decision and rationale are recorded in this change, not only in a commit
