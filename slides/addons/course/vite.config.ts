import { defineConfig, type Plugin } from "vite"

// Slidev syncs presenter state (drawings, nav) through POSTs to `/@server-reactive/<key>`, and
// the server stores `payload.data` whenever a payload has no `patch`. After a hot reload a tab
// can post an empty diff, serialized as the `__UNDEFINED___` marker, which sets the state to
// `undefined`; every page load then throws in `define(undefined, …)` and the deck stays white
// until the server restarts. Such a payload carries nothing to apply, so it is dropped here.
function dropEmptyServerStatePosts(): Plugin {
  const UNDEFINED = "__UNDEFINED___"
  return {
    name: "course:drop-empty-server-state-posts",
    enforce: "pre",
    configureServer(server) {
      server.middlewares.use((req, res, next) => {
        if (req.method !== "POST" || !req.url?.startsWith("/@server-reactive/")) return next()
        let body = ""
        req.on("data", (chunk) => (body += chunk))
        req.on("end", () => {
          let payload: { patch?: unknown; data?: unknown } | undefined
          try {
            payload = JSON.parse(body, (_, value) => (value === UNDEFINED ? undefined : value))
          } catch {
            payload = undefined
          }
          if (payload && payload.patch === undefined && payload.data === undefined) {
            res.statusCode = 204
            res.end()
            return
          }
          // The server-ref middleware reads the body through `req.on`, and the stream is spent.
          req.on = ((event: string, listener: (chunk?: string) => void) => {
            if (event === "data") listener(body)
            else if (event === "end") listener()
            return req
          }) as typeof req.on
          next()
        })
      })
    },
  }
}

export default defineConfig({
  plugins: [dropEmptyServerStatePosts()],
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
