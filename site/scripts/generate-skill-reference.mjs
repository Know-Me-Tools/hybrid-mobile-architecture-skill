import {readFile, readdir, mkdir, writeFile} from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const checkOnly = process.argv.includes('--check');
const siteRoot = path.resolve(import.meta.dirname, '..');
const repoRoot = path.resolve(siteRoot, '..');
const skillRoot = path.join(repoRoot, 'skills');
const outputRoot = path.join(siteRoot, 'docs', 'reference', 'skills');
const manifest = JSON.parse(await readFile(path.join(repoRoot, 'builder.manifest.json'), 'utf8'));
const catalog = JSON.parse(
  await readFile(path.join(repoRoot, 'docs', 'catalog', 'skill-guidance.json'), 'utf8')
);

function parseSkill(text, skillName) {
  const match = text.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!match) throw new Error(`${skillName}: invalid Agent Skills frontmatter`);
  const name = match[1].match(/^name:\s*(.+)$/m)?.[1]?.trim();
  const description = match[1].match(/^description:\s*(.+)$/m)?.[1]?.trim();
  if (name !== skillName || !description) {
    throw new Error(`${skillName}: missing or mismatched name/description`);
  }
  return {description, body: match[2]};
}

function publicBody(body, skillName) {
  return body
    .replace(/<!--[\s\S]*?-->\n?/g, '')
    .replace(/^# .+\n+/m, '')
    .replace(/\[\[([a-z0-9-]+)\]\]/g, '[$1](./$1)')
    .replace(
      /\]\((?:\.\.\/)+references\/([^)]+)\)/g,
      `](https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill/blob/main/skills/${skillName}/references/$1)`
    )
    .replace(
      /\]\(references\/([^)]+)\)/g,
      `](https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill/blob/main/skills/${skillName}/references/$1)`
    )
    .replace(/<(?=\d)/g, '&lt;')
    .replace(/>(?=\d)/g, '&gt;')
    .trim();
}

function render(skillName, source, guidance, position) {
  const useCases = guidance.useCases.map((item) => `- ${item}`).join('\n');
  return `---
title: ${skillName}
sidebar_label: ${skillName}
sidebar_position: ${position}
description: ${JSON.stringify(source.description)}
---

# ${skillName}

**Category:** ${guidance.category}

## What it is for

${source.description}

## Why it is designed this way

${guidance.why}

## Common use cases

${useCases}

## How to invoke it

Use the explicit skill name when the gate is important or implicit activation
would be ambiguous:

\`\`\`text
/${skillName} <your task or question>
\`\`\`

Claude Code, Codex, OpenCode, and Kimi discover the same canonical
\`SKILL.md\`. Their activation adapters may recommend the skill, but the
adapter is advisory: Prometheus remains the lifecycle and mutation authority.

## Scope boundary

${guidance.notFor}

## Canonical operating contract

${publicBody(source.body, skillName)}

## Installation and verification

Install the complete bundle with \`knowme-builder skills install --path <project>\`
or the workstation installer described in [Installation](../installation).
Verify a project copy with:

\`\`\`bash
knowme-builder skills check --path <project>
\`\`\`

The canonical source is
\`skills/${skillName}/SKILL.md\`; generated scaffold and harness copies
must never be edited independently.
`;
}

const errors = [];
const generated = new Map();
const manifestSkills = new Set(manifest.skills);
for (const key of Object.keys(catalog.skills)) {
  if (!manifestSkills.has(key)) errors.push(`guidance exists for undeclared skill: ${key}`);
}

for (const [index, skillName] of manifest.skills.entries()) {
  const guidance = catalog.skills[skillName];
  if (!guidance) {
    errors.push(`missing guidance for declared skill: ${skillName}`);
    continue;
  }
  const sourcePath = path.join(skillRoot, skillName, 'SKILL.md');
  const source = parseSkill(await readFile(sourcePath, 'utf8'), skillName);
  generated.set(`${skillName}.md`, render(skillName, source, guidance, index + 1));
}

if (errors.length) {
  console.error(errors.join('\n'));
  process.exit(1);
}

await mkdir(outputRoot, {recursive: true});
if (checkOnly) {
  const existing = new Set((await readdir(outputRoot)).filter((name) => name.endsWith('.md')));
  for (const [name, expected] of generated) {
    existing.delete(name);
    let actual = '';
    try {
      actual = await readFile(path.join(outputRoot, name), 'utf8');
    } catch {
      errors.push(`missing generated skill page: ${name}`);
      continue;
    }
    if (actual !== expected) errors.push(`generated skill page is stale: ${name}`);
  }
  for (const unexpected of existing) errors.push(`unexpected generated skill page: ${unexpected}`);
} else {
  for (const [name, content] of generated) {
    await writeFile(path.join(outputRoot, name), content);
  }
}

if (errors.length) {
  console.error(errors.join('\n'));
  process.exit(1);
}

console.log(`${checkOnly ? 'checked' : 'generated'} ${generated.size} skill reference pages`);
