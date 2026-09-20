# 006 — present entry point

- **Labels** — `enhancement` · `priority:high` · `complexity:s` · `agent-ready`
- **Depends on** — 003, 004, 005
- **Traces to** — DESIGN.md § Shape

## Context

One command is the whole lecturer-facing interface.

## Scope

- `PlutoDeck.present(deck_path)` loading the deck, starting the session, serving, and blocking until interrupted.
- Print the deck URL and the Pluto editor URL on startup.
- Report progress while Pluto boots; the gap is around thirty seconds even on a warm machine.

## Done when

- From a clean checkout, one command serves a working deck.
- Interrupting it leaves no orphaned Julia or Pluto processes.

## Out of scope

- A shell CLI wrapper. The Julia entry point is enough.
