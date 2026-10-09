// Writing bond values so that a burst becomes one reactive run.
//
// Two rules, both of which were a silent failure in the spike first: what a burst of bond
// changes becomes, and when a reactive run counts as over.

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

/** What the queue needs of the notebook it is writing to. */
export interface BondQueueDriver {
  /**
   * Write the whole batch as one notebook update.
   *
   * `Worker.setBond` sends its own `update_notebook`, so setting six bonds through it is six
   * reactive runs, and the first five see bonds that are still `missing`.
   */
  write(pairs: readonly (readonly [string, unknown])[]): Promise<void>

  /** The watched cells' `last_run_timestamp`s, which is what a finished run is measured by. */
  stamps(): ReadonlyMap<string, number>

  /** Whether the server reports no run in progress. */
  isIdle(): boolean
}

export class BondQueue {
  readonly #driver: BondQueueDriver
  readonly #pending = new Map<string, unknown>()
  #flush: Promise<void> | null = null

  constructor(driver: BondQueueDriver) {
    this.#driver = driver
  }

  /**
   * Set a bond, and resolve once the run it caused has finished.
   *
   * Resolving late is what paces a dragged slider: Pluto's bond listener awaits this before it
   * sends the next value, so the notebook runs once per settled value instead of once per
   * input event.
   */
  set(name: string, value: unknown): Promise<void> {
    this.#pending.set(name, value)
    this.#flush ??= this.#drain()
    return this.#flush
  }

  async #drain(): Promise<void> {
    try {
      while (this.#pending.size > 0) {
        // Each widget reports its own value as its card's scripts finish, so writing the first
        // one the moment it arrives makes it a reactive run of its own — and that run sees every
        // other bond still `missing`. A short collecting window turns the burst into one run.
        await new Promise((resolve) => setTimeout(resolve, BATCH_MS))
        const batch = [...this.#pending]
        this.#pending.clear()
        const before = this.#driver.stamps()
        await this.#driver.write(batch)
        await this.#settle(before)
      }
    } finally {
      this.#flush = null
    }
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
  #settle(before: ReadonlyMap<string, number>): Promise<void> {
    const started = Date.now()
    const seen = new Map(before)
    let idleSince: number | null = null
    let lastChange = started

    return new Promise((resolve) => {
      const tick = (): void => {
        const now = this.#driver.stamps()
        let advanced = false
        for (const [cellId, stamp] of seen) {
          const current = now.get(cellId) ?? 0
          if (current !== stamp) {
            seen.set(cellId, current)
            lastChange = Date.now()
          }
          if (current > (before.get(cellId) ?? 0)) {
            advanced = true
          }
        }

        idleSince = this.#driver.isIdle() ? (idleSince ?? Date.now()) : null
        const quiet = Math.min(
          idleSince === null ? 0 : Date.now() - idleSince,
          Date.now() - lastChange,
        )

        if (quiet >= (advanced ? QUIET_MS : NO_RUN_MS) || Date.now() - started > SETTLE_TIMEOUT_MS) {
          resolve()
          return
        }
        setTimeout(tick, POLL_MS)
      }
      setTimeout(tick, POLL_MS)
    })
  }
}
