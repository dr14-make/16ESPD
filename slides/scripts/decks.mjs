import { spawnSync } from "node:child_process"
import { existsSync, readdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

export const WORKSPACE = dirname(dirname(fileURLToPath(import.meta.url)))
export const DECKS = join(WORKSPACE, "decks")
export const DIST = join(WORKSPACE, "dist")

/** Every folder in `decks/` holding a `slides.md` is a deck, named after the folder. */
export function decks() {
  return readdirSync(DECKS, { withFileTypes: true })
    .filter((e) => e.isDirectory() && existsSync(join(DECKS, e.name, "slides.md")))
    .map((e) => e.name)
    .sort()
}

/** The published URL of a deck is `/16ESPD/<deck>/`, which links already given out rely on. */
export function build(deck) {
  slidev(["build", join(DECKS, deck, "slides.md"), "--base", `/16ESPD/${deck}/`, "--out", join(DIST, deck)])
}

/** The handout is the deck's slides as a PDF, published beside the built deck. */
export function exportHandout(deck) {
  slidev(["export", join(DECKS, deck, "slides.md"), "--output", join(DIST, deck, "handout.pdf")])
}

function slidev(args) {
  const bin = join(WORKSPACE, "node_modules", ".bin", "slidev")
  const result = spawnSync(bin, args, { cwd: WORKSPACE, stdio: "inherit" })
  if (result.status !== 0) throw new Error(`slidev ${args.join(" ")} exited with ${result.status}`)
}
