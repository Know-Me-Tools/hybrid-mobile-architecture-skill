# C-010 flutter-surface — completion summary

**Status:** complete. Delivers the `scaffold-flutter.sh` v2 rewrite, a new
`prometheus_entity_management` pub.dev package (PEM Flutter port, analysis §1.5),
and a working example mobile vertical slice — all on Riverpod 3.3.2 / frb 2.12,
wired to the three flutter packages. Verified end-to-end: every emitted Dart file
parses (`dart format` exit 0 across 22 files), `audit.sh flutter` reports
**PASS 24 / WARN 2 / FAIL 0** (the two warnings are the expected pre-codegen
`.g.dart`/`.freezed.dart` absence), and both scripts pass `bash -n`.

## Files created / modified

- **`scripts/scaffold-flutter.sh`** (rewritten, v1→v2): pubspec upgraded to
  `flutter_riverpod ^3.3.2`, `riverpod_annotation ^4.0.3`, `flutter_rust_bridge ^2.12.0`,
  `riverpod_sqflite`, `alchemist` (goldens); path-deps the three flutter packages.
  Emits a working example app: `bridge/` FFI seam (facade + `A2uiEvent` sealed mirror +
  `A2uiContentDriver`), `features/chat` (`ChatNotifier` folds A2uiEvent→ContentBlock,
  Mutations-API send, `ref.mounted` guards), `features/notes` (entity-CRUD demo over PEM,
  families-as-normalization + change-bridge), `shared/` (`FrbEntityTransport` adapter +
  `SyncChip` driven by the Rust `SyncStatus` stream), GoRouter shell, design tokens,
  Android `.so` + iOS XCFramework build scripts (now using `--config-file`), and 3
  boundary/golden tests. Deferred `flutter pub get` behind a package-presence guard so
  standalone and hybrid flows both work.
- **`scripts/scaffold-packages.sh`** (extended): new
  `flutter_packages/prometheus_entity_management/` package — freezed mirrors of
  `gen_ui_types` view/entity/change wire types (snake_case, 1:1 with Rust serde),
  a plain-sealed `SyncStatus` mirror, the `EntityTransport` seam (host-implemented, never
  UI), and `providers.dart`: `entityListProvider`/`entityProvider` families as the
  normalization map, `entityChangeBridgeProvider` (Rust ChangeEvent → targeted
  `ref.invalidate`), an immutable dirty-path `EditBuffer`, and an `EntityCrud` controller
  with optimistic snapshot/rollback. Every FFI-backed provider opts out of Riverpod 3
  auto-retry via `_noRetry` (a Rust domain error is terminal).
- **`scripts/audit.sh`** (surgical fix): anchored the `provider:`/`bloc:` pubspec greps to
  the dependency-key column so `path_provider` no longer trips a false `FAIL` (pre-existing
  bug — v1's pubspec also shipped `path_provider`; the check has always misfired).

## Tests (features-first, per references/flutter/testing.md)

3 boundary/golden tests, no internal mocks — fakes only at the FFI/transport boundary:
`chat_flow_test` (ChatNotifier folds a canned Rust-shaped A2uiEvent stream into
ContentBlocks through the real driver/fold path), `content_block_golden_test` (alchemist
golden over ContentBlockView variants), `entity_crud_test` (EntityCrud optimistic save
rolls back the edit buffer when the transport throws).

## Deviations / notes

- **`SyncStatus` and `A2uiEvent` Dart mirrors** were added (SyncStatus in PEM, A2uiEvent in
  the app bridge) rather than sourced from `gen_ui_widgets`, which only exports
  `ContentBlock`. frb generates its own unions across the FFI at codegen time; these sealed
  mirrors let the app + tests compile/run standalone pre-codegen and give the sync chip /
  chat fold compile-time-exhaustive switches. Consistent with how `gen_ui_widgets` already
  mirrors `ContentBlock`.
- **`ChatNotifier` uses `@riverpod` (retry not set):** its `build()` is synchronous and
  never throws, so provider-level retry doesn't apply; terminality is enforced on the async
  FFI-backed providers and by the Mutation's own error handling. The load-bearing
  retry opt-outs (`@Riverpod(retry: _noRetry)`) are on `entityList`/`entity`/`syncStatus`
  and PEM's providers, exactly per references/flutter/patterns.md.
- **Formatter style:** heredocs are authored readable, not pinned to the host's Dart 3.7+
  "tall" formatter output (cosmetic only; matches v1's approach — users run `dart format`).
- **No blockers.** Scope held to C-010; `gen_ui_types` seams and other lanes untouched.
