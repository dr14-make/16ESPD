// The slice of Pluto's notebook state the deck reads.
//
// Declared here rather than imported, because `@plutojl/rainbow` 0.6.21 does not type what it
// hands back: `dist/standalone/client.d.ts` writes `getState(): NotebookData | null` without
// importing `NotebookData`, so the name is unresolved, `skipLibCheck` swallows it, and every
// read off the notebook state is silently `any`. Declaring the fields the deck depends on is
// what makes them checked, and `isNotebookState` is where an upgrade that changes the shape
// stops being a card that renders nothing.

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null
}

/**
 * The bond a notebook declares to be told which color scheme the deck is being shown in.
 *
 * A contract with every notebook that opts in, so renaming it is a migration across all of
 * them. A notebook that declares no bond of this name is left alone.
 */
export const THEME_BOND = "deck_theme"

/** What a cell is showing, as PlutoRunner wrote it. */
export interface CellOutput {
  readonly body: unknown
  readonly mime: string
  readonly last_run_timestamp: number
}

/** What a cell holds, as the notebook file has it. */
export interface CellInput {
  readonly code: string
  /** The cell's own metadata, where a cell declares the card it publishes as `card`. */
  readonly metadata?: unknown
}

export interface CellDependency {
  /** Keys are the variables this cell defines. */
  readonly downstream_cells_map: Readonly<Record<string, readonly string[]>>
  /** Keys are the variables this cell references. */
  readonly upstream_cells_map: Readonly<Record<string, readonly string[]>>
}

export interface NotebookState {
  readonly process_status: string
  // Held as `unknown` because that is all the shape check establishes: a notebook carries a cell
  // per notebook rather than per card, and these are read on every diff. `isCellOutput`,
  // `isCellInput` and `isCellDependency` narrow what the deck actually takes out of them.
  readonly cell_inputs: Readonly<Record<string, unknown>>
  readonly cell_results: Readonly<Record<string, unknown>>
  readonly cell_dependencies: Readonly<Record<string, unknown>>
  readonly published_objects: Readonly<Record<string, unknown>>
  readonly bonds: Readonly<Record<string, { readonly value: unknown } | undefined>>
}

/** The notebook as a bond write sees it, which is the one place the deck mutates the state. */
export interface MutableNotebookState {
  bonds: Record<string, { value: unknown }>
}

export function isCellDependency(value: unknown): value is CellDependency {
  return (
    isRecord(value) &&
    isRecord(value.downstream_cells_map) &&
    isRecord(value.upstream_cells_map)
  )
}

/**
 * Whether a cell's output is one a card can be painted from.
 *
 * `last_run_timestamp` is the sole repaint key for every card and the settle key for every bond,
 * and `mime` decides how the body is rendered. Checked here rather than over the whole of
 * `cell_results`, which is read on every notebook diff and holds a cell the deck never places.
 */
export function isCellOutput(value: unknown): value is CellOutput {
  return (
    isRecord(value) &&
    typeof value.mime === "string" &&
    typeof value.last_run_timestamp === "number"
  )
}

export function isCellInput(value: unknown): value is CellInput {
  return isRecord(value) && typeof value.code === "string"
}

/**
 * Whether `value` is the notebook state the deck knows how to read.
 *
 * The maps are checked for being maps rather than for what is in them: a notebook carries a cell
 * per notebook, not per card, and this is read on every diff. What the deck actually reads out of
 * one is checked where it is read — `isCellOutput` for a cell's output, and `declares` for a
 * dependency entry.
 */
export function isNotebookState(value: unknown): value is NotebookState {
  return (
    isRecord(value) &&
    typeof value.process_status === "string" &&
    isRecord(value.cell_inputs) &&
    isRecord(value.cell_results) &&
    isRecord(value.cell_dependencies) &&
    isRecord(value.published_objects) &&
    isRecord(value.bonds)
  )
}
