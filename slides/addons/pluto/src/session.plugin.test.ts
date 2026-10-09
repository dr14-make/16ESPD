import assert from "node:assert/strict"
import { mkdtemp, symlink, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { test } from "node:test"
import { deckSession } from "./session.plugin.ts"

async function deck() {
  const directory = await mkdtemp(join(tmpdir(), "pluto-session-"))
  await writeFile(join(directory, "notebook.jl"), "")
  return {
    directory,
    source: (headmatter: unknown, live = true) => ({
      entry: join(directory, "slides.md"),
      headmatter: () => headmatter,
      live,
    }),
    running: {
      plutoUrl: "http://localhost:1234",
      secret: "s3cr3t42",
      notebook: join(directory, "notebook.jl"),
    },
  }
}

test("the page is told the kernel and the notebook, resolved against the deck", async () => {
  const { source, running } = await deck()

  assert.deepEqual(await deckSession(source({ pluto: { notebook: "notebook.jl" } }), running), {
    kernel: running,
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
  assert.ok("problem" in renamed && renamed.problem.includes("restart slidev"))

  for (const headmatter of [{}, { pluto: "x" }, { pluto: { notebook: 7 } }]) {
    const unnamed = await deckSession(source(headmatter), running)
    assert.ok("problem" in unnamed && unnamed.problem.includes("names no notebook"))
  }
})
