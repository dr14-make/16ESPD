// What the deck's dev server hands the page about its kernel, and how the page finds its notebook
// among the ones Pluto is running.

// By its real extension, because Node's test runner loads this module as written.
import { isRecord } from "./pluto.interface.ts"

/** The Pluto server a deck's notebook runs in, and the notebook, by its absolute path. */
export interface KernelAddress {
  readonly plutoUrl: string
  readonly secret: string
  readonly notebook: string
}

/**
 * Either where the kernel is, or why the page has none.
 *
 * `slidev dev` serves this as `virtual:pluto-session` (`session.plugin.ts`). A build always
 * carries a `problem`, so a published deck holds neither the secret nor a path on this machine.
 */
export type DeckSession = { readonly kernel: KernelAddress } | { readonly problem: string }

export function isKernelAddress(value: unknown): value is KernelAddress {
  return (
    isRecord(value) &&
    typeof value.plutoUrl === "string" &&
    typeof value.secret === "string" &&
    typeof value.notebook === "string"
  )
}

export function isDeckSession(value: unknown): value is DeckSession {
  return isRecord(value) && (isKernelAddress(value.kernel) || typeof value.problem === "string")
}

/**
 * The id of the notebook running from `path`, out of what `Host.workers()` resolves to.
 *
 * Taken as `unknown`: @plutojl/rainbow 0.6.21 types the result as `Worker[]`, but it hands back
 * Pluto's own `notebook_list` entries, `{ notebook_id, path, … }`, and an empty list whenever
 * the request fails.
 */
export function notebookIdAt(listed: unknown, path: string): string | null {
  if (!Array.isArray(listed)) {
    return null
  }
  for (const entry of listed) {
    if (isRecord(entry) && entry.path === path && typeof entry.notebook_id === "string") {
      return entry.notebook_id
    }
  }
  return null
}
