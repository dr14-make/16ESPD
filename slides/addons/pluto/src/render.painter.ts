// Rendering a cell's output the way Pluto renders it.
//
// Assigning to `innerHTML` never executes an inserted <script>, and most Pluto output is a
// container plus the script that fills it, so a naive renderer shows empty boxes for Plotly,
// for PlutoUI widgets and for most @bind elements. `OutputBody` re-creates script nodes so
// they run, resolves `published_to_js` payloads, and wires bound elements back to the kernel.
//
// Rainbow draws through Preact, and this is the one place the deck meets it: a card component
// owns a card's box and hands this function a plain element to paint into.

import {
  OutputBody,
  PlutoActionsContext,
  PlutoBondsContext,
  PlutoJSInitializingContext,
  html,
  render,
} from "@plutojl/rainbow/ui"
import type { CardContent } from "./session.interface.js"
import type { Kernel } from "./kernel.client.js"
import type { NotebookState } from "./pluto.interface.js"
import { clearMath, typesetMath } from "./math.typesetter.js"
import { isolate } from "./published.helper.js"

/**
 * The containers whose scripts are running right now.
 *
 * `RawHTMLContainer` calls `.add(container)` before its scripts run and `.delete(container)`
 * after, so this has to be a `Set`: any other shape throws inside the effect and no script in
 * any card ever runs, with nothing rendered and nothing logged.
 */
const RUNNING_SCRIPTS = new Set<Element>()

/** How often a card's scripts are re-checked for having finished, in milliseconds. */
const SCRIPT_POLL_MS = 20

/** How long a card's scripts may run before the deck stops waiting for them. */
const SCRIPT_TIMEOUT_MS = 20_000

/**
 * The payloads each card's recent renders were handed, newest first.
 *
 * A card's scripts finish well after the paint that started them, and a repaint replaces the
 * resolver they call. Without the renders before it, a script still running from an earlier
 * paint asks the newest one for an id that went out with its own run, is handed `undefined`,
 * and throws — leaving a card that reports `live` and draws nothing.
 */
const PAYLOADS = new WeakMap<Element, readonly Readonly<Record<string, unknown>>[]>()

/** How many renders' payloads a card keeps, which is how many repaints may be in flight. */
const PAYLOAD_DEPTH = 3

/** An action Pluto's components call that the deck has no answer for; the key must exist. */
const ignored = (): void => undefined

/** Paints a cell's output into an element that is already in the document. */
export type Painter = (host: Element, content: CardContent) => void

/** A `<pluto-cell>` carries the resolver `execute_scripttags` reaches for, once a paint installs it. */
interface PublishingCell extends HTMLElement {
  getPublishedObject?(id: string): unknown
}

/**
 * Build the painter every card renders through.
 *
 * `kernel` is read for the contexts Pluto's own components expect — the bonds a widget shows,
 * the published payloads a script asks for, and the bond setter a widget writes through.
 *
 * A payload is isolated on the way out: Pluto publishes one object per cell, and a deck renders
 * a cell once per slide it is placed on. See `published.helper.ts`.
 *
 * Every widget this painter drew is brought to the kernel's bond value whenever the bonds
 * change, not only when its card repaints. A widget's cell does not re-run when its own bond
 * moves, so a card placed on several slides would otherwise leave every copy but the one that
 * was moved at the value it was painted with.
 */
export function createPainter(kernel: Kernel): Painter {
  // The effect that executes a card's scripts lists `pluto_actions` among its dependencies, so
  // a fresh object here would re-run every script on every repaint.
  const actions = {
    set_bond: (name: string, value: unknown) => kernel.setBond(name, value),
    get_notebook: () => kernel.notebook(),
    get_published_object: (id: string) => isolate(kernel.publishedObject(id)),
    get_launch_params: () => ({}),
    set_doc_query: ignored,
    focus_on_neighbor: ignored,
  }

  const draw = (cell: HTMLElement, content: CardContent, bonds: NotebookState["bonds"]): void => {
    render(
      html`<${PlutoActionsContext.Provider} value=${actions}>
        <${PlutoBondsContext.Provider} value=${bonds}>
          <${PlutoJSInitializingContext.Provider} value=${RUNNING_SCRIPTS}>
            <${OutputBody}
              mime=${content.mime}
              body=${content.body}
              cell_id=${content.cellId}
              last_run_timestamp=${content.stamp}
              persist_js_state=${false}
              sanitize_html=${false}
            />
          <//>
        <//>
      <//>`,
      cell,
    )
  }

  // Redrawn with the same body, stamp and actions, `RawHTMLContainer` re-runs only its effect
  // keyed on the bonds, which sets each bound element's value without dispatching an event — so
  // a copy follows the bond without writing it back. The notebook state is immutable and keeps
  // `bonds` the same object until a patch touches it, which is what makes identity the test.
  const drawn = new Map<HTMLElement, CardContent>()
  let shownBonds = kernel.bonds()
  kernel.onChange(() => {
    const bonds = kernel.bonds()
    if (bonds === shownBonds) {
      return
    }
    shownBonds = bonds
    for (const [cell, content] of drawn) {
      if (cell.isConnected) {
        draw(cell, content, bonds)
      } else {
        drawn.delete(cell)
      }
    }
  })

  return function paint(host: Element, content: CardContent): void {
    // `execute_scripttags` resolves a script's published objects through
    //   root_node.closest("pluto-cell").getPublishedObject(id)
    // so output rendered without a <pluto-cell> ancestor carrying that method cannot reach any
    // `published_to_js` payload, and the script dies with no exception and nothing rendered.
    // `closest` does not cross a shadow boundary, which is why every element between here and
    // the document is in light DOM.
    let cell = host.querySelector(":scope > pluto-cell")
    if (cell === null) {
      cell = document.createElement("pluto-cell")
      host.replaceChildren(cell)
    }
    if (!(cell instanceof HTMLElement)) {
      throw new Error("a card's <pluto-cell> is not an HTMLElement")
    }
    const publishing: PublishingCell = cell

    const payloads = [
      content.published,
      ...(PAYLOADS.get(publishing) ?? []).slice(0, PAYLOAD_DEPTH - 1),
    ]
    PAYLOADS.set(publishing, payloads)
    publishing.getPublishedObject = (id: string): unknown => {
      for (const published of payloads) {
        if (id in published) {
          return isolate(published[id])
        }
      }
      return isolate(kernel.publishedObject(id))
    }

    // Before the render that replaces it: MathJax finds what it has drawn with `contains`, so
    // once the old output is detached it can no longer be reached to be forgotten.
    clearMath(cell)

    draw(cell, content, kernel.bonds())
    // Only a cell with a bound element has anything to bring to a new bond value, and a plot
    // card's content holds its whole published payload.
    if (cell.querySelector("bond") === null) {
      drawn.delete(cell)
    } else {
      drawn.set(cell, content)
    }

    // `RawHTMLContainer` sets the cell's HTML in a layout effect, which Preact flushes before
    // `render` returns, so the `.tex` elements the kernel wrote are in the document by here.
    void typesetMath(cell)
  }
}

/**
 * Resolve once no card's scripts are still running.
 *
 * A preamble card's whole purpose is a side effect its scripts perform, and a card that
 * depends on that effect and is rendered before it finishes draws nothing.
 */
export function whenScriptsSettled(): Promise<void> {
  const deadline = Date.now() + SCRIPT_TIMEOUT_MS
  return new Promise((resolve) => {
    const tick = (): void => {
      if (RUNNING_SCRIPTS.size === 0 || Date.now() > deadline) {
        resolve()
        return
      }
      setTimeout(tick, SCRIPT_POLL_MS)
    }
    setTimeout(tick, SCRIPT_POLL_MS)
  })
}
