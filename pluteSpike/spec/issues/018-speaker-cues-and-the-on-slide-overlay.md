# 018 — Speaker cues and the on-slide overlay

- **Labels** — `enhancement` · `priority:high` · `complexity:m` · `agent-ready`
- **Depends on** — 003, 012
- **Traces to** — DESIGN.md § Speaker cues are the deck's, and reach the lecturer without
  a popup

## Context

Timing, what to say, what to do when a demo misbehaves. None of it can live in the notebook:
the card contract publishes any cell carrying a `card` key, so a cue there is either shown to
every student who opens the file or is scratch work no deck can read.

The reveal.js deck in `docs/slides/lecture-01/` solved this twice over. Reveal's own speaker
view opens a second window, and `assets/deck.js` adds an on-slide panel bound to a key because
that window can be blocked — "so the guidance is never stranded". The overlay is not merely the
fallback: a laptop plugged into a projector mirrors by default, and mirrored, a second window
shows the cues to the room exactly as the overlay does.

This is the first markdown the frontend renders itself, so it carries the parser the deck did
not have before.

## Scope

Cues are a slide-level key with no geometry, because they are not placed anywhere:

```json
{ "title": "Proportional", "notes": "notes/proportional.md", "cards": [ … ] }
```

**Loader.** `notes` is optional per slide: a relative path resolved against the deck file and
validated exactly as `"notebook"` is, with a deck naming a file that is not there failing at
load and reporting the slide and the resolved path. A `notes` value carrying grid keys is
refused.

**Serving.** The path is checked once, at load. The text is read when `/api/deck` is asked, so
a cue rewritten five minutes before a lecture needs a browser refresh rather than a kernel
restart. A file that has gone missing since load is reported in the payload rather than served
as empty.

**Parser.** A markdown parser is vendored into `frontend/vendor/` beside the Rainbow bundles —
zero runtime dependencies, an ESM build, a permissive licence; `marked` unless its current
build fails one of those. Imported by the deck's own module graph rather than by a build step,
because 007 is still deferred.

**Overlay.** A panel over the current slide, toggled by a key, rendering that slide's cues. It
follows the slide when the deck pages. A slide with no cues states that rather than showing an
empty panel. The key is announced in the deck chrome the way the existing navigation is, and is
subject to the same modifier and focus rules — a cue key must not fire while a lecturer is
typing in a widget.

The overlay scrolls its own overflow. Cues run to several hundred words and there is no
geometry for them to overflow.

**Example.** The lecture-1 deck gains cues for at least one slide, under `lecture-01/notes/`,
carrying the folder-per-deck convention.

## Done when

- A slide carrying `notes` shows that file's markdown in the overlay when the key is pressed,
  and hides it when pressed again — with bold, inline code, lists and nested lists correct.
- Paging while the overlay is open moves it to the new slide's cues.
- A slide with no `notes` shows a stated absence, not an empty box.
- Cues render with no kernel reachable, asserted with no session connected.
- Cues never appear on a slide, and no cue text reaches the card list `/api/deck` publishes.
- Editing a notes file and refreshing the browser shows the new text without restarting
  `present`.
- A deck naming a missing notes file fails at load, naming the slide and the resolved path.
- The cue key does not fire while focus is inside a widget.
- `] test PlutoDeck` is green, browser suite included.

## Out of scope

- The speaker window — 019.
- Guidance prose on the slide. `DESIGN.md` defers it: a notebook `md` cell carrying a `card`
  key already renders in Pluto and on the slide from one source. The two cases that would
  bring it back are recorded there.
- Per-card cues. A cue is about the beat, and the beat is the slide.
