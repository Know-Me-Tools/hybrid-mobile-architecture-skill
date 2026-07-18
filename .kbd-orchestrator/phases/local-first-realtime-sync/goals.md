# Goals

- Assess docs/knowme-local-first-realtime-master-plan.md plus all notes under docs/research/ to determine how to add skills supporting local-first, realtime, and sync strategies for TJ-ARCH-MOB-001 apps, then add that behavior to the apps
- Partial replication, not full mirroring: a user's local store holds only the data they need, are authorized for, or are interested in, plus application-wide common lookup/metatype data that changes over time and must sync to stay current
- AI chat local-first: store conversation threads client-side AND provide a client-side vector database for vector search and client-side RAG with agents
- Client-side agent data storage and management
- User profile and sensitive personal data stored client-side only, synced device-to-device (all devices and browser instances a user owns) over WebRTC or other peer connections with CRDT convergence; consumed by client-side agents doing momentary inference against safe cloud servers or local LLMs — never persisted server-side
- One-time server data loads: certain data loads once before onboarding, and again after onboarding once the user provides preferences or personal data
- Deliver solid reference code for every scenario with Prometheus Entity Management as the entity-layer replacement for TanStack Query (which sits in the wrong client layer for this data), all working cleanly with PGlite
