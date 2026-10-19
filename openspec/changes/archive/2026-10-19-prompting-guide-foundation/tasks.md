## 1. Canonical content contracts

- [x] 1.1 Inventory the current root/site prompting files and add the stable content,
  recipe, harness, role, evidence, authority, artifact, recovery, and route identifiers
  without deleting either source tree yet.
- [x] 1.2 Add JSON Schemas for recipe, harness, and model-registry data and pin Ajv in
  `site/package.json` and the frozen lockfile.
- [x] 1.3 Implement semantic validation for non-empty prompt blocks, producer/critic
  separation, skill resolution, TJ-ARCH-MOB-001/Base Rules, authority, evidence,
  recovery, and public-boundary termination.

## 2. Model evidence and routing

- [x] 2.1 Extend `model-registry.yaml` and its schema with exact-ID/family distinction,
  claim-to-source mapping, confidence, vendor-report labels, availability, role
  vocabulary, and freshness policy.
- [x] 2.2 Audit GPT-5.6 Sol/Terra/Luna, Claude Sonnet 5/Opus 4.8/Fable 5, Kimi
  K3/K2.7 Code/K2.6, MiniMax M3, Qwen 3.7 Max/3.6 variants, and DeepSeek V4
  Pro/Flash against current official sources; map supported official identifiers and
  preserve every unsupported request transparently without invented capabilities.
- [x] 2.3 Generate dated role-routing Markdown from the validated registry and add a
  committed-drift check so mutable model claims are not duplicated in prose.

## 3. Canonical source and privacy boundary

- [x] 3.1 Expand sanitization and content classification to scan `docs/prompting/` and
  reject private wiki/log material, secrets, personal data, unsupported claims, and
  machine-local paths before Docusaurus reads content.
- [x] 3.2 Prove the pinned Docusaurus build can consume `../docs/prompting`; if it cannot,
  implement the documented generated-copy/parity fallback and record the evidence.
- [x] 3.3 Migrate the two site summaries into the canonical taxonomy, update the
  prompting plugin path, and remove editable duplicates only after parity proof.

## 4. Foundation verification

- [x] 4.1 Run schema/semantic negative fixtures, sanitizer fixtures, registry generation
  drift checks, `npm --prefix site run sanitize`, and `npm --prefix site run build`.
- [x] 4.2 Build from a fresh source checkout without ignored site artifacts and record
  canonical-source, privacy, and generated-routing evidence in project Karpathy memory.
