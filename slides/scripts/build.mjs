// Exports every deck's handout into the build `check` made, then assembles the published site in
// dist/: the built decks plus the pages under slides/ still published as committed.
import { cpSync, existsSync } from "node:fs"
import { join } from "node:path"
import { DIST, decks, exportHandout, staticDecks, WORKSPACE } from "./decks.mjs"

const COMMITTED = ["index.html", "handson"]

const all = decks()
for (const deck of staticDecks()) {
  if (!existsSync(join(DIST, deck, "index.html"))) throw new Error(`${deck} is not built: run check first`)
  exportHandout(deck)
}
for (const entry of COMMITTED.filter((e) => !all.includes(e))) {
  cpSync(join(WORKSPACE, entry), join(DIST, entry), { recursive: true })
}
