## ADDED Requirements

### Requirement: The install contract is provable from a consumer's position
The pack SHALL provide an executable proof that a third party can install and register it
from a clone, exercising the documented contract rather than the local working tree.

#### Scenario: A fresh clone satisfies the contract
- **WHEN** the pack is cloned to a scratch location and the consumer-install proof is run
- **THEN** all four install-contract conditions SHALL hold and every shipped skill SHALL
  resolve through the harness registry path a consumer would use

#### Scenario: The proof cannot read the source tree
- **WHEN** the consumer-install proof executes
- **THEN** it SHALL operate only on the clone, so a passing result cannot be produced by
  the local checkout

#### Scenario: A broken package is rejected for its own reason
- **WHEN** the clone is perturbed with an undeclared skill directory, a missing plugin
  manifest, or a manifest naming an unresolvable skill
- **THEN** the proof SHALL exit non-zero and its message SHALL name that specific cause
