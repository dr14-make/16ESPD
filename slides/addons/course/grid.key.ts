import type { InjectionKey } from "vue"

/** How many columns and rows the `Grid` a `Card` sits in has. */
export const GRID: InjectionKey<{ readonly cols: number; readonly rows: number }> = Symbol("grid")
