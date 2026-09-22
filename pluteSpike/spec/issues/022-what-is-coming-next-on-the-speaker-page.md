# 022 — What is coming next, on the speaker page

- **Labels** — `enhancement` · `priority:low` · `complexity:s` · `agent-ready`
- **Depends on** — 019
- **Traces to** — DESIGN.md § Speaker cues are the deck's, and reach the lecturer without
  a popup

## Context

The speaker page says where the deck is. It does not say what is next, so the decision a
lecturer actually makes at the end of a beat — move on now, or take one more question — is made
without the one fact that informs it.

Reveal's speaker view answers this with a thumbnail: two `<iframe>`s loading the whole deck
again, one driven to the current slide and one told `next`. That is cheap for reveal because
its slides are static HTML, and it is the wrong shape here twice over.

It would cost a second kernel websocket, the Rainbow bundle and the published Plotly payload
per frame, and it would forfeit the reason this page exists — it renders no cards, so it
survives a kernel that has died. Worse, a second live deck writes the `deck_theme` bond, and a
bond write is a reactive run: a preview would make the *presentation* re-run cells mid-lecture.
The browser suite already works around exactly this, injecting a second deck's messages on the
wire rather than opening one.

And a thumbnail would not earn it. Slides 2 through 6 of the lecture deck each show the same
speed plot beside a different set of gain sliders; their pictures are nearly indistinguishable.
What tells them apart is the title and the opening of the cue — "**Beat:** the fix, and its
cost. ~6 minutes."

So the preview is what distinguishes the slides, not a picture of them.

## Scope

- The speaker page shows the next slide's title and the first paragraph of its cue, below the
  current slide's cues and visibly subordinate to them.
- Nothing is fetched and no card is rendered: `/api/deck` already carries every slide's title
  and cue markdown, so this is the payload the page has.
- The first paragraph renders as markdown through the renderer the page already uses, so
  `**Beat:**` reads as it was written.
- It is clamped by CSS line count rather than truncated in JavaScript — a cue's first paragraph
  is short by convention and not by guarantee, and a clamp cannot cut a word or an open tag.
- The last slide says it is the last, rather than showing nothing.
- A next slide carrying no cues shows its title alone.
- The preview is as stale as the cues are, so a `lost` deck covers both under the chrome that
  already says so. No second caveat.

## Done when

- On any slide but the last, the speaker page names the next slide and the opening of its cue.
- On the last slide it says so.
- A next slide with no cues shows its title and no empty block.
- A cue whose first paragraph runs long is clamped, not cut mid-word.
- The page still renders with no kernel reachable, and still requests nothing but `/api/deck`.
- The browser suite asserts the above against the fixture deck.

## Out of scope

- A rendered thumbnail of the next slide, by iframe or otherwise. Ruled out above on the bond
  write, not merely on cost.
- A snapshot image. That needs the cached-snapshot machinery `DESIGN.md` defers, including the
  staleness problem it names — a stale snapshot looks exactly like a fresh one.
- A timer or a clock. Neither reads the deck, and both belong to whoever asks for them.
