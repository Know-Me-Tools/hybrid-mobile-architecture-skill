## ADDED Requirements

### Requirement: A shipped template is either exercised or removed
The generator SHALL NOT retain a template that claims to produce compiling output while no
gate ever renders and builds it.

#### Scenario: A template is retained
- **WHEN** the pack keeps a code template in its generator
- **THEN** a named gate SHALL render it into a scratch project and build it, and that gate
  SHALL exit non-zero when the template is deliberately broken

#### Scenario: A template is withdrawn
- **WHEN** the pack removes a code template instead of gating it
- **THEN** no script, manifest, spec, or skill SHALL still reference it, and the generator
  purity audit SHALL pass

#### Scenario: A partially removed render step
- **WHEN** template render steps are removed from a scaffold script
- **THEN** no remaining step SHALL render a fragment of a removed artifact
