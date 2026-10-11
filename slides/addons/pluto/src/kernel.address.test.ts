import assert from "node:assert/strict"
import { test } from "node:test"
import { isKernelLookup, notebookIdAt } from "./kernel.address.ts"

// Pluto's own `notebook_list` entries, which is what `Host.workers()` resolves to.
const listed = [
  { notebook_id: "1", path: "/decks/a/notebook.jl", shortpath: "notebook.jl", in_temp_dir: false },
  { notebook_id: "2", path: "/decks/b/notebook.jl", shortpath: "notebook.jl", in_temp_dir: false },
]

test("a deck finds its notebook by path, not by file name", () => {
  assert.equal(notebookIdAt(listed, "/decks/b/notebook.jl"), "2")
})

test("a notebook Pluto is not running is not found", () => {
  assert.equal(notebookIdAt(listed, "/decks/c/notebook.jl"), null)
  // rainbow resolves a failed request to an empty list.
  assert.equal(notebookIdAt([], "/decks/a/notebook.jl"), null)
  assert.equal(notebookIdAt(undefined, "/decks/a/notebook.jl"), null)
})

test("the page is handed either a kernel's address or the reason there is none", () => {
  const address = { plutoUrl: "http://localhost:1234", secret: "s", notebook: "/n.jl", owned: true }
  assert.ok(isKernelLookup(address))
  assert.ok(isKernelLookup({ ...address, secret: null, owned: false }))
  assert.ok(isKernelLookup({ problem: "no kernel runs /n.jl" }))
  assert.ok(!isKernelLookup({ plutoUrl: "http://localhost:1234", secret: "s" }))
  assert.ok(!isKernelLookup({ ...address, owned: undefined }))
  assert.ok(!isKernelLookup({ kernel: address }))
  assert.ok(!isKernelLookup(null))
})
