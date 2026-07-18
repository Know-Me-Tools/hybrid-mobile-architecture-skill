import {readdir, readFile, stat} from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import Ajv from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';
import {parse as parseYaml} from 'yaml';

const repoRoot = path.resolve(import.meta.dirname, '..', '..');
const promptingRoot = path.join(repoRoot, 'docs', 'prompting');
const schemasRoot = path.join(promptingRoot, 'schemas');
const skillRoots = [
  path.join(repoRoot, 'templates', 'project-skills'),
  path.join(repoRoot, '.agents', 'skills'),
  path.join(repoRoot, '.claude', 'skills'),
  path.join(repoRoot, '.codex', 'skills'),
  path.join(repoRoot, '.opencode', 'skills'),
  path.join(repoRoot, '.kimi-code', 'skills')
];

const requiredScenarioIds = [
  'scenario-full-knowme-hybrid',
  'scenario-flutter-rust-ffi',
  'scenario-tauri-local-inference',
  'scenario-full-stack-automation',
  'scenario-multi-tenant-saas',
  'scenario-local-agent-client',
  'scenario-ideation-studio',
  'scenario-native-rust-agent',
  'scenario-multi-cloud-deployment',
  'scenario-branded-docs-portal'
];

const recipePageById = {
  'scenario-full-knowme-hybrid': 'full-knowme-hybrid.md',
  'scenario-flutter-rust-ffi': 'flutter-rust-ffi.md',
  'scenario-tauri-local-inference': 'tauri-local-inference.md',
  'scenario-full-stack-automation': 'full-stack-automation.md',
  'scenario-multi-tenant-saas': 'multi-tenant-saas.md',
  'scenario-local-agent-client': 'local-agent-client.md',
  'scenario-ideation-studio': 'ideation-studio.md',
  'scenario-native-rust-agent': 'native-rust-agent.md',
  'scenario-multi-cloud-deployment': 'multi-cloud-deployment.md',
  'scenario-branded-docs-portal': 'branded-docs-portal.md'
};

const requiredHarnessIds = [
  'harness-codex',
  'harness-claude-code',
  'harness-opencode',
  'harness-kimi-code-cli',
  'harness-antigravity',
  'harness-zed'
];

const requiredRoleIds = [
  'role-frontier-architect',
  'role-balanced-producer',
  'role-mechanical-transformer',
  'role-research-synthesizer',
  'role-independent-critic'
];

const requiredEvidenceIds = [
  'evidence-official-source',
  'evidence-public-boundary',
  'evidence-clean-checkout',
  'evidence-independent-critic',
  'evidence-karpathy-record'
];

const requiredHarnessSections = [
  'installation_version_checks',
  'instruction_discovery',
  'skills_plugins',
  'mcp_configuration',
  'permissions',
  'plan_build_critic',
  'autonomous_budgets',
  'evidence_capture',
  'interruption_resume',
  'handoff_examples'
];

const harnessPageById = {
  'harness-codex': 'codex.md',
  'harness-claude-code': 'claude-code.md',
  'harness-opencode': 'opencode.md',
  'harness-kimi-code-cli': 'kimi-code-cli.md',
  'harness-antigravity': 'antigravity.md',
  'harness-zed': 'zed.md'
};

const loopPages = [
  {
    file: 'feynman-loop.md',
    fields: ['Invocation', 'Grade rubric', 'Failure branch', 'Closure evidence', 'Next waypoint']
  },
  {
    file: 'kbd-lifecycle.md',
    fields: ['Stage sequence', 'Stage gates', 'Waypoint and handoff files', 'Recovery for missing handoffs', 'End-to-end phase example']
  },
  {
    file: 'karpathy-pmpo.md',
    fields: ['Public and private retention', 'Sanitization gate', 'PMPO metaprompt loop', 'Requirement-preservation rule', 'Bounded retries']
  },
  {
    file: 'producer-critic-autonomy.md',
    fields: ['Producer and critic split', 'Cross-model anti-sycophancy', 'Autonomous development loop', 'Recovery loop', 'Skill-generation loop', 'Native-agent-generation loop']
  },
  {
    file: 'connected-transcript.md',
    fields: ['Producer turn', 'Critic turn', 'Correction turn', 'Verification turn', 'Retention turn']
  }
];

const errors = [];

const bareGpt56Lowercase = /(^|[^A-Za-z0-9_.-])gpt-5\.6(?!-(?:sol|terra|luna)\b)(?=$|[^A-Za-z0-9_-])/;

async function exists(filePath) {
  try {
    await stat(filePath);
    return true;
  } catch {
    return false;
  }
}

async function readJson(filePath) {
  return JSON.parse(await readFile(filePath, 'utf8'));
}

function addAjvError(label, validate) {
  for (const error of validate.errors ?? []) {
    errors.push(`${label}: ${error.instancePath || '/'} ${error.message}`);
  }
}

function assertIncludes(text, values, label) {
  for (const value of values) {
    if (!text.includes(value)) {
      errors.push(`${label}: missing ${value}`);
    }
  }
}

function assertNoBareGpt56(text, label) {
  const checkedText = text
    .split('\n')
    .filter((line) => !/(bare|invalid|rejected|by itself|without suffix)/i.test(line))
    .join('\n');
  if (bareGpt56Lowercase.test(checkedText)) {
    errors.push(`${label}: bare gpt-5.6 is not a valid model id; use an exact id such as gpt-5.6-sol`);
  }
}

function assertProducerCriticSeparation(recipe, label) {
  const roleText = recipe.recommended_roles.join(' ');
  if (!roleText.includes('critic')) {
    errors.push(`${label}: missing independent critic role`);
  }
  if (!recipe.evidence.includes('evidence-independent-critic')) {
    errors.push(`${label}: missing independent critic evidence`);
  }
}

function assertPromptBlocks(recipe, label) {
  for (const [name, prompt] of Object.entries(recipe.prompts)) {
    if (!prompt.trim()) {
      errors.push(`${label}: prompt ${name} is empty`);
    }
    if (/^\s*(todo|tbd|outline only)\s*$/i.test(prompt.trim())) {
      errors.push(`${label}: prompt ${name} is placeholder text`);
    }
  }
}

function assertArchitecture(recipe, label) {
  if (recipe.id === 'scenario-full-knowme-hybrid' || recipe.id === 'scenario-flutter-rust-ffi' || recipe.id === 'scenario-tauri-local-inference') {
    const body = JSON.stringify(recipe).toLowerCase();
    if (!body.includes('shared rust') && !body.includes('rust core')) {
      errors.push(`${label}: platform recipe must preserve shared Rust ownership`);
    }
    if (/(use|adopt|install|recommend|prefer)\s+tanstack query/.test(body)) {
      errors.push(`${label}: must not recommend TanStack Query`);
    }
  }
}

async function assertRecipePage(recipe, label) {
  const pageName = recipePageById[recipe.id];
  if (!pageName) {
    errors.push(`${label}: no expected page mapping`);
    return;
  }
  const pagePath = path.join(promptingRoot, 'scenarios', pageName);
  if (!(await exists(pagePath))) {
    errors.push(`${label}: missing recipe page ${path.relative(repoRoot, pagePath)}`);
    return;
  }
  const index = await readFile(path.join(promptingRoot, 'scenario-packs.md'), 'utf8');
  const page = await readFile(pagePath, 'utf8');
  const route = `./scenarios/${pageName}`;
  if (!index.includes(recipe.id)) {
    errors.push(`docs/prompting/scenario-packs.md: missing scenario id ${recipe.id}`);
  }
  if (!index.includes(route)) {
    errors.push(`docs/prompting/scenario-packs.md: missing link ${route}`);
  }
  for (const field of ['Prerequisites', 'Feynman', 'KBD', 'Implementation', 'verification', 'Stop']) {
    if (!page.toLowerCase().includes(field.toLowerCase())) {
      errors.push(`${path.relative(repoRoot, pagePath)}: missing recipe section ${field}`);
    }
  }
  if (!page.includes('```text')) {
    errors.push(`${path.relative(repoRoot, pagePath)}: missing copyable prompt block`);
  }
}

function assertRecipeEvidence(recipe, label) {
  if (!recipe.evidence.includes('evidence-independent-critic')) {
    errors.push(`${label}: missing independent critic evidence`);
  }
  if (!recipe.evidence.includes('evidence-public-boundary')) {
    errors.push(`${label}: missing public-boundary evidence`);
  }
  if (!/stop/i.test(recipe.prompts.stop_conditions) || recipe.prompts.stop_conditions.length < 20) {
    errors.push(`${label}: missing actionable stop evidence`);
  }
  if (!/official|source|docs|local source|registry/i.test(recipe.prompts.research)) {
    errors.push(`${label}: research prompt lacks source-evidence language`);
  }
}

function assertFreshSourceDates(record, label) {
  const verifiedAt = new Date(`${record.verified_at}T00:00:00Z`);
  if (Number.isNaN(verifiedAt.getTime())) {
    errors.push(`${label}: invalid verified_at date`);
    return;
  }

  const maxAgeMs = record.freshness_days * 24 * 60 * 60 * 1000;
  const now = new Date();
  if (verifiedAt.getTime() > now.getTime() + 24 * 60 * 60 * 1000) {
    errors.push(`${label}: verified_at is in the future`);
  }
  if (now.getTime() - verifiedAt.getTime() > maxAgeMs) {
    errors.push(`${label}: verified_at is older than freshness_days`);
  }

  for (const source of record.official_sources) {
    const accessedAt = new Date(`${source.accessed_at}T00:00:00Z`);
    if (Number.isNaN(accessedAt.getTime())) {
      errors.push(`${label}: source ${source.id} has invalid accessed_at date`);
      continue;
    }
    if (accessedAt.getTime() > now.getTime() + 24 * 60 * 60 * 1000) {
      errors.push(`${label}: source ${source.id} accessed_at is in the future`);
    }
    if (verifiedAt.getTime() - accessedAt.getTime() > maxAgeMs) {
      errors.push(`${label}: source ${source.id} predates verified_at by more than freshness_days`);
    }
  }
}

function assertHarnessCoverage(harness, label) {
  assertFreshSourceDates(harness, label);

  const sectionSet = new Set(harness.required_sections);
  for (const section of requiredHarnessSections) {
    if (!sectionSet.has(section)) {
      errors.push(`${label}: missing required section ${section}`);
    }
  }

  const supportedSections = new Set(harness.official_sources.flatMap((source) => source.supports));
  for (const section of supportedSections) {
    if (!requiredHarnessSections.includes(section)) {
      errors.push(`${label}: source supports unknown section ${section}`);
    }
  }

  const localOnlySections = requiredHarnessSections.filter((section) => !supportedSections.has(section));
  if (localOnlySections.length > 0 && !(harness.local_observations?.length > 0)) {
    errors.push(`${label}: sections ${localOnlySections.join(', ')} lack official-source coverage and need local_observations`);
  }
}

async function assertHarnessPage(harness, label) {
  const pageName = harnessPageById[harness.id];
  if (!pageName) {
    errors.push(`${label}: no expected page mapping`);
    return;
  }
  const pagePath = path.join(promptingRoot, 'harnesses', pageName);
  if (!(await exists(pagePath))) {
    errors.push(`${label}: missing harness page ${path.relative(repoRoot, pagePath)}`);
    return;
  }
  const page = await readFile(pagePath, 'utf8');
  for (const source of harness.official_sources) {
    if (!page.includes(source.url)) {
      errors.push(`${path.relative(repoRoot, pagePath)}: missing official source ${source.url}`);
    }
    if (!page.includes(source.accessed_at)) {
      errors.push(`${path.relative(repoRoot, pagePath)}: missing access date ${source.accessed_at}`);
    }
  }
  for (const section of ['Installation', 'Instruction', 'MCP', 'Permissions', 'Evidence', 'Handoff']) {
    if (!page.toLowerCase().includes(section.toLowerCase())) {
      errors.push(`${path.relative(repoRoot, pagePath)}: missing required prose section ${section}`);
    }
  }
  if (!page.includes('```text') && !page.includes('```bash')) {
    errors.push(`${path.relative(repoRoot, pagePath)}: missing copyable command/prompt block`);
  }
}

async function validateLoopPages() {
  for (const loop of loopPages) {
    const pagePath = path.join(promptingRoot, 'loops', loop.file);
    if (!(await exists(pagePath))) {
      errors.push(`docs/prompting/loops/${loop.file}: missing loop page`);
      continue;
    }
    const page = await readFile(pagePath, 'utf8');
    const label = path.relative(repoRoot, pagePath);
    assertNoBareGpt56(page, label);
    for (const field of loop.fields) {
      if (!page.includes(field)) {
        errors.push(`${label}: missing loop field ${field}`);
      }
    }
    if (!page.includes('```text') && !page.includes('```bash')) {
      errors.push(`${label}: missing copyable block`);
    }
    if (!/stop/i.test(page)) {
      errors.push(`${label}: missing stop condition language`);
    }
  }
}

async function collectSkills() {
  const names = new Set();
  for (const root of skillRoots) {
    if (!(await exists(root))) continue;
    for (const name of await readdir(root)) {
      if (await exists(path.join(root, name, 'SKILL.md'))) {
        names.add(name);
      }
    }
  }
  return names;
}

async function validateStructuredData(kind, schemaName) {
  const dataRoot = path.join(promptingRoot, 'data', `${kind}s`);
  if (!(await exists(dataRoot))) return;
  const ajv = new Ajv({allErrors: true, strict: false});
  addFormats(ajv);
  const schema = await readJson(path.join(schemasRoot, schemaName));
  const validate = ajv.compile(schema);
  const skills = await collectSkills();
  for (const file of (await readdir(dataRoot)).filter((name) => name.endsWith('.json')).sort()) {
    const filePath = path.join(dataRoot, file);
    const value = await readJson(filePath);
    const label = `${path.relative(repoRoot, filePath)}`;
    assertNoBareGpt56(JSON.stringify(value), label);
    if (!validate(value)) addAjvError(label, validate);
    if (kind === 'recipe') {
      assertPromptBlocks(value, label);
      assertProducerCriticSeparation(value, label);
      assertArchitecture(value, label);
      assertRecipeEvidence(value, label);
      await assertRecipePage(value, label);
      if (!value.evidence.includes('evidence-public-boundary')) {
        errors.push(`${label}: missing public-boundary evidence`);
      }
      if (!value.recovery.length || !value.termination.trim()) {
        errors.push(`${label}: missing recovery or termination rule`);
      }
      for (const skill of value.required_skills) {
        if (!skills.has(skill) && !skill.startsWith('prometheus:') && !skill.startsWith('external:')) {
          errors.push(`${label}: unresolved skill ${skill}`);
        }
      }
    }
    if (kind === 'harness') {
      assertHarnessCoverage(value, label);
      await assertHarnessPage(value, label);
    }
  }
}

async function validateInventory() {
  const inventoryPath = path.join(promptingRoot, 'content-inventory.md');
  const inventory = await readFile(inventoryPath, 'utf8');
  assertNoBareGpt56(inventory, 'docs/prompting/content-inventory.md');
  assertIncludes(inventory, requiredScenarioIds, 'content-inventory.md scenarios');
  assertIncludes(inventory, requiredHarnessIds, 'content-inventory.md harnesses');
  assertIncludes(inventory, requiredRoleIds, 'content-inventory.md roles');
  assertIncludes(inventory, requiredEvidenceIds, 'content-inventory.md evidence');
}

async function validateRegistryShape() {
  const ajv = new Ajv({allErrors: true, strict: false});
  addFormats(ajv);
  const schema = await readJson(path.join(schemasRoot, 'model-registry.schema.json'));
  const registryText = await readFile(path.join(promptingRoot, 'model-registry.yaml'), 'utf8');
  assertNoBareGpt56(registryText, 'docs/prompting/model-registry.yaml');
  const registry = parseYaml(registryText);
  const validate = ajv.compile(schema);
  if (!validate(registry)) {
    addAjvError('docs/prompting/model-registry.yaml', validate);
  }
}

async function validatePromptingMarkdown() {
  const markdownRoots = [
    promptingRoot,
    path.join(repoRoot, 'templates', 'project-skills', 'orchestrate-prometheus-application')
  ];
  for (const root of markdownRoots) {
    if (!(await exists(root))) continue;
    const stack = [root];
    while (stack.length) {
      const current = stack.pop();
      const currentStat = await stat(current);
      if (currentStat.isDirectory()) {
        for (const entry of await readdir(current)) {
          stack.push(path.join(current, entry));
        }
        continue;
      }
      if (!/\.(md|mdx|json|yaml|yml)$/i.test(current)) continue;
      assertNoBareGpt56(await readFile(current, 'utf8'), path.relative(repoRoot, current));
    }
  }
}

await validateInventory();
await validateRegistryShape();
await validateStructuredData('recipe', 'recipe.schema.json');
await validateStructuredData('harness', 'harness.schema.json');
await validateLoopPages();
await validatePromptingMarkdown();

if (errors.length) {
  console.error(errors.join('\n'));
  process.exit(1);
}

console.log('prompting content contracts passed');
