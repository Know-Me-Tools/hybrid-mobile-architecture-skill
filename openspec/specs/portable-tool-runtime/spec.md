# Portable Tool Runtime Specification

## Purpose

Define the package-wide portability contract for first-party execution,
platform evidence, and byte-identical full and mini payloads.

## Requirements

### Requirement: First-party portable execution
The package SHALL ship TypeScript 7-authored `.mjs` hook/orchestration entrypoints and native Rust utilities without first-party Bash or Python runtime dependencies. Vendor toolchain internals SHALL be identified separately.

#### Scenario: Clean Windows consumer
- **WHEN** a user installs the package on Windows x64 or ARM64 with the declared prerequisites
- **THEN** hooks and installation run without Bash, Python, jq or a full skill-pack checkout
- **AND** malformed advisory hook input never blocks the user's workflow

### Requirement: Honest platform evidence
The package SHALL distinguish target installation, cross-compilation, native linking and native execution.

#### Scenario: Cross target installed on macOS
- **WHEN** Windows Rust standard-library targets are installed on macOS
- **THEN** diagnostics SHALL NOT report Windows build or execution as verified

### Requirement: Reproducible package payload
Full and mini distributions SHALL ship identical portable runtime bytes and all required resources.

#### Scenario: Staged package smoke
- **WHEN** the payload is copied away from its source checkout
- **THEN** consumer commands resolve their own resources and pass the documented smoke checks
