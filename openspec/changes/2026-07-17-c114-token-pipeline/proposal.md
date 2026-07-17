# 2026-07-17-c114-token-pipeline

> Phase: cross-platform-app-theming · Status: proposed
> Depends on: (none)
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

The binding phase requirement — Flutter theme **precisely identical** to the React 19
theme — has no mechanism. The assessment proved three-way drift in `apps/knowme-poc`
(real tokens only in `desktop/src/index.css`; stale unrelated `tokens.dart`; `main.dart`
using stock `ThemeData.dark()`), and the analyze stage confirmed nothing adoptable
exists anywhere (zero GitHub results for Tailwind↔Flutter theme sync; all pub.dev token
codegen packages 1-like/alpha/abandoned). This change builds the missing tool.

## What changes

Add a **token pipeline template** to the skill package (`templates/theme-pipeline/`)
consisting of:

- `design/tokens.json` — W3C DTCG token source (color light+dark, typography, spacing,
  radius, elevation, motion). Single source of truth.
- `design/theme.config.mjs` — Style Dictionary v5 (`style-dictionary@^5.5`, npm health
  verified 2026-06) config declaring four outputs, **including the authored
  brand→Material semantic mapping passed as options to the Dart format** (decision:
  mapping lives in config, not in tokens.json — DTCG has no file-level `$extensions`
  and a mapping group would parse as tokens).
- **Output 1 (adopt, config-only):** CSS custom properties in the exact shape
  `desktop/src/index.css` already uses — Tailwind v4 `@theme` block + `body.light`
  overrides.
- **Output 2 (build, the core):** custom Dart format emitting
  `lib/core/theme/tokens.g.dart`: explicitly constructed `ColorScheme` light+dark via
  the **full constructor** (`.fromSeed` banned for defined brand colors — it invents
  values), `TextTheme`, and an `AppTokens ThemeExtension<T>` (raw brand colors, spacing,
  radii, elevation) with `copyWith`/`lerp`.
- **Output 3 (build, small):** generated `DESIGN.md` brand spec (consumed by c119's
  OpenDesign entry).
- **Output 4:** every generated file's header carries `sha256` of `tokens.json`
  (consumed by c117's drift audit).
- Runtime wiring template: `@riverpod` `Notifier<ThemeMode>` + derived
  `Provider<ThemeData>` (no extra package; `flex_color_scheme` rejected-for-now per D6).
- Fixed unit policy: **1rem = 16 logical px/dp**, divergence under user text-scaling
  documented, not compensated.

Invocation: root `pnpm tokens:build` script (Node 24 already a required tool).

## Impact

- New `templates/theme-pipeline/` in the skill package; no existing scaffold behavior
  changes yet (c116 wires it in). Additive.
- Establishes the semantic-token scope of "precisely the same": identical token values
  through each platform's own rendering pipeline — not pixel-identical rendering
  (unachievable across Skia and browser engines; see assessment pitfalls).
