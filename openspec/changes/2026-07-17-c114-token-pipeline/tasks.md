# Tasks — 2026-07-17-c114-token-pipeline

- [ ] T1 — Author `templates/theme-pipeline/design/tokens.json` (DTCG) seeded from the
      real KnowMe tokens in `apps/knowme-poc/desktop/src/index.css` (18 colors × 2
      modes, 4 font families, plus spacing/radius/elevation/motion scales that CSS
      currently hardcodes inline). This is the canonical worked-example token set.
- [ ] T2 — Author `design/theme.config.mjs`: SD v5 config, DTCG parsing, the
      brand→Material mapping block (ember→primary, red→error, surface/card→
      surface/surfaceContainer, …) as Dart-format options, and the four outputs.
- [ ] T3 — Build the custom Dart format: full-constructor `ColorScheme` (light+dark),
      `TextTheme`, `AppTokens ThemeExtension<T>` with `copyWith`/`lerp`, token-hash
      header stamp. Generated file must compile clean under `flutter analyze`.
- [ ] T4 — Configure the CSS output to byte-match the semantics of the existing
      `desktop/src/index.css` `@theme` + `body.light` shape (names may normalize;
      values must be identical).
- [ ] T5 — Build the `DESIGN.md` output format (brand spec prose+tables from tokens).
- [ ] T6 — Add the Riverpod wiring template (`theme_provider.dart`) and a minimal usage
      snippet showing `MaterialApp(theme: ref.watch(themeDataProvider))`.
- [ ] T7 — VERIFY: run `pnpm tokens:build` on the template; diff CSS values against
      `desktop/src/index.css` (must be value-identical); `flutter analyze` the generated
      Dart in a scratch Flutter project; confirm hash stamps present in all outputs.

## Verification

- Value-parity proof: a script or documented diff showing every CSS custom property
  value equals the corresponding generated Dart constant (this IS the binding
  requirement, made mechanical).
- Generated Dart compiles; `ThemeExtension.lerp` round-trips light↔dark.
