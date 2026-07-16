# 2026-07-16-c113-mobile-platform-navigation

> Phase: phase-codegen-and-ci-verification · Status: proposed
> Assigned harness/model: claude/opus-4.8
> Depends on: (none)
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

Mobile UI must follow the host platform's navigation conventions, and the two platforms
disagree:

- **iOS** — bottom tab bar is the accepted standard (top tab bars are rare); Human
  Interface Guidelines.
- **Android** — Material 3 permits top or bottom placement depending on the pattern
  (navigation bar vs. tabs under a top app bar).

This applies to **both** UI stacks (React and Flutter), and extends to **mobile web
PWA**, where the same React bundle runs on an iOS or Android browser. Today nothing in
the skill package encodes this, so generated mobile UI risks a desktop-shaped or
uniformly-styled navigation that is wrong on at least one platform.

Per user direction, the PWA-by-platform choice must be **consistent** — a deliberate,
documented rule (adapt to detected platform, or pick one convention everywhere), not an
accident of whichever component an agent reached for.

## What changes

- Establish the per-platform navigation convention as guidance in the skill package
  (Flutter + React/Tauri surfaces), covering native mobile and mobile-web/PWA.
- Decide and document the PWA-by-platform rule (adaptive vs. single convention) —
  this is a decision to record in the phase decision-log, not to leave implicit.
- Apply the convention to the PoC's mobile surfaces so the guidance has a worked example.

## Impact

- Touches mobile navigation in the Flutter app and the React surface's mobile layout.
- Additive guidance; no change to the Rust core or the ContentBlock contract.
