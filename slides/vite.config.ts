import { defineConfig } from "vite"

// Slidev looks for a Vite config beside each deck's slides.md; every deck re-exports this one.
export default defineConfig({
  // Vite 8's lightningcss minifier rejects Slidev 53's own theme CSS and fails the build.
  build: { cssMinify: false },
})
