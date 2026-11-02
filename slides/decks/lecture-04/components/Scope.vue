<script setup lang="ts">
// A digital storage oscilloscope that replays traces exported from a simulated Dyad model. Each
// channel gets its own band of the 10 × 8 graticule; the scales are fixed across the variants, so
// switching the duty or the modulation moves the trace and never the axes. A channel listed in
// `offset` is shown like a scope with its vertical offset set: the band is centered on a round value
// near that variant's mean, written on screen, so a small ripple on a large level fills the band. A
// channel listed in `average` shows its measured mean, like a scope's measurement readout.
import { useSlideContext } from "@slidev/client"
import { computed, onMounted, onUnmounted, ref, useId, watch } from "vue"

interface Channel { name: string; label: string; unit: string; y: number[] }
interface Variant { label: string; t: number[]; channels: Channel[] }
interface Traces { title: string; source: string; variants: Variant[] }

const props = withDefaults(
  defineProps<{
    src: string
    channels?: string[]
    variant?: number
    vdiv?: Record<string, number>
    offset?: string[]
    average?: string[]
  }>(),
  { variant: 0 },
)

const COLORS = ["#f5d742", "#3fd6e8", "#ee5fe0", "#5fe07a"]
const DIV = 48
const X0 = 14
const Y0 = 12
const W = 10 * DIV
const H = 8 * DIV
const STRIP = 30
const SWEEP_S = 2.4
const TRAIL = 0.55 * W
const FLOOR = 0.16

const uid = useId()
const data = ref<Traces | null>(null)
const status = ref<"loading" | "ready" | "missing">("loading")
const current = ref(props.variant)
const previous = ref(props.variant)
const playing = ref(true)
const reduced = ref(false)
const head = ref(0)

let context: ReturnType<typeof useSlideContext> | null = null
try {
  context = useSlideContext()
} catch {
  context = null
}
const animatable = computed(() => {
  if (!context) return true
  const where = context.$renderContext?.value
  if (context.$nav.value.isPrintMode || (where !== "slide" && where !== "presenter")) return false
  return context.$page.value === context.$nav.value.currentSlideNo
})
const sweeping = computed(() => status.value === "ready" && playing.value && !reduced.value && animatable.value)

async function load() {
  status.value = "loading"
  // The deck is published under a base path, so a root-relative src must be resolved against it.
  const url = props.src.startsWith("/") ? import.meta.env.BASE_URL.replace(/\/$/, "") + props.src : props.src
  try {
    const response = await fetch(url)
    if (!response.ok) throw new Error(String(response.status))
    // A dev server may answer a missing file with the app's HTML page, so parse before trusting it.
    const json = JSON.parse(await response.text()) as Traces
    if (!Array.isArray(json.variants) || json.variants.length === 0) throw new Error("no variants")
    data.value = json
    current.value = previous.value = Math.min(props.variant, json.variants.length - 1)
    status.value = "ready"
  } catch {
    data.value = null
    status.value = "missing"
  }
}

const shown = computed(() => {
  const all = data.value?.variants[0].channels.map((c) => c.name) ?? []
  return props.channels ?? all
})

function nice125(x: number) {
  if (!(x > 0)) return 1
  const e = Math.floor(Math.log10(x))
  const m = x / 10 ** e
  const step = [1, 2, 5, 10].find((s) => s >= m - 1e-9) ?? 10
  return step * 10 ** e
}

function si(value: number, unit: string) {
  const prefixes: [number, string][] = [[1e3, "k"], [1, ""], [1e-3, "m"], [1e-6, "µ"], [1e-9, "n"]]
  const [scale, prefix] = prefixes.find(([s]) => value >= s * 0.999) ?? [1e-9, "n"]
  const number = Number((value / scale).toPrecision(3))
  return unit ? `${number} ${prefix}${unit}` : `${number * scale}`
}

const mean = (y: number[]) => y.reduce((a, b) => a + b, 0) / Math.max(y.length, 1)

// One scale per channel across all variants. Without an offset the band is DC-referenced: zero is
// always inside it. With one, the scale fits the widest swing of any variant around its own mean.
const scales = computed(() => {
  const variants = data.value?.variants ?? []
  const n = Math.max(shown.value.length, 1)
  const bandDivs = 8 / n
  return shown.value.map((name, k) => {
    const offset = !!props.offset?.includes(name)
    const traces = variants.map((v) => v.channels.find((c) => c.name === name))
    const ranges = traces.map((ch) => (ch ? [Math.min(...ch.y), Math.max(...ch.y)] : [0, 0]))
    const lo = Math.min(0, ...ranges.map((r) => r[0]))
    const hi = Math.max(0, ...ranges.map((r) => r[1]))
    const swing = offset ? Math.max(...ranges.map((r) => r[1] - r[0])) : hi - lo
    const perDiv = props.vdiv?.[name] ?? nice125((swing || 1) / bandDivs)
    const step = perDiv / 5
    const mids = ranges.map((r) => (offset ? Math.round((r[0] + r[1]) / 2 / step) * step : (lo + hi) / 2))
    const averages = traces.map((ch) => (ch && props.average?.includes(name) ? mean(ch.y) : null))
    const first = traces.find(Boolean)
    const center = Y0 + ((k + 0.5) * H) / n
    return { name, label: first?.label ?? name, unit: first?.unit ?? "", perDiv, offset, mids, averages,
      center, color: COLORS[k % COLORS.length], top: Y0 + (k * H) / n, bottom: Y0 + ((k + 1) * H) / n,
      y: (v: number, vi: number) => center - ((v - mids[vi]) / perDiv) * DIV }
  })
})

// Readouts are drawn on an opaque box so a trace running under them stays legible; the font is
// monospaced, so the width follows from the character count.
const CHAR = 7.3
function labelWidth(label: string, note: string) {
  return (label.length + (note ? note.length + 1.5 : 0)) * CHAR + 8
}

function readout(value: number, unit: string) {
  return `${Number(value.toPrecision(3))} ${unit}`.trim()
}

// What the current variant puts on screen per band: where the ground marker sits and the offset or
// average readout.
const bands = computed(() =>
  scales.value.map((s) => {
    const vi = current.value
    const zero = s.y(0, vi)
    const inBand = zero >= s.top && zero <= s.bottom
    const notes = []
    if (s.offset) notes.push(`offset ${readout(s.mids[vi], s.unit)}`)
    const avg = s.averages[vi]
    if (avg !== null) notes.push(`avg ${`${avg.toPrecision(3)} ${s.unit}`.trim()}`)
    return { zero, inBand, marker: inBand ? zero : s.center, note: notes.join("  ") }
  }),
)

const timebase = computed(() => {
  const variants = data.value?.variants ?? []
  const t0 = variants[0]?.t[0] ?? 0
  const span = Math.max(...variants.map((v) => v.t[v.t.length - 1] - v.t[0]), 0)
  const perDiv = nice125(span / 10)
  return { t0, perDiv, x: (t: number) => X0 + ((t - t0) / perDiv) * DIV }
})

function pathOf(variant: Variant, name: string, y: (v: number) => number) {
  const ch = variant.channels.find((c) => c.name === name)
  if (!ch) return ""
  const x = timebase.value.x
  let d = ""
  for (let k = 0; k < ch.y.length; k++) d += `${k ? "L" : "M"}${x(variant.t[k]).toFixed(1)} ${y(ch.y[k]).toFixed(1)}`
  return d
}

const paths = computed(() =>
  (data.value?.variants ?? []).map((v, vi) => scales.value.map((s) => pathOf(v, s.name, (y) => s.y(y, vi)))),
)

// Normal trigger on the first channel shown: its first rising crossing of the middle of its range.
const trigger = computed(() => {
  const v = data.value?.variants[current.value]
  const s = scales.value[0]
  const ch = v?.channels.find((c) => c.name === s?.name)
  if (!v || !s || !ch) return null
  const level = s.mids[current.value]
  let k = ch.y.findIndex((y, i) => i > 0 && ch.y[i - 1] < level && y >= level)
  if (k < 0) k = 0
  return { x: timebase.value.x(v.t[k]), y: s.y(level, current.value), color: s.color }
})

const heads = computed(() => {
  const v = data.value?.variants[current.value]
  if (!v || !sweeping.value) return []
  const t = timebase.value.t0 + (head.value / DIV) * timebase.value.perDiv
  const dt = (v.t[v.t.length - 1] - v.t[0]) / (v.t.length - 1)
  const k = Math.round((t - v.t[0]) / dt)
  if (k < 0 || k >= v.t.length || head.value > W) return []
  return scales.value.flatMap((s) => {
    const ch = v.channels.find((c) => c.name === s.name)
    return ch ? [{ x: X0 + head.value, y: s.y(ch.y[k], current.value), color: s.color }] : []
  })
})

function choose(k: number) {
  if (k === current.value) return
  previous.value = sweeping.value ? current.value : k
  current.value = k
  head.value = 0
}

let frame = 0
let last = 0
function tick(now: number) {
  if (last !== 0 && sweeping.value) {
    head.value += ((now - last) / 1000) * (W / SWEEP_S)
    if (head.value > W + TRAIL) {
      head.value = 0
      previous.value = current.value
    }
  }
  last = now
  frame = requestAnimationFrame(tick)
}

watch(() => props.src, load)
onMounted(() => {
  reduced.value = !!window.matchMedia?.("(prefers-reduced-motion: reduce)").matches
  load()
  frame = requestAnimationFrame(tick)
})
onUnmounted(() => cancelAnimationFrame(frame))

const minorTicks = computed(() => {
  const ticks: { x1: number; y1: number; x2: number; y2: number }[] = []
  const cx = X0 + W / 2
  const cy = Y0 + H / 2
  for (let k = 0; k <= 50; k++) {
    const x = X0 + (k * W) / 50
    ticks.push({ x1: x, y1: cy - 3, x2: x, y2: cy + 3 })
  }
  for (let k = 0; k <= 40; k++) {
    const y = Y0 + (k * H) / 40
    ticks.push({ x1: cx - 3, y1: y, x2: cx + 3, y2: y })
  }
  return ticks
})
</script>

<template>
  <div class="scope">
    <svg :viewBox="`0 0 ${W + 2 * X0} ${H + Y0 + STRIP}`" class="scope-screen" role="img"
      :aria-label="data ? `Oscilloscope: ${data.title}, ${data.variants[current].label}` : 'Oscilloscope, no trace data yet'">
      <defs>
        <clipPath :id="`${uid}-now`"><rect :x="X0" :y="Y0" :width="sweeping ? Math.min(head, W) : W" :height="H" /></clipPath>
        <clipPath :id="`${uid}-old`"><rect :x="X0 + Math.min(head, W)" :y="Y0" :width="W - Math.min(head, W)" :height="H" /></clipPath>
        <linearGradient v-for="(s, k) in scales" :id="`${uid}-g${k}`" :key="s.name" gradientUnits="userSpaceOnUse"
          :x1="X0 + head - TRAIL" :x2="X0 + head" y1="0" y2="0">
          <stop offset="0" :stop-color="s.color" :stop-opacity="FLOOR" />
          <stop offset="1" :stop-color="s.color" stop-opacity="1" />
        </linearGradient>
      </defs>
      <rect :x="X0" :y="Y0" :width="W" :height="H" class="glass" />
      <line v-for="k in 9" :key="`v${k}`" :x1="X0 + k * DIV" :y1="Y0" :x2="X0 + k * DIV" :y2="Y0 + H" class="grid" />
      <line v-for="k in 7" :key="`h${k}`" :x1="X0" :y1="Y0 + k * DIV" :x2="X0 + W" :y2="Y0 + k * DIV" class="grid" />
      <line v-for="(t, k) in minorTicks" :key="`m${k}`" v-bind="t" class="tick" />
      <rect :x="X0" :y="Y0" :width="W" :height="H" class="frame" />

      <text v-if="status === 'missing'" :x="X0 + W / 2" :y="Y0 + H / 2 - 8" text-anchor="middle" class="message">trace data not exported yet</text>
      <text v-if="status === 'missing'" :x="X0 + W / 2" :y="Y0 + H / 2 + 14" text-anchor="middle" class="message small">{{ src }}</text>

      <template v-if="status === 'ready' && data">
        <g v-for="(s, k) in scales" :key="s.name">
          <line v-if="bands[k].inBand" :x1="X0" :y1="bands[k].zero" :x2="X0 + W" :y2="bands[k].zero" :stroke="s.color" class="ground" />
          <path :d="`M${X0 - 12} ${bands[k].marker - 6} h7 l5 6 l-5 6 h-7 z`" :fill="s.color" />
          <text :x="X0 - 8.5" :y="bands[k].marker + 4" text-anchor="middle" class="marker-num">{{ k + 1 }}</text>
          <path v-if="sweeping" :d="paths[previous][k]" :stroke="s.color" :stroke-opacity="FLOOR"
            :clip-path="`url(#${uid}-old)`" class="trace" />
          <path :d="paths[current][k]" :stroke="sweeping ? `url(#${uid}-g${k})` : s.color"
            :clip-path="`url(#${uid}-now)`" class="trace" />
        </g>
        <rect v-for="(s, k) in scales" :key="`b${s.name}`" :x="X0 + 2" :y="s.top + 2" height="16"
          :width="labelWidth(s.label, bands[k].note)" class="label-box" />
        <text v-for="(s, k) in scales" :key="`l${s.name}`" :x="X0 + 6" :y="s.top + 14" :fill="s.color" class="band-label">
          {{ s.label }}<tspan v-if="bands[k].note" class="band-note" dx="10">{{ bands[k].note }}</tspan>
        </text>
        <g v-for="(p, k) in heads" :key="`head${k}`">
          <circle :cx="p.x" :cy="p.y" r="6" :fill="p.color" opacity="0.25" />
          <circle :cx="p.x" :cy="p.y" r="2.4" fill="#fff" />
        </g>
        <g v-if="trigger">
          <path :d="`M${trigger.x - 6} ${Y0 - 10} h12 l-6 9 z`" class="trig" />
          <text :x="trigger.x + 8" :y="Y0 - 2" class="trig-t">T</text>
          <path :d="`M${X0 + W + 1} ${trigger.y} l8 -6 v12 z`" :fill="trigger.color" />
        </g>
        <rect :x="X0 + W - 10 - labelWidth(data.variants[current].label, '')" :y="Y0 + 2" height="16"
          :width="labelWidth(data.variants[current].label, '') + 8" class="label-box" />
        <text :x="X0 + W - 6" :y="Y0 + 14" text-anchor="end" class="status">{{ data.variants[current].label }}</text>
      </template>

      <g class="strip">
        <text v-for="(s, k) in scales" :key="`s${k}`" :x="X0 + (k * (W - 74)) / scales.length" :y="Y0 + H + 21" :fill="s.color">
          CH{{ k + 1 }} {{ si(s.perDiv, s.unit) }}/div
        </text>
        <text v-if="status === 'ready'" :x="X0 + W" :y="Y0 + H + 21" text-anchor="end" class="timebase">
          {{ si(timebase.perDiv, "s") }}/div
        </text>
      </g>
    </svg>

    <div v-if="status === 'ready'" class="scope-controls">
      <button :disabled="reduced" @click="playing = !playing">
        {{ sweeping ? "⏸ stop" : "▶ run" }}
      </button>
      <template v-if="data && data.variants.length > 1">
        <button v-for="(v, k) in data.variants" :key="v.label" :class="{ on: k === current }" @click="choose(k)">
          {{ v.label }}
        </button>
      </template>
    </div>
    <div v-if="data" class="scope-caption">
      <div>{{ data.title }}</div>
      <div class="source">source: {{ data.source }}</div>
    </div>
  </div>
</template>

<style>
.scope {
  background: #23292e;
  border-radius: 8px;
  padding: 0.35rem 0.45rem 0.4rem;
  color: #d8dee4;
  margin: 0 auto;
  width: fit-content;
  max-width: 100%;
}
.scope-screen { display: block; height: 26rem; max-width: 100%; }
.scope-screen text { font-family: ui-monospace, "DejaVu Sans Mono", monospace; }
.scope .glass { fill: #070c0a; }
.scope .grid { stroke: #ffffff; stroke-opacity: 0.2; stroke-width: 1; stroke-dasharray: 1 3; }
.scope .tick { stroke: #ffffff; stroke-opacity: 0.3; stroke-width: 1; }
.scope .frame { fill: none; stroke: #ffffff; stroke-opacity: 0.35; stroke-width: 1; }
.scope .ground { stroke-opacity: 0.25; stroke-width: 1; stroke-dasharray: 2 4; }
.scope .marker-num { font-size: 10px; font-weight: 700; fill: #070c0a; }
.scope .band-label, .scope .status, .scope .message { paint-order: stroke; stroke: #070c0a; stroke-width: 4px; }
.scope .band-label { font-size: 12px; }
.scope .band-note { fill: #e8edf2; }
.scope .label-box { fill: #070c0a; fill-opacity: 0.85; }
.scope .trace { fill: none; stroke-width: 1.8; stroke-linejoin: round; }
.scope .trig { fill: #ff9a3c; }
.scope .trig-t { font-size: 9px; font-weight: 700; fill: #ff9a3c; }
.scope .status { font-size: 12px; fill: #e8edf2; }
.scope .message { font-size: 17px; fill: #9fb0a8; }
.scope .message.small { font-size: 12px; opacity: 0.7; }
.scope .strip text { font-size: 11.5px; font-weight: 600; }
.scope .strip .timebase { fill: #e8edf2; }
.scope-controls { display: flex; gap: 0.35rem; justify-content: center; flex-wrap: wrap; margin-top: 0.2rem; }
.scope-controls button {
  font-size: 0.7rem;
  line-height: 1rem;
  padding: 0.1rem 0.55rem;
  border: 1px solid #5a6672;
  border-radius: 4px;
  background: #313941;
  color: #e8edf2;
}
.scope-controls button.on { background: #4d4220; border-color: #f5d742; }
.scope-controls button:disabled { opacity: 0.4; }
.scope-caption { font-size: 0.68rem; line-height: 0.95rem; text-align: center; margin-top: 0.2rem; }
.scope-caption .source { opacity: 0.65; font-size: 0.6rem; }
</style>
