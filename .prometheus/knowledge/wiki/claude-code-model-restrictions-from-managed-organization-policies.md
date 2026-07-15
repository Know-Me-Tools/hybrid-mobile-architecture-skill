---
type: Reference
id: claude-code-model-restrictions-from-managed-organization-policies
title: Claude Code model restrictions from managed organization policies
tags:
- claude-code
- managed-policy
- organization-settings
- model-access
- mdm
- troubleshooting
sources:
- stdin
timestamp: 2026-07-14T23:00:37.043066+00:00
created_at: 2026-07-14T23:00:37.043066+00:00
updated_at: 2026-07-14T23:00:37.043066+00:00
revision: 0
---

## Symptom pattern

A Claude Code error such as **"your account doesn't allow this change"**, especially when paired with UI instructions the user cannot follow, indicates a likely **managed policy or organization restriction** rather than a personal-plan limitation.

Typical indicators:

- Claude web chat can access a model under a personal Max plan.
- Claude Code CLI or desktop app cannot select the same model.
- Claude Code rejects configuration changes with an account-policy-style error.
- The remediation instructions reference admin UI or settings unavailable to the user.

## Root cause

Claude Code can read a local `managed-settings.json` deployed by an organization or MDM. If the account or machine is governed by a Team/Enterprise organization policy, that policy can:

- Restrict which models Claude Code may select.
- Block local configuration changes.
- Override personal Max-plan capabilities inside Claude Code.
- Apply consistently across Claude Code CLI and desktop app.

The Claude web app (`claude.ai`) does not necessarily honor the same local managed policy, which explains cases where the web app shows a model but Claude Code does not.

## Read-only confirmation commands

Check for managed policy files:

```bash
ls -la ~/.claude/managed-settings.json \
  "/Library/Application Support/ClaudeCode/managed-settings.json" \
  /etc/claude-code/managed-settings.json 2>/dev/null
```

If a file exists, inspect it. It is policy configuration, not credentials:

```bash
cat "/Library/Application Support/ClaudeCode/managed-settings.json" 2>/dev/null
cat ~/.claude/managed-settings.json 2>/dev/null
```

Look for keys such as:

- `model`
- `allowedModels`
- `permissions`
- Any explicit model names

Also check which account or organization Claude Code is using:

```text
/status
```

If `/status` shows an organization rather than only a personal account, that organization's admin settings may govern Claude Code.

## Resolution paths

- **`managed-settings.json` exists**: the model restriction likely lives in managed policy. On a personal machine, remove or adjust the file if appropriate. On a managed/work machine, only the organization admin or MDM owner should change it.
- **`/status` shows a Team/Enterprise organization**: Claude Code is governed by that organization's plan or policy, separate from the user's personal Max subscription. The organization may not have the desired model enabled for Claude Code. Fix in the org admin console or log Claude Code into the personal Max account instead.
- **No managed settings and no organization shown**: policy is less likely; investigate local Claude Code settings overrides next.

# Citations

1. stdin