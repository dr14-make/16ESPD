<script setup lang="ts">
// PROTOTYPE. PlutoDeck's <deck-card> as a Vue component: the box is Vue's, everything inside
// `host` belongs to Pluto's Preact renderer once the first paint lands.
import { onMounted, onUnmounted, ref } from "vue"
import { useSlideContext } from "@slidev/client"
import { loadPlotly, needsPlotly } from "@plutodeck/plotly.loader"
import { countMount, usePluto } from "../pluto.session"

const props = defineProps<{ name: string; x: number; y: number; w: number; h: number }>()

const { $renderContext } = useSlideContext()
const host = ref<HTMLElement>()
const source = ref<"placeholder" | "live">("placeholder")
// Outside a slide (the global layer) there is no render context to inject.
const mountKey = `${props.name}@${$renderContext?.value ?? "global"}`

let stamp: number | null = null
let stop: (() => void) | null = null

onMounted(async () => {
  countMount(mountKey, 1)
  const { kernel, painter, deck } = await usePluto()
  const cellId = deck.cards[props.name]
  if (cellId === undefined) {
    throw new Error(`the notebook declares no card "${props.name}"`)
  }

  const repaint = async (): Promise<void> => {
    const content = kernel.content(cellId)
    if (content === null || content.stamp === stamp || host.value === undefined) {
      return
    }
    stamp = content.stamp
    if (needsPlotly(content.body)) {
      await loadPlotly()
    }
    source.value = "live"
    painter(host.value, content)
  }

  await repaint()
  stop = kernel.onChange(() => void repaint())
})

onUnmounted(() => {
  countMount(mountKey, -1)
  stop?.()
})
</script>

<template>
  <div
    class="pluto-card"
    :data-source="source"
    :data-card="name"
    :style="{ gridColumn: `${x + 1} / span ${w}`, gridRow: `${y + 1} / span ${h}` }"
  >
    <p v-if="source === 'placeholder'" class="card-waiting">{{ name }}</p>
    <div ref="host" class="card-body" />
  </div>
</template>

<style>
.pluto-grid {
  display: grid;
  grid-template-columns: repeat(12, minmax(0, 1fr));
  grid-template-rows: repeat(12, minmax(0, 1fr));
  gap: 0.5rem;
  block-size: calc(100% - 4rem);
}

.pluto-card {
  background: var(--slidev-theme-background, #fff);
  border: 1px solid #d0d7de;
  border-radius: 6px;
  padding: 0.6rem;
  min-inline-size: 0;
  min-block-size: 0;
  overflow: auto;
  font-size: 0.8rem;
}

.pluto-card[data-source="placeholder"] {
  border-style: dashed;
  display: grid;
  place-items: center;
}

.card-waiting {
  margin: 0;
  opacity: 0.6;
  font-family: ui-monospace, monospace;
}

.card-body,
.card-body pluto-cell {
  display: block;
  min-inline-size: 0;
}

.card-body:has(.js-plotly-plot),
.card-body:has(.js-plotly-plot) > pluto-cell,
.card-body:has(.js-plotly-plot) > pluto-cell > * {
  block-size: 100%;
}

.card-body :first-child {
  margin-block-start: 0;
}

.card-body :last-child {
  margin-block-end: 0;
}

.card-body table {
  inline-size: 100%;
  border-collapse: collapse;
}

.card-body td {
  text-align: end;
  font-variant-numeric: tabular-nums;
}
</style>
