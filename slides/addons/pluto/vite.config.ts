import { defineConfig } from "vite"
import { vendor } from "./vendor.plugin"

export default defineConfig({
  plugins: [vendor()],
})
