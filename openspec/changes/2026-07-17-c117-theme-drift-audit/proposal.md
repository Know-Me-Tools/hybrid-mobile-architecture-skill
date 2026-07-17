# 2026-07-17-c117-theme-drift-audit

> Phase: cross-platform-app-theming · Status: proposed
> Depends on: 2026-07-17-c114-token-pipeline
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

The binding requirement is an invariant, and invariants need enforcement, not
convention. The phase goals explicitly require "lint/audit support so it's enforced
automatically in every scaffolded project, not left to manual review." Nothing in
`scripts/audit.sh` checks theme parity today. OpenDesign's token-first migration proved
the pattern: a guard that fails the build on off-token values is what actually stops
drift (their guard bans default Tailwind palette utilities; ours bans the Flutter-side
equivalents).

## What changes

Extend `scripts/audit.sh` with a `theme` check (wired into `flutter`, `tauri`, and
`all` modes):

- **Hash check:** recompute `sha256(design/tokens.json)` and compare against the stamp
  in every generated file header (`tokens.g.dart`, the CSS token block, `DESIGN.md`).
  Mismatch = stale generated output = fail with "run pnpm tokens:build".
- **Hand-edit check:** generated files carry a `GENERATED — DO NOT EDIT` marker; audit
  fails if the marker is missing (file was replaced) — the hash check catches content
  edits.
- **Flutter lints:** fail on `ColorScheme.fromSeed(` anywhere in app code, and on raw
  `Color(0xFF…)` literals outside `*.g.dart` (allowlist mechanism for genuine
  user-content/canvas colors, mirroring OpenDesign's narrow-allowlist discipline).
- **Web lint:** fail on hex/rgb color literals in `src/**/*.tsx` outside the generated
  token file (same allowlist file).

## Impact

- `scripts/audit.sh` + a small allowlist file convention (`design/token-audit-allow.txt`).
- Additive check; projects without `design/tokens.json` skip it with a notice (no
  retroactive breakage).
