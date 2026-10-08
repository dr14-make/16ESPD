// Exports every deck's handout into the build `check` made, then assembles the published site in
// dist/: the built decks, the landing page, and each guide under guides/ at the same path in dist/.
import { copyFileSync, existsSync, mkdirSync, readdirSync, statSync } from "node:fs"
import { join } from "node:path"
import { DIST, decks, exportHandout, WORKSPACE } from "./decks.mjs"

for (const deck of decks()) {
  if (!existsSync(join(DIST, deck, "index.html"))) throw new Error(`${deck} is not built: run check first`)
  exportHandout(deck)
}
copyFileSync(join(WORKSPACE, "index.html"), join(DIST, "index.html"))
copyResolved(join(WORKSPACE, "guides"), DIST)

/**
 * A guide shares its screenshots with its tutor deck through a symlink to the deck's `public/`, so
 * the copy follows every link; `cpSync`'s `dereference` follows only the top-level path.
 */
function copyResolved(from, to) {
  if (!statSync(from).isDirectory()) return copyFileSync(from, to)
  mkdirSync(to, { recursive: true })
  for (const entry of readdirSync(from)) copyResolved(join(from, entry), join(to, entry))
}
