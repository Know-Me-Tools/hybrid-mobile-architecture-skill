# Tasks — 2026-07-17-c118-knowme-mobile-retrofit

- [ ] T1 — Install the pipeline into `apps/knowme-poc` (design/, config, root script);
      seed `tokens.json` from `desktop/src/index.css`; author the KnowMe brand→Material
      mapping (ember→primary, cyan→secondary, red→error, green/amber semantic status,
      bg/surface/card→surface roles) in `theme.config.mjs`.
- [ ] T2 — Generate + wire mobile: delete stale `tokens.dart`, migrate its three import
      sites to `tokens.g.dart`/`AppTokens`, add `theme_provider.dart`, point both
      `MaterialApp`s at the derived `ThemeData` (dark default).
- [ ] T3 — Regenerate the desktop CSS token block from the same source; diff must show
      zero value changes (round-trip identity).
- [ ] T4 — VERIFY: `flutter analyze` + `flutter test` (goldens refreshed deliberately,
      per flutter-golden-ui loop); desktop `pnpm build` + vitest; c117 audit passes in
      `all` mode; side-by-side screenshot (mobile sim or golden vs desktop) recorded in
      the change notes as the parity evidence.
