// Answers the page of a live deck served by `slidev dev` with where its Pluto server is: one it
// starts, or one already running that `PLUTO_URL` names. The answer is `<base>@pluto/kernel`, a
// request answered afresh each time, so a reload sees a notebook opened since or a headmatter edit.
//
// The secret is reachable only through Vite, whose host check refuses a request naming any host
// but this machine: a page on another site that rebinds its own name to 127.0.0.1 is refused.
// `slidev --remote` and `--tunnel` widen the hosts Vite allows, so this holds for a local server.

import { realpath } from "node:fs/promises"
import { dirname, resolve } from "node:path"
import type { Plugin } from "vite"
// By their real extension, because Node, through Slidev's loader and the test runner alike, loads
// these modules as written.
import { KERNEL_ENDPOINT } from "./kernel.address.ts"
import type { KernelLookup } from "./kernel.address.ts"
import { attachPluto, kernelChoice } from "./kernel.attach.ts"
import type { KernelChoice, KernelSource } from "./kernel.attach.ts"
import { launchPluto } from "./kernel.launcher.ts"
import { isRecord } from "./pluto.interface.ts"

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
    return { problem: `no kernel runs ${notebook}; restart slidev to start one` }
  }
  return kernel.locate(notebook)
}

/**
 * Start the deck's own Pluto with `notebook` open, or attach to the server `choice` names.
 *
 * A server the deck starts runs only the notebook named when it started, so a deck that names
 * another one since is told to restart.
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
      return {
        async locate(named) {
          if (named !== notebook || !(await server.ready)) {
            return { problem: `no kernel runs ${named}; restart slidev to start one` }
          }
          return { plutoUrl: server.plutoUrl, secret: server.secret, notebook, owned: true }
        },
        stop: () => server.stop(),
      }
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
