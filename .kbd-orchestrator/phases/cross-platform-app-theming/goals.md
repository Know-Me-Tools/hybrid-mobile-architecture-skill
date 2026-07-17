# Goals

Add a cross-platform app theming skill, methodology, and reference architecture
to this skill package so that scaffolded hybrid projects (Flutter mobile + Tauri/
React 19 desktop, and any plain web/Tailwind surface) share exactly one design
token source of truth, with no drift between platforms.

## Primary goal

- **Author a new project skill** (e.g. `templates/project-skills/theme-parity/` or
  integrate into the existing `theme-factory` reference) that defines the
  methodology for deriving a single semantic token set (color, typography,
  spacing, radius, elevation, motion) and compiling it to:
  - React 19 + Tailwind CSS (CSS custom properties + Tailwind theme config)
  - Flutter `ThemeData`/`ColorScheme` (light + dark)
  - Shared design tokens artifact (JSON/YAML) that both compilers read from

## Binding requirement (explicit user directive)

- **When doing Flutter work in this repo's scaffolds, the Flutter theme MUST be
  precisely the same as the React 19 app's theme in the reference app** —
  same palette, same semantic roles, same typographic scale, same spacing
  rhythm — not just "visually similar." This is a hard architectural invariant,
  not a suggestion, and must be encoded as a skill (with lint/audit support)
  so it's enforced automatically in every scaffolded project, not left to
  manual review.

## Supporting goals

- Document the methodology: single source of token truth → per-platform
  compilers, referencing the existing `theme-factory` skill and
  `references/ui-skills.md` assessment as prior art.
- Provide a concrete worked example: derive tokens from the KnowMe reference
  app's React/Tailwind theme (`docs/reference-app/`) and compile matching
  Flutter `ThemeData`.
- Wire this into scaffolding: `scaffold-hybrid.sh` and `scaffold-flutter.sh`
  should reference/install the theming skill so new projects inherit parity
  by default, not as an afterthought.
- Add an audit/lint hook (extending `scripts/audit.sh` or the theming skill
  itself) that flags Flutter theme values that have drifted from the
  canonical token source.
- Update `CLAUDE.md` reference index to point at the new theming skill/docs.
