## ADDED Requirements

### Requirement: Common executable loop contract
Every documented loop SHALL state its prerequisite state, exact invocation, input and
output artifacts, authority envelope, budget, retry limit, failure branch, human
checkpoint, closure evidence, retention action, and next waypoint.

#### Scenario: Loop is only described conceptually
- **WHEN** a loop page names phases but provides no executable command or artifact
  transition
- **THEN** validation SHALL reject it as an incomplete operational guide

### Requirement: Feynman learning loop
The guide SHALL teach an explain, grade, identify-gaps, re-study, transfer, and retain
loop that closes only when the stated grade and transfer criteria are evidenced.

#### Scenario: Architecture knowledge is incomplete
- **WHEN** a user cannot explain or transfer a required concept at the target grade
- **THEN** the loop SHALL return to the named evidence source and MUST NOT advance to
  architecture implementation

### Requirement: KBD lifecycle loop
The guide SHALL show the canonical assess, analyze, spec, plan, apply, verify, reflect,
and waypoint transitions using the actual `.kbd-orchestrator` state and handoff files.

#### Scenario: KBD stage completes
- **WHEN** a stage's artifacts and handoff pass its gate
- **THEN** the guide SHALL show the exact next command and the state fields that move
  the phase forward

#### Scenario: A required handoff is missing
- **WHEN** a later KBD stage is invoked without its prerequisite handoff
- **THEN** the example SHALL stop and show the canonical remediation rather than
  bypassing the gate

### Requirement: Karpathy retention loop
The guide SHALL require append-only project memory at phase boundaries and a sanitized
private superset when configured, recording intent, observations, evidence, failures,
decisions, reusable lessons, and the next experiment without publishing raw private
material.

#### Scenario: Phase evidence is retained
- **WHEN** a phase starts or reaches verified closure
- **THEN** project memory SHALL record the phase event and private memory SHALL receive
  only the authorized superset through its configured repository workflow

### Requirement: PMPO and producer-critic loop
The guide SHALL separate producer and critic roles, use explicit rubrics and
anti-sycophancy checks, and permit PMPO to improve prompt strategy without changing
requirements to fit a failed output.

#### Scenario: Critic finds unmet requirements
- **WHEN** independent review identifies a requirement without evidence
- **THEN** the loop SHALL return a bounded corrective prompt and MUST NOT weaken or
  delete the requirement

#### Scenario: Retry budget is exhausted
- **WHEN** the same failure reaches the declared retry limit
- **THEN** the loop SHALL stop with evidence, classify the blocker, and request a human
  decision rather than continuing autonomously

### Requirement: Autonomous development guardrails
Autonomous examples MUST use clean worktrees, atomic commits, explicit write and
external-effect boundaries, one public-boundary test per completed capability,
timeouts, budgets, stop conditions, and independent verification.

#### Scenario: Agent attempts self-certified completion
- **WHEN** the producing agent reports completion without the required public-boundary
  and critic evidence
- **THEN** the control loop SHALL keep the waypoint incomplete

### Requirement: Capability-generation loop
The guide SHALL teach users to create or extend a skill only for a real, repeatable
operational gap and to create a typed native agent when lifecycle ownership requires a
process, protocol, durable state, concurrency, authentication, deployment, or an
independent release.

#### Scenario: Repeated operational gap is confirmed
- **WHEN** Feynman/KBD reflection shows the same missing procedure across multiple
  tasks and no suitable capability exists
- **THEN** the guide SHALL route to the skill creator with a validation and scratch-use
  requirement

#### Scenario: Capability owns an independent runtime
- **WHEN** the missing capability requires typed protocol endpoints or independent
  lifecycle ownership
- **THEN** the guide SHALL route to the native-agent creator and require consumer
  contract, packaging, and launch evidence
