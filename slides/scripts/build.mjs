// Exports every deck's handout into the build `check` made, then assembles the published site in
// dist/: the built decks, the landing page, and each guide under guides/ at the same path in dist/.
import { cpSync, existsSync } from "node:fs"
import { join } from "node:path"
import { DIST, decks, exportHandout, WORKSPACE } from "./decks.mjs"

for (const deck of decks()) {
  if (!existsSync(join(DIST, deck, "index.html"))) throw new Error(`${deck} is not built: run check first`)
  exportHandout(deck)
}
cpSync(join(WORKSPACE, "index.html"), join(DIST, "index.html"))
cpSync(join(WORKSPACE, "guides"), DIST, { recursive: true })
