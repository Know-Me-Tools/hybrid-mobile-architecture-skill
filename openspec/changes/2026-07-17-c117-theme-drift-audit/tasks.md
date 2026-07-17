# Tasks — 2026-07-17-c117-theme-drift-audit

- [ ] T1 — Implement the `theme` audit section in `scripts/audit.sh`: hash check,
      marker check, `fromSeed`/raw-`Color(0xFF…)` Flutter lints, web hex/rgb lint,
      allowlist loading (`design/token-audit-allow.txt`, entries = path-pattern +
      reason, narrow by design).
- [ ] T2 — Wire into existing `flutter` / `tauri` / `all` audit modes; skip-with-notice
      when `design/tokens.json` absent.
- [ ] T3 — VERIFY (negative tests, OpenDesign guard style): (a) edit a generated file →
      audit fails on hash; (b) add `ColorScheme.fromSeed(` to a scratch widget → fails;
      (c) add `Color(0xFFFF0000)` outside `*.g.dart` → fails; (d) add it to the
      allowlist with a reason → passes; (e) clean tree passes.
