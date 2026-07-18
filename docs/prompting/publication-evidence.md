# Prompting guide publication evidence

**Date:** 2026-07-18  
**OpenSpec change:** `prompting-guide-publication-gates`

## Release gate evidence

The documentation release gate was run from the repository root:

```bash
npm --prefix site run release:check
```

Observed result: passed.

Fresh clone proof was also run from commit `6e1d158` in
`/tmp/knowme-docs-clone.yTAkQa/repo/site` with no preexisting `site/node_modules` or
`site/build`:

```bash
npm ci
PLAYWRIGHT_BROWSER_CHANNEL=chrome npm run release:check
```

Observed result: passed. The fresh clone reported 46 internal links and 83 bounded
external links with 200 status after this evidence page was included.

The gate includes:

- public-content sanitization;
- prompting schema and semantic validation;
- negative fixtures, including rejection of bare `gpt-5.6` model IDs;
- orchestration skill parity and scratch exercise;
- KnowMe Flat 2.0 style contract validation;
- generated model-routing drift check;
- Docusaurus production build;
- built-route, sitemap, local-search, and OpenGraph assertions;
- fatal internal link check;
- bounded external link check;
- browser publication gate across desktop/dark and mobile/light viewports, including
  required routes, prompt blocks, Mermaid/SVG rendering, keyboard focus, Flat 2.0
  shadow check, and axe serious/critical scan.

## Pages workflow evidence

`.github/workflows/docs-pages.yml` uses full-SHA action pins and runs the release gate
before uploading the GitHub Pages artifact. The workflow keeps this repository in the
static documentation lane only: it builds and deploys the static site and does not
attempt application deployment, cluster mutation, or live service rollout.

## Harness certification evidence

Installed harness versions observed on 2026-07-18:

| Harness | Version evidence |
|---|---|
| Codex | `codex-cli 0.0.0` |
| OpenCode | `0.0.0-dev-202607032021` |
| Kimi Code CLI | `0.26.0` |
| Zed | `Zed 1.11.3` |
| Claude Code | `2.1.212` |

The `orchestrate-prometheus-application` skill was validated across the canonical
template and project-local harness skill directories, then exercised by
`site/scripts/test-orchestration-skill.mjs`. The exercise checks scenario
classification, required Feynman/KBD sequencing, registry-derived producer/critic
selection, Karpathy retention requirements, missing-capability skill/native-agent
routing, and the `hybrid-runtime-verification` completion gate.

## Representative recipe coverage

The full KnowMe hybrid recipe is present in both structured and public forms:

- `docs/prompting/data/recipes/full-knowme-hybrid.json`
- `docs/prompting/scenarios/full-knowme-hybrid.md`

Validation proves the recipe contains staged prompts for prerequisites, discovery,
Feynman learning, KBD assessment/analyze/spec/plan, research, bounded implementation,
public-boundary verification, independent critic review, reflection retention, recovery,
and stop conditions.

The ACP/CLI representative harness coverage is captured through OpenCode and Kimi Code
CLI harness records and pages:

- `docs/prompting/data/harnesses/opencode.json`
- `docs/prompting/harnesses/opencode.md`
- `docs/prompting/data/harnesses/kimi-code-cli.json`
- `docs/prompting/harnesses/kimi-code-cli.md`

## Completion boundary

This evidence certifies the prompting-guide publication gates. It does not certify the
previously deferred multi-architecture image-build work, live Kubernetes rollout, or
Intel-box container build tasks.
