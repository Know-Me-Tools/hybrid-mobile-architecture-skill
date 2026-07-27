---
sidebar_position: 1
title: KnowMe reference application
---

# The reference product

The KnowMe example proves the architecture across Flutter mobile, Tauri desktop,
and React/Axum web. It demonstrates multiple durable conversations, local model
selection, optional BYOK cloud providers, memory retrieval with visible citations,
thinking and tool events, and rich ContentBlock output.

The chat experience uses Shadcn UI and Assistant UI on React, actual chat bubbles
on React and Flutter, Prometheus Entity Management 3.x plus Zustand for client
entity state, PGlite for browser conversation storage, and the Rust persistence
boundary for desktop/mobile. The application must start with an available local
model path without requiring a cloud key.

Configuration may add Flint Forge, Flint Realtime Fabric, Flint Gate, Ory Kratos,
Ory Keto, and Liter-LLM. Authentication and BYOK are optional capabilities—not
fake dependencies of the anonymous demonstration.

## Where the reference lives

KnowMe is the **design target**, described by the artifacts in
`docs/reference-app/` — the standalone HTML app, the mood board, and the
functional specification. Those are what the `reference-ui-fidelity` gate treats
as the visual acceptance oracle.

The repository does **not** carry a built copy of the application. It used to:
a 40k-LOC snapshot lived under `apps/`, committed as "the example." It read like
generator output but was a snapshot of a real product, so when the generator fell
behind, every check still passed — which is exactly how that drift went unnoticed.

It is now replaced by a fixture that regenerates on every push:

```bash
bash scripts/verify-scaffold.sh            # scaffold, diff against ci/expected-tree.txt
bash scripts/verify-scaffold.sh --update   # after an INTENTIONAL scaffold change
```

The check compares structure — paths, workspace members, inference features, lane
constants — not file contents, then proves placeholders substituted, that the JNI
class path matches its Kotlin bridge, and that every emitted manifest parses. A
generated fixture cannot go stale without CI saying so.
