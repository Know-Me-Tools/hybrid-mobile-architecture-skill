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
