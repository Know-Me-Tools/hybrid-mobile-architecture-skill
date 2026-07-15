# Goals

> Revised 2026-07-15 (user-directed at assess time): the phase's end result is a
> working proof-of-concept application, not just pipeline verification. The original
> codegen/CI goals below become supporting objectives that the PoC proves in passing.

## Primary goal

- **Build a proof-of-concept app in `apps/<name>/`** using the scaffolds and skills in
  this repository, based on the KnowMe reference documentation in `docs/reference-app/`
  (functional spec + moodboard/user journeys). The PoC must prove the skill package
  works end-to-end and showcase the broadest practical range of supported capabilities
  (streaming ContentBlock chat, PEM entity management, SurrealDB graph-RAG memory,
  local-first sync, cross-platform Flutter/Tauri/web from one Rust core). Feature
  subset selected via web research (showcase-app best practices + 2026 on-device AI
  feasibility).

## Supporting goals (from the original phase scope — proven via the PoC)

- Run the real codegen pipeline on the PoC: `flutter_rust_bridge_codegen generate`,
  `dart run build_runner build`, full `flutter pub get` / `pnpm install`; confirm the
  pre-codegen warnings clear once generated code and sibling packages exist.
- Resolve or work around the PEM install blocker
  (`@prometheus-ags/entity-graph-core@workspace:*` unresolvable outside the PEM monorepo).
- Verify the PoC builds and runs on at least one real target per surface
  (macOS Tauri desktop; iOS simulator or Android emulator for Flutter).
- Wire CI to run `cargo clippy --workspace`, `audit.sh all`, and the boundary test
  suites against the PoC on every push.
