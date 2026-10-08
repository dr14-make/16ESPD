// Copies each folder of images/ to every place that publishes it. A deck serves images only from
// its own public/, and the site only from site/public/, so an image both use is copied into each.
// The copies are build output and gitignored: edit the image under images/.
import { cpSync, rmSync } from "node:fs"
import { join } from "node:path"
import { WORKSPACE } from "./decks.mjs"

const COPIES = {
  "handson-01": ["decks/handson-01/public/img", "site/public/handson/lecture-01/img"],
}

for (const [folder, targets] of Object.entries(COPIES)) {
  for (const target of targets) {
    rmSync(join(WORKSPACE, target), { recursive: true, force: true })
    cpSync(join(WORKSPACE, "images", folder), join(WORKSPACE, target), { recursive: true })
  }
}
