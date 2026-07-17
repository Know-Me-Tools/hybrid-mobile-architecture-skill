# 2026-07-17-c115-theme-parity-skill

> Phase: cross-platform-app-theming · Status: proposed
> Depends on: 2026-07-17-c114-token-pipeline
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

The skill layer currently lies: `templates/project-skills/hybrid-design-tokens/SKILL.md`
claims `theme-factory` "emits BOTH a Tailwind/shadcn CSS token block and a Flutter theme
from one definition" — the vendored `theme-factory` is a static 10-theme picker for
slide decks with no compilation logic. Downstream agents get false confidence that
automated parity exists. With c114's pipeline real, the skill must document the actual
methodology and workflow.

## What changes

- **Rewrite `hybrid-design-tokens/SKILL.md`** to describe the real pipeline: edit
  `design/tokens.json` → `pnpm tokens:build` → never hand-edit generated files. Remove
  the false `theme-factory` delegation; keep `theme-factory` only as an optional
  *palette-ideation* reference, clearly labeled as not-a-compiler.
- **Add the methodology reference** `references/theming.md`: single-source token
  architecture, the brand→Material semantic-mapping discipline, the "identical token
  values, per-platform rendering" scope statement, known cross-platform pitfalls
  (Material tonal model vs flat palettes, font-metric differences, rem/dp policy),
  and the OpenDesign ideation on-ramp (pull tokens from an OD project via `od mcp`
  `get_artifact`/`get_file`; explicitly note push/KB-sync are unsupported today per
  `docs/plugins-spec.md` — daemon-only writes, 7 fixed `od.context` fields).
- **Update the reference index in `CLAUDE.md`** and the skill tables in
  `references/ui-skills.md` to point at the corrected skill + new doc.

## Impact

- Documentation and skill-template surface only; no generated-code behavior change.
- Every future scaffolded project receives a truthful skill instead of a false claim.
