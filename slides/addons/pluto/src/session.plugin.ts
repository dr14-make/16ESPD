// Starts the Pluto server behind a live deck with `slidev dev`, and hands the page where it is as
// the module `virtual:pluto-session`.
//
// The secret is reachable only through Vite, whose host check refuses a request naming any host
// but this machine: a page on another site that rebinds its own name to 127.0.0.1 is refused.

import { realpath } from "node:fs/promises"
import { dirname, resolve } from "node:path"
import type { Plugin } from "vite"
import type { DeckSession, KernelAddress } from "./deck.session.js"
// By their real extension, because Node, through Slidev's loader and the test runner alike, loads
// these modules as written.
import { launchPluto } from "./kernel.launcher.ts"
import type { PlutoServer } from "./kernel.launcher.ts"
import { isRecord } from "./pluto.interface.ts"

const ID = "virtual:pluto-session"
const RESOLVED_ID = `\0${ID}`

/** What the plugin needs to know about the deck Slidev is serving. */
export interface DeckSource {
  /** The deck's Markdown entry. */
  readonly entry: string
  /** The deck's headmatter, read whenever the module is, so an edit to it applies on reload. */
  readonly headmatter: () => unknown
  /** Only `slidev dev` presents against a kernel; a build or an export has none. */
  readonly live: boolean
}

/**
 * The notebook the deck's headmatter names, or why it names none.
 *
 * Resolved against the deck file and through symlinks, because the page finds its notebook among
 * the ones Pluto runs by comparing paths, and Pluto is handed this one.
 */
export async function deckNotebook(source: DeckSource): Promise<string | { problem: string }> {
  const headmatter = source.headmatter()
  const pluto = isRecord(headmatter) ? headmatter.pluto : undefined
  const reference = isRecord(pluto) ? pluto.notebook : undefined
  if (typeof reference !== "string") {
    return {
      problem: "the headmatter names no notebook; a live deck carries pluto: { notebook: path }",
    }
  }
  const named = resolve(dirname(source.entry), reference)
  return realpath(named).catch(() => named)
}

/**
 * The page's session, given the kernel this dev server started (`null` when it started none, or
 * Julia exited before Pluto answered).
 */
export async function deckSession(
  source: DeckSource,
  running: KernelAddress | null,
): Promise<DeckSession> {
  if (!source.live) {
    return { problem: "a built deck has no kernel" }
  }
  const notebook = await deckNotebook(source)
  if (typeof notebook !== "string") {
    return notebook
  }
  // The kernel starts with the dev server, so a notebook named since then has none.
  if (running?.notebook !== notebook) {
    return { problem: `no kernel runs ${notebook}; restart slidev to start one` }
  }
  return { kernel: { plutoUrl: running.plutoUrl, secret: running.secret, notebook } }
}

export function sessionPlugin(source: DeckSource, launch = launchPluto): Plugin {
  let running: (KernelAddress & Pick<PlutoServer, "ready" | "stop">) | null = null

  return {
    name: "pluto-session",
    resolveId(id) {
      return id === ID ? RESOLVED_ID : undefined
    },
    // The page imports this once it has rendered, and is answered once Pluto is.
    async load(id) {
      if (id !== RESOLVED_ID) {
        return undefined
      }
      const session = await deckSession(source, (await running?.ready) ? running : null)
      return `export default ${JSON.stringify(session)}`
    },
    async configureServer() {
      if (!source.live) {
        return
      }
      const notebook = await deckNotebook(source)
      if (typeof notebook !== "string") {
        return
      }
      // Slidev starts Vite with its log level at `warn`, which would hide Pluto starting.
      const log = (line: string) => process.stdout.write(`[pluto] ${line}\n`)
      const server = await launch([notebook], log)
      running = {
        plutoUrl: server.plutoUrl,
        secret: server.secret,
        notebook,
        ready: server.ready,
        stop: () => server.stop(),
      }
    },
    // Vite closes a dev server's plugins with it, which is also how Slidev restarts one.
    async closeBundle() {
      const stopping = running
      running = null
      await stopping?.stop()
    },
  }
}
