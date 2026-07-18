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
