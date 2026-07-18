---
sidebar_position: 5
title: Multi-tenant SaaS
description: Staged prompts for SaaS with threat model, RLS, optional Kratos/Gate/Keto, BYOK, Forge/Fabric isolation, deployment, recovery, and tenant-boundary proof.
---

# Multi-tenant SaaS

Use this recipe when the app becomes a SaaS product. Authentication can be
optional for a demo, but tenancy cannot be accidental. Tenant identity,
authorization, RLS, realtime channels, BYOK, and audit logs must be modeled
deliberately.

## Prerequisites

```text
Verify tenancy model, threat model owner, Postgres/RLS strategy, secret manager
target, optional Kratos/Gate/Keto decision, Forge/Fabric availability, and BYOK
provider list.
```

## Discovery and Feynman prompts

```text
Read auth/security patterns, deployment catalog, Forge/Fabric/Gate docs,
Kratos/Keto docs, database policies, tenant identity model, and app config.
```

```text
Explain tenant isolation from request identity through API, RLS, realtime
channels, BYOK secret access, audit logs, and anonymous mode.
```

## KBD prompts

```text
/kbd-assess multi-tenant-saas
Assess tenants, roles, data classes, BYOK risks, anonymous access, realtime
scope, audit needs, onboarding, and deployment environments.
```

```text
/kbd-analyze multi-tenant-saas
Analyze auth adapters, database schema, RLS policies, secret references,
Forge/Fabric isolation, Gate/Kratos/Keto integration points, and overlays.
```

```text
/kbd-spec multi-tenant-saas
Specify threat model, tenant IDs, identity mapping, authorization tuples, RLS,
BYOK storage references, realtime isolation, audit events, anonymous-mode
decision, and tenant-boundary tests.
```

```text
/kbd-plan multi-tenant-saas
Plan identity and tenant types first, then RLS, API enforcement, BYOK secret
references, realtime isolation, UI settings, deployment manifests, tests,
critic, and retention.
```

## Implementation and verification

```text
Implement tenant identity as a required domain type. Do not pass raw provider
keys through logs or public docs. Make anonymous mode an explicit product
decision, not a default accident.
```

```text
Attempt cross-tenant reads/writes through public API, database policy, realtime
subscription, and BYOK access. Render deployment manifests and scan for inline
secrets.
```

## Stop evidence

Stop for missing threat model, unscoped BYOK keys, inline secrets, ambiguous
anonymous mode, unverified RLS, cross-tenant leak, or direct production
deployment.
