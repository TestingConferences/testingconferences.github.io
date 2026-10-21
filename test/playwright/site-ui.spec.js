const { test, expect } = require('@playwright/test');

test.describe('visitor experience', () => {
  test('upcoming conferences show their essential details', async ({ page }) => {
    await page.goto('/');

    await expect(page).toHaveTitle('Software Testing Conferences');

    const conferences = page.locator('.post-list > li');
    expect(await conferences.count()).toBeGreaterThan(0);

    const firstConference = conferences.first();
    await expect(firstConference.getByRole('heading').getByRole('link')).toBeVisible();
    await expect(firstConference.getByRole('img', { name: 'Dates' })).toBeVisible();
    await expect(firstConference.getByRole('img', { name: 'Location' })).toBeVisible();
  });

  test('primary navigation opens the archive and marks it active', async ({ page }) => {
    await page.goto('/');

    await expect(page.getByRole('link', { name: 'Upcoming', exact: true })).toHaveClass(/active/);
    await page.getByRole('link', { name: 'Past', exact: true }).click();

    await expect(page).toHaveURL(/\/past\/$/);
    await expect(page).toHaveTitle('Past Software Testing Conferences');
    await expect(page.getByRole('link', { name: 'Past', exact: true })).toHaveClass(/active/);
  });
});
