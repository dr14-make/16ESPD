// Reaching the batched bond write that Pluto's client marks private.
//
// `Worker.setBond` sends its own `update_notebook`, so setting six bonds through it is six
// reactive runs, and the first five see bonds that are still `missing`. The method that takes a
// whole batch is the one the deck needs and the one rainbow does not publish, which makes this
// the single place a `@plutojl/rainbow` upgrade can break the deck quietly.

import type { MutableNotebookState } from "./pluto.interface.js"

/** Writes a whole batch of bonds as one notebook update. */
export type BondWriter = (mutate: (notebook: MutableNotebookState) => void) => Promise<void>

/**
 * The batched write `worker` offers, or null when it offers none.
 *
 * Taken by name rather than through the published type, so that a rename upstream is a null
 * here — something a caller can report — rather than a call on `undefined` at the first bond a
 * lecturer touches.
 */
export function bondWriter(worker: unknown): BondWriter | null {
  if (typeof worker !== "object" || worker === null) {
    return null
  }
  const write: unknown = Reflect.get(worker, "_update_notebook_state")
  if (typeof write !== "function") {
    return null
  }
  return async (mutate) => {
    await Reflect.apply(write, worker, [mutate])
  }
}
