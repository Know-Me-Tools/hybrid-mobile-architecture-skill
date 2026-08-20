# `tauri-tray-app` — Skill Specification

> **Status:** v0.1.0 draft (for HMA v0.2.0)
> **Parent doc:** [`05-hma-pmp-companion-architecture.md`](./05-hma-pmp-companion-architecture.md)
> **Built on:** `hybrid-mobile-architecture/skills/tauri-custom-titlebar/`,
> `prometheus-skill-pack/skills/tauri/tauri-react-vite/`
> **Reference impl:** `prometheus-companion/crates/prometheus-companion/src/tray.rs`
> **File path:** `skills/tauri-tray-app/SKILL.md` (+ 5 mirrors)

---

## §0 · Frontmatter

```yaml
---
name: tauri-tray-app
description: >
  Build a tray-resident Tauri 2.0 desktop application with a
  health-aggregator-driven tray icon, a frameless main
  dashboard window with a custom title bar, and a popover
  for at-a-glance status. Use when scaffolding the
  Prometheus Companion, a fleet operator's console, or any
  app that lives in the OS menu bar / system tray and
  supervises a set of background services. Triggers on:
  tray app, system tray, menu bar app, LSUIElement,
  accessory activation policy, popover, health
  aggregator, frameless window, Tauri 2, TrayIconBuilder.
license: MIT
version: '1.0.0'
allowed-tools: file_system code_interpreter sequential_thinking
metadata:
  author: Prometheus AGS
  category: tauri
  tags: [tauri, desktop, tray, system-tray, menubar,
         observability, health-aggregator, accessory]
---

# tauri-tray-app
```

---

## §1 · Why this skill exists

There are four skills in the HMA / PMP stack that touch
Tauri desktop:

- `tauri-react-vite` (PMP) — the IPC + Vite integration
- `tauri-custom-titlebar` (HMA) — the custom title bar
- `tauri-ui-review` (HMA) — the screenshot-driven review
  loop

None of them covers the **tray + popover + health
aggregator** pattern as a unit. The Companion is the
first truly tray-resident Tauri 2 app in the stack
(the Promethean pattern: "lives in the OS menu bar,
supervises a fleet of services, opens a dashboard on
demand, never appears in Cmd+Tab"). The pattern needs
to be reusable so a fleet operator's console or a CI
runner's status app can be built the same way.

This skill captures the pattern.

---

## §2 · The anatomy of a tray-resident Tauri 2 app

```
┌─────────────────────────────────────────────────────────────┐
│  OS shell (macOS menu bar / Windows system tray / Linux     │
│            Ayatana indicator)                                │
│  ┌──────────────────┐                                        │
│  │  Tray icon       │  ← color from health aggregator         │
│  └──────────────────┘                                        │
│         │                                                    │
│         │ left-click                                         │
│         ▼                                                    │
│  ┌────────────────────────────────────┐                      │
│  │  Popover window                    │  ← transparent,      │
│  │  (frameless, alwaysOnTop,          │    frameless,        │
│  │   skipTaskbar, transient)          │    skipTaskbar,       │
│  └────────────────────────────────────┘    closes on Esc     │
│         │                                                    │
│         │ "Show dashboard"                                   │
│         ▼                                                    │
│  ┌────────────────────────────────────┐                      │
│  │  Main window                       │  ← frameless,        │
│  │  (frameless, custom title bar,     │    custom title bar, │
│  │   dashboard content)               │    dashboard          │
│  └────────────────────────────────────┘                      │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Rust side (Tauri 2)                                │   │
│  │  - Health aggregator (mpsc actor)                   │   │
│  │  - Service supervisor (substrate)                   │   │
│  │  - Tray + popover builder                           │   │
│  │  - PEM 3.x state (in-process PGlite)                │   │
│  │  - A2UI bridge (surface)                            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## §3 · The 5 pieces (each a section in the skill body)

### §3.1 The tray icon builder (Rust)

The icon states (the 5 colors):

| State | Color | When |
|---|---|---|
| Green | `var(--success)` | All required services `liveness=up, readiness=ready` |
| Yellow | `var(--warning)` | At least one service degraded |
| Red | `var(--danger)` | At least one required service down for ≥ 30s |
| Gray | `var(--muted)` | Substrate paused by user |
| Spinner | animated | Substrate initializing |

The Rust side, in `crates/<app>/src/tray.rs`:

```rust
use tauri::tray::{TrayIcon, TrayIconBuilder, TrayIconEvent,
                   MouseButton, MouseButtonState};
use tauri::menu::{Menu, MenuItem, PredefinedMenuItem};
use tauri::Manager;

pub fn build_tray(app: &tauri::App) -> tauri::Result<TrayIcon> {
    let show = MenuItem::with_id(app, "show", "Show dashboard", true, None::<&str>)?;
    let status = MenuItem::with_id(app, "status", "Substrate status", true, None::<&str>)?;
    let pause = MenuItem::with_id(app, "pause", "Pause substrate", true, None::<&str>)?;
    let settings = MenuItem::with_id(app, "settings", "Settings…", true, None::<&str>)?;
    let pair = MenuItem::with_id(app, "pair", "Pair new device…", true, None::<&str>)?;
    let quit = MenuItem::with_id(app, "quit", "Quit", true, None::<&str>)?;
    let menu = Menu::with_items(app, &[&show, &status, &pause, &settings,
        &PredefinedMenuItem::separator(app)?, &pair,
        &PredefinedMenuItem::separator(app)?, &quit])?;

    TrayIconBuilder::with_id("prometheus-tray")
        .icon(app.default_window_icon().unwrap().clone())
        .icon_as_template(true)              // macOS template image
        .menu(&menu)
        .on_menu_event(|app, ev| match ev.id.as_ref() {
            "show"     => show_main(app),
            "status"   => show_tray_popover(app),
            "pause"    => toggle_pause(app),
            "settings" => show_settings(app),
            "pair"     => show_pairing(app),
            "quit"     => app.exit(0),
            _ => {}
        })
        .on_tray_icon_event(|tray, ev| {
            if let TrayIconEvent::Click {
                button: MouseButton::Left,
                button_state: MouseButtonState::Up, ..
            } = ev {
                show_tray_popover(tray.app_handle());
            }
        })
        .build(app)
}
```

### §3.2 The health aggregator (Rust, mpsc actor)

The aggregator subscribes to each service's health
update and applies the 5-color policy. See
`prometheus-companion/crates/prometheus-companion/src/health.rs`
for the canonical implementation.

```rust
pub struct HealthAggregator {
    state: Arc<RwLock<TrayState>>,
    supervisor: Arc<Supervisor>,
}

impl HealthAggregator {
    pub async fn run(self: Arc<Self>) {
        let mut rx = self.supervisor.subscribe_health();
        while let Some(update) = rx.recv().await {
            let new = self.compute(&update);
            if new != *self.state.read().await {
                *self.state.write().await = new.clone();
                self.app_handle.emit("tray:state", &new).ok();
                self.set_icon(&new).await;
            }
        }
    }
}
```

### §3.3 The popover window (TypeScript)

The popover window in `tauri.conf.json`:

```jsonc
{
  "label": "tray-popover",
  "title": "Prometheus",
  "decorations": false,
  "transparent": true,
  "width": 360,
  "height": 480,
  "resizable": false,
  "skipTaskbar": true,
  "alwaysOnTop": true,
  "visible": false,
  "focus": false
}
```

The React component (`src/presentation/components/tray/tray-popover.tsx`)
shows: substrate health, queue depth, last doctor run,
quick actions.

### §3.4 The main window (TypeScript, per `tauri-custom-titlebar`)

The main window has `decorations: false`,
`titleBarStyle: "Overlay"`, `hiddenTitle: true`. The
custom title bar is per the HMA `tauri-custom-titlebar`
skill. The dashboard is the main content (PEM 3.x
entity-driven, per the joint spec).

### §3.5 The macOS-specific trick: `LSUIElement`

For the menu-bar-only app, set the macOS activation
policy to `accessory`:

```jsonc
// tauri.conf.json
{
  "bundle": {
    "macOS": {
      "activationPolicy": "accessory"
    }
  }
}
```

This makes the app:
- Show in the menu bar but **not** in the Dock
- Show in the menu bar but **not** in Cmd+Tab
- Stay running when all windows are closed

For a regular desktop app that ALSO has a Dock icon,
set `activationPolicy: "regular"` (the default).

---

## §4 · The icon set (5 states × 6 sizes)

The 5 PNGs (green, yellow, red, gray, spinner) at
6 sizes (16, 22, 32, 44, 88, 176 px). Generated from a
single SVG source-of-truth by `scripts/gen-tray-icons.sh`:

```bash
#!/usr/bin/env bash
# scripts/gen-tray-icons.sh — generate tray icons from SVG
set -euo pipefail
SRC="assets/icons/tray-source.svg"   # one SVG with <g id="green"> etc.
OUT="assets/tray"
SIZES=(16 22 32 44 88 176)
for state in green yellow red gray spinner; do
  for size in "${SIZES[@]}"; do
    rsvg-convert -w "$size" -h "$size" "$SRC" \
      --stylesheet="assets/icons/tray-${state}.css" \
      > "${OUT}/${state}/${size}.png"
  done
done
```

The spinner is an animated SVG that `rsvg-convert`
rasterizes to a 4-frame PNG. Tauri tray API doesn't
support GIF; we use `set_icon` in a timer to cycle
through 4 PNGs at 200ms intervals.

---

## §5 · The health-aggregator policy (the 5-color logic)

```rust
fn compute(&self, update: &HealthUpdate) -> TrayState {
    let required = update.services.iter()
        .filter(|s| s.required)
        .collect::<Vec<_>>();

    // Critical: at least one required service has been
    // liveness=down for >= 30s
    if required.iter().any(|s|
        s.liveness == "down" &&
        s.down_since.elapsed() >= Duration::from_secs(30)
    ) {
        return TrayState::Red;
    }

    // Warning: at least one service is degraded
    if update.services.iter().any(|s|
        s.liveness == "up" && s.readiness != "ready"
    ) {
        return TrayState::Yellow;
    }

    // OK: all required services up and ready
    if required.iter().all(|s|
        s.liveness == "up" && s.readiness == "ready"
    ) && update.queue_depth < update.queue_threshold {
        return TrayState::Green;
    }

    // Paused: user paused
    if self.paused {
        return TrayState::Gray;
    }

    // Default: green
    TrayState::Green
}
```

---

## §6 · The launchd / systemd plist (companion's own daemon)

The tray app itself runs as a user-level service
(`launchd` on macOS, `systemd --user` on Linux). The
plist is generated by the
`launchagent-supervisor` skill (see
[`07-launchagent-supervisor-spec.md`](./07-launchagent-supervisor-spec.md))
with the 9 fixes from the architecture review §1
(`ThrottleInterval`, `ProcessType`, etc.).

The tray app **does not run in the menu bar at boot**.
It starts in the background, builds the tray icon,
and waits for user interaction. The `RunAtLoad: true`
in the plist triggers this on login.

---

## §7 · When to invoke this skill

Invoke when:

- Scaffolding a tray-resident Tauri 2 app
- Adding a tray icon to an existing Tauri 2 app
- The user asks for "menu bar app", "system tray", "LSUIElement",
  "accessory activation policy", "popover", "health
  aggregator", or "tray + dashboard"
- Migrating an Electron tray app to Tauri 2

Do **not** invoke when:

- The user just wants a regular Tauri 2 desktop app (use
  `scaffold-react-vite-tauri` instead)
- The user wants a tray-only utility (no dashboard) — use
  this skill but skip the dashboard pieces
- The user is debugging an existing tray app — use the
  architecture review §6 + `claude-hooks-reliability` instead

---

## §8 · Skills used (this skill is built on)

- `hybrid-mobile-architecture/skills/tauri-custom-titlebar` —
  the title bar pattern
- `hybrid-mobile-architecture/skills/launchagent-supervisor` —
  the plist generation
- `hybrid-mobile-architecture/skills/connected-skill-packages` —
  the install contract
- `hybrid-mobile-architecture/skills/a11y-gate` — the WCAG
  2.2 AA checks
- `hybrid-mobile-architecture/skills/tauri-ui-review` — the
  screenshot review
- `prometheus-skill-pack/skills/tauri/tauri-react-vite` — the
  IPC + Vite integration
- `prometheus-skill-pack/skills/architecture/clean-architecture` —
  the 4-layer CLEAN model

---

## §9 · Definition of done

- [ ] `skills/tauri-tray-app/SKILL.md` exists with the
      frontmatter above
- [ ] The SKILL.md body covers all of §1-§8
- [ ] Mirrored to the 5 per-harness directories
- [ ] Added to the `plugin.json` `skills` array
- [ ] The reference impl
      (`prometheus-companion/crates/prometheus-companion/src/tray.rs`)
      is linked from the skill body
- [ ] A new project can be scaffolded with this skill and
      pass the 8-shot `tauri-ui-review` check

---

*This is the v0.1.0 spec for the `tauri-tray-app` skill,
to be added to the HMA package in v0.2.0. The skill
captures the tray + popover + health-aggregator pattern
from the Prometheus Companion, generalized for any
fleet-operator console or status app. The reference impl
is in the Companion's `crates/prometheus-companion/src/`
directory.*
