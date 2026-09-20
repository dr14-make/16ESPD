import "./vendor/browser-shim.js"
import { Host, getOutput, getStatus } from "./vendor/rainbow.esm.js"
import {
  OutputBody, html, render,
  PlutoActionsContext, PlutoBondsContext, PlutoJSInitializingContext,
} from "./vendor/rainbow-ui.esm.js"

const preamble = document.createElement("div")
preamble.id = "preamble"
preamble.style.display = "none"
document.body.appendChild(preamble)

const log = (m) => (document.getElementById("log").textContent += "\n" + m)
document.getElementById("log").textContent = "connecting…"

const cfg = await (await fetch("/api/session")).json()
const worker = new Host(`${cfg.plutoUrl}/?secret=${cfg.secret}`).worker(cfg.notebook_id)
await worker.connect()
log(`connected · notebook ${cfg.notebook_id}`)

// RawHTMLContainer add()s a container here while its scripts run and delete()s it after,
// so this must be Set-like. The editor uses a Set subclass that flushes queued bond changes
// when it empties; a plain Set is enough to make scripts execute.
const JS_INIT = new Set()

const idOf = (re) => worker.getSnippets().find((c) => re.test(c.input.code))?.cell_id

// OutputBody expects the Pluto editor's contexts. Supply the minimum a card needs:
// bonds it can read, and an actions object it can call into.
const actions = {
  set_bond: async (name, value) => { await worker.setBond(name, value) },
  set_doc_query: () => {},
  focus_on_neighbor: () => {},
  get_notebook: () => worker.getState(),
  // published_to_js payloads travel in notebook.published_objects, not in the cell body.
  // Scripts call a bare getPublishedObject(id), which execute_scripttags wires to this.
  get_published_object: (id) => worker.getState()?.published_objects?.[id],
  get_launch_params: () => ({}),
}

// A notebook diff arrives for every cell, many times per run. Repainting every card on every
// diff tears down and rebuilds each card's scripts — for a Plotly card that means rebuilding
// the graph against a multi-megabyte published payload, and the browser grows without bound.
// A card repaints only when its own cell has actually re-run.
const painted = new Map()

function paint(where, cell_id, force = false) {
  const host = document.getElementById(where)
  if (!cell_id) { host.textContent = "cell not found"; return }
  const o = getOutput(worker, cell_id)
  if (!o?.body) { host.textContent = `no output (status ${getStatus(worker, cell_id)})`; return }
  const stamp = o.last_run_timestamp ?? 0
  if (!force && painted.get(cell_id) === stamp) return
  painted.set(cell_id, stamp)

  // execute_scripttags resolves a script's getPublishedObject through
  //   root_node.closest("pluto-cell").getPublishedObject(id)
  // so a card needs a <pluto-cell> ancestor carrying that method, or every published_to_js
  // payload — which is how PlutoPlotly ships both the library and the plot data — is
  // unreachable and the script dies silently.
  let cell = host.querySelector("pluto-cell")
  if (!cell) {
    cell = document.createElement("pluto-cell")
    cell.style.display = "block"
    host.appendChild(cell)
  }
  cell.getPublishedObject = (id) => worker.getState()?.published_objects?.[id]

  render(
    html`<${PlutoActionsContext.Provider} value=${actions}>
      <${PlutoBondsContext.Provider} value=${worker.getState()?.bonds ?? {}}>
        <${PlutoJSInitializingContext.Provider} value=${JS_INIT}>
          <${OutputBody} mime=${o.mime} body=${o.body} cell_id=${cell_id}
            persist_js_state=${false} last_run_timestamp=${o.last_run_timestamp}
            sanitize_html=${false} />
        <//>
      <//>
    <//>`,
    cell
  )
  log(`rendered ${where}: mime=${o.mime} bytes=${String(o.body).length}`)
}

async function paintPreamble() {
  // PlutoPlotly's offline loader is a cell whose *output is a side-effecting script*: it
  // inlines the plotly bundle onto window. It has to be in the DOM and executed before any
  // plot card renders, yet it is not something a slide should show — and it is painted once,
  // because repainting re-runs the library import.
  paint("preamble", idOf(/^\s*plotly_offline\s*=/m))
  await new Promise((r) => setTimeout(r, 1200))
}

function paintAll() {
  paint("probe",  idOf(/^\s*script_probe\s*=/m))
  paint("plotly", idOf(/^\s*plotly_demo\s*=/m))
  paint("bond",   idOf(/@bind\s+v_ref_kmh\b/))
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
for (let i = 0; i < 240; i++) {           // PlutoPlotly may still be installing
  const id = idOf(/^\s*plotly_demo\s*=/m)
  if (id && getStatus(worker, id) === "done" && getOutput(worker, id)?.body) break
  await sleep(500)
}
log(`kernel status: ${worker.getState()?.process_status}`)
await paintPreamble()
paintAll()

// --- frequency slider -> bond -------------------------------------------------------------
// Latest value wins, one write in flight: a dragged slider emits far faster than Julia runs.
const slider = document.getElementById("freq")
const readout = document.getElementById("freqval")
const lat = document.getElementById("lat")
const plotCell = () => idOf(/^\s*plotly_demo\s*=/m)

let queued = null, busy = false
async function pump() {
  if (busy || queued === null) return
  busy = true
  const v = queued; queued = null
  const t0 = performance.now()
  const before = getOutput(worker, plotCell())?.last_run_timestamp ?? 0
  await worker.setBond("freq", v)
  for (let i = 0; i < 200; i++) {
    if ((getOutput(worker, plotCell())?.last_run_timestamp ?? 0) > before && worker.isIdle()) break
    await new Promise((r) => setTimeout(r, 25))
  }
  lat.textContent = `${Math.round(performance.now() - t0)} ms round trip`
  busy = false
  pump()
}

slider.addEventListener("input", () => {
  readout.textContent = Number(slider.value).toFixed(1)
  queued = Number(slider.value)
  pump()
})

await worker.setBond("freq", Number(slider.value))
worker.onUpdate(() => paintAll())
