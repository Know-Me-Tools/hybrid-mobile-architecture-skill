# KBD Constraints
> Hybrid Mobile Architecture — TJ-ARCH-MOB-001

## BLOCKING (stop and refuse)

- **NEVER re-implement networking, LLM interaction, inference, MCP, or agent logic in Dart or TypeScript.** These live exclusively in `gen_ui_core` (Rust). Any generated code that duplicates this in the UI layer violates the architecture invariant.
- **NEVER create a second Tokio runtime.** One global runtime per process, initialized in `gen_ui_core/src/runtime.rs`.
- **NEVER call `invoke()` from a React component or hook.** `invoke()` / `listen()` are allowed only inside Zustand stores.
- **NEVER call APIs or services from a Flutter Widget directly.** All external calls go through Riverpod providers → repositories → FFI.
- **NEVER use manual `Provider(...)` declarations in Flutter.** All providers must use `@riverpod` codegen annotations.
- **NEVER expose the Supabase service role key to clients.** Key exchange (Kratos session → Supabase JWT) must happen inside the Rust layer.
- **NEVER skip a step in the 7-step ContentBlock guide** (`references/rust/new-block-type.md`). Skipping steps causes compile-time errors by design; do not work around them.
- **NEVER create feature-to-feature direct imports.** Cross-feature dependencies go through `app/` or `shared/` only.
- **NEVER use `any` types in TypeScript** unless explicitly justified in a comment.
- **NEVER generate or modify files inside `docs/tj-arch-mob-001.html` or `docs/gen_ui_spec.html`** — these are canonical reference documents, not working files.

## WARNING (flag and confirm before proceeding)

- **Adding a new dependency to scaffold templates** — verify it does not conflict with existing workspace deps and that it is the current stable version.
- **Changing state management patterns** — any deviation from Riverpod (Flutter) or Zustand+TanStack (React) requires explicit justification against TJ-ARCH-MOB-001.
- **Modifying `scripts/`** — scaffolding scripts are consumed by downstream projects; changes must be backward-compatible or versioned.
- **Touching `plugin.json` or `marketplace.json`** — these are published marketplace artifacts; changes require a version bump.
- **Placing business logic in a UI component** — flag as an architectural violation even if the change appears to "work."
- **Changing the ContentBlock discriminated union** — requires all 7 steps across Rust + Dart/TypeScript; partial changes leave the codebase in a broken state.

## STYLE / CONVENTION

- All generated files must begin with `// TJ-ARCH-MOB-001 compliant`.
- Feature directories follow `data/ → domain/ → presentation/` layering; no deviation.
- Rust: run `cargo fmt` and `cargo clippy -- -D warnings` mentally before outputting generated code.
- Flutter: follow `flutter_lints` rules; no wildcard imports.
- React: follow ESLint config from `references/tauri/eslint-config.md`; strict TypeScript.
- Commit messages follow conventional commits format (`feat:`, `fix:`, `docs:`, `chore:`, etc.).
