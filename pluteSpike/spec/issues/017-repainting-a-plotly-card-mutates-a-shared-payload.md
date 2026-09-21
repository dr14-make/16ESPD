# 017 — Repainting a Plotly card mutates the payload it was given

- **Labels** — `bug` · `priority:medium` · `complexity:m`
- **Depends on** — 009, 010
- **Traces to** — DESIGN.md § Cards render through Pluto's own renderer

## Context

The lecture-1 deck logs this 16 times in one run, while rendering correctly throughout:

```
Error: button name 'Copy PNG to Clipboard' is taken
```

It comes from Plotly's own modebar, which refuses two buttons of one name. PlutoPlotly appends
that button to the plot's config when it draws:

```julia
plot_obj.config.modeBarButtonsToAdd = _.union(
  plot_obj.config.modeBarButtonsToAdd,
  [ { name: "Copy PNG to Clipboard", ... }, ... ]
)
```

`_.union` compares by identity, and each draw appends a fresh object literal, so it cannot
dedupe them. That only matters if the same `plot_obj` is drawn more than once — and under a
deck it always is. `plot_obj` reaches the browser through `published_to_js`, which means one
object per cell, shared by every render of it. A deck repaints a card whenever its cell
re-runs, and places one cell on as many slides as the deck likes: the lecture deck has
`speed-plot` on five.

So the payload a card is handed is not read-only in practice, and a card that is drawn twice
hands the second draw a config the first one grew.

Confirmed: the duplicate name, the count, and that `_.union` cannot dedupe object literals.
Inferred, and worth checking first: that the shared `published_to_js` object is what carries
the mutation between draws.

## Scope

- Establish whether the mutation crosses draws through the published object.
- Give each draw a payload it may mutate freely, without copying a multi-megabyte library on
  every repaint.

## Done when

- A deck placing one plot cell on several slides, and repainting them, logs no console error.
- The lecture-1 deck's browser run reports no console error at all.

## Out of scope

- Fixing PlutoPlotly. The interaction is worth reporting upstream, but a deck cannot wait on
  it, and the same shape would arise from any library that treats its payload as scratch space.

## Note

Not `agent-ready`: the fix depends on which of `plot_obj`, its `config`, or the button array
actually needs isolating, and the cheap answer — deep-copying the payload — is the one that
costs 3.82 MB a repaint. That measurement has to come before the approach is chosen.
