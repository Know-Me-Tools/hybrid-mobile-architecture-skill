# Prometheus scenario prompt packs

Use these as staged prompts. Replace bracketed values and keep the approved plan as
an artifact between stages. Producer/critic choices are roles resolved from the
dated model registry, not permanent model endorsements.

## Shared phase prompts

**Plan:** “Run the Feynman/KBD assessment for this scenario. Read the binding rules
and selected skills. Produce a decision-complete waypoint plan with artifacts,
authority, clean-checkout criteria, budgets, retry limits, and a critic.”

**Implement:** “Implement only `[waypoint]`. Preserve existing work. Exercise the
public boundary once before adding 3–5 behavior tests. Record failures and stop after
two repeats of the same failed approach.”

**Verify:** “As an independent critic, grade the original criteria. Inspect the real
launch, persistence, packaging, security defaults, and omitted platforms. Do not
accept the producer summary as evidence.”

**Reflect:** “Append intent, observed behavior, evidence, failures, decision, and
reusable lesson to project Karpathy memory. Add private context only to the private
wiki. Advance the waypoint only on verified evidence.”

## 1. Full KnowMe hybrid application

- Prerequisites: Flutter beta, Rust 1.96, Node 24, Tauri 2.10, local model capacity.
- First prompt: “Plan a TJ-ARCH-MOB-001 KnowMe product with Flutter mobile, Tauri
  desktop, React/Axum web, and one shared Rust application layer.”
- Skills: orchestrate, scaffold hybrid, Rust/Flutter/Tauri patterns, ContentBlock UI,
  design tokens, accessibility, deploy stack, runtime verification.
- Roles: frontier architect; balanced implementation producers by surface; different
  family critic.
- Artifacts: shared types/services, thin adapters, chat bubbles, event persistence,
  Docker/Compose/GitOps, run evidence.
- Stop: Flutter, Tauri, and Axum execute the same persisted conversation workflow;
  local chat works without a key; clean checkout passes.

## 2. Flutter-only mobile with Rust FFI

- Prerequisites: Flutter beta, Xcode/Android toolchains, FRB version matched to Rust.
- First prompt: “Plan a Flutter iOS/Android app whose networking, persistence, and
  agent behavior live exclusively in the Rust core.”
- Skills: orchestrate, Flutter/Rust patterns, navigation, golden UI, accessibility,
  runtime verification.
- Artifacts: Riverpod-generated providers, domain repository, generated FFI, XCFramework
  and Android library, integration test.
- Stop: real simulator/device launch crosses FFI, persists state, and survives restart.

## 3. Tauri local inference desktop

- Prerequisites: platform compiler, Tauri CLI, a distributable local model strategy.
- First prompt: “Plan an offline-first Tauri agent with React 19, Shadcn UI,
  Assistant UI, PEM 3.x/Zustand, and Rust-owned inference/persistence.”
- Skills: orchestrate, Tauri/Rust, ContentBlock UI, titlebar, UI review, runtime verify.
- Artifacts: model manager, bubbles/composer/history, typed Tauri commands, app-data
  layout, diagnostics.
- Stop: packaged-equivalent launch downloads or discovers a safe default model and
  streams a persisted conversation with the network disabled.

## 4. Full-stack automation product

- Prerequisites: typed workflow domain and explicit tool authority.
- First prompt: “Model a Hands-style automation product with inspectable AG-UI tool,
  progress, approval, artifact, citation, and error events.”
- Skills: orchestrate, workflow/agent design, ContentBlock UI, deployment, runtime verify.
- Artifacts: workflow state machine, approval policy, event log/projection, scheduler,
  public API, operator UI.
- Stop: one real workflow pauses for approval, resumes, produces an artifact, and can
  be reconstructed from events.

## 5. Multi-tenant SaaS

- Prerequisites: tenant isolation model, threat model, cloud secret manager.
- First prompt: “Plan an optional authenticated SaaS using Kratos identity, Gate,
  Keto authorization, Forge/PostgreSQL, Fabric realtime, and tenant-safe BYOK.”
- Skills: orchestrate, auth/security, deploy stack, API design, runtime verify.
- Artifacts: tenancy types/RLS, identity mapping, authorization tuples, encrypted key
  references, audit log, cloud overlays.
- Stop: cross-tenant attempts fail at public and database boundaries; realtime and
  key access are identity-scoped; anonymous mode remains optional.

## 6. Claude Desktop-style local agent client

- Prerequisites: MCP threat model and per-capability permission design.
- First prompt: “Plan a local desktop agent client supporting MCP, skills, files,
  model routing, multiple conversations, and auditable tool approvals.”
- Skills: orchestrate, agent protocol, Tauri/Rust, ContentBlock UI, runtime verify.
- Artifacts: MCP host, skill loader, permission store, file grants, model registry,
  conversation/event store.
- Stop: a permissioned MCP tool executes through the UI, denial is enforced, and the
  transcript shows the complete auditable event chain.

## 7. Business ideation and validation studio

- Prerequisites: target market and evidence-quality rubric.
- First prompt: “Use a Feynman loop to clarify the customer/job, then create an
  evidence-seeking ideation workflow that challenges rather than flatters ideas.”
- Skills: orchestrate, research, product owner, Feynman/Karpathy memory.
- Artifacts: assumptions, experiments, sources, scoring rubric, decision journal,
  reusable research skills.
- Stop: a proposal has falsifiable assumptions, contradictory evidence, next tests,
  and a retained rationale—not merely generated enthusiasm.

## 8. Native Rust agent

- Prerequisites: stable job definition and protocol consumers.
- First prompt: “Use the native-agent creator to design one typed core with only the
  required HTTP/OpenAI, MCP, ACP, AG-UI, or A2A adapters.”
- Skills: orchestrate, native-agent creator, Axum, protocol/security, Docker.
- Artifacts: Rust crate, protocol adapters, health/readiness, config, container,
  public-boundary integration tests.
- Stop: each declared protocol passes a real consumer interaction and adapters share
  one behavior implementation.

## 9. Source-built multi-cloud deployment

- Prerequisites: pinned source commits, GHCR ownership, external GitOps repository,
  OIDC trust in GCP/Azure/AWS.
- First prompt: “Use the centralized catalog to build, attest, mirror, and promote
  immutable digests without direct cluster deployment.”
- Skills: orchestrate, deploy stack, ArgoCD multi-cloud, cloud architect, security.
- Artifacts: locks, Bake graph, SBOM/provenance, Compose profiles, CNPG catalog,
  GKE/AKS/EKS overlays, promotion commit.
- Stop: every target builds on amd64/arm64, profiles are ready, overlays render, and
  the exact GHCR digest exists in all approved registries and GitOps.

## 10. Branded documentation portal

- Prerequisites: authoritative brand/UI standard and content classification owner.
- First prompt: “Build a KnowMe-branded Docusaurus portal with multiple content
  owners, local search, Mermaid, Pages, container delivery, and private-data gates.”
- Skills: orchestrate, branded Docusaurus, design tokens, accessibility, runtime verify.
- Artifacts: source manifest, pinned site, theme, sanitizer, search, Pages workflow,
  container, visual/a11y evidence.
- Stop: fresh frozen install builds with no broken links; mobile/desktop light/dark
  routes are branded and accessible; private material is absent.
