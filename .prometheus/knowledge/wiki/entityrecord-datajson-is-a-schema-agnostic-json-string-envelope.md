---
type: Reference
id: entityrecord-datajson-is-a-schema-agnostic-json-string-envelope
title: EntityRecord dataJson is a schema-agnostic JSON string envelope
tags:
- hybrid-mobile-architecture
- knowme-poc
- entity-record
- ffi-transport
- tauri
- flutter-rust-bridge
- codegen
- contentblock-streaming
links:
- poc-focused-codegen-and-ci-phase-assessment-update
- c-103-execute-handoff-for-knowme-poc-live-chat-milestone
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T03:57:35.835945+00:00
created_at: 2026-07-16T03:57:35.835945+00:00
updated_at: 2026-07-16T03:57:35.835945+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T03:56:47Z`
- **Phase source:** `manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification`
- **Current milestone:** C-103 Tauri plugin wiring for live chat / `stream_agent_a2ui`

The phase remains under the revised PoC-first scope from [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md), with C-103 continuing from [C-103 execute handoff for KnowMe PoC live chat milestone](/c-103-execute-handoff-for-knowme-poc-live-chat-milestone.md).

## Decision: `EntityRecord.dataJson` remains `String`

`EntityRecord.dataJson` is intentionally a `String`, not a `Map<String, dynamic>`.

Rationale:

- `EntityRecord` is a schema-agnostic transport envelope shared across entity kinds.
- It crosses both FFI/IPC boundaries used by the architecture:
  - `flutter_rust_bridge` / FRB
  - Tauri IPC
- The Rust transport type, `gen_ui_types::transport::EntityRecord`, defines the corresponding field as `data_json: String`.
- Feature code is responsible for decoding its own payload shape at the point of use.

Observed Dart usage in `notes_screen.dart` matches this design:

```dart
final data = jsonDecode(rec.dataJson);
```

Writes also preserve the same contract:

```dart
final record = EntityRecord(
  // ...
  dataJson: jsonEncode({
    // feature-specific entity payload
  }),
);
```

This confirms the current behavior is consistent with the intended “generic envelope, feature decodes its own shape” pattern.

## Not a bug

The `String` type is not a mistake and does not require a bug fix. Changing `dataJson` to a typed map or per-entity payload would be an architecture change, requiring a different bridge model, such as:

- One bridge type per entity kind
- More FRB-generated payload types
- Less generic transport handling across Rust, Flutter, and Tauri

No change should be made unless the project explicitly chooses typed payloads per entity kind as a new architecture direction.

## Phase goals still in effect

The primary phase deliverable is a working proof-of-concept application under `apps/<name>/`, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC should demonstrate the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web from one Rust core

Supporting proof points remain:

- Run real codegen on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - `flutter pub get`
  - `pnpm install`
- Confirm pre-codegen warnings clear once generated code and sibling packages exist.
- Resolve or work around the PEM install blocker:
  - `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds/runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI on every push for:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites

## Next action

Resume verification of `tauri-plugin-gen-ui` build for `stream_agent_a2ui` wiring. The prior work was interrupted during `cargo check`.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification