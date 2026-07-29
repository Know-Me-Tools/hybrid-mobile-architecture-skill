# Adding a ContentBlock Type

Use this checklist whenever a new typed agent/UI block crosses the runtime
boundary. A change is incomplete until every layer and its contract test agree.

## 1. Runtime event

- Add the typed streaming event in Rust.
- Preserve stable serialization names and field types.
- Add round-trip serialization tests.

## 2. A2UI ingestion

- Add the corresponding A2UI event.
- Map every runtime field explicitly.
- Preserve unknown events as inspectable artifacts; never drop them silently.

## 3. AG-UI translation

- Add the typed AG-UI/custom event mapping.
- Keep correlation IDs, ordering, cancellation, and error state intact.
- Add a translation fixture.

## 4. Generated bindings

- Update the canonical command/event manifest.
- Regenerate TypeScript and Dart/FRB bindings.
- Regenerate Tauri handler registration and permissions.
- Reject handwritten drift in CI.

## 5. Client types

- Add the Dart sealed-class variant and TypeScript discriminated-union member.
- Parse required fields without lossy coercion.
- Retain forward-compatible unknown fields where the protocol permits them.

## 6. Projection driver

- Add exhaustive driver cases for Flutter and React/Tauri.
- Keep the UI as a projection: it must not own provider routing, tool
  execution, prompts, or agent lifecycle.
- Add state-transition tests for streaming, completion, cancellation, and
  failure.

## 7. Renderer

- Add the Flutter widget and React component.
- Keep loading, approval, cancellation, empty, error, and accessibility states
  explicit.
- Add Flutter golden tests and React component tests.

## Required verification

- Rust serialization and adapter tests pass.
- Generated bindings are byte-stable on a second run.
- Tauri command registration and permission parity pass.
- Flutter analysis/tests and React typecheck/tests pass.
- Unknown-event preservation and restart recovery are covered.
- The public-boundary test is green before the block is described as working,
  complete, or production-grade.
