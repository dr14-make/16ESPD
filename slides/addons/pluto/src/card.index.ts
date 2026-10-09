// Card names, resolved to cells from the notebook state itself.
//
// A cell publishes itself by carrying `card = "some-name"` in its own Pluto metadata, which
// reaches the deck in `cell_inputs` with the rest of the notebook. A cell without the key is
// scratch work and cannot reach a slide.

// By its real extension, because Node's test runner loads this module as written.
import { isRecord } from "./pluto.interface.ts"

/** The cell metadata key a cell publishes itself to a deck under. */
export const CARD_METADATA_KEY = "card"

/**
 * Where a card's content came from. A card starts at `placeholder` and moves to whatever first
 * supplies it, or to a fault when its name addresses no single cell: `unknown` when no cell
 * declares it, `duplicate` when more than one does.
 */
export type CardSource = "placeholder" | "live" | "unknown" | "duplicate"

/**
 * What a cell is currently showing.
 *
 * `stamp` is the cell's own `last_run_timestamp`, which is what tells a card whether this is
 * output it has already painted. `published` is every payload the body may reach for.
 */
export interface CardContent {
  readonly source: "live"
  readonly stamp: number
  readonly mime: string
  readonly body: unknown
  readonly published: Readonly<Record<string, unknown>>
  readonly cellId: string
}

/** Every card the notebook declares, keyed to the cell that publishes it. */
export interface CardIndex {
  /** Names exactly one cell declares. */
  readonly cards: Readonly<Record<string, string>>
  /** Names more than one cell declares, with every cell declaring them. */
  readonly duplicates: Readonly<Record<string, readonly string[]>>
}

export type CardLookup =
  | { readonly cellId: string }
  | { readonly fault: "unknown" }
  | { readonly fault: "duplicate"; readonly cellIds: readonly string[] }

/**
 * The cards `cellInputs` declares.
 *
 * A `card` value that is not a non-empty string cannot be written as a card's `name`, so it is
 * passed over rather than refused: no card on a slide can reach it either way.
 */
export function cardIndex(cellInputs: Readonly<Record<string, unknown>>): CardIndex {
  const declared = new Map<string, string[]>()
  for (const [cellId, input] of Object.entries(cellInputs)) {
    const metadata = isRecord(input) ? input.metadata : undefined
    const name = isRecord(metadata) ? metadata[CARD_METADATA_KEY] : undefined
    if (typeof name !== "string" || name.trim() === "") {
      continue
    }
    declared.set(name, [...(declared.get(name) ?? []), cellId])
  }

  const cards: Record<string, string> = {}
  const duplicates: Record<string, readonly string[]> = {}
  for (const [name, cellIds] of declared) {
    const [only] = cellIds
    if (cellIds.length === 1 && only !== undefined) {
      cards[name] = only
    } else {
      duplicates[name] = [...cellIds].sort()
    }
  }
  return { cards, duplicates }
}

/** The cell a card name addresses, or why it addresses none. */
export function lookUpCard(index: CardIndex, name: string): CardLookup {
  if (Object.hasOwn(index.cards, name)) {
    const cellId = index.cards[name]
    if (cellId !== undefined) {
      return { cellId }
    }
  }
  if (Object.hasOwn(index.duplicates, name)) {
    const cellIds = index.duplicates[name]
    if (cellIds !== undefined) {
      return { fault: "duplicate", cellIds }
    }
  }
  return { fault: "unknown" }
}
