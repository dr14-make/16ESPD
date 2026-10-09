import assert from "node:assert/strict"
import { test } from "node:test"
import { cardIndex, lookUpCard } from "./card.index.ts"

const cell = (code: string, metadata: Record<string, unknown> = {}) => ({ code, metadata })

test("a card name addresses the one cell that declares it", () => {
  const index = cardIndex({
    a: cell("@bind freq Slider(1:5)", { card: "frequency" }),
    b: cell("scratch = 1 + 1"),
    c: cell("plot(t, v)", { card: "wave", disabled: false }),
  })

  assert.deepEqual(lookUpCard(index, "frequency"), { cellId: "a" })
  assert.deepEqual(lookUpCard(index, "wave"), { cellId: "c" })
  assert.deepEqual(Object.keys(index.cards).sort(), ["frequency", "wave"])
})

test("a name no cell declares is unknown", () => {
  const index = cardIndex({ a: cell("x = 1", { card: "x" }) })

  assert.deepEqual(lookUpCard(index, "not-in-the-notebook"), { fault: "unknown" })
  // A name is looked up as data, never through the prototype.
  assert.deepEqual(lookUpCard(index, "constructor"), { fault: "unknown" })
})

test("a name two cells declare addresses neither, and names both", () => {
  const index = cardIndex({
    b: cell("md\"first\"", { card: "metrics" }),
    a: cell("md\"second\"", { card: "metrics" }),
    c: cell("y = 2", { card: "other" }),
  })

  assert.deepEqual(lookUpCard(index, "metrics"), { fault: "duplicate", cellIds: ["a", "b"] })
  assert.ok(!("metrics" in index.cards))
  assert.deepEqual(lookUpCard(index, "other"), { cellId: "c" })
})

test("a card key that cannot be written as a name publishes nothing", () => {
  const index = cardIndex({
    a: cell("x = 1", { card: true }),
    b: cell("x = 2", { card: "  " }),
    c: cell("x = 3", { card: 3 }),
    d: { code: "x = 4" },
    e: "not a cell",
  })

  assert.deepEqual(index, { cards: {}, duplicates: {} })
})
