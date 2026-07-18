---
sidebar_position: 5
title: Connected loop transcript
description: A sanitized producer→critic→correction→verification→retention example with budgets, checkpoints, failure handling, and durable artifacts.
---

# Connected loop transcript

This is a sanitized example. It shows the expected shape of a Prometheus loop
without publishing raw private chat or machine-local details.

## Scenario

Goal: add a harness playbook page to the documentation site.

Budget:

- 45 minutes;
- one documentation page;
- two correction attempts;
- no external publication;
- no private memory copied into public docs.

Public boundary:

```bash
npm --prefix site run validate:prompting
npm --prefix site run sanitize
npm --prefix site run build
```

Durable artifacts:

- `docs/prompting/harnesses/<harness>.md`
- `docs/prompting/data/harnesses/<harness>.json`
- `site/scripts/validate-prompting.mjs`
- KBD task status
- reviewed project memory summary

## Producer turn

```text
Producer:
I will implement the next KBD task only.

Allowed files:
- docs/prompting/harnesses/<harness>.md
- docs/prompting/data/harnesses/<harness>.json
- site/scripts/validate-prompting.mjs if validation coverage is missing

Stop conditions:
- sanitizer fails on private content twice;
- official sources do not support a required claim;
- publication is requested but not authorized.

Verification:
- validate prompting contracts;
- sanitize public content;
- build site if this is the final task in the change.
```

Producer output:

```text
Changed:
- added harness page;
- added source map;
- updated validator for required sections.

Verification:
- validate:prompting passed;
- sanitize failed on a raw private/project-memory path.
```

## Critic turn

```text
Critic:
FAIL.

Evidence:
- The sanitizer caught a raw private/project-memory path in public docs.
- The page cannot be published until the path is rewritten as public-safe prose.

Required correction:
- remove the raw path;
- keep the operational concept;
- rerun validation and sanitization.
```

## Correction turn

```text
Producer:
Correction attempt 1 of 2.

Change:
- replaced the raw memory path with "reviewed project memory wiki".

Verification:
- validate:prompting passed;
- sanitize passed.
```

## Verification turn

```text
Verifier:
PASS for this task.

Requirement evidence:
- page exists;
- source dates are recorded;
- required sections are present;
- public-content sanitizer passed;
- no publication claim was made.

Remaining phase work:
- continue the next unchecked task.
```

## Retention turn

```text
Karpathy record:
Intent: add a publishable harness page.
Failure: sanitizer caught raw memory path leakage.
Decision: public docs may refer to reviewed memory concepts, not raw paths.
Reusable rule: run sanitize before marking any docs task complete.
Next waypoint: continue the next KBD apply task.
```

## Why this transcript matters

The loop demonstrates:

- producer does not self-certify;
- critic uses tool evidence;
- correction is bounded;
- verification matches the public boundary;
- retention records a reusable process improvement;
- private/raw material stays out of public documentation.
