import { defineConfig } from "vite"

export default defineConfig({
  // Vite 8's lightningcss minifier rejects Slidev 53's own theme CSS and fails the build.
  build: { cssMinify: false },
  slidev: {
    markdown: {
      // Slidev renders every Markdown link starting with `.` as a route inside the deck. A link
      // climbing out of the deck's folder points at a page beside it — another deck, the
      // hands-on guide — so it stays a plain link.
      markdownSetup(md) {
        const slidevLinkOpen = md.renderer.rules.link_open!
        md.renderer.rules.link_open = (tokens, idx, options, env, self) =>
          tokens[idx].attrGet("href")?.startsWith("../")
            ? self.renderToken(tokens, idx, options)
            : slidevLinkOpen(tokens, idx, options, env, self)
      },
    },
  },
})
