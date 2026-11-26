import assert from "node:assert/strict";
import test from "node:test";
import { browser } from "vibium";

const baseURL = "http://127.0.0.1:4174";
const findOptions = { timeout: 5_000 };

test(
  "readers can browse from Upcoming to Past conferences",
  { timeout: 30_000 },
  async (t) => {
    const session = await browser.start({ engine: "chrome", headless: true });
    t.after(() => session.stop());
    const page = await session.page();

    // Keep the journey independent of analytics, fonts, and organizer websites.
    await page.route("**/*", (route) =>
      route.request.url().startsWith(`${baseURL}/`)
        ? route.continue()
        : route.abort(),
    );

    await page.go(`${baseURL}/`);
    const firstListing = { css: ".post-list h2 a" };
    const upcoming = await page.find(firstListing, findOptions);
    assert.ok(
      await upcoming.isVisible(),
      "An upcoming conference link should be visible",
    );

    const navigation = await page.findAll({ css: ".main-nav a" }, findOptions);
    const past = navigation.find((link) => /^past$/i.test(link.info.text.trim()));
    assert.ok(past, "The main Past link should be present");
    await past.click({ timeout: 5_000 });
    await page.waitForURL(`${baseURL}/past/`, findOptions);
    assert.equal(await page.title(), "Past Software Testing Conferences");

    const archived = await page.find(firstListing, findOptions);
    assert.ok(
      await archived.isVisible(),
      "An archived conference link should be visible",
    );
  },
);
