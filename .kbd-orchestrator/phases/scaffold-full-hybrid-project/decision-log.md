### 2026-07-15 — kbd-analyze verdicts
- ADOPT: PGlite 0.5.4 (web), pglite-oxide 0.5.1 (desktop ONLY — doc correction filed as C-9),
  SQLite+sqlite-vec (mobile), SurrealDB 3.2 embedded (graph RAG, all platforms),
  Electric shapes (read path), PEM 3.0.0-alpha.0 (React), Riverpod 3.3.2, fastembed-rs,
  flint-gate/forge/FRF via git deps consumed inside gen_ui_core.
- BUILD: prometheus_entity_management (Dart/Riverpod port, Rust-backed).
- CONTESTED (flagged, not silently picked): write-path sync — DIY-via-forge (80, recommended)
  vs PowerSync (72) vs PES-wave-1-now (55). Score gap < 15% between top two → user decision
  requested in analysis.md Open Questions #1. Provenance: research (4 parallel agents).
- CORRECTION: docs/pglite-oxide-tauri-hybrid.md claims (native binary; iOS/Android support)
  verified FALSE against crates.io/docs.rs → new change C-9.

### 2026-07-15 — Repo pulls (user-directed)
- flint-gate, flint-forge, prometheus-entity-management: pulled on main (all already current;
  flint-forge is 14 commits ahead of origin — local work, nothing to pull).
- flint-realtime-fabric: on feature branch sovereign-sfu-decode-proof with uncommitted work;
  local main fast-forwarded via fetch origin main:main WITHOUT merging the feature branch
  (mid-flight work — merge deferred to repo owner).

### 2026-07-15 — Contested stack choice RESOLVED
Options: DIY-write-queue-via-forge (80) vs PowerSync (72) | Score gap: ~10%
Decision: DIY via forge, with PES-compatible trait seams | Provenance: user (AskUserQuestion)
Also resolved: example scope = vertical slice (Chat + entity CRUD + memory/graph RAG + sync status), per user.

### 2026-07-15 — Dispatch reassignment: C-008
opencode+kimi-k2p6 auto-rejected reads: kimi constructed absolute main-repo paths
(/Users/.../CLAUDE.md) instead of worktree-relative, and opencode's sandbox blocks
external_directory reads. GLM-5.2 (C-007) read relative paths fine, so this is a kimi
path-following issue, not an opencode-wide block. C-008 (doc-only, needs the C-001 MSRV
1.80->1.93 bump correct) reassigned to claude/sonnet-5. Harness lesson: opencode agents
must be told paths are worktree-relative; kimi-k2p6 unreliable at this.

### 2026-07-15 — Integration-strategy correction (found mid-loop)
FLAW: all 5 code lanes (C-003/004/005/006/007) implement their crates by editing the
SAME file, scripts/scaffold-rust-core.sh (each +800 lines to the same heredocs). Worktree
isolation defers rather than prevents conflict — a 5-way merge of one 800-line script.
FIX: do NOT git-merge the five lanes. Instead HARVEST each lane's crate content and
integrate by hand into the scaffold, ideally refactoring so each crate's source comes from
separate template files under templates/rust-crates/<crate>/ rather than one monolithic
heredoc. The lane CONTENT (verified clippy-clean, wasm-clean, boundary-tested per lane) is
the deliverable; the scaffold file is just the carrier. C-005 verified: Electric consumer +
DIY write-queue + SyncTransport on global runtime, LocalStore/WriteSink seams, clippy/wasm/
3 tests clean, seams untouched.

### 2026-07-15 — Harness finding: opencode unreliable for code lanes
Both opencode lanes failed on sandbox permission blocks:
- C-008 (kimi k2p6): auto-rejected reads of absolute main-repo paths → 0 output (reassigned to claude, succeeded).
- C-007 (GLM-5.2): got partway (workspace deps added), then auto-rejected a /tmp scratch-file
  write it needed for multi-line splicing → harness exited incomplete. Only dep declarations
  landed, not the frb/tauri/wasm leaf bodies.
CONCLUSION: opencode's sandbox blocks the scratch-file + absolute-path workflows these models
use. Claude and codex lanes (native cwd, relative paths) had zero permission issues. Reassign
C-007 to claude/sonnet-5. Harness scorecard this phase: claude 5/5 clean, codex 1/1 clean,
opencode 0/2. For remaining work, prefer claude/codex for code; reserve opencode for nothing
critical until its sandbox is configured to allow worktree + /tmp scratch.

### 2026-07-15 — C-011 finding: PEM publish blocker (external, not a defect)
C-011 (React, codex/gpt-5.6-sol) delivered the full Vite8/React19/shadcn scaffold with PEM
3.0.0-alpha.0 + @flint/react git deps, gen-ui-react ContentBlock rendering, core-fed stores,
PGlite local-first. Correctly REFUSED to vendor/reimplement PEM (Rule 40 + adopt verdict).
BLOCKER (external): clean `pnpm install` fails ERR_PNPM_WORKSPACE_PKG_NOT_FOUND because the
unpublished PEM git subpackage depends on @prometheus-ags/entity-graph-core@workspace:*, which
only resolves inside the PEM monorepo. Resolution is upstream: PEM must publish consumable
packages (or replace workspace: protocols in its packed artifact) before generated apps
typecheck end-to-end. Matches analysis §1.7 (all Flint/PEM deps unpublished). C-011 also fixed
several pre-existing scaffold-tauri.sh bugs (Vite HTML/tsconfig, uuid dep, CommonJS require,
Sandpack pkg name) + added SKIP_INSTALL verification seam.
