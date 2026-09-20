# 003 — deck.json schema, loader and validation

- **Labels** — `enhancement` · `priority:high` · `complexity:m` · `agent-ready`
- **Depends on** — 002
- **Traces to** — DESIGN.md § The deck is a separate JSON file / The layout schema is gridstack-shaped

## Context

The deck is hand-authored, so it will be wrong often, and it has to fail in a way that names what a human must fix. The schema carries gridstack's geometry from the start so the visual editor is additive later rather than a migration.

## Scope

- Schema: a `notebook` path, and `slides[]` where each slide holds `cards[]` of `{card, x, y, w, h}`.
- Leave room for a per-card snapshot reference without implementing snapshots.
- Load, parse, and resolve every card name against `cards()` from 002.
- Fail at load naming each unresolved card and the slide it sits on.

## Done when

- A valid deck loads into a typed structure.
- A deck referencing an unknown card errors with that card's name and slide index, not a stack trace.
- Malformed geometry is rejected at load, not at render.

## Out of scope

- Schema migration or versioning. One schema, no versions yet.
