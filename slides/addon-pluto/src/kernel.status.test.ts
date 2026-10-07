import assert from "node:assert/strict"
import { test } from "node:test"
import { kernelStatus } from "./kernel.status.ts"

// The states a live kernel does not pass through, which the browser suite cannot reach without
// taking the kernel down and ending its own run.
test("every kernel state the chrome can be in maps to one of four", () => {
  assert.equal(kernelStatus({ process: null }).state, "connecting")
  assert.equal(kernelStatus({ process: "starting" }).state, "connecting")
  assert.equal(kernelStatus({ process: "ready" }).state, "ready")
  assert.equal(kernelStatus({ connected: false, process: "ready" }).state, "offline")
  assert.equal(kernelStatus({ process: "no_process" }).state, "offline")
  assert.equal(kernelStatus({ failure: "no websocket" }).state, "error")
})

test("a failure is reported as what it was, not as a state name", () => {
  assert.equal(kernelStatus({ failure: "no websocket to :1234" }).message, "no websocket to :1234")
})

test("a status Pluto grows later is an error naming itself rather than a silent ready", () => {
  const status = kernelStatus({ process: "some_new_state" })

  assert.equal(status.state, "error")
  assert.match(status.message, /some new state/)
})

test("a connection that dropped outranks whatever the process last reported", () => {
  assert.equal(kernelStatus({ connected: false, process: "starting" }).state, "offline")
})
