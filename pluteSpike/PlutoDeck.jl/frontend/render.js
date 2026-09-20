// Rendering a cell's output the way Pluto renders it.
//
// Assigning to `innerHTML` never executes an inserted <script>, and most Pluto output is a
// container plus the script that fills it, so a naive renderer shows empty boxes for Plotly,
// for PlutoUI widgets and for most @bind elements. `OutputBody` re-creates script nodes so
// they run, resolves `published_to_js` payloads, and wires bound elements back to the kernel.

import "./vendor/browser-shim.js" // must precede the bundle; see that file
import {
  OutputBody,
  PlutoActionsContext,
  PlutoBondsContext,
  PlutoJSInitializingContext,
  html,
  render,
} from "./vendor/rainbow-ui.esm.js"

/**
 * The containers whose scripts are running right now.
 *
 * `RawHTMLContainer` calls `.add(container)` before its scripts run and `.delete(container)`
 * after, so this has to be a `Set`: any other shape throws inside the effect and no script in
 * any card ever runs, with nothing rendered and nothing logged.
 */
const RUNNING_SCRIPTS = new Set()

/** How often a card's scripts are re-checked for having finished, in milliseconds. */
const SCRIPT_POLL_MS = 20

/** How long a card's scripts may run before the deck stops waiting for them. */
const SCRIPT_TIMEOUT_MS = 20_000

/**
 * Build the painter every card renders through.
 *
 * `kernel` is read for the contexts Pluto's own components expect — the bonds a widget shows,
 * the published payloads a script asks for, and the bond setter a widget writes through.
 */
export function createPainter(kernel) {
  // The effect that executes a card's scripts lists `pluto_actions` among its dependencies, so
  // a fresh object here would re-run every script on every repaint.
  const actions = {
    set_bond: (name, value) => kernel.setBond(name, value),
    get_notebook: () => kernel.notebook(),
    get_published_object: (id) => kernel.publishedObject(id),
    get_launch_params: () => ({}),
    set_doc_query: () => {},
    focus_on_neighbor: () => {},
  }

  return function paint(host, content) {
    // `execute_scripttags` resolves a script's published objects through
    //   root_node.closest("pluto-cell").getPublishedObject(id)
    // so output rendered without a <pluto-cell> ancestor carrying that method cannot reach any
    // `published_to_js` payload, and the script dies with no exception and nothing rendered.
    let cell = host.querySelector(":scope > pluto-cell")
    if (cell === null) {
      cell = document.createElement("pluto-cell")
      host.replaceChildren(cell)
    }
    cell.getPublishedObject = (id) => kernel.publishedObject(id)

    render(
      html`<${PlutoActionsContext.Provider} value=${actions}>
        <${PlutoBondsContext.Provider} value=${kernel.bonds()}>
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
}

/**
 * Resolve once no card's scripts are still running.
 *
 * A preamble card's whole purpose is a side effect its scripts perform — loading the offline
 * Plotly bundle onto `window` — and a plot card rendered before that finishes draws nothing.
 */
export function whenScriptsSettled() {
  const deadline = Date.now() + SCRIPT_TIMEOUT_MS
  return new Promise((resolve) => {
    const tick = () => {
      if (RUNNING_SCRIPTS.size === 0 || Date.now() > deadline) return resolve()
      setTimeout(tick, SCRIPT_POLL_MS)
    }
    setTimeout(tick, SCRIPT_POLL_MS)
  })
}
