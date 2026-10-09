import assert from "node:assert/strict"
import { test } from "node:test"
import { BondQueue } from "./bond.queue.ts"

/** A notebook that re-runs on every write, which is the ordinary case a slider produces. */
function reactiveNotebook() {
  const updates: string[][] = []
  let stamp = 0
  const queue = new BondQueue({
    write: (pairs) => {
      updates.push(pairs.map(([name]) => name))
      stamp += 1
      return Promise.resolve()
    },
    stamps: () => new Map([["watched-cell", stamp]]),
    isIdle: () => true,
  })
  return { queue, updates }
}

test("a burst of bond changes is one notebook update, not six", async () => {
  const { queue, updates } = reactiveNotebook()

  // Every widget reports its own value as its card's scripts finish, so this is the shape a
  // page load produces. Six updates would be six reactive runs, and the first five would see
  // every other bond still `missing`.
  await Promise.all(
    ["a", "b", "c", "d", "e", "f"].map((name, index) => queue.set(name, index)),
  )

  assert.equal(updates.length, 1)
  assert.deepEqual(updates[0], ["a", "b", "c", "d", "e", "f"])
})

test("a value set while a run is settling is written after it, not folded into it", async () => {
  const { queue, updates } = reactiveNotebook()

  const first = queue.set("freq", 1)
  await first
  await queue.set("freq", 2)

  assert.equal(updates.length, 2)
  assert.deepEqual(updates, [["freq"], ["freq"]])
})

test("the last value of a name wins inside one batch", async () => {
  const written: unknown[][] = []
  let stamp = 0
  const queue = new BondQueue({
    write: (pairs) => {
      written.push(pairs.map(([, value]) => value))
      stamp += 1
      return Promise.resolve()
    },
    stamps: () => new Map([["watched-cell", stamp]]),
    isIdle: () => true,
  })

  // A dragged slider fires faster than the collecting window, and the kernel is owed where the
  // hand stopped rather than every position it passed through.
  await Promise.all([queue.set("freq", 1), queue.set("freq", 2), queue.set("freq", 3)])

  assert.deepEqual(written, [[3]])
})

test("a bond that re-runs nothing is let go rather than waited on forever", async () => {
  const updates: string[][] = []
  const queue = new BondQueue({
    write: (pairs) => {
      updates.push(pairs.map(([name]) => name))
      return Promise.resolve()
    },
    // No stamp ever advances: the value was already what the notebook held.
    stamps: () => new Map([["watched-cell", 7]]),
    isIdle: () => true,
  })

  await queue.set("deck_theme", "light")

  assert.equal(updates.length, 1)
})

test("idle is not believed while the server is still reporting a run", async () => {
  let idle = false
  let stamp = 0
  const settled: number[] = []
  const queue = new BondQueue({
    write: () => {
      stamp += 1
      // `isIdle()` is true in the window between sending a bond and the server starting the
      // run, so a queue that believed it immediately would settle before anything had run.
      setTimeout(() => {
        idle = true
      }, 150)
      return Promise.resolve()
    },
    stamps: () => new Map([["watched-cell", stamp]]),
    isIdle: () => idle,
  })

  const started = Date.now()
  await queue.set("freq", 4)
  settled.push(Date.now() - started)

  assert.ok(idle, "the run had to be reported finished before the write resolved")
  assert.ok(settled[0] !== undefined && settled[0] >= 150)
})
