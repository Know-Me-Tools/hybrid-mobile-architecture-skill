## 1. Implementation

- [ ] 1.0 BLOCKING: define what 'replay' means mechanically, or conclude it is infeasible
- [ ] 1.1 `--verify` re-executes the replay field against the affected skill
- [ ] 1.2 Fail Verify when the failure still reproduces
- [ ] 1.3 Assert an eval case covering the evidence exists; absent → fail with the fix command
- [ ] 1.4 If 1.0 concluded infeasible: amend `SKILL.md` Stage 4 to match the script

## 2. Verification

- [ ] 2.1 Ticket whose evidence still reproduces → `--verify` non-zero
- [ ] 2.2 Genuine fix + eval case → exits 0
- [ ] 2.3 Fixed ticket with NO eval case → non-zero naming the gap
- [ ] 2.4 REGRESSION: `--ship` still refuses a ticket that has not passed Verify
- [ ] 2.5 No promise in `SKILL.md` the script does not keep
