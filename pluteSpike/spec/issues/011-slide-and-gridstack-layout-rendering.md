# 011 — Slide and gridstack layout rendering

- **Labels** — `enhancement` · `priority:high` · `complexity:m` · `agent-ready`
- **Depends on** — 003, 010
- **Traces to** — DESIGN.md § The layout schema is gridstack-shaped, and hand-authored first

## Context

GridStack 13.3.0 is MIT, has no runtime dependencies, and ships its own type definitions. In v1 it renders a fixed layout; dragging comes later.

## Scope

- Render each slide's cards into a gridstack grid at the `{x, y, w, h}` the deck specifies.
- Static in v1: no dragging, no resizing.
- A card whose cell is missing at run time renders as a visibly broken card, not a gap.

## Done when

- A two-slide deck renders with every card at its specified geometry.
- Resizing the window keeps the layout coherent.

## Out of scope

- The visual editor. The schema makes it additive; this issue does not start it.
