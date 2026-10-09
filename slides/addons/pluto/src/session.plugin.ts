// Hands the page where its kernel is, as the module `virtual:pluto-session`.
//
// PlutoDeck's `present` writes Pluto's URL and secret to a session file beside the deck once the
// notebook is ready, and removes it on the way down. The deck's own dev server serves them, so
// the secret is reachable only through Vite, whose host check refuses a request naming any host
// but this machine: a page on another site that rebinds its own name to 127.0.0.1 is refused.

import { readFile, realpath } from "node:fs/promises"
import { dirname, join, resolve } from "node:path"
import type { Plugin } from "vite"
import type { DeckSession } from "./deck.session.js"
// By its real extension, because Node, through Slidev's loader and the test runner alike, loads
// this module as written.
import { isRecord } from "./pluto.interface.ts"

/** The file `present` writes beside the deck. Gitignored, because it holds Pluto's secret. */
export const SESSION_FILE = ".pluto-session.json"

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
 * The page's session, from the deck's headmatter and the session file's text (`null` when
 * there is none).
 *
 * The notebook path is resolved against the deck file and through symlinks, the way `present`
 * resolves the one it opens, because the page finds its notebook by comparing the two.
 */
export async function deckSession(
  source: DeckSource,
  sessionText: string | null,
): Promise<DeckSession> {
  if (!source.live) {
    return { problem: "a built deck has no kernel" }
  }

  const headmatter = source.headmatter()
  const pluto = isRecord(headmatter) ? headmatter.pluto : undefined
  const reference = isRecord(pluto) ? pluto.notebook : undefined
  if (typeof reference !== "string") {
    return {
      problem: "the headmatter names no notebook; a live deck carries pluto: { notebook: path }",
    }
  }
  const named = resolve(dirname(source.entry), reference)
  const notebook = await realpath(named).catch(() => named)

  if (sessionText === null) {
    return { problem: "no kernel is running for this deck; start one with PlutoDeck's present" }
  }
  let session: unknown
  try {
    session = JSON.parse(sessionText)
  } catch {
    return { problem: `${SESSION_FILE} is not JSON` }
  }
  if (
    !isRecord(session) ||
    typeof session.plutoUrl !== "string" ||
    typeof session.secret !== "string"
  ) {
    return { problem: `${SESSION_FILE} carries no plutoUrl and secret` }
  }
  return { kernel: { plutoUrl: session.plutoUrl, secret: session.secret, notebook } }
}

export function sessionPlugin(source: DeckSource): Plugin {
  const file = join(dirname(source.entry), SESSION_FILE)
  const read = (): Promise<string | null> => readFile(file, "utf8").catch(() => null)

  return {
    name: "pluto-session",
    resolveId(id) {
      return id === ID ? RESOLVED_ID : undefined
    },
    async load(id) {
      if (id !== RESOLVED_ID) {
        return undefined
      }
      const session = await deckSession(source, source.live ? await read() : null)
      return `export default ${JSON.stringify(session)}`
    },
    configureServer(server) {
      // `present` and `slidev dev` start in either order, and a kernel restarted mid-lecture
      // comes back on a new port with a new secret: the page reloads onto whichever is current.
      server.watcher.add(file)
      const reload = (changed: string): void => {
        if (changed !== file) {
          return
        }
        const module = server.moduleGraph.getModuleById(RESOLVED_ID)
        if (module !== undefined) {
          server.moduleGraph.invalidateModule(module)
        }
        server.ws.send({ type: "full-reload" })
      }
      server.watcher.on("add", reload)
      server.watcher.on("change", reload)
      server.watcher.on("unlink", reload)
    },
  }
}
