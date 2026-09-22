// Paging the deck: the two buttons, where the deck is, and the cue toggle.

import { consume } from "@lit/context"
import { LitElement, css, html } from "lit"
import type { CSSResultGroup, TemplateResult } from "lit"
import { customElement, property, state } from "lit/decorators.js"
import { deckContext, slideIndexContext } from "./deck.context.js"
import type { Deck } from "./deck.interface.js"

/** Asks the deck to move to a slide. */
export class DeckMoveEvent extends Event {
  public static readonly type = "deck-move"
  public readonly index: number

  constructor(index: number) {
    super(DeckMoveEvent.type, { bubbles: true, composed: true })
    this.index = index
  }
}

/** Asks the deck to show or hide the speaker cues over the slide. */
export class DeckToggleCuesEvent extends Event {
  public static readonly type = "deck-toggle-cues"

  constructor() {
    super(DeckToggleCuesEvent.type, { bubbles: true, composed: true })
  }
}

@customElement("deck-nav")
export class DeckNav extends LitElement {
  @consume({ context: deckContext, subscribe: true })
  @state()
  private deck: Deck | null = null

  @consume({ context: slideIndexContext, subscribe: true })
  @state()
  private index = 0

  @property({ type: Boolean, useDefault: true }) public cuesOpen = false

  public static override styles: CSSResultGroup = css`
    :host {
      display: block;
      margin-block: 1.5rem;
    }

    nav {
      display: flex;
      align-items: center;
      gap: 0.75rem;
    }

    button {
      font: inherit;
      font-size: 0.85rem;
      padding-block: 0.35rem;
      padding-inline: 0.8rem;
      border: 1px solid var(--edge);
      border-radius: 6px;
      background: var(--surface);
      color: var(--ink);
      cursor: pointer;

      &:disabled {
        color: var(--muted);
        cursor: default;
      }

      &[aria-pressed="true"] {
        border-color: var(--warn);
        color: var(--warn);
      }
    }

    .position {
      margin: 0;
      color: var(--muted);
      font-size: 0.85rem;
      /* The counter changes on every move; proportional digits make the nav jitter as it does. */
      font-variant-numeric: tabular-nums;
    }
  `

  protected override render(): TemplateResult {
    const count = this.deck?.slides.length ?? 0

    return html`
      <nav aria-label="Slides">
      <button
        class="previous"
        type="button"
        ?disabled=${this.index === 0}
        @click=${() => this.#move(this.index - 1)}
      >
        Previous slide
      </button>
      <p class="position" aria-live="polite">${count === 0 ? "" : `${this.index + 1} / ${count}`}</p>
      <button
        class="next"
        type="button"
        ?disabled=${count === 0 || this.index === count - 1}
        @click=${() => this.#move(this.index + 1)}
      >
        Next slide
      </button>
      <button
        class="cues"
        type="button"
        aria-pressed=${String(this.cuesOpen)}
        @click=${() => this.dispatchEvent(new DeckToggleCuesEvent())}
      >
        Speaker cues (C)
      </button>
      </nav>
    `
  }

  #move(index: number): void {
    this.dispatchEvent(new DeckMoveEvent(index))
  }
}
