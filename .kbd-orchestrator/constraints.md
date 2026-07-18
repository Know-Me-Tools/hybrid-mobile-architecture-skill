# KBD Constraints

> Hybrid Mobile Architecture Skill — TJ-ARCH-MOB-001

## BLOCKING (stop and refuse)

- **NEVER re-implement networking, LLM interaction, inference, MCP, agent logic, or persistence in Dart or TypeScript.** These capabilities live in the shared Rust application layer. UI surfaces use typed FFI, Tauri, or WASM adapters.
- **NEVER create a second Tokio runtime.** Use one global runtime per process. Run CPU-heavy GGUF loading, inference, and similar work through `spawn_blocking`.
- **NEVER import a Zustand store or call `invoke()` directly from a React visual component.** React follows Component → Hook → Store → Rust/external API.
- **NEVER call APIs, services, or FFI directly from a Flutter widget.** Flutter follows Widget → generated Riverpod provider → Repository/Service → Rust FFI.
- **NEVER use manual `Provider(...)` declarations in Flutter.** Use `@riverpod` code generation exclusively.
- **NEVER introduce TanStack Query.** Use `@prometheus-ags/prometheus-entity-management` 3.x for React server, async, and normalized entity state; Zustand owns transient client UI state.
- **NEVER expose service credentials, BYOK values, private keys, tokens, or passwords to client bundles or committed configuration.** Use environment references, platform keychains, vaults, or cloud secret managers.
- **NEVER skip a step in the seven-step ContentBlock guide** at `references/rust/new-block-type.md`. Do not add a fallback that hides a missing variant.
- **NEVER create direct feature-to-feature dependencies.** Cross-feature behavior goes through `app/`, `shared/`, or explicit domain interfaces.
- **NEVER use implicit or unjustified `any` in TypeScript.** Prefer generated types, discriminated unions, and exhaustive checks.
- **NEVER set `panic = "abort"` on Flutter FFI release profiles.** It prevents flutter_rust_bridge from converting Rust panics and terminates the process.
- **NEVER edit generated reference HTML directly**, including `docs/tj-arch-mob-001.html` and `docs/gen_ui_spec.html`. Update the source or generation pipeline.
- **NEVER delete, reset, overwrite, or revert unrelated dirty work.** Preserve user changes and use recoverable operations for material cleanup.
- **NEVER weaken, delete, or ignore a failing acceptance test to claim success.** After two repetitions of the same failed approach, stop and reassess.

## WARNING (flag and verify)

- **Adding or updating dependencies** — verify the current supported version, platform compatibility, license, and responsible scaffold/template.
- **Changing state management** — Flutter uses Riverpod codegen; React uses Prometheus Entity Management 3.x plus Zustand. Any deviation requires an explicit architectural decision.
- **Modifying `scripts/`, `assets/templates/`, or `templates/project-skills/`** — downstream projects consume these outputs; propagate fixes to the responsible generator and exercise a scratch scaffold.
- **Placing business logic in UI code** — treat this as an architectural violation even if the feature appears to work.
- **Changing ContentBlock or protocol contracts** — update Rust, Dart/FRB, TypeScript, Flutter, React, persistence, and public-boundary verification together.
- **Changing published plugin or marketplace metadata** — bump the package version, validate both Claude and Codex manifests, and test clean marketplace installation.
- **Calling an application “working”** — require a clean-checkout install/build, a real launch, persistence proof, and one public-boundary workflow via `hybrid-runtime-verification`.
- **React UI construction** — prefer Shadcn UI components and Assistant UI for chat behavior; preserve the borderless Flat 2.0 light/dark design contract.
- **Flutter UI construction** — preserve matching KnowMe tokens, chat bubbles, semantic behavior, and light/dark parity using the Flutter UI skills.

## STYLE / CONVENTION

- Generated source files include the `TJ-ARCH-MOB-001 compliant` marker in the target language's comment syntax.
- Flutter features use `data/domain/presentation`; React features use `api/stores/queries/hooks/components` with visual components importing hooks only.
- Rust inner-loop verification uses one clippy pass rather than alternating `cargo check` and clippy caches.
- Features are completed and exercised once before adding 3–5 public-boundary behavior tests; do not mock internal implementation.
- Commit messages follow conventional commit prefixes such as `feat:`, `fix:`, `docs:`, and `chore:`.
- Project and private Karpathy records capture verified decisions and failures without credentials or raw private conversation content.

## WORKFLOW TRIGGERS

- On iteration completion, run the configured build-health command when the changed scope affects the documentation site.
- On deployment-catalog changes, run the configured lint command.
- Before archiving an application change, run the relevant architecture audit and `hybrid-runtime-verification` public boundary.
