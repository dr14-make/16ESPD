# 019 — Cue-only speaker window

- **Labels** — `enhancement` · `priority:medium` · `complexity:s`
- **Depends on** — 018
- **Traces to** — DESIGN.md § Speaker cues are the deck's, and reach the lecturer without
  a popup

## Context

018 guarantees the cues are never stranded. This is the better way to read them when the room
allows it: a second window on the lecturer's own screen while the projector carries the deck.

It renders no cards. No kernel, no Rainbow bundle, no bonds, no published objects — only the
cue text and which slide it belongs to. That is what keeps it a second page rather than a
second renderer, and it is why it survives a kernel that has died.

Reveal's `S` is blocked because a keypress calls `window.open` from code. A link in the deck
chrome is a click the viewer made, and browsers do not block those — the same shape as the
existing "open the notebook in Pluto" link. The two windows are same-origin, so the slide
number crosses on a `BroadcastChannel` with no handshake and no opener relationship.

## Scope

- A second page served by the deck's own server, showing the current slide's cues, its title
  and its position.
- Reached by a link in the deck chrome, never by `window.open` from a key handler.
- The deck publishes its slide index; the speaker page follows it.
- Opened with no deck window driving it, the page states that rather than showing slide one as
  though it were live.

## Done when

- Opening the link shows the current slide's cues, and paging the deck moves them.
- The page renders with no kernel reachable.
- Closing and reopening the deck window re-establishes the link without reloading the speaker
  page.
- The overlay of 018 keeps working while the speaker window is open.

## Out of scope

- Mirroring the slide, a next-slide preview, a timer, or a clock. Cue-only is the decision that
  keeps this page free of the renderer.
- Driving the deck from the speaker window.

## Note

Not marked `agent-ready`. What the page shows when the two windows disagree — a deck reloaded,
a second deck opened, a stale index — is a behavior this issue states the shape of but does not
settle, and guessing it wrong is worse than the popup it replaces.
