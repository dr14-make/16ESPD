import assert from "node:assert/strict"
import { mkdtemp, symlink, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { test } from "node:test"
import { deckSession } from "./session.plugin.ts"

const SESSION = JSON.stringify({ plutoUrl: "http://localhost:1234", secret: "s3cr3t42" })

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
  }
}

test("the page is told the kernel and the notebook, resolved against the deck", async () => {
  const { directory, source } = await deck()

  assert.deepEqual(await deckSession(source({ pluto: { notebook: "notebook.jl" } }), SESSION), {
    kernel: { plutoUrl: "http://localhost:1234", secret: "s3cr3t42", notebook: join(directory, "notebook.jl") },
  })
})

test("a notebook reached through a symlink is named by the file Pluto opens", async () => {
  const { directory, source } = await deck()
  await symlink(directory, `${directory}-link`)

  const session = await deckSession(
    source({ pluto: { notebook: `${directory}-link/notebook.jl` } }),
    SESSION,
  )

  assert.ok("kernel" in session)
  assert.equal(session.kernel.notebook, join(directory, "notebook.jl"))
})

test("a built deck carries neither the secret nor a path", async () => {
  const { source } = await deck()

  const session = await deckSession(source({ pluto: { notebook: "notebook.jl" } }, false), SESSION)

  assert.deepEqual(session, { problem: "a built deck has no kernel" })
})

test("without a session file, or a notebook, the page is told why it has no kernel", async () => {
  const { source } = await deck()

  const absent = await deckSession(source({ pluto: { notebook: "notebook.jl" } }), null)
  assert.ok("problem" in absent && absent.problem.includes("no kernel is running"))

  for (const headmatter of [{}, { pluto: "x" }, { pluto: { notebook: 7 } }]) {
    const unnamed = await deckSession(source(headmatter), SESSION)
    assert.ok("problem" in unnamed && unnamed.problem.includes("names no notebook"))
  }

  const garbled = await deckSession(source({ pluto: { notebook: "notebook.jl" } }), "{")
  assert.ok("problem" in garbled && garbled.problem.includes("not JSON"))
})
