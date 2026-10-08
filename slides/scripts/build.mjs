// Exports every deck's handout into the build `check` made: the site and the decks are already in
// dist/, so the handout PDFs are all that is left to publish.
import { existsSync } from "node:fs"
import { join } from "node:path"
import { DIST, decks, exportHandout } from "./decks.mjs"

if (!existsSync(join(DIST, "index.html"))) throw new Error("the site is not built: run check first")
for (const deck of decks()) {
  if (!existsSync(join(DIST, deck, "index.html"))) throw new Error(`${deck} is not built: run check first`)
  exportHandout(deck)
}
