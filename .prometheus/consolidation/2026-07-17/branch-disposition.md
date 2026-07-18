---
title: Branch and worktree consolidation disposition
date: 2026-07-17
status: verified-integration
---

# Branch and worktree consolidation disposition

The pre-consolidation inventory is recorded in
`pre-consolidation-manifest.json`. Every dirty worktree was committed before
selective integration, and every Prometheus artifact is mapped by
`wiki-consolidation-manifest.json` to either a canonical page or a
provenance-preserved source variant.

## Disposition

| Source | Decision |
|---|---|
| `claude/c106-sync-infra` | Tip already contained in `main`; retained only dirty Prometheus history. |
| `claude/compassionate-babbage-7cd4bc` | Rejected wholesale because it was stale and regressed the current tree. Ported its blocking Mistral load, iOS archive/link repairs, Rust/toolchain alignment, and applicable diagnostics while retaining current navigation. |
| `claude/cross-platform-app-theming-4a272e` | Preserved the phase plans and OpenSpec proposals as deferred backlog. Rejected transient harness rewrites and waypoint activation. |
| `claude/funny-wozniak-06a4cc` | Ported the additive SurrealDB statement-error guard and current-compatible graph behavior tests. Rejected the older store/search implementation. |
| `claude/goofy-gould-d872b8` | Integrated committed and dirty Prometheus history only. |
| `claude/optimistic-volhard-233482` | Tip already contained in `main`; retained unique Prometheus history only. |
| `claude/pensive-greider-2e206c` | Tip already contained in `main`; retained unique Prometheus history only. |
| `claude/practical-bose-6b609c` | Identical to the original `main` tip; no code port required. |
| `claude/sweet-mendeleev-401c40` | Ported source-based local package exports, publish-time `dist` overrides, current-compatible tests, and the startup promise `finally` reset. |
| `claude/xenodochial-sammet-a67a35` | Identical to the original `main` tip; no code port required. |
| `worktree-agent-a6bf13877ab890979` | Tip already contained in `main`; no unique code required. |
| `worktree-agent-ad0c09b67356676bb` | Audio crate files were byte-equivalent to `main`; rejected its stale workspace manifest and retained the audit evidence. |
| dirty primary worktree | Preserved at `4f38c17`; retained/refined boot logging and regenerated locks/schemas from final sources. |

## History proof

The lossless merge produced 239 root wiki pages, 20 desktop pages, 3 desktop
Tauri pages, and 34 Rust pages. This exceeds the required 238/20/3/34 union
because the consolidation postmortem is itself a new root page. Same-name or
same-ID divergent pages have provenance copies; event records are a
de-duplicated union that retains conflicting variants; redactions are listed in
the wiki manifest.

## Package ownership decision

All application/scaffold dependency declarations for
`@prometheus-ags/prometheus-entity-management` use the owned 3.x line,
`3.0.0-alpha.0`. That version was verified both in the local owner repository at
`$PROMETHEUS_ENTITY_MANAGEMENT_REPO` and in the npm
registry. Local development resolves tracked TypeScript sources; publish-time
exports resolve built `dist` artifacts.
