# Karpathy progress: prompting guide publication gates

**Timestamp:** 2026-07-18T11:20:51Z  
**Phase:** `build-detailed-prompting-guide`  
**Change:** `prompting-guide-publication-gates`

## Intent

Publish the detailed prompting guide through the KnowMe-branded Docusaurus site with
deterministic release gates, GitHub Pages workflow coverage, browser/accessibility
checks, and retention evidence.

## Observations

- Bare `gpt-5.6` appeared as a stale model route in legacy project wiki records.
- The correct OpenAI route for frontier GPT-5.6 use is the exact suffixed ID
  `gpt-5.6-sol`; the bare ID is invalid.
- Docusaurus generated extensionless routes as `.html` files, so the static browser
  gate needed `.html` fallback behavior to match GitHub Pages.
- Light-mode ember contrast was below AA for inline links and breadcrumbs.
- Playwright's bundled browser cache was locally inconsistent, so the gate uses
  installed Chrome locally and bundled Chromium in CI.

## Decisions

- Add a validation rule and negative fixture rejecting accidental bare `gpt-5.6`
  routing while allowing explanatory warnings that state the ID is invalid.
- Darken the light-mode ember accent and distinguish inline links with weight and
  background, preserving Flat 2.0 no-border/no-shadow rules.
- Use a direct Playwright script with an embedded static server for deterministic
  publication checks.
- Add `release:check` to the GitHub Pages workflow before artifact upload.

## Evidence

- `npm --prefix site run release:check` passed on 2026-07-18.
- Internal link scan reported 45 links with 200 status.
- External bounded link scan reported 82 links with 200 status.
- Browser publication gate passed for 2 viewports and 7 required routes.
- `docs/prompting/publication-evidence.md` records the public evidence set.
- Fresh clone proof from commit `6e1d158` passed `npm ci` and
  `PLAYWRIGHT_BROWSER_CHANNEL=chrome npm run release:check`; the fresh-clone scan
  reported 46 internal links and 83 external links after adding the evidence page.

## Reusable lesson

Model-routing documents should validate exact machine IDs separately from display-family
labels. Publication gates should test built static artifacts, not framework dev-server
behavior, because GitHub Pages serves static files.
