# Tasks — 2026-07-17-c116-scaffold-theme-wiring

- [ ] T1 — `scaffold-hybrid.sh`: copy `templates/theme-pipeline/`, add root
      `tokens:build` script, invoke the compiler once after both surfaces exist.
- [ ] T2 — `scaffold-flutter.sh`: delete the placeholder `tokens.dart` heredoc
      (line ~164); emit generated `tokens.g.dart` + `theme_provider.dart`; fix the two
      `ThemeData.dark(useMaterial3: true)` sites (~1279, ~1290) to use the provider.
      Update the three `core/theme/tokens.dart` import sites the scaffold also emits.
- [ ] T3 — `scaffold-tauri.sh`: source `index.css` token block from compiler output.
- [ ] T4 — VERIFY: scaffold a scratch hybrid project end-to-end; `flutter analyze` and
      `pnpm --filter <web> build` pass; CSS values == Dart constants (c114's parity
      check reused); no `ThemeData.dark(` and no placeholder palette in the output.
