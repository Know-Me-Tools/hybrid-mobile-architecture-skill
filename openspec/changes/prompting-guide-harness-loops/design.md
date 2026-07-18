## Context

The current source has one short paragraph per harness and names several loops without
teaching their actual commands or artifacts. The repository already contains project
skills, OpenSpec/KBD state, and harness-specific configuration, so the playbooks can be
grounded in current contracts instead of generic advice.

## Goals / Non-Goals

**Goals:**

- Give each harness an operational, official-source playbook.
- Make every learning/autonomy loop executable and bounded.
- Share stable concepts without erasing differences in permissions, modes, and state.

**Non-Goals:**

- Installing or globally configuring the harnesses.
- Promising feature parity where official sources do not support it.
- Embedding all detailed examples into one oversized `SKILL.md`.

## Decisions

### One page and evidence record per harness

Each harness will have a canonical Markdown page and machine-readable metadata for
required sections, official sources, and verification date. A shared introduction will
explain Agent Skills portability, but command and permission examples stay with the
owning harness. This avoids both duplication and false compatibility.

### Teach loops through state transitions

Loop pages will use a consistent anatomy: entry conditions, exact command/prompt,
created artifacts, closure test, failure/retry branch, retention, and next waypoint.
Examples will reference installed Prometheus skill contracts and committed KBD files,
not remembered aliases. A full producer→critic→retention transcript will connect the
individual loops.

### Version-sensitive claims require local proof plus official support

Commands will be checked against the installed version where practical and cited to an
official source with `verified_at`. Local-only observations will be marked unverified
instead of silently becoming public support statements.

### Detailed docs, compact skill routing

The orchestration skill will link to selected harness and loop pages through
progressive disclosure. Copying all playbooks into the skill would consume context and
create another source-of-truth problem.

## Risks / Trade-offs

- **[Harness documentation changes rapidly]** → attach dates, source mappings, and a
  freshness gate to every version-sensitive command.
- **[Examples expose local paths or credentials]** → use repository-relative paths and
  placeholders; run the canonical sanitizer.
- **[Loop examples invite unbounded automation]** → require budgets, retries, external
  side-effect boundaries, checkpoints, and explicit termination in every example.
- **[Shared sections drift]** → centralize stable principles and validate each harness
  page against a small, harness-specific requirement map.

## Migration Plan

1. Author the shared harness/loop start pages and metadata contract examples.
2. Add each harness playbook with official evidence and installed-version notes.
3. Add loop pages from the actual skill contracts and one connected transcript.
4. Replace summary claims only after all routes validate.
5. Roll back by removing new routes; no runtime or data migration is involved.

## Open Questions

No content decision blocks implementation. The locally installed ACP/CLI harness used
for release evidence will be selected during the publication-gates change based on
authenticated availability.

## Analyze reuse evidence

- **cand-007 — Agent Skills specification (adopt):** the specification defines the
  portable `SKILL.md` frontmatter/folder contract, and its best-practices guidance
  recommends compact skills with progressively disclosed resources. It does not
  normalize harness commands, permissions, plugins, or session semantics, which is why
  the six playbooks remain separate. Sources: <https://agentskills.io/specification>,
  <https://agentskills.io/skill-creation/best-practices>.
