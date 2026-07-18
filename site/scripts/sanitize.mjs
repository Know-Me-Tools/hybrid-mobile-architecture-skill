import {readdir, readFile, stat} from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const siteRoot = path.resolve(import.meta.dirname, '..');
const repoRoot = path.resolve(siteRoot, '..');
const scanRoots = [
  path.join(siteRoot, 'docs'),
  path.join(siteRoot, 'src'),
  path.join(siteRoot, 'static'),
  path.join(repoRoot, 'docs', 'prompting')
];

const forbidden = [
  {name: 'machine-local absolute path', pattern: /\/Users\/[A-Za-z0-9._-]+/},
  {name: 'raw prometheus wiki path', pattern: /\.prometheus\//},
  {name: 'private Karpathy wiki', pattern: /prometheus-wiki-private/i},
  {name: 'raw conversation/session log', pattern: /(codex_internal_context|in-app-browser-context|session log|raw conversation)/i},
  {name: 'private key', pattern: /BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY/},
  {name: 'inline credential', pattern: /(?:api[_-]?key|client[_-]?secret|password|token)\s*[:=]\s*["'][^"']+/i},
  {name: 'unsupported completion claim', pattern: /(?:guaranteed success|always works|never fails|fully autonomous without review)/i}
];

async function exists(filePath) {
  try {
    await stat(filePath);
    return true;
  } catch {
    return false;
  }
}

async function files(dir) {
  const out = [];
  for (const item of await readdir(dir, {withFileTypes: true})) {
    if (item.name === 'node_modules' || item.name === 'build' || item.name === '.docusaurus') continue;
    const itemPath = path.join(dir, item.name);
    if (item.isDirectory()) {
      out.push(...await files(itemPath));
    } else if (/\.(css|js|json|md|mdx|svg|toml|ya?ml)$/.test(item.name)) {
      out.push(itemPath);
    }
  }
  return out;
}

const violations = [];
for (const root of scanRoots) {
  if (!(await exists(root))) continue;
  for (const file of await files(root)) {
    const text = await readFile(file, 'utf8');
    const lines = text.split(/\r?\n/);
    for (const [index, line] of lines.entries()) {
      for (const rule of forbidden) {
        if (rule.pattern.test(line)) {
          violations.push(`${path.relative(repoRoot, file)}:${index + 1}: ${rule.name}`);
        }
      }
    }
  }
}

if (violations.length) {
  console.error(violations.join('\n'));
  process.exit(1);
}

console.log('public-content sanitization passed');
