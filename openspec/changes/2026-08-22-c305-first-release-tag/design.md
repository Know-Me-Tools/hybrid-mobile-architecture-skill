# Design decisions — c305

## D-1 · The tag goes on `main`, not on a branch (tasks 1.4/1.5)

**Decided by:** user, 2026-08-23

All five changes sat on a linear chain of feature branches, 10 commits ahead of
`main`. `main` was still at `e76c29b` — the tree the phase started from, with
two red gates. Tagging the branch tip would have produced a tag that resolves
while the default branch anyone clones stays broken.

`main` was fast-forwarded to the chain tip, all 16 gates re-run **on `main`**
with a clean working tree, and the tag cut there. Order matters: the clone-at-tag
proof ran **before** `git push`, so nothing outward-facing happened against an
unverified tag.

## D-2 · A sixteenth gate, red on `main` before the phase began

Building the roster for task 1.1 surfaced one more:

```
$ jq -e '.version == "2.0.0-alpha.2" ...' "$receipt"     # test-harness-installer.sh:32
$ jq -r '.package.version' builder.manifest.json
2.0.0-alpha.3
```

`scripts/test-harness-installer.sh` asserted a hardcoded version the package had
already outgrown. The install itself succeeded; the assertion failed, and `set -e`
aborted with no diagnostic — the script printed "Installed … 2.0.0-alpha.3" and
exited 1. Nothing ran it, so nobody saw.

This is the same class as B-2 (`check-git-url-discovery.sh`'s hardcoded `30`) and
the third instance this phase. The version is now derived from
`builder.manifest.json`, and the assertion prints the mismatch rather than
failing silently.

The roster's real value was finding it. A gate absent from the list is a gate
nobody runs, and the phase's assessment had already miscounted once.

## D-3 · `--fast` refuses to claim a pass

`run-all-gates.sh --fast` skips the four slow gates and exits **2 PARTIAL**,
mirroring the contract `verify-tray-templates.sh` adopted in c303 after review
found its `--fast` printing "PASS — every rendered template builds" over a
broken template. A prose warning is not a machine-readable signal; the exit code
is.

## D-4 · The phase name overstates what shipped — recommend renaming at reflect

The phase is `hma-companion-consumer-integration`. Nothing consumer-side shipped,
and nothing could have: `prometheus-companion` is a two-commit scaffold with no
install surface (assessment §2, G1).

What actually shipped is producer stabilisation — two red gates closed (three
counting D-2), a consumer-install proof run against a *simulated* consumer, an
honest refiner Verify, compiled tray templates, a reconciled W6.x index, and the
first published tag.

**Recommendation for `/kbd-reflect`: rename to `hma-producer-stabilisation`.**
G1″ — the genuine cross-repo proof against the Companion — stays on the
Companion's roadmap and is the natural next phase, once that repo has an install
surface to prove against.

## D-5 · The tag was published with a red gate, then moved

**This is the phase's most serious process failure and is recorded plainly.**

`v2.0.0-alpha.3` was first cut at `23abd02` and pushed, on the strength of
"16/16 gates green". Adversarial review then found the roster **itself
incomplete** — and one of the four gates it omitted, `scripts/verify-scaffold.sh`
(which CI runs), was **red at that commit**:

```
Error: crate version 2.0.0-alpha.2 differs from manifest version 2.0.0-alpha.3
```

`BUILDER_VERSION` is `CARGO_PKG_VERSION`, so `tools/knowme-builder/Cargo.toml`
drifts from `builder.manifest.json` structurally whenever one is bumped without
the other. Fixing it exposed two more stale literals behind it: `ci/expected-tree.txt`
predated the six v0.2.0 skills (additions only, zero removals — a stale snapshot,
regenerated), and the companion-projection assertion hardcoded "29" against 35
actual (now derived from `templates/project-skills`).

That is the **fourth** hardcoded-literal rot this phase, after B-2's `30` and
D-2's `2.0.0-alpha.2`. The pattern is now unmistakable: this repository's gates
were written with counts and versions baked in, and they rot silently because
nothing re-derives them.

**The irony is the point.** c305's thesis is that an unlisted gate is an unrun
gate. The roster shipped incomplete, declared a commit green that was not, and
a tag was published on that claim. The roster was right about the failure mode
and was itself an instance of it.

Resolution (user, 2026-08-23): the tag was **force-moved** to `b1934d7`. Moving
a published tag is normally wrong; it was chosen because the tag was hours old,
is the repository's first, and the guidance pointing consumers at it is what
this very phase shipped. The tag message records the move so anyone who pinned
`23abd02` learns to re-pin. Roster completed 16 → 20 gates, now cross-checked
against `.github/workflows/`, and `run-all-gates.sh` carries a note requiring
that cross-check when a gate is added.
