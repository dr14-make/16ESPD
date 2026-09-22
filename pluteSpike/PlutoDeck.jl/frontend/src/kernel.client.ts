// The deck's one connection to Pluto: cell output out, bond values in.
//
// Every rule encoded here was a silent failure in the spike first. See pluteSpike/README.md.

import { Host } from "@plutojl/rainbow"
import type { Worker } from "@plutojl/rainbow"
import { BondQueue } from "./bond.queue.js"
import { bondWriter } from "./bond.writer.js"
import type { BondWriter } from "./bond.writer.js"
import type { CardContent, Session } from "./deck.interface.js"
import { isCellDependency, isCellOutput, isNotebookState } from "./pluto.interface.js"
import type { NotebookState } from "./pluto.interface.js"

function isRecordLike(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null
}

/** How a cell body reaches for a `published_to_js` payload, as PlutoRunner writes it. */
const PUBLISHED_REFERENCE = /getPublishedObject\("([^"]+)"\)/g

/**
 * Connect to the Pluto server `session` describes and attach to its notebook.
 *
 * Attaches by notebook id rather than creating a worker: `createWorker` builds its upload URL
 * by concatenation and never forwards the secret, and a server without a secret lets any page
 * the browser visits run Julia on this machine.
 */
export async function connect(session: Session): Promise<Kernel> {
  const host = new Host(`${session.plutoUrl}/?secret=${session.secret}`)
  const worker = host.worker(session.notebook_id)
  if (!(await worker.connect())) {
    throw new Error(`no websocket to ${session.plutoUrl}`)
  }

  // A deck that cannot batch writes a bond per reactive run, and every run but the last sees
  // the other bonds still `missing`. Failing here beats a deck whose widgets half work.
  const writeBonds = bondWriter(worker)
  if (writeBonds === null) {
    throw new Error("this @plutojl/rainbow Worker cannot write bonds as one notebook update")
  }

  // `present` blocks until the kernel is ready, so a deck that finds it otherwise has a kernel
  // that died or parked afterwards, and restarting is the only way back.
  const kernel = new Kernel(worker, writeBonds)
  if (kernel.status !== "ready") {
    await worker.restart()
  }

  return kernel
}

/**
 * A live Pluto notebook, addressed by cell id.
 *
 * Reads are synchronous against the last state the websocket delivered; writes are bond values,
 * batched so that a burst becomes one reactive run.
 */
export class Kernel {
  readonly #worker: Worker
  #watched: readonly string[] = []
  readonly #bonds: BondQueue

  constructor(worker: Worker, writeBonds: BondWriter) {
    this.#worker = worker
    this.#bonds = new BondQueue({
      write: (pairs) =>
        writeBonds((notebook) => {
          for (const [name, value] of pairs) {
            notebook.bonds[name] = { value }
          }
        }),
      stamps: () => this.#stamps(),
      isIdle: () => this.#worker.isIdle(),
    })
  }

  /**
   * The notebook state, or null while the websocket has delivered nothing the deck can read.
   *
   * Every read goes through here: `Worker.getState()` is untyped (see `pluto.interface.ts`), so
   * this is the one place the shape is established rather than assumed.
   */
  #state(): NotebookState | null {
    const state: unknown = this.#worker.getState()
    return isNotebookState(state) ? state : null
  }

  /** `ready`, `starting`, `no_process`, or `waiting_for_permission`. */
  get status(): string {
    return this.#state()?.process_status ?? "no_process"
  }

  /** What a cell is currently showing, or `null` while it has nothing whole to show. */
  content(cellId: string): CardContent | null {
    const state = this.#state()
    const result = state?.cell_results[cellId]
    const output: unknown = isRecordLike(result) ? result.output : undefined
    if (!isCellOutput(output) || output.body === undefined || output.body === null) {
      return null
    }

    const published = state?.published_objects ?? {}
    // A body and the payloads it reaches for arrive in separate patches, and the body can be
    // first. A card painted in that window resolves `getPublishedObject` to `undefined`, and
    // the script it was handed throws — leaving a card that reports `live`, logs to a console
    // nobody is reading, and shows an empty box. Output only half here is not output.
    if (typeof output.body === "string") {
      for (const [, id] of output.body.matchAll(PUBLISHED_REFERENCE)) {
        if (id === undefined || !(id in published)) {
          return null
        }
      }
    }

    return {
      source: "live",
      stamp: output.last_run_timestamp,
      mime: output.mime,
      body: output.body,
      // Taken with the body rather than read when a script asks, because a re-run landing in
      // between replaces `published_objects` whole and takes this body's ids with it.
      published: { ...published },
      cellId,
    }
  }

  /** Payloads sent by `published_to_js`, which travel outside the cell body. */
  publishedObject(id: string): unknown {
    return this.#state()?.published_objects[id]
  }

  bonds(): NotebookState["bonds"] {
    return this.#state()?.bonds ?? {}
  }

  /**
   * Whether the notebook has a variable of this name.
   *
   * Not a question `bonds` can answer: it carries the values a browser has reported, so a bond
   * nothing has written yet is absent from it — which is exactly the bond the deck is about to
   * write. The dependency graph is where a declared name exists before it has a value.
   */
  declares(name: string): boolean {
    const dependencies = this.#state()?.cell_dependencies ?? {}
    return Object.values(dependencies).some(
      (cell) =>
        isCellDependency(cell) &&
        (name in cell.downstream_cells_map || name in cell.upstream_cells_map),
    )
  }

  notebook(): NotebookState | null {
    return this.#state()
  }

  /**
   * The cells the deck reads, which is what a run is settled against.
   *
   * Downstream cells finish after the cell they depend on, so settling against the cell a bond
   * feeds hands back the previous run's output for everything below it.
   */
  watch(cellIds: readonly (string | undefined)[]): void {
    this.#watched = [...new Set(cellIds)].filter((id): id is string => id !== undefined)
  }

  onChange(fn: (event: unknown) => void): () => void {
    return this.#worker.onUpdate(fn)
  }

  onConnectionChange(fn: (state: { connected: boolean }) => void): () => void {
    return this.#worker.onConnectionStatus(fn)
  }

  /** Set a bond, and resolve once the run it caused has finished. */
  setBond(name: string, value: unknown): Promise<void> {
    return this.#bonds.set(name, value)
  }

  #stamps(): ReadonlyMap<string, number> {
    return new Map(this.#watched.map((cellId) => [cellId, this.content(cellId)?.stamp ?? 0]))
  }
}
