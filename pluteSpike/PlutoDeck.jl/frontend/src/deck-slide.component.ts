// One slide: a heading and the 12-column grid its cards are placed on.

import { html, nothing } from "lit"
import type { TemplateResult } from "lit"
import { customElement, property } from "lit/decorators.js"
import { styleMap } from "lit/directives/style-map.js"
import type { Slide } from "./deck.interface.js"
import { LightDomElement } from "./light-dom.element.js"
import "./deck-card.component.js"

/**
 * Renders in light DOM, which is not a preference: see `LightDomElement`.
 *
 * Every slide stays mounted and painted; only `current` changes. Unmounting would throw away a
 * Plotly card's rendered graph and have it rebuilt against a multi-megabyte payload on the way
 * back, and `deck.css` hides a slide with `visibility` rather than `display` so that a card on
 * it still measures the width it will be shown at.
 */
@customElement("deck-slide")
export class DeckSlide extends LightDomElement {
  @property({ attribute: false }) public slide: Slide | null = null

  /** Which slide this is, used for the heading a slide with no title of its own gets. */
  @property({ type: Number, useDefault: true }) public index = 0

  @property({ type: Boolean, useDefault: true }) public current = false

  public override connectedCallback(): void {
    super.connectedCallback()
    this.classList.add("slide")
  }

  protected override willUpdate(): void {
    // An untitled slide still needs a heading to be navigable by one; it just reads as a label
    // rather than as a title, which is what `data-titled` lets the stylesheet say.
    this.dataset.titled = String(this.slide !== null && this.slide.title !== null)
    this.dataset.current = String(this.current)
  }

  protected override render(): TemplateResult | typeof nothing {
    const slide = this.slide
    if (slide === null) {
      return nothing
    }

    return html`
      <h2>${slide.title ?? `Slide ${this.index + 1}`}</h2>
      <div class="grid">
        ${slide.cards.map(
          (placement) =>
            html`<deck-card
              name=${placement.card}
              style=${styleMap({
                gridColumn: `${placement.x + 1} / span ${placement.w}`,
                gridRow: `${placement.y + 1} / span ${placement.h}`,
              })}
            ></deck-card>`,
        )}
      </div>
    `
  }
}
