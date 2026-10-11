import assert from "node:assert/strict"
import { mkdtemp, symlink, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { test } from "node:test"
import { fakePluto, packStringMap } from "../test/helpers.ts"
import { attachPluto, kernelChoice, stringMapEntries } from "./kernel.attach.ts"

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

test("a notebook list reads as its ids and paths, and anything else as nothing", () => {
  const long = `/${"x".repeat(200)}.jl`
  assert.deepEqual(stringMapEntries(packStringMap({ a: "/one.jl", b: long })), [
    ["a", "/one.jl"],
    ["b", long],
  ])
  assert.deepEqual(stringMapEntries(packStringMap({})), [])
  assert.equal(stringMapEntries(new TextEncoder().encode("<html>")), null)
  assert.equal(stringMapEntries(packStringMap({ a: "/one.jl" }).subarray(0, 5)), null)
})

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

    assert.deepEqual(located, { plutoUrl: pluto.plutoUrl, secret: null, notebookId: "id1" })
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
    assert.ok("notebookId" in right && right.secret === "right")

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
