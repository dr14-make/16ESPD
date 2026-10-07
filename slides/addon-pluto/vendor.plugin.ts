// Serves the libraries a live card loads from the deck itself, so that a lecture hall's network
// is never on the path to a plot or an equation: under `pluto/` beside the page in `slidev dev`,
// and as files at the same path in a build. `index.html` names them there.
//
// MathJax and Plotly are classic scripts assigning a global, so they are passed through as they
// are. lodash and interact.js are what a plot cell imports by absolute CDN URL, so each is
// bundled into one module, which the import map in `index.html` puts in place of that URL.

import { readFile } from "node:fs/promises"
import { createRequire } from "node:module"
import { fileURLToPath } from "node:url"
import { build } from "rolldown"
import type { Plugin } from "vite"

const require = createRequire(fileURLToPath(import.meta.url))

const DIRECTORY = "pluto"

async function bundle(entry: string): Promise<string> {
  const { output } = await build({
    input: fileURLToPath(new URL(`./src/${entry}`, import.meta.url)),
    output: { format: "esm", minify: true },
    write: false,
    logLevel: "warn",
  })
  return output[0].code
}

const FILES: Readonly<Record<string, () => Promise<string | Uint8Array>>> = {
  "tex-svg-full.js": () => readFile(require.resolve("mathjax/es5/tex-svg-full.js")),
  "plotly.min.js": () => readFile(require.resolve("plotly.js-dist-min/plotly.min.js")),
  "lodash.js": () => bundle("lodash.vendor.ts"),
  "interact.js": () => bundle("interact.vendor.ts"),
}

export function vendor(): Plugin {
  // Built once per process, however many requests or builds ask.
  const contents = new Map<string, Promise<string | Uint8Array>>()
  const content = (name: string, load: () => Promise<string | Uint8Array>) => {
    let loaded = contents.get(name)
    if (loaded === undefined) {
      loaded = load()
      contents.set(name, loaded)
    }
    return loaded
  }

  return {
    name: "pluto-vendor",
    configureServer(server) {
      server.middlewares.use(async (request, response, next) => {
        const path = request.url?.split("?")[0] ?? ""
        const name = path.startsWith(`${server.config.base}${DIRECTORY}/`)
          ? path.slice(server.config.base.length + DIRECTORY.length + 1)
          : ""
        const load = FILES[name]
        if (load === undefined) {
          next()
          return
        }
        try {
          response.setHeader("Content-Type", "text/javascript")
          response.end(await content(name, load))
        } catch (error) {
          next(error)
        }
      })
    },
    async generateBundle() {
      for (const [name, load] of Object.entries(FILES)) {
        this.emitFile({ type: "asset", fileName: `${DIRECTORY}/${name}`, source: await content(name, load) })
      }
    },
  }
}
