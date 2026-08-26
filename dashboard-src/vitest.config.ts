import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "jsdom",
    include: ["dashboard-src/src/**/*.test.{ts,tsx}"],
    setupFiles: ["dashboard-src/src/test-setup.ts"],
  },
});
