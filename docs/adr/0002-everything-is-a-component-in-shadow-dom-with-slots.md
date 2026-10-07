---
status: superseded by ADR-0003
---

# Everything on a page is a component, rendered in shadow DOM with slotted content

Every piece of a slide or guide is a `deck-*` element — blocks, layouts, block-level text and
inline text alike — so a deck is composed from one vocabulary rather than from HTML plus
utility classes. Each component keeps its structure and styles in a shadow root and receives
what an author writes as slotted children, never copying it inside. That is what keeps
authored text, live cards and figure paths in the document, where MathJax, highlight.js,
Pluto's renderer (`closest("pluto-cell")` does not cross a shadow root), find-in-page and the
build's structure, figure-slot and text-equivalence checks can all reach them.

## Considered options

- Light DOM throughout, as PlutoDeck's shell does today: one global stylesheet across every
  component type, with no isolation between them.
- Components only for structured blocks, prose left as plain HTML: rejected in favor of a
  single vocabulary, at the cost of more verbose markup.

## Consequences

- PlutoDeck's `deck-app`, `deck-slide` and `deck-card` move from light DOM to slots; a card's
  own output still renders as light DOM, which is what Pluto needs.
- Styles that must reach inside slotted content ship in the library's page-level stylesheet,
  since a shadow root's styles cannot.
