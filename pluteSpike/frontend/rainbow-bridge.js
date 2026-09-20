// Deck <-> Pluto bridge.
//
// Slides stay static HTML: <pluto-bind var="Kp"> writes a bond, <pluto-out cell="metrics">
// renders a cell's output. Nothing in a slide imports this module or holds a worker.

import "./vendor/browser-shim.js" // must precede the bundle; see that file
import { Host, getOutput, getStatus } from "./vendor/rainbow.esm.js"

const listeners = new Set()
let deck = null

export function onDeckState(fn) {
  listeners.add(fn)
  if (deck) fn(deck.state)
  return () => listeners.delete(fn)
}

const announce = (state) => listeners.forEach((fn) => fn(state))

class PlutoDeck {
  constructor(worker, watch) {
    this.worker = worker
    this.watch = watch
    this.state = { connected: true, busy: false, error: null }
    this._pending = new Map()
    this._flushing = false
    this._byName = new Map()
    worker.onUpdate(() => this._refresh())
    worker.onConnectionStatus(({ connected }) => {
      this.state = { ...this.state, connected }
      announce(this.state)
    })
  }

  // A bond and the cell that assigns it are both addressed by the Julia name.
  cellIdFor(name) {
    if (this._byName.has(name)) return this._byName.get(name)
    const bind = new RegExp(String.raw`@bind\s+${name}\b`)
    const assign = new RegExp(String.raw`^\s*${name}\s*=(?!=)`, "m")
    const hit = this.worker
      .getSnippets()
      .find((c) => bind.test(c.input.code) || assign.test(c.input.code))
    if (hit) this._byName.set(name, hit.cell_id)
    return hit?.cell_id ?? null
  }

  output(name) {
    const id = this.cellIdFor(name)
    if (!id) return null
    return { ...getOutput(this.worker, id), status: getStatus(this.worker, id) }
  }

  execute(expr) {
    return this.worker.execute(expr)
  }

  // Sliders emit far faster than Julia can run. Latest value wins; one flush in flight.
  setBond(name, value) {
    this._pending.set(name, value)
    this._flush()
  }

  async _flush() {
    if (this._flushing) return
    this._flushing = true
    this.state = { ...this.state, busy: true }
    announce(this.state)
    try {
      while (this._pending.size) {
        const batch = [...this._pending]
        this._pending.clear()
        const before = this._stamps()
        await this._setBonds(batch)
        await this._settle(before)
      }
      this.state = { ...this.state, busy: false, error: null }
    } catch (e) {
      this.state = { ...this.state, busy: false, error: e.message }
    } finally {
      this._flushing = false
      announce(this.state)
      this._refresh()
    }
  }

  // Downstream cells finish after the one they depend on, so waiting on `sim` alone hands
  // back the previous run's `metrics`. Watch everything the deck actually reads.
  _watchNames() {
    const shown = [...document.querySelectorAll("pluto-out")].map((el) => el.getAttribute("cell"))
    return [...new Set([...this.watch, ...shown])].filter(Boolean)
  }

  // Rainbow's setBond sends one `update_notebook` per call, so a six-slider push is six
  // reactive runs and the early ones still see `missing`. One patch set, one run.
  _setBonds(pairs) {
    return this.worker._update_notebook_state((nb) => {
      for (const [name, value] of pairs) nb.bonds[name] = { value }
    })
  }

  _stamps() {
    return new Map(this._watchNames().map((n) => [n, this.output(n)?.last_run_timestamp ?? 0]))
  }

  // isIdle() is true in the window between sending a bond and the server starting the run,
  // so it alone reports "settled" immediately. Wait for the watched cells to re-run too.
  _settle(before, timeout = 30000) {
    const t0 = Date.now()
    return new Promise((resolve) => {
      const tick = () => {
        const reran = [...before].every(([n, ts]) => (this.output(n)?.last_run_timestamp ?? 0) > ts)
        if ((reran && this.worker.isIdle()) || Date.now() - t0 > timeout) return resolve()
        setTimeout(tick, 40)
      }
      setTimeout(tick, 40)
    })
  }

  _refresh() {
    document.querySelectorAll("pluto-out").forEach((el) => el.render())
  }
}

export async function connectDeck({ watch = ["sim"] } = {}) {
  const cfg = await (await fetch("/api/session")).json()
  const host = new Host(`${cfg.plutoUrl}/?secret=${cfg.secret}`)
  const worker = host.worker(cfg.notebook_id)
  if (!(await worker.connect())) throw new Error("websocket refused")

  // An uploaded notebook can be parked in `waiting_for_permission`; a restart starts it.
  if (worker.getState()?.process_status !== "ready") await worker.restart()

  deck = new PlutoDeck(worker, watch)
  announce(deck.state)
  return deck
}

export const getDeck = () => deck

// --- <pluto-bind var="Kp" type="range" min=0 max=20 step=0.1 value=2 label="Kp"> ---------

customElements.define(
  "pluto-bind",
  class extends HTMLElement {
    connectedCallback() {
      const name = this.getAttribute("var")
      const type = this.getAttribute("type") ?? "range"
      const value = this.getAttribute("value")
      const label = this.getAttribute("label") ?? name
      const unit = this.getAttribute("unit") ?? ""

      this.innerHTML = `
        <label for="b-${name}">${label}</label>
        <input id="b-${name}" type="${type}"
          ${["min", "max", "step"].map((a) => (this.hasAttribute(a) ? `${a}="${this.getAttribute(a)}"` : "")).join(" ")}>
        <output id="o-${name}"></output>`

      this.input = this.querySelector("input")
      this.readout = this.querySelector("output")
      if (type === "checkbox") this.input.checked = value !== "false"
      else this.input.value = value

      const show = () =>
        (this.readout.textContent =
          type === "checkbox" ? (this.input.checked ? "on" : "off") : `${this.input.value}${unit}`)
      show()

      this.input.addEventListener("input", () => {
        show()
        getDeck()?.setBond(name, this.value())
      })
    }

    value() {
      return this.input.type === "checkbox" ? this.input.checked : Number(this.input.value)
    }

    push() {
      getDeck()?.setBond(this.getAttribute("var"), this.value())
    }
  }
)

// --- <pluto-out cell="metrics"> ----------------------------------------------------------

customElements.define(
  "pluto-out",
  class extends HTMLElement {
    connectedCallback() {
      this.render()
    }

    render() {
      const d = getDeck()
      if (!d) return
      const out = d.output(this.getAttribute("cell"))
      if (!out) return
      this.dataset.status = out.status
      const body = out.body
      if (out.mime === "text/html" && typeof body === "string") this.innerHTML = body
      else this.textContent = typeof body === "string" ? body : JSON.stringify(body)
    }
  }
)

// Bonds start as `missing` — the widget's own default is never reported by itself.
export function pushAllBinds() {
  document.querySelectorAll("pluto-bind").forEach((el) => el.push())
}
