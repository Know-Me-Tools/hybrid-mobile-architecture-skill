import {readFile} from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const siteRoot = path.resolve(import.meta.dirname, '..');
const css = await readFile(path.join(siteRoot, 'src', 'css', 'custom.css'), 'utf8');
const config = await readFile(path.join(siteRoot, 'docusaurus.config.mjs'), 'utf8');
const errors = [];

for (const required of [
  '--km-canvas',
  '--km-chrome',
  '--km-surface',
  '--km-raised',
  '--km-ember',
  "[data-theme='dark']",
  'border-color:transparent!important',
  'box-shadow:none!important',
  ':focus-visible',
  'outline:3px solid var(--km-ember)!important',
  'th,td{border:0!important}'
]) {
  if (!css.includes(required)) errors.push(`custom.css missing ${required}`);
}

for (const forbidden of [
  /box-shadow:(?!none)/,
  /border:\s*(?!0|none)[^;]+solid/,
  /linear-gradient\(/,
  /radial-gradient\(/
]) {
  if (forbidden.test(css)) {
    errors.push(`custom.css violates Flat 2.0 rule: ${forbidden}`);
  }
}

for (const required of [
  "title: 'KnowMe Builder'",
  "navbar:",
  "label: 'Prompting'",
  "img/knowme-builder-documentation-og.png",
  "colorMode: {defaultMode: 'dark'"
]) {
  if (!config.includes(required)) errors.push(`docusaurus.config.mjs missing ${required}`);
}

if (errors.length) {
  console.error(errors.join('\n'));
  process.exit(1);
}

console.log('KnowMe Flat 2.0 style contract passed');
