## ADDED Requirements

### Requirement: The Verify stage keeps every promise its skill body makes
The reactive skill-refinement loop SHALL NOT document a verification step its script does
not perform. Where the script cannot perform a documented step, the documentation SHALL be
amended to match the script.

#### Scenario: A fix that does not fix the reported failure
- **WHEN** a ticket is verified and its recorded failure still reproduces
- **THEN** Verify SHALL exit non-zero and MUST NOT mark the ticket verified

#### Scenario: A fix with no regression coverage
- **WHEN** a ticket's failure no longer reproduces but no eval case covers it
- **THEN** Verify SHALL exit non-zero and name the missing coverage

#### Scenario: Replay is infeasible for an evidence class
- **WHEN** the recorded evidence cannot be mechanically re-executed
- **THEN** the skill body SHALL be amended so it claims only what the script performs

### Requirement: The ship gate remains closed behind Verify
Changes to the Verify stage SHALL NOT weaken the existing ship precondition.

#### Scenario: Shipping an unverified ticket
- **WHEN** ship is invoked on a ticket that has not passed Verify
- **THEN** it SHALL be refused
