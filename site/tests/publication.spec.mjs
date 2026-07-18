import {expect, test} from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

const routes = [
  '',
  'prompting/playbook',
  'prompting/harnesses/codex',
  'prompting/loops/feynman-loop',
  'prompting/scenarios/full-knowme-hybrid',
  'prompting/model-routing',
  'prompting/agent-orchestration'
];

test.describe('KnowMe documentation publication gates', () => {
  async function openRoute(page, route) {
    const response = await page.goto(route, {waitUntil: 'domcontentloaded'});
    expect(response?.ok()).toBeTruthy();
    await page.locator('nav').waitFor({state: 'visible'});
  }

  for (const route of routes) {
    test(`route renders without private/default content: ${route}`, async ({page}) => {
      await openRoute(page, route);
      await expect(page.locator('body')).toContainText('KnowMe');
      await expect(page.locator('body')).not.toContainText('Welcome to Docusaurus');
      await expect(page.locator('body')).not.toContainText('Docusaurus Tutorial');
      await expect(page.locator('body')).not.toContainText('Docusaurus logo');
      await expect(page.locator('body')).not.toContainText('prometheus-wiki-private');
      await expect(page.locator('body')).not.toContainText('codex_internal_context');
      await expect(page.locator('nav')).toBeVisible();
      await expect(page.getByRole('link', {name: /Prompting/}).first()).toBeVisible();
    });
  }

  test('search opens and finds scenario content', async ({page}) => {
    await openRoute(page, '');
    const search = page.getByRole('button', {name: /search/i}).or(page.getByPlaceholder(/search/i));
    await search.first().click();
    await page.keyboard.type('scenario-full-knowme-hybrid');
    await expect(page.locator('body')).toContainText(/Full KnowMe hybrid|scenario-full-knowme-hybrid/);
  });

  test('prompt code blocks expose copy controls or selectable text', async ({page}) => {
    await openRoute(page, 'prompting/scenarios/full-knowme-hybrid');
    const codeBlock = page.locator('pre').first();
    await expect(codeBlock).toBeVisible();
    await expect(codeBlock).toContainText('/kbd-assess');
    const copyButtons = page.getByRole('button', {name: /copy/i});
    await expect(copyButtons.first()).toBeVisible();
  });

  test('Mermaid and Flat 2.0 visual contract are observable', async ({page}) => {
    await openRoute(page, 'prompting/agent-orchestration');
    await expect(page.locator('.mermaid, svg').first()).toBeVisible();
    const body = page.locator('body');
    await expect(body).toHaveCSS('box-shadow', 'none');
    const card = page.locator('article').first();
    await expect(card).toBeVisible();
  });

  test('keyboard focus and axe accessibility gate', async ({page}) => {
    await openRoute(page, 'prompting/playbook');
    await page.keyboard.press('Tab');
    const focused = await page.evaluate(() => document.activeElement?.tagName);
    expect(focused).toBeTruthy();
    const results = await new AxeBuilder({page})
      .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
      .analyze();
    const serious = results.violations.filter((violation) => ['serious', 'critical'].includes(violation.impact ?? ''));
    expect(serious, JSON.stringify(serious, null, 2)).toEqual([]);
  });
});
