const { test, expect } = require("@playwright/test");

test("readers can browse from Upcoming to Past conferences", async ({
  page,
  baseURL,
}) => {
  // Keep the journey independent of analytics, fonts, and organizer websites.
  await page.route("**/*", (route) =>
    route.request().url().startsWith(`${baseURL}/`)
      ? route.continue()
      : route.abort(),
  );

  await page.goto("/");
  await expect(
    page.locator(".post-list").getByRole("link").first(),
  ).toBeVisible();

  await page.getByRole("link", { name: "Past", exact: true }).click();
  await expect(page).toHaveURL(/\/past\/$/);
  await expect(page).toHaveTitle("Past Software Testing Conferences");
  await expect(
    page.locator(".post-list").getByRole("link").first(),
  ).toBeVisible();
});
