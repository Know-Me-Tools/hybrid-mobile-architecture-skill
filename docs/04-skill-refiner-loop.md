# `realtime-skill-refiner` — Skill Specification

> **Status:** v0.1.0 draft (for HMA v0.2.0)
> **Parent doc:** [`05-hma-pmp-companion-architecture.md`](./05-hma-pmp-companion-architecture.md)
> **Built on:** `prometheus-skill-pack/skills/process/skill-refiner/`
> **File path:** `skills/realtime-skill-refiner/SKILL.md` (+ 5 mirrors)

---

## §0 · Frontmatter

```yaml
---
name: realtime-skill-refiner
description: >
  Realtime detection and refinement of bugs in currently
  installed skill packages. Invokes skill-refiner on the
  affected skills, verifies the fix, and ships a local
  patch. Use when a skill is producing wrong answers,
  when the Companion's log monitor flags a skill as
  failing, or when the user says "skill X is broken, fix
  it". Triggers on: skill bug, skill failing, fix skill,
  patch skill, refine skill, realtime correction, skill
  regression, sycophancy.
license: MIT
version: '1.0.0'
allowed-tools: file_system code_interpreter sequential_thinking
metadata:
  author: Prometheus AGS
  category: process
  tags: [skill-refiner, bug-fix, realtime, companion,
         sycophancy, triage, ship]
---

# realtime-skill-refiner
```

---

## §1 · Why this skill exists

Skills ship with bugs. A description that fires for the
wrong prompt, a `description` that exceeds the 1024-char
cap, a `bash -c '…'` that hangs on a missing env var, a
matcher that's too narrow, a `name` that doesn't match
the folder. The PMP has a `skill-refiner` skill for
**proactive refinement** (the author runs it after
writing a skill). The Companion needs a **reactive
refinement loop** that runs when a real failure is
detected.

This skill is the entry point for that loop. It
implements the 5-stage Triage → Refine → Verify → Ship
flow from the joint spec §8.

---

## §2 · The 5-stage loop

```
                  ┌──────────────────┐
                  │ Detect (hook /   │
                  │ log monitor /   │
                  │ sycophancy-     │
                  │ correction)     │
                  └────────┬─────────┘
                           ▼
                  ┌──────────────────┐
                  │ Triage (gather   │
                  │ evidence, scope  │
                  │ affected skills)│
                  └────────┬─────────┘
                           ▼
                  ┌──────────────────┐
                  │ Refine (invoke   │
                  │ skill-refiner    │
                  │ per affected     │
                  │ skill)           │
                  └────────┬─────────┘
                           ▼
                  ┌──────────────────┐
                  │ Verify (run the  │
                  │ affected skill's │
                  │ eval / BDD)      │
                  └────────┬─────────┘
                           ▼
                  ┌──────────────────┐
                  │ Ship (write a    │
                  │ local patch,    │
                  │ re-register)     │
                  └──────────────────┘
```

### §2.1 Detect

The detection signal comes from one of three sources:

1. **Log monitor** — the Companion's `log_monitor` Tauri
   command (per the joint spec §7.2) tails every
   connected service's log and matches lines against
   patterns. A match against a "skill failed" pattern
   creates a `BugTicket`.
2. **Sycophancy correction** — the PMP
   `sycophancy-correction` skill is run on every skill
   output (via a hook, if installed). A flag creates a
   `BugTicket` with `source: 'sycophancy'`.
3. **User** — the operator opens the "Report a bug"
   dialog and selects a skill. Creates a `BugTicket` with
   `source: 'user'`.

The `BugTicket` is a PEM entity:

```ts
const bugTicketEntity = defineEntity({
  name: 'bugTicket',
  privacyClass: 'local',  // never server-synced; local-only
  fields: {
    id: { type: 'id', clientId: true },
    packageId: { type: 'string' },         // 'hybrid-mobile-architecture'
    skillName: { type: 'string' },         // 'a11y-gate'
    source: { type: 'enum', enum: ['log', 'sycophancy', 'user'] },
    evidence: { type: 'string' },          // the log line / the flagged text
    detectedAt: { type: 'datetime' },
    status: { type: 'enum', enum: [
      'new', 'triaged', 'refining', 'verified', 'shipped', 'rejected'
    ] },
  },
})
```

### §2.2 Triage

The triage stage runs **once per ticket**, triggered by
the user clicking "Investigate" in the toast. The
Companion spawns a Claude Code session in headless mode
with the `realtime-skill-refiner` skill loaded. The
session:

1. Reads the ticket
2. Reads the affected skill's `SKILL.md` and any
   referenced files
3. Searches the project for similar recent failures
   (a "this is a one-off" vs "this is a pattern"
   decision)
4. Proposes a triage:
   - **`affected_skills`**: which skills need to change
     (often the ticket names one skill but the real
     problem is in another that calls into it)
   - **`suggested_fix`**: a 1-paragraph English
     description of the proposed change
   - **`severity`**: `low` (cosmetic), `medium`
     (degraded), `high` (silently failing), `critical`
     (the skill is producing wrong answers that the
     user has acted on)
   - **`revert_possible`**: can the fix be reverted if
     the verify stage fails?

The triage is shown to the user in a side panel. The
**user must explicitly approve** to proceed. The
architecture review's §17 anti-pattern ("a producer
never grades its own work") applies here.

### §2.3 Refine

Once the user approves the triage, the Companion runs
the **PMP `skill-refiner` skill** in headless mode
against each affected skill:

```bash
claude -p "Refine the skill ${skill_ref} using the
skill-refiner skill. The triage is: ${suggested_fix}."
--allowedTools "Read,Edit,Write,Bash(bash:*)" \
--cwd ~/.prometheus/skill-packages/${package_id}
```

`skill-refiner` writes the patch to a **temporary file**
(atomic, `.new` extension). The Companion reads the
patch and shows a side-by-side diff in the UI.

### §2.4 Verify

The verify stage runs the affected skill's eval suite
(if any) and re-validates the manifest:

```bash
# Run the package's eval suite, if any
if [[ -f ~/.prometheus/skill-packages/${package_id}/scripts/eval.sh ]]; then
  bash ~/.prometheus/skill-packages/${package_id}/scripts/eval.sh
fi

# Re-run the install contract check
bash ~/.prometheus/skill-packages/${package_id}/scripts/verify-skill-manifest.sh

# Re-run the HMA hooks-reliability check
bash ~/.prometheus/skill-packages/${package_id}/scripts/verify-hooks-reliability.sh
```

If any check fails, the patch is **rejected** and the
user is shown the failure. No automatic revert; the
operator decides.

### §2.5 Ship

The ship stage applies the patch atomically:

```bash
# Atomic write: tempfile + os.replace
cp "${SKILL_NEW}" "${SKILL_PATH}.new"
mv "${SKILL_PATH}.new" "${SKILL_PATH}"

# Re-register the package with the active harness
claude plugin marketplace remove "${package_id}" || true
claude plugin marketplace add ~/.prometheus/skill-packages/${package_id}
claude plugin install "${package_id}@${package_id}"
```

The Companion then:

1. Updates the `bugTicket` entity to `status: 'shipped'`
2. Updates the `skillPackage` entity to
   `installedSha: <new sha>`, `lastValidatedAt: <now>`,
   `lastValidationResult: 'ok'`
3. Emits a Tauri event `skill:refined` so the UI can
   show a success toast

---

## §3 · The Tauri commands

```rust
// crates/prometheus-companion/src/commands/skill_refiner.rs
#[tauri::command]
pub async fn detect_skill_bug(
    state: State<'_, AppState>,
    signal: BugSignal,
) -> Result<BugTicket, String>;

#[tauri::command]
pub async fn triage_skill_bug(
    state: State<'_, AppState>,
    ticket: BugTicket,
) -> Result<Triage, String>;

#[tauri::command]
pub async fn refine_skill(
    state: State<'_, AppState>,
    skill_ref: SkillRef,
) -> Result<RefineOutcome, String>;

#[tauri::command]
pub async fn verify_skill_refinement(
    state: State<'_, AppState>,
    skill_ref: SkillRef,
) -> Result<VerifyOutcome, String>;

#[tauri::command]
pub async fn ship_skill_refinement(
    state: State<'_, AppState>,
    skill_ref: SkillRef,
    patch: SkillPatch,
) -> Result<(), String>;
```

The `refine_skill` command spawns a Claude Code session
via the `claude` binary in headless mode (`claude -p`).
The session is given only the `Read, Edit, Write,
Bash(bash:*)` tools and is `cwd`-bound to the package's
install path. The session writes the patch to
`${SKILL_PATH}.new`. The Companion reads the patch
back, shows the diff, and waits for the user to
approve `ship_skill_refinement`.

---

## §4 · The user-visible flow

When the Companion detects a bug:

1. A toast appears: "Skill `a11y-gate` is failing on
   the last 5 calls."
2. The user clicks "Investigate" → the Triage stage
   runs and shows the affected skills + suggested fix
   in a side panel.
3. The user reviews the triage, optionally edits the
   suggested fix, then clicks "Refine".
4. The Refine stage runs `skill-refiner` in headless
   mode and shows a side-by-side diff of the proposed
   patch.
5. The user reviews the diff, then clicks "Ship".
6. The Verify + Ship stages run automatically. On
   success, the toast changes to "Skill `a11y-gate`
   refined. New sha: `abc1234`."
7. On Verify failure, the patch is rejected and the
   user is shown the failure.

If the user closes the panel without acting, the
ticket stays in `status: 'new'` and reappears in the
"Refinement queue" on the next session.

---

## §5 · The "halt at Triage" rule (the user-in-the-loop invariant)

The architecture review's §17 anti-pattern is: "a
producer never grades its own work." The realtime
skill-refiner loop is a **producer** of patches. The
Triage stage is the **critical human review** gate.

**The loop always halts at Triage.** It does not auto-
apply, auto-verify, or auto-ship. The user must
explicitly approve at Triage, and again at Ship (the
side-by-side diff is the second approval). If the user
walks away, the ticket stays in the queue.

This is non-negotiable. A loop that fixes its own
bugs without human review is a sycophancy violation
(the model "agrees" the patch is good because it
wrote the patch).

---

## §6 · Skills used (this skill is built on)

- `prometheus-skill-pack/skills/process/skill-refiner` —
  the underlying refinement skill
- `prometheus-skill-pack/skills/process/sycophancy-correction`
  — the bug detector
- `prometheus-skill-pack/skills/architecture/clean-architecture`
  — the 4-layer CLEAN model
- `hybrid-mobile-architecture/skills/connected-skill-packages`
  — the install/upgrade path
- `hybrid-mobile-architecture/skills/claude-hooks-reliability`
  — the hooks reliability

---

## §7 · Definition of done

- [ ] `skills/realtime-skill-refiner/SKILL.md` exists with
      the frontmatter above
- [ ] The SKILL.md body covers all of §1-§6
- [ ] Mirrored to the 5 per-harness directories
- [ ] Added to the `plugin.json` `skills` array
- [ ] The Tauri commands in §3 are implemented in
      `crates/prometheus-companion/src/commands/skill_refiner.rs`
- [ ] The `bugTicket` PEM entity is in the Companion's
      domain
- [ ] The Companion's UI shows a Refinement queue
- [ ] A roundtrip test (introduce a bug → detect →
      triage → refine → verify → ship) exits 0

---

*This is the v0.1.0 spec for the `realtime-skill-refiner`
skill, to be added to the HMA package in v0.2.0. The skill
is the runtime complement to the PMP's
`skill-refiner` skill: same algorithm, different
trigger. The PMP `skill-refiner` is for proactive
refinement; the HMA `realtime-skill-refiner` is for
reactive refinement driven by real failures.*
