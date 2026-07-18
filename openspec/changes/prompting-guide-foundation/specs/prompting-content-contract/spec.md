## ADDED Requirements

### Requirement: Canonical prompting source
The project SHALL maintain `docs/prompting/` as the only human-edited source for the
public prompting guide. The documentation site MUST consume that source directly or
through a deterministic generated copy whose parity is checked during the build.

#### Scenario: Direct external source succeeds
- **WHEN** the pinned Docusaurus build can consume `../docs/prompting`
- **THEN** the prompting plugin SHALL use that path and the hand-maintained
  `site/docs/prompting/` summaries SHALL be removed

#### Scenario: Direct external source is incompatible
- **WHEN** a clean build proves that Docusaurus cannot safely consume the parent path
- **THEN** a prebuild step SHALL generate the site copy, mark it generated, and fail
  when its content hash differs from the canonical source

### Requirement: Structured prompt recipe contract
Every scenario recipe SHALL declare machine-readable metadata and contain non-empty,
copyable prompts for prerequisites and discovery; Feynman learning; KBD assess,
analyze, spec, and plan; bounded research and implementation; public-boundary
verification; independent criticism; reflection and retention; recovery; and stop
conditions.

#### Scenario: Complete recipe is validated
- **WHEN** a recipe declares all contract fields and every required prompt block has
  executable content
- **THEN** shape and semantic validation SHALL accept it

#### Scenario: Outline masquerades as a recipe
- **WHEN** a recipe merely names a stage, omits its prompt, or leaves an empty fenced
  block
- **THEN** validation SHALL fail with the missing stage and source path

### Requirement: Authority and evidence contract
Every recipe and playbook MUST declare operator authority, allowed write roots,
external side-effect boundaries, budget and retry limits, human checkpoints, expected
artifacts, observable success evidence, independent critic role, and termination rule.

#### Scenario: Completion claim lacks public evidence
- **WHEN** content permits an agent to call work complete without a named
  public-boundary observation or independent verification
- **THEN** semantic validation SHALL reject the content

### Requirement: Skill and architecture references resolve
Prompting content SHALL reference only skills present in the canonical template or a
supported installed package, and platform recipes MUST conform to TJ-ARCH-MOB-001 and
the 40 Prometheus Base Rules.

#### Scenario: Visual component bypasses shared architecture
- **WHEN** a hybrid recipe assigns networking, LLM, inference, agent logic, or
  persistence to Dart or TypeScript instead of the shared Rust core
- **THEN** the architecture audit SHALL fail the recipe

#### Scenario: Referenced skill is absent
- **WHEN** recipe metadata names a skill that cannot be resolved from the supported
  project skill sources
- **THEN** semantic validation SHALL report the unresolved skill and fail

### Requirement: Public and private content separation
The public guide MUST contain only reviewed, sanitized synthesis. Raw `.prometheus`
events, private Karpathy wiki pages, conversation/session logs, secrets, credentials,
personal information, unsupported claims, and machine-specific absolute paths SHALL
never enter the site build.

#### Scenario: Prohibited source material is introduced
- **WHEN** a canonical prompting file contains a prohibited path, secret pattern, raw
  private-log marker, or private-wiki source
- **THEN** sanitization SHALL stop the production build and identify the source file

#### Scenario: Private learning informs public guidance
- **WHEN** a private record contains a reusable lesson
- **THEN** only reviewed, source-supported synthesis SHALL be authored into the
  canonical public guide
