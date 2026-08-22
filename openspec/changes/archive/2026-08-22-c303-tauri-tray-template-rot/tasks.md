## 1. Implementation

- [x] 1.1 DECIDE A or B; record the rationale in this change
- [x] 1.2A Add `scripts/verify-tray-templates.sh` (render → clippy → teardown)
- [x] 1.3A Wire into `audit.sh` as a named mode
- [x] 1.4A Implement `toggle_pause` or document the stub
- [x] 1.2B ~~Delete the templates~~ — **NOT TAKEN**: option A chosen (D-1). Deleting would have removed a broken artifact; the gate is what *found* it.
- [x] 1.3B ~~Move the pattern into the skill body~~ — **NOT TAKEN** (option B branch).
- [x] 1.4B ~~Update the spec DoD for deletion~~ — **NOT TAKEN** (option B branch).

## 2. Verification

- [x] 2.1 The 1.1 decision and rationale are recorded
- [x] 2.2A NEGATIVE FIXTURE: the gate FAILS on a deliberately broken template
- [x] 2.3B ~~No file references the deleted templates~~ — **NOT APPLICABLE** (option A: nothing deleted). `generator-purity` still passes.
- [x] 2.4 Either way: no artifact remains that claims to compile but is never compiled
