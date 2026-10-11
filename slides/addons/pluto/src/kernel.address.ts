// What the deck's dev server hands the page about its kernel.

// By its real extension, because Node's test runner loads this module as written.
import { isRecord } from "./pluto.interface.ts"

/** Where, under the deck's base, `slidev dev` answers with a `KernelLookup` (`kernel.plugin.ts`). */
export const KERNEL_ENDPOINT = "@pluto/kernel"

/** The Pluto server a deck's notebook runs in, and the id it runs that notebook under. */
export interface KernelAddress {
  readonly plutoUrl: string
  /** `null` for a server started without one. */
  readonly secret: string | null
  readonly notebookId: string
}

/**
 * Either where the kernel is, or why the page has none.
 *
 * Only `slidev dev` answers it, so a built deck carries none of it.
 */
export type KernelLookup = KernelAddress | { readonly problem: string }

function isKernelAddress(value: unknown): value is KernelAddress {
  return (
    isRecord(value) &&
    typeof value.plutoUrl === "string" &&
    (typeof value.secret === "string" || value.secret === null) &&
    typeof value.notebookId === "string"
  )
}

export function isKernelLookup(value: unknown): value is KernelLookup {
  return isKernelAddress(value) || (isRecord(value) && typeof value.problem === "string")
}

/** The query a request to a Pluto server with `secret` carries, from `?` on; `""` for none. */
export function secretQuery(secret: string | null): string {
  return secret === null ? "" : `?secret=${encodeURIComponent(secret)}`
}
