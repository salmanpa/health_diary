import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { viteSingleFile } from "vite-plugin-singlefile";

export default defineConfig({
  root: "dashboard-src",
  base: "./",
  plugins: [react(), viteSingleFile()],
  build: {
    outDir: "../dashboard",
    emptyOutDir: true,
    target: "es2022",
    cssCodeSplit: false,
  },
  server: {
    host: "127.0.0.1",
    port: 4174,
    strictPort: true,
  },
  preview: {
    host: "127.0.0.1",
    port: 4175,
    strictPort: true,
  },
});
