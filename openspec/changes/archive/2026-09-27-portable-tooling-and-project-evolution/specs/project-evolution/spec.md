## Purpose

Define how the Builder creates runnable clean-architecture projects, adopts
brownfield projects without destructive ownership changes, and upgrades prior
generated outputs through explicit recoverable migrations.

## ADDED Requirements

### Requirement: Non-destructive brownfield integration
The builder SHALL inventory existing surfaces and preserve user-owned content when adopting or altering an existing project. It SHALL report architectural gaps without claiming absent surfaces are runnable.

#### Scenario: Adoption preview
- **WHEN** adoption is requested with `--check`
- **THEN** no files change and the result reports actual surfaces, integration steps and conflicts

### Requirement: Continuous versioned upgrades
The builder SHALL support explicit compatible migrations from prior outputs, preserve stable rendering inputs and user edits, and record applied migrations with recovery evidence.

#### Scenario: Edited managed output
- **WHEN** an upgrade conflicts with user changes
- **THEN** user bytes remain intact, proposed changes are inspectable and the applied version is not advanced

#### Scenario: Repeated migration
- **WHEN** a successful migration is applied again
- **THEN** it is a no-op

#### Scenario: Interrupted upgrade
- **WHEN** application fails after any write
- **THEN** the migration journal enables restoration of original bytes and metadata

#### Scenario: User edit after upgrade
- **WHEN** rollback detects content that matches neither its original bytes nor the applied output
- **THEN** rollback reports a conflict and preserves all files and version metadata

#### Scenario: Concurrent Builder operation
- **WHEN** another Builder upgrade holds the native project coordination lock
- **THEN** the new apply or rollback fails without writing managed application files

### Requirement: Verified runnable baselines
Runnable certification SHALL require full code generation, build and runtime evidence for each claimed surface and architecture. Unsupported inputs SHALL fail before destination writes.

#### Scenario: Missing native prerequisites
- **WHEN** requested FFI or target capabilities cannot be built on the current host
- **THEN** preflight reports the missing prerequisites and does not certify the generated project as runnable
