import assert from "node:assert/strict"
import { mkdtemp, symlink, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { test } from "node:test"
import type { KernelAddress } from "./deck.session.ts"
import type { KernelSource } from "./kernel.attach.ts"
import type { PlutoServer } from "./kernel.launcher.ts"
import { deckSession, kernelSource } from "./session.plugin.ts"

/** A kernel source that runs exactly the notebook at `address.notebook`. */
function serving(address: KernelAddress): KernelSource {
  return {
    locate: (notebook) =>
      Promise.resolve(
        notebook === address.notebook ? address : { problem: `no kernel runs ${notebook}` },
      ),
    stop: () => Promise.resolve(),
  }
}

async function deck() {
  const directory = await mkdtemp(join(tmpdir(), "pluto-session-"))
  await writeFile(join(directory, "notebook.jl"), "")
  const address = {
    plutoUrl: "http://localhost:1234",
    secret: "s3cr3t42",
    notebook: join(directory, "notebook.jl"),
    owned: true,
  }
  return {
    directory,
    source: (headmatter: unknown, live = true) => ({
      entry: join(directory, "slides.md"),
      headmatter: () => headmatter,
      live,
    }),
    address,
    running: serving(address),
  }
}

test("the page is told the kernel and the notebook, resolved against the deck", async () => {
  const { source, address, running } = await deck()

  assert.deepEqual(await deckSession(source({ pluto: { notebook: "notebook.jl" } }), running), {
    kernel: address,
  })
})

test("a notebook reached through a symlink is named by the file Pluto opens", async () => {
  const { directory, source, running } = await deck()
  await symlink(directory, `${directory}-link`)

  const session = await deckSession(
    source({ pluto: { notebook: `${directory}-link/notebook.jl` } }),
    running,
  )

  assert.ok("kernel" in session)
  assert.equal(session.kernel.notebook, join(directory, "notebook.jl"))
})

test("a built deck carries neither the secret nor a path", async () => {
  const { source, running } = await deck()

  const session = await deckSession(source({ pluto: { notebook: "notebook.jl" } }, false), running)

  assert.deepEqual(session, { problem: "a built deck has no kernel" })
})

test("without a kernel for its notebook, or a notebook, the page is told why", async () => {
  const { directory, source, running } = await deck()

  const absent = await deckSession(source({ pluto: { notebook: "notebook.jl" } }), null)
  assert.ok("problem" in absent && absent.problem.includes("restart slidev"))

  // Named after the dev server started its kernel for another one.
  await writeFile(join(directory, "other.jl"), "")
  const renamed = await deckSession(source({ pluto: { notebook: "other.jl" } }), running)
  assert.ok("problem" in renamed && renamed.problem.includes("no kernel runs"))

  for (const headmatter of [{}, { pluto: "x" }, { pluto: { notebook: 7 } }]) {
    const unnamed = await deckSession(source(headmatter), running)
    assert.ok("problem" in unnamed && unnamed.problem.includes("names no notebook"))
  }
})

/** A launcher that records what it was asked to start, standing in for Julia. */
function fakeLauncher() {
  const launched: string[][] = []
  let stopped = 0
  const launch = (notebooks: readonly string[]): Promise<PlutoServer> => {
    launched.push([...notebooks])
    return Promise.resolve({
      plutoUrl: "http://localhost:4321",
      secret: "own",
      ready: Promise.resolve(true),
      stop: () => {
        stopped++
        return Promise.resolve()
      },
    })
  }
  return { launch, launched, stopped: () => stopped }
}

test("without PLUTO_URL, the deck starts its own kernel and may restart it", async () => {
  const { launch, launched, stopped } = fakeLauncher()
  const lines: string[] = []

  const kernel = await kernelSource({ mode: "launch" }, "/deck/nb.jl", (l) => lines.push(l), launch)

  assert.deepEqual(launched, [["/deck/nb.jl"]])
  assert.deepEqual(await kernel.locate("/deck/nb.jl"), {
    plutoUrl: "http://localhost:4321",
    secret: "own",
    notebook: "/deck/nb.jl",
    owned: true,
  })
  const other = await kernel.locate("/deck/other.jl")
  assert.ok("problem" in other && other.problem.includes("restart slidev"))
  await kernel.stop()
  assert.equal(stopped(), 1)
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
