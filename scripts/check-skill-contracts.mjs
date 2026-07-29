#!/usr/bin/env node
import { readFile, readdir } from "node:fs/promises";
import { resolve } from "node:path";

const root = resolve(new URL("..", import.meta.url).pathname);
const manifest = JSON.parse(await readFile(resolve(root, "builder.manifest.json"), "utf8"));
const evalLines = (await readFile(resolve(root, "evals/builder-skills.jsonl"), "utf8"))
  .trim()
  .split("\n")
  .map((line) => JSON.parse(line));
const failures = [];

for (const skill of manifest.skills) {
  const directory = resolve(root, "templates/project-skills", skill);
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
  await readdir(resolve(root, "templates/project-skills"), { withFileTypes: true })
)
  .filter((entry) => entry.isDirectory() && entry.name !== "hooks")
  .map((entry) => entry.name)
  .sort();
const declared = [...manifest.skills].sort();
if (JSON.stringify(skillDirectories) !== JSON.stringify(declared)) {
  failures.push("canonical skill directories differ from builder.manifest.json");
}

for (const failure of failures) process.stderr.write(`error: ${failure}\n`);
if (failures.length) process.exit(1);
process.stdout.write(
  `Validated ${manifest.skills.length} Agent Skills and ${evalLines.length} evaluation cases.\n`,
);
