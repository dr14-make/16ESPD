// One kernel connection per browser window, shared by every live card in it.
//
// Slidev runs each window — the audience view, presenter mode — as an app of its own, so each
// opens its own websocket to Pluto.

import { shallowRef, watch } from "vue"
import type { Ref } from "vue"
import { connect } from "./kernel.client.js"
import type { Kernel } from "./kernel.client.js"
import { kernelStatus } from "./kernel.status.js"
import type { KernelReport } from "./kernel.status.js"
import { sizePlotsToTheirCards } from "./plot.size.js"
import { createPainter } from "./render.painter.js"
import type { Painter } from "./render.painter.js"
import { THEME_BOND, fetchJson, isCardIndex, isSession } from "./session.interface.js"

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

/** What Slidev says about the window the session runs in. */
export interface View {
  readonly isDark: Readonly<Ref<boolean>>
  readonly isPresenter: Readonly<Ref<boolean>>
}

/** The session once it is up, for the bond layer to render from. */
export const live = shallowRef<Pluto | null>(null)

let begin: ((session: Promise<Pluto>) => void) | null = null
const started = new Promise<Pluto>((resolve) => {
  begin = resolve
})

/** Start the window's session; the bond layer calls this once, as the deck opens. */
export function startPluto(view: View): Promise<Pluto> {
  begin?.(start(view))
  begin = null
  return started
}

/** The window's session, once it has started. */
export function usePluto(): Promise<Pluto> {
  return started
}

async function start(view: View): Promise<Pluto> {
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
      const scheme = view.isDark.value ? "dark" : "light"
      if (!view.isPresenter.value && kernel.bonds()[THEME_BOND]?.value !== scheme) {
        await kernel.setBond(THEME_BOND, scheme)
      }
    }
    watch([view.isDark, view.isPresenter], () => void publish())
    await publish()
  }

  const pluto: Pluto = {
    kernel,
    painter: createPainter(kernel),
    cards,
    bindCards: Object.entries(cards)
      .filter(([, cellId]) => kernel.code(cellId).includes(BIND))
      .map(([name]) => name),
  }
  live.value = pluto
  return pluto
}

/** Put the window's kernel state on the page, where the browser suite reads it. */
function showStatus(report: KernelReport): void {
  const { state } = kernelStatus(report)
  if (document.body.dataset.kernel !== state) {
    document.body.dataset.kernel = state
  }
}
