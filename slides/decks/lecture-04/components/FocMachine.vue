<script setup lang="ts">
// A permanent-magnet machine under field-oriented control, drawn with one pole pair: the rotor
// turns, the inverter keeps the stator current vector at a fixed angle to the magnets, and the
// same current is shown twice, as three alternating phase currents (what the stator carries) and
// as two steady numbers (what the rotor sees). Concepts only: no transform is computed beyond the
// projection the picture needs.
import { computed, onMounted, onUnmounted, ref } from "vue"

const props = withDefaults(defineProps<{ weakened?: boolean }>(), { weakened: false })

const theta = ref(0.6)
const playing = ref(true)
const weakening = ref(props.weakened)

// Current magnitude 1 at the inverter's limit. Field weakening turns part of it against the
// magnets, and what is left for torque shrinks so the magnitude stays at the limit.
const id = computed(() => (weakening.value ? -0.6 : 0))
const iq = computed(() => Math.sqrt(1 - id.value * id.value))

let frame = 0
let last = 0
function tick(now: number) {
  if (last !== 0 && playing.value) theta.value = (theta.value + (now - last) * 0.0016) % (2 * Math.PI)
  last = now
  frame = requestAnimationFrame(tick)
}
onMounted(() => {
  if (window.matchMedia?.("(prefers-reduced-motion: reduce)").matches) playing.value = false
  frame = requestAnimationFrame(tick)
})
onUnmounted(() => cancelAnimationFrame(frame))

// Machine picture: center and radii, y pointing down on screen, angles counterclockwise.
const C = { x: 200, y: 200 }
const R_STATOR = 170
const R_ROTOR = 92
const SCALE = 140
const pt = (r: number, a: number) => ({ x: C.x + r * Math.cos(a), y: C.y - r * Math.sin(a) })

const dAxis = computed(() => pt(R_ROTOR + 40, theta.value))
const qAxis = computed(() => pt(R_ROTOR + 40, theta.value + Math.PI / 2))
// The stator current vector in the fixed frame: i_d along the magnets, i_q 90 degrees ahead.
const current = computed(() => {
  const a = theta.value
  const x = id.value * Math.cos(a) - iq.value * Math.sin(a)
  const y = id.value * Math.sin(a) + iq.value * Math.cos(a)
  return { x: C.x + SCALE * x, y: C.y - SCALE * y }
})

const north = computed(() => {
  const a = theta.value
  const p1 = pt(R_ROTOR, a - Math.PI / 2)
  const p2 = pt(R_ROTOR, a + Math.PI / 2)
  return `M ${p1.x} ${p1.y} A ${R_ROTOR} ${R_ROTOR} 0 0 0 ${p2.x} ${p2.y} Z`
})
const south = computed(() => {
  const a = theta.value
  const p1 = pt(R_ROTOR, a + Math.PI / 2)
  const p2 = pt(R_ROTOR, a + (3 * Math.PI) / 2)
  return `M ${p1.x} ${p1.y} A ${R_ROTOR} ${R_ROTOR} 0 0 0 ${p2.x} ${p2.y} Z`
})
const nLabel = computed(() => pt(R_ROTOR * 0.55, theta.value))
const sLabel = computed(() => pt(R_ROTOR * 0.55, theta.value + Math.PI))

const PHASES = [
  { name: "a", angle: 0, color: "#1f5fa8" },
  { name: "b", angle: (2 * Math.PI) / 3, color: "#a75d00" },
  { name: "c", angle: (4 * Math.PI) / 3, color: "#2e8b57" },
]
// Each phase current is the current vector projected onto that phase's winding axis.
function phaseCurrent(angle: number, a: number) {
  const x = id.value * Math.cos(a) - iq.value * Math.sin(a)
  const y = id.value * Math.sin(a) + iq.value * Math.cos(a)
  return x * Math.cos(angle) + y * Math.sin(angle)
}

// Phase-current plot over one electrical revolution, with a cursor at the present angle.
const PLOT = { x: 0, y: 30, w: 330, h: 150 }
function wave(angle: number) {
  const n = 120
  let d = ""
  for (let k = 0; k <= n; k++) {
    const a = (2 * Math.PI * k) / n
    const x = PLOT.x + (PLOT.w * k) / n
    const y = PLOT.y + PLOT.h / 2 - (PLOT.h / 2.4) * phaseCurrent(angle, a)
    d += `${k === 0 ? "M" : "L"} ${x.toFixed(1)} ${y.toFixed(1)} `
  }
  return d
}
const cursorX = computed(() => PLOT.x + (PLOT.w * theta.value) / (2 * Math.PI))

// Rotor-frame bars: i_d and i_q against the same limit.
const BAR = { x0: 120, w: 180, y: 250 }
const barEnd = (v: number) => BAR.x0 + (BAR.w / 2) * v
</script>

<template>
  <div class="foc">
    <svg viewBox="0 0 400 400" class="foc-machine" role="img"
      aria-label="A two-pole permanent-magnet rotor turning inside a three-phase stator, with the stator current vector held 90 degrees ahead of the magnets">
      <circle :cx="C.x" :cy="C.y" :r="R_STATOR" class="stator" />
      <circle :cx="C.x" :cy="C.y" :r="R_STATOR - 26" class="airgap" />
      <g v-for="ph in PHASES" :key="ph.name">
        <line :x1="pt(R_STATOR - 26, ph.angle).x" :y1="pt(R_STATOR - 26, ph.angle).y"
          :x2="pt(R_STATOR - 26, ph.angle + Math.PI).x" :y2="pt(R_STATOR - 26, ph.angle + Math.PI).y"
          :stroke="ph.color" class="phase-axis" />
        <text :x="pt(R_STATOR - 12, ph.angle).x" :y="pt(R_STATOR - 12, ph.angle).y + 5"
          text-anchor="middle" :style="{ fill: ph.color }" class="phase-label">{{ ph.name }}</text>
      </g>
      <path :d="north" class="north" />
      <path :d="south" class="south" />
      <text :x="nLabel.x" :y="nLabel.y + 6" text-anchor="middle" class="pole">N</text>
      <text :x="sLabel.x" :y="sLabel.y + 6" text-anchor="middle" class="pole">S</text>
      <line :x1="C.x" :y1="C.y" :x2="dAxis.x" :y2="dAxis.y" class="axis" />
      <line :x1="C.x" :y1="C.y" :x2="qAxis.x" :y2="qAxis.y" class="axis" />
      <text :x="dAxis.x" :y="dAxis.y" class="axis-label">d</text>
      <text :x="qAxis.x" :y="qAxis.y" class="axis-label">q</text>
      <defs>
        <marker id="foc-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6"
          orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10 z" fill="#c0392b" /></marker>
      </defs>
      <line :x1="C.x" :y1="C.y" :x2="current.x" :y2="current.y" class="current" marker-end="url(#foc-arrow)" />
      <text :x="current.x + 6" :y="current.y - 6" class="current-label">i</text>
    </svg>

    <div class="foc-side">
      <svg viewBox="-10 0 350 300" class="foc-plots" role="img"
        aria-label="Left: the three phase currents alternate as the rotor turns. Right: the same current seen from the rotor is two steady bars, i_d and i_q.">
        <text x="0" y="16" class="title">the stator carries: three alternating currents</text>
        <line :x1="PLOT.x" :y1="PLOT.y + PLOT.h / 2" :x2="PLOT.x + PLOT.w" :y2="PLOT.y + PLOT.h / 2" class="zero" />
        <path v-for="ph in PHASES" :key="ph.name" :d="wave(ph.angle)" :stroke="ph.color" class="wave" />
        <line :x1="cursorX" :y1="PLOT.y" :x2="cursorX" :y2="PLOT.y + PLOT.h" class="cursor" />
        <text x="0" y="218" class="title">the rotor sees: two steady numbers</text>
        <line :x1="BAR.x0" y1="228" :x2="BAR.x0" y2="292" class="zero" />
        <text x="0" :y="BAR.y + 4" class="bar-label">i_d, field</text>
        <rect :x="Math.min(BAR.x0, barEnd(id))" :y="BAR.y - 10" :width="Math.abs(barEnd(id) - BAR.x0)" height="18" class="bar-d" />
        <text x="0" :y="BAR.y + 34" class="bar-label">i_q, torque</text>
        <rect :x="BAR.x0" :y="BAR.y + 20" :width="barEnd(iq) - BAR.x0" height="18" class="bar-q" />
      </svg>
      <div class="foc-controls">
        <button @click="playing = !playing">{{ playing ? "⏸ pause" : "▶ play" }}</button>
        <button :class="{ on: weakening }" @click="weakening = !weakening">
          field weakening {{ weakening ? "on" : "off" }}
        </button>
      </div>
    </div>
  </div>
</template>

<style>
.foc {
  display: grid;
  grid-template-columns: 1fr 1.05fr;
  gap: 0.75rem;
  align-items: center;
  background: #fff;
  color: #16202c;
  border-radius: 6px;
  padding: 0.25rem;
}
.foc svg text { font-family: sans-serif; fill: #16202c; }
.foc-machine { width: 100%; max-height: 22rem; }
.foc-plots { width: 100%; }
.foc .stator { fill: #eef1f4; stroke: #4a5a6b; stroke-width: 2; }
.foc .airgap { fill: #fff; stroke: #4a5a6b; stroke-width: 1; }
.foc .phase-axis { stroke-width: 1.5; stroke-dasharray: 5 4; opacity: 0.6; }
.foc .phase-label { font-size: 16px; font-weight: 600; }
.foc .north { fill: #d9534f; }
.foc .south { fill: #5b8fd6; }
.foc .pole { font-size: 20px; font-weight: 700; fill: #fff !important; }
.foc .axis { stroke: #16202c; stroke-width: 1.5; stroke-dasharray: 3 3; }
.foc .axis-label { font-size: 16px; font-style: italic; }
.foc .current { stroke: #c0392b; stroke-width: 5; }
.foc .current-label { font-size: 18px; font-weight: 700; fill: #c0392b !important; }
.foc .title { font-size: 14px; font-weight: 600; }
.foc .zero { stroke: #4a5a6b; stroke-width: 1; }
.foc .wave { fill: none; stroke-width: 2.5; }
.foc .cursor { stroke: #c0392b; stroke-width: 2; }
.foc .bar-label { font-size: 13px; }
.foc .bar-d { fill: #a75d00; }
.foc .bar-q { fill: #1f5fa8; }
.foc-controls { display: flex; gap: 0.5rem; justify-content: center; margin-top: 0.25rem; }
.foc-controls button {
  font-size: 0.75rem;
  padding: 0.15rem 0.6rem;
  border: 1px solid #4a5a6b;
  border-radius: 4px;
  background: #fff;
  color: #16202c;
}
.foc-controls button.on { background: #fdf0e0; border-color: #a75d00; }
</style>
