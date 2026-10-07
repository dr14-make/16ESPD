import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { test } from "node:test"
import { cueProblems, glossaryKinds } from "./cues.mjs"

const kinds = glossaryKinds(readFileSync(new URL("../CONTEXT.md", import.meta.url), "utf8"))
const notes = (...paragraphs) => `# Slide\n\n<!--\n${paragraphs.join("\n\n")}\n-->\n`
const leads = (md) => cueProblems(md, kinds).map((p) => p.lead)

test("the glossary's cue kinds are what the check knows", () => {
  assert.ok(kinds.includes("say"))
  assert.ok(kinds.includes("ask the room"))
  assert.ok(kinds.includes("they get wrong"))
  assert.equal(kinds.at(-1), "why")
})

test("a cue written as **Kind:** passes", () => {
  assert.deepEqual(leads(notes("**Say:** hello.", "**Ask the room:** why?", "**Point at:** the plot.")), [])
})

test("bold emphasis that names no cue kind passes", () => {
  assert.deepEqual(leads(notes("**On attendance:** nobody counts.", "**Before the room fills.** Deck up.")), [])
})

test("a lead-in close to a cue kind but not written as one fails", () => {
  assert.deepEqual(
    leads(notes(
      "**Point at** the plot.",
      "**Read out:** the axis.",
      "**Readout — every symbol on this slide**",
      "**Ask the rom:** anyone?",
      "**say:** lower case.",
      "**Why it matters:** because.",
    )),
    ["Point at", "Read out:", "Readout — every symbol on this slide", "Ask the rom:", "say:", "Why it matters:"],
  )
})

test("bold text outside speaker notes is not a cue", () => {
  assert.deepEqual(leads("**Point at** this is slide text.\n"), [])
})

test("a problem names the line its lead-in is on", () => {
  const [problem] = cueProblems(notes("**Say:** fine.", "**Point at** the plot."), kinds)
  assert.equal(problem.line, 6)
})
