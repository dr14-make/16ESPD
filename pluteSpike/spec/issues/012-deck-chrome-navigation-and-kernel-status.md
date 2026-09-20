# 012 — Deck chrome: navigation and kernel status

- **Labels** — `enhancement` · `priority:medium` · `complexity:s` · `agent-ready`
- **Depends on** — 011
- **Traces to** — DESIGN.md § Cards show placeholders until the kernel is live

## Context

The nineteen seconds between the page going live and the first card having content is the moment a lecturer decides whether this tool is trustworthy.

## Scope

- Next and previous slide, by pointer and by keyboard.
- One global kernel state on the deck chrome: connecting, ready, offline, error.
- That global state carries the warming-up message, so individual placeholders do not have to.

## Done when

- Navigation works by keyboard and by pointer.
- The status reflects a kernel that is starting, one that is ready, and one that is lost.

## Out of scope

- URL-fragment deep links. Parked in DESIGN.md; do not decide it here.
