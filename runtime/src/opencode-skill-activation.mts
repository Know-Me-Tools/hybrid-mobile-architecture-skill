// TJ-ARCH-MOB-001 compliant
import { readFileSync, fstatSync } from 'node:fs';
import { resolve } from 'node:path';
try {
  const input = fstatSync(0);
  if (input.isFile() || input.isFIFO() || input.isSocket()) {
    const payload = JSON.parse(readFileSync(0, 'utf8')) as { prompt?: unknown; message?: unknown };
    const manifest = JSON.parse(readFileSync(process.env.KNOWME_BUILDER_ACTIVATION_MANIFEST ?? resolve('.knowme-builder/activation-manifest.json'), 'utf8')) as { skills?: { name: string; terms: string[] }[] };
    const prompt = String(payload.prompt ?? payload.message ?? '').toLowerCase();
    const skills = (manifest.skills ?? []).filter(skill => typeof skill?.name === 'string' && Array.isArray(skill.terms) && skill.terms.some(term => typeof term === 'string' && prompt.includes(term.toLowerCase()))).map(skill => skill.name);
    if (skills.length) process.stdout.write(`${JSON.stringify({ additionalContext: 'Relevant KnowMe Builder skills (advisory): ' + skills.join(', ') })}\n`);
  }
} catch { /* Advisory activation is silent for unavailable input or metadata. */ }
