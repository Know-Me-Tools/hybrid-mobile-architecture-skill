# Tasks — 2026-07-16-c113-mobile-platform-navigation

- [ ] T1 — RESEARCH (record sources, Rule 22-style provenance): current iOS HIG tab-bar
      guidance and Material 3 navigation-bar/tabs guidance; confirm the top-vs-bottom
      rules per platform and what the 2026 conventions actually say.
- [ ] T2 — DECIDE and record in decision-log.md: the mobile-web/PWA rule — adapt
      navigation to the detected platform (iOS→bottom, Android→per-M3), or commit to one
      convention across mobile web. Must be a single consistent choice, per user
      direction.
- [ ] T3 — Document the convention for the Flutter surface (bottom NavigationBar vs.
      top tabs; where the platform check belongs under the Riverpod layer contract).
- [ ] T4 — Document the convention for the React surface (mobile layout + PWA), honoring
      the T2 decision and the existing Hooks→Stores layer contract.
- [ ] T5 — Apply to the PoC's mobile surfaces as the worked example; verify on both
      platforms (iOS simulator + Android) that navigation lands per convention.
- [ ] T6 — Fold the guidance into the skill package so scaffolded projects inherit it
      (extend an existing UI skill or add one — decide at execute time; do not duplicate
      what `content-block-ui` / `hybrid-design-tokens` already own).
