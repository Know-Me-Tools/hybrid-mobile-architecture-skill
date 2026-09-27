# Design

The reviewed implementation design is maintained in `docs/assessment/portable-tooling-plan.md`; source audits and structured goal assessment live beside it.

Use one native generator, `knowme-builder`, and one compiled TypeScript tool runtime. Do not create a second generator in JavaScript. Node performs hook protocol and portable orchestration; Rust owns native diagnostics, generation and evolution. Pin the compiler and use emitted modules at invocation time.

Migration order: project tools and evidence, portable runtime/hooks, native and remaining tools, brownfield/upgrade correctness, runnable baselines, distribution verification. Each stage records actual evidence and unresolved host limitations. Local success cannot certify Windows or device execution.

Generated ownership remains explicit. Brownfield adoption initially adds only control metadata; upgrades require a complete inspectable migration plan, preserved original rendering inputs, conflict preflight and recovery. Earlier output fixtures establish supported version ranges. Skeletons are allowed only when explicitly requested and are never certified runnable.

The team ledger coordinates ownership; it does not replace existing Prometheus/KBD lifecycle authority. The two existing active-phase labels are retained pending authoritative reconciliation.
