#!/usr/bin/env node
import { access, readFile, readdir } from "node:fs/promises";
import { relative, resolve } from "node:path";

const root = resolve(new URL("..", import.meta.url).pathname);
const manifest = JSON.parse(await readFile(resolve(root, "builder.manifest.json"), "utf8"));
const evalLines = (await readFile(resolve(root, "evals/builder-skills.jsonl"), "utf8"))
  .trim()
  .split("\n")
  .map((line) => JSON.parse(line));
const failures = [];
const publicSkills = [manifest.distribution.packageSkill, ...manifest.skills];

async function exists(path) {
  try {
    await access(path);
    return true;
  } catch {
    return false;
  }
}

for (const skill of publicSkills) {
  const directory = resolve(root, manifest.distribution.skillSourceRoot, skill);
  const markdown = await readFile(resolve(directory, "SKILL.md"), "utf8");
  const match = markdown.match(/^---\n([\s\S]*?)\n---\n/);
  if (!match) {
    failures.push(`${skill}: missing frontmatter`);
    continue;
  }
  const keys = match[1]
    .split("\n")
    .filter((line) => /^[A-Za-z][A-Za-z0-9_-]*:/.test(line))
    .map((line) => line.slice(0, line.indexOf(":")));
  if (keys.join(",") !== "name,description") {
    failures.push(`${skill}: frontmatter must contain only name and description`);
  }
  const name = match[1].match(/^name:\s*(.+)$/m)?.[1]?.trim();
  const description = match[1].match(/^description:\s*(.+)$/m)?.[1]?.trim();
  if (name !== skill) failures.push(`${skill}: frontmatter name mismatch`);
  if (!description || description.length > 1024) {
    failures.push(`${skill}: description must be 1..1024 characters`);
  }
  const referencedPaths = new Set([
    ...[...markdown.matchAll(/\]\((?!https?:|#|mailto:)([^)]+)\)/g)].map(
      (match) => match[1].split("#", 1)[0],
    ),
    ...[...markdown.matchAll(/\breferences\/[A-Za-z0-9_.\/-]+\.(?:md|json|toml|ya?ml)\b/g)].map(
      (match) => match[0],
    ),
  ]);
  for (const referencedPath of referencedPaths) {
    const target = resolve(directory, referencedPath);
    const fromSkill = relative(directory, target);
    if (fromSkill.startsWith("..") || fromSkill.startsWith("/")) {
      failures.push(`${skill}: resource escapes skill directory: ${referencedPath}`);
    } else if (!(await exists(target))) {
      failures.push(`${skill}: missing referenced resource: ${referencedPath}`);
    }
  }
  const openai = resolve(directory, "agents/openai.yaml");
  try {
    const yaml = await readFile(openai, "utf8");
    if (!yaml.includes("display_name:") || !yaml.includes("short_description:")) {
      failures.push(`${skill}: incomplete agents/openai.yaml`);
    }
  } catch {
    failures.push(`${skill}: missing agents/openai.yaml`);
  }
  const cases = evalLines.filter(
    (entry) =>
      entry.id.startsWith(`${skill}-`) &&
      (entry.expectedSkills.includes(skill) || entry.kind === "negative-near-miss"),
  );
  const kinds = new Set(cases.map((entry) => entry.kind));
  for (const kind of ["positive-explicit", "positive-implicit", "negative-near-miss"]) {
    if (!kinds.has(kind)) failures.push(`${skill}: missing ${kind} evaluation`);
  }
}

const skillDirectories = (
  await readdir(resolve(root, manifest.distribution.skillSourceRoot), { withFileTypes: true })
)
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort();
const declared = [...publicSkills].sort();
if (JSON.stringify(skillDirectories) !== JSON.stringify(declared)) {
  failures.push("canonical skill directories differ from builder.manifest.json");
}

const internalNames = new Set();
for (const harness of [".agents", ".claude", ".codex", ".kimi", ".kimi-code", ".opencode"]) {
  const harnessRoot = resolve(root, harness, "skills");
  for (const entry of await readdir(harnessRoot, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    if (!entry.name.startsWith("openspec-") && !entry.name.startsWith("source-command-opsx-")) {
      continue;
    }
    internalNames.add(entry.name);
    const markdown = await readFile(resolve(harnessRoot, entry.name, "SKILL.md"), "utf8");
    if (!/^metadata:\n(?:  .+\n)*  internal: true$/m.test(markdown)) {
      failures.push(`${harness}/skills/${entry.name}: missing metadata.internal: true`);
    }
  }
}
if (internalNames.size !== 20) {
  failures.push(`expected 20 unique internal authoring skills, found ${internalNames.size}`);
}

for (const failure of failures) process.stderr.write(`error: ${failure}\n`);
if (failures.length) process.exit(1);
process.stdout.write(
  `Validated ${publicSkills.length} public Agent Skills and ${evalLines.length} evaluation cases.\n`,
);
