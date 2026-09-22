import assert from "node:assert/strict"
import { test } from "node:test"
import { isolate } from "./published.helper.ts"

test("one draw's writes do not reach the next draw", () => {
  // PlutoPlotly appends its modebar buttons to the payload's `config` on every draw, and Plotly
  // aborts a draw on a duplicate button name after attaching the traces and before painting a
  // line. A card placed on two slides draws twice.
  const payload = { config: { modeBarButtons: ["zoom"] } }

  const first = isolate(payload)
  assert.ok(first !== null && typeof first === "object" && "config" in first)
  const config: unknown = first.config
  assert.ok(config !== null && typeof config === "object" && "modeBarButtons" in config)
  assert.ok(Array.isArray(config.modeBarButtons))
  config.modeBarButtons.push("copyPng")

  assert.deepEqual(payload.config.modeBarButtons, ["zoom"])
})

test("what is expensive is shared rather than copied", () => {
  // The offline Plotly bundle is a 3.82 MB string and a trace's coordinates are typed arrays,
  // so copying a payload per draw is not the fix it looks like.
  const coordinates = new Float64Array([1, 2, 3])
  const library = "a".repeat(1024)
  const payload = { data: [{ x: coordinates }], library }

  const copy = isolate(payload)
  assert.ok(copy !== null && typeof copy === "object" && "data" in copy && "library" in copy)
  assert.equal(copy.library, library)
  assert.ok(Array.isArray(copy.data))
  const trace: unknown = copy.data[0]
  assert.ok(trace !== null && typeof trace === "object" && "x" in trace)
  assert.equal(trace.x, coordinates, "a typed array is passed by reference, never copied")
})

test("an instance of something is handed over as it is", () => {
  const date = new Date(0)

  assert.equal(isolate(date), date)
})
