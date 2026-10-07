// One kernel connection per browser window, shared by every live card in it.
//
// Slidev runs each window — the audience view, presenter mode — as an app of its own, so each
// opens its own websocket to Pluto. Nothing here renders: `render.painter.ts` owns Pluto's
// renderer and `kernel.client.ts` owns the connection.

import { shallowRef } from "vue"
import { connect } from "./kernel.client.js"
import type { Kernel } from "./kernel.client.js"
import { kernelStatus } from "./kernel.status.js"
import { sizePlotsToTheirCards } from "./plot.size.js"
import { createPainter } from "./render.painter.js"
import type { Painter } from "./render.painter.js"
import { fetchJson, isCardIndex, isSession } from "./session.interface.js"

/**
 * The bond a notebook declares to be told which color scheme the deck is being shown in.
 *
 * A contract with every notebook that opts in, so renaming it is a migration across all of
 * them. A notebook that declares no bond of this name is left alone.
 */
const THEME_BOND = "deck_theme"

/** Where Slidev's presenter mode lives, under `routerMode: hash`. */
const PRESENTER = "#/presenter"

/** How a cell that renders an input reads, which is what earns its card a place in the bond layer. */
const BIND = "@bind"

export interface Pluto {
  readonly kernel: Kernel
  readonly painter: Painter
  /** Every card the notebook declares, keyed to the cell that publishes it. */
  readonly cards: Readonly<Record<string, string>>
  /** The cards whose cell renders an input, which the bond layer keeps mounted. */
  readonly bindCards: readonly string[]
}

/** The session once it is up, for the bond layer to render from. */
export const live = shallowRef<Pluto | null>(null)

let started: Promise<Pluto> | null = null

/** The window's session, started by whichever caller asks first. */
export function usePluto(): Promise<Pluto> {
  started ??= start()
  return started
}

async function start(): Promise<Pluto> {
  showStatus({})
  sizePlotsToTheirCards()
  let kernel: Kernel
  let cards: Readonly<Record<string, string>>
  try {
    const [session, index] = await Promise.all([
      fetchJson("/api/session", isSession),
      fetchJson("/api/deck", isCardIndex),
    ])
    cards = index.cards
    kernel = await connect(session)
  } catch (error) {
    showStatus({ failure: `the kernel could not be reached: ${String(error)}` })
    throw error
  }

  // Downstream cells finish after the cell they depend on, so a run is only settled once every
  // cell a card reads has come to rest — not only the one a bond feeds.
  kernel.watch(Object.values(cards))

  let connected = true
  kernel.onConnectionChange((connection) => {
    connected = connection.connected
    showStatus({ connected, process: kernel.status })
  })
  kernel.onChange(() => showStatus({ connected, process: kernel.status }))
  showStatus({ connected, process: kernel.status })

  // Written before the first paint, so a card is not painted light and then repainted dark.
  if (kernel.declares(THEME_BOND)) {
    // The room's view decides how plots are colored. Presenter mode never writes, so two windows
    // in different schemes cannot overwrite each other and opening it sets off no notebook run.
    const publish = async (): Promise<void> => {
      const scheme = isDark() ? "dark" : "light"
      if (!location.hash.startsWith(PRESENTER) && kernel.bonds()[THEME_BOND]?.value !== scheme) {
        await kernel.setBond(THEME_BOND, scheme)
      }
    }
    new MutationObserver(() => void publish()).observe(document.documentElement, {
      attributeFilter: ["class"],
    })
    await publish()
  }

  const pluto: Pluto = {
    kernel,
    painter: createPainter(kernel),
    cards,
    bindCards: Object.keys(cards).filter((name) => kernel.code(cards[name] ?? "").includes(BIND)),
  }
  live.value = pluto
  return pluto
}

/** Whether Slidev is showing the deck dark, which it says with a class on the root element. */
function isDark(): boolean {
  return document.documentElement.classList.contains("dark")
}

/**
 * Put the window's kernel state where the browser suite waits on it.
 *
 * A module script delays `load` until it has started, not finished, so the page announces when
 * it has bound its listeners rather than leaving the suite to guess.
 */
function showStatus(report: Parameters<typeof kernelStatus>[0]): void {
  document.body.dataset.kernel = kernelStatus(report).state
}
