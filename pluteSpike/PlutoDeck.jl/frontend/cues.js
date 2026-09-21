// The speaker cues of the slide that is showing, over the slide, on a key.
//
// The only markdown the frontend renders itself. Julia's `Markdown` stdlib would need a live
// kernel, and a cue is worth most in the twenty-odd seconds before one exists or after one has
// been killed — so the parser is vendored and the text arrives as markdown in `/api/deck`.

import { marked } from "./vendor/marked.esm.js"

/**
 * The overlay a lecturer reads their cues from.
 *
 * `slides` is the slide list `/api/deck` published: each carries `notes`, which is `null`, or
 * an object holding either the file's `markdown` or the `error` that reading it gave.
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
    const notes = this.#slides[this.#index]?.notes ?? null

    if (notes === null) {
      this.#body.replaceChildren(absence("This slide has no speaker cues."))
    } else if (notes.error !== undefined) {
      this.#body.replaceChildren(absence(`${notes.path} could not be read: ${notes.error}`))
    } else {
      // A cue file is authored by whoever authored the deck and the notebook, and is trusted
      // exactly as far as they are: markdown carrying raw HTML renders as that HTML.
      this.#body.innerHTML = marked.parse(notes.markdown)
    }
    this.#panel.scrollTop = 0
  }
}

function absence(message) {
  return Object.assign(document.createElement("p"), {
    className: "cue-absent",
    textContent: message,
  })
}
