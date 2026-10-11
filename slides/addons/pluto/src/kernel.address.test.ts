import assert from "node:assert/strict"
import { test } from "node:test"
import { isKernelLookup, secretQuery } from "./kernel.address.ts"

test("the page is handed either a kernel's address or the reason there is none", () => {
  const address = { plutoUrl: "http://localhost:1234", secret: "s", notebookId: "1" }
  assert.ok(isKernelLookup(address))
  assert.ok(isKernelLookup({ ...address, secret: null }))
  assert.ok(isKernelLookup({ problem: "no kernel runs /n.jl" }))
  assert.ok(!isKernelLookup({ plutoUrl: "http://localhost:1234", secret: "s" }))
  assert.ok(!isKernelLookup({ ...address, secret: undefined }))
  assert.ok(!isKernelLookup({ kernel: address }))
  assert.ok(!isKernelLookup(null))
})

test("a secret travels as a query parameter, escaped, and no secret as no query", () => {
  assert.equal(secretQuery("a/b c"), "?secret=a%2Fb%20c")
  assert.equal(secretQuery(null), "")
})
