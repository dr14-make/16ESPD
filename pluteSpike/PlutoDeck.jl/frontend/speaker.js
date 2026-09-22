// The speaker window: the cues of the slide the deck is showing, and nothing else.
//
// No kernel, no Rainbow bundle, no bonds, no published objects — the deck's slide list and its
// cue markdown are the whole of what this page reads, which is why it survives a kernel that has
// died and why it is a second page rather than a second renderer.

import { renderCues } from "./cues.js"
import { Following } from "./position.js"

const deckElement = document.getElementById("speaker-deck")
const slideElement = document.getElementById("speaker-slide")
const positionElement = document.getElementById("speaker-position")
const stateElement = document.getElementById("speaker-state")
const bodyElement = document.getElementById("cue-body")

const deck = await fetch("/api/deck").then((response) => response.json())

deckElement.textContent = deck.path.split("/").pop()
document.title = `Speaker cues · ${deckElement.textContent}`

let rendered = null

new Following({ deck: deck.path, onChange: show })

/**
 * Say where the deck is, or that there is no deck saying.
 *
 * The cues are left standing through a `lost` — the lecturer is still talking to that slide —
 * and it is the chrome that has to make it unmistakable that nothing is confirming them.
 */
function show({ status, index, decks }) {
  document.body.dataset.deck = status

  const slide = index === null ? null : deck.slides[index]

  if (slide === undefined) {
    // The deck is paging a slide list this page does not have, which one refresh fixes and
    // nothing else will: its cues would be another slide's, which is worse than no cues.
    stateElement.textContent =
      `The deck is on slide ${index + 1} of a deck this page has not loaded. Refresh it.`
    positionElement.textContent = "—"
    slideElement.textContent = ""
    bodyElement.replaceChildren()
    rendered = null
    return
  }

  if (slide !== null && index !== rendered) {
    renderCues(bodyElement, slide.notes ?? null)
    document.scrollingElement.scrollTop = 0
    rendered = index
  }

  slideElement.textContent = slide === null ? "" : slide.title ?? `Slide ${index + 1}`
  positionElement.textContent = slide === null ? "—" : `${index + 1} / ${deck.slides.length}`
  stateElement.textContent = stateMessage(status, decks)
}

function stateMessage(status, decks) {
  if (status === "waiting") {
    return "No deck window is driving this page; it follows one as soon as the deck is open."
  }
  if (status === "lost") {
    return "The deck window is gone — these are the last cues it sent, not the live slide."
  }
  // Two windows on one deck page independently, and this page can only follow whichever spoke
  // last: saying so is what lets the lecturer close one, rather than watching it flip.
  return decks > 1
    ? `${decks} deck windows are driving this page — close all but one.`
    : "Following the deck."
}
