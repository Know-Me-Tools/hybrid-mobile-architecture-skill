# Prompting content inventory

**Inventory date:** 2026-07-18
**OpenSpec change:** `prompting-guide-foundation`
**Canonical editing root:** `docs/prompting/`

This inventory records the current prompting content surfaces before the
foundation change migrates the Docusaurus site to the canonical source. It also
assigns stable identifiers used by later schema and semantic validators.

## Source Trees

| Tree ID | Path | Status | Role |
|---|---|---|---|
| `tree-canonical-prompting` | `docs/prompting/` | canonical | Human-edited source for the public prompting guide and machine-readable registry data. |
| `tree-site-prompting` | `site/docs/prompting/` | transitional | Existing Docusaurus summaries retained until direct canonical-source consumption or generated-copy parity is proven. |

## Current Files

| Content ID | Path | Source tree | Type | Route ID | Owner |
|---|---|---|---|---|---|
| `content-prompting-guide` | `docs/prompting/prometheus-application-prompting-guide.md` | `tree-canonical-prompting` | guide | `route-prompting-guide` | canonical |
| `content-scenario-packs` | `docs/prompting/scenario-packs.md` | `tree-canonical-prompting` | recipe-index | `route-prompting-scenarios` | canonical |
| `content-model-registry` | `docs/prompting/model-registry.yaml` | `tree-canonical-prompting` | registry | `route-prompting-model-registry` | canonical |
| `content-model-registry-validator` | `docs/prompting/validate-model-registry.mjs` | `tree-canonical-prompting` | validation-script | none | canonical |
| `content-harnesses` | `docs/prompting/harnesses.md` | `tree-canonical-prompting` | guide | `route-prompting-harnesses` | canonical |
| `content-site-playbook-summary` | `site/docs/prompting/playbook.md` | `tree-site-prompting` | migrated-removed | `route-site-prompting-playbook` | removed after parent-source proof |
| `content-site-harness-summary` | `site/docs/prompting/harnesses.md` | `tree-site-prompting` | migrated-removed | `route-site-prompting-harnesses` | removed after parent-source proof |

## Stable Route Identifiers

| Route ID | Intended route | Canonical content ID |
|---|---|---|
| `route-prompting-overview` | `/prompting/overview` | pending detailed overview |
| `route-prompting-guide` | `/prompting/playbook` | `content-prompting-guide` |
| `route-prompting-harnesses` | `/prompting/harnesses` | pending harness playbooks |
| `route-prompting-loops` | `/prompting/loops` | pending executable loop guide |
| `route-prompting-scenarios` | `/prompting/scenarios` | `content-scenario-packs` |
| `route-prompting-model-registry` | `/prompting/models` | `content-model-registry` |
| `route-prompting-model-routing` | `/prompting/model-routing` | pending generated routing |
| `route-prompting-agent-orchestration` | `/prompting/agent-orchestration` | pending case study and decision guide |
| `route-prompting-publication-evidence` | `/prompting/publication-evidence` | pending publication proof |

## Scenario Identifiers

| Scenario ID | Scenario |
|---|---|
| `scenario-full-knowme-hybrid` | Full KnowMe hybrid application: Flutter mobile, Tauri desktop, React/Axum web, shared Rust. |
| `scenario-flutter-rust-ffi` | Flutter-only mobile application with Rust FFI. |
| `scenario-tauri-local-inference` | Tauri desktop application with local inference and offline persistence. |
| `scenario-full-stack-automation` | Full-stack automation product with Hands/workflows and agentic events. |
| `scenario-multi-tenant-saas` | Multi-tenant SaaS with optional Kratos, Gate, Keto, Forge, and Fabric. |
| `scenario-local-agent-client` | Claude Desktop-style local agent client with MCP, skills, files, and model routing. |
| `scenario-ideation-studio` | Business ideation and validation studio using Feynman and Karpathy loops. |
| `scenario-native-rust-agent` | Native Rust agent generated through the Prometheus native-agent creator. |
| `scenario-multi-cloud-deployment` | Source-built multi-cloud deployment using the deployment catalog. |
| `scenario-branded-docs-portal` | Branded documentation portal using the Docusaurus skill. |

## Harness Identifiers

| Harness ID | Harness |
|---|---|
| `harness-codex` | Codex |
| `harness-claude-code` | Claude Code |
| `harness-opencode` | OpenCode |
| `harness-kimi-code-cli` | Kimi Code CLI |
| `harness-antigravity` | Google Antigravity |
| `harness-zed` | Zed |

## Role Identifiers

| Role ID | Role |
|---|---|
| `role-frontier-architect` | Hard architecture, cross-repository synthesis, difficult root-cause work. |
| `role-balanced-producer` | Normal implementation, review, and bounded agent work. |
| `role-mechanical-transformer` | Low-risk high-volume transformation with clear acceptance checks. |
| `role-research-synthesizer` | Source-grounded research and synthesis before planning. |
| `role-independent-critic` | Separate verifier that grades evidence against original criteria. |
| `role-long-context-cartographer` | Large-context repository or document mapping. |
| `role-multimodal-reviewer` | Image, UI, diagram, and multimodal inspection. |

## Evidence Identifiers

| Evidence ID | Evidence |
|---|---|
| `evidence-official-source` | Dated official vendor or project documentation. |
| `evidence-local-command` | Captured command output from this repository. |
| `evidence-public-boundary` | Observable behavior through an app, API, CLI, package, or published site boundary. |
| `evidence-clean-checkout` | Reproduction from a fresh checkout without ignored artifacts. |
| `evidence-independent-critic` | Separate critic evaluation against original requirements. |
| `evidence-karpathy-record` | Project or private Karpathy memory entry. |
| `evidence-redaction-review` | Sanitization and private/public boundary proof. |

## Authority Identifiers

| Authority ID | Authority |
|---|---|
| `authority-repo-local-write` | May edit files in the current repository. |
| `authority-supporting-repo-read` | May read supporting repositories for evidence, without modifying them. |
| `authority-supporting-repo-write` | May modify supporting repositories only when explicitly authorized for the phase. |
| `authority-network-research` | May use web research and dated source capture. |
| `authority-external-publish` | May push, publish Pages, publish packages, or publish images when explicitly authorized. |
| `authority-destructive-cleanup` | May delete branches, worktrees, images, or environments only when explicitly authorized. |

## Artifact Identifiers

| Artifact ID | Artifact |
|---|---|
| `artifact-plan` | Decision-complete KBD or OpenSpec plan. |
| `artifact-guide-page` | Public documentation page. |
| `artifact-recipe-page` | Scenario recipe page with staged prompts. |
| `artifact-registry` | Machine-readable model or source registry. |
| `artifact-generated-routing` | Markdown generated from registry data. |
| `artifact-skill` | Reusable project-local skill. |
| `artifact-site-build` | Built Docusaurus site artifact. |
| `artifact-validation-report` | Schema, sanitizer, link, accessibility, or runtime verification output. |
| `artifact-karpathy-memory` | Project or private memory record. |

## Recovery Identifiers

| Recovery ID | Recovery |
|---|---|
| `recovery-two-failure-stop` | Stop after two repeated failures on the same approach and reassess. |
| `recovery-replan-at-kbd` | Return to KBD assess/analyze/spec/plan when assumptions fail. |
| `recovery-skill-gap` | Create or update a skill when a repeated operational gap is proven. |
| `recovery-human-checkpoint` | Ask the operator before external side effects, destructive actions, or authority expansion. |
| `recovery-clean-checkout-repro` | Reproduce from a fresh checkout before calling work complete. |

## Inventory Decision

Task 1.1 deleted no prompting files. Task 3.2 proved direct Docusaurus
consumption of `../docs/prompting` with a production build, and task 3.3 removed
the obsolete editable `site/docs/prompting/` summaries after migrating their
content into canonical pages.
