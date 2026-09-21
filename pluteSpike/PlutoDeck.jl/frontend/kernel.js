// The deck's one connection to Pluto: cell output out, bond values in.
//
// Every rule encoded here was a silent failure in the spike first. See pluteSpike/README.md.

import "./vendor/browser-shim.js" // must precede the bundle; see that file
import { Host } from "./vendor/rainbow.esm.js"

/** How long bond changes are collected before they are written, in milliseconds. */
const BATCH_MS = 20

/** How often a settling run is re-checked, in milliseconds. */
const POLL_MS = 40

/** How long the notebook must stay quiet before a run counts as finished. */
const QUIET_MS = 120

/** How long to wait for a run that never starts, because the bond changed nothing. */
const NO_RUN_MS = 800

/** How long a single reactive run may take before the deck stops waiting for it. */
const SETTLE_TIMEOUT_MS = 30_000

/** How a cell body reaches for a `published_to_js` payload, as PlutoRunner writes it. */
const PUBLISHED_REFERENCE = /getPublishedObject\("([^"]+)"\)/g

/**
 * Connect to the Pluto server `session` describes and attach to its notebook.
 *
 * Attaches by notebook id rather than creating a worker: `createWorker` builds its upload URL
 * by concatenation and never forwards the secret, and a server without a secret lets any page
 * the browser visits run Julia on this machine.
 */
export async function connect(session) {
  const host = new Host(`${session.plutoUrl}/?secret=${session.secret}`)
  const worker = host.worker(session.notebook_id)
  if (!(await worker.connect())) throw new Error(`no websocket to ${session.plutoUrl}`)

  // `present` blocks until the kernel is ready, so a deck that finds it otherwise has a kernel
  // that died or parked afterwards, and restarting is the only way back.
  if (worker.getState()?.process_status !== "ready") await worker.restart()

  return new Kernel(worker)
}

/**
 * A live Pluto notebook, addressed by cell id.
 *
 * Reads are synchronous against the last state the websocket delivered; writes are bond values,
 * batched so that a burst becomes one reactive run.
 */
export class Kernel {
  #worker
  #watched = []
  #pending = new Map()
  #flush = null

  constructor(worker) {
    this.#worker = worker
  }

  /** `ready`, `starting`, `no_process`, or `waiting_for_permission`. */
  get status() {
    return this.#worker.getState()?.process_status ?? "no_process"
  }

  /**
   * What a cell is currently showing, or `null` while it has nothing whole to show.
   *
   * `stamp` is the cell's own `last_run_timestamp`, which is what tells a card whether this is
   * output it has already painted. `published` is every payload the body may reach for.
   */
  content(cellId) {
    const state = this.#worker.getState()
    const output = state?.cell_results?.[cellId]?.output
    if (output == null || output.body == null) return null

    const published = state.published_objects ?? {}
    // A body and the payloads it reaches for arrive in separate patches, and the body can be
    // first. A card painted in that window resolves `getPublishedObject` to `undefined`, and
    // the script it was handed throws — leaving a card that reports `live`, logs to the
    // console nobody is reading, and shows an empty box. Output only half here is not output.
    if (typeof output.body === "string") {
      for (const [, id] of output.body.matchAll(PUBLISHED_REFERENCE)) {
        if (!(id in published)) return null
      }
    }

    return {
      source: "live",
      stamp: output.last_run_timestamp ?? 0,
      mime: output.mime,
      body: output.body,
      // Taken with the body rather than read when a script asks, because a re-run landing in
      // between replaces `published_objects` whole and takes this body's ids with it.
      published: { ...published },
      cellId,
    }
  }

  /** Payloads sent by `published_to_js`, which travel outside the cell body. */
  publishedObject(id) {
    return this.#worker.getState()?.published_objects?.[id]
  }

  bonds() {
    return this.#worker.getState()?.bonds ?? {}
  }

  /**
   * Whether the notebook has a variable of this name.
   *
   * Not a question `bonds` can answer: it carries the values a browser has reported, so a bond
   * nothing has written yet is absent from it — which is exactly the bond the deck is about to
   * write. The dependency graph is where a declared name exists before it has a value.
   */
  declares(name) {
    const dependencies = this.#worker.getState()?.cell_dependencies ?? {}
    return Object.values(dependencies).some((cell) =>
      name in (cell.downstream_cells_map ?? {}) || name in (cell.upstream_cells_map ?? {}))
  }

  notebook() {
    return this.#worker.getState()
  }

  /**
   * The cells the deck reads, which is what a run is settled against.
   *
   * Downstream cells finish after the cell they depend on, so settling against the cell a bond
   * feeds hands back the previous run's output for everything below it.
   */
  watch(cellIds) {
    this.#watched = [...new Set(cellIds)].filter(Boolean)
  }

  onChange(fn) {
    return this.#worker.onUpdate(fn)
  }

  onConnectionChange(fn) {
    return this.#worker.onConnectionStatus(fn)
  }

  /**
   * Set a bond, and resolve once the run it caused has finished.
   *
   * Resolving late is what paces a dragged slider: Pluto's bond listener awaits this before it
   * sends the next value, so the notebook runs once per settled value instead of once per
   * input event.
   */
  setBond(name, value) {
    this.#pending.set(name, value)
    this.#flush ??= this.#drain()
    return this.#flush
  }

  async #drain() {
    try {
      while (this.#pending.size > 0) {
        // Each widget reports its own value as its card's scripts finish, so writing the first
        // one the moment it arrives makes it a reactive run of its own — and that run sees every
        // other bond still `missing`. A short collecting window turns the burst into one run.
        await new Promise((resolve) => setTimeout(resolve, BATCH_MS))
        const batch = [...this.#pending]
        this.#pending.clear()
        const before = this.#stamps()
        await this.#write(batch)
        await this.#settle(before)
      }
    } finally {
      this.#flush = null
    }
  }

  /**
   * One notebook update for the whole batch.
   *
   * `Worker.setBond` sends its own `update_notebook`, so setting six bonds through it is six
   * reactive runs, and the first five see bonds that are still `missing`.
   */
  #write(pairs) {
    return this.#worker._update_notebook_state((notebook) => {
      for (const [name, value] of pairs) notebook.bonds[name] = { value }
    })
  }

  #stamps() {
    return new Map(this.#watched.map((cellId) => [cellId, this.content(cellId)?.stamp ?? 0]))
  }

  /**
   * Wait for the run the bonds caused to finish.
   *
   * `isIdle()` is true in the window between sending a bond and the server starting the run, and
   * the diff carrying one cell's result can arrive before the diff that queues its dependents.
   * Idle is therefore only believed once it has held, and once no watched cell has produced
   * anything new, for `QUIET_MS`. A bond that changes nothing re-runs nothing, so a run that
   * never starts is given `NO_RUN_MS` and then let go.
   */
  #settle(before) {
    const started = Date.now()
    const seen = new Map(before)
    let idleSince = null
    let lastChange = started

    return new Promise((resolve) => {
      const tick = () => {
        let advanced = false
        for (const [cellId, stamp] of seen) {
          const now = this.content(cellId)?.stamp ?? 0
          if (now !== stamp) {
            seen.set(cellId, now)
            lastChange = Date.now()
          }
          if (now > before.get(cellId)) advanced = true
        }

        idleSince = this.#worker.isIdle() ? (idleSince ?? Date.now()) : null
        const quiet = Math.min(
          idleSince === null ? 0 : Date.now() - idleSince,
          Date.now() - lastChange,
        )

        if (quiet >= (advanced ? QUIET_MS : NO_RUN_MS)) return resolve()
        if (Date.now() - started > SETTLE_TIMEOUT_MS) return resolve()
        setTimeout(tick, POLL_MS)
      }
      setTimeout(tick, POLL_MS)
    })
  }
}
