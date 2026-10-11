import assert from "node:assert/strict"
import { test } from "node:test"
import { setTimeout as sleep } from "node:timers/promises"
import { alive } from "../test/helpers.ts"
import { supervise } from "./kernel.launcher.ts"

// A child that ignores its stdin and starts a grandchild in a session of its own, the way Pluto
// starts a notebook's worker.
const PARENT = `
  const { spawn } = require("node:child_process")
  const worker = spawn(process.execPath, ["-e", "setInterval(() => {}, 1000)"], {
    detached: true,
    stdio: "ignore",
  })
  console.log(worker.pid)
  setInterval(() => {}, 1000)
`

test("stopping takes down a grandchild in a session of its own", { timeout: 15_000 }, async () => {
  const lines: string[] = []
  const child = supervise(process.execPath, ["-e", PARENT], (line) => lines.push(line), 200)
  while (lines.length === 0) {
    await sleep(20)
  }
  const worker = Number(lines[0])
  assert.ok(alive(worker))

  await child.stop()

  const deadline = Date.now() + 5_000
  while (alive(worker) && Date.now() < deadline) {
    await sleep(50)
  }
  assert.ok(!alive(worker), `worker ${worker} outlived stop()`)
})
