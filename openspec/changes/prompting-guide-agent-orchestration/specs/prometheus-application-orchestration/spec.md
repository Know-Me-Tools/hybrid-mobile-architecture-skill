## ADDED Requirements

### Requirement: Scenario classification and sequence selection
The `orchestrate-prometheus-application` skill SHALL classify user requests into the
ten documented scenarios or an explicit composition and select the required
architecture references, skills, harness playbook, control loops, and recipe stages.

#### Scenario: User requests a known scenario
- **WHEN** the request matches one of the ten scenario contracts
- **THEN** the skill SHALL identify that stable scenario ID and load only the relevant
  progressively disclosed references

#### Scenario: Request spans multiple scenarios
- **WHEN** a product needs capabilities from multiple recipes
- **THEN** the skill SHALL compose a dependency-ordered sequence and identify shared
  artifacts rather than issuing one unbounded build prompt

### Requirement: Incomplete knowledge starts with learning and KBD
The skill MUST begin with Feynman and KBD stages when requirements, architecture, or
operational knowledge is incomplete and SHALL preserve durable waypoints between
stages.

#### Scenario: Architecture choice is uncertain
- **WHEN** assessment reveals unresolved platform or responsibility boundaries
- **THEN** the skill SHALL route to learning and analysis before producing an
  implementation plan

### Requirement: Registry-derived producer and critic roles
The skill SHALL select independent producer and critic role classes from the generated,
dated registry and MUST NOT embed mutable model identifiers or unsupported capability
claims in `SKILL.md`.

#### Scenario: Preferred role candidate is unavailable
- **WHEN** the harness lacks the first generated candidate
- **THEN** the skill SHALL use another validated candidate for that role or request an
  operator choice while preserving role separation

### Requirement: Retention and completion gates
The skill SHALL require Karpathy records at phase boundaries and SHALL refuse
“working” or “complete” status until the relevant public-boundary evidence and
`hybrid-runtime-verification` contract pass.

#### Scenario: Producer reports completion without launch proof
- **WHEN** generated code builds but the requested real surface has not launched and
  exercised its public workflow
- **THEN** the skill SHALL keep the phase incomplete and route to verification

### Requirement: One canonical skill synchronized to six harnesses
The project SHALL maintain one template source for the orchestration skill and copy its
validated contents to `.claude/skills`, `.codex/skills`, `.opencode/skills`,
`.kimi/skills`, `.agents/skills`, and `.kimi-code/skills`, plus generated project
activation instructions.

#### Scenario: Harness copy drifts
- **WHEN** any installed project copy differs from the canonical template
- **THEN** the skill validation gate SHALL fail and report the divergent path

### Requirement: Real capability gaps use existing creators
The skill SHALL invoke the existing skill creator for repeatable procedural gaps and
the native-agent creator for typed lifecycle gaps only after research proves the gap is
real, reusable, and not already covered.

#### Scenario: Missing capability is reported
- **WHEN** a repeated gap is identified
- **THEN** the skill SHALL search existing capabilities, record the build-versus-adopt
  decision, select the correct creator, and require scratch/consumer verification
