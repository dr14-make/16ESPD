// Placeholder rendering: every card is a labelled box until a kernel client fills it.

const [session, deck] = await Promise.all([
  fetch("/api/session").then((r) => r.json()),
  fetch("/api/deck").then((r) => r.json()),
])

document.getElementById("deck-title").textContent = deck.path.split("/").pop()
document.getElementById("deck-notebook").textContent = deck.notebook
const editor = document.getElementById("editor-link")
editor.href = session.editUrl

const slides = document.getElementById("slides")
for (const [index, slide] of deck.slides.entries()) {
  const section = document.createElement("section")
  section.className = "slide"
  section.append(Object.assign(document.createElement("h2"), { textContent: `Slide ${index + 1}` }))

  const grid = document.createElement("div")
  grid.className = "grid"
  for (const placement of slide.cards) {
    const card = document.createElement("article")
    card.className = "card"
    card.style.gridColumn = `${placement.x + 1} / span ${placement.w}`
    card.style.gridRow = `${placement.y + 1} / span ${placement.h}`
    card.append(
      Object.assign(document.createElement("h3"), { textContent: placement.card }),
      Object.assign(document.createElement("p"), {
        className: "cell-id",
        textContent: deck.cards[placement.card],
      }),
      Object.assign(document.createElement("p"), { textContent: "waiting for the kernel" }),
    )
    grid.append(card)
  }
  section.append(grid)
  slides.append(section)
}
