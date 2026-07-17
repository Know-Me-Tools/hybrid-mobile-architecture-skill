<!-- source=agent-a6bf13877ab890979; branch=worktree-agent-a6bf13877ab890979; original_sha256=ac3617da9eaa8461ae8a274993575eb476ef6eda9f278dee41336550427570c0 -->
---
type: Reference
id: claude-code-model-access-divergence-caused-by-org-login-context
title: Claude Code model access divergence caused by org login context
tags:
- claude-code
- model-access
- organization-settings
- account-context
- troubleshooting
links:
- diagnosing-claude-code-model-list-restrictions-without-managed-settings
- claude-code-model-restrictions-from-managed-organization-policies
sources:
- stdin
timestamp: 2026-07-14T23:02:56.790610+00:00
created_at: 2026-07-14T23:02:56.790610+00:00
updated_at: 2026-07-14T23:02:56.790610+00:00
revision: 0
---

## Context

Claude Code could not show or select Sonnet 5 in either the CLI or desktop app, while the same user could access Sonnet 5 in Claude web/desktop chat through a personal Max plan.

Established facts:

- Personal Max plan has Sonnet 5 available in `claude.ai` web/desktop chat.
- Sonnet 5 is missing from all Claude Code surfaces: CLI and desktop app.
- No `managed-settings.json` was found, ruling out local MDM/enterprise managed settings as the immediate cause; see [Diagnosing Claude Code model list restrictions without managed settings](/diagnosing-claude-code-model-list-restrictions-without-managed-settings.md).
- Claude Code occasionally emits an error paraphrased as **"your account doesn't allow this change"** with remediation instructions that do not match the user's UI.
- Bash and filesystem MCP access are sandboxed to `$REPO_ROOT`, so they cannot inspect `~/.claude/` or global Claude Code config.

## Likely root cause

The strongest diagnosis is that **Claude Code is authenticated against a different account or organization context than the personal Max plan**.

Most likely scenario: Claude Code is logged into a Team/Enterprise workspace where:

- The organization's plan governs model access and may not include or enable Sonnet 5.
- Organization policy overrides personal Max-plan entitlements inside Claude Code.
- Settings changes are rejected with account-policy errors such as **"your account doesn't allow this change"**.
- Error remediation text assumes the user is an org admin, explaining why the referenced settings or admin UI do not appear.

This differs from the local managed-policy case in [Claude Code model restrictions from managed organization policies](/claude-code-model-restrictions-from-managed-organization-policies.md): no `managed-settings.json` was found, so the remaining high-probability explanation is **login/workspace context**, not machine-level MDM config.

## Definitive checks

These checks must be performed interactively because available tools are sandboxed to the project directory.

### CLI

Run:

```text
/status
```

Inspect the top account/login section. Determine whether it shows:

- only the personal email, e.g. `travis@know-me.tools`, or
- an organization/workspace name.

A previous sub-command errored, but the top section of `/status` should still render.

### Desktop app

Open:

```text
Settings → Account
```

Check which account and workspace Claude Code is signed into.

## Remediation

If Claude Code shows an organization/workspace instead of the personal account context:

1. In the CLI, run:

   ```text
   /login
   ```

2. Re-authenticate and explicitly choose the **personal account**, not the Team/Enterprise workspace.
3. Alternatively, switch account/workspace from the Claude Code desktop app's account settings.
4. Re-check model availability in Claude Code after switching context.

## Evidence to capture

The next time the account-policy error appears, copy the exact literal text. The precise wording can distinguish between:

- account permission block,
- model-access block,
- settings-write block,
- organization-admin-only control.

The current conclusion is inferred from the symptom combination; exact error text plus `/status` account context would confirm it.

# Citations

1. stdin