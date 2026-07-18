## ADDED Requirements

### Requirement: Evidence-qualified generator history
The OpenAI Proxy case study SHALL distinguish operator-provided lineage, initial
generator output that commit evidence can establish, capabilities added later, current
source behavior, public-boundary verification, inference, stale claims, and unsupported
claims.

#### Scenario: Generator provenance is not independently recorded
- **WHEN** the repository history cannot prove that a current capability came from the
  native-agent generator
- **THEN** the case study SHALL label the lineage as operator-provided or inferred and
  MUST NOT present it as verified generator output

### Requirement: Current architecture map
The case study SHALL map the current Axum service, OpenAI-compatible API, MCP
stdio/HTTP, ACP, AG-UI, optional A2A, skills, memory, Docker packaging, and OpenCode
plugin to source paths and typed/public protocol boundaries.

#### Scenario: Capability is documented as current
- **WHEN** the case study claims a protocol or package exists
- **THEN** it SHALL cite the current source location and identify the command or public
  consumer evidence that verifies the claim

### Requirement: Authentication and model claims are bounded
The public case study MUST NOT document subscription-authentication techniques or model
catalog claims as supported unless current vendor documentation explicitly supports
them. Stale catalog or authentication material SHALL be excluded or clearly marked
historical and unsupported.

#### Scenario: Source contains an undocumented authentication technique
- **WHEN** local proxy code implements a vendor flow that current official
  documentation does not support
- **THEN** the public guide SHALL omit operational instructions for that flow and record
  only the architectural risk at an appropriate level

### Requirement: Skill-versus-native-agent decision contract
The guide SHALL define a repeatable lifecycle test: a skill owns repeatable
host-executed instructions, while a native agent is warranted when the capability owns
a process, typed protocol endpoint, durable state, concurrency, authentication,
deployment, public consumer contract, or independent release lifecycle.

#### Scenario: Capability is procedural
- **WHEN** the capability can run inside an existing host without owning independent
  runtime state or protocol lifecycle
- **THEN** the guide SHALL route to skill creation or extension

#### Scenario: Capability owns lifecycle boundaries
- **WHEN** the capability owns one or more native-agent lifecycle criteria
- **THEN** the guide SHALL route to the native-agent creator and require typed
  contracts, packaging, launch, and consumer verification
