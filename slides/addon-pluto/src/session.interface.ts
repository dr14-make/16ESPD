// The shapes `/api/session` and `/api/deck` publish, as PlutoDeck.jl's `server.jl` writes them,
// in as much depth as a live card reads them.

/** What the browser needs to reach Pluto: the deck does not proxy it, so the page connects itself. */
export interface Session {
  readonly plutoUrl: string
  readonly secret: string
  // Snake case because it is the wire field Pluto's own client expects, unlike its neighbors here.
  readonly notebook_id: string
  readonly editUrl: string
}

/** Every card the notebook declares, keyed to the cell that publishes it. */
export interface CardIndex {
  readonly cards: Readonly<Record<string, string>>
}

/** Where a card's content came from. A card starts at `placeholder` and moves to whatever first supplies it. */
export type CardSource = "placeholder" | "live"

/**
 * What a cell is currently showing.
 *
 * `stamp` is the cell's own `last_run_timestamp`, which is what tells a card whether this is
 * output it has already painted. `published` is every payload the body may reach for.
 */
export interface CardContent {
  readonly source: Exclude<CardSource, "placeholder">
  readonly stamp: number
  readonly mime: string
  readonly body: unknown
  readonly published: Readonly<Record<string, unknown>>
  readonly cellId: string
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null
}

export function isSession(value: unknown): value is Session {
  return (
    isRecord(value) &&
    typeof value.plutoUrl === "string" &&
    typeof value.secret === "string" &&
    typeof value.notebook_id === "string" &&
    typeof value.editUrl === "string"
  )
}

/**
 * Whether `value` carries the card index a live card resolves its name through.
 *
 * Every value is a cell id, so a non-string here is a card that silently never paints.
 */
export function isCardIndex(value: unknown): value is CardIndex {
  return (
    isRecord(value) &&
    isRecord(value.cards) &&
    Object.values(value.cards).every((cellId) => typeof cellId === "string")
  )
}

/**
 * Read one of the deck server's two endpoints, refusing a body that is not what it should be.
 *
 * A shape the frontend cannot read otherwise surfaces as cards that never leave `placeholder`,
 * which reads in a lecture hall exactly like a kernel that has not started.
 */
export async function fetchJson<T>(
  url: string,
  isValid: (value: unknown) => value is T,
): Promise<T> {
  const response = await fetch(url)
  if (!response.ok) {
    throw new Error(`${url} answered ${String(response.status)}`)
  }
  const body: unknown = await response.json()
  if (!isValid(body)) {
    throw new Error(`${url} answered a body this deck cannot read`)
  }
  return body
}
