## Context

The current scenario file contains ten short outlines, while the public site contains
none of them. The foundation change defines a common contract and generated model-role
guidance; the harness/loop change defines the invocations these recipes must assemble.
This change supplies the substantive, copyable application-building workflows.

## Goals / Non-Goals

**Goals:**

- Deliver all ten promised scenario packs as first-class pages.
- Make each recipe executable in bounded stages with durable artifacts and recovery.
- Preserve scenario-specific architecture, safety, and verification obligations.

**Non-Goals:**

- Building each example application during documentation implementation.
- Hard-coding current model IDs in every recipe.
- Reducing the recipes to one giant “build everything” prompt.

## Decisions

### One page per scenario, one shared recipe anatomy

Each recipe will be a canonical page under `docs/prompting/scenarios/` with stable ID,
metadata, prerequisites, stage navigation, and fenced copyable prompts. Shared anatomy
will be validated, but scenario-specific requirements remain explicit and cannot be
satisfied by a generic paragraph.

### Stage prompts are independently resumable

Prompts will name their required inputs, allowed actions, expected outputs, checkpoint,
and next command. Durable KBD/OpenSpec/commit/wiki artifacts form the resume token;
chat history alone does not. Recovery prompts first inventory durable state, then
continue only the first incomplete stage.

### Architecture rules live in prompts and validators

Relevant recipes will cite TJ-ARCH-MOB-001 and `AGENT_BASE_RULES.md` and include
scenario-specific semantic checks. This avoids relying on readers to remember the
shared-Rust invariant, platform decision, PEM replacement, UI layering, GitOps
ownership, or public-boundary verification.

### Model routing is referenced by role class

Recipes will request roles such as architecture producer, bounded implementer,
independent critic, research synthesizer, or mechanical transformer. The generated
registry view resolves current candidates. This keeps recipes stable as vendors and
availability change.

### Completion is an evidence bundle

Each recipe ends with a required evidence manifest: artifacts, commands, public
observations, critic verdict, unresolved risks, Karpathy record, clean-status proof,
and explicit stop state. A prose completion claim cannot satisfy the recipe.

## Risks / Trade-offs

- **[Ten pages repeat shared language]** → centralize anatomy and link stable concepts,
  while keeping each copyable prompt self-sufficient enough to execute.
- **[Recipes become stale as skills change]** → validate skill references and use
  canonical command identifiers with dated harness wrappers.
- **[Prompt packs encourage excessive authority]** → require explicit write roots,
  external effects, budgets, destructive checkpoints, and stop conditions per stage.
- **[Documentation-only proof misses real harness behavior]** → publication gates will
  execute representative Codex and ACP/CLI fixtures.

## Migration Plan

1. Define the shared recipe navigation and stable IDs.
2. Expand the ten existing outlines into complete staged pages in dependency-aware
   batches: local application surfaces, agentic products, generators/deployment/docs.
3. Run schema, semantic, architecture, source, and route validation after each batch.
4. Replace the outline index with generated inventory only after all ten pages pass.
5. Roll back a failing page without changing the shared contract or other recipes.

## Open Questions

No product-scope question blocks the recipes. Exact producer/critic model candidates
remain registry-derived at build time, as required by the foundation change.
