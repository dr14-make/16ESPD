// Bundle the deck's TypeScript into ../frontend-dist, which is what `frontend_directory()`
// serves. Node is a build-time tool: nothing here runs when a deck is presented.
//
// Run `npm run build` once, or `npm run dev` to keep the bundle current while editing.

import { rm, mkdir, readFile, writeFile } from "node:fs/promises"
import { dirname, join, relative } from "node:path"
import { fileURLToPath } from "node:url"
import * as esbuild from "esbuild"

const HERE = dirname(fileURLToPath(import.meta.url))
const SOURCE = join(HERE, "src")
const OUT = join(HERE, "..", "frontend-dist")

/** Each page, its entry module, and the template that references the built assets. */
const PAGES = [
  { template: "index.html", entry: "deck.entry.ts", token: "deck.js" },
  { template: "speaker.html", entry: "speaker.entry.ts", token: "speaker.js" },
]

const watch = process.argv.includes("--watch")

/**
 * `@plutojl/rainbow` publishes an ESM build meant for a bundler rather than for a page.
 *
 * immer, which its root bundle embeds, reads `process.env.NODE_ENV` as a bare global six times.
 * Nothing defines it in a page, so importing that build directly throws `ReferenceError:
 * process is not defined` before anything connects — the failure `frontend/vendor/browser-shim.js`
 * existed to prevent, and the one no Node-side harness can catch, because Node defines `process`
 * itself. Substituting it here is what makes the shim unnecessary rather than merely relocated.
 *
 * `global` needs nothing: every reference in either bundle is the browserify
 * `typeof global !== "undefined" ? global : …` probe, and `typeof` on an undeclared name does
 * not throw. Defining it anyway would be a substitution that provably changes no byte.
 */
const define = { "process.env.NODE_ENV": '"production"' }

async function emitPages(metafile) {
  const outputs = Object.entries(metafile.outputs)

  const assetFor = (entrySuffix) => {
    const hit = outputs.find(([, meta]) => meta.entryPoint?.endsWith(entrySuffix))
    if (hit === undefined) {
      throw new Error(`nothing in the bundle was built from ${entrySuffix}`)
    }
    return relative(OUT, join(HERE, hit[0]))
  }

  const stylesheet = assetFor("src/deck.css")

  for (const page of PAGES) {
    const template = await readFile(join(SOURCE, page.template), "utf8")
    const rendered = template
      .replaceAll("{{deck.css}}", stylesheet)
      .replaceAll(`{{${page.token}}}`, assetFor(`src/${page.entry}`))

    if (rendered.includes("{{")) {
      throw new Error(`${page.template} still holds an unsubstituted token`)
    }
    await writeFile(join(OUT, page.template), rendered)
  }
}

/** Rewriting the HTML is part of every build, because the asset names carry a content hash. */
const emitPagesPlugin = {
  name: "emit-pages",
  setup(build) {
    build.onEnd(async (result) => {
      if (result.metafile !== undefined && result.errors.length === 0) {
        await emitPages(result.metafile)
      }
    })
  },
}

const options = {
  // The metafile's output keys are resolved against this, so naming it is what makes the asset
  // URLs written into the HTML correct from any working directory rather than only from here.
  absWorkingDir: HERE,
  entryPoints: [
    join(SOURCE, "deck.entry.ts"),
    join(SOURCE, "speaker.entry.ts"),
    join(SOURCE, "deck.css"),
  ],
  outdir: OUT,
  bundle: true,
  format: "esm",
  // The speaker page carries no kernel and no Rainbow bundle by design. Splitting is what keeps
  // that true as the two pages come to share more of the deck's own modules.
  splitting: true,
  target: ["chrome120", "firefox120", "safari17"],
  // A hashed name is what lets `server.jl` answer `immutable` for an asset that can never change
  // under its own name.
  entryNames: "[name]-[hash]",
  chunkNames: "chunk-[hash]",
  assetNames: "asset-[hash]",
  // Maps are for whoever is editing the source, and the bundle is committed: shipping them
  // would put 8 MB of generated text into every frontend commit for a file no lecturer opens.
  sourcemap: watch,
  minify: true,
  metafile: true,
  logLevel: "info",
  define,
  plugins: [emitPagesPlugin],
}

await rm(OUT, { recursive: true, force: true })
await mkdir(OUT, { recursive: true })

if (watch) {
  const context = await esbuild.context(options)
  await context.watch()
} else {
  await esbuild.build(options)
}
