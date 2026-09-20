# 013 — End-to-end browser test harness

- **Labels** — `enhancement` · `priority:medium` · `complexity:m` · `agent-ready`
- **Depends on** — 006, 012
- **Traces to** — DESIGN.md § Implementation notes carried from the spike

## Context

A Node-side DOM harness cannot catch the class of bug that broke the spike twice. Node defines `process` itself, so the missing browser shim passed every jsdom test and failed instantly in Chrome.

## Scope

- Drive headless Chrome over the DevTools protocol: load the deck, assert cards render, move a bond, assert the dependent card changes.
- Capture console errors and exceptions, and fail the run on any.
- Assert the page is served over HTTP rather than loaded from disk, so static-serving bugs are exercised.

## Done when

- One command runs the suite against a freshly started `present()`.
- Removing the `process` shim makes the suite fail.

## Out of scope

- Cross-browser coverage. One real browser is the bar.

## Note

The second miss had the same shape: loading modules from disk meant the HTTP route was never exercised, and a broken static handler went unnoticed. Both requirements above exist to close those two holes.
