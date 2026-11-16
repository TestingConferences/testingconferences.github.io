const path = require("node:path");
const { defineConfig } = require("@playwright/test");

const baseURL = "http://127.0.0.1:4173";

module.exports = defineConfig({
  testDir: ".",
  use: {
    baseURL,
    browserName: "chromium",
  },
  webServer: {
    command:
      "bundle exec ruby -run -e httpd -- --bind-address=127.0.0.1 --port=4173 _site",
    cwd: path.resolve(__dirname, "../.."),
    url: baseURL,
    timeout: 15_000,
  },
});
