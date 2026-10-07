import { spawnSync } from "node:child_process"
import { existsSync, readdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

export const WORKSPACE = dirname(dirname(fileURLToPath(import.meta.url)))
export const DIST = process.env.DECKS_DIST ?? join(WORKSPACE, "dist")

/** Every folder in the workspace holding a `slides.md` is a deck, named after the folder. */
export function decks() {
  return readdirSync(WORKSPACE, { withFileTypes: true })
    .filter((e) => e.isDirectory() && e.name !== "node_modules" && e.name !== "dist")
    .filter((e) => existsSync(join(WORKSPACE, e.name, "slides.md")))
    .map((e) => e.name)
    .sort()
}

/** The published URL of a deck is `/16ESPD/<deck>/`, which links already given out rely on. */
export function build(deck, { pdf = false } = {}) {
  const entry = join(deck, "slides.md")
  const out = join(DIST, deck)
  run(["build", entry, "--base", `/16ESPD/${deck}/`, "--out", out])
  if (pdf) run(["export", entry, "--output", join(out, "handout.pdf")])
}

function run(args) {
  const slidev = join(WORKSPACE, "node_modules", ".bin", "slidev")
  const result = spawnSync(slidev, args, { cwd: WORKSPACE, stdio: "inherit" })
  if (result.status !== 0) throw new Error(`slidev ${args.join(" ")} exited with ${result.status}`)
}
