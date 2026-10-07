import { fileURLToPath } from "node:url"
import { defineConfig } from "vite"

const PLUTODECK_SRC = fileURLToPath(new URL("../PlutoDeck.jl/frontend/src", import.meta.url))

export default defineConfig({
  resolve: {
    alias: { "@plutodeck": PLUTODECK_SRC },
  },
  // Slidev 53's own theme CSS trips Vite 8's lightningcss minifier and fails the build.
  build: { cssMinify: false },
  server: {
    fs: { allow: [".."] },
    // PlutoDeck's own server answers /api/session and /api/deck; the browser still talks to
    // Pluto directly on Pluto's port, exactly as in PlutoDeck.
    proxy: { "/api": "http://127.0.0.1:8099" },
  },
})
