---
sidebar_position: 3
title: Karpathy retention and PMPO loops
description: Preserve reusable learning safely while using PMPO to improve prompts without weakening requirements.
---

# Karpathy retention and PMPO loops

Karpathy retention turns each phase into reusable operating knowledge. PMPO
turns failed or weak prompts into better prompts. The two loops work together:
retention records what actually happened, and PMPO improves the next invocation
without changing the requirement to make failure look acceptable.

## Public and private retention

Maintain two levels of memory:

| Memory | Contains | Never contains |
|---|---|---|
| Project memory | Reviewed decisions, evidence, sanitized lessons, skill improvements. | Secrets, private raw transcripts, credentials, local machine details. |
| Private memory | Personal operating notes, rawer phase reflection, private context. | Material intended for public documentation without review. |

Public docs may synthesize lessons from memory, but they must not publish raw
conversation logs, private notes, credentials, personal data, or local machine
paths.

Retention prompt:

```text
Write a Karpathy retention record for this phase.

Include:
- intent;
- decisions;
- failed assumptions;
- evidence that passed;
- evidence still missing;
- reusable prompt or skill improvement;
- public/private classification.

Exclude:
- raw transcript;
- credentials;
- personal data;
- local machine paths;
- unsupported claims.
```

## Sanitization gate

Before content moves from memory into public docs:

```text
Classify each source as:
- public direct;
- public normalized;
- private synthesis only;
- excluded.

Then run the repository sanitization test. If it fails, remove or rewrite the
content and record the redaction reason in private memory.
```

## PMPO metaprompt loop

Use PMPO when an agent repeatedly misses the desired shape of work.

```text
PMPO loop:
1. Preserve the original requirement verbatim.
2. Identify output defects with evidence.
3. Rewrite the prompt, not the requirement.
4. Add constraints, examples, and stop conditions.
5. Rerun within a bounded retry budget.
6. Compare improved output to the original requirement.
7. Retain the prompt pattern only if it improves evidence.
```

## Requirement-preservation rule

The PMPO optimizer may change:

- task framing;
- decomposition;
- role assignment;
- examples;
- validation commands;
- stop conditions;
- evidence requirements.

It may not change:

- user intent;
- required features;
- authority boundaries;
- privacy constraints;
- verification criteria;
- non-negotiable architecture decisions.

Requirement-preservation prompt:

```text
Optimize this prompt, but preserve the original requirement.

Original requirement:
<verbatim user requirement>

Observed defects:
<evidence-backed defects>

Allowed changes:
- clearer sequencing;
- sharper constraints;
- role split;
- validators;
- examples.

Forbidden changes:
- dropping requirements;
- weakening verification;
- substituting unsupported technology;
- adding authority not granted.
```

## Bounded retries

Retry budgets prevent loop drift:

| Loop | Budget | Stop when |
|---|---|---|
| prompt rewrite | 2 attempts | same defect repeats or evidence improves. |
| implementation correction | 2 attempts per failing gate | same command fails for same reason. |
| research gap | 3 source passes | primary sources are exhausted or contradiction remains. |
| skill creation | 1 draft + 1 validation pass | scratch-project verification fails or passes. |

If the budget expires, write the blocker and ask for a decision instead of
continuing blind.

## Authority boundary

PMPO can propose a stronger process, but it cannot authorize new external
actions. If an improved prompt needs publishing, installing, deleting, charging,
emailing, or changing a remote service, stop and request explicit authority.

## Closure evidence

A retention/PMPO loop closes with:

- original requirement preserved;
- prompt delta recorded;
- defect evidence recorded;
- retry count recorded;
- final verification result recorded;
- reusable lesson or skill candidate identified.
