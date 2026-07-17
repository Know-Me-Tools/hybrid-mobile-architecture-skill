# 2026-07-17-c119-opendesign-design-system-entry

> Phase: cross-platform-app-theming · Status: proposed
> Depends on: 2026-07-17-c114-token-pipeline
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

The user wants OpenDesign (the fork at `~/Projects/references/open-design`) in the
ideation loop: designs authored there should drive code generation, and OpenDesign's
own AI should generate on-brand. The assessment verified what the fork supports today:
design systems are plugin entries (`open-design.json` + `DESIGN.md`, ~150 existing
examples) exposed as read-only MCP resources (`od://design-systems/<id>/DESIGN.md`),
and any agent can pull project artifacts via `od mcp`. Bidirectional push and KB/wiki
manifest fields are **not** supported and are explicitly out of scope (deferred to
their own proposal per the decision log).

## What changes

- Add `plugins/_official/design-systems/knowme/` (or `community/` per fork policy) to
  the OpenDesign fork: `open-design.json` following the exact existing convention
  (`od.mode: "design-system"`, `context.designSystem.ref: "knowme"`,
  `context.assets: ["./DESIGN.md"]`) + the c114-**generated** `DESIGN.md` (never
  hand-authored; regenerated on token change, hash-stamped).
- Document the round-trip workflow in `references/theming.md` (extends c115's doc):
  ideate in OpenDesign → pull artifact CSS via `od mcp get_artifact` → update
  `design/tokens.json` → `pnpm tokens:build` → regenerated `DESIGN.md` goes back into
  the fork entry. One-way pull loop, drift-guarded at both ends by the hash stamp.
- Validate per the fork's own publish checklist (`plugins/spec/SPEC.md` §10):
  JSON valid, `pnpm guard`, `od plugin validate` if available.

## Impact

- One additive directory in the OpenDesign fork; zero daemon/schema changes.
- This repo's `references/theming.md` gains the workflow section.
- Explicitly NOT included: conversational push into OD, KB/wiki context fields
  (separate proposals if pursued; `context.mcp[]` is the documented escape hatch).
