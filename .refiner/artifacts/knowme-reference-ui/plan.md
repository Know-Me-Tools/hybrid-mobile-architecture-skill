# Plan — KnowMe Reference UI

1. Inventory accepted screens/states and record why the prior process missed them.
2. Install a binding reference-fidelity skill and corrected UI guidance in every harness and
   scaffolded project.
3. Establish one token pipeline and implement the full React shell/screen inventory using
   Shadcn and Assistant UI.
4. Replace the in-memory single-thread chat model with PEM 3.x conversation entities and
   platform-specific PGlite/pglite-oxide persistence.
5. Wire local-first model lifecycle, Liter-LLM BYOK, AG-UI/ContentBlock richness, and local
   memory/RAG into the visible product states.
6. Retrofit Flutter with generated tokens, equivalent navigation/screens, rich blocks, and
   the same Rust public workflows.
7. Capture and compare every required reference state; fix shared causes until converged.
8. Repeat builds, launches, persistence, inference, memory search, and scaffold verification
   from clean source state.

Required preview evidence lives under `dist/previews/knowme-reference-ui/` and includes a
desktop/phone × light/dark × destination/state screenshot manifest, diagnostics, and the
production preview artifact. The project UI itself remains under `apps/knowme-poc`.
