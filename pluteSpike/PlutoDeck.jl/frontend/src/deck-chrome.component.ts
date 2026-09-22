// The deck's header: which deck and notebook this is, what the kernel is doing, and the two
// links out of it.

import { consume } from "@lit/context"
import { LitElement, css, html, nothing } from "lit"
import type { CSSResultGroup, TemplateResult } from "lit"
import { customElement, state } from "lit/decorators.js"
import { deckContext, editUrlContext, kernelStatusContext } from "./deck.context.js"
import { fileName } from "./deck.interface.js"
import type { Deck } from "./deck.interface.js"
import type { KernelStatus } from "./kernel.status.js"

@customElement("deck-chrome")
export class DeckChrome extends LitElement {
  @consume({ context: deckContext, subscribe: true })
  @state()
  private deck: Deck | null = null

  @consume({ context: editUrlContext, subscribe: true })
  @state()
  private editUrl: string | null = null

  @consume({ context: kernelStatusContext, subscribe: true })
  @state()
  private status: KernelStatus = { state: "connecting", message: "the kernel is starting" }

  public static override styles: CSSResultGroup = css`
    :host {
      display: block;
    }

    h1 {
      margin: 0;
      font-size: 1.4rem;
    }

    p {
      margin-block: 0.25rem;
      color: var(--muted);
      font-size: 0.9rem;
    }

    a {
      color: inherit;
    }

    .status {
      color: var(--warn);

      &::before {
        content: "";
        display: inline-block;
        inline-size: 0.5rem;
        block-size: 0.5rem;
        margin-inline-end: 0.35rem;
        border-radius: 50%;
        background: currentColor;
      }
    }

    :host([data-kernel="ready"]) .status {
      color: var(--ok);
    }

    :host([data-kernel="offline"]) .status {
      color: var(--muted);
    }

    :host([data-kernel="error"]) .status {
      color: var(--bad);
    }
  `

  protected override willUpdate(): void {
    this.dataset.kernel = this.status.state
  }

  protected override render(): TemplateResult {
    return html`
      <h1>${this.deck === null ? "PlutoDeck" : fileName(this.deck.path)}</h1>
      <p>${this.deck === null ? nothing : fileName(this.deck.notebook)}</p>
      <p>
        <span class="status" aria-live="polite">${this.status.message}</span> ·
        ${this.editUrl === null
          ? nothing
          : html`<a href=${this.editUrl}>open the notebook in Pluto</a> ·`}
        <a class="speaker-link" href="speaker.html" target="_blank" rel="noopener">cues in a window</a>
      </p>
    `
  }
}
