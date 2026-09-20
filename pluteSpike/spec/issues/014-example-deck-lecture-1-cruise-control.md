# 014 — Example deck: lecture 1 cruise control

- **Labels** — `enhancement` · `priority:medium` · `complexity:s`
- **Depends on** — 006, 012
- **Traces to** — DESIGN.md § What it is

## Context

The spike's notebook already produces the lecture's numbers from the L0 parameter set. Porting it is the first real exercise of the card contract, and the first chance to learn whether hand-authoring a deck is tolerable.

## Scope

- Add `card` keys to the spike notebook's bind and output cells.
- Write `lecture-01.deck.json` arranging them across slides.
- Replace the hand-rolled canvas chart with a Plotly card.

## Done when

- `present()` on this deck shows the sliders, the metrics and an interactive plot.
- Moving a slider updates every dependent card.

## Out of scope

- Porting the remaining nine lecture notebooks.

## Note

Not marked `agent-ready`: it needs pedagogical judgment about what belongs on a slide, which is the author's call and cannot be specified up front.
