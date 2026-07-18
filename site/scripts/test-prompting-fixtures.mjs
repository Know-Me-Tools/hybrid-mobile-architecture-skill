import {readFile} from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import Ajv from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';

const repoRoot = path.resolve(import.meta.dirname, '..', '..');
const schemasRoot = path.join(repoRoot, 'docs', 'prompting', 'schemas');
const errors = [];

async function compile(schemaName) {
  const ajv = new Ajv({allErrors: true, strict: false});
  addFormats(ajv);
  return ajv.compile(JSON.parse(await readFile(path.join(schemasRoot, schemaName), 'utf8')));
}

function expectReject(label, validate, value) {
  if (validate(value)) {
    errors.push(`${label}: expected schema rejection`);
  }
}

function expectSanitizerReject(label, value) {
  const forbidden = [
    /\/Users\/[A-Za-z0-9._-]+/,
    /\.prometheus\//,
    /prometheus-wiki-private/i,
    /(codex_internal_context|in-app-browser-context|session log|raw conversation)/i,
    /BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY/,
    /(?:api[_-]?key|client[_-]?secret|password|token)\s*[:=]\s*["'][^"']+/i,
    /(?:guaranteed success|always works|never fails|fully autonomous without review)/i
  ];
  if (!forbidden.some((rule) => rule.test(value))) {
    errors.push(`${label}: expected sanitizer rejection`);
  }
}

function expectBareModelReject(label, value) {
  const bareGpt56Lowercase = /(^|[^A-Za-z0-9_.-])gpt-5\.6(?!-(?:sol|terra|luna)\b)(?=$|[^A-Za-z0-9_-])/;
  if (!bareGpt56Lowercase.test(value)) {
    errors.push(`${label}: expected bare gpt-5.6 rejection`);
  }
}

const recipeValidate = await compile('recipe.schema.json');
const registryValidate = await compile('model-registry.schema.json');
const harnessValidate = await compile('harness.schema.json');

expectReject('empty recipe prompt', recipeValidate, {
  id: 'scenario-full-knowme-hybrid',
  title: 'Incomplete',
  scenario: 'Hybrid',
  harnesses: ['harness-codex'],
  required_skills: ['orchestrate-prometheus-application'],
  recommended_roles: ['role-balanced-producer', 'role-independent-critic'],
  authority: ['authority-repo-local-write'],
  artifacts: ['artifact-guide-page'],
  evidence: ['evidence-public-boundary', 'evidence-independent-critic'],
  recovery: ['recovery-two-failure-stop'],
  termination: 'Stop with public evidence.',
  prompts: {
    prerequisites: '',
    discovery: '',
    feynman: '',
    kbd_assess: '',
    kbd_analyze: '',
    kbd_spec: '',
    kbd_plan: '',
    research: '',
    implementation: '',
    public_boundary_verification: '',
    independent_critic: '',
    reflection_retention: '',
    recovery: '',
    stop_conditions: ''
  }
});

expectReject('recipe missing stop evidence', recipeValidate, {
  id: 'scenario-tauri-local-inference',
  title: 'Missing stop',
  scenario: 'Desktop',
  harnesses: ['harness-codex'],
  required_skills: ['orchestrate-prometheus-application'],
  recommended_roles: ['role-balanced-producer', 'role-independent-critic'],
  authority: ['authority-repo-local-write'],
  artifacts: ['artifact-recipe-page'],
  evidence: ['evidence-public-boundary', 'evidence-independent-critic'],
  recovery: ['recovery-two-failure-stop'],
  termination: '',
  prompts: {
    prerequisites: 'Verify tools.',
    discovery: 'Read docs.',
    feynman: 'Explain.',
    kbd_assess: 'Assess.',
    kbd_analyze: 'Analyze.',
    kbd_spec: 'Spec.',
    kbd_plan: 'Plan.',
    research: 'Research.',
    implementation: 'Implement.',
    public_boundary_verification: 'Verify.',
    independent_critic: 'Critic.',
    reflection_retention: 'Retain.',
    recovery: 'Recover.',
    stop_conditions: ''
  }
});

expectReject('registry without official sources', registryValidate, {
  schema_version: 2,
  verified_at: '2026-07-18',
  disclaimer: 'test',
  freshness_policy: {max_age_days: 45, refresh_required_before_production_routing: true},
  requested_inventory: [{requested_label: 'Missing', registry_status: 'unverified', evidence_gap: 'none'}],
  models: []
});

expectReject('harness missing authority fields', harnessValidate, {
  id: 'harness-codex',
  name: 'Codex',
  instruction_sources: ['AGENTS.md'],
  skills: []
});

expectSanitizerReject('machine-local path', 'See /Users/example/private/file.md');
expectSanitizerReject('raw private wiki', 'Source: prometheus-wiki-private');
expectSanitizerReject('inline credential', 'api_key = "secret"');
expectSanitizerReject('unsupported claim', 'This agent never fails.');
expectBareModelReject('bare lowercase model id', 'Use codex / gpt-5.6 for implementation.');

if (errors.length) {
  console.error(errors.join('\n'));
  process.exit(1);
}

console.log('prompting negative fixtures passed');
