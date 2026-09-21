# 020 — On-demand clipping check across every card

- **Labels** — `enhancement` · `tech-debt` · `priority:medium` · `complexity:s` · `agent-ready`
- **Depends on** — 011, 012

## Context

`PLAN.md` records that the lecture deck's geometry was retuned until "no card on any of its six
slides clips, measured". That measurement was made by hand, once. Nothing repeats it, and the
browser suite asserts nothing about it, so the next deck starts the same manual pass from
scratch and a regression in this one would go unseen.

Found while designing 018; it is independent of it, and of cues entirely.

The check is offered on demand rather than shown always. A card scrolling output whose size
nobody could predict is `overflow: auto` working as designed — that is why `.card` carries it —
so a red edge on every slide would be a warning learned and then ignored within one lecture.

## Scope

- A key marks every card on every slide whose content is taller than its box, and unmarks them.
- It reaches slides that are not showing. They keep their geometry precisely so that this
  works; a hidden slide already measures correctly.
- The key is announced in the deck chrome alongside the others, and follows the same modifier
  and focus rules as the existing navigation keys.
- A test helper exposing the same measurement, so the suite can assert a whole deck clean.

## Done when

- A deck with a deliberately undersized card reports exactly that card, on the slide it is on.
- The lecture-1 deck reports no clipping card on any of its six slides, asserted in the browser
  suite rather than described in `PLAN.md`.
- The key does not fire while focus is inside a widget.

## Out of scope

- Fixing any geometry the check finds.
- A load-time check. Height depends on the font and the column width, so only the browser knows.
- Changing `overflow: auto` on `.card`. Scrolling stays the right answer for output whose size
  the deck cannot predict; this issue only makes it visible.
