const { test, expect } = require('@playwright/test');

test.describe('site smoke checks', () => {
  test('API: key pages return success responses', async ({ request, baseURL }) => {
    for (const path of ['/', '/past/', '/subscribe/']) {
      const response = await request.get(`${baseURL}${path}`);
      expect(response.ok(), `${path} should return success`).toBeTruthy();
    }
  });

  test('UI: homepage renders nav links', async ({ page }) => {
    await page.goto('/');

    await expect(page).toHaveTitle(/Software Testing Conferences/);
    await expect(page.getByRole('link', { name: 'Upcoming' })).toBeVisible();
    await expect(page.getByRole('link', { name: 'Past' })).toBeVisible();
    await expect(page.getByRole('link', { name: 'Newsletter', exact: true })).toBeVisible();
  });

  test('UI: past page lists conferences', async ({ page }) => {
    await page.goto('/past/');

    await expect(page).toHaveURL(/\/past\/$/);
    await expect(page.locator('ul.post-list li').first()).toBeVisible();
  });
});
