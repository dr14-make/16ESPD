// The slice of Pluto's notebook state the deck reads.
//
// Declared here rather than imported, because `@plutojl/rainbow` 0.6.21 does not type what it
// hands back: `dist/standalone/client.d.ts` writes `getState(): NotebookData | null` without
// importing `NotebookData`, so the name is unresolved, `skipLibCheck` swallows it, and every
// read off the notebook state is silently `any`. Declaring the fields the deck depends on is
// what makes them checked, and `isNotebookState` is where an upgrade that changes the shape
// stops being a card that renders nothing.

/** What a cell is showing, as PlutoRunner wrote it. */
export interface CellOutput {
  readonly body: unknown
  readonly mime: string
  readonly last_run_timestamp: number
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
  // per notebook rather than per card, and these are read on every diff. `isCellOutput` and
  // `isCellDependency` narrow what the deck actually takes out of them.
  readonly cell_results: Readonly<Record<string, unknown>>
  readonly cell_dependencies: Readonly<Record<string, unknown>>
  readonly published_objects: Readonly<Record<string, unknown>>
  readonly bonds: Readonly<Record<string, { readonly value: unknown } | undefined>>
}

/** The notebook as a bond write sees it, which is the one place the deck mutates the state. */
export interface MutableNotebookState {
  bonds: Record<string, { value: unknown }>
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null
}

/**
 * Whether a cell's output is one a card can be painted from.
 *
 * `last_run_timestamp` is the sole repaint key for every card and the settle key for every bond,
 * and `mime` decides how the body is rendered. Checked here rather than over the whole of
 * `cell_results`, which is read on every notebook diff and holds a cell the deck never places.
 */
export function isCellDependency(value: unknown): value is CellDependency {
  return (
    isRecord(value) &&
    isRecord(value.downstream_cells_map) &&
    isRecord(value.upstream_cells_map)
  )
}

export function isCellOutput(value: unknown): value is CellOutput {
  return (
    isRecord(value) &&
    typeof value.mime === "string" &&
    typeof value.last_run_timestamp === "number"
  )
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
    isRecord(value.cell_results) &&
    isRecord(value.cell_dependencies) &&
    isRecord(value.published_objects) &&
    isRecord(value.bonds)
  )
}
