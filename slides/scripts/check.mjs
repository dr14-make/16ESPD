// The workspace check CI runs before publishing: every deck's cues name glossary kinds, every
// image it references exists, no link to a page beside it turns into a slide route, and it builds.
import { existsSync, readdirSync, readFileSync } from "node:fs"
import { dirname, join, relative } from "node:path"
import { cueProblems, glossaryKinds } from "./cues.mjs"
import { build, decks, WORKSPACE } from "./decks.mjs"

const kinds = glossaryKinds(readFileSync(join(WORKSPACE, "CONTEXT.md"), "utf8"))
const failures = []

for (const deck of decks()) {
  for (const file of markdownFiles(join(WORKSPACE, deck))) {
    const markdown = readFileSync(file, "utf8")
    const where = (line) => `${relative(WORKSPACE, file)}:${line}`
    for (const p of cueProblems(markdown, kinds)) failures.push(`${where(p.line)}: ${p.message}`)
    for (const image of missingImages(markdown, file, deck)) {
      failures.push(`${where(image.line)}: image ${image.src} resolves to nothing`)
    }
    for (const link of pageLinks(markdown)) {
      failures.push(
        `${where(link.line)}: [..](${link.href}) becomes a link to a slide of this deck; ` +
          `write <a href="${link.href}"> to leave the deck`,
      )
    }
  }
}

if (failures.length === 0) {
  for (const deck of decks()) {
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
console.log(`check passed: ${decks().join(", ")}`)

function markdownFiles(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap((e) => {
    if (e.isDirectory()) return e.name === "public" ? [] : markdownFiles(join(dir, e.name))
    return e.name.endsWith(".md") ? [join(dir, e.name)] : []
  })
}

/**
 * Slidev renders a Markdown link whose target starts with `.` or `/` as a route inside the deck,
 * so a link to a page beside the deck has to be written as an `<a>` element.
 */
function pageLinks(markdown) {
  const links = []
  for (const match of markdown.matchAll(/(?<!!)\[[^\]]*\]\(\s*<?([./][^)\s>]*)/g)) {
    links.push({ href: match[1], line: markdown.slice(0, match.index).split("\n").length })
  }
  return links
}

/** Absolute paths are served from the deck's `public/`; relative ones from the Markdown file. */
function missingImages(markdown, file, deck) {
  const missing = []
  const pattern = /!\[[^\]]*\]\(\s*<?([^)\s>]+)|<img\b[^>]*\bsrc="([^"]+)"/g
  for (const match of markdown.matchAll(pattern)) {
    const src = match[1] ?? match[2]
    if (/^(https?:|data:)/.test(src)) continue
    const path = src.startsWith("/")
      ? join(WORKSPACE, deck, "public", src)
      : join(dirname(file), src)
    if (!existsSync(decodeURI(path))) {
      missing.push({ src, line: markdown.slice(0, match.index).split("\n").length })
    }
  }
  return missing
}
