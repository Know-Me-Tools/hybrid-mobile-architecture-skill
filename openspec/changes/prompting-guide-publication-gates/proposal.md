## Why

Markdown volume does not prove that users can find, copy, execute, or trust the guide.
The publication pipeline needs deterministic route, search, privacy, link, browser,
accessibility, and representative-harness evidence before GitHub Pages may advertise
the prompting system as complete.

> Scope: Docusaurus integration, semantic validation, browser/accessibility proof,
> representative execution fixtures, and GitHub Pages release gates.

## What Changes

- Publish the canonical prompting tree through the existing isolated Docusaurus plugin
  with nested sidebars, local search, complete sitemap routes, KnowMe branding, Flat
  2.0 light/dark behavior, and no hand-maintained duplicate summaries.
- Add Ajv-backed shape validation plus project semantic checks for staged prompts,
  skill references, producer/critic separation, architecture rules, source freshness,
  evidence contracts, authority boundaries, and public-boundary stop conditions.
- Adapt Linkinator for bounded built-site and official external-link checks with
  timeout, retry, and reviewed allowlist behavior.
- Add Playwright and axe checks for representative routes, search, theme, responsive
  layouts, keyboard/focus behavior, copyable prompts, and WCAG violations.
- Assert every required route appears in the build/sitemap and local-search index.
- Exercise one full-hybrid recipe in Codex and one representative recipe in an
  installed ACP/CLI harness, retaining commands, outputs, failures, and completion
  evidence without publishing private session material.
- Extend the pinned GitHub Pages workflow so all gates pass before artifact upload and
  deployment; CI remains static publication only.

## Capabilities

### New Capabilities

- `prompting-site-publication`: Canonical, navigable, searchable, branded, sanitized
  publication of all prompting-guide sections through Docusaurus and GitHub Pages.
- `prompting-guide-verification`: Schema, semantic, source, route, link, browser,
  accessibility, and representative-harness gates for truthful completion claims.

### Modified Capabilities

None.

## Impact

- Affects Docusaurus configuration/sidebars, `site/package.json` and lockfile, site
  scripts/tests, sanitizer scope, Playwright configuration, route inventory, local
  search assertions, and `.github/workflows/docs-pages.yml`.
- Adopts/adapts `cand-003` through `cand-006` and retains `cand-011`.
- Publication waits on all four content/orchestration changes.

## Dependencies

- `prompting-guide-foundation`
- `prompting-guide-harness-loops`
- `prompting-guide-scenario-recipes`
- `prompting-guide-agent-orchestration`
