// The deck: build a card per placement, then feed every card the kernel's output.
//
// Nothing here renders output or talks to the websocket. `render.painter.ts` owns Pluto's
// renderer, `kernel.client.ts` owns the connection, `kernel.status.ts` owns the chrome's state,
// and a card is only ever given content.

import { provide } from "@lit/context"
import { html } from "lit"
import type { TemplateResult } from "lit"
import { customElement, state } from "lit/decorators.js"
import {
  cardContentContext,
  deckContext,
  kernelStatusContext,
  painterContext,
  editUrlContext,
  slideIndexContext,
} from "./deck.context.js"
import type { CardContents } from "./deck.context.js"
import { fetchJson, isDeck, isSession } from "./deck.interface.js"
import type { CardContent, Deck, Session } from "./deck.interface.js"
import type { DeckMoveEvent } from "./deck-nav.component.js"
import { connect } from "./kernel.client.js"
import type { Kernel } from "./kernel.client.js"
import { kernelStatus } from "./kernel.status.js"
import type { KernelStatus } from "./kernel.status.js"
import { LightDomElement } from "./light-dom.element.js"
import { Position } from "./position.channel.js"
import { createPainter, whenScriptsSettled } from "./render.painter.js"
import type { Painter } from "./render.painter.js"
import { DeckCard } from "./deck-card.component.js"
import "./cue-overlay.component.js"
import "./deck-chrome.component.js"
import "./deck-nav.component.js"
import "./deck-slide.component.js"

/**
 * The bond a notebook declares to be told which color scheme the deck is being shown in.
 *
 * A contract with every notebook that opts in, so renaming it is a migration across all of
 * them. A notebook that declares no bond of this name is left alone.
 */
const THEME_BOND = "deck_theme"

/** The key that puts the current slide's speaker cues over it, and takes them away again. */
const CUE_KEY = "c"

/** Keys that move the deck, and by how many slides. */
const NAVIGATION_KEYS: Readonly<Record<string, number>> = {
  ArrowRight: 1,
  PageDown: 1,
  ArrowLeft: -1,
  PageUp: -1,
}

/** The scheme the deck itself is styled for, which `deck.css` follows through the same query. */
const darkScheme = window.matchMedia("(prefers-color-scheme: dark)")

/**
 * Renders in light DOM, which is not a preference: see `LightDomElement`.
 *
 * The provider boundary for everything below it. The cues and the slide publisher are built
 * before the kernel is reached, because `connect` throws when there is no kernel to reach and a
 * cue is worth most in the minutes a lecturer spends without one.
 */
@customElement("deck-app")
export class DeckApp extends LightDomElement {
  // `@state` only where this element's own template reads the value. `@provide` notifies its
  // consumers itself, so marking the rest reactive would re-render the whole slide tree on every
  // notebook diff to produce byte-identical DOM.
  @provide({ context: deckContext }) @state() private deck: Deck | null = null
  @provide({ context: slideIndexContext }) @state() private slideIndex = 0

  @provide({ context: editUrlContext }) private editUrl: string | null = null
  @provide({ context: painterContext }) private painter: Painter | null = null
  @provide({ context: cardContentContext }) private contents: CardContents = new Map()
  @provide({ context: kernelStatusContext }) private status: KernelStatus = kernelStatus()

  @state() private cuesOpen = false

  #kernel: Kernel | null = null
  #position: Position | null = null
  #connected = true
  #failure: string | null = null
  #refreshing = false
  #refreshAgain = false

  #loaded = false

  public override connectedCallback(): void {
    super.connectedCallback()
    // Registered here rather than after the fetches, so that it is added and removed in the same
    // place and a disconnect landing mid-load cannot remove a listener that is not there yet.
    window.addEventListener("keydown", this.#onKeyDown)
    if (!this.#loaded) {
      this.#loaded = true
      void this.#load()
    }
  }

  async #load(): Promise<void> {
    const [session, deck] = await Promise.all([
      fetchJson("/api/session", isSession),
      fetchJson("/api/deck", isDeck),
    ])
    this.editUrl = session.editUrl
    this.deck = deck
    document.title = `PlutoDeck · ${deck.path.split("/").pop() ?? deck.path}`

    // Announced from here for the same reason the cues are: the speaker window carries no
    // kernel, and a deck that never reached one still has to drive it.
    this.#position = new Position(deck.path)

    this.#showStatus()

    await this.#run(session, deck)
  }

  public override disconnectedCallback(): void {
    super.disconnectedCallback()
    window.removeEventListener("keydown", this.#onKeyDown)
    this.#position?.stop()
    this.#position = null
  }

  protected override render(): TemplateResult {
    const deck = this.deck

    return html`
      <deck-chrome></deck-chrome>

      <div class="preamble" hidden>
        ${(deck?.preamble ?? []).map((name) => html`<deck-card name=${name}></deck-card>`)}
      </div>

      <main class="slides">
        ${(deck?.slides ?? []).map(
          (slide, index) =>
            html`<deck-slide
              .slide=${slide}
              .index=${index}
              ?current=${index === this.slideIndex}
            ></deck-slide>`,
        )}
      </main>

      <deck-nav
        .cuesOpen=${this.cuesOpen}
        @deck-move=${(event: DeckMoveEvent) => this.#showSlide(event.index)}
        @deck-toggle-cues=${() => this.#toggleCues()}
      ></deck-nav>

      <cue-overlay ?open=${this.cuesOpen}></cue-overlay>
    `
  }

  async #run(session: Session, deck: Deck): Promise<void> {
    let kernel: Kernel
    try {
      kernel = await connect(session)
    } catch (error) {
      this.#failure = `the kernel could not be reached: ${describe(error)}`
      this.#showStatus()
      return
    }

    this.#kernel = kernel
    this.painter = createPainter(kernel)

    // Downstream cells finish after the cell they depend on, so a run is only settled once every
    // cell the deck reads has come to rest — not only the one a bond feeds.
    kernel.watch(this.#everyCardName(deck).map((name) => deck.cards[name]))

    darkScheme.addEventListener("change", () => void this.#publishTheme())
    await this.#publishTheme()

    kernel.onChange(() => void this.#refresh())
    kernel.onConnectionChange((connection) => {
      this.#connected = connection.connected
      this.#showStatus()
    })
    await this.#refresh()
  }

  /**
   * Tell the kernel which color scheme the viewer is in.
   *
   * A plot paints its own paper in Julia, where nothing knows what the browser is showing, so a
   * dark deck otherwise carries a white slab per plot. No stylesheet reaches inside a rendered
   * figure — the colors are in the payload the kernel sent — so the only way to change them is
   * to have the kernel send different ones, which is what a bond and a reactive run already do.
   *
   * Written before the first paint, so a card is not painted light and then repainted dark.
   */
  async #publishTheme(): Promise<void> {
    const kernel = this.#kernel
    if (kernel === null) {
      return
    }
    if (!kernel.declares(THEME_BOND)) {
      return
    }
    await kernel.setBond(THEME_BOND, darkScheme.matches ? "dark" : "light")
  }

  /**
   * Bring every card up to date with the kernel.
   *
   * A diff arrives for every cell many times per run and each one lands here, so a refresh that
   * is already in flight records that it has to go round once more rather than stacking up.
   */
  async #refresh(): Promise<void> {
    if (this.#refreshing) {
      this.#refreshAgain = true
      return
    }
    this.#refreshing = true
    try {
      let again = true
      while (again) {
        this.#refreshAgain = false
        await this.#publish()
        this.#showStatus()
        again = this.#refreshAgain
      }
    } finally {
      this.#refreshing = false
    }
  }

  /**
   * Hand the cards their content, the preamble first.
   *
   * A plot card drawn before the preamble's script has loaded the offline Plotly bundle draws
   * nothing, so the two groups are published in order rather than together, and the paint is
   * awaited: `whenScriptsSettled` reports an empty set until a card has actually rendered.
   */
  async #publish(): Promise<void> {
    const deck = this.deck
    const kernel = this.#kernel
    if (deck === null || kernel === null) {
      return
    }

    const contentOf = (name: string): CardContent | null => {
      const cellId = deck.cards[name]
      return cellId === undefined ? null : kernel.content(cellId)
    }

    const preamble = collect(deck.preamble, contentOf)
    if (this.#holdsNewContent(preamble)) {
      this.contents = preamble
      await this.#cardsPainted()
      await whenScriptsSettled()
    }

    this.contents = collect(this.#everyCardName(deck), contentOf)
    await this.#cardsPainted()
  }

  /** Whether any card would repaint for this content, which is what `stamp` reports. */
  #holdsNewContent(contents: CardContents): boolean {
    for (const [name, content] of contents) {
      if (this.contents.get(name)?.stamp !== content.stamp) {
        return true
      }
    }
    return false
  }

  /** A context update only reaches a card on Lit's next turn, and painting is what is awaited. */
  async #cardsPainted(): Promise<void> {
    await this.updateComplete
    const cards = [...this.querySelectorAll("deck-card")].filter(
      (card): card is DeckCard => card instanceof DeckCard,
    )
    await Promise.all(cards.map((card) => card.updateComplete))
  }

  #everyCardName(deck: Deck): string[] {
    return [...deck.preamble, ...deck.slides.flatMap((slide) => slide.cards.map((c) => c.card))]
  }

  /**
   * Move to slide `index`, if there is one there.
   *
   * Every slide stays mounted and painted; only which one is visible changes. Unmounting would
   * throw away a Plotly card's rendered graph and have it rebuilt against a multi-megabyte
   * payload on the way back.
   */
  #showSlide(index: number): void {
    const count = this.deck?.slides.length ?? 0
    if (index < 0 || index >= count) {
      return
    }
    this.slideIndex = index
    this.#position?.moved(index)
  }

  #toggleCues(): void {
    this.cuesOpen = !this.cuesOpen
  }

  readonly #onKeyDown = (event: KeyboardEvent): void => {
    // Alt+ArrowLeft is the browser's own history, and Ctrl/Meta combinations belong to the
    // browser too, so only an unmodified key moves the deck.
    if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) {
      return
    }

    // A range input is driven with the same arrow keys, and every other key is a character a
    // text field is owed: a lecturer nudging a gain must not be thrown onto the next slide for
    // it, and one typing must not open the cues.
    const target = event.target
    if (
      target instanceof Element &&
      target.closest("input, select, textarea, [contenteditable]") !== null
    ) {
      return
    }

    // Case-folded, because caps lock is not a modifier: it would otherwise leave the cue key
    // silently dead in exactly the room the cues exist for.
    if (event.key.toLowerCase() === CUE_KEY) {
      event.preventDefault()
      this.#toggleCues()
      return
    }

    const step = NAVIGATION_KEYS[event.key]
    if (step === undefined) {
      return
    }

    event.preventDefault()
    this.#showSlide(this.slideIndex + step)
  }

  #showStatus(): void {
    this.status = kernelStatus({
      failure: this.#failure,
      connected: this.#connected,
      process: this.#kernel?.status ?? null,
    })
    // The suite waits on this to know the page has bound its listeners: a module script delays
    // `load` until it has started, not finished.
    document.body.dataset.kernel = this.status.state
  }
}

function collect(
  names: readonly string[],
  contentOf: (name: string) => CardContent | null,
): CardContents {
  const contents = new Map<string, CardContent>()
  for (const name of names) {
    const content = contentOf(name)
    if (content !== null) {
      contents.set(name, content)
    }
  }
  return contents
}

function describe(error: unknown): string {
  return error instanceof Error ? error.message : String(error)
}
