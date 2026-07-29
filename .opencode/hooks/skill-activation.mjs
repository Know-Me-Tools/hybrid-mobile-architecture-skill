#!/usr/bin/env node

import { readFile } from "node:fs/promises";
import { resolve } from "node:path";

let payload = "";
for await (const chunk of process.stdin) payload += chunk;
let input;
try {
  input = JSON.parse(payload);
} catch {
  process.exit(0);
}
const manifestPath =
  process.env.KNOWME_BUILDER_ACTIVATION_MANIFEST ??
  resolve(".knowme-builder/activation-manifest.json");
let manifest;
try {
  manifest = JSON.parse(await readFile(manifestPath, "utf8"));
} catch {
  process.exit(0);
}
const prompt = String(input.prompt ?? input.message ?? "").toLowerCase();
const skills = manifest.skills
  .filter((skill) =>
    skill.terms.some((term) => prompt.includes(String(term).toLowerCase())),
  )
  .map((skill) => skill.name);
if (skills.length > 0) {
  process.stdout.write(
    JSON.stringify({
      additionalContext:
        "Relevant KnowMe Builder skills (advisory): " + skills.join(", "),
    }),
  );
}
