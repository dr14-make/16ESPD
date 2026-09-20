// A card is a state machine over where its content came from, and nothing else.
//
// It holds no kernel reference and pulls from nothing: it is given content, so a second source
// — a cached snapshot, a static export — is one more `show` call rather than a new renderer.

/**
 * One card of a deck.
 *
 * `paint(host, content)` renders content into an element; `element` is the card's own DOM.
 * A card starts in `placeholder` and moves to whatever source first hands it content.
 */
export class Card {
  #body
  #paint
  #stamp = null

  constructor({ name, paint }) {
    this.name = name
    this.#paint = paint

    this.#body = document.createElement("div")
    this.#body.className = "card-body"
    this.#body.append(
      Object.assign(document.createElement("p"), { className: "card-waiting", textContent: name }),
    )

    this.element = document.createElement("article")
    this.element.className = "card"
    this.element.dataset.card = name
    this.element.dataset.source = "placeholder"
    this.element.append(this.#body)
  }

  get source() {
    return this.element.dataset.source
  }

  /**
   * Show `content`, or leave the card as it is when there is nothing new to show.
   *
   * Repainting rebuilds every script in the card against whatever payload it reads, which for a
   * plot means rebuilding the graph against a multi-megabyte published object. A notebook diff
   * arrives for every cell many times per run, so a card only repaints when the content it is
   * given is new, which is what `stamp` reports.
   */
  show(content) {
    if (content == null) return false
    if (content.source === this.source && content.stamp === this.#stamp) return false

    this.#stamp = content.stamp
    this.element.dataset.source = content.source
    this.#paint(this.#body, content)
    return true
  }
}
