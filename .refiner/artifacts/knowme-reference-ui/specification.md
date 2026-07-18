# Specify — KnowMe Reference UI

## Clarified intent

Refine the generated KnowMe proof application and the architecture skill package together
until any supported harness can reproduce the accepted standalone application's product
quality without sacrificing real local-first runtime behavior.

The artifact is a production React 19/Tauri/web UI with a semantically equivalent Flutter
surface. It is not a static recreation: accepted controls and states must bind to durable
entities, real local/cloud inference, memory/RAG, and Rust-owned platform services.

## Target state

- Six accepted destinations and all meaningful responsive/theme/runtime states exist.
- The live React UI matches the standalone design's hierarchy, density, composition, and
  interaction language while following the newer borderless Flat 2.0 standard.
- Shadcn UI and Assistant UI are mounted at their real product boundaries.
- Conversation entities persist across refresh/relaunch through platform-correct stores.
- Local inference and local memory work without cloud configuration.
- Flutter expresses the same semantic design and public workflows through Rust FFI.
- Every harness and fresh scaffold receives the same fidelity and runtime gates.

## Unknowns to resolve through execution

- Exact per-platform model sizes that satisfy first-run download and performance budgets.
- Assistant UI external-store adapter details needed to project the existing ContentBlock
  stream without weakening the Rust protocol contract.
- Which approved screenshots should be masked for dynamic time/model/runtime metrics during
  automated visual comparison.

## Execution assessment

Code execution, browser rendering, screenshot capture, Rust/TypeScript/Flutter compilation,
simulator launch, database inspection, and real model inference are required. Source review
alone cannot prove the target.
