// The speaker cues of the slide that is showing, over the slide on a key.
//
// Over the slide rather than in it: a cue is for the lecturer, and the room is looking at the
// same screen. A second window can be blocked and a mirrored projector shows it to the room, so
// the overlay is the path that works without preparation rather than the degraded one.

import { consume } from "@lit/context"
import { LitElement, css, html } from "lit"
import type { CSSResultGroup, TemplateResult } from "lit"
import { customElement, property, state } from "lit/decorators.js"
import { cueBodyStyles } from "./cue-body.styles.js"
import { renderCues } from "./cues.helper.js"
import { deckContext, slideIndexContext } from "./deck.context.js"
import type { Deck } from "./deck.interface.js"

@customElement("cue-overlay")
export class CueOverlay extends LitElement {
  @consume({ context: deckContext, subscribe: true })
  @state()
  private deck: Deck | null = null

  @consume({ context: slideIndexContext, subscribe: true })
  @state()
  private index = 0

  @property({ type: Boolean, reflect: true, useDefault: true }) public open = false

  #rendered: number | null = null

  public static override styles: CSSResultGroup = [
    cueBodyStyles,
    css`
      :host {
        display: none;
      }

      /* Fixed rather than placed in the flow: the panel covers the slide it belongs to, and a
         card's geometry — which \`h\` and the clipping of a figure both depend on — must not move
         when a lecturer opens it mid-lecture. */
      :host([open]) {
        display: block;
        position: fixed;
        inset-block: auto 0;
        inset-inline: 0;
        z-index: 10;
        max-block-size: 46vh;
        /* Several hundred words is the normal length of a cue and there is no geometry for it to
           overflow, so the panel scrolls rather than the page. */
        overflow-y: auto;
        padding-block: 1rem 1.25rem;
        padding-inline: 1.25rem;
        /* \`--surface\` alone is the page's own white in light mode, which leaves the panel
           reading as more deck rather than as the lecturer's own margin. */
        background: color-mix(in srgb, var(--warn) 5%, var(--surface));
        border-block-start: 3px solid var(--warn);
        box-shadow: 0 -6px 20px rgb(0 0 0 / 0.18);
        font-size: 0.95rem;
        line-height: 1.5;
      }

      /* The deck's own measure: a cue set edge to edge on a projector is a 1400 px line. */
      .cue-body {
        margin-inline: auto;
        max-inline-size: 72rem;
      }
    `,
  ]

  protected override render(): TemplateResult {
    return html`<div class="cue-body" role="complementary" aria-label="Speaker cues"></div>`
  }

  protected override updated(): void {
    if (!this.open || this.deck === null) {
      return
    }
    if (this.index === this.#rendered) {
      return
    }

    const body = this.renderRoot.querySelector(".cue-body")
    if (body === null) {
      return
    }

    renderCues(body, this.deck.slides[this.index]?.notes ?? null)
    this.#rendered = this.index
    this.scrollTop = 0
  }

  /** Reopening on a slide whose cues were rendered before must still repaint them. */
  protected override willUpdate(changed: Map<PropertyKey, unknown>): void {
    super.willUpdate(changed)
    if (changed.has("open") && this.open) {
      this.#rendered = null
    }
  }
}
