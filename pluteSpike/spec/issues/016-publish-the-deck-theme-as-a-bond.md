# 016 — Publish the deck's theme as a bond

- **Labels** — `enhancement` · `priority:high` · `complexity:m`
- **Depends on** — 008, 012
- **Traces to** — DESIGN.md § Cards render through Pluto's own renderer

## Context

The deck honours the viewer's light/dark scheme; a card holding a Julia-rendered plot does not,
and cannot. The plot paints its own paper in Julia, where nothing knows what scheme the browser
is in, so a dark deck shows a dark page around a white plot panel — on a projector, the one
bright rectangle in the room.

Found while theming the demo. It is not a styling problem: no CSS reaches inside a rendered
Plotly figure to repaint it, because the colours are baked into the payload the kernel sent.

The fix reuses machinery that already works rather than adding any. Bonds already carry values
from the browser into the kernel, and cells already re-run when a bond changes. The deck knows
the scheme; the kernel does not; a bond is the pipe between them:

```julia
template = theme == "dark" ? "plotly_dark" : "plotly_white"
```

## Scope

- The deck sets a bond carrying the viewer's colour scheme, on connect and whenever it changes.
- A notebook that declares that bond gets the scheme; one that does not is unaffected.
- The convention is documented where a lecture author will find it.

## Done when

- A plot card repaints to match when the deck is switched between light and dark.
- A notebook declaring no such bond renders exactly as it does now.

## Out of scope

- Theming the cards themselves. `deck.css` already does that, and this issue is only about
  content the kernel rendered before the browser could reach it.
- A full theme object. One scheme name is what a plot template needs.

## Note

Not marked `agent-ready`: the bond's name is a contract between the package and every lecture
notebook that ever opts in, and renaming it later costs a migration across all of them. That
name is the author's call and has to be settled before the work starts.
