# Karpathy progress: prompting guide foundation

**Timestamp:** 2026-07-18T09:34:20Z
**Phase:** `build-detailed-prompting-guide`
**OpenSpec change:** `prompting-guide-foundation`

## Intent

Establish the canonical, machine-checkable foundation for the detailed
Prometheus application prompting guide before writing the full harness and
scenario content.

## Observations

- `docs/prompting/` now owns the public prompting source.
- Docusaurus 3.10.1 can consume `../docs/prompting` directly.
- The previous site-local prompting summaries were editable duplicates and were
  removed after direct-source build proof.
- The clean-clone reproduction caught that `yaml` had been used implicitly from
  an existing `node_modules` tree; it is now pinned directly.
- The KBD apply helper repeatedly emitted a non-fatal shell warning:
  `local: can only be used in a function`. It exited successfully and updated
  the OpenSpec task ledger.

## Evidence

- `npm --prefix site run validate:prompting` passed.
- `npm --prefix site run test:prompting-fixtures` passed.
- `npm --prefix site run sanitize` passed.
- `npm --prefix site run check:model-routing` passed.
- `npm --prefix site run build` passed after switching the prompting plugin to
  `../docs/prompting`.
- A temporary clean local clone at
  `/var/folders/ln/0wnpd96j26z2qhvx9m6hwt2r0000gn/T/tmp.Hpdr7jhWNz/repo` passed
  `npm --prefix site ci`, `npm --prefix site run test:prompting-fixtures`, and
  `npm --prefix site run build` without reusing ignored site artifacts.

## Decisions

- Keep `docs/prompting/` as the canonical human-edited source.
- Generate `docs/prompting/model-routing.generated.md` from
  `docs/prompting/model-registry.yaml`; edits belong in the registry.
- Treat Kimi K2.6 as a supported Kimi Code route/family behavior, not as a
  proven standalone exact model ID.
- Keep Qwen 3.7 Max low-confidence until a stronger official primary model
  page is captured.
- Do not publish raw search output, conversation logs, private wiki material, or
  machine-local paths into the Docusaurus site.

## Reusable Lesson

Clean-clone documentation builds need direct dependencies for validation scripts.
If a validator imports a package, pin it in the site package even when it happens
to resolve from an existing local `node_modules` tree.
