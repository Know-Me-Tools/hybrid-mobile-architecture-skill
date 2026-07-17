# 2026-07-17-c118-knowme-mobile-retrofit

> Phase: cross-platform-app-theming · Status: proposed
> Depends on: 2026-07-17-c114-token-pipeline, 2026-07-17-c117-theme-drift-audit
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

This is the binding user directive made concrete: "when we are doing flutter work, we
should use a theme that is precisely the same as the theme for the react 19 app in the
reference app." Today `apps/knowme-poc/mobile` renders stock `ThemeData.dark()` while
carrying an unused `tokens.dart` from a different brand entirely. The PoC is also the
worked example the phase goals require — the pipeline is only proven when the real app
passes the real audit.

## What changes

- Install the c114 pipeline into `apps/knowme-poc`: `design/tokens.json` seeded from
  the canonical values in `desktop/src/index.css`, root `tokens:build` script.
- Replace `mobile/lib/core/theme/tokens.dart` (stale travisjames.ai brand) with
  generated `tokens.g.dart` + `theme_provider.dart`; migrate the three existing import
  sites; wire both `MaterialApp`s to the provider-derived `ThemeData` (light + dark,
  dark default to match desktop).
- Regenerate `desktop/src/index.css`'s token block from the same source (values must
  round-trip identically — the seed came from this file).
- Run the c117 audit in `all` mode; the PoC must pass, including golden-test refresh
  (`flutter-golden-ui` loop) since widget colors legitimately change.

## Impact

- `apps/knowme-poc` mobile theme visibly changes from stock Material dark to the real
  KnowMe brand — the intended, user-directed outcome.
- Desktop CSS values must not change (round-trip identity is part of verification).
