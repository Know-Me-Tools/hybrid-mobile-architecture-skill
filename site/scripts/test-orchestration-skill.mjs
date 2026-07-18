import {readFile} from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const repoRoot = path.resolve(import.meta.dirname, '..', '..');
const errors = [];

async function read(relativePath) {
  return readFile(path.join(repoRoot, relativePath), 'utf8');
}

function assertIncludes(label, text, values) {
  for (const value of values) {
    if (!text.includes(value)) errors.push(`${label}: missing ${value}`);
  }
}

const skill = await read('templates/project-skills/orchestrate-prometheus-application/SKILL.md');
const classification = await read('templates/project-skills/orchestrate-prometheus-application/references/scenario-classification.md');
const control = await read('templates/project-skills/orchestrate-prometheus-application/references/control-loop.md');
const nativeDecision = await read('templates/project-skills/orchestrate-prometheus-application/references/native-agent-decision.md');

const knownScenario = {
  request: 'Build a Tauri desktop local inference app with Assistant UI chat.',
  expected: [
    'scenario-tauri-local-inference',
    'docs/prompting/scenarios/tauri-local-inference.md',
    'docs/prompting/data/recipes/tauri-local-inference.json'
  ]
};

const compositeScenario = {
  request: 'Build a SaaS app, publish docs, and deploy to Kubernetes.',
  expected: [
    'scenario-multi-tenant-saas',
    'scenario-branded-docs-portal',
    'scenario-multi-cloud-deployment'
  ]
};

assertIncludes('known scenario classification', classification, knownScenario.expected);
assertIncludes('composite scenario classification', classification, compositeScenario.expected);
assertIncludes('skill progressive refs', skill, [
  'references/scenario-classification.md',
  'references/control-loop.md',
  'references/native-agent-decision.md'
]);
assertIncludes('reference manifest', classification, [
  'Architecture references:',
  'Recipe references:',
  'Harness references:',
  'Loop references:',
  'Role/model references:',
  'Retention references:',
  'Verification references:'
]);
assertIncludes('producer critic and retention', control, [
  'The producer implements; the critic verifies.',
  'Record intent, evidence, failures, decisions, and reusable lessons',
  'hybrid-runtime-verification'
]);
assertIncludes('creator routing', control + nativeDecision, [
  'Use the skill creator',
  'Use the native-agent creator',
  'build, launch, protocol consumer'
]);
assertIncludes('incomplete without launch gate', skill + control, [
  'public-boundary verification',
  'before “working” or “complete.”'
]);

if (errors.length) {
  console.error(errors.join('\n'));
  process.exit(1);
}

console.log('orchestration skill scratch exercise passed');
