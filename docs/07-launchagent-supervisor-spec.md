# `launchagent-supervisor` — Skill Specification

> **Status:** v0.1.0 draft (for HMA v0.2.0)
> **Parent doc:** [`05-hma-pmp-companion-architecture.md`](./05-hma-pmp-companion-architecture.md)
> **Built on:** `prometheus-skill-pack/docs/audits/2026-08-20-skill-pack-architecture-review.md` §1
> **File path:** `skills/launchagent-supervisor/SKILL.md` (+ 6 harness mirrors + project templates)

---

## §0 · Frontmatter

As shipped in `skills/launchagent-supervisor/SKILL.md`:

```yaml
---
name: launchagent-supervisor
description: Author, install, and supervise a macOS LaunchAgent, a Linux systemd --user unit, or a Windows Scheduled Task for a long-running managed daemon. Use when adding a service to the substrate, when a service is crash-looping or silently disappearing, or when asked for auto-restart, self-healing, or a watchdog. Triggers on LaunchAgent, plist, launchd, launchctl, KeepAlive, ThrottleInterval, ProcessType, RunAtLoad, daemon, supervisor, self-healing, restart loop, watchdog, systemd user unit, scheduled task.
---
```

`scripts/check-skill-contracts.mjs` requires the frontmatter keys to be
exactly `name` and `description`, in that order, with `description` a single
line of at most 1024 characters. It rejects `license`, `version`,
`allowed-tools`, and `metadata`, so the trigger vocabulary that would
otherwise live in those keys is folded into `description` — which is what the
harness matches on anyway. `name` must equal the skill's directory name.

---

## §1 · Why this skill exists

A Prometheus-managed daemon is a long-running process
that the substrate supervises. On macOS, the canonical
supervisor is `launchd` (via a `LaunchAgent` plist). On
Linux, it's `systemd --user`. On Windows, it's the Task
Scheduler.

The 1.7.0 prometheus-skill-pack installs 7+ LaunchAgents
with a known-bad plist pattern: `KeepAlive: true` with
no `ThrottleInterval` and no `ProcessType`. This is the
architecture review's W1.1 finding, and it leads to
**launchd crash-loop amnesia** — launchd silently
removes the service on crash-loop, and the install
reports "healthy" because the port is empty.

This skill is the HMA-facing surface that codifies
the **9 fixes from the architecture review §1** as
reusable rules. Any project that adopts HMA's daemon
supervision inherits the same discipline.

---

## §2 · The 9 fixes (the canonical plist template)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- Identity (required) -->
  <key>Label</key>
  <string>ai.prometheus.<service-name></string>

  <!-- R1.1 + R1.2: bare KeepAlive is wrong; use the
       dictionary form so planned shutdowns don't restart
       and crashes do. ThrottleInterval prevents
       crash-loop removal. ProcessType keeps launchd
       from classifying the service as "inefficient". -->
  <key>KeepAlive</key>
  <dict>
    <key>SuccessfulExit</key>
    <false/>
    <key>Crashed</key>
    <true/>
    <key>NetworkState</key>
    <true/>
  </dict>
  <key>ThrottleInterval</key>
  <integer>15</integer>
  <key>ProcessType</key>
  <string>Interactive</string>

  <!-- What to run -->
  <key>ProgramArguments</key>
  <array>
    <string>/usr/local/bin/<binary></string>
    <string>--port</string>
    <integer>8943</integer>
  </array>

  <!-- When to run (RunAtLoad = true on login) -->
  <key>RunAtLoad</key>
  <true/>

  <!-- R1.3: log paths; per-service logrotate policy -->
  <key>StandardOutPath</key>
  <string>$HOME/.prometheus/logs/<service>.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/.prometheus/logs/<service>.err</string>

  <!-- Environment -->
  <key>EnvironmentVariables</key>
  <dict>
    <key>PROMETHEUS_HOME</key>
    <string>$HOME</string>
    <key>PATH</key>
    <string>/usr/local/bin:/opt/homebrew/bin:$HOME/.local/bin:/usr/bin:/bin</string>
  </dict>

  <!-- Resource limits (optional) -->
  <key>SoftResourceLimits</key>
  <dict>
    <key>NumberOfFiles</key>
    <integer>65536</integer>
  </dict>

  <!-- macOS bundle identifier for log tagging -->
  <key>WorkingDirectory</key>
  <string>$HOME</string>
</dict>
</plist>
```

### §2.1 The 9 fixes explained

| # | Fix | Why |
|---|---|---|
| R1.1 | `ThrottleInterval: 15` | launchd classifies > 5 restarts in 10s as "inefficient" and may remove the job. 15s is well above the threshold. |
| R1.2 | `KeepAlive` dictionary form | `{ SuccessfulExit: false, Crashed: true, NetworkState: true }` — planned shutdowns don't restart, crashes do, network changes don't restart. |
| R1.3 | `ProcessType: Interactive` | raises launchd's threshold for "inefficient" termination; the service is treated like a user app, not a background daemon. |
| R1.4 | `StandardOutPath` / `StandardErrorPath` | log files the Companion tails (per the joint spec §7). Per-service logrotate policy. |
| R1.5 | `RunAtLoad: true` | the service starts on login. Without this, the operator has to manually `launchctl kickstart` after every reboot. |
| R1.6 | self-healing watchdog | the binary itself has a `launchctl print self-check` every 5 min; if the service is removed, it re-bootstraps. |
| R1.7 | macOS notification | `osascript -e 'display notification …'` fires when a service has been `down` for > 5 min. |
| R1.8 | `.bootstrap-lock` PID file | the lock is a PID file, not a mkdir; the holding process gone → take the lock immediately. |
| R1.9 | one supervisor | `install-mcp-services.sh` is the only installer; `prometheus-services.sh` is deleted. |

### §2.2 The systemd --user unit (Linux)

```ini
# ~/.config/systemd/user/ai.prometheus.<service>.service
[Unit]
Description=Prometheus <service>
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/<binary> --port 8943
Restart=on-failure
RestartSec=15
StandardOutput=append:$HOME/.prometheus/logs/<service>.log
StandardError=append:$HOME/.prometheus/logs/<service>.err
Environment="PROMETHEUS_HOME=$HOME"
Environment="PATH=/usr/local/bin:/usr/bin:/bin"

[Install]
WantedBy=default.target
```

The `RestartSec=15` mirrors `ThrottleInterval: 15` on
macOS. The `StandardOutput=append:` is the systemd
equivalent of `StandardOutPath`.

### §2.3 The Windows Scheduled Task

The Scheduled Task is the most awkward of the three
because Task Scheduler is the worst of the three
supervisors. The Companion ships a helper that creates
a Task with:

- Trigger: at logon
- Action: run `<binary>` with the right args
- Settings: "If the task fails, restart every 1 minute",
  "Attempt to restart up to 3 times"
- Run as: the current user, with highest privileges

The Windows path is documented in the architecture
review's §1.5 as a known-bad layer; the Companion
tries to make it as good as it can be.

---

## §3 · The self-healing watchdog (Rust)

The binary itself includes a self-healing watchdog
(R1.6):

```rust
// src/bin/<service>/watchdog.rs
pub async fn self_check_loop(label: &str) {
    let mut interval = tokio::time::interval(Duration::from_secs(300));
    loop {
        interval.tick().await;
        let status = Command::new("launchctl")
            .args(["print", &format!("gui/{}/{}", uid(), label)])
            .output().await;
        if status.is_err() || !status.unwrap().status.success() {
            warn!(label, "self-check: service removed; re-bootstrapping");
            bootstrap_again(label).await;
        }
    }
}
```

The watchdog runs as a tokio task in the daemon's
process. If the service is removed (by launchd's
crash-loop heuristic, or by the operator deleting the
plist), the watchdog re-bootstraps it.

The same loop in systemd-land:

```rust
pub async fn self_check_loop_systemd(unit: &str) {
    let mut interval = tokio::time::interval(Duration::from_secs(300));
    loop {
        interval.tick().await;
        let status = Command::new("systemctl")
            .args(["--user", "is-active", unit])
            .output().await;
        if !String::from_utf8_lossy(&status.unwrap().stdout)
            .trim().eq("active")
        {
            warn!(unit, "self-check: service inactive; restarting");
            Command::new("systemctl")
                .args(["--user", "restart", unit])
                .output().await.ok();
        }
    }
}
```

---

## §4 · The HMA-side generator script

`scripts/render-supervisor-plist.sh` (new in the HMA
repo) generates the plist for a given service name
and binary path. Used by the Companion's
`install_service` Tauri command.

```bash
#!/usr/bin/env bash
# scripts/render-supervisor-plist.sh
# Generate a 9-fix-compliant LaunchAgent plist for a service.
set -euo pipefail
SERVICE_NAME="$1"
BINARY_PATH="$2"
PORT="${3:-}"
USER_HOME="${HOME:-$(eval echo ~$(id -un))}"
LOG_DIR="$USER_HOME/.prometheus/logs"
mkdir -p "$LOG_DIR"

cat > "$LOG_DIR/../LaunchAgents/ai.prometheus.$SERVICE_NAME.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>ai.prometheus.$SERVICE_NAME</string>
  <key>KeepAlive</key>
  <dict>
    <key>SuccessfulExit</key><false/>
    <key>Crashed</key><true/>
    <key>NetworkState</key><true/>
  </dict>
  <key>ThrottleInterval</key><integer>15</integer>
  <key>ProcessType</key><string>Interactive</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BINARY_PATH</string>$( [ -n "$PORT" ] && echo "
    <string>--port</string>
    <integer>$PORT</integer>" )
  </array>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>$LOG_DIR/$SERVICE_NAME.log</string>
  <key>StandardErrorPath</key><string>$LOG_DIR/$SERVICE_NAME.err</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PROMETHEUS_HOME</key><string>$USER_HOME</string>
  </dict>
  <key>SoftResourceLimits</key>
  <dict><key>NumberOfFiles</key><integer>65536</integer></dict>
  <key>WorkingDirectory</key><string>$USER_HOME</string>
</dict>
</plist>
PLIST

# Validate
plutil -lint "$LOG_DIR/../LaunchAgents/ai.prometheus.$SERVICE_NAME.plist"
```

The systemd version is similar (`scripts/render-supervisor-systemd-unit.sh`).

---

## §5 · The user notification path (R1.7)

When a service is `down` for more than 5 minutes, the
Companion emits a macOS notification:

```rust
// crates/prometheus-companion/src/commands/notify.rs
#[tauri::command]
pub async fn notify_down(state: State<'_, AppState>, service: String) -> Result<(), String> {
    if cfg!(target_os = "macos") {
        let _ = Command::new("osascript")
            .args([
                "-e",
                &format!(
                    "display notification \"{} is down\" with title \"Prometheus\" subtitle \"Click to investigate\"",
                    service
                ),
            ])
            .output().await;
    } else {
        // Linux: notify-send
        let _ = Command::new("notify-send")
            .args(["Prometheus", &format!("{} is down", service)])
            .output().await;
    }
    Ok(())
}
```

---

## §6 · When to invoke this skill

Invoke when:

- Adding a new service to the substrate
- A service is crash-looping and the operator wants a
  fix
- The user asks for "auto-restart", "self-healing",
  "watchdog", "KeepAlive", "throttle", or "ProcessType"
- The architecture review's §1 is being addressed
- The Companion's `install_service` Tauri command is
  generating a plist

Do **not** invoke when:

- The service runs only during a Claude Code session
  (use a hook, not a launchd job)
- The service is a one-shot (use `cron` or a launchd
  `StartCalendarInterval`)
- The service is an OS-level daemon (use a system
  LaunchDaemon plist, not a user LaunchAgent)

---

## §7 · Skills used (this skill is built on)

- `prometheus-skill-pack/skills/rust/actor-model` — the
  mpsc actor for the watchdog
- `prometheus-skill-pack/skills/rust/async-patterns` —
  graceful shutdown
- The architecture review §1 — the canonical 9 fixes

---

## §8 · Definition of done

- [ ] `skills/launchagent-supervisor/SKILL.md` exists with
      the frontmatter above
- [ ] The SKILL.md body covers all of §1-§7
- [ ] Mirrored to the 6 per-harness directories + `templates/project-skills/`
      via `bash scripts/sync-harness-skills.sh` (verify with `--check`)
- [ ] `scripts/render-supervisor-plist.sh` exists and
      produces a `plutil -lint`-clean plist
- [ ] `scripts/render-supervisor-systemd-unit.sh` exists
- [ ] The 7 existing PMP LaunchAgents are migrated to the
      9-fix plist template (R1.1-1.9 in the architecture
      review)
- [ ] The `self_check_loop` watchdog is added to the
      substrate's most-crash-prone service as a reference

---

*This is the v0.1.0 spec for the `launchagent-supervisor`
skill, to be added to the HMA package in v0.2.0. The skill
encodes the 9 fixes from the architecture review §1 as
reusable plist and systemd templates. The generator
script applies the fixes to any new or existing service.*
