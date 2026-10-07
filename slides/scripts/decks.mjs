import { spawnSync } from "node:child_process"
import { existsSync, readdirSync, readFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { parseSync } from "@slidev/parser/core"

export const WORKSPACE = dirname(dirname(fileURLToPath(import.meta.url)))
export const DIST = join(WORKSPACE, "dist")

/** Every folder in the workspace holding a `slides.md` is a deck, named after the folder. */
export function decks() {
  return readdirSync(WORKSPACE, { withFileTypes: true })
    .filter((e) => e.isDirectory() && existsSync(join(WORKSPACE, e.name, "slides.md")))
    .map((e) => e.name)
    .sort()
}

/**
 * The decks that are built and published. A live deck names its notebook in its headmatter and is
 * presented against a running kernel; built without one, every card would stay a placeholder.
 */
export function staticDecks() {
  return decks().filter((deck) => {
    const file = join(WORKSPACE, deck, "slides.md")
    const { frontmatter } = parseSync(readFileSync(file, "utf8"), file).slides[0] ?? {}
    return frontmatter?.pluto?.notebook == null
  })
}

/** The published URL of a deck is `/16ESPD/<deck>/`, which links already given out rely on. */
export function build(deck) {
  slidev(["build", join(deck, "slides.md"), "--base", `/16ESPD/${deck}/`, "--out", join(DIST, deck)])
}

/** The handout is the deck's slides as a PDF, published beside the built deck. */
export function exportHandout(deck) {
  slidev(["export", join(deck, "slides.md"), "--output", join(DIST, deck, "handout.pdf")])
}

function slidev(args) {
  const bin = join(WORKSPACE, "node_modules", ".bin", "slidev")
  const result = spawnSync(bin, args, { cwd: WORKSPACE, stdio: "inherit" })
  if (result.status !== 0) throw new Error(`slidev ${args.join(" ")} exited with ${result.status}`)
}
