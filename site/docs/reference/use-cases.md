---
sidebar_position: 4
title: Common use cases
description: Practical recipes that map product work to KnowMe Builder profiles, utilities, services, and skills.
---

# Common use cases

These recipes show how the parts fit together. They are starting sequences, not
permission to skip a project’s own policy and acceptance gates.

## Build a private cross-platform assistant

Use `sovereign-hybrid` in runnable mode.

1. Generate or adopt with the CLI.
2. Use `local-inference-lanes` to bind LiteRT-LM, MLX, llama.cpp, and WebLLM
   through `InferenceProvider`.
3. Use `pem-local-first` for durable conversations and `client-rag` for local
   retrieval.
4. Put sensitive learned facts behind `peer-profile-sync`.
5. Render typed output with `content-block-ui` and
   `a2ui-surface-contract`.
6. Apply `agent-runtime-security` to every governed tool.
7. Finish with platform UI gates and physical-device
   `hybrid-runtime-verification`.

## Add a governed agent to a business web application

Use `governed-web-shell` or `axum-web`.

1. Adopt the existing application rather than regenerating it.
2. Normalize durable state through `entity-graph-web-shell` and PEM.
3. Establish verified identity and project-local policy.
4. Submit agent work through `axum-agent-gateway`.
5. Stream `agui-event-contract` events and render A2UI as projections.
6. Apply `persona-scoped-agent` for bounded assistant modes.
7. Require named-human release in the policy overlay for consequential
   outputs.

## Embed a frozen legacy product

1. Add a bridge proposal with
   `knowme-builder add legacy-embed <name> --path .`.
2. Invoke `legacy-app-embed`.
3. Pin exact allowed origins and bridge versions.
4. Validate source window, origin, message schema, capability, correlation, and
   idempotency.
5. Translate allowed intent in the host BFF.
6. Test hostile origins, replay, navigation, reload, and timeouts.

The embedded product never receives tenant authority, credentials, database
handles, or direct UAR access.

## Add an independently testable mini-app

1. Run `knowme-builder add module <name> --path .`.
2. Invoke `mini-app-module`.
3. Declare routes, entities, capabilities, policy actions, events, and
   migrations in its versioned manifest.
4. Register normalized entities with the shell.
5. Route agent triggers through the governed gateway.
6. Prove the module can be disabled without breaking the host.

## Add local semantic search

1. Classify every source field and privacy class with `sync-doctrine`.
2. Invoke `client-rag`.
3. Use the shared 384-dimensional representation.
4. Implement embed-on-write after the durable entity commit.
5. Store vault vectors in a separate local-only index.
6. Test real ingest-to-retrieve behavior and ordering against the selected
   tier store.

## Add a model or change a platform inference lane

1. Invoke `dependency-pin-discipline` before changing versions.
2. Invoke `local-inference-lanes`.
3. Keep engine types behind `InferenceProvider`.
4. Add revision-pinned, resumable, SHA-256-verified acquisition.
5. Implement memory preflight before native load.
6. Test host feature compilation.
7. Invoke `hybrid-runtime-verification` and record physical-device load and
   generation evidence.

## Implement a supplied design

1. Invoke `reference-ui-fidelity` and inventory every route, state, theme, and
   form factor.
2. Define one source with `hybrid-design-tokens`.
3. Apply `mobile-navigation`, `tauri-custom-titlebar`, and
   `content-block-ui` where relevant.
4. Run `a11y-gate`.
5. Use `tauri-ui-review` or `flutter-golden-ui`.
6. Finish with a real runtime workflow rather than screenshot evidence alone.

## Publish product documentation

1. Invoke `build-branded-docusaurus`.
2. Classify source content as public, public-normalize,
   private-synthesis-only, or excluded.
3. Edit Docusaurus source, never `site/build`.
4. Generate public skill references and model routing.
5. Run sanitization, frozen build, route/search checks, link checks, and
   browser accessibility.
6. Publish the immutable static artifact through the Pages workflow.

## Continue work in another harness

1. Use `karpathy-progress-memory` to retain evidence and the exact next step.
2. Pause and audit through `prometheus kbd`.
3. Revise the plan if the architecture changed.
4. Release or revise the CRDT work claim and resolve any conflicts.
5. Start the next harness from the same project UUID and committed revision.

Builder skills provide the same instructions in every harness; Prometheus
provides the durable causal position and convergent claim/conflict authority.
