// The speaker cues of the slide that is showing: over the slide on a key, and on the speaker
// page, from one renderer.
//
// The only markdown the frontend renders itself. Julia's `Markdown` stdlib would need a live
// kernel, and a cue is worth most in the twenty-odd seconds before one exists or after one has
// been killed — so the parser is vendored and the text arrives as markdown in `/api/deck`.

import { marked } from "./vendor/marked.esm.js"

/**
 * The overlay a lecturer reads their cues from, bound to a key over the slide.
 *
 * `slides` is the slide list `/api/deck` published.
 */
export class Cues {
  #panel
  #body
  #slides
  #index = 0

  constructor({ panel, body, slides }) {
    this.#panel = panel
    this.#body = body
    this.#slides = slides
  }

  get open() {
    return !this.#panel.hidden
  }

  /** Follow the deck to slide `index`, which is a repaint only while the panel is showing. */
  show(index) {
    this.#index = index
    if (this.open) this.#render()
  }

  toggle() {
    this.#panel.hidden = this.open
    if (this.open) this.#render()
  }

  #render() {
    renderCues(this.#body, this.#slides[this.#index]?.notes ?? null)
    this.#panel.scrollTop = 0
  }
}

/**
 * Put the cues of one slide into `body`.
 *
 * `notes` is a slide's `notes` from `/api/deck`: `null`, or an object holding either the file's
 * `markdown` or the `error` that reading it gave. Nothing here knows whether the cues are over
 * a slide or on a page of their own, which is what lets the speaker window render them without
 * a panel to toggle.
 */
export function renderCues(body, notes) {
  if (notes === null) {
    body.replaceChildren(absence("This slide has no speaker cues."))
  } else if (notes.error !== undefined) {
    body.replaceChildren(absence(`${notes.path} could not be read: ${notes.error}`))
  } else {
    // A cue file is authored by whoever authored the deck and the notebook, and is trusted
    // exactly as far as they are: markdown carrying raw HTML renders as that HTML.
    body.innerHTML = marked.parse(notes.markdown)
  }
}

function absence(message) {
  return Object.assign(document.createElement("p"), {
    className: "cue-absent",
    textContent: message,
  })
}
