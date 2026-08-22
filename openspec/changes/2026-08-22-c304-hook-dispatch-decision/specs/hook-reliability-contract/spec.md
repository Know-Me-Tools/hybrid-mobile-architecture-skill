## ADDED Requirements

### Requirement: Weakness labels are consistent across authority documents
Every hook-reliability weakness label SHALL resolve to the same remedy in every document
that names it, and consistency SHALL be enforced mechanically.

#### Scenario: Two documents number a shared sequence differently
- **WHEN** one document's weakness sequence is offset against another's
- **THEN** one sequence SHALL be renumbered end to end so both map each label to the same
  remedy

#### Scenario: A label mapping drifts
- **WHEN** a weakness label is changed in one document but not the other
- **THEN** the consistency check SHALL exit non-zero

### Requirement: An advisory remedy is decided, not carried indefinitely
A remedy listed in a Definition of Done SHALL either ship or be removed from that
Definition of Done.

#### Scenario: A remedy is dropped
- **WHEN** a remedy is removed from a Definition of Done
- **THEN** the hook-reliability verifier SHALL stop reporting it as a pending item
