const { test, expect } = require('@playwright/test');

test.describe('site endpoints', () => {
  test('core pages return HTML successfully', async ({ request }) => {
    const paths = ['/', '/past/', '/news/', '/videos/', '/about/', '/subscribe/'];

    for (const path of paths) {
      const response = await request.get(path);

      expect(response.ok(), `${path} should return a successful response`).toBe(true);
      expect(response.headers()['content-type']).toContain('text/html');
    }
  });

  test('RSS feed returns XML with the site title', async ({ request }) => {
    const response = await request.get('/feed.xml');

    expect(response.ok()).toBe(true);
    expect(response.headers()['content-type']).toMatch(/(?:application|text)\/xml/);
    await expect(response.text()).resolves.toContain('<title>Software Testing Conferences</title>');
  });
});
