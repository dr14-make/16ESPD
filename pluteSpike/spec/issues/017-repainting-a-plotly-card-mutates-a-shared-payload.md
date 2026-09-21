# 017 — Repainting a Plotly card mutates the payload it was given

- **Labels** — `bug` · `priority:high` · `complexity:s` · `agent-ready`
- **Depends on** — 009, 010
- **Traces to** — DESIGN.md § Cards render through Pluto's own renderer

## Context

A plot card placed on more than one slide is blank. Measured on the lecture-1 deck:

| card | placements | traces attached | points | lines drawn |
|---|---|---|---|---|
| `open-loop` | 1 | 1 | 546 | 1 |
| `torque-plot` | 1 | 3 | 1180 | 3 |
| `speed-plot` | 5 | 2 | 591 | 2 on one placement, 0 on the other four |

Every placement has its data. What is missing is the drawn line, and one exception is thrown
while drawing:

```
Error: button name 'Copy PNG to Clipboard' is taken
```

Plotly refuses a second modebar button of a name it already has, and it throws *after* the
traces are attached and *before* any line is painted. So a blank plot holds its full data and
looks, to every other measure, like a plot that rendered.

`published_to_js` sends one payload per cell, and every render of that cell is handed the same
object. PlutoPlotly appends its modebar buttons to that object's `config` on each draw:

```julia
plot_obj.config.modeBarButtonsToAdd = _.union(
  plot_obj.config.modeBarButtonsToAdd,
  [ { name: "Copy PNG to Clipboard", ... }, ... ]
)
```

`_.union` compares by identity and each draw appends a fresh object literal, so it cannot
dedupe them. `plot_obj` is the published object itself — lodash's `_.update` returns the object
it mutated — so the second draw is handed a config the first one grew. One draw per card, so a
plot used once is fine and a plot reused across slides is broken.

**Confirmed**, not inferred: the carrier is the shared published object, and what crosses
between draws is the small `modeBarButtonsToAdd` array on its `config` — not the data. The
payload's bulk is typed arrays and, for the offline library, a 3.82 MB string; none of it is
touched. Isolating the payload's object spine per draw is therefore cheap, and deep-copying the
payload is the expensive answer to a question nobody asked.

## Scope

- Hand every draw a payload it may write to without the next draw seeing it.
- Do not copy what a draw does not write to.
- Do not reach into PlutoPlotly: the same shape arises from any library that treats the payload
  it was given as scratch space.
- Assert that a card is *drawn*, not merely rendered. A suite that looks for
  `.js-plotly-plot` passes over every blank plot above.

## Done when

- A deck placing one plot cell on several slides, and repainting them, draws a line on each.
- The lecture-1 deck's browser run reports no console error at all.
- The browser suite fails if the isolation is removed, and fails there alone.

## Out of scope

- Fixing PlutoPlotly. The interaction is worth reporting upstream, but a deck cannot wait on
  it, and the deck's own invariant — a published payload is shared — holds either way.
