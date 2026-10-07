// PROTOTYPE. One kernel connection per browser window, shared by every <PlutoCard> in it, plus
// the instrumentation the spike reads: which cards are mounted where, and every bond write.

import { reactive } from "vue"
import { connect } from "@plutodeck/kernel.client"
import type { Kernel } from "@plutodeck/kernel.client"
import { createPainter } from "@plutodeck/render.painter"
import type { Painter } from "@plutodeck/render.painter"
import { fetchJson, isDeck, isSession } from "@plutodeck/deck.interface"
import type { Deck } from "@plutodeck/deck.interface"

export interface Pluto {
  readonly kernel: Kernel
  readonly painter: Painter
  readonly deck: Deck
}

export const probe = reactive({
  status: "connecting",
  error: "",
  /** `${card}@${renderContext}` → how many instances are mounted right now. */
  mounts: {} as Record<string, number>,
  bondWrites: [] as { name: string; value: unknown; at: string }[],
})

let started: Promise<Pluto> | null = null

export function usePluto(): Promise<Pluto> {
  started ??= start()
  return started
}

async function start(): Promise<Pluto> {
  try {
    const [session, deck] = await Promise.all([
      fetchJson("/api/session", isSession),
      fetchJson("/api/deck", isDeck),
    ])
    const kernel = await connect(session)

    const setBond = kernel.setBond.bind(kernel)
    kernel.setBond = (name: string, value: unknown) => {
      const at = new Date().toISOString().slice(11, 23)
      probe.bondWrites.unshift({ name, value, at })
      probe.bondWrites.length = Math.min(probe.bondWrites.length, 12)
      console.log("[spike] setBond", name, value, at)
      return setBond(name, value)
    }

    kernel.watch(Object.values(deck.cards))
    probe.status = kernel.status
    kernel.onChange(() => {
      probe.status = kernel.status
    })
    return { kernel, painter: createPainter(kernel), deck }
  } catch (error) {
    probe.status = "failed"
    probe.error = String(error)
    throw error
  }
}

export function countMount(key: string, delta: 1 | -1): void {
  probe.mounts[key] = (probe.mounts[key] ?? 0) + delta
  console.log("[spike] mount", key, probe.mounts[key])
}
