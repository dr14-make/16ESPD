<script setup lang="ts">
// A live card: the box is Vue's, and everything inside `host` belongs to Pluto's Preact
// renderer once the first paint lands, so the template binds nothing inside it.
import { onMounted, onUnmounted, ref } from "vue"
import { loadPlotly, needsPlotly } from "../src/plotly.loader"
import { usePluto } from "../src/pluto.session"
import type { CardSource } from "../src/session.interface"

/** The card name the notebook declares. Placed on a slide by the `Card` it sits in. */
const props = defineProps<{ name: string }>()

const host = ref<HTMLElement>()
const source = ref<CardSource>("placeholder")

let stop: (() => void) | null = null
let unmounted = false

onMounted(async () => {
  const { kernel, painter, cards } = await usePluto()
  const cellId = cards[props.name]
  // `present` refuses a deck naming an unknown card, but a name typed during a rehearsal reaches
  // the page through hot reload without a restart, so the card says what is wrong with it.
  if (cellId === undefined) {
    source.value = "unknown"
    return
  }

  // Repainting rebuilds every script in the card against whatever payload it reads, which for a
  // plot is a multi-megabyte published object. A diff arrives for every cell many times per run,
  // so a card repaints only when its own cell's `last_run_timestamp` moves.
  let stamp: number | null = null
  const repaint = async (): Promise<void> => {
    const next = kernel.stamp(cellId)
    if (next === null || next === stamp || host.value === undefined) {
      return
    }
    const content = kernel.content(cellId)
    if (content === null) {
      return
    }
    stamp = content.stamp
    // A plot card drawn before the library is on `window` draws nothing.
    if (needsPlotly(content.body)) {
      await loadPlotly()
    }
    if (!unmounted) {
      source.value = content.source
      painter(host.value, content)
    }
  }

  if (!unmounted) {
    stop = kernel.onChange(() => void repaint())
    await repaint()
  }
})

onUnmounted(() => {
  unmounted = true
  stop?.()
})
</script>

<template>
  <div class="pluto-card" :data-card="name" :data-source="source" :data-fault="source === 'unknown' || undefined">
    <p v-if="source === 'unknown'" class="pluto-card-unknown">the notebook declares no card "{{ name }}"</p>
    <p v-else-if="source === 'placeholder'" class="pluto-card-waiting">{{ name }}</p>
    <div ref="host" class="pluto-card-body" />
  </div>
</template>
