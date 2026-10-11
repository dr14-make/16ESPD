import assert from "node:assert/strict"
import { mkdtemp, symlink, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { test } from "node:test"
import { fakePluto } from "../test/helpers.ts"
import type { KernelAddress } from "./kernel.address.ts"
import type { KernelSource } from "./kernel.attach.ts"
import type { PlutoServer } from "./kernel.launcher.ts"
import { kernelSource, lookUpKernel } from "./kernel.plugin.ts"

/** A kernel source that runs exactly the notebook at `path`, at `address`. */
function serving(path: string, address: KernelAddress): KernelSource {
  return {
    locate: (notebook) =>
      Promise.resolve(notebook === path ? address : { problem: `no kernel runs ${notebook}` }),
    stop: () => Promise.resolve(),
  }
}

async function deck() {
  const directory = await mkdtemp(join(tmpdir(), "pluto-kernel-"))
  await writeFile(join(directory, "notebook.jl"), "")
  const address = { plutoUrl: "http://localhost:1234", secret: "s3cr3t42", notebookId: "1" }
  return {
    directory,
    source: (headmatter: unknown) => ({
      entry: join(directory, "slides.md"),
      headmatter: () => headmatter,
      live: true,
    }),
    address,
    running: serving(join(directory, "notebook.jl"), address),
  }
}

test("the page is told the kernel and the notebook, resolved against the deck", async () => {
  const { source, address, running } = await deck()

  assert.deepEqual(
    await lookUpKernel(source({ pluto: { notebook: "notebook.jl" } }), running),
    address,
  )
})

test("a notebook reached through a symlink is named by the file Pluto opens", async () => {
  const { directory, source, address, running } = await deck()
  await symlink(directory, `${directory}-link`)

  const found = await lookUpKernel(
    source({ pluto: { notebook: `${directory}-link/notebook.jl` } }),
    running,
  )

  assert.deepEqual(found, address)
})

test("without a kernel for its notebook, or a notebook, the page is told why", async () => {
  const { directory, source, running } = await deck()

  const absent = await lookUpKernel(source({ pluto: { notebook: "notebook.jl" } }), null)
  assert.ok("problem" in absent && absent.problem.includes("restart slidev"))

  // Named after the dev server started its kernel for another one.
  await writeFile(join(directory, "other.jl"), "")
  const renamed = await lookUpKernel(source({ pluto: { notebook: "other.jl" } }), running)
  assert.ok("problem" in renamed && renamed.problem.includes("no kernel runs"))

  for (const headmatter of [{}, { pluto: "x" }, { pluto: { notebook: 7 } }]) {
    const unnamed = await lookUpKernel(source(headmatter), running)
    assert.ok("problem" in unnamed && unnamed.problem.includes("names no notebook"))
  }
})

/**
 * A launcher that records what it was asked to start, standing in for Julia with a Pluto that
 * lists those notebooks, or with a Julia that exits without listing anything when `dies`.
 */
function fakeLauncher(dies = false) {
  const launched: string[][] = []
  const servers: { close(): Promise<unknown> }[] = []
  let stopped = 0
  const launch = async (notebooks: readonly string[]): Promise<PlutoServer> => {
    launched.push([...notebooks])
    const pluto = await fakePluto(dies ? [] : notebooks)
    servers.push(pluto)
    return {
      plutoUrl: pluto.plutoUrl,
      secret: "own",
      exited: dies ? Promise.resolve() : new Promise(() => undefined),
      stop: () => {
        stopped++
        return Promise.resolve()
      },
    }
  }
  const close = () => Promise.all(servers.map((server) => server.close()))
  return { launch, launched, stopped: () => stopped, close }
}

test("without PLUTO_URL, the deck starts its own kernel and attaches to it", async () => {
  const { launch, launched, stopped, close } = fakeLauncher()
  const lines: string[] = []

  try {
    const kernel = await kernelSource({ mode: "launch" }, "/deck/nb.jl", (l) => lines.push(l), launch)

    assert.deepEqual(launched, [["/deck/nb.jl"]])
    const located = await kernel.locate("/deck/nb.jl")
    assert.ok("notebookId" in located)
    assert.deepEqual(located, { plutoUrl: located.plutoUrl, secret: "own", notebookId: "id0" })
    const other = await kernel.locate("/deck/other.jl")
    assert.ok("problem" in other && other.problem.includes("restart slidev"))
    await kernel.stop()
    assert.equal(stopped(), 1)
  } finally {
    await close()
  }
})

test("a kernel whose Julia exits before opening the notebook says to restart", async () => {
  const { launch, close } = fakeLauncher(true)

  try {
    const kernel = await kernelSource({ mode: "launch" }, "/deck/nb.jl", () => undefined, launch)

    const located = await kernel.locate("/deck/nb.jl")
    assert.ok("problem" in located && located.problem.includes("restart slidev"))
  } finally {
    await close()
  }
})

test("with PLUTO_URL, the deck starts no kernel and warns of a server with no secret", async () => {
  const { launch, launched } = fakeLauncher()
  const lines: string[] = []
  const choice = { mode: "attach", plutoUrl: "http://127.0.0.1:9", secret: null } as const

  const kernel = await kernelSource(choice, "/deck/nb.jl", (l) => lines.push(l), launch)
  await kernel.stop()

  assert.deepEqual(launched, [])
  assert.equal(lines.filter((line) => line.startsWith("warning:")).length, 1)
  assert.match(lines.join("\n"), /any web page/)
})

test("an attached server with a secret draws no warning", async () => {
  const lines: string[] = []
  const choice = { mode: "attach", plutoUrl: "http://127.0.0.1:9", secret: "s" } as const

  await kernelSource(choice, "/deck/nb.jl", (l) => lines.push(l), fakeLauncher().launch)

  assert.ok(!lines.some((line) => line.startsWith("warning:")))
})

test("a malformed PLUTO_URL starts nothing, and says why in the terminal and on the page", async () => {
  const { launch, launched } = fakeLauncher()
  const lines: string[] = []
  const choice = { mode: "invalid", problem: "PLUTO_URL x is not a URL" } as const

  const kernel = await kernelSource(choice, "/deck/nb.jl", (l) => lines.push(l), launch)

  assert.deepEqual(launched, [])
  assert.deepEqual(lines, ["PLUTO_URL x is not a URL"])
  assert.deepEqual(await kernel.locate("/deck/nb.jl"), { problem: "PLUTO_URL x is not a URL" })
})
