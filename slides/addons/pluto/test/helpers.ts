// What the unit tests and the live suite share: a stand-in Pluto, and a process check.

import assert from "node:assert/strict"
import { execFileSync } from "node:child_process"
import { createServer } from "node:http"
import type { IncomingMessage, ServerResponse } from "node:http"

/** Whether `pid` is a process that has not exited; a zombie has, and only awaits its reaping. */
export function alive(pid: number): boolean {
  try {
    return !execFileSync("ps", ["-o", "stat=", "-p", String(pid)], { encoding: "utf8" })
      .trim()
      .startsWith("Z")
  } catch {
    return false
  }
}

/** A MessagePack map from strings to strings, as Pluto's `/notebooklist` sends it. */
export function packStringMap(entries: Record<string, string>): Uint8Array {
  const string = (text: string) => {
    const bytes = new TextEncoder().encode(text)
    const header = bytes.length < 32 ? [0xa0 | bytes.length] : [0xd9, bytes.length]
    return [...header, ...bytes]
  }
  const pairs = Object.entries(entries)
  return new Uint8Array([
    0x80 | pairs.length,
    ...pairs.flatMap(([key, value]) => [...string(key), ...string(value)]),
  ])
}

/**
 * A stand-in Pluto that lists `paths` under the ids `id0`, `id1`, …, and refuses a request without
 * `secret` when it has one.
 */
export async function fakePluto(paths: readonly string[], secret: string | null = null) {
  const server = createServer((request: IncomingMessage, response: ServerResponse) => {
    const url = new URL(request.url ?? "/", "http://localhost")
    if (secret !== null && url.searchParams.get("secret") !== secret) {
      response.writeHead(403).end()
      return
    }
    if (url.pathname !== "/notebooklist") {
      response.writeHead(404).end()
      return
    }
    response.end(packStringMap(Object.fromEntries(paths.map((path, i) => [`id${i}`, path]))))
  })
  await new Promise<void>((done) => server.listen(0, "127.0.0.1", done))
  const address = server.address()
  assert.ok(address !== null && typeof address !== "string")
  return {
    plutoUrl: `http://127.0.0.1:${address.port}`,
    close: () => new Promise((done) => server.close(done)),
  }
}
