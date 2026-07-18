import {chromium} from 'playwright';
import AxeBuilder from '@axe-core/playwright';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {createServer} from 'node:http';
import {readFile, stat} from 'node:fs/promises';

const baseUrl = process.env.PUBLICATION_BASE_URL ?? 'http://127.0.0.1:4174/hybrid-mobile-architecture-skill/';
const routes = [
  '',
  'prompting/playbook',
  'prompting/harnesses/codex',
  'prompting/loops/feynman-loop',
  'prompting/scenarios/full-knowme-hybrid',
  'prompting/model-routing',
  'prompting/agent-orchestration'
];

const viewports = [
  {name: 'desktop-dark', width: 1440, height: 1000, colorScheme: 'dark'},
  {name: 'mobile-light', width: 390, height: 844, colorScheme: 'light'}
];

const errors = [];
let server;
const siteRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const buildRoot = path.join(siteRoot, 'build');

function urlFor(route) {
  return new URL(route, baseUrl).toString();
}

async function openRoute(page, route, label, {requireNav = true} = {}) {
  console.log(`checking ${label}`);
  const response = await page.goto(urlFor(route), {waitUntil: 'domcontentloaded', timeout: 15_000});
  if (!response?.ok()) {
    errors.push(`${label}: route ${route || '/'} returned ${response?.status() ?? 'no response'}`);
  }
  if (requireNav) {
    await page.waitForSelector('nav', {state: 'visible', timeout: 5_000});
  }
}

async function waitForServer() {
  const deadline = Date.now() + 60_000;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(baseUrl);
      if (response.ok) return;
    } catch {
      // Server is still starting.
    }
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
  throw new Error(`Timed out waiting for ${baseUrl}`);
}

async function resolveBuildPath(requestUrl) {
  const parsed = new URL(requestUrl, baseUrl);
  const basePath = new URL(baseUrl).pathname.replace(/\/$/, '');
  let pathname = decodeURIComponent(parsed.pathname);
  if (basePath && pathname.startsWith(basePath)) {
    pathname = pathname.slice(basePath.length) || '/';
  }
  let candidate = path.join(buildRoot, pathname);
  const relative = path.relative(buildRoot, candidate);
  if (relative.startsWith('..') || path.isAbsolute(relative)) {
    return null;
  }
  try {
    const candidateStat = await stat(candidate);
    if (candidateStat.isDirectory()) {
      candidate = path.join(candidate, 'index.html');
    }
  } catch {
    try {
      await stat(`${candidate}.html`);
      candidate = `${candidate}.html`;
    } catch {
      candidate = path.join(candidate, 'index.html');
    }
  }
  return candidate;
}

function contentType(filePath) {
  if (filePath.endsWith('.html')) return 'text/html; charset=utf-8';
  if (filePath.endsWith('.js')) return 'text/javascript; charset=utf-8';
  if (filePath.endsWith('.css')) return 'text/css; charset=utf-8';
  if (filePath.endsWith('.json')) return 'application/json; charset=utf-8';
  if (filePath.endsWith('.svg')) return 'image/svg+xml';
  if (filePath.endsWith('.png')) return 'image/png';
  if (filePath.endsWith('.webp')) return 'image/webp';
  return 'application/octet-stream';
}

async function startStaticServer() {
  const httpServer = createServer(async (request, response) => {
    const filePath = await resolveBuildPath(request.url ?? '/');
    if (!filePath) {
      response.writeHead(403);
      response.end('forbidden');
      return;
    }
    try {
      const body = await readFile(filePath);
      response.writeHead(200, {'content-type': contentType(filePath)});
      response.end(body);
    } catch {
      response.writeHead(404);
      response.end('not found');
    }
  });
  await new Promise((resolve) => httpServer.listen(4174, '127.0.0.1', resolve));
  return httpServer;
}

async function assertBody(page, label, matcher, message) {
  const body = (await page.locator('body').textContent({timeout: 5_000})) ?? '';
  if (typeof matcher === 'string' ? !body.includes(matcher) : !matcher.test(body)) {
    errors.push(`${label}: ${message}`);
  }
}

async function assertBodyExcludes(page, label, value) {
  const body = (await page.locator('body').textContent({timeout: 5_000})) ?? '';
  if (body.includes(value)) {
    errors.push(`${label}: unexpected text ${value}`);
  }
}

async function assertStaticRoute(route, viewportName) {
  const label = `${viewportName} static ${route || '/'}`;
  console.log(`checking ${label}`);
  const response = await fetch(urlFor(route));
  if (!response.ok) {
    errors.push(`${label}: route returned ${response.status}`);
    return;
  }
  const html = await response.text();
  if (!html.includes('KnowMe')) {
    errors.push(`${label}: missing KnowMe branding`);
  }
  for (const forbidden of ['Welcome to Docusaurus', 'Docusaurus Tutorial', 'Docusaurus logo', 'prometheus-wiki-private', 'codex_internal_context']) {
    if (html.includes(forbidden)) {
      errors.push(`${label}: unexpected ${forbidden}`);
    }
  }
}

if (!process.env.PUBLICATION_BASE_URL) {
  server = await startStaticServer();
  await waitForServer();
}

const launchOptions = process.env.CI ? {} : {channel: process.env.PLAYWRIGHT_BROWSER_CHANNEL ?? 'chrome'};
const browser = await chromium.launch(launchOptions);

try {
  for (const viewport of viewports) {
    const context = await browser.newContext({
      colorScheme: viewport.colorScheme,
      viewport: {width: viewport.width, height: viewport.height},
      isMobile: viewport.name.startsWith('mobile'),
      hasTouch: viewport.name.startsWith('mobile')
    });
    const page = await context.newPage();
    page.setDefaultTimeout(5_000);

    for (const route of routes) {
      await assertStaticRoute(route, viewport.name);
    }

    await openRoute(page, '', `${viewport.name} home browser`);
    await assertBody(page, `${viewport.name} home browser`, 'KnowMe', 'missing KnowMe branding');

    const search = page.getByPlaceholder(/search/i).first();
    await search.click();
    await page.keyboard.type('scenario-full-knowme-hybrid');
    const searchValue = await search.inputValue();
    if (!searchValue.includes('scenario-full-knowme-hybrid')) {
      errors.push(`${viewport.name} search: search input did not retain typed query`);
    }
    await page.keyboard.press('Escape');

    await openRoute(page, 'prompting/scenarios/full-knowme-hybrid', `${viewport.name} prompt copy`, {requireNav: false});
    const codeText = (await page.locator('pre').allTextContents()).join('\n');
    if (!codeText.includes('/kbd-assess')) {
      errors.push(`${viewport.name} prompt copy: first prompt block missing /kbd-assess`);
    }

    await openRoute(page, 'prompting/agent-orchestration', `${viewport.name} mermaid`, {requireNav: false});
    if ((await page.locator('.mermaid, svg').count()) < 1) {
      errors.push(`${viewport.name} mermaid: missing Mermaid/SVG rendering`);
    }
    const boxShadow = await page.locator('body').evaluate((body) => getComputedStyle(body).boxShadow);
    if (boxShadow !== 'none') {
      errors.push(`${viewport.name} flat 2.0: body box-shadow is ${boxShadow}`);
    }

    await openRoute(page, 'prompting/playbook', `${viewport.name} accessibility`, {requireNav: false});
    await page.keyboard.press('Tab');
    const focused = await page.evaluate(() => document.activeElement?.tagName ?? '');
    if (!focused) {
      errors.push(`${viewport.name} accessibility: keyboard focus did not move`);
    }
    const axe = await new AxeBuilder({page})
      .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
      .analyze();
    const serious = axe.violations.filter((violation) => ['serious', 'critical'].includes(violation.impact ?? ''));
    if (serious.length) {
      errors.push(`${viewport.name} accessibility: serious/critical axe violations ${JSON.stringify(serious, null, 2)}`);
    }

    await context.close();
  }
} finally {
  await browser.close();
  if (server) {
    server.close();
  }
}

if (errors.length) {
  console.error(errors.join('\n\n'));
  process.exit(1);
}

console.log(`browser publication gate passed (${viewports.length} viewports, ${routes.length} routes)`);
