## Context

The repository already ships a compact orchestration skill copied across six harness
directories, and the OpenAI Proxy repository provides a rich current example of an
Axum-based native agent. Neither currently supplies a verified generator-to-product
history, an operational skill-versus-agent boundary, or artifact-generating routing
for the ten recipes.

## Goals / Non-Goals

**Goals:**

- Turn OpenAI Proxy into a careful, source-inspected case study.
- Define a lifecycle-based skill/native-agent decision test.
- Upgrade the existing orchestration skill without creating a competing skill.

**Non-Goals:**

- Copying or modifying the OpenAI Proxy source repository.
- Publishing undocumented authentication instructions or stale model catalogs.
- Making `SKILL.md` contain the full prompting corpus.

## Decisions

### Compare history and current source, label every evidence class

The case study will use current source, public route/protocol definitions, packaging,
and available commit history. Statements will be tagged as verified current,
verified historical, operator-provided lineage, inferred, stale, or unsupported. This
protects the value of the example without rewriting uncertain history as fact.

### Use lifecycle ownership as the decision boundary

Feature complexity alone does not decide skill versus agent. The guide will use
process, protocol, state, concurrency, auth, deployment, consumer, and release
ownership because these produce testable architectural consequences.

### Keep the orchestration skill as a compact router

The canonical template will classify scenarios and emit a reference manifest pointing
to selected recipe, harness, loop, role class, retention, and verification contracts.
Detailed prompts remain in canonical docs. This follows progressive disclosure and
avoids six oversized, drifting skill copies.

### Synchronize through existing project tooling

The template remains authoritative. Existing copy/activation scripts will be extended
or reused to populate all six harness directories and generated `AGENTS.md`/`CLAUDE.md`
rules. A parity validator will enforce byte identity where harness wrappers do not
require a documented difference.

## Risks / Trade-offs

- **[Commit history cannot prove generator lineage]** → label operator-provided and
  inferred claims instead of overclaiming.
- **[Case study leaks unsupported auth behavior]** → require current official vendor
  support before publishing operational guidance.
- **[Compact skill does too little]** → define a concrete reference-manifest output and
  scratch-project validation while loading detailed docs progressively.
- **[Six copies drift]** → generate/copy from one template and fail parity checks.

## Migration Plan

1. Establish the case-study evidence table and current architecture map.
2. Publish the lifecycle decision guide.
3. Extend the canonical orchestration template to select the completed guide assets.
4. Synchronize all harness copies and generated-project activation rules.
5. Exercise known and composite scenario classifications in a scratch project.
6. Roll back the skill change from the canonical template if activation fails; case
   study content remains independently useful.

## Open Questions

No blocking question remains. Any generator lineage not supported by repository
history will retain its operator-provided label.

## Analyze reuse evidence

- **cand-008 — existing orchestration skill (adapt):** local source inspection found
  the same compact scenario-classification template copied to all six harness
  directories. It is the correct base, but it lacks artifact generation and validation.
  Source: <https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill/tree/main/templates/project-skills/orchestrate-prometheus-application>.
- **cand-009 — OpenAI Proxy (reference):** source inspection found Axum
  OpenAI-compatible routes, AG-UI, optional A2A, MCP stdio/HTTP, ACP stdio, memory,
  Docker, and an OpenCode plugin. The repository has no declared license, generator
  lineage is not independently proven, and auth/catalog text can become stale; it is
  reference evidence, not a dependency. Source: <https://github.com/GQAdonis/openai-proxy>.
