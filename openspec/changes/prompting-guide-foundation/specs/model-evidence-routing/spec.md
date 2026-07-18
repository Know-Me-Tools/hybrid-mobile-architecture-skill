## ADDED Requirements

### Requirement: Dated model registry
The project SHALL maintain a machine-readable registry whose entries include provider,
exact model identifier or explicitly labeled family, verified date, official sources,
context and modality claims, tool/reasoning capabilities, recommended role classes,
known constraints, availability, and confidence.

#### Scenario: Exact model entry has adequate support
- **WHEN** an entry names an exact API model identifier
- **THEN** at least one current official source SHALL support that identifier and each
  published material claim SHALL map to a supporting source

#### Scenario: Requested model cannot be verified
- **WHEN** a requested model name has no current official evidence
- **THEN** the registry SHALL mark it unverified or unavailable and public guidance
  MUST NOT invent capabilities, context, pricing, or routing recommendations

### Requirement: Source sufficiency and freshness
Registry validation MUST distinguish URL reachability from claim support, require HTTPS
official sources, reject duplicate model identifiers, apply a documented freshness
window, and preserve access dates and vendor-reported labels.

#### Scenario: Family announcement is used for an exact identifier
- **WHEN** an exact model claim cites only a general family announcement that does not
  identify that model
- **THEN** validation SHALL fail the claim-to-source correspondence check

#### Scenario: Vendor benchmark is published
- **WHEN** an entry includes a vendor benchmark or qualitative vendor claim
- **THEN** generated guidance SHALL label it vendor-reported and include the evidence
  date

### Requirement: Requested model inventory accountability
The registry SHALL account explicitly for GPT-5.6 Sol, Terra, and Luna; Claude Sonnet
5, Opus 4.8, and Fable 5; Kimi K3, K2.7 Code, and K2.6; MiniMax M3; Qwen 3.7 Max and
Qwen 3.6 variants; and DeepSeek V4 Pro and Flash. “Account for” means either a current,
officially supported registry entry or a visible unverified/unavailable record with no
invented capabilities or recommendation.

#### Scenario: Every requested label is reconciled
- **WHEN** the registry inventory validator runs
- **THEN** each requested label SHALL resolve to a supported exact model/family record
  or an explicit unverified/unavailable status with the search date and evidence gap

#### Scenario: Vendor naming differs from the requested label
- **WHEN** official sources use a different identifier or product name
- **THEN** the registry SHALL preserve the requested alias for accountability, map it
  only when evidence supports equivalence, and publish the official identifier as the
  canonical value

### Requirement: Registry-derived routing guidance
Producer, critic, research, long-context, multimodal, and bounded-mechanical-work role
tables SHALL be generated from validated registry fields. Hand-authored prose MUST NOT
duplicate mutable model IDs, availability, context windows, or capability claims.

#### Scenario: Registry role changes
- **WHEN** a reviewed registry entry changes its recommended roles
- **THEN** regeneration SHALL update every public routing view deterministically

#### Scenario: Unverified model has no route
- **WHEN** an entry is unverified, unavailable, or lacks sufficient official evidence
- **THEN** the routing generator SHALL omit it from recommended producer and critic
  selections while retaining its transparent registry status if requested

### Requirement: Role selection remains evaluative
The guide SHALL present routing as dated, evidence-informed starting guidance rather
than a permanent endorsement and MUST require local task evaluation for consequential
work.

#### Scenario: User selects a producer and critic
- **WHEN** a recipe recommends role classes for a task
- **THEN** it SHALL require independent critic separation, task-specific evaluation,
  and observable acceptance evidence instead of relying on vendor ranking alone
