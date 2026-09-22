# 024 — Light-DOM components carry their identity twice

- **Labels** — `refactor` · `tech-debt` · `priority:low` · `complexity:s` · `agent-ready`
- **Depends on** — 007
- **Traces to** — DESIGN.md § The chrome is Lit; a card's own output is light DOM

## Context

`deck-slide` and `deck-card` render into light DOM so that `deck.css` and Pluto's renderer can
reach a card's output. Both then write a second copy of what they already are:

- `connectedCallback` adds `class="slide"` / `class="card"`, which `deck.css` selects on — while
  the same stylesheet selects `deck-app, speaker-page` by tag. The file does it both ways, and
  the class version leaves a window between element upgrade and `connectedCallback` in which the
  element is unstyled.
- `deck-card` takes `name` as an attribute and then writes `data-card` as a second copy of it;
  `deck-slide` takes `current` and writes `data-current`. The stylesheet and the browser suite
  then read the copy rather than the original. Two representations of one fact on one element is
  how they go out of step.

Raised in review of 007 and deferred there rather than widened into it: the change is
mechanical but touches roughly nineteen selectors in `deck.css` and a dozen in `browser.jl`,
which is a diff that would have buried the port it was attached to.

`data-source` is **not** in scope and stays. It is a state the component computes rather than a
copy of an input, and the suite's `MutationObserver` keys on it.

## Scope

- Select `deck-slide` and `deck-card` by tag, and drop the two `classList.add` calls.
- Read `[name=…]` and `:host([current])` rather than `data-card` and `data-current`.
- Update `deck.css` and `browser.jl` together, so the suite still pins the same behavior.

## Done when

- No component writes an attribute that restates one of its own inputs.
- `] test PlutoDeck` is green, browser tests included, with the same assertions as before.

## Out of scope

- `data-source`, and `document.body.dataset.kernel` / `.deck`, which are page-level signals the
  harness waits on rather than per-element identity.
