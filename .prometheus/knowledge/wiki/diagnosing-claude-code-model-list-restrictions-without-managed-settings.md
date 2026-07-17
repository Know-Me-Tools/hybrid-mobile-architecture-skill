---
type: Reference
id: diagnosing-claude-code-model-list-restrictions-without-managed-settings
title: Diagnosing Claude Code model list restrictions without managed settings
tags:
- claude-code
- model-access
- troubleshooting
- organization-settings
- settings-overrides
links:
- claude-code-model-restrictions-from-managed-organization-policies
sources:
- stdin
timestamp: 2026-07-14T23:01:31.761907+00:00
created_at: 2026-07-14T23:01:31.761907+00:00
updated_at: 2026-07-14T23:01:31.761907+00:00
revision: 0
---

## Finding

No `managed-settings.json` file was found in any of the checked locations. That rules out local MDM/enterprise managed policy as the cause of Claude Code model-list locking. This refines the diagnosis from [Claude Code model restrictions from managed organization policies](/claude-code-model-restrictions-from-managed-organization-policies.md): if managed settings are absent, focus on account/org context or personal settings overrides.

## Remaining likely causes

- **Organization attached to the login**: Claude Code may be authenticated under an organization rather than only a personal account.
- **Personal settings override**: User-level or project-level Claude settings may filter or force model behavior.
- **Account-policy-style error**: The recurring message paraphrased as `account doesn't allow this change` remains diagnostic, but the exact literal wording is needed to distinguish:
  - permissions block
  - model-access block
  - settings-write block

## Diagnostic steps

### 1. Check active account and organization context

Run in Claude Code:

```text
/status
```

Inspect whether the status output names an **organization** or only the user's personal account.

### 2. Search personal and project Claude settings for model-related overrides

Run:

```bash
grep -rn -iE '"(model|allowedModels|models|apiKeyHelper|forceLoginMethod)"' \
  ~/.claude/settings.json \
  ~/.claude/settings.local.json \
  .claude/settings.json \
  .claude/settings.local.json \
  2>/dev/null
```

Relevant keys to look for:

- `model`
- `allowedModels`
- `models`
- `apiKeyHelper`
- `forceLoginMethod`

These may indicate local or project-level settings that constrain model selection or authentication behavior.

### 3. Capture the exact error wording

When the `account doesn't allow this change` error appears again, capture the full literal text by screenshot or copy/paste. Do not rely on paraphrase; the exact string is needed to classify the failure mode.

## Current conclusion

Because no managed settings file exists, the model restriction is probably not caused by local MDM policy. Continue investigation with `/status`, settings grep output, and the exact error text.

# Citations

1. stdin
