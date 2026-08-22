## ADDED Requirements

### Requirement: Vendored mirrors survive external regeneration
The pack SHALL re-apply its repo-local skill invariants after any run of an external
skill generator, deriving the managed tool set from that generator's own configuration
rather than a hardcoded list.

#### Scenario: External generator strips a repo-local invariant
- **WHEN** `openspec update` regenerates the vendored `openspec-*` mirrors and removes
  `metadata.internal: true`
- **THEN** running the pack's normalization script SHALL restore the invariant across
  every managed harness, and the skill-contract gate SHALL exit 0

#### Scenario: Normalization is idempotent
- **WHEN** the generator and the normalization script are run twice in sequence
- **THEN** the second run SHALL leave the working tree clean under `git diff --exit-code`

#### Scenario: An upstream harness rename is accepted, not reverted
- **WHEN** the generator migrates a harness directory to a new name
- **THEN** the pack SHALL adopt the new name and MUST NOT recreate the old directory

### Requirement: Per-harness mirror completeness is enforced
The skill-contract gate SHALL assert the expected mirror set for each managed harness
individually, rather than a count unioned across harnesses.

#### Scenario: One harness loses its entire mirror set
- **WHEN** every vendored skill directory is removed from a single managed harness
- **THEN** the gate SHALL exit non-zero and name that harness

#### Scenario: Harnesses have differing expected shapes
- **WHEN** one managed harness legitimately carries additional skill families that others
  do not
- **THEN** the assertion SHALL encode the per-harness expectation and MUST NOT fail that
  harness for the difference

### Requirement: Audit modes fail closed
The architecture audit SHALL exit non-zero when invoked with an unrecognised mode.

#### Scenario: A mistyped audit mode
- **WHEN** the audit is invoked with a mode that is not in its declared set
- **THEN** it SHALL exit non-zero and MUST NOT report a passing result

### Requirement: Skill-count gates track the actual pack
Gates asserting a public skill count SHALL derive it from the pack rather than a
hardcoded literal that the pack can outgrow.

#### Scenario: The pack gains a skill
- **WHEN** a new public skill is added and declared
- **THEN** the discovery gate SHALL continue to exit 0 without a manual literal edit
