import assert from "node:assert/strict"
import { test } from "node:test"
import { kernelState } from "./kernel.status.ts"

// The states a live kernel does not pass through, which the live suite cannot reach without
// taking the kernel down and ending its own run.
test("every kernel state a window can be in maps to one of four", () => {
  assert.equal(kernelState({ process: null }), "connecting")
  assert.equal(kernelState({ process: "starting" }), "connecting")
  assert.equal(kernelState({ process: "ready" }), "ready")
  assert.equal(kernelState({ connected: false, process: "ready" }), "offline")
  assert.equal(kernelState({ process: "no_process" }), "offline")
  assert.equal(kernelState({ process: "waiting_for_permission" }), "error")
  assert.equal(kernelState({ failure: "no websocket" }), "error")
})

test("a status Pluto grows later is an error rather than a silent ready", () => {
  assert.equal(kernelState({ process: "some_new_state" }), "error")
})

test("a connection that dropped outranks whatever the process last reported", () => {
  assert.equal(kernelState({ connected: false, process: "starting" }), "offline")
})
