import { defineConfig } from "vite";
import { resolve } from "path";

export default defineConfig({
  build: {
    lib: {
      entry: resolve(__dirname, "dist/index.mjs"),
      name: "mhx",
      formats: ["es", "umd"],
      fileName: (format) => (format === "es" ? "mhx.esm.js" : "mhx.umd.js"),
    },
    outDir: "dist",
    emptyOutDir: false,
    minify: "esbuild",
    rollupOptions: {
      output: {
        name: "mhx",
      },
    },
  },
});
