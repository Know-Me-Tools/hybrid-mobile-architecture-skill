## Why

The repository claims a comprehensive prompting system but currently maintains two
partial source trees and cannot prove that model claims, role routing, or recipe
structure are current and complete. A canonical, machine-checkable foundation is
required before the detailed guide can be authored or published truthfully.

> Scope: canonical prompting content ownership, content contracts, model evidence,
> and generated routing guidance. Detailed playbooks and scenario prose are separate
> changes.

## What Changes

- Make `docs/prompting/` the only editable source for public prompting guidance and
  configure the existing Docusaurus prompting plugin to consume that source.
- Define schemas and semantic rules for recipe metadata, harness metadata, model
  evidence, routing roles, authority boundaries, artifacts, and stop conditions.
- Strengthen the dated model registry with exact model identifiers, claim-to-source
  evidence, confidence, availability, and freshness policy.
- Generate model-role tables from the registry instead of duplicating routing claims
  in prose.
- Expand the public-content sanitizer to cover the canonical source and reject raw
  `.prometheus`, private-wiki, conversation-log, secret, personal, and machine-local
  material.
- Retain the proven Docusaurus 3.10.1, local-search, and GitHub Pages stack; framework
  migration and Docusaurus upgrades are out of scope.

## Capabilities

### New Capabilities

- `prompting-content-contract`: Canonical source ownership and machine-checkable
  structural, privacy, authority, and evidence contracts for prompting content.
- `model-evidence-routing`: A dated, official-source model registry whose validated
  entries generate task-role routing guidance without unsupported claims.

### Modified Capabilities

None.

## Impact

- Affects `docs/prompting/`, `site/docusaurus.config.mjs`, site validation scripts,
  model-registry data/schema files, generated routing content, and site build inputs.
- Adopts Ajv (`cand-003`) for schema validation and retains Docusaurus/local search
  (`cand-001`, `cand-002`).
- Establishes the required input contract for all later prompting-guide changes.

## Dependencies

None. This is the first change in the phase.
