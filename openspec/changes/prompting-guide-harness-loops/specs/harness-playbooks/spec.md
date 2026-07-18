## ADDED Requirements

### Requirement: Six distinct operational playbooks
The guide SHALL publish separate playbooks for Codex, Claude Code, OpenCode, Kimi Code
CLI, Google Antigravity, and Zed. It MUST NOT present one harness's commands,
permissions, plugins, headless behavior, or session model as portable to another.

#### Scenario: Required harness inventory is complete
- **WHEN** the canonical prompting content is validated
- **THEN** exactly one discoverable playbook for each of the six required harnesses
  SHALL satisfy the harness contract

#### Scenario: Universal command is claimed
- **WHEN** a playbook applies a harness-specific command or permission flag to another
  harness without official evidence
- **THEN** review and semantic validation SHALL reject the claim

### Requirement: Operational content contract
Each harness playbook MUST include installation/version checks, instruction discovery,
project and global skill locations, plugin/marketplace behavior where supported, MCP
configuration, permissions, plan/build/critic invocations, autonomous budgets,
event/evidence capture, interruption/resume, and handoff examples.

#### Scenario: User follows a playbook from a fresh project
- **WHEN** the documented prerequisites are installed and the copyable commands are
  executed within their declared authority
- **THEN** the user SHALL be able to discover project instructions and skills, invoke
  a bounded producer, collect evidence, invoke an independent critic, and hand off or
  resume the task

### Requirement: Official and dated harness evidence
Every version-sensitive command and configuration path SHALL cite a current official
source and carry a `verified_at` date. Unverified local observations MUST be labeled
as such and SHALL NOT be generalized into support claims.

#### Scenario: Harness command ages beyond policy
- **WHEN** a command's verification date exceeds the documented freshness window
- **THEN** source validation SHALL flag it for review before publication can claim it
  is current

### Requirement: Harness-specific semantics are explicit
The playbooks SHALL cover Codex `AGENTS.md`, project skills, plugins, goals, approvals,
and parallel tasks; Claude Code `CLAUDE.md`, skills/plugins, hooks, subagents,
headless/streaming, permissions, budgets, and continuation; OpenCode skills, agents,
permissions, commands, MCP, and ACP; Kimi config, skills, plugins/hooks, MCP,
plan/auto/non-interactive modes, ACP, and step limits; Antigravity workspace/global
skills, plugins, hooks, MCP, SDK/CLI distinction, approvals, and artifacts; and Zed
native Agent Panel, ACP external agents, terminal threads, permissions, MCP, skills,
review, and thread handoff.

#### Scenario: Playbook completeness is checked
- **WHEN** a harness page omits one of its required semantic areas
- **THEN** the harness contract validator SHALL report the named missing area

### Requirement: Portable skill baseline remains bounded
The guide SHALL use the Agent Skills specification for shared `SKILL.md` packaging and
progressive disclosure, while explicitly treating harness installation, activation,
permissions, and invocation as separate contracts.

#### Scenario: Project skill is shared across harnesses
- **WHEN** one project-local skill is installed into supported harness directories
- **THEN** its core instructions SHALL remain identical and each harness playbook SHALL
  document only the harness-specific discovery and invocation wrapper
