import assert from "node:assert/strict"
import { test } from "node:test"
import { isDeckSession, notebookIdAt } from "./deck.session.ts"

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

test("a session is either a kernel's address or the reason there is none", () => {
  const kernel = { plutoUrl: "http://localhost:1234", secret: "s", notebook: "/n.jl", owned: true }
  assert.ok(isDeckSession({ kernel }))
  assert.ok(isDeckSession({ kernel: { ...kernel, secret: null, owned: false } }))
  assert.ok(isDeckSession({ problem: "a built deck has no kernel" }))
  assert.ok(!isDeckSession({ kernel: { plutoUrl: "http://localhost:1234", secret: "s" } }))
  assert.ok(!isDeckSession({ kernel: { ...kernel, owned: undefined } }))
  assert.ok(!isDeckSession(null))
})
