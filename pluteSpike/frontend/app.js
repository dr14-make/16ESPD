import { connectDeck, onDeckState, pushAllBinds, getDeck } from "./rainbow-bridge.js"

const statusEl = document.getElementById("status")
const traceEl = document.getElementById("trace")
const canvas = document.getElementById("plot")
const ctx = canvas.getContext("2d")

let series = null

function setStatus(state, text) {
  statusEl.dataset.state = state
  statusEl.querySelector(".txt").textContent = text
}

// --- chart ------------------------------------------------------------------------------

function fit() {
  const dpr = window.devicePixelRatio || 1
  const r = canvas.getBoundingClientRect()
  canvas.width = r.width * dpr
  canvas.height = r.height * dpr
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
  return r
}

const css = (n) => getComputedStyle(document.documentElement).getPropertyValue(n).trim()

function panel(box, xs, lines, label) {
  const all = lines.flatMap((l) => l.y)
  let lo = Math.min(...all), hi = Math.max(...all)
  if (!isFinite(lo) || !isFinite(hi)) return
  const pad = (hi - lo) * 0.12 || 1
  lo -= pad; hi += pad
  const X = (v) => box.x + (v / xs[xs.length - 1]) * box.w
  const Y = (v) => box.y + box.h - ((v - lo) / (hi - lo)) * box.h

  ctx.strokeStyle = css("--rule"); ctx.lineWidth = 1
  ctx.fillStyle = css("--soft"); ctx.font = "11px ui-monospace, monospace"
  for (let i = 0; i <= 4; i++) {
    const v = lo + ((hi - lo) * i) / 4
    const y = Math.round(Y(v)) + 0.5
    ctx.beginPath(); ctx.moveTo(box.x, y); ctx.lineTo(box.x + box.w, y); ctx.stroke()
    ctx.fillText(v.toFixed(0), 4, y + 3)
  }
  ctx.fillText(label, box.x + 4, box.y + 12)

  for (const l of lines) {
    ctx.strokeStyle = l.color
    ctx.lineWidth = l.w ?? 1.8
    ctx.setLineDash(l.dash ?? [])
    ctx.beginPath()
    l.y.forEach((v, i) => (i ? ctx.lineTo(X(xs[i]), Y(v)) : ctx.moveTo(X(xs[i]), Y(v))))
    ctx.stroke()
  }
  ctx.setLineDash([])
}

function draw() {
  const r = fit()
  ctx.clearRect(0, 0, r.width, r.height)
  if (!series) {
    ctx.fillStyle = css("--soft"); ctx.font = "13px sans-serif"
    ctx.fillText("waiting for the kernel…", 40, 40)
    return
  }
  const L = 42, R = 12, gap = 26
  const h = (r.height - gap) / 2
  const t = series.t
  panel({ x: L, y: 8, w: r.width - L - R, h: h - 16 }, t,
    [
      { y: t.map(() => series.vref), color: css("--ref"), w: 1.2, dash: [5, 4] },
      { y: series.v, color: css("--v") },
    ], "speed  km/h")
  panel({ x: L, y: h + gap, w: r.width - L - R, h: h - 16 }, t,
    [
      { y: series.Tc, color: css("--tc") },
      { y: series.Td, color: css("--td") },
    ], "torque  N·m")
}

// --- data pull --------------------------------------------------------------------------

// The series arrives as a cell output, not through execute(): Pluto rotates to a fresh
// workspace module on each reactive run, so an out-of-band eval races it and can throw
// UndefVarError for variables the run has not republished yet.
function pullSeries() {
  const t0 = performance.now()
  const raw = getDeck()?.output("series_out")?.body
  if (!raw || raw === "null") return
  try {
    series = JSON.parse(raw)
    draw()
    traceEl.textContent =
      `series_out ${Math.round(performance.now() - t0)} ms · ${series.t.length} pts`
  } catch (e) {
    traceEl.textContent = `series parse failed: ${e.message}`
  }
}

// --- boot -------------------------------------------------------------------------------

window.addEventListener("resize", draw)
draw()

let wasBusy = false
onDeckState((s) => {
  if (!s.connected) return setStatus("offline", "kernel disconnected")
  if (s.error) return setStatus("error", s.error)
  setStatus(s.busy ? "busy" : "ready", s.busy ? "running Julia…" : "kernel ready")
  if (wasBusy && !s.busy) pullSeries()
  wasBusy = s.busy
})

try {
  setStatus("connecting", "connecting…")
  await connectDeck({ watch: ["sim", "series_out"] })
  setStatus("ready", "kernel ready")
  pushAllBinds() // bonds are `missing` until the deck states them
} catch (e) {
  setStatus("error", e.message)
  traceEl.textContent = `connect failed: ${e.message}`
}
