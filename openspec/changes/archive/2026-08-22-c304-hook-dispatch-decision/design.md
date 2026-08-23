# Design decisions — c304

## D-1 · `prom-hook-dispatch` leaves this repo's Definition of Done (task 1.1)

> **Numbering note:** this remedy is **W6.9** under the canonical numbering D-2
> establishes. Earlier phases and the pre-c304 tree called it W6.7; that label
> now belongs to the structured-log weakness.

**Decided by:** user, 2026-08-23 · **Option chosen:** drop from this repo's DoD;
owned by `prometheus-skill-system`

The plan framed this as "build it or drop it, after two phases of advisory
text". Checking the premise first narrowed it to a boundary question rather
than a build/no-build one.

### The verifier was never wrong about this

The plan's task 1.4 assumed `verify-hooks-reliability.sh` reports a phantom
pending item that a "drop" decision would need to remove. It does not.
`scripts/verify-hooks-reliability.sh:19-21` already scopes it correctly:

> W6.2, W6.5, W6.7 and W6.9 are properties of a hook *runner* binary. A project
> that ships no runner has nothing to check; when a runner is present its path
> is checked for the cache, process-group kill, and NDJSON log markers.

(Quoted post-renumbering. Before D-2 those labels read W6.2/W6.4/W6.6/W6.7.)

Running it emits no W6.9 line at all. The prior phase's reflection called W6.7
"guidance only", which was accurate; nothing in the tooling needed changing.

### This repo structurally cannot host the crate

Every implementation path `docs/05-hma-pmp-companion-architecture.md:593-597`
names is absent here:

| Path named by the spec | Present in this repo? |
|---|---|
| `crates/prom-hook-dispatch/` | no — this repo has no `crates/` at all |
| `shared/scripts/hook-runtime-v1.sh` | no |
| `hooks/hooks.json` | no |
| `shared/scripts/generated/hook-*.sh` | no |

That table is the `prometheus-skill-system` layout. This repository ships no
Rust binaries; its own hooks live in `.claude/settings.json`. It owns the
**guidance skill** (`claude-hooks-reliability`), not the runtime the guidance
describes.

A Definition of Done cannot require an artifact the repo has no place to put.
Carrying it a third phase would have meant carrying an item that could never be
satisfied here.

### A caveat worth recording rather than burying

The spec's own example implementation still shells out:

```rust
let status = Command::new("bash")
    .arg(&script)
    ...
```

W6.9's stated symptom is "every hook still has a `bash` interpreter in the
loop". A dispatcher that itself invokes `bash` narrows the surface — one
immutable, ABI-versioned, env-cleared entry point instead of inline quoting —
but does not remove the interpreter. That is worth knowing before the owning
repo builds it, so it is recorded here rather than left as an implicit promise.

## D-2 · The real work: the W6.x sequences are offset by one

The numbering problem is not a disagreement over one label. Across W6.6–W6.9
the two documents are **shifted**:

| Label | `docs/03-hooks-reliability.md` | `docs/05-…-architecture.md` |
|---|---|---|
| W6.6 | No structured hook-result log | `exec 2>>"$LOG"` first in every hook script |
| W6.7 | Inline `bash -c` unfixable → **prom-hook-dispatch** | Add structured hook-result log |
| W6.8 | `sessionstart-*` matchers too broad | **prom-hook-dispatch** |
| W6.9 | `UserPromptSubmit` has no `matcher` | Tighten `sessionstart-*` matchers |

Both files legitimately contain W6.7 *and* W6.8 with different meanings, so no
single-label edit reconciles them — a whole sequence must move.

`docs/03` is renumbered to match `docs/05`, not the reverse: `docs/05` is the
joint architecture document shared with the Companion and the skill-system
review it derives from (`2026-08-20-skill-pack-architecture-review.md` §6),
while `docs/03` is this repo's own spec. Changing the local document rather than
the shared one keeps the numbering agreeing with the review that originated it.

## D-3 · The mapping is enforced, not just fixed

Fixing the offset without a check leaves the next editor free to reintroduce it.
`scripts/check-w6-mapping.sh` asserts every W6.x label resolves to the same
remedy in both documents, and ships with a negative fixture proving it fails
when a single label is perturbed — per the phase's standing rule that a checker
which only passes is not a checker.

## D-4 · What the mapping check does *not* prove

`check-w6-mapping.sh` freezes agreement **between this repo's artifacts**:
`docs/03`, the shipped skill, and the `docs/05` remedy table. It asserts each
W6.N denotes the intended weakness and each R6.N the intended remedy, and it
refuses ambiguous keywords so a wrong heading cannot satisfy the wrong slot.

It does **not** read the architecture review that `docs/03:5` names as its
source of truth. That document lives in `prometheus-skill-pack`, outside this
repository, so the check cannot reach it; the keyword tables are a transcription
of the review, not a derivation from it.

The consequence is worth stating plainly: **a remap that all three local
artifacts shared would pass.** The renumbering shipped here was verified against
the review by hand (and independently re-verified during adversarial review),
but that verification is a point-in-time act, not a standing guarantee.

Vendoring a copy of the review was considered and rejected: it would create a
second source of truth in this repo that can itself drift from the original,
trading one unpinned mapping for two. If the review ever moves into a
consumable form — a published table, or the skill-system exposing it — the
keyword tables should be derived from it instead.
