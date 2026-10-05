---
type: SessionRecord
id: karpathy-session-30e7dca136744bc7
title: Karpathy session 30e7dca13674
tags:
- karpathy
- session-learning
sources:
- resource: session:54c1998e-0691-4568-b2ef-0572fcf2a584
generated:
  by: pk/1.11.0
  at: 2026-10-05T18:59:33.274465+00:00
created_at: 2026-10-05T18:59:33.274465+00:00
updated_at: 2026-10-05T18:59:33.274465+00:00
revision: 0
---

## Delta

I found why the skills disappeared: the active generation is a downgrade. I haven't rolled anything back, and Prometheus has no rollback command that I could see.

**What happened today, from the manifests and receipts**

| | `previous` (26bdb347…) | `current` (f58037cc…) |
|---|---|---|
| Built | 12:03 | 12:16 |
| Source version | 1.11.2 (matches the installed CLI) | 1.7.0 |
| Source provenance | commit `ba5c451`, tree modified, 9 external sources | none: no commit, no external sources |
| Skills recorded | 217 | 145 |
| `executionComponent` | present | missing |
| Layout | flat | categorized (`learn/`, `rust/` …) |

- **Timeline:** the skill links in the harness directories were created at 12:23–12:24 for the flat layout, so `previous` was still active then. `current` was switched to the 1.7.0 generation at 12:27. That is why those links now dangle.
- **Not a deliberate removal:** an older 1.7.0 package with no provenance replaced a newer 1.11.2 one. It has fewer skills, and the 1.11.2 CLI still expects the newer features. This also explains `execution.runtime` failing and "active generation selected hooks differ" in the doctor output.
- **Not caused by this work:** the installers I ran only touched this repo's skills and the Claude and Codex plugin registrations. I never invoked `prometheus install`, so I don't know what triggered the 12:27 activation. It happened around the time this session began.
- **Both generations are signed and "verified".** So the signature check doesn't catch a downgrade.

**Rolling back**
- **Mechanism:** the `previous` pointer exists as a rollback target. The only mechanism I can see is manually re-pointing `~/.prometheus/plugins/prometheus-skill-pack/current` to `generations/26bdb347…`. The `pointers/` directory probably records it too.
- **Why I stopped:** that edits Prometheus's signed state by hand, and I don't know whether it re-checks the pointers. It's also not clear what else switched at 12:27, such as hooks, services and the `prometheus-exec` binary.
- **What it would fix:** the 443 dangling links would resolve again, and `execution.runtime` and the hook defects should clear.

**Decision for you:** how should I proceed?
1. **Roll back by hand:** I'd flip the `current` pointer to `26bdb347…`, keep a copy of the old pointer, and re-run `prometheus doctor --json` from the Prometheus source checkout. Tell me where that is.
2. **Find the trigger first:** look for what built or activated the 1.7.0 generation, since rolling back without that may just repeat it. I'd check the launch agents, hooks log and `~/.prometheus/hooks.log`.
3. **Report it upstream:** none of this has gone to the Prometheus maintainers yet.

I recommend 2 and then 1. A manual rollback is quick, but if the 1.7.0 generation gets rebuilt at the next session start, it will be undone.

## Root Cause

No explicit root-cause section was captured; preserve this as a session record, not an inferred diagnosis.

## Corrective Actions

Review and promote only reusable findings.

## Session Metadata

- Harness: claude-code
- Session: 54c1998e-0691-4568-b2ef-0572fcf2a584
- Captured: 2026-10-05T18:59:32.532894Z
- Project: /Users/gqadonis/Projects/references/hybrid-mobile-architecture-skill

## Changed Paths

- .claude/settings.local.json
