# local-first-skills Specification

## Purpose
TBD - created by archiving change c121-local-first-skills. Update Purpose after archive.
## Requirements
### Requirement: Local-first project skills
The skill package SHALL ship four project-local skills — `sync-doctrine`,
`pem-local-first`, `client-rag`, and `peer-profile-sync` — in
`templates/project-skills/`, each with a directive ALWAYS-invoke description and
trigger words, citing the `references/sync/` doctrine, registered in the
skill-activation hook's trigger map, propagated by `add-project-skills.sh`, and
mirrored into the repo's harness skill directories.

#### Scenario: Sync-related prompt activates the skills
- **WHEN** a prompt in a scaffolded project mentions sync, offline, entities,
  vectors/RAG, or profile/vault/device-to-device concerns
- **THEN** the skill-activation hook SHALL nudge the matching skill(s) and the
  skill content SHALL point to the binding references/sync documents

#### Scenario: Scaffolded project receives the skills
- **WHEN** `add-project-skills.sh` runs against a project root
- **THEN** all four local-first skills SHALL be copied alongside the existing
  project skills with their activation hooks

