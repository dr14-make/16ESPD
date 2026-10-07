// The shape `/api/deck` publishes, as `server.jl` writes it, beyond the card index a live card
// reads. The session and the card content belong to the `pluto` addon, which the deck renders
// its cards through.

export type { CardContent, Session } from "../../../../slides/addon-pluto/src/session.interface.js"
export {
  THEME_BOND,
  fetchJson,
  isSession,
} from "../../../../slides/addon-pluto/src/session.interface.js"

/** A slide's speaker cues as they were read, carrying either the text or the failure to read it. */
export interface CueText {
  readonly path: string
  readonly markdown: string
}

export interface CueFailure {
  readonly path: string
  readonly error: string
}

export type SlideNotes = CueText | CueFailure

export function hasCueText(notes: SlideNotes): notes is CueText {
  return "markdown" in notes
}

/** Where a card sits on a slide, in the 12-column grid `deck.json` addresses. */
export interface CardPlacement {
  readonly card: string
  readonly x: number
  readonly y: number
  readonly w: number
  readonly h: number
  readonly snapshot: string | null
}

export interface Slide {
  readonly title: string | null
  readonly notes: SlideNotes | null
  readonly cards: readonly CardPlacement[]
}

export interface Deck {
  readonly path: string
  readonly notebook: string
  /** Cards rendered before any slide and shown on none, for the side effects their scripts perform. */
  readonly preamble: readonly string[]
  readonly slides: readonly Slide[]
  /** Every card the notebook declares, not only the placed ones, keyed to the cell that publishes it. */
  readonly cards: Readonly<Record<string, string>>
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null
}

export const fileName = (path: string): string => path.split("/").pop() ?? path

/**
 * Whether `value` is a deck the frontend knows how to render.
 *
 * Checked as deeply as the frontend indexes: the loader has already refused a deck whose cards
 * overlap or name a cell that does not exist, so what is left to establish here is that the
 * shape crossing the wire is the shape `server.jl` documents.
 */
export function isDeck(value: unknown): value is Deck {
  return (
    isRecord(value) &&
    typeof value.path === "string" &&
    typeof value.notebook === "string" &&
    isStringArray(value.preamble) &&
    // Every value is a cell id the deck resolves a card through, so a non-string here is a card
    // that silently never paints.
    isRecord(value.cards) &&
    Object.values(value.cards).every((cellId) => typeof cellId === "string") &&
    Array.isArray(value.slides) &&
    value.slides.every(isSlide)
  )
}

function isSlide(value: unknown): value is Slide {
  return (
    isRecord(value) &&
    (value.title === null || typeof value.title === "string") &&
    (value.notes === null || isSlideNotes(value.notes)) &&
    Array.isArray(value.cards) &&
    value.cards.every(isPlacement)
  )
}

/**
 * Cues carrying neither text nor a reason are not an absence to render.
 *
 * `renderCues` reaches `notes.path` and `notes.error` on the failure branch, so a half-shaped
 * `notes` renders "undefined could not be read: undefined" — which reads as a broken parser
 * rather than as the missing file it is.
 */
function isSlideNotes(value: unknown): value is SlideNotes {
  if (!isRecord(value) || typeof value.path !== "string") {
    return false
  }
  return typeof value.markdown === "string" || typeof value.error === "string"
}

function isPlacement(value: unknown): value is CardPlacement {
  return (
    isRecord(value) &&
    typeof value.card === "string" &&
    typeof value.x === "number" &&
    typeof value.y === "number" &&
    typeof value.w === "number" &&
    typeof value.h === "number" &&
    (value.snapshot === null || typeof value.snapshot === "string")
  )
}

function isStringArray(value: unknown): value is string[] {
  return Array.isArray(value) && value.every((item) => typeof item === "string")
}
