import { defineConfig } from "vite"
import { vendor } from "./vendor.plugin"

export default defineConfig({
  plugins: [vendor()],
  server: {
    // PlutoDeck.jl answers /api/session and /api/deck. The browser still talks to Pluto directly
    // on Pluto's own port, carrying the secret `/api/session` hands it.
    proxy: { "/api": process.env.PLUTODECK_URL ?? "http://127.0.0.1:8099" },
  },
})
