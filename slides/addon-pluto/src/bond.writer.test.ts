import assert from "node:assert/strict"
import { test } from "node:test"
import { bondWriter } from "./bond.writer.ts"
import type { MutableNotebookState } from "./pluto.interface.ts"

test("a worker offering no batched write is reported rather than called", () => {
  // The branch that turns a `@plutojl/rainbow` rename into a legible message at connect time,
  // instead of a deck whose widgets half work in front of a room.
  assert.equal(bondWriter({}), null)
  assert.equal(bondWriter({ _update_notebook_state: "not a function" }), null)
  assert.equal(bondWriter(null), null)
  assert.equal(bondWriter(undefined), null)
})

test("the whole batch reaches the notebook as one update", async () => {
  const updates: string[][] = []
  const worker = {
    _update_notebook_state(mutate: (notebook: MutableNotebookState) => void) {
      const notebook: MutableNotebookState = { bonds: {} }
      mutate(notebook)
      updates.push(Object.keys(notebook.bonds))
      return Promise.resolve()
    },
  }

  const write = bondWriter(worker)
  assert.ok(write !== null)
  await write((notebook) => {
    notebook.bonds.freq = { value: 4 }
    notebook.bonds.deck_theme = { value: "dark" }
  })

  assert.deepEqual(updates, [["freq", "deck_theme"]])
})

test("the write is applied to the worker, not to a detached function", async () => {
  // `Reflect.get` hands back an unbound method, so a writer that forgot the receiver would work
  // against a stub holding no state and fail against the real client, which keeps the notebook
  // on `this`.
  const worker = {
    seen: 0,
    _update_notebook_state() {
      this.seen += 1
      return Promise.resolve()
    },
  }

  const write = bondWriter(worker)
  assert.ok(write !== null)
  await write(() => undefined)

  assert.equal(worker.seen, 1)
})
