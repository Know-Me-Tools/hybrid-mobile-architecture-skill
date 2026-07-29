---
sidebar_position: 1
title: KnowMe reference application
---

# The reference consumer

KnowMe is an evolved consumer adopted with the `sovereign-hybrid` profile. It
is not disposable scaffold output. Its application and certification suites
are independent release gates for the Builder.

The intended product contract spans Flutter mobile and Tauri desktop with a
shared Rust application layer, embedded UAR for mobile/local operation, and a
service or in-process UAR facade for desktop/web. It includes durable
conversations, per-device local model selection, optional BYOK providers,
governed tools, local retrieval, typed event projection, and restart recovery.

The chat experience uses Shadcn UI and Assistant UI on React, actual chat bubbles
on React and Flutter, Prometheus Entity Management 3.x plus Zustand for client
entity state, PGlite for browser conversation storage, and the Rust persistence
boundary for desktop/mobile. The application must start with an available local
model path without requiring a cloud key.

Authentication and BYOK are optional capabilities, not fake dependencies of an
anonymous or local baseline. Raw MCP transport, unverified token claims, and
client-side administration are outside the accepted boundary.

## Where the reference lives

KnowMe is the **design target**, described by the artifacts in
`docs/reference-app/` — the standalone HTML app, the mood board, and the
functional specification. Those are what the `reference-ui-fidelity` gate treats
as the visual acceptance oracle.

The Builder repository does **not** carry a built copy of the application. It used to:
a 40k-LOC snapshot lived under `apps/`, committed as "the example." It read like
generator output but was a snapshot of a real product, so when the generator fell
behind, every check still passed — which is exactly how that drift went unnoticed.

Reusable generator behavior is now covered by profile fixtures that regenerate
on every push:

```bash
bash scripts/verify-scaffold.sh            # scaffold, diff against ci/expected-tree.txt
bash scripts/verify-scaffold.sh --update   # after an INTENTIONAL scaffold change
```

The check compares structure — paths, workspace members, inference features, lane
constants — not file contents, then proves placeholders substituted, that the JNI
class path matches its Kotlin bridge, and that every emitted manifest parses. A
generated fixture cannot go stale without CI saying so, but it also cannot
replace consumer acceptance. Stable Builder release still requires the
KnowMe-specific Rust, Tauri/React, Flutter/FRB, deterministic UAR, persistence,
security, platform-build, and current physical-device gates.

See [Generation profiles](../architecture/profiles) for the generic contract
and [Runtime verification](./skills/hybrid-runtime-verification) for the
evidence levels.
