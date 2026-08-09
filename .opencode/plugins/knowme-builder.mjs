import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const pluginDirectory = dirname(fileURLToPath(import.meta.url));

async function readActivationManifest(directory) {
  const configured = process.env.KNOWME_BUILDER_ACTIVATION_MANIFEST;
  const configRoot = process.env.XDG_CONFIG_HOME ?? join(homedir(), ".config");
  const candidates = [
    configured,
    join(directory, ".knowme-builder", "activation-manifest.json"),
    resolve(pluginDirectory, "../../templates/activation-manifest.json"),
    join(configRoot, "opencode", "knowme-builder", "activation-manifest.json"),
  ].filter(Boolean);
  for (const candidate of candidates) {
    try {
      return JSON.parse(await readFile(candidate, "utf8"));
    } catch {
      // Advisory activation must remain silent when a candidate is unavailable.
    }
  }
  return null;
}

function promptText(parts) {
  return parts
    .filter((part) => part?.type === "text" && typeof part.text === "string")
    .map((part) => part.text)
    .join("\n")
    .toLocaleLowerCase();
}

function matchingSkills(prompt, manifest) {
  if (!prompt || !Array.isArray(manifest?.skills)) return [];
  return manifest.skills
    .filter(
      (skill) =>
        typeof skill?.name === "string" &&
        Array.isArray(skill.terms) &&
        skill.terms.some(
          (term) => typeof term === "string" && prompt.includes(term.toLocaleLowerCase()),
        ),
    )
    .map((skill) => skill.name)
    .slice(0, 8);
}

export const KnowMeBuilderPlugin = async ({ directory }) => {
  const manifest = await readActivationManifest(directory);
  const sessionHints = new Map();
  return {
    "chat.message": async (input, output) => {
      const matches = matchingSkills(promptText(output.parts ?? []), manifest);
      if (matches.length > 0) sessionHints.set(input.sessionID, matches);
      else sessionHints.delete(input.sessionID);
    },
    "experimental.chat.system.transform": async (input, output) => {
      const matches = input.sessionID ? sessionHints.get(input.sessionID) : null;
      if (!matches?.length) return;
      output.system.push(
        `Relevant KnowMe Builder skills (advisory; load only when applicable): ${matches.join(", ")}. ` +
          "Prometheus remains the development lifecycle and KBD authority.",
      );
    },
    event: async ({ event }) => {
      if (event?.type === "session.deleted" && event.properties?.info?.id) {
        sessionHints.delete(event.properties.info.id);
      }
    },
  };
};
