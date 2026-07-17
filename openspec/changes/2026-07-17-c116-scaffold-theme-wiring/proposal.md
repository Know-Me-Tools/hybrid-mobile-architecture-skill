# 2026-07-17-c116-scaffold-theme-wiring

> Phase: cross-platform-app-theming · Status: proposed
> Depends on: 2026-07-17-c114-token-pipeline
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

The drift is scaffold-designed, not accidental: `scripts/scaffold-flutter.sh:164`
hardcodes an unrelated placeholder `tokens.dart` and lines 1279/1290 hardcode
`theme: ThemeData.dark(useMaterial3: true)` into generated `main.dart`. Every new
project is born out of sync. Fixing only the PoC would leave the generator reproducing
the bug.

## What changes

- `scaffold-hybrid.sh`: copy `templates/theme-pipeline/` into new projects
  (`design/tokens.json`, `design/theme.config.mjs`, root `tokens:build` script) and
  **run the compiler once at scaffold time** so a fresh project is born in-sync.
- `scaffold-flutter.sh`: replace the hardcoded placeholder `tokens.dart` heredoc with
  generated `tokens.g.dart` + `theme_provider.dart` wiring; generated `main.dart` uses
  the provider-derived `ThemeData`, never `ThemeData.dark()`.
- `scaffold-tauri.sh`: emit `index.css` tokens from the same compiler output instead of
  an independent hand-written block.
- Single-surface scaffolds still receive the pipeline — the token source is the
  invariant even when only one surface exists yet.

## Impact

- Touches the three scaffold scripts; generated projects gain `design/` + a root
  `tokens:build` script. Existing scaffolded projects unaffected (c118 retrofits the
  PoC separately).
