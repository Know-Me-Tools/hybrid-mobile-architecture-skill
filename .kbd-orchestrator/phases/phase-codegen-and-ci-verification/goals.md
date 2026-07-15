# Goals

- Wire a CI pipeline that runs `cargo clippy --workspace`, `audit.sh all`, and the
  boundary test suites (Rust + Dart + Vitest) automatically on every push.
- Unblock the PEM (`@prometheus-ags/prometheus-entity-management`) end-to-end install:
  resolve the `@prometheus-ags/entity-graph-core@workspace:*` dependency that currently
  fails outside the PEM monorepo (either upstream publish, or a pre-resolve step in
  scaffold-packages.sh).
- Run a real codegen pass on a fully scaffolded project: `flutter_rust_bridge_codegen
  generate`, `dart run build_runner build`, full `flutter pub get` / `pnpm install`,
  and confirm the pre-codegen warnings (379 dart analyze issues, override_on_non_overriding_member,
  path_does_not_exist) clear as expected once generated code and sibling packages exist.
- Verify the full stack builds and runs end-to-end on at least one real target
  (e.g. macOS Tauri desktop or an iOS/Android simulator) rather than scaffold-only checks.
