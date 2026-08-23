# release-tagging Specification

## Purpose
TBD - created by archiving change 2026-08-22-c305-first-release-tag. Update Purpose after archive.

## Requirements

### Requirement: Published guidance to pin a tag is backed by a tag
When the pack instructs consumers to pin a release tag, a matching tag SHALL exist and
SHALL resolve.

#### Scenario: A consumer follows the pin-a-tag guidance
- **WHEN** a consumer clones the pack at the tag named by its own guidance
- **THEN** the clone SHALL pass the consumer-install proof

### Requirement: A release tag points at a fully green tree
A release tag SHALL be cut only at a commit where the complete local gate set passes, and
that set SHALL be enumerated by an executable script rather than by prose.

#### Scenario: A gate is failing at tag time
- **WHEN** any gate in the enumerated set fails
- **THEN** the aggregate gate script SHALL exit non-zero and the tag SHALL NOT be cut

#### Scenario: Published manifests disagree with the tag
- **WHEN** a release is tagged
- **THEN** every published marketplace and plugin manifest SHALL carry the tagged version
  and a clean marketplace install from the tag SHALL succeed on every supported harness
