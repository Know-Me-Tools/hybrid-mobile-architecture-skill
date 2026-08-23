# `claude-hooks-reliability` — Skill Specification

> **Status:** v0.1.0 draft (for HMA v0.2.0)
> **Parent doc:** [`05-hma-pmp-companion-architecture.md`](./05-hma-pmp-companion-architecture.md)
> **Source of truth:** `prometheus-skill-pack/docs/audits/2026-08-20-skill-pack-architecture-review.md` §6
> **File path:** `skills/claude-hooks-reliability/SKILL.md` (+ 6 harness mirrors + project templates)

---

## §0 · Frontmatter

As shipped in `skills/claude-hooks-reliability/SKILL.md`:

```yaml
---
name: claude-hooks-reliability
description: Diagnose, fix, and prevent silent hook failures in the agent hook chain. Use when a hook is not firing, when a skill did not trigger, when a matcher is too narrow or too broad, when a hook runner leaks processes, or when hook stdout corrupts a tool decision. Triggers on hook not firing, hook unreliable, matcher issue, hook timeout, PostToolUse, SessionStart, UserPromptSubmit, SubagentStop, hook bundle, hook runtime, hook script, dispatcher hash, hooks.json, settings.json hooks.
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

The Claude Code hook chain is the **silent backbone** of every
Prometheus-managed project. If a hook doesn't fire, the
model never knows the rule exists, the bundle id drifts
silently, the matcher is too narrow, the inline `bash -c`
hangs, the runner leaks child processes, the dispatcher
hash check fires every time, the SubagentStop matchers are
fragile, the script's stdout pollutes the decision JSON, or
the runner doesn't reap zombies. Any of these issues turn
"the system works" into "the system feels broken" with no
visible error.

The architecture review §6 names **9 specific weaknesses**
(W6.1-6.9) and **10 specific remedies** (R6.1-R6.10). This
skill is the HMA-facing surface that codifies those
remedies as reusable rules. Any project that adopts HMA's
hook-reliability patterns inherits the same discipline.

---

## §2 · The 9 fixes (the canonical checklist)

This is the body of the skill. It is intentionally short
and prescriptive. When a session needs to fix a hook
issue, the answer is in this table.

### W6.1 — Inline `bash -c '…'` is fragile

**Symptom:** the hook fires, but a copy-paste of the inline
script into a different shell breaks silently. The quoting
chain (`'…'` and `"…"` and `'"'"'`) is unreadable.

**Fix (R6.1):** extract the inline script to a checked-in
file under `shared/scripts/generated/hooks/` and have the
JSON just call that file.

```diff
  {
    "hooks": [{
      "type": "command",
-     "command": "bash -c 'runner=\"$HOME/.prometheus/plugins/.../run-hook\"\nif [[ ! -x \"$runner\" ]] || ! \"$runner\" --bundle \"$1\" --resolve-only >/dev/null 2>&1; then\n  ...lots of inline shell...\nfi\nexec \"$runner\" --bundle \"$1\" --hook \"$2\" --harness \"$3\"'"
+     "command": "bash $BUNDLE_ROOT/shared/scripts/generated/hooks/sessionstart-kbd-control.sh \"$1\" \"$2\" \"$3\""
    }]
  }
```

**Verify:** the JSON is readable; each hook script is
independently testable with `echo '{"event":"…"}' |
bash the-script.sh`.

### W6.2 — SHA re-validated on every hook

**Symptom:** every hook pays the cost of `shasum -a 256` on
the dispatcher file. On a SessionStart with 5 hooks, that's
5 shasum calls before the first `Enter` is typed.

**Fix (R6.3):** cache the validated SHA for 60s in a temp
file (`/tmp/.prom-hook-cache-<bundle>`).

```bash
# Inside run-hook
CACHE="/tmp/.prom-hook-cache-${BUNDLE_ID}"
if [[ -f "$CACHE" ]] && [[ $(( $(date +%s) - $(stat -c %Y "$CACHE") )) -lt 60 ]]; then
  : # cache fresh
else
  ACTUAL="$(shasum -a 256 "$DISPATCHER" | awk '{print $1}')"
  [[ "$ACTUAL" == "$DISPATCHER_SHA" ]] || fail "DISPATCHER_HASH" "dispatcher hash differs"
  echo "$ACTUAL" > "$CACHE"
fi
```

**Verify:** `time pnpm tauri dev` shows the cache hit on
the second SessionStart.

### W6.3 — Subagent matchers are fragile

**Symptom:** the matchers `assessor`, `analyst`, `planner`,
`executor`, `reflector` must match the agent name string
exactly. A future agent named `planner-v2` or `plan`
silently fails to fire. The README claims a fallback
matcher exists, but the JSON has no matcher on the
fallback hook — so it fires for every subagent, defeating
the per-role design.

**Fix (R6.5):** use regex-anchored matchers, and add a per-
Prompt matcher to `UserPromptSubmit`.

```diff
  {
    "matcher": "assessor"
  }
+ {
+   "matcher": "^(planner|plan|planner-v2)$"
+ }
```

**Verify:** `/hooks` shows the regex matcher; the fallback
matcher fires for unknown subagents and only the
checkpoint.

### W6.4 — Hook stdout pollutes PreToolUse decisions

**Symptom:** the hook script writes a `WARN: …` line to
stdout. Claude Code parses it as the decision JSON and
discards the real decision. The hook "ran but didn't
block."

**Fix (R6.6):** `exec 2>>"$LOG"` first thing in every
generated hook script so stdout stays clean for decision
JSON.

```bash
#!/usr/bin/env bash
# shared/scripts/generated/hooks/sessionstart-kbd-control.sh
exec 2>>"$LOG_DIR/hooks.log"
# ... real work, all writes go to stderr or the log file ...
```

**Verify:** a hook that prints a warning still delivers the
correct decision.

### W6.5 — Hook leaks processes on timeout

**Symptom:** a hook that runs `sleep 60` in the background
and then `exit 0` returns within the timeout but leaks the
sleep. The runner doesn't reap zombies.

**Fix (R6.4):** spawn the hook via `setpgid`, kill the
process group on timeout, reap zombies.

```bash
# Inside the hook runner
HOOK_PID=
setsid bash -c "exec $HOOK_SCRIPT" &
HOOK_PID=$!
if ! wait $HOOK_PID; then
  kill -KILL -$HOOK_PID 2>/dev/null || true
fi
wait $HOOK_PID  # reap the zombie
```

**Verify:** `ps aux | grep <hook-name>` shows nothing after
a timeout.

### W6.6 — `sessionstart-*` matchers are too broad

**Symptom:** every SessionStart hook fires for every new
session, including read-only "what's in this file?"
sessions. The cold-start cost is multiplied by 5.

**Fix (R6.9):** tighten the matchers, or use a
`claude-code` matcher to skip non-Code-Code sessions.

```diff
  {
-   "matcher": "*"
+   "matcher": "claude-code"
  }
```

**Verify:** `/hooks` shows the narrowed matcher; a
read-only session still has the hooks fire but only for
the Claude-Code harness.

### W6.7 — No structured hook-result log

**Symptom:** when a hook misfires, the operator has no
observability. The bundle logs to its own file; the hook
script logs to another; the dispatcher logs to a third.

**Fix (R6.7):** a 1-line structured log per hook
invocation, appended to `~/.prometheus/logs/hooks.ndjson`:

```json
{"ts":"2026-08-20T12:34:56Z","hook_id":"sessionstart-kbd-control","harness":"claude-code","exit":0,"dur_ms":42,"stderr_hash":"…"}
```

**Verify:** `tail -f ~/.prometheus/logs/hooks.ndjson |
jq .` shows the line after every hook fire.

### W6.8 — `UserPromptSubmit` has no `matcher` field

**Symptom:** `prompt-karpathy-learning` is the only hook
in the `UserPromptSubmit` block, with no matcher. If a
second hook is ever added, both will unconditionally fire
on every prompt.

**Fix:** add a `matcher: "*"` to every entry in the
`UserPromptSubmit` block, even if it's the only one. The
matcher field is required for forward compatibility.

```diff
  {
+   "matcher": "*",
    "hooks": [{ "type": "command", "command": "..." }]
  }
```

**Verify:** the JSON schema validator accepts the entry;
`/hooks` shows the matcher.

### W6.9 — Inline `bash -c` is unfixable long-term

**Symptom:** even with the extracted-script fix, every
hook still has a `bash` interpreter in the loop. A
malformed env var or a missing binary breaks the whole
chain.

**Fix (R6.8):** replace the inline `bash` with a small
Rust binary `prom-hook-dispatch` (or fold into
`prometheus-exec run`). The binary is bundled once,
immutable, and ABI-versioned.

```rust
// crates/prom-hook-dispatch/src/main.rs
fn main() {
    let args = Args::parse();
    let bundle = resolve_bundle(&args.bundle)?;
    let script = bundle.script_for(&args.hook)?;
    let status = Command::new("bash")
        .arg(&script)
        .args(&args.rest)
        .env_clear()                    // clean env
        .envs(safe_env(&args))
        .status()?;
    std::process::exit(status.code().unwrap_or(1));
}
```

**Verify:** the JSON has `command: "prom-hook-dispatch"`
instead of `bash -c '…'`. The binary is signed.


---

## §3 · The HMA-side install script

`scripts/install-hooks-reliability.sh` (new in the HMA
repo) auto-applies the three **mechanically safe** fixes —
W6.3 (anchor bare-string SubagentStop matchers), W6.6
(narrow a bare-wildcard SessionStart matcher) and W6.8 (add
a missing `matcher`) — and **reports** the rest, because each
of those changes runtime behavior and needs a human
decision. Idempotent.

```bash
#!/usr/bin/env bash
# scripts/install-hooks-reliability.sh
# Apply the 9 hook-reliability fixes to a target project.
set -euo pipefail
TARGET="${1:-.}"
[[ -d "$TARGET" ]] || { echo "usage: $0 <target>"; exit 1; }
[[ -f "$TARGET/hooks/hooks.json" ]] || { echo "no hooks.json at $TARGET"; exit 1; }
# W6.1 — extract inline bash -c scripts to shared/scripts/generated/hooks/
# ... (apply each fix, in order) ...
echo "✓ applied 9 hook-reliability fixes to $TARGET"
```

## §4 · The HMA-side verify script

`scripts/verify-hooks-reliability.sh` is the inverse: it
checks the settings-level fixes (W6.1, W6.3, W6.4, W6.6,
W6.8) and fails with a per-fix message if not. W6.2, W6.5
and W6.7 are runner properties, checked only when a runner
binary is present; W6.9 is out of scope here entirely (see
§7). The Companion's `doctor` command runs this against
every installed package that ships hooks.

```bash
#!/usr/bin/env bash
# scripts/verify-hooks-reliability.sh
set -euo pipefail
TARGET="${1:-.}"
violations=0
# W6.1 — no inline bash -c with > 256 chars of script body
violations=$(grep -E '"command": "bash -c \047' "$TARGET/hooks/hooks.json" 2>/dev/null | wc -l)
[[ "$violations" -eq 0 ]] || { echo "W6.1: $violations inline bash -c scripts found"; exit 1; }
# ... (check each of the 9 fixes) ...
echo "verify-hooks-reliability: PASS"
```

---

## §5 · When to invoke this skill

Invoke when:

- A `hooks/hooks.json` is being created or modified
- A hook is reported as "not firing" by the operator
- The architecture review's §6 is being addressed
- The `scripts/install-hooks-reliability.sh` is being
  applied to a new project
- The Companion's `doctor` is reporting a hooks-related
  issue

Do **not** invoke when:

- The user just wants to add a new skill (no hook
  involvement)
- The user is debugging a Claude Code **plugin** issue, not
  a hook issue (different skills apply)

---

## §6 · Skills used (this skill is built on)

- `prometheus-skill-pack/skills/process/clean-skill` — the
  authoring rules
- `prometheus-skill-pack/skills/process/skill-refiner` —
  refinement
- The architecture review §6 — the canonical 9 weaknesses
  and 10 remedies

---

## §7 · Definition of done

- [ ] `skills/claude-hooks-reliability/SKILL.md` exists with
      the frontmatter above
- [ ] The SKILL.md body covers all of §1-§6
- [ ] Mirrored to the 6 per-harness directories + `templates/project-skills/`
      via `bash scripts/sync-harness-skills.sh` (verify with `--check`)
- [ ] `scripts/install-hooks-reliability.sh` exists and is
      executable
- [ ] `scripts/verify-hooks-reliability.sh` exists and is
      executable
- [ ] The **settings-level** fixes are applied to the HMA repo's own
      `.claude/settings.json` (if it has hooks) — W6.1, W6.3, W6.4, W6.6, W6.8
- [ ] `scripts/verify-hooks-reliability.sh` exits 0 on the
      HMA repo
- [ ] `bash scripts/check-w6-mapping.sh` exits 0 — the W6.x labels agree
      across this spec and the shipped skill, and every cited R6.x resolves
      in `docs/05`

### Out of scope for this repository

**W6.9 (`prom-hook-dispatch`) is owned by `prometheus-skill-system`**, not by
this package, and is deliberately absent from the list above.

This repository ships the *guidance skill*; it does not own the hook runtime the
guidance describes. It has no `crates/` directory and publishes no Rust
binaries, and every path the remedy table names — `crates/prom-hook-dispatch/`,
`shared/scripts/hook-runtime-v1.sh`, `hooks/hooks.json` — belongs to the
skill-system's layout, not this one. This repo's own hooks live in
`.claude/settings.json`.

`scripts/verify-hooks-reliability.sh` already encodes this boundary: W6.2, W6.5,
W6.7 and W6.9 are properties of a hook *runner* binary, so a project shipping no
runner has nothing to check. It reports no pending item for them.

One caveat for whoever builds it: the sketch in W6.9 still invokes `bash` to run
the resolved script. A dispatcher narrows the surface — one immutable,
ABI-versioned, env-cleared entry point instead of inline quoting — but does not
remove the interpreter its own symptom statement names.

---

*This is the v0.1.0 spec for the `claude-hooks-reliability`
skill, to be added to the HMA package in v0.2.0. The skill
encodes the 9 hook-reliability fixes from the architecture
review §6 as reusable rules. The install / verify scripts
make the fixes applicable to any project that adopts HMA's
hook chain.*
