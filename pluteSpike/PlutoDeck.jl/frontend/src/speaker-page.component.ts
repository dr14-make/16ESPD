// The speaker window: the cues of the slide the deck is showing, and nothing else.
//
// No kernel, no Rainbow bundle, no bonds, no published objects — the deck's slide list and its
// cue markdown are the whole of what this page reads, which is why it survives a kernel that has
// died and why it is a second page rather than a second renderer.

import { LitElement, css, html } from "lit"
import type { CSSResultGroup, TemplateResult } from "lit"
import { customElement, state } from "lit/decorators.js"
import { cueBodyStyles } from "./cue-body.styles.js"
import { renderCues } from "./cues.helper.js"
import { fetchJson, fileName, isDeck } from "./deck.interface.js"
import type { Deck } from "./deck.interface.js"
import { Following } from "./position.channel.js"
import type { FollowReport } from "./position.channel.js"

/** What the window is, for the heading and the title when no deck is naming a slide. */
const PAGE_NAME = "Speaker cues"

@customElement("speaker-page")
export class SpeakerPage extends LitElement {
  @state() private deck: Deck | null = null
  #following: Following | null = null
  @state() private report: FollowReport = { status: "waiting", index: null, decks: 0 }

  #rendered: number | null = null

  public static override styles: CSSResultGroup = [
    cueBodyStyles,
    css`
      :host {
        display: block;
      }

      /* Sticky, because a cue long enough to scroll would otherwise take which slide it belongs
         to and whether anything is still confirming it off the top of the page. */
      header {
        position: sticky;
        inset-block-start: 0;
        padding-block-end: 0.75rem;
        margin-block-end: 1rem;
        background: var(--bg);
        border-block-end: 1px solid var(--edge);
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

      .state {
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

      :host([data-deck="live"]) .state {
        color: var(--ok);
      }

      /* Read across a lecture hall's worth of peripheral vision: a lecturer looking at the cues
         has to see that nothing is confirming them without reading the line. */
      :host([data-deck="lost"]) .state {
        color: var(--bad);
        font-weight: 600;
      }

      /* The cues are the page here rather than a panel over a slide, so they carry a reading
         size. */
      .cue-body {
        font-size: 1.05rem;
        line-height: 1.6;
      }
    `,
  ]

  public override connectedCallback(): void {
    super.connectedCallback()
    void this.#load()
  }

  async #load(): Promise<void> {
    const deck = await fetchJson("/api/deck", isDeck)
    this.deck = deck
    document.title = `${PAGE_NAME} · ${fileName(deck.path)}`

    this.#following = new Following(deck.path, (report) => {
      this.report = report
    })
  }

  public override disconnectedCallback(): void {
    super.disconnectedCallback()
    this.#following?.stop()
    this.#following = null
  }

  protected override willUpdate(): void {
    this.dataset.deck = this.report.status
    // The page-level signal the suite waits on before asserting anything: a module script
    // delays `load` until it has started, not finished.
    document.body.dataset.deck = this.report.status
  }

  protected override render(): TemplateResult {
    const { status, index, decks } = this.report
    const deck = this.deck
    const slide = deck !== null && index !== null ? deck.slides[index] : undefined

    // The deck is paging a slide list this page does not have, which one refresh fixes and
    // nothing else will: its cues would be another slide's, which is worse than no cues.
    if (deck !== null && index !== null && slide === undefined) {
      return html`
        <header>
          <h1>${PAGE_NAME}</h1>
          <p><span class="position">—</span> · <span>${this.#deckName()}</span></p>
          <p class="state" aria-live="polite">
            The deck is on slide ${index + 1} of a deck this page has not loaded. Refresh it.
          </p>
        </header>
        <div class="cue-body"></div>
      `
    }

    // Never empty: this page sits with no deck driving it by design, and an `h1` with no
    // accessible name announces as a level-one heading called nothing.
    const title = slide === undefined ? PAGE_NAME : (slide.title ?? `Slide ${(index ?? 0) + 1}`)
    const position =
      slide === undefined || deck === null ? "—" : `${(index ?? 0) + 1} / ${deck.slides.length}`

    return html`
      <header>
        <h1>${title}</h1>
        <p><span class="position">${position}</span> · <span>${this.#deckName()}</span></p>
        <p class="state" aria-live="polite">${stateMessage(status, decks)}</p>
      </header>
      <div class="cue-body"></div>
    `
  }

  /**
   * The cues are left standing through a `lost` — the lecturer is still talking to that slide —
   * and it is the chrome that has to make it unmistakable that nothing is confirming them.
   */
  protected override updated(): void {
    const { index } = this.report
    const deck = this.deck
    const slide = deck !== null && index !== null ? deck.slides[index] : undefined
    const body = this.renderRoot.querySelector(".cue-body")
    if (body === null) {
      return
    }

    if (index === null || slide === undefined) {
      body.replaceChildren()
      this.#rendered = null
      return
    }

    if (index !== this.#rendered) {
      renderCues(body, slide.notes)
      document.scrollingElement?.scrollTo({ top: 0 })
      this.#rendered = index
    }
  }

  #deckName(): string {
    return this.deck === null ? "" : fileName(this.deck.path)
  }
}

function stateMessage(status: FollowReport["status"], decks: number): string {
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
