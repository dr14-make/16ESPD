// Putting the Plotly library where a plot cell looks for it.
//
// A plot cell does not embed the library. PlutoPlotly emits, per plot,
//
//     window.plutoplotly_imports?.['<version>'] ?? (await import("https://esm.sh/…")).default
//
// so whatever sits at that global is what every plot draws with, and a deck that fills it needs
// no change to any plot cell.
//
// Copied rather than bundled, for the reason MathJax is: the distribution is a classic script
// assigning `window.Plotly`, not a module.

/** The link each page's HTML carries, naming the Plotly build the bundle put beside it. */
const SOURCE_REL = "plotly-source"

/** The global a plot cell reads, and the marker that tells apart a body that will read it. */
const IMPORTS = "plutoplotly_imports"

declare global {
  interface Window {
    Plotly?: object
    [IMPORTS]?: Record<string, object>
  }
}

/** The load, once, however many plots ask for it. */
let loading: Promise<void> | null = null

/**
 * Whether `body` is cell output that will reach for the Plotly global.
 *
 * The name is PlutoPlotly's contract rather than an incidental string: it is what a plot cell
 * reads and what this module writes, so output naming it is output that needs the library.
 * A deck whose notebook draws no plots never asks, so it never fetches the build.
 */
export function needsPlotly(body: unknown): boolean {
  return typeof body === "string" && body.includes(IMPORTS)
}

/**
 * Load Plotly out of the bundle and publish it at the global, resolving either way.
 *
 * A rejection would be a plot card that draws nothing however it were reported, and the suite
 * asserts a drawn graph rather than a loaded script, so the failure is caught where it shows.
 *
 * The version the link declares is the key, because a plot cell asks for one version by name
 * and falls through to the network for any other. `server.jl` asserts the two agree.
 */
export function loadPlotly(): Promise<void> {
  loading ??= load()
  return loading
}

function load(): Promise<void> {
  const source = document.head.querySelector(`link[rel="${SOURCE_REL}"]`)
  if (!(source instanceof HTMLLinkElement)) {
    return Promise.resolve()
  }
  const { version } = source.dataset
  if (version === undefined) {
    return Promise.resolve()
  }

  return new Promise((resolve) => {
    const script = document.createElement("script")
    script.addEventListener("load", () => {
      const plotly = window.Plotly
      if (plotly !== undefined) {
        window[IMPORTS] = { ...window[IMPORTS], [version]: plotly }
      }
      resolve()
    })
    script.addEventListener("error", () => {
      resolve()
    })
    script.src = source.href
    document.head.append(script)
  })
}
