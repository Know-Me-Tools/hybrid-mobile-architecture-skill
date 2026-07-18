import {defineConfig, devices} from '@playwright/test';

const port = Number(process.env.PLAYWRIGHT_PORT || 4174);

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  expect: {timeout: 10_000},
  fullyParallel: false,
  workers: 1,
  reporter: [['list'], ['html', {open: 'never', outputFolder: 'playwright-report'}]],
  use: {
    baseURL: `http://127.0.0.1:${port}/hybrid-mobile-architecture-skill/`,
    channel: 'chrome',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure'
  },
  webServer: {
    command: `npm run serve -- --host 127.0.0.1 --port ${port} --no-open`,
    url: `http://127.0.0.1:${port}/hybrid-mobile-architecture-skill/`,
    reuseExistingServer: !process.env.CI,
    timeout: 60_000
  },
  projects: [
    {
      name: 'desktop-dark',
      use: {...devices['Desktop Chrome'], colorScheme: 'dark', viewport: {width: 1440, height: 1000}}
    },
    {
      name: 'mobile-light',
      use: {...devices['Desktop Chrome'], colorScheme: 'light', viewport: {width: 390, height: 844}, isMobile: true, hasTouch: true}
    }
  ]
});
