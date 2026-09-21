// The deck: build a card per placement, then feed every card the kernel's output.
//
// Nothing here renders output or talks to the websocket. `render.js` owns Pluto's renderer,
// `kernel.js` owns the connection, `status.js` owns the chrome's state, and a card is only
// ever given content.

import { Card } from "./card.js"
import { Cues } from "./cues.js"
import { connect } from "./kernel.js"
import { createPainter, whenScriptsSettled } from "./render.js"
import { kernelStatus } from "./status.js"

/**
 * The bond a notebook declares to be told which color scheme the deck is being shown in.
 *
 * A contract with every notebook that opts in, so renaming it is a migration across all of
 * them. A notebook that declares no bond of this name is left alone.
 */
const THEME_BOND = "deck_theme"

/** The scheme the deck itself is styled for, which `deck.css` follows through the same query. */
const darkScheme = window.matchMedia("(prefers-color-scheme: dark)")

/** The key that puts the current slide's speaker cues over it, and takes them away again. */
const CUE_KEY = "c"

/** Keys that move the deck, and by how many slides. */
const NAVIGATION_KEYS = {
  ArrowRight: 1,
  PageDown: 1,
  ArrowLeft: -1,
  PageUp: -1,
}

const slidesElement = document.getElementById("slides")
const preambleElement = document.getElementById("preamble")
const statusElement = document.getElementById("kernel-status")
const positionElement = document.getElementById("slide-position")
const previousButton = document.getElementById("previous-slide")
const nextButton = document.getElementById("next-slide")
const cuesButton = document.getElementById("toggle-cues")

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
const sections = deck.slides.map(buildSlide)
const placed = deck.slides.flatMap((slide, index) => placeCards(sections[index], slide))

// Built before the kernel is reached, and deliberately: `connect` throws when there is no
// kernel to reach, and a cue is worth most in the minutes a lecturer spends without one.
const cues = new Cues({
  panel: document.getElementById("speaker-cues"),
  body: document.getElementById("cue-body"),
  slides: deck.slides,
})

let kernel = null
let current = 0
let connected = true
let failure = null
let refreshing = false
let refreshAgain = false

showSlide(0)
previousButton.addEventListener("click", () => showSlide(current - 1))
nextButton.addEventListener("click", () => showSlide(current + 1))
cuesButton.addEventListener("click", toggleCues)
window.addEventListener("keydown", onKeyDown)

showStatus()

try {
  kernel = await connect(session)
} catch (error) {
  failure = `the kernel could not be reached: ${error.message}`
  showStatus()
  throw error
}
paintContent = createPainter(kernel)

// Downstream cells finish after the cell they depend on, so a run is only settled once every
// cell the deck reads has come to rest — not only the one a bond feeds.
kernel.watch([...preamble, ...placed].map((card) => cellIdOf(card.name)))

darkScheme.addEventListener("change", publishTheme)
await publishTheme()

kernel.onChange(refresh)
kernel.onConnectionChange((state) => {
  connected = state.connected
  showStatus()
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
      showStatus()
    } while (refreshAgain)
  } finally {
    refreshing = false
  }
}

/**
 * Tell the kernel which color scheme the viewer is in.
 *
 * A plot paints its own paper in Julia, where nothing knows what the browser is showing, so a
 * dark deck otherwise carries a white slab per plot. No stylesheet reaches inside a rendered
 * figure — the colors are in the payload the kernel sent — so the only way to change them is
 * to have the kernel send different ones, which is what a bond and a reactive run already do.
 *
 * Written before the first paint, so a card is not painted light and then repainted dark.
 */
function publishTheme() {
  if (!kernel.declares(THEME_BOND)) return Promise.resolve()
  return kernel.setBond(THEME_BOND, darkScheme.matches ? "dark" : "light")
}

/** Show each card its cell's current output, and report whether any of them repainted. */
function show(cards) {
  let repainted = false
  for (const card of cards) repainted = card.show(kernel.content(cellIdOf(card.name))) || repainted
  return repainted
}

/**
 * Move to slide `index`, if there is one there.
 *
 * Every slide stays mounted and painted; only which one is visible changes. Unmounting would
 * throw away a Plotly card's rendered graph and have it rebuilt against a multi-megabyte
 * payload on the way back.
 */
function showSlide(index) {
  if (index < 0 || index >= sections.length) return
  current = index

  for (const [at, section] of sections.entries()) {
    section.dataset.current = String(at === index)
  }

  positionElement.textContent = `${index + 1} / ${sections.length}`
  previousButton.disabled = index === 0
  nextButton.disabled = index === sections.length - 1
  cues.show(index)
}

function toggleCues() {
  cues.toggle()
  cuesButton.setAttribute("aria-pressed", String(cues.open))
}

function onKeyDown(event) {
  // Alt+ArrowLeft is the browser's own history, and Ctrl/Meta combinations belong to the
  // browser too, so only an unmodified key moves the deck.
  if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return

  // A range input is driven with the same arrow keys, and every other key is a character a
  // text field is owed: a lecturer nudging a gain must not be thrown onto the next slide for
  // it, and one typing must not open the cues.
  if (event.target instanceof Element && event.target.closest("input, select, textarea, [contenteditable]")) {
    return
  }

  // Case-folded, because caps lock is not a modifier: it would otherwise leave the cue key
  // silently dead in exactly the room the cues exist for.
  if (event.key.toLowerCase() === CUE_KEY) {
    event.preventDefault()
    toggleCues()
    return
  }

  const step = NAVIGATION_KEYS[event.key]
  if (step === undefined) return

  event.preventDefault()
  showSlide(current + step)
}

function buildSlide(slide, index) {
  const section = document.createElement("section")
  section.className = "slide"
  // An untitled slide still needs a heading to be navigable by one; it just reads as a label
  // rather than as a title, which is what `data-titled` lets the stylesheet say.
  section.dataset.titled = String(slide.title != null)
  section.append(Object.assign(document.createElement("h2"), {
    textContent: slide.title ?? `Slide ${index + 1}`,
  }))

  const grid = document.createElement("div")
  grid.className = "grid"
  section.append(grid)
  slidesElement.append(section)

  return section
}

function placeCards(section, slide) {
  const grid = section.querySelector(".grid")

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

function showStatus() {
  const { state, message } = kernelStatus({ failure, connected, process: kernel?.status ?? null })
  statusElement.textContent = message
  document.body.dataset.kernel = state
}
