// Answers the page of a live deck served by `slidev dev` with where its Pluto server is: one it
// starts, or one already running that `PLUTO_URL` names. The answer is `<base>@pluto/kernel`, a
// request answered afresh each time, so a reload sees a notebook opened since or a headmatter edit.
//
// The secret is reachable only through Vite, whose host check refuses a request naming any host
// but this machine: a page on another site that rebinds its own name to 127.0.0.1 is refused.
// `slidev --remote` and `--tunnel` widen the hosts Vite allows, so this holds for a local server.

import { dirname, resolve } from "node:path"
import { setTimeout as sleep } from "node:timers/promises"
import type { Plugin } from "vite"
// By their real extension, because Node, through Slidev's loader and the test runner alike, loads
// these modules as written.
import { KERNEL_ENDPOINT } from "./kernel.address.ts"
import type { KernelAddress, KernelLookup } from "./kernel.address.ts"
import { attachPluto, kernelChoice, resolvedPath } from "./kernel.attach.ts"
import type { KernelChoice, KernelSource } from "./kernel.attach.ts"
import { launchPluto } from "./kernel.launcher.ts"
import { isRecord } from "./pluto.interface.ts"

/** How often to ask a starting Pluto whether it has opened the deck's notebook yet. */
const OPENED_POLL_MS = 500

/** What the plugin needs to know about the deck Slidev is serving. */
export interface DeckSource {
  /** The deck's Markdown entry. */
  readonly entry: string
  /** The deck's headmatter, read on every request, so an edit to it applies on reload. */
  readonly headmatter: () => unknown
  /** Only `slidev dev` presents against a kernel; a build or an export has none. */
  readonly live: boolean
}

/**
 * The notebook the deck's headmatter names, or why it names none.
 *
 * Resolved against the deck file and through symlinks, because the notebook is found among the
 * ones Pluto runs by comparing paths, and a Pluto the deck starts is handed this one.
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
  return resolvedPath(resolve(dirname(source.entry), reference))
}

/** Why the page has no kernel when the one this dev server could start is not running `notebook`. */
function noKernel(notebook: string): { readonly problem: string } {
  return { problem: `no kernel runs ${notebook}; restart slidev to start one` }
}

/**
 * Where the page finds the deck's notebook, given the kernel source this dev server set up (`null`
 * when it set up none).
 */
export async function lookUpKernel(
  source: DeckSource,
  kernel: KernelSource | null,
): Promise<KernelLookup> {
  const notebook = await deckNotebook(source)
  if (typeof notebook !== "string") {
    return notebook
  }
  if (kernel === null) {
    return noKernel(notebook)
  }
  return kernel.locate(notebook)
}

/**
 * Start the deck's own Pluto with `notebook` open and attach to it, or attach to the server
 * `choice` names.
 *
 * A server the deck starts runs only the notebook named when it started, so a deck that names
 * another one since, or whose Julia exited before it opened the notebook, is told to restart.
 */
export async function kernelSource(
  choice: KernelChoice,
  notebook: string,
  log: (line: string) => void,
  launch = launchPluto,
): Promise<KernelSource> {
  switch (choice.mode) {
    case "invalid":
      log(choice.problem)
      return {
        locate: () => Promise.resolve({ problem: choice.problem }),
        stop: () => Promise.resolve(),
      }
    case "attach": {
      log(`attaching to the Pluto server at ${choice.plutoUrl}; this dev server will not stop it`)
      if (choice.secret === null) {
        log(
          "warning: that server has no secret, so any web page open in this browser can run Julia on it",
        )
      }
      const attached = attachPluto(choice)
      void attached.locate(notebook).then((located) => {
        log("problem" in located ? located.problem : `${choice.plutoUrl} has ${notebook} open`)
      })
      return attached
    }
    case "launch": {
      const server = await launch([notebook], log)
      const opened = untilOpened(attachPluto(server), notebook, server.exited)
      return {
        locate: async (named) =>
          named === notebook ? ((await opened) ?? noKernel(named)) : noKernel(named),
        stop: () => server.stop(),
      }
    }
  }
}

/** Where `source` runs `notebook`, asked until it does, or `null` once `exited` settles first. */
async function untilOpened(
  source: KernelSource,
  notebook: string,
  exited: Promise<void>,
): Promise<KernelAddress | null> {
  const gone = exited.then(() => false)
  for (;;) {
    const located = await source.locate(notebook)
    if (!("problem" in located)) {
      return located
    }
    if (!(await Promise.race([gone, sleep(OPENED_POLL_MS, true)]))) {
      return null
    }
  }
}

export function kernelPlugin(
  source: DeckSource,
  launch = launchPluto,
  env: Readonly<Record<string, string | undefined>> = process.env,
): Plugin {
  let kernel: KernelSource | null = null

  return {
    name: "pluto-kernel",
    async configureServer(server) {
      // A build or an export answers nothing here, so the page there has no kernel to find.
      if (!source.live) {
        return
      }
      const endpoint = `${server.config.base}${KERNEL_ENDPOINT}`
      server.middlewares.use((request, response, next) => {
        if (request.url?.split("?")[0] !== endpoint) {
          next()
          return
        }
        lookUpKernel(source, kernel).then((found) => {
          response.setHeader("Content-Type", "application/json")
          response.setHeader("Cache-Control", "no-store")
          response.end(JSON.stringify(found))
        }, next)
      })
      const notebook = await deckNotebook(source)
      if (typeof notebook !== "string") {
        return
      }
      // Slidev starts Vite with its log level at `warn`, which would hide Pluto starting.
      const log = (line: string) => process.stdout.write(`[pluto] ${line}\n`)
      kernel = await kernelSource(kernelChoice(env), notebook, log, launch)
    },
    // Vite closes a dev server's plugins with it, which is also how Slidev restarts one.
    async closeBundle() {
      const stopping = kernel
      kernel = null
      await stopping?.stop()
    },
  }
}
