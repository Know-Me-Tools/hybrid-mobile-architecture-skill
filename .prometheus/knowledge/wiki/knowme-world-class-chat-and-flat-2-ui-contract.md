---
type: Reference
id: knowme-world-class-chat-and-flat-2-ui-contract
title: KnowMe world-class chat and Flat 2.0 UI contract
tags:
- knowme
- assistant-ui
- shadcn-ui
- flat-2
- pglite
- pglite-oxide
- conversation-history
- content-block
sources:
- chat:codex
timestamp: 2026-07-17T20:05:20Z
created_at: 2026-07-17T20:05:20Z
updated_at: 2026-07-17T21:45:00Z
revision: 3
---

## Binding UI decision

KnowMe uses strict Flat 2.0 on React, Tauri, and Flutter. There are no visible borders, divider lines, decorative outlines, or layout shadows. Adjacent regions and component states are distinguished by background-color changes. The same semantic surface hierarchy must work in light and dark themes.

React general-purpose controls use Shadcn UI. React chat uses Assistant UI for the thread, composer, thread list, streaming lifecycle, attachments, and message actions. Flutter uses the same design tokens and shadcn_flutter components. Registry defaults are restyled to KnowMe rather than shipped unchanged.

## Conversation architecture

- Prometheus Entity Management 3.x owns normalized conversation, message, block, citation, attachment, draft, and protocol-event entities.
- PGlite persists the browser/PWA entities in IndexedDB-backed storage.
- pglite-oxide persists the same logical records behind typed Rust commands in Tauri.
- Zustand owns only transient interaction state and in-flight stream assembly.
- Mobile persists through the shared Rust repository and the supported mobile relational backend; pglite-oxide is not an iOS/Android backend.
- TanStack Query and parallel query caches are prohibited.

Multiple conversations must be creatable, resumable, searchable, renameable, archivable, and deletable without losing messages or rich events. Append-only AG-UI/internal A2UI events retain thinking, citation, memory/RAG, tool, skill, artifact, and media provenance.

## Rich response contract

Assistant responses support safe Markdown extensions, code, lazy Mermaid rendering, sanitized SVG artifacts, images, audio/video with controls and no autoplay, citations, memory chunks, thinking, tools, skills, and downloadable artifacts. Each shared ContentBlock variant has an exhaustive React and Flutter renderer. Raw model HTML is never trusted.

## Local-first behavior

Chat works without credentials. Browser/PWA uses WebLLM with a cached product-default model when WebGPU is available. Tauri uses the downloaded Rust local model. Cloud is optional BYOK and must never be a silent fallback from an explicitly selected on-device lane.

The canonical product standard is `docs/knowme-ui-ux-standard.md`; scaffolds, templates, skills, audits, CLAUDE.md, and AGENTS.md must enforce it so generated applications cannot regress to hand-rolled chat, Material defaults, or border-based Shadcn defaults.

## Local-inference verification finding

The ignored public-boundary `local_inference_live` behavior test exposed that the macOS desktop dependency was described as Metal-capable while `mistralrs` had all default features disabled and no `metal` or `accelerate` feature enabled. The resulting CPU auto-device mapper reported zero available memory and refused to load the Qwen 1.5B Q4 model.

The Xcode Metal Toolchain is now installed and `xcrun -f metal` resolves it. Enabling the
correct Metal and Accelerate features actively compiled Mistral Metal shaders, then exposed
an upstream dependency defect: the pinned Mistral fork resolves Candle core/nn 0.10.2 from
Hugging Face while its Metal kernel edge still resolves Candle 0.11 from the GQAdonis
fork. Their `Device`, `Buffer`, and `EncoderProvider` types cannot unify. A controlled
attempt to patch the Metal kernel to the same upstream revision still left both source
versions in `mistralrs-quant` and `mistralrs-paged-attn`, producing the same class of
compile failure. Per the two-attempt rule, the live Mistral test loop stopped and the
Metal feature change was not retained because it would break normal macOS builds.

The remaining blocker is therefore the pinned Mistral/Candle dependency graph, not the
machine toolchain. Local chat must not be reported as verified through Mistral until that
graph is corrected or the desktop local lane is moved to another embedded backend; cloud
must not silently replace an explicitly selected on-device lane.
