# 011 — Slide layout: geometry, overlap and broken cards

- **Labels** — `enhancement` · `priority:high` · `complexity:s` · `agent-ready`
- **Depends on** — 003, 010
- **Traces to** — DESIGN.md § The layout schema is gridstack-shaped, and hand-authored first

## Context

The design decision this traces to buys a *schema* shaped like gridstack's — `{x, y, w, h}` in
grid units — so that a visual editor is additive later rather than a migration. It does not buy
the library. GridStack's value is drag-and-drop authoring, and DESIGN.md assigns that to the
editor it defers.

A 12-column CSS grid with a fixed row track renders that schema exactly, in no bytes: `h` is
literal, so a card with `h: 6` measures 328 px whether it holds a placeholder or a plot, and
nothing reflows when content arrives.

What a grid does not do is complain. Two cards given the same area stack silently, and a card
reaching past the last column adds one no other card occupies — both render as a plausible
slide rather than as an error, which for a hand-authored deck is the fault that actually
happens.

## Scope

- Render each slide's cards at the `{x, y, w, h}` the deck specifies, static in v1.
- Refuse at load a deck whose cards overlap, or reach past the last column, naming both cards
  and their extents.
- A card whose cell is missing at run time renders as a visibly broken card, not as a gap and
  not as a placeholder that never resolves.
- A card whose cell threw renders as visibly broken too. Pluto's error output is content like
  any other, so such a card reports `live` and logs nothing; nothing on the card or in the
  console distinguishes a deck that is working from one showing an error box on every slide.

## Done when

- A two-slide deck renders with every card at its specified geometry.
- Resizing the window keeps the layout coherent.
- A deck whose cards overlap names both of them and does not load.
- A card whose cell has gone is distinguishable from a card whose kernel is still warming up.
- A card whose cell threw is distinguishable from a card that rendered.

## Out of scope

- GridStack itself. Nothing here forecloses it; it arrives with the visual editor that needs
  it, against a schema that already carries its geometry.
- The visual editor. The schema makes it additive; this issue does not start it.
