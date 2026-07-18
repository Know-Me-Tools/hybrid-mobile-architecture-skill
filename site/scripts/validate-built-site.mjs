import {readFile, stat} from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const siteRoot = path.resolve(import.meta.dirname, '..');
const buildRoot = path.join(siteRoot, 'build');
const {routes, recipeIds} = JSON.parse(await readFile(path.join(siteRoot, 'required-routes.json'), 'utf8'));
const errors = [];

async function exists(filePath) {
  try {
    await stat(filePath);
    return true;
  } catch {
    return false;
  }
}

function routeToHtml(route) {
  if (route === '/') return path.join(buildRoot, 'index.html');
  return path.join(buildRoot, `${route.replace(/^\//, '')}.html`);
}

for (const route of routes) {
  const filePath = routeToHtml(route);
  if (!(await exists(filePath))) {
    errors.push(`missing built route ${route} -> ${path.relative(siteRoot, filePath)}`);
  }
}

const sitemap = await readFile(path.join(buildRoot, 'sitemap.xml'), 'utf8');
for (const route of routes) {
  if (!sitemap.includes(route)) {
    errors.push(`sitemap missing ${route}`);
  }
}

const index = await readFile(path.join(buildRoot, 'index.html'), 'utf8');
for (const required of [
  'KnowMe Builder',
  'og:image',
  'knowme-builder-documentation-og.png',
  'twitter:image',
  'Build software that understands its users'
]) {
  if (!index.includes(required)) errors.push(`index metadata/body missing ${required}`);
}

const search = await readFile(path.join(buildRoot, 'search-index.json'), 'utf8');
for (const recipeId of recipeIds) {
  if (!search.includes(recipeId)) {
    errors.push(`search index missing recipe id ${recipeId}`);
  }
}
for (const term of ['Codex playbook', 'Feynman learning loop', 'Agent orchestration']) {
  if (!search.includes(term)) {
    errors.push(`search index missing ${term}`);
  }
}

const cssDir = path.join(buildRoot, 'assets', 'css');
if (!(await exists(cssDir))) errors.push('missing built css directory');

if (errors.length) {
  console.error(errors.join('\n'));
  process.exit(1);
}

console.log('built site route/search/social assertions passed');
