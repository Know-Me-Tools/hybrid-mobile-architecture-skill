import {readdir, readFile, stat} from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const repoRoot = path.resolve(import.meta.dirname, '..', '..');
const canonical = path.join(repoRoot, 'templates', 'project-skills', 'orchestrate-prometheus-application');
const harnessRoots = [
  '.agents/skills',
  '.claude/skills',
  '.codex/skills',
  '.opencode/skills',
  '.kimi/skills',
  '.kimi-code/skills'
];

const errors = [];

async function exists(filePath) {
  try {
    await stat(filePath);
    return true;
  } catch {
    return false;
  }
}

async function listFiles(root, prefix = '') {
  const files = [];
  for (const entry of await readdir(path.join(root, prefix), {withFileTypes: true})) {
    const relative = path.join(prefix, entry.name);
    if (entry.isDirectory()) {
      files.push(...await listFiles(root, relative));
    } else if (entry.isFile()) {
      files.push(relative);
    }
  }
  return files.sort();
}

const canonicalFiles = await listFiles(canonical);

for (const harnessRoot of harnessRoots) {
  const target = path.join(repoRoot, harnessRoot, 'orchestrate-prometheus-application');
  if (!(await exists(target))) {
    errors.push(`${harnessRoot}: missing orchestrate-prometheus-application`);
    continue;
  }

  const targetFiles = await listFiles(target);
  for (const file of canonicalFiles) {
    if (!targetFiles.includes(file)) {
      errors.push(`${harnessRoot}: missing ${file}`);
      continue;
    }
    const source = await readFile(path.join(canonical, file), 'utf8');
    const copy = await readFile(path.join(target, file), 'utf8');
    if (source !== copy) {
      errors.push(`${harnessRoot}: drift in ${file}`);
    }
  }
}

if (errors.length) {
  console.error(errors.join('\n'));
  process.exit(1);
}

console.log('orchestrate-prometheus-application skill parity passed');
