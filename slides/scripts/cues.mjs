/**
 * The cue-kind check. A cue is a speaker-notes paragraph opening with a bold lead-in that names
 * a cue kind from the course-material glossary, written `**Kind:**`. Bold lead-ins that are
 * nowhere near a kind (`**On attendance:**`) are ordinary emphasis and pass; a lead-in that is
 * close to a kind but not written as one — `**Point at**` with no colon, `**Read out:**`,
 * `**Readout — every symbol**`, `**Ask the rom:**` — is reported.
 */

/** The cue kinds as the glossary lists them under **Cue**, lower case. */
export function glossaryKinds(contextMd) {
  const entry = contextMd.match(/\*\*Cue\*\*:\s*\n([\s\S]*?)\n(?:_Avoid_|\n)/)
  if (!entry) throw new Error("the glossary has no **Cue** entry")
  const list = entry[1].replace(/\s+/g, " ").split("—")[1]
  if (!list) throw new Error("the glossary's **Cue** entry lists no kinds after its dash")
  return list.replace(/\.\s*$/, "").split(",").map((k) => k.trim().toLowerCase()).filter(Boolean)
}

/** Every bold lead-in opening a paragraph inside an HTML comment, which is where Slidev notes live. */
export function leadIns(markdown) {
  const found = []
  for (const comment of markdown.matchAll(/<!--([\s\S]*?)-->/g)) {
    const before = markdown.slice(0, comment.index)
    const firstLine = before.split("\n").length
    let offset = 0
    for (const paragraph of comment[1].split(/\n\s*\n/)) {
      const lead = paragraph.trimStart().match(/^\*\*(.+?)\*\*/)
      if (lead) {
        const line = firstLine + comment[1].slice(0, offset).split("\n").length - 1
        found.push({ lead: lead[1], line: line + leadingNewlines(paragraph) })
      }
      offset += paragraph.length + 2
    }
  }
  return found
}

/** Problems with the lead-ins of one Markdown file, as `{ line, lead, message }`. */
export function cueProblems(markdown, kinds) {
  const problems = []
  for (const { lead, line } of leadIns(markdown)) {
    if (kinds.some((k) => lead === `${capitalize(k)}:`)) continue
    const kind = nearestKind(lead, kinds)
    if (kind) {
      problems.push({
        line,
        lead,
        message: `**${lead}** reads as the cue kind "${kind}"; write it as **${capitalize(kind)}:**`,
      })
    }
  }
  return problems
}

function nearestKind(lead, kinds) {
  const words = lead.toLowerCase().match(/[a-z']+/g) ?? []
  for (const kind of kinds) {
    const size = kind.split(" ").length
    const tolerance = kind.length <= 4 ? 0 : kind.length <= 8 ? 1 : 2
    for (const n of [size, size + 1]) {
      if (words.length < n) continue
      const head = words.slice(0, n)
      for (const candidate of [head.join(" "), head.join("")]) {
        for (const target of [kind, kind.replaceAll(" ", "")]) {
          if (distance(candidate, target) <= tolerance) return kind
        }
      }
    }
  }
  return undefined
}

function capitalize(kind) {
  return kind[0].toUpperCase() + kind.slice(1)
}

function leadingNewlines(text) {
  return text.length - text.replace(/^\n+/, "").length
}

function distance(a, b) {
  let previous = Array.from({ length: b.length + 1 }, (_, i) => i)
  for (let i = 1; i <= a.length; i++) {
    const current = [i]
    for (let j = 1; j <= b.length; j++) {
      current[j] = Math.min(
        previous[j] + 1,
        current[j - 1] + 1,
        previous[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1),
      )
    }
    previous = current
  }
  return previous[b.length]
}
