// The deck: build a card per placement, then feed every card the kernel's output.
//
// Nothing here renders output or talks to the websocket. `render.js` owns Pluto's renderer,
// `kernel.js` owns the connection, and a card is only ever given content.

import { Card } from "./card.js"
import { connect } from "./kernel.js"
import { createPainter, whenScriptsSettled } from "./render.js"

const slidesElement = document.getElementById("slides")
const preambleElement = document.getElementById("preamble")
const statusElement = document.getElementById("kernel-status")

const [session, deck] = await Promise.all([
  fetch("/api/session").then((response) => response.json()),
  fetch("/api/deck").then((response) => response.json()),
])

document.getElementById("deck-title").textContent = fileName(deck.path)
document.getElementById("deck-notebook").textContent = fileName(deck.notebook)
document.getElementById("editor-link").href = session.editUrl

// Cards are built before the kernel is connected, because a labelled placeholder during the
// twenty-odd seconds a cold kernel takes is the whole difference between warming up and broken.
let paintContent = null
const paint = (host, content) => paintContent(host, content)

// Preamble cards are rendered and never shown: `enable_plutoplotly_offline()` is a cell whose
// output is a script that loads a library onto `window`, which every plot card needs to have
// run and no slide should display.
const preamble = deck.preamble.map((name) => mount(preambleElement, name))
const placed = deck.slides.flatMap(buildSlide)

let refreshing = false
let refreshAgain = false

setStatus("waiting", "connecting to the kernel")
const kernel = await connect(session)
paintContent = createPainter(kernel)

// Downstream cells finish after the cell they depend on, so a run is only settled once every
// cell the deck reads has come to rest — not only the one a bond feeds.
kernel.watch([...preamble, ...placed].map((card) => cellIdOf(card.name)))

kernel.onChange(refresh)
kernel.onConnectionChange(({ connected }) => {
  if (!connected) setStatus("waiting", "the kernel connection dropped")
})
await refresh()

/**
 * Bring every card up to date with the kernel.
 *
 * A diff arrives for every cell many times per run and each one lands here, so a refresh that
 * is already in flight records that it has to go round once more rather than stacking up.
 */
async function refresh() {
  if (refreshing) {
    refreshAgain = true
    return
  }
  refreshing = true
  try {
    do {
      refreshAgain = false
      // A plot card drawn before the preamble's script has finished draws nothing, so the two
      // groups are painted in order rather than together.
      if (show(preamble)) await whenScriptsSettled()
      show(placed)
      const status = kernel.status
      setStatus(status === "ready" ? "ready" : "waiting", `kernel ${status.replace(/_/g, " ")}`)
    } while (refreshAgain)
  } finally {
    refreshing = false
  }
}

/** Show each card its cell's current output, and report whether any of them repainted. */
function show(cards) {
  let repainted = false
  for (const card of cards) repainted = card.show(kernel.content(cellIdOf(card.name))) || repainted
  return repainted
}

function buildSlide(slide, index) {
  const section = document.createElement("section")
  section.className = "slide"
  section.append(Object.assign(document.createElement("h2"), { textContent: `Slide ${index + 1}` }))

  const grid = document.createElement("div")
  grid.className = "grid"
  section.append(grid)
  slidesElement.append(section)

  return slide.cards.map((placement) => {
    const card = mount(grid, placement.card)
    card.element.style.gridColumn = `${placement.x + 1} / span ${placement.w}`
    card.element.style.gridRow = `${placement.y + 1} / span ${placement.h}`
    return card
  })
}

function mount(host, name) {
  const card = new Card({ name, paint })
  host.append(card.element)
  return card
}

function cellIdOf(name) {
  return deck.cards[name]
}

function fileName(path) {
  return path.split("/").pop()
}

function setStatus(state, text) {
  statusElement.textContent = text
  document.body.dataset.kernel = state
}
