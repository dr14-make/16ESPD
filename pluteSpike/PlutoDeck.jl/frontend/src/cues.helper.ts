// Rendering a slide's speaker cues, for the overlay over the slide and for the speaker page
// alike.
//
// The only markdown the frontend renders itself. Julia's `Markdown` stdlib would need a live
// kernel, and a cue is worth most in the twenty-odd seconds before one exists or after one has
// been killed — so the parser is bundled and the text arrives as markdown in `/api/deck`.

import { marked } from "marked"
import { hasCueText } from "./deck.interface.js"
import type { SlideNotes } from "./deck.interface.js"

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
  body.innerHTML = marked.parse(notes.markdown, { async: false })
}

function absence(message: string): HTMLParagraphElement {
  const paragraph = document.createElement("p")
  paragraph.className = "cue-absent"
  paragraph.textContent = message
  return paragraph
}
