### 2026-07-15 — kbd-analyze (bootstrap pillars) verdicts
- ADOPT: prometheus-skill-system (public; full install flow documented; verify via pk doctor
  + mcp-health + required binaries), @fission-ai/openspec 1.6.0 (bare 'openspec' npm is
  squatted — scoped name mandatory; channel-aware upgrade), Flutter beta 3.47.0 (releases-JSON
  currency check; dart mcp-server gate; our install-flutter.sh must be fixed — shallow stable
  clone), node@24 pinned (NOT --lts) + bun + pnpm + typescript@latest.
- USER REVISION: TypeScript pillar 6.0+ → 7.0.2 (latest). Scaffold pins updated ^5.x→^7.0.0
  (stale pins = live Rule-22 violation in our own generators, fixed).
- USER DIRECTIVE: 40 Prometheus Base Rules → canonical AGENT_BASE_RULES.md, wired into
  CLAUDE/AGENTS/dispatch-preamble/scaffold-emission/skill-templates. Provenance: user.
- BUILD (extend own): check-env.sh → 4-pillar bootstrap with operational gates; 7-item delta.
- Open: remediation aggressiveness default (recommend check-only default, --install, --full
  for long ops); skill-system clone location; staleness warn-vs-fail (recommend warn).
