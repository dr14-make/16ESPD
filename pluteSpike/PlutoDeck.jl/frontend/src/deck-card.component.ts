// A card is a state machine over where its content came from, and nothing else.
//
// It holds no kernel reference and pulls from nothing: it is given content, so a second source
// — a cached snapshot, a static export — is one more entry in the content map rather than a new
// renderer.

import { consume } from "@lit/context"
import { html } from "lit"
import type { TemplateResult } from "lit"
import { customElement, property, state } from "lit/decorators.js"
import { cardContentContext, painterContext } from "./deck.context.js"
import type { CardContents } from "./deck.context.js"
import { LightDomElement } from "./light-dom.element.js"
import type { Painter } from "./render.painter.js"

/**
 * One card of a deck.
 *
 * Renders in light DOM, which is not a preference: see `LightDomElement`.
 *
 * The body is handed to Pluto's Preact renderer and its children belong to it from then on.
 * `render` therefore returns one constant template with no bindings inside the body, so Lit
 * clones it once and never touches what the painter put there.
 */
@customElement("deck-card")
export class DeckCard extends LightDomElement {
  /** The card name the deck placed, which is also the key its content arrives under. */
  @property({ type: String, useDefault: true }) public name = ""

  @consume({ context: cardContentContext, subscribe: true })
  @state()
  private contents: CardContents = new Map()

  @consume({ context: painterContext, subscribe: true })
  @state()
  private painter: Painter | null = null

  #stamp: number | null = null

  public override connectedCallback(): void {
    super.connectedCallback()
    this.classList.add("card")
    this.dataset.card = this.name
    this.dataset.source ??= "placeholder"
  }

  /** Where this card's content came from, which `deck.css` and the suite both read. */
  public get source(): string {
    return this.dataset.source ?? "placeholder"
  }

  protected override render(): TemplateResult {
    return html`<div class="card-body"><p class="card-waiting"></p></div>`
  }

  protected override firstUpdated(): void {
    const waiting = this.renderRoot.querySelector(".card-waiting")
    if (waiting !== null) {
      waiting.textContent = this.name
    }
  }

  /**
   * Show the content this card has been given, or leave it as it is when there is nothing new.
   *
   * Repainting rebuilds every script in the card against whatever payload it reads, which for a
   * plot means rebuilding the graph against a multi-megabyte published object. A notebook diff
   * arrives for every cell many times per run, so a card only repaints when the content it is
   * given is new, which is what `stamp` reports.
   */
  protected override updated(): void {
    const content = this.contents.get(this.name)
    if (content === undefined || this.painter === null) {
      return
    }
    if (content.source === this.source && content.stamp === this.#stamp) {
      return
    }

    const body = this.renderRoot.querySelector(".card-body")
    if (body === null) {
      return
    }

    this.#stamp = content.stamp
    this.dataset.source = content.source
    this.painter(body, content)
  }
}
