# 002 — Read card keys from notebook cell metadata

- **Labels** — `enhancement` · `priority:high` · `complexity:s` · `agent-ready`
- **Depends on** — 001
- **Traces to** — DESIGN.md § Cards address cells by a `card` key in the cell's own metadata

## Context

A card names a cell by a `card` key in that cell's Pluto metadata. Pluto writes non-default metadata keys into the `.jl` file as TOML on cell-metadata comment lines and preserves unknown keys across a save and load, so this needs no change to Pluto.

## Scope

- `cards(notebook)::Dict{String,UUID}` mapping card name to cell id.
- Reject duplicate card names within one notebook, naming the offender.
- A listing entry point so an author can see what a notebook publishes — Pluto's UI cannot set this key, so it is added by hand for now.

## Done when

- Unit test over a fixture notebook with three carded cells, one uncarded cell and one duplicate.
- A cell with no `card` key never appears in the result.

## Out of scope

- Writing `card` keys. Reading is enough for v1; authoring support is a later concern.
