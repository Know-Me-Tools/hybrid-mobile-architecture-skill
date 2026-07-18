# Why the First KnowMe UI Missed the Target

**Status:** Corrective-action record
**Acceptance target:** `KnowMe Standalone.html`, the approved screenshot set, and `docs/knowme-ui-ux-standard.md`

## Executive finding

The first implementation did not fail because the design target was ambiguous. It failed
because the delivery workflow allowed architecture-shaped placeholders to count as a
product. The application launched, but it did not implement the specified product shell,
screen inventory, visual system, conversation experience, or runtime proof.

The accepted standalone design demonstrates the missing standard: a coherent desktop and
phone shell, six real destinations, multiple conversations, structured agent events,
local-first model identity, durable memory concepts, theme parity, and intentional empty,
status, and control states.

## Evidence of the gap

| Requirement visible in the accepted design | Earlier implementation state | Result |
|---|---|---|
| Six destinations: Home, Chat, Hands, Memory, Models, Settings | Two routes: Chat and Memory | Product scope collapsed |
| Desktop rail and phone bottom navigation with branded chrome | Minimal icon rail/bottom bar without the product shell | Generic scaffold appearance |
| Conversation library and multiple durable threads | One in-memory `messages` array | No conversation product |
| Assistant-specific composer and thread behaviors | Raw `<textarea>`, `<button>`, and transcript list | Assistant UI was installed but unused |
| Thinking, tools, citations, memory writes, and rich blocks | Minimal generic ContentBlock output | Protocol capability invisible |
| Local model is ready/default, cloud is optional | Cloud lane defaulted and local dev required environment configuration | Out-of-box chat failed |
| PGlite/pglite-oxide conversation persistence | Chat lived only in Zustand memory | Refresh/relaunch lost history |
| Flat 2.0 background-defined hierarchy | Visible borders around shell, lane picker, input, and dividers | Direct violation of product direction |
| Deliberate light and dark KnowMe themes | Conflicting legacy and Shadcn token blocks | Theme drift |
| Screenshot parity across approved states | No accepted screenshot evidence | Visual quality was never proven |
| Flutter semantic parity | Stock `ThemeData.dark()` and stale unrelated tokens | Cross-platform claim was false |

## Root causes

### 1. “Architecture-compliant” was treated as “product-complete”

The audits emphasized directory layering, imports, compilation, and process launch. Those
checks are necessary, but they do not prove that the specified destinations, user journeys,
or interaction states exist. A two-route shell could pass while most of the product was
absent.

### 2. No visual acceptance oracle was bound to implementation

The mood board and product specifications existed, but the implementation process did not
create a screen/state coverage matrix or compare the running application to approved
screenshots. The UI-review skill requested screenshots but did not require matching a
specific reference or prove coverage of every route.

### 3. UI skills were advisory and inconsistently discoverable

The project-local skills were copied into generated projects, but the repository root did
not expose the full UI skill set to every harness. Only Claude received prompt hooks, and
other harnesses depended on best-effort skill discovery. A model could therefore complete a
UI task without ever loading the design, component, accessibility, or fidelity guidance.

### 4. The component stack was installed but not integrated

Shadcn UI and Assistant UI packages/components existed, yet the live chat route continued
to use raw controls. Dependency presence was mistaken for implementation. No audit checked
that the actual product boundary mounted Assistant UI or used Shadcn primitives.

### 5. State responsibilities were incomplete

Zustand correctly existed as UI state, but became the only chat store. The architecture did
not require conversations/messages/events to be Prometheus Entity Management entities
backed by PGlite on web and pglite-oxide on desktop. Consequently, multiple threads,
search, drafts, replay, and relaunch persistence never emerged.

### 6. Runtime verification was too narrow in practice

Launching Vite/Tauri and receiving HTTP 200 was reported as success even when the public
chat workflow failed. The stronger runtime-verification skill now requires a real prompt,
streamed ContentBlocks, persistence, memory search, production assets, and clean-checkout
proof, but those gates were not applied before the earlier quality claim.

### 7. Generator and skill guidance contained contradictory design advice

The token skill claimed `theme-factory` generated React and Flutter outputs even though it
does not. The UI-review skill rewarded shadows/depth while the current KnowMe standard
requires borderless, shadowless Flat 2.0 surface differentiation. Incorrect guidance made
theme parity and visual convergence less likely.

### 8. The reference application was not used as executable specification

The accepted standalone HTML contains working navigation, theme/form-factor toggles,
conversation selection, local/cloud lane selection, structured event blocks, memory review,
models, Hands, and settings. None of these were converted into a binding component/state
inventory before implementation.

## Corrective controls

| Control | Required effect |
|---|---|
| `reference-ui-fidelity` project skill | Makes design discovery, screen inventory, and screenshot comparison mandatory |
| `knowme-ui-ux-standard.md` | Establishes Flat 2.0, component, persistence, chat, and parity rules |
| All skills copied to all six harness directories | Same local instructions for Claude, Codex, OpenCode, Kimi, and compatible scanners |
| Activation keyword coverage | Prompts mentioning screenshots, prototypes, mood boards, or reference apps activate fidelity review |
| Complete route/state audit | Missing destinations or placeholder routes fail review |
| Assistant UI/Shadcn boundary checks | Installed-but-unused component libraries no longer count |
| PEM 3.x + PGlite/pglite-oxide contract | Conversation history becomes durable entity state instead of an in-memory demo |
| Local-first public-workflow gate | A prompt must work without cloud credentials and stream through the real UI |
| Reference screenshot matrix | Visual claims require evidence at phone/desktop and light/dark states |
| Flutter goldens and token-hash parity | Mobile cannot silently ship a stock unrelated theme |
| Clean scaffold verification | Fixes must be present in generators, not only the example app |

## Definition of correction

This failure is corrected only when:

1. the React/Tauri app implements the accepted screen inventory and conversation behavior;
2. the Flutter app expresses the same semantic theme and core journeys;
3. local inference, cloud BYOK, conversation persistence, memory/RAG, and rich event blocks
   work through real public boundaries;
4. all harnesses receive the same binding skills and reference-fidelity gate;
5. a fresh scaffold inherits those protections; and
6. clean-checkout runtime and screenshot evidence proves the result.

Documentation and skill changes prevent recurrence, but they do not by themselves satisfy
the definition above. The reference application and generators must also be implemented and
verified.
