# Documentation map and authority

This repository contains product documentation, specifications, generated
reference material, dated research, and implementation evidence. They answer
different questions and must not be treated as interchangeable authority.

## Current operational documentation

The Docusaurus source under `site/docs` is the public operational manual:

- installation and first-project workflow;
- full CLI reference;
- application profiles and design rationale;
- one generated page for every canonical Builder skill;
- service and integration-boundary catalog;
- utility, template, and CI catalog; and
- common use-case recipes.

The public site is:

[KnowMe Builder documentation](https://know-me-tools.github.io/hybrid-mobile-architecture-skill/)

## Package authorities

| Source | Authority |
|---|---|
| `builder.manifest.json` | Package identity, profiles, skills, commands, templates, generated targets, supported harnesses |
| `versions.toml` | Builder application-stack pins and engine selections |
| `compatibility/prometheus-control-plane.json` | Required Prometheus development-control contract |
| `compatibility/uar-runtime.json` | Required UAR runtime contract |
| `skills` | Canonical public skill instructions |
| `templates/project-skills` | Generated project/scaffold skill projection |
| `assets/templates` | Canonical generated application artifacts |
| `tools/knowme-builder` | Generation, adoption, ownership, upgrade, audit, and doctor behavior |

Generated plugin manifests, harness trees, command wrappers, activation
manifests, command bindings, and public skill pages are reviewable projections
of those authorities.

## Architecture and standards

- `references/arch-standard.md` is the application architecture standard.
- `references/rust`, `references/flutter`, `references/tauri`,
  `references/auth`, and `references/sync` provide progressively disclosed
  implementation contracts.
- `docs/knowme-ui-ux-standard.md` is the detailed cross-surface UI standard.
- `docs/tj-arch-mob-001.html` and `docs/gen_ui_spec.html` are historical formal
  specification artifacts. When they conflict with the 2.0 manifest,
  compatibility descriptors, or current typed code, the current sources win.

## Prompting documentation

`docs/prompting` contains harness playbooks, scenarios, model routing, and
orchestration guidance. Model IDs and capabilities are dated inputs and are
validated separately from stable application architecture.

Prometheus owns workflow lifecycle. Builder prompting guidance does not own
pause, resume, lease, handoff, or mutation authority.

## Research and dated assessments

Files under `docs/research`, dated assessments, competitive analyses, and
reference-app documents are evidence and prior-art analysis. Their conclusions
may be superseded.

Before acting on a claim from a dated document:

1. check its date and stated scope;
2. compare it with `builder.manifest.json`, compatibility descriptors, current
   code, and current consumer state;
3. reproduce defects rather than assuming they remain;
4. retain useful rationale even when the recommendation is obsolete; and
5. update current operational documentation when a validated decision changes.

## Private and excluded sources

Raw Prometheus wikis, live KBD projections, session/event logs, credentials,
personal information, client notes, and production data are not public
documentation inputs.

The Docusaurus sanitizer rejects common private-source indicators and
machine-local paths. Public pages synthesize reviewed conclusions rather than
copying private evidence.

## Updating documentation

When a skill changes:

```bash
node site/scripts/generate-skill-reference.mjs
node site/scripts/generate-skill-reference.mjs --check
```

When package metadata changes:

```bash
knowme-builder manifest generate
knowme-builder manifest check
```

Before publication:

```bash
cd site
npm ci
npm run release:check
```

Never edit `site/build`, generated harness trees, or generated skill pages as
independent sources.
