# skill-refiner-loop Specification

## Purpose
TBD - created by archiving change 2026-08-22-c302-refiner-verify-replay. Update Purpose after archive.

## Requirements

### Requirement: The Verify stage keeps every promise its skill body makes
The reactive skill-refinement loop SHALL NOT document a verification step its script does
not perform. Where the script cannot perform a documented step, the documentation SHALL be
amended to match the script.

#### Scenario: A fix that does not fix the reported failure
- **WHEN** a ticket is verified and its recorded failure still reproduces
- **THEN** Verify SHALL exit non-zero and MUST NOT mark the ticket verified

#### Scenario: No reproduction was recorded
- **WHEN** a ticket carries no executable replay command
- **THEN** Verify SHALL report that no replay was recorded and mark the ticket
  `replayed: false`, so a reader can distinguish "the failure was re-executed
  and is gone" from "nobody re-executed anything"

#### Scenario: Replay is infeasible for an evidence class
- **WHEN** the recorded evidence cannot be mechanically re-executed
- **THEN** the skill body SHALL be amended so it claims only what the script performs

### Requirement: The ship gate remains closed behind Verify
Changes to the Verify stage SHALL NOT weaken the existing ship precondition.

#### Scenario: Shipping an unverified ticket
- **WHEN** ship is invoked on a ticket that has not passed Verify
- **THEN** it SHALL be refused
