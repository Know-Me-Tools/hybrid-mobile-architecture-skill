# PLAN: build-detailed-prompting-guide

Project: Hybrid Mobile Architecture Skill
Date: 2026-07-18
OpenSpec available: YES
Changes to implement: 5
Backend: OpenSpec 1.6 spec-driven (`proposal → specs → design → tasks`)
Model policy: absent; KBD fallback makes Plan and every high-complexity change
frontier-class

## Ordering rationale

The five Spec changes form one strict value chain. Foundation establishes the only
editable source, content schemas, source/privacy policy, and registry-derived routing.
Harness/loop pages consume those contracts. Scenario recipes then compose the contracts
and playbooks. The agent/orchestration change cannot route to recipes until they exist.
Publication gates integrate and certify all prior output.

All five changes touch the canonical prompting tree or its publication pipeline, so
there is no safe change-level parallel wave. The KBD one-task-per-turn ledger is the
execution grain: each change contains bounded tasks even though its overall routing
score is High because each has more than eight tasks.

## CHANGE LIST (ordered)

### 1. `prompting-guide-foundation`: canonical source, content contracts, and model evidence

- **Scope:** documentation source, Docusaurus input, JSON Schema, Node validation,
  model registry, routing generation, sanitizer
- **Depends on:** NONE
- **Library:** `cand-001` Docusaurus/plugin-content-docs (adopt), `cand-002` local
  search (adopt), `cand-003` Ajv (adopt)
- **Build-required gaps:** `gap-canonical-prompting-source`,
  `gap-model-evidence-routing`, `gap-content-verification`,
  `gap-publication-boundary`
- **Recommended agent:** Codex
- **Est. complexity:** L
- **Complexity score:** High
- **Model class:** frontier
- **Customer value:** HIGH
- **Tasks:** 11
- **Details:** Establish `docs/prompting/` as the only editable source, with a
  deterministic-copy fallback only if a fresh Docusaurus build disproves direct parent
  consumption. Add Ajv shape validation plus project semantic checks, reconcile every
  requested model label against official evidence, generate role routing, and extend
  the privacy boundary before migrating summaries.
- **Exit evidence:** negative fixtures fail correctly; supported/unverified model
  inventory is explicit; generated routing has no drift; sanitizer and clean production
  build pass; canonical-source decision is recorded.

### 2. `prompting-guide-harness-loops`: six harness playbooks and executable control loops

- **Scope:** canonical harness and loop documentation, metadata/evidence maps,
  command/source verification
- **Depends on:** `prompting-guide-foundation`
- **Library:** `cand-007` Agent Skills specification (adopt)
- **Build-required gaps:** `gap-six-harness-playbooks`, `gap-loop-invocations`
- **Recommended agent:** Claude Code
- **Est. complexity:** L
- **Complexity score:** High
- **Model class:** frontier
- **Customer value:** HIGH
- **Tasks:** 14
- **Details:** Publish separate operational playbooks for Codex, Claude Code, OpenCode,
  Kimi Code CLI, Antigravity, and Zed with actual discovery, skill/plugin/MCP,
  permissions, autonomy, evidence, recovery, and handoff semantics. Publish executable
  Feynman, KBD, Karpathy, PMPO, producer/critic, autonomous, recovery, skill-creation,
  and native-agent loops from the installed contracts.
- **Exit evidence:** all six inventories satisfy their source-dated contracts; loop
  examples have exact commands, artifacts, budgets, failure branches, closure, and next
  waypoints; copyable installed commands are exercised or labeled unverified.

### 3. `prompting-guide-scenario-recipes`: ten complete staged application recipes

- **Scope:** canonical scenario taxonomy, ten detailed recipe pages, architecture and
  role-routing validation
- **Depends on:** `prompting-guide-foundation`, `prompting-guide-harness-loops`
- **Library:** none; substantive recipe content is build-required
- **Build-required gap:** `gap-ten-scenario-recipes`
- **Recommended agent:** Claude Code
- **Est. complexity:** L
- **Complexity score:** High
- **Model class:** frontier
- **Customer value:** HIGH
- **Tasks:** 13
- **Details:** Replace outlines with full staged prompt packs for hybrid, Flutter-only,
  Tauri local inference, automation, SaaS, local agent client, ideation studio, native
  Rust agent, multi-cloud deployment, and branded docs. Every recipe carries discovery,
  Feynman, KBD, research, implementation, public verification, critic, retention,
  recovery, authority, budgets, artifacts, and stop prompts while preserving shared
  Rust, PEM 3.x, Shadcn/Assistant UI, deployment, and Flat 2.0 rules where applicable.
- **Exit evidence:** exactly ten stable IDs resolve to full pages; every stage has a
  non-empty copyable prompt; architecture, skill, role, recovery, and termination
  validators pass; an independent evidence matrix covers all normative scenarios.

### 4. `prompting-guide-agent-orchestration`: case study, decision guide, and routing skill

- **Scope:** OpenAI Proxy evidence synthesis, skill/native-agent decision guide,
  canonical project skill, six harness copies, generated activation instructions
- **Depends on:** `prompting-guide-foundation`, `prompting-guide-harness-loops`,
  `prompting-guide-scenario-recipes`
- **Library:** `cand-008` existing orchestration skill (adapt)
- **Reference:** `cand-009` OpenAI Proxy repository (reference only)
- **Build-required gaps:** `gap-openai-proxy-case-study`, `gap-orchestration-skill`
- **Recommended agent:** Codex
- **Est. complexity:** L
- **Complexity score:** High
- **Model class:** frontier
- **Customer value:** HIGH
- **Tasks:** 10
- **Details:** Produce a source/commit-qualified generator-to-product case study without
  unsupported auth or model claims. Define the lifecycle boundary between a skill and
  typed native agent, then adapt the existing compact router to select the completed
  scenario/harness/loop/role/retention/verification assets and enforce
  `hybrid-runtime-verification` before completion.
- **Exit evidence:** claims are classified as verified, historical,
  operator-provided, inferred, stale, or unsupported; known and composite scenarios
  resolve in a scratch project; six skill copies and activation outputs pass parity;
  missing launch proof keeps completion false.

### 5. `prompting-guide-publication-gates`: branded publication and truthful certification

- **Scope:** Docusaurus integration, dependency/lockfile updates, route/search/sitemap,
  semantic/link/browser/a11y tests, Pages CI, representative harness evidence
- **Depends on:** all four prior changes
- **Library:** `cand-003` Ajv (adopt), `cand-004` Linkinator (adapt), `cand-005`
  Playwright Test (adopt), `cand-006` axe Playwright (adopt), `cand-011` existing
  GitHub Pages workflow (adopt)
- **Build-required gap:** `gap-content-verification`
- **Recommended agent:** Codex
- **Est. complexity:** L
- **Complexity score:** High
- **Model class:** frontier
- **Customer value:** HIGH
- **Tasks:** 14
- **Details:** Publish every canonical route in the KnowMe Docusaurus site with local
  search, nested sidebars, Flat 2.0 themes, and static-only privacy. Layer deterministic
  validation, bounded links, Playwright, axe, manual keyboard/visual evidence, fresh
  clone proof, and Pages upload gating; separately require a Codex and one ACP/CLI
  exercise before phase certification.
- **Exit evidence:** frozen clean build; all required route/sitemap/search records;
  prompt-copy, responsive/theme, keyboard and axe proof; no private/default content;
  Pages gates before upload; sanitized representative execution manifests and scratch
  skill proof.

## EXECUTION ROUND ORDER

1. **Round 1:** `prompting-guide-foundation`
2. **Round 2:** `prompting-guide-harness-loops`
3. **Round 3:** `prompting-guide-scenario-recipes`
4. **Round 4:** `prompting-guide-agent-orchestration`
5. **Round 5:** `prompting-guide-publication-gates`

No rounds are parallel. Each change edits or consumes the same canonical content and
generated site surfaces, and every dependency is normative rather than advisory.

## EXECUTION DISCIPLINE

- `/kbd-execute` writes the dispatch contract; `/kbd-apply` advances one unchecked
  OpenSpec task per turn. Do not invoke bare `/opsx:apply` for this phase.
- Run a frontier-class producer for every change because all task ledgers exceed eight
  tasks and cross documentation, validation, source evidence, or publication
  boundaries.
- Use a separate critic context/model role at each change boundary; a producer cannot
  certify its own completion.
- Keep changes in the current checkout unless a later task is proven file-disjoint.
  Do not create concurrent worktrees for shared `docs/prompting`, `site`, skill-copy,
  or workflow edits.
- Append project Karpathy evidence at each change start/verified end and the authorized
  private superset separately; never publish raw conversation or wiki content.

## COMMANDS TO RUN

The Spec stage already created and strictly validated these OpenSpec changes. The
historical `/opsx:new` creation commands MUST NOT be rerun:

```text
/opsx:new prompting-guide-foundation
/opsx:new prompting-guide-harness-loops
/opsx:new prompting-guide-scenario-recipes
/opsx:new prompting-guide-agent-orchestration
/opsx:new prompting-guide-publication-gates
```

The next lifecycle command is:

```text
/kbd-execute build-detailed-prompting-guide
```

After dispatch is written, task execution starts with:

```text
/kbd-apply prompting-guide-foundation
```

## SCOPE CUTS AND TRADE-OFFS

- Retain Docusaurus 3.10.1, local search, and GitHub Pages; no Astro migration or
  opportunistic Docusaurus upgrade.
- Publish reviewed synthesis only; raw `.prometheus`, private wiki, and session logs
  remain outside the public artifact.
- Structurally validate all ten recipes, but require live representative execution for
  one full-hybrid Codex path and one installed ACP/CLI path—not all sixty
  harness/scenario combinations.
- Treat requested model names without official evidence as unverified/unavailable;
  do not manufacture the desired routing table.
- Do not modify the OpenAI Proxy or other supporting repositories in this phase.
- These are five multi-task capability slices, not five single-turn edits. KBD task
  state, not chat history or elapsed time, controls resumability and completion.

## PHASE EXIT CRITERIA

- All 62 OpenSpec tasks are complete and all five changes pass strict verification.
- Six harness playbooks, executable loop guides, and ten complete recipe routes are
  present in the canonical source and public site.
- Requested model labels are reconciled against official evidence and routing views are
  generated without drift or invented claims.
- The OpenAI Proxy case study and lifecycle decision guide pass independent evidence
  review; the orchestration skill passes six-copy and scratch-project validation.
- Sanitization, schemas, semantics, architecture, sources, routes, search, sitemap,
  links, Docusaurus build, Playwright, axe, keyboard/visual, and fresh-clone gates pass.
- Representative Codex and ACP/CLI evidence manifests exist, GitHub Pages is published,
  Karpathy project/private records are committed as authorized, and tracked repository
  state is synchronized.

## SYCOPHANCY SELF-CHECK

- The mandatory detector ran at standard strictness for `pmpo_plan_phase`: score
  `0.017857`, one low-severity S-07 length signal, no mandatory correction. The detail
  is retained because the KBD output contract requires five fully annotated changes,
  execution rounds, commands, exit evidence, and scope cuts.
- **S-02:** Feasibility is grounded in the existing working Docusaurus/Pages path and
  strict OpenSpec artifacts; the plan does not claim the missing content already exists.
- **S-07:** Scope is limited to the requested guide, skill, and publication proof; it
  excludes framework migration, supporting-repository changes, and exhaustive harness
  execution.
- **S-03:** The plan surfaces serial execution, frontier cost, external-source
  freshness, representative-only runtime proof, and unverified-model outcomes rather
  than promising frictionless completion.

PLAN COMPLETE
