# 001 — Package skeleton and build layout

- **Labels** — `enhancement` · `priority:high` · `complexity:s` · `agent-ready`
- **Depends on** — —
- **Traces to** — DESIGN.md § Shape

## Context

Nothing exists yet. Everything else needs somewhere to live, and the bundle's ignore rule has to be right from the first commit or the history is already polluted.

## Scope

- `Project.toml` for `PlutoDeck`, with `Pluto` and `HTTP` as dependencies.
- `src/PlutoDeck.jl` exporting `present`, including `session.jl`, `deck.jl`, `cards.jl` and `server.jl` as stubs.
- `frontend/` and `frontend-dist/` directories.
- `.gitignore` carrying `frontend-dist` and `frontend-dist-*`.
- `test/runtests.jl`.

## Done when

- `] test PlutoDeck` runs green on an empty suite.
- `git status` stays clean after a frontend build drops files into `frontend-dist/`.

## Out of scope

- Any actual behavior. This issue is scaffolding.
