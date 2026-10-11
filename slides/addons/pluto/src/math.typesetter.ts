// Drawing the LaTeX that reaches a card.
//
// The markup is Pluto's: `.tex` elements carrying their own `$` delimiters, written by the
// kernel.
//
// MathJax draws to SVG, so every glyph is a path and there are no font files to serve.

/** The link each page's HTML carries, naming the MathJax build the bundle put beside it. */
const SOURCE_REL = "mathjax-source"

interface MathJaxStartup {
  typeset: boolean
}

/**
 * The MathJax surface the deck writes and then calls.
 *
 * `window.MathJax` is the configuration until the script lands and the runtime it grows into
 * afterwards, which is why the members the runtime supplies are optional: the same property is
 * read in both states.
 */
interface MathJaxGlobal {
  options: { ignoreHtmlClass: string; processHtmlClass: string }
  startup: MathJaxStartup
  tex: { inlineMath: string[][] }
  svg: { fontCache: string }
  typesetPromise?: (elements?: Element[]) => Promise<unknown>
  typesetClear?: (elements?: Element[]) => void
}

declare global {
  interface Window {
    MathJax?: MathJaxGlobal
  }
}

/** The load, once, however many containers ask for it. */
let loading: Promise<void> | null = null

/**
 * Typeset the math in `container`, once MathJax is there to do it.
 *
 * Awaited rather than skipped when the script has not landed, so a formula that arrives before
 * MathJax is drawn rather than left showing its delimiters.
 *
 * A deck whose notebook holds no math never asks, so it never fetches the build.
 */
export async function typesetMath(container: Element): Promise<void> {
  const math = container.querySelectorAll(".tex")
  if (math.length === 0) {
    return
  }

  loading ??= load()
  await loading

  try {
    // `typesetPromise` rather than `typeset`: the synchronous form throws where a typeset needs
    // a component MathJax has not loaded, which is the one failure here that recovers on its own.
    await window.MathJax?.typesetPromise?.([...math])
  } catch {
    // MathJax draws LaTeX it cannot parse as an error box of its own, so what lands here is the
    // renderer failing rather than the formula being wrong. The delimiters stay on the slide,
    // which is a failure a lecturer can see and read past rather than a blank card.
  }
}

/**
 * Forget the math MathJax drew inside `container`, before `container` is emptied.
 *
 * MathJax holds every item it has typeset on its document, and `contains` is how it finds them
 * again — so content replaced without this leaves its detached subtree reachable for as long as
 * the page lives. A card whose formula carries a bond repaints on every frame of a drag, and
 * with a local font cache each abandoned copy carries its own glyph paths.
 */
export function clearMath(container: Element): void {
  window.MathJax?.typesetClear?.([container])
}

/**
 * Configure MathJax and load it, resolving either way.
 *
 * A rejection would be a slide's worth of delimiters however it were reported, and the suite
 * asserts drawn glyphs rather than a loaded script, so the failure is caught where it shows.
 */
function load(): Promise<void> {
  const source = document.head.querySelector(`link[rel="${SOURCE_REL}"]`)
  if (!(source instanceof HTMLLinkElement)) {
    return Promise.resolve()
  }

  window.MathJax = {
    // Pluto's verbatim, and inert here: the elements handed to a pass are the `.tex` nodes
    // themselves, whose only child is the text MathJax reads, so the walk these govern has
    // nothing to skip or force. Nothing in the tree carries `no-MαθJax` either.
    options: { ignoreHtmlClass: "no-MαθJax", processHtmlClass: "tex" },
    startup: {
      // Every pass names the container it just painted, and a document-wide sweep would be the
      // one pass able to find a `$` in prose that no `.tex` element wraps.
      typeset: false,
    },
    tex: {
      inlineMath: [
        ["$", "$"],
        ["\\(", "\\)"],
      ],
    },
    // `local` where Pluto has `global`: each formula carries its glyph paths in its own `<defs>`
    // rather than reaching one document-wide `<svg>` through `<use href="#…">`, so a formula's
    // own subtree is all it needs to draw. Still no font files.
    svg: { fontCache: "local" },
  }

  return new Promise((resolve) => {
    const script = document.createElement("script")
    script.addEventListener("load", () => {
      resolve()
    })
    script.addEventListener("error", () => {
      resolve()
    })
    script.src = source.href
    document.head.append(script)
  })
}

