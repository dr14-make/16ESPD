// The workspace check CI runs before publishing: every image a deck references exists, and every
// deck but a live one builds into dist/<deck>/.
import { existsSync, readdirSync, readFileSync } from "node:fs"
import { dirname, join, relative } from "node:path"
import { extractImagesUsage, parseSync } from "@slidev/parser/core"
import { build, decks, staticDecks, WORKSPACE } from "./decks.mjs"

const all = decks()
const failures = []

for (const deck of all) {
  for (const file of markdownFiles(join(WORKSPACE, deck))) {
    const markdown = readFileSync(file, "utf8")
    const where = (line) => `${relative(WORKSPACE, file)}:${line}`
    for (const slide of parseSync(markdown, file).slides) {
      for (const src of extractImagesUsage(slide.content, slide.frontmatter)) {
        if (!resolves(src, file, deck)) failures.push(`${where(slide.start + 1)}: image ${src} resolves to nothing`)
      }
    }
  }
}

if (failures.length === 0) {
  for (const deck of staticDecks()) {
    try {
      build(deck)
    } catch (error) {
      failures.push(`${deck}: ${error.message}`)
    }
  }
}

if (failures.length > 0) {
  console.error(failures.join("\n"))
  console.error(`\ncheck failed: ${failures.length} problem(s)`)
  process.exit(1)
}
console.log(`check passed: ${all.join(", ")}`)

function markdownFiles(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap((e) => {
    if (e.isDirectory()) return ["public", "node_modules"].includes(e.name) ? [] : markdownFiles(join(dir, e.name))
    return e.name.endsWith(".md") ? [join(dir, e.name)] : []
  })
}

/** Absolute paths are served from the deck's `public/`; relative ones from the Markdown file. */
function resolves(src, file, deck) {
  if (/^(https?:|data:)/.test(src)) return true
  const path = src.startsWith("/") ? join(WORKSPACE, deck, "public", src) : join(dirname(file), src)
  return existsSync(decodeURI(path))
}
