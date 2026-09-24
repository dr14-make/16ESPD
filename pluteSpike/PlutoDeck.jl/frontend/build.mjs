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

/**
 * The two libraries the deck serves itself, so that a lecture hall's network is never on the
 * path to an equation or a plot.
 *
 * Copied, not bundled: each is a classic script assigning a global — `window.MathJax`,
 * `window.Plotly` — rather than a module. Resolved through the package rather than by path, so
 * an install layout that does not put them under a flat `node_modules` fails here instead of
 * naming a file that is not there.
 */
const MATHJAX = fileURLToPath(import.meta.resolve("mathjax/es5/tex-svg-full.js"))
const PLOTLY = fileURLToPath(import.meta.resolve("plotly.js-dist-min/plotly.min.js"))

/**
 * The version of that Plotly build, read from the package rather than written down.
 *
 * It is the key a plot cell asks `window.plutoplotly_imports` for, so a version this build and
 * the notebook's PlutoPlotly disagree on is a deck whose every plot silently fetches from
 * esm.sh — working at a desk, failing in a lecture room. `server.jl` asserts they agree.
 */
const PLOTLY_VERSION = JSON.parse(
  await readFile(fileURLToPath(import.meta.resolve("plotly.js-dist-min/package.json")), "utf8"),
).version

/**
 * What a plot cell's script imports by absolute URL, against the module of the deck's own that
 * satisfies it.
 *
 * PlutoPlotly's scripts import both with a top-level `await`, so either one unreachable is a
 * plot card that draws nothing at all. An import map is how a page says what satisfies a
 * specifier, and it reaches the dynamic `import()` inside a cell's script because Rainbow
 * compiles that script with `Function(…)` and a document's map governs resolution for code
 * compiled that way.
 *
 * One object rather than a list in each place it is needed: the entry points, the map written
 * into the page and this rationale would otherwise be three edits, and the one that gets
 * forgotten is a silent CDN fetch. `server.jl` fails if PlutoPlotly imports a URL not named
 * here.
 */
const VENDORED_IMPORTS = {
  "https://cdn.jsdelivr.net/npm/lodash-es@4.17.21/+esm": "lodash.vendor.ts",
  "https://esm.sh/interactjs@1.10.19": "interact.vendor.ts",
}

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

async function emitPages(metafile, vendored) {
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
      .replaceAll("{{mathjax.js}}", vendored.mathjax)
      .replaceAll("{{plotly.js}}", vendored.plotly)
      .replaceAll("{{plotly.version}}", PLOTLY_VERSION)
      .replaceAll("{{importmap}}", importMap(assetFor))
      .replaceAll(`{{${page.token}}}`, assetFor(`src/${page.entry}`))

    if (rendered.includes("{{")) {
      throw new Error(`${page.template} still holds an unsubstituted token`)
    }
    await writeFile(join(OUT, page.template), rendered)
  }
}

/** The import map `index.html` carries, naming each vendored module by its built asset. */
function importMap(assetFor) {
  return JSON.stringify({
    imports: Object.fromEntries(
      Object.entries(VENDORED_IMPORTS).map(([specifier, file]) => [
        specifier,
        `./${assetFor(`src/${file}`)}`,
      ]),
    ),
  })
}

/**
 * Copy `source` into the bundle as `name`, under a content-hashed name, and report what it is
 * called.
 *
 * A build of its own because the `copy` loader is keyed by extension: setting it for `.js` in
 * the main build would stop esbuild bundling every `.js` its module graph reaches through
 * `node_modules` and copy those too.
 */
async function copyVendored(source, name) {
  const result = await esbuild.build({
    absWorkingDir: HERE,
    entryPoints: [{ in: source, out: name }],
    outdir: OUT,
    loader: { ".js": "copy" },
    entryNames: "[name]-[hash]",
    metafile: true,
  })
  const [built] = Object.keys(result.metafile.outputs)
  if (built === undefined) {
    throw new Error(`nothing was copied from ${source}`)
  }
  return relative(OUT, join(HERE, built))
}

/** Rewriting the HTML is part of every build, because the asset names carry a content hash. */
function emitPagesPlugin(vendored) {
  return {
    name: "emit-pages",
    setup(build) {
      build.onEnd(async (result) => {
        if (result.metafile !== undefined && result.errors.length === 0) {
          await emitPages(result.metafile, vendored)
        }
      })
    },
  }
}

await rm(OUT, { recursive: true, force: true })
await mkdir(OUT, { recursive: true })

// Before the options, because the plugin closes over the names the copies landed under, and
// once rather than per rebuild: a pinned dependency cannot change while a watcher is running.
const vendored = {
  mathjax: await copyVendored(MATHJAX, "tex-svg-full"),
  plotly: await copyVendored(PLOTLY, "plotly"),
}

const options = {
  // The metafile's output keys are resolved against this, so naming it is what makes the asset
  // URLs written into the HTML correct from any working directory rather than only from here.
  absWorkingDir: HERE,
  entryPoints: [
    join(SOURCE, "deck.entry.ts"),
    join(SOURCE, "speaker.entry.ts"),
    // Reached by no import of the deck's own, only by the import map `index.html` carries.
    ...Object.values(VENDORED_IMPORTS).map((file) => join(SOURCE, file)),
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
  plugins: [emitPagesPlugin(vendored)],
}

if (watch) {
  const context = await esbuild.context(options)
  await context.watch()
} else {
  await esbuild.build(options)
}
