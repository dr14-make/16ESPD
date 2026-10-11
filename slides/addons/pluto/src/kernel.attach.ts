// Which Pluto server a live deck runs against: one `slidev dev` starts, or one already running
// that `PLUTO_URL` names, such as the server an editor extension keeps for authoring.

import { realpath } from "node:fs/promises"
import { secretQuery } from "./kernel.address.ts"
import type { KernelLookup } from "./kernel.address.ts"

/** How long an attached server gets to list its notebooks before the deck says it is not there. */
const LIST_TIMEOUT_MS = 5_000

/** The Pluto server behind a live deck, whichever kind it is. */
export interface KernelSource {
  /** Where the page finds `notebook`, an absolute path with its symlinks resolved. */
  locate(notebook: string): Promise<KernelLookup>
  /** Stop whatever the dev server started; an attached server is left running. */
  stop(): Promise<void>
}

/** A running Pluto server to attach to, at `plutoUrl` without a trailing slash. */
export interface AttachTarget {
  readonly plutoUrl: string
  /** `null` for a server started without a secret. */
  readonly secret: string | null
}

export type KernelChoice =
  | { readonly mode: "launch" }
  | ({ readonly mode: "attach" } & AttachTarget)
  | { readonly mode: "invalid"; readonly problem: string }

/**
 * Launch a server of the deck's own, or attach to the one `PLUTO_URL` names.
 *
 * The secret is `PLUTO_SECRET`, or the `secret` query parameter of `PLUTO_URL`, the form the URL
 * Pluto prints takes. Two secrets that disagree are refused rather than one picked silently.
 */
export function kernelChoice(env: Readonly<Record<string, string | undefined>>): KernelChoice {
  const given = env.PLUTO_URL?.trim() ?? ""
  if (given === "") {
    return { mode: "launch" }
  }
  let url: URL
  try {
    url = new URL(given)
  } catch {
    return { mode: "invalid", problem: `PLUTO_URL ${given} is not a URL` }
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") {
    return { mode: "invalid", problem: `PLUTO_URL ${given} is not an http(s) URL` }
  }
  const inUrl = url.searchParams.get("secret") ?? ""
  const inEnv = env.PLUTO_SECRET?.trim() ?? ""
  if (inUrl !== "" && inEnv !== "" && inUrl !== inEnv) {
    return { mode: "invalid", problem: "PLUTO_URL and PLUTO_SECRET carry different secrets" }
  }
  const secret = inUrl !== "" ? inUrl : inEnv
  return {
    mode: "attach",
    plutoUrl: `${url.origin}${url.pathname.replace(/\/+$/, "")}`,
    secret: secret === "" ? null : secret,
  }
}

/** `path` with its symlinks resolved, or as given when there is nothing there to resolve. */
export function resolvedPath(path: string): Promise<string> {
  return realpath(path).catch(() => path)
}

/**
 * The Pluto server at `target`, which the dev server neither started nor stops.
 *
 * Asked again on every page load, so a notebook opened in the server after the deck started is
 * found on the next reload. Pluto lists a notebook by the path it was opened from, which may run
 * through a symlink, so both sides are resolved before they are compared.
 */
export function attachPluto(target: AttachTarget): KernelSource {
  return {
    async locate(notebook) {
      const listed = await notebookList(target)
      if ("problem" in listed) {
        return listed
      }
      for (const [notebookId, path] of listed.entries) {
        if ((await resolvedPath(path)) === notebook) {
          return { plutoUrl: target.plutoUrl, secret: target.secret, notebookId }
        }
      }
      return {
        problem: `the Pluto server at ${target.plutoUrl} has not opened ${notebook}; open it there and reload the deck`,
      }
    },
    stop: () => Promise.resolve(),
  }
}

/** The notebooks the server at `target` runs, as id and path, or why it said nothing. */
async function notebookList(
  target: AttachTarget,
): Promise<
  { readonly entries: readonly (readonly [string, string])[] } | { readonly problem: string }
> {
  let response: Response
  try {
    response = await fetch(`${target.plutoUrl}/notebooklist${secretQuery(target.secret)}`, {
      signal: AbortSignal.timeout(LIST_TIMEOUT_MS),
    })
  } catch {
    return { problem: `no Pluto server answers at ${target.plutoUrl}` }
  }
  if (response.status === 403) {
    return {
      problem: `the Pluto server at ${target.plutoUrl} refused the deck; set PLUTO_SECRET to its secret`,
    }
  }
  const entries = response.ok ? stringMapEntries(new Uint8Array(await response.arrayBuffer())) : null
  if (entries === null) {
    return { problem: `${target.plutoUrl} answered, but not with a Pluto notebook list` }
  }
  return { entries }
}

/**
 * The entries of a MessagePack map from strings to strings, or `null` for anything else.
 *
 * Pluto's `/notebooklist` is exactly that map, notebook id to path; this reads that one shape and
 * nothing more.
 */
export function stringMapEntries(bytes: Uint8Array): [string, string][] | null {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)
  let at = 0
  const take = (size: number): number | null => {
    if (at + size > bytes.length) {
      return null
    }
    const start = at
    at += size
    return start
  }
  const uint = (size: 1 | 2 | 4): number | null => {
    const start = take(size)
    if (start === null) {
      return null
    }
    return size === 1
      ? view.getUint8(start)
      : size === 2
        ? view.getUint16(start)
        : view.getUint32(start)
  }
  /** The length a header announces: a fix-size tag in `fix`, or a tag `sized` names. */
  const header = (
    fix: readonly [number, number],
    sized: readonly (readonly [number, 1 | 2 | 4])[],
  ): number | null => {
    const tag = uint(1)
    if (tag === null) {
      return null
    }
    if (tag >= fix[0] && tag <= fix[1]) {
      return tag - fix[0]
    }
    const size = sized.find(([sizedTag]) => sizedTag === tag)?.[1]
    return size === undefined ? null : uint(size)
  }
  const string = (): string | null => {
    const length = header([0xa0, 0xbf], [[0xd9, 1], [0xda, 2], [0xdb, 4]])
    if (length === null) {
      return null
    }
    const start = take(length)
    return start === null ? null : new TextDecoder().decode(bytes.subarray(start, start + length))
  }

  const entries = header([0x80, 0x8f], [[0xde, 2], [0xdf, 4]])
  if (entries === null) {
    return null
  }
  const pairs: [string, string][] = []
  for (let i = 0; i < entries; i++) {
    const key = string()
    const value = string()
    if (key === null || value === null) {
      return null
    }
    pairs.push([key, value])
  }
  return at === bytes.length ? pairs : null
}
