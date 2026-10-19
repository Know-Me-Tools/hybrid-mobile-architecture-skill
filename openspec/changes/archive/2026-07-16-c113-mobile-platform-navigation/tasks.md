# Tasks — 2026-07-16-c113-mobile-platform-navigation

> **The proposal's premise was wrong.** It states iOS and Android "disagree" about
> top-vs-bottom navigation. Sourced research (T1) shows they converge on **bottom** for
> top-level destinations at phone width; Android's top tabs are a *different component
> for a different purpose*. That collapsed T2 from a hard tradeoff into a
> straightforward call. Full evidence in the phase decision-log.

- [x] T1 — RESEARCH (sourced from live pages; WebFetch returned JS shells, re-fetched
      via Firecrawl — every claim below is quoted guidance, not recall):
      - iOS HIG *Tab bars*: tab bar "lets people navigate between **top-level
        sections**", "floats above content at the **bottom of the screen**". Top
        placement on iPhone isn't discouraged — it's never contemplated. The explicit
        prohibition is about purpose: "support navigation, not… actions".
      - M3 *Navigation bar*: "**always placed at the bottom**", "**three to five**"
        destinations, "for **top-level destinations**".
      - M3 *Tabs*: "at the **top** of the content pane under an app bar", for "groups of
        **related content**". Decisive line: "Use navigation for distinct pages and
        **tabs for related content within a page**."
      - Real split is by **form factor, not OS**: Apple → top tab bar/sidebar on iPad;
        M3 → rail at expanded widths.
- [x] T2 — DECIDED + recorded in decision-log.md (**user-ratified**): mobile web/PWA uses
      **one convention — bottom nav, no platform detection**. Rationale: (1) it follows
      from the convergence — one bottom bar satisfies both HIG and M3, so adaptive buys
      nothing; (2) **no authority exists** for the alternative — web.dev's PWA *App
      design* chapter doesn't address nav placement at all and is internally inconsistent
      (icons platform-agnostic, fonts platform-native); (3) web OS-detection is
      UA-sniffing, which Client Hints deliberately degrade — two nav trees off an
      unreliable signal.
- [x] T3 — Flutter convention documented (`references/flutter/patterns.md`): bottom
      `NavigationBar` for top-level destinations; the M3-tabs trap; **no platform check**
      (`Platform.isIOS` in nav code is a smell); width-based rail switch; layer contract
      (router owns nav state, index *derived* from `matchedLocation`, one destinations
      list).
- [x] T4 — React/PWA convention documented (`references/tauri/patterns.md`): why not to
      adapt (all three reasons + sources), the 600px M3 boundary as a `--breakpoint-sm`
      token (Tailwind's default 640px is *not* the spec value), distinct nav landmark
      labels, `env(safe-area-inset-bottom)`, derive-don't-mirror, index-route exact match.
- [x] T5 — Applied to the PoC. Flutter already shipped a conformant bottom M3
      `NavigationBar` — no change needed. React had **no navigation at all** (single `/`
      route → ChatScreen), so this was greenfield: added `navigation.ts` (one
      destinations list), `AppShell.tsx` (bottom bar / rail by width), `MemoryScreen`,
      and the `/memory` route.
      **Three real bugs found by making the Memory screen reachable:**
        1. Desktop `memory_search`/`graph_expand` were still **stubs** returning empty
           `Vec<String>` — C-104 wired the mobile FFI to `gen_ui_agent::memory` but left
           the Tauri commands behind, so desktop memory search silently produced nothing.
        2. React's `MemoryHit` had drifted to `name`/`snippet`; the Rust type moved to
           `text`/`kind` in C-104 (Flutter updated, React not). An `as unknown as` cast —
           commented "known, tracked mismatch" — kept tsc quiet past the point the
           mismatch was resolved.
        3. `memoryStore`'s tests mocked `@tauri-apps/api/core`, but the store reaches Rust
           through the *plugin's* wrappers, which import their own `invoke` — so no call
           ever landed (0 invocations). Fixed 2 of the 4 known-failing desktop tests.
      `MemoryPanel` was fully built and hook-wired but **never mounted**, so it had no
      styling — it rendered unstyled the moment it became reachable. Styled to the
      existing token idiom.
- [x] T6 — `templates/project-skills/mobile-navigation/SKILL.md`: new skill (nothing
      existing covers nav placement — `content-block-ui` owns ContentBlock rendering,
      `hybrid-design-tokens` owns color/spacing/type, `tauri-custom-titlebar` owns the
      desktop window frame). Directive description + red-flags table, following the
      C-112 titlebar precedent.
      **Registered in all four places the list is duplicated** — `add-project-skills.sh`
      (hardcoded loop; unregistered = silently never installs), README, AGENTS.md,
      CLAUDE.md — and given a `skill-activation.py` matcher, without which it would
      install but never auto-activate. Matcher deliberately triggers on
      `Platform.isIOS`/`useragent` too: the wrong turn the skill exists to prevent.
      **Verified**: installs into a scratch project; hook fires on both a nav prompt and
      the `Platform.isIOS` trap.

## Verification — what was and wasn't proven

- **Verified on screen** (browser, real dev server, not just tsc): bottom bar at 375px;
  rail at 1024px; the switch between them; `/memory` navigation; the styled panel.
- **NOT verified on devices.** T5 originally asked for iOS simulator + Android. The React
  surface is Tauri-desktop + mobile-web, so browser widths are the honest test for *it* —
  but the **Flutter** side's conformance is asserted from reading `router.dart`
  (a bottom M3 `NavigationBar`), not from a simulator run. It was already conformant and
  is unchanged by this work, so nothing here regressed it; a device run would confirm
  rather than discover. Left explicit rather than claimed.
