## ADDED Requirements

### Requirement: Ten first-class scenario recipes
The guide SHALL publish exactly one complete, independently navigable prompt pack for
each requested scenario: full KnowMe hybrid; Flutter-only Rust FFI; Tauri local
inference; full-stack automation; multi-tenant SaaS; local desktop agent client;
business ideation studio; native Rust agent; source-built multi-cloud deployment; and
branded documentation portal.

#### Scenario: Required recipe inventory is validated
- **WHEN** the canonical recipe inventory is checked
- **THEN** all ten stable scenario identifiers SHALL resolve to pages and no required
  identifier SHALL be represented only by an outline or redirect

### Requirement: Complete staged prompt sequence
Every scenario SHALL provide copyable prompts for prerequisites and source discovery;
Feynman learning; KBD assess, analyze, spec, and plan; bounded research;
implementation waypoints; public-boundary verification; independent criticism;
reflection and Karpathy retention; interruption recovery; and final termination.

#### Scenario: User executes a recipe in stages
- **WHEN** the user copies the prompts in order and supplies the named prerequisites
- **THEN** each stage SHALL identify its expected artifacts, evidence, authority,
  budget, retry rule, human checkpoint, and exact next stage

#### Scenario: A stage fails or is interrupted
- **WHEN** expected evidence is absent, a retry budget is exhausted, or the session is
  interrupted
- **THEN** the recovery prompt SHALL resume from durable state or stop with a precise
  blocker without repeating completed work

### Requirement: Producer, critic, and harness variants
Every recipe SHALL select producer and critic role classes from generated model
routing, keep those roles independent, and provide invocation notes for each supported
harness without duplicating mutable model claims.

#### Scenario: Selected model is unavailable
- **WHEN** the preferred role candidate is unavailable in the user's harness
- **THEN** the recipe SHALL select another validated model in the same role class or
  require an explicit operator choice rather than inventing support

### Requirement: Architecture and safety invariants
Applicable recipes MUST enforce TJ-ARCH-MOB-001, the 40 Prometheus Base Rules, shared
Rust ownership, feature-based layering, Prometheus Entity Management instead of
TanStack Query, clean worktrees, atomic commits, explicit side-effect authority, and
public-boundary verification before completion.

#### Scenario: Hybrid recipe assigns core behavior to a UI layer
- **WHEN** a prompt or generated plan places networking, inference, MCP, agent logic,
  or persistence in Dart or TypeScript
- **THEN** the architecture check SHALL fail and return the responsibility to the
  shared Rust core

#### Scenario: React server-state layer introduces TanStack Query
- **WHEN** a recipe or generated implementation selects TanStack Query
- **THEN** it SHALL be rejected in favor of Prometheus Entity Management 3.x with the
  documented Zustand and PGlite/pglite-oxide client persistence architecture

### Requirement: Full KnowMe hybrid coverage
The full-hybrid recipe SHALL assign Flutter mobile, Tauri desktop, React/Axum web, and
the shared Rust runtime; require chat bubbles and ContentBlock/AG-UI event rendering;
and prove one cross-surface workflow plus local-first persistence and real launch.

#### Scenario: Full-hybrid recipe reaches completion
- **WHEN** its implementation stages finish
- **THEN** Flutter mobile, Tauri desktop, and React/Axum web SHALL consume the shared
  Rust contracts and at least one real workflow SHALL be observed through each
  required public surface

### Requirement: Flutter-only coverage
The Flutter-only recipe SHALL include feature/domain/data/presentation layering,
Riverpod code generation, FRB generation, Rust FFI ownership, simulator/device launch,
persistence restart proof, and cross-platform parity criteria.

#### Scenario: Flutter recipe is verified
- **WHEN** the recipe reaches its verify stage
- **THEN** generated bindings, analyze/tests, a real mobile launch, Rust-ready state,
  and persistence across restart SHALL be evidenced

### Requirement: Tauri local-inference coverage
The Tauri recipe SHALL cover model acquisition and fallback, explicit cache paths,
offline behavior, Assistant UI and shadcn-ui chat surfaces, PEM 3.x/Zustand storage,
pglite-oxide desktop persistence, streaming ContentBlocks, diagnostics, and a
packaging-equivalent launch.

#### Scenario: Tauri recipe is verified offline
- **WHEN** the configured local model has been acquired and network access is removed
- **THEN** a real prompt SHALL stream into chat bubbles, conversation state SHALL
  persist, and diagnostics SHALL identify the selected model and data paths

### Requirement: Automation and SaaS coverage
The automation recipe SHALL cover workflow state, approval authority, resumability,
event replay, destructive-tool checkpoints, and artifacts. The SaaS recipe SHALL cover
threat modeling, tenancy/RLS, optional Kratos/Gate/Keto identity, BYOK secret
boundaries, Forge/Fabric realtime isolation, anonymous-mode decisions, and deployment.

#### Scenario: Automation performs a destructive step
- **WHEN** a workflow reaches a destructive or externally visible operation
- **THEN** it SHALL stop at the declared approval checkpoint and persist replayable
  state before execution

#### Scenario: SaaS tenant boundary is verified
- **WHEN** two tenants use the public application boundary
- **THEN** data, realtime events, authorization, and BYOK secrets SHALL remain isolated
  and anonymous mode SHALL follow the explicit product decision

### Requirement: Local agent and ideation coverage
The local-agent recipe SHALL cover MCP trust, file grants, skill discovery,
conversation/event storage, model routing, approval denial, and audit replay. The
ideation recipe SHALL cover falsification, contradictory-evidence search, experiment
design, scoring, decision journaling, Feynman transfer, Karpathy retention, and
skill-generation thresholds.

#### Scenario: Agent tool request is denied
- **WHEN** the user denies a file, MCP, or external-effect request
- **THEN** the agent SHALL preserve the denial in the audit event stream and continue
  only within its remaining authority

#### Scenario: Ideation hypothesis survives review
- **WHEN** evidence, counter-evidence, experiments, and scores meet the declared rubric
- **THEN** the decision journal SHALL record the conclusion and the next falsifiable
  experiment rather than converting confidence into an unsupported build mandate

### Requirement: Native-agent and deployment coverage
The native-agent recipe SHALL cover capability classification, generator invocation,
one-core/adapter architecture, protocol consumer contracts, Docker proof, and the
skill-versus-agent test. The deployment recipe SHALL cover source locks, BuildKit
builds, SBOM/provenance, digest mirroring, Compose profiles, PostgreSQL 18/CNPG,
GKE/AKS/EKS rendering, GitOps promotion, ingress/gateway/TLS options, and the ban on
direct cluster deployment from CI.

#### Scenario: Native agent is selected
- **WHEN** the capability owns a process, typed protocol, durable state, or independent
  deployment lifecycle
- **THEN** the recipe SHALL invoke the native-agent creator and require consumer,
  package, Docker, and real-launch evidence

#### Scenario: Multi-cloud deployment is planned
- **WHEN** the recipe targets Kubernetes
- **THEN** it SHALL include NGINX Ingress, Traefik Ingress/Gateway, and pure Envoy
  Gateway examples with wildcard and Let's Encrypt certificate options, render every
  cloud overlay, and leave live-state promotion to the configured GitOps repository

### Requirement: Branded documentation coverage
The documentation recipe SHALL cover content classification, canonical source,
information architecture, KnowMe branding, Flat 2.0 light/dark rules, Mermaid, local
search, GitHub Pages/container publication, sanitization, accessibility, screenshots,
link recovery, and OpenGraph metadata.

#### Scenario: Documentation portal is complete
- **WHEN** the recipe reaches publication
- **THEN** a fresh build SHALL expose every required route with KnowMe branding, no
  private content, no visible borders or decorative shadows, accessible navigation,
  working search, and validated social-preview metadata
