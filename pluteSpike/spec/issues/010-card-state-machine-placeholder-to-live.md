# 010 — Card state machine: placeholder to live

- **Labels** — `enhancement` · `priority:high` · `complexity:s` · `agent-ready`
- **Depends on** — 008, 009
- **Traces to** — DESIGN.md § Cards show placeholders until the kernel is live

## Context

Cold start is roughly thirty seconds on a warm machine with a notebook loading no packages, and minutes with a real one. Version one does not hide that, but it must not look broken, and it must not make snapshots a rewrite later.

## Scope

- A card is a state machine over where its HTML came from: `placeholder`, then `live`.
- A card holds no worker reference and pulls from nothing; it is given content.
- A labelled placeholder per card while no content exists.

## Done when

- A card shows its placeholder before the kernel is ready and swaps on first output.
- Adding a third content source requires no change to the renderer.

## Out of scope

- Cached snapshots. Deferred — but this issue is what keeps them cheap.
