import assert from "node:assert/strict"
import { mkdtemp, symlink, writeFile } from "node:fs/promises"
import { createServer } from "node:http"
import type { IncomingMessage, ServerResponse } from "node:http"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { test } from "node:test"
import { attachPluto, kernelChoice, stringMapValues } from "./kernel.attach.ts"

test("no PLUTO_URL launches the deck's own kernel", () => {
  assert.deepEqual(kernelChoice({}), { mode: "launch" })
  assert.deepEqual(kernelChoice({ PLUTO_URL: " ", PLUTO_SECRET: "s" }), { mode: "launch" })
})

test("PLUTO_URL attaches, with or without a secret", () => {
  assert.deepEqual(kernelChoice({ PLUTO_URL: "http://localhost:1234" }), {
    mode: "attach",
    plutoUrl: "http://localhost:1234",
    secret: null,
  })
  assert.deepEqual(kernelChoice({ PLUTO_URL: "http://localhost:1234/", PLUTO_SECRET: "abc" }), {
    mode: "attach",
    plutoUrl: "http://localhost:1234",
    secret: "abc",
  })
})

test("a secret in PLUTO_URL, as Pluto prints it, is taken from the URL", () => {
  assert.deepEqual(kernelChoice({ PLUTO_URL: "http://localhost:1234/?secret=a%2Fb" }), {
    mode: "attach",
    plutoUrl: "http://localhost:1234",
    secret: "a/b",
  })
  assert.deepEqual(
    kernelChoice({ PLUTO_URL: "http://localhost:1234/pluto/?secret=x", PLUTO_SECRET: "x" }),
    { mode: "attach", plutoUrl: "http://localhost:1234/pluto", secret: "x" },
  )
})

test("a PLUTO_URL that cannot be attached to is refused, not launched around", () => {
  for (const env of [
    { PLUTO_URL: "localhost:1234" },
    { PLUTO_URL: "not a url" },
    { PLUTO_URL: "http://localhost:1234/?secret=a", PLUTO_SECRET: "b" },
  ]) {
    assert.equal(kernelChoice(env).mode, "invalid", JSON.stringify(env))
  }
})

/** A MessagePack map from strings to strings, as Pluto's `/notebooklist` sends it. */
function packStringMap(entries: Record<string, string>): Uint8Array {
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

test("a notebook list reads as its paths, and anything else as nothing", () => {
  const long = `/${"x".repeat(200)}.jl`
  assert.deepEqual(stringMapValues(packStringMap({ a: "/one.jl", b: long })), ["/one.jl", long])
  assert.deepEqual(stringMapValues(packStringMap({})), [])
  assert.equal(stringMapValues(new TextEncoder().encode("<html>")), null)
  assert.equal(stringMapValues(packStringMap({ a: "/one.jl" }).subarray(0, 5)), null)
})

/** A stand-in Pluto that lists `paths`, and refuses a request without `secret` when it has one. */
async function fakePluto(paths: string[], secret: string | null = null) {
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

async function notebookBehindSymlink() {
  const directory = await mkdtemp(join(tmpdir(), "pluto-attach-"))
  const notebook = join(directory, "notebook.jl")
  await writeFile(notebook, "")
  await symlink(directory, `${directory}-link`)
  return { notebook, linked: `${directory}-link/notebook.jl` }
}

test("an attached server is found running the deck's notebook through a symlink", async () => {
  const { notebook, linked } = await notebookBehindSymlink()
  const pluto = await fakePluto(["/elsewhere.jl", linked])
  try {
    const located = await attachPluto({ plutoUrl: pluto.plutoUrl, secret: null }).locate(notebook)

    // The path as Pluto lists it, since that is what the page matches the notebook list against.
    assert.deepEqual(located, {
      plutoUrl: pluto.plutoUrl,
      secret: null,
      notebook: linked,
      owned: false,
    })
  } finally {
    await pluto.close()
  }
})

test("an attached server that has not opened the notebook says so", async () => {
  const { notebook } = await notebookBehindSymlink()
  const pluto = await fakePluto(["/elsewhere.jl"])
  try {
    const located = await attachPluto({ plutoUrl: pluto.plutoUrl, secret: null }).locate(notebook)

    assert.ok("problem" in located && located.problem.includes(`has not opened ${notebook}`))
  } finally {
    await pluto.close()
  }
})

test("an attached server's secret is sent, and a refusal names PLUTO_SECRET", async () => {
  const { notebook } = await notebookBehindSymlink()
  const pluto = await fakePluto([notebook], "right")
  try {
    const right = await attachPluto({ plutoUrl: pluto.plutoUrl, secret: "right" }).locate(notebook)
    assert.ok("owned" in right && right.secret === "right")

    const wrong = await attachPluto({ plutoUrl: pluto.plutoUrl, secret: null }).locate(notebook)
    assert.ok("problem" in wrong && wrong.problem.includes("PLUTO_SECRET"))
  } finally {
    await pluto.close()
  }
})

test("no server at PLUTO_URL is reported, not waited on", async () => {
  const pluto = await fakePluto([])
  await pluto.close()

  const located = await attachPluto({ plutoUrl: pluto.plutoUrl, secret: null }).locate("/nb.jl")

  assert.deepEqual(located, { problem: `no Pluto server answers at ${pluto.plutoUrl}` })
})
