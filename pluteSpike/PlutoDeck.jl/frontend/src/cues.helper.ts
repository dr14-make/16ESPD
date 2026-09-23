// Rendering a slide's speaker cues, for the overlay over the slide and for the speaker page
// alike.
//
// The only markdown the frontend renders itself. Julia's `Markdown` stdlib would need a live
// kernel, and a cue is worth most in the twenty-odd seconds before one exists or after one has
// been killed — so the parser is bundled and the text arrives as markdown in `/api/deck`.

import { Marked } from "marked"
import { hasCueText } from "./deck.interface.js"
import type { SlideNotes } from "./deck.interface.js"
import { texMarkup } from "./math.markup.js"
import { clearMath, typesetMath } from "./math.typesetter.js"

/**
 * The parser, carrying the math a cue may hold.
 *
 * Its own instance: the module-level `marked` is a singleton every importer shares, so
 * configuring it would configure it for whatever else reaches for it.
 */
const parser = new Marked(texMarkup)

/**
 * Put the cues of one slide into `body`.
 *
 * `notes` is a slide's `notes` from `/api/deck`: `null`, or the file's text, or the error that
 * reading it gave. Nothing here knows whether the cues are over a slide or on a page of their
 * own, which is what lets the speaker window render them without a panel to toggle.
 */
export function renderCues(body: Element, notes: SlideNotes | null): void {
  if (notes === null) {
    body.replaceChildren(absence("This slide has no speaker cues."))
    return
  }
  if (!hasCueText(notes)) {
    body.replaceChildren(absence(`${notes.path} could not be read: ${notes.error}`))
    return
  }
  // A cue file is authored by whoever authored the deck and the notebook, and is trusted
  // exactly as far as they are: markdown carrying raw HTML renders as that HTML.
  clearMath(body)
  body.innerHTML = parser.parse(notes.markdown, { async: false })
  void typesetMath(body)
}

function absence(message: string): HTMLParagraphElement {
  const paragraph = document.createElement("p")
  paragraph.className = "cue-absent"
  paragraph.textContent = message
  return paragraph
}
