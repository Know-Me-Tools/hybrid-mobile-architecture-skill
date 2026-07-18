import {createServer} from 'node:http';
import {createReadStream} from 'node:fs';
import {readFile, stat} from 'node:fs/promises';
import path from 'node:path';
import {spawn} from 'node:child_process';
import process from 'node:process';

const mode = process.argv[2] || 'internal';
const siteRoot = path.resolve(import.meta.dirname, '..');
const buildRoot = path.join(siteRoot, 'build');
const port = Number(process.env.LINK_CHECK_PORT || 4173);
const host = '127.0.0.1';
const basePath = process.env.BASE_URL || '/hybrid-mobile-architecture-skill/';

function contentType(filePath) {
  if (filePath.endsWith('.html')) return 'text/html; charset=utf-8';
  if (filePath.endsWith('.css')) return 'text/css; charset=utf-8';
  if (filePath.endsWith('.js')) return 'application/javascript; charset=utf-8';
  if (filePath.endsWith('.json')) return 'application/json; charset=utf-8';
  if (filePath.endsWith('.xml')) return 'application/xml; charset=utf-8';
  if (filePath.endsWith('.svg')) return 'image/svg+xml';
  if (filePath.endsWith('.png')) return 'image/png';
  return 'application/octet-stream';
}

async function resolveFile(urlPath) {
  let decoded = decodeURIComponent(urlPath.split('?')[0]);
  if (basePath !== '/' && decoded.startsWith(basePath)) {
    decoded = `/${decoded.slice(basePath.length)}`;
  }
  const safe = path.normalize(decoded).replace(/^(\.\.[/\\])+/, '');
  const relative = safe === '/' ? 'index.html' : safe.replace(/^\//, '');
  const candidates = [
    path.join(buildRoot, relative),
    path.join(buildRoot, `${relative}.html`),
    path.join(buildRoot, relative, 'index.html')
  ];
  for (const candidate of candidates) {
    try {
      const info = await stat(candidate);
      if (info.isFile() && candidate.startsWith(buildRoot)) return candidate;
    } catch {
      // try next candidate
    }
  }
  return null;
}

const server = createServer(async (req, res) => {
  const filePath = await resolveFile(req.url || '/');
  if (!filePath) {
    res.writeHead(404);
    res.end('not found');
    return;
  }
  res.writeHead(200, {
    'content-type': contentType(filePath),
    'cache-control': filePath.includes('/assets/') || filePath.includes('/img/')
      ? 'public, max-age=31536000, immutable'
      : 'public, max-age=300'
  });
  createReadStream(filePath).pipe(res);
});

await new Promise((resolve) => server.listen(port, host, resolve));

const url = `http://${host}:${port}/`;
const args = [
  'linkinator',
  url,
  '--recurse',
  '--format',
  'text',
  '--timeout',
  '10000',
  '--retry',
  '--retry-errors',
  '--retry-errors-count',
  '1'
];

if (mode === 'internal') {
  args.push('--skip', '^(?!http://127\\.0\\.0\\.1:4173/)');
} else if (mode === 'external') {
  const allowlist = JSON.parse(await readFile(path.join(siteRoot, 'linkinator.allowlist.json'), 'utf8'));
  for (const skipped of allowlist.externalAllowlist) {
    args.push('--skip', skipped);
  }
} else {
  console.error(`unknown link check mode: ${mode}`);
  server.close();
  process.exit(1);
}

const child = spawn('npx', args, {stdio: 'inherit', shell: false, cwd: siteRoot});
child.on('exit', (code) => {
  server.close(() => process.exit(code ?? 1));
});
