# PlutoDeck — implementation tracing

If you are here to start building, read `START-HERE.md` first — it names the first slice and
the rules that are not yours to relax.

Fifteen issues derived from `../DESIGN.md`. Each issue file states its own done-condition; this
file is the only place status lives, so recording progress never means editing an issue.

Labels follow the repository convention: a kind, `tech-debt` where the payoff is lower future
cost rather than new capability, a priority, and a complexity. `agent-ready` marks an issue that
states its own done-condition, holds its blast radius to one subsystem, and leaves no judgment
call open.

## Status

| # | Title | Kind | Pri | Cx | Agent-ready | Depends on | Status |
|---|---|---|---|---|---|---|---|
| [001](issues/001-package-skeleton-and-build-layout.md) | Package skeleton and build layout | `enhancement` | `high` | `s` | yes | — | **done** |
| [002](issues/002-read-card-keys-from-notebook-cell-metadata.md) | Read card keys from notebook cell metadata | `enhancement` | `high` | `s` | yes | 001 | **done** |
| [003](issues/003-deck-json-schema-loader-and-validation.md) | deck.json schema, loader and validation | `enhancement` | `high` | `m` | yes | 002 | **done** |
| [004](issues/004-pluto-session-lifecycle.md) | Pluto session lifecycle | `enhancement` | `high` | `m` | yes | 001 | **done** |
| [005](issues/005-http-server-and-the-frontend-directory-toggle.md) | HTTP server and the frontend_directory toggle | `enhancement` | `high` | `m` | yes | 001, 003, 004 | **done** |
| [006](issues/006-present-entry-point.md) | present entry point | `enhancement` | `high` | `s` | yes | 003, 004, 005 | **done** |
| [007](issues/007-typescript-build-pipeline.md) | TypeScript build pipeline | `enhancement` | `high` | `m` | yes | 001 | **done** |
| [008](issues/008-kernel-client-connect-bonds-settle.md) | Kernel client: connect, bonds, settle | `enhancement` | `high` | `m` | yes | 007 | **done** |
| [009](issues/009-card-renderer-via-rainbow-ui.md) | Card renderer via rainbow ui | `enhancement` | `high` | `m` | yes | 007 | **done** |
| [010](issues/010-card-state-machine-placeholder-to-live.md) | Card state machine: placeholder to live | `enhancement` | `high` | `s` | yes | 008, 009 | **done** |
| [011](issues/011-slide-layout-geometry-and-broken-cards.md) | Slide layout: geometry, overlap and broken cards | `enhancement` | `high` | `s` | yes | 003, 010 | **partial** |
| [012](issues/012-deck-chrome-navigation-and-kernel-status.md) | Deck chrome: navigation and kernel status | `enhancement` | `medium` | `s` | yes | 011 | **done** |
| [013](issues/013-end-to-end-browser-test-harness.md) | End-to-end browser test harness | `enhancement` | `medium` | `m` | yes | 006, 012 | **done** |
| [014](issues/014-example-deck-lecture-1-cruise-control.md) | Example deck: lecture 1 cruise control | `enhancement` | `medium` | `s` | no | 006, 012 | **done** |
| [015](issues/015-release-process-build-force-add-bundle-tag.md) | Release process: build, force-add bundle, tag | `enhancement` `tech-debt` | `medium` | `s` | yes | 001, 007 | todo — unblocked |
| [016](issues/016-publish-the-deck-theme-as-a-bond.md) | Publish the deck's theme as a bond | `enhancement` | `high` | `m` | no | 008, 012 | **done** |
| [017](issues/017-repainting-a-plotly-card-mutates-a-shared-payload.md) | Repainting a Plotly card mutates the payload it was given | `bug` | `high` | `s` | yes | 009, 010 | **done** |
| [018](issues/018-speaker-cues-and-the-on-slide-overlay.md) | Speaker cues and the on-slide overlay | `enhancement` | `high` | `m` | yes | 003, 012 | **done** |
| [019](issues/019-cue-only-speaker-window.md) | Cue-only speaker window | `enhancement` | `medium` | `s` | no | 018 | **done** |
| [020](issues/020-on-demand-clipping-check-across-every-card.md) | On-demand clipping check across every card | `enhancement` `tech-debt` | `medium` | `s` | yes | 011, 012 | todo |
| [021](issues/021-the-deck-cannot-tell-a-dead-kernel-from-a-cold-one.md) | The deck cannot tell a dead kernel from a cold one | `bug` | `high` | `s` | yes | 012 | todo |
| [022](issues/022-what-is-coming-next-on-the-speaker-page.md) | What is coming next, on the speaker page | `enhancement` | `low` | `s` | yes | 019 | todo |
| [023](issues/023-ctrl-c-does-not-always-stop-present-cleanly.md) | Ctrl-C does not always stop `present` cleanly | `bug` | `high` | `m` | no | 006 | todo |
| [024](issues/024-light-dom-components-carry-their-identity-twice.md) | Light-DOM components carry their identity twice | `refactor` `tech-debt` | `low` | `s` | yes | 007 | todo |
| [025](issues/025-render-the-math-a-control-theory-lecture-is-made-of.md) | Render the math a control-theory lecture is made of | `enhancement` | `high` | `m` | yes | 007, 009, 018 | **done** |
| [026](issues/026-attach-to-a-pluto-server-that-is-already-running.md) | Attach to a Pluto server that is already running | `enhancement` | `high` | `m` | no | 004, 021 | todo |
| [027](issues/027-offline-plotly-is-imported-from-a-data-url-and-costs-7gb.md) | Offline Plotly is imported from a `data:` URL, and the renderer pays 7 GB | `bug` | `high` | `s` | no | 014 | **done** — fixed by 028 |
| [028](issues/028-the-deck-serves-plotly-as-a-file.md) | The deck serves Plotly as a file, the way it already serves MathJax | `bug` | `high` | `m` | yes | 027, 007, 014 | **done** |

009 was run first as a de-risking spike, out of dependency order, because it is the only issue
whose failure would invalidate the design. Two findings from that spike were new and are not in
`DESIGN.md`: decks need a hidden preamble card, and offline Plotly costs 3.82 MB of notebook
state. `../HANDOFF.md` carries the detail; the preamble is now part of the deck schema.

008, 009 and 010 landed together, against the plain ES modules `frontend_directory()` served
before 007, with `frontend/vendor/` holding hand-copied dependencies.

007 is **done**, and it changed two things the rest of this plan assumed. The frontend is
TypeScript and Lit under `frontend/src/`, bundled by esbuild into `frontend-dist/`; every
dependency comes from npm, pinned exactly, and `frontend/vendor/` is deleted. The deck chrome,
the nav, the cue overlay and the speaker page are Lit components, and the state `deck.js` held in
module-level bindings travels through `@lit/context` from a provider boundary that is now an
element. What stayed exactly as it was is the part that breaks silently: a card's output renders
in light DOM, because `closest("pluto-cell")` and `deck.css` both stop at a shadow root, and
Rainbow's Preact renderer is untouched.

The issue file says two things that are no longer true, and were already recorded as such before
the work started: it asks for `gridstack` to be vendored, which 011's re-scoping had already
ruled out, and it assumes the bundle is gitignored. **The bundle is committed**, which reverses a
`DESIGN.md` decision; that section now says what the tree does and what would move it back.
`JULIA_PLUTODECK_FORCE_BUNDLED` is gone — with `frontend/` holding TypeScript there is no source
mode to force, or to fall back to — and `serve` refuses a missing bundle naming the command that
builds one. The dev loop is `mise run deck`, which now runs esbuild in watch mode beside the
deck.

The browser suite grew the assertion the whole issue exists for: the built bundle imports into a
page whose module graph is empty and resolves, where the published Rainbow build alone throws
`process is not defined`. Three tests that unit-tested frontend modules by importing them over
HTTP moved to `node --test` files beside the source, which is where two of them always belonged.

011 was re-scoped rather than implemented, and is **partial**. Its issue file called for the
GridStack library; the design decision it traces to calls only for a schema shaped like
GridStack's, and assigns drag-and-drop to the visual editor it defers. A 12-column CSS grid
already renders that schema exactly, so the 2.1 MB dependency bought nothing this version uses.
What the grid does not do is complain, so the loader now refuses a deck whose cards overlap or
reach past the last column.

`h` has since been made to mean what it says. A figure is given its card's height rather than
drawing itself 400 px inside it, a markdown card no longer spends 32 px of its box on a margin
Pluto's own stylesheet would have reset, and the lecture deck's geometry was retuned against
both: no card on any of its six slides clips, measured. The broken-card state is what remains
open.

014 chose six slides, one per lecture beat, which needed an open-loop cell the spike notebook
did not have — notebook 01's beat is a car with no controller, and setting every gain to zero
commands no torque rather than constant throttle. The deck is **done** and verified against a
live kernel: six titled slides, forty cards live, seven interactive plots, paging across all
six, and a gain change reaching every dependent card. It is not silent, though — 017 records
the console error it logs while doing all of that.

017 turned out to be blocking rather than cosmetic: four of the lecture deck's seven plots
were blank, holding their full data with no line drawn, because Plotly aborts a draw on a
duplicate modebar button after attaching the traces. The deck now hands every draw its own copy
of a payload's object spine, which shares the typed arrays and the 3.82 MB library string and
so costs nothing. The suite asserts a *drawn* line, on a cell placed on two slides, which is
the case that breaks.

016 is **done** against the lecture deck and the browser suite: the deck writes `deck_theme`
on connect and whenever the viewer's scheme changes, and the notebook picks its Plotly template
off it. Two findings came out of building it, both in `../HANDOFF.md` — `bonds` cannot say
whether a notebook declares a bond, and a card painting a body whose payload the kernel has
already replaced renders nothing at all.

013 is **done**. The harness drives headless Chrome over the DevTools protocol as part of
`] test PlutoDeck`, and it now drives `present` itself — in a process of its own, because
blocking until interrupted is the whole of what `present` adds over `start_session` and
`serve`, and the interrupt it prints as its last line is what has to take the kernel down
again. That the interrupt alone ends it, cleanly, is asserted; that no worker is left is
asserted in `session.jl`, from the process that owns one.

What it covers: the deck page over HTTP, a bond round trip, console errors, the chrome 012
adds — navigation by pointer and by keyboard, the ends, a widget that keeps the arrow keys it
needs — the geometry a hidden slide holds on to, a plot drawn on both the slides it is placed
on, a plot repainting to match the viewer's color scheme, and a figure being as tall as the
card the deck gave it. That last one is the only assertion that notices `deck.css` losing its
grip on a figure's height: a 400 px plot still draws, still reports `live`, and still answers
every other selector in the suite.

What was open and 007 closed: until it landed, no browser had ever loaded a deck out of
`frontend-dist`, because nothing had built one. Every browser test now runs against the real
bundle, which is the only thing served.

018 and 019 come from a second design pass, on prose PlutoDeck had no home for. It ended
smaller than it started. Guidance prose on the slide — "drag Kp until it oscillates" — was
designed and then deferred, because a notebook `md` cell carrying a `card` key already renders
in Pluto and on the slide from one source, and duplicating that in the deck buys wording that
differs per deck at the price of a second thing to keep in step. `DESIGN.md` records the two
cases that would bring it back. Speaker cues stayed, because the card contract leaves them
nowhere else to live.

020 was found while designing those and is independent of both: this plan says the lecture
deck's geometry was measured by hand, and nothing has measured it since.

Pinning 018's remaining conditions turned up 021. Asserting that the cues render against a
Pluto that is not there is the only test that puts the deck in front of an unreachable kernel,
and it showed the chrome reporting a cold start over a dead one — indefinitely. The cues
themselves were unaffected, so 018 is **done** on its own terms; what 021 carries is the chrome
lying about everything else on the slide.

025 is the first issue whose gap was invisible in the deck rather than visible in it: nothing
under `frontend/src/` mentioned MathJax, KaTeX or `.tex`, and the lecture-1 notebook happens to
carry no LaTeX, so six slides of a control-theory course rendered correctly while the thing the
course is mostly made of had no path to a screen at all.

Half of it needed no design. `PlutoRunner/src/display/LaTeX.jl` overrides Julia's Markdown HTML
writer inside the kernel, so every card the deck paints already carries `.tex` elements with
inline and display distinguished by the tag and by the delimiter — verified against a live
PlutoRunner rather than read off the source, because the override is invisible to a bare
`using Markdown`. There is nothing to parse and nothing to scan for `$`, so a dollar in prose is
not a false positive. The renderer and its configuration are Pluto's too.

Copying that configuration is where this issue went wrong on the way through, twice, and both
corrections are in `../DESIGN.md` rather than quietly applied. `ignoreHtmlClass` and
`processHtmlClass` were called load-bearing and are inert: they govern the walk inside the
elements a pass is handed, and those are the `.tex` nodes themselves. The `MathJax.Hub` shim was
called load-bearing and is gone — Plotly 2.x takes the MathJax 3 path and never calls it, and
Plotly 1.x calls `Hub.Typeset` with a single element and then reads `.MathJax_SVG` back out,
which MathJax 3 never writes, so no shim over MathJax 3 could serve it either. Copying Pluto's
comment instead of reading the caller is what put it there, and reading the caller is what
took it out.

The cue half had no precedent, because `marked` has no math. The renderer now emits Pluto's own
markup rather than a second convention, so one typeset pass covers a card and a cue alike and one
formula reads identically in the notebook, on a slide and in the speaker window. What counts as
math follows Julia's delimiter rule — no whitespace after an opening delimiter or before a
closing one — which is the whole of what leaves `costs $5 and $6` as the prose it is. Where the
two parsers genuinely disagree is recorded in `../DESIGN.md`.

Two things only showed up on a deck someone looked at, and neither would have failed the suite
as it stood. Display math copied out of the reveal deck — `$$ u \;=\; k\,e $$`, spaced inside its
delimiters — rendered as mangled prose, because Julia refuses that form and the tokenizer was
faithful to it. The cue tokenizer now accepts it, which makes the divergence list three rather
than one — and the card side of that divergence is worse than it first looked: the same line in
a notebook cell is not prose but `UndefVarError`, because Julia leaves a bare `$` for the `md`
macro to interpolate, so the whole card is lost rather than one line set wrong. And every inline formula in a cue was about twice its proper width: MathJax's
stylesheet lives in `document.head`, a document stylesheet does not cross a shadow boundary, and
the rule it was missing is the one hiding the assistive MathML.

Fixing the second turned up a third underneath it, and it is the one worth carrying forward:
the glyphs had never been drawn in a cue at all. `fontCache: "global"` emits every glyph once
into one `<svg>` in the document and reaches it by `<use href="#…">`, which does not cross a
shadow boundary, so each formula was a correctly sized box containing nothing — and what had
been legible in a cue until then was the unstyled assistive MathML, which is exactly what fixing
the stylesheet hid. Three assertions had passed over it: the container was present, its width
was right, and the delimiters were gone. Only looking at a rendered deck found it. The cache is
`local` now, and the suite asserts that a formula's glyphs are inside its own subtree.

All three are recorded in `../DESIGN.md`. The lesson the plan should keep is narrower than "test
the browser", which this project already does: an assertion about the shape of rendered math
says nothing about whether any of it was painted.

Two deviations from Pluto are deliberate and both come from the same place. Pluto loads MathJax
behind `requestIdleCallback` and typesets the whole document on arrival, because a cell can
render before the script lands and Pluto cannot tell which did. The deck awaits the load and
names the container it just painted instead: cues are read in the minutes before a kernel exists,
so a formula skipped for arriving early would show its dollars for the whole of the window the
cues are there to cover — and a document-wide pass reaches no cue at all, because the overlay and
the speaker page are Lit components with shadow roots.

## Order

Three tracks that converge. Julia and TypeScript are independent until 013.

```
Julia        001 ─→ 002 ─→ 003 ─┐
                 └─→ 004 ───────┼─→ 005 ─→ 006 ──┐
                                │                │
TypeScript   001 ─→ 007 ─→ 008 ─┼─→ 010 ─→ 011 ─→ 012 ─┼─→ 013 ─→ 014
                        └─→ 009 ┘                      │
Release      001, 007 ─────────────────────────────────┴─→ 015
```

001 unblocks everything. 003 and 004 are where the design's two contracts become code — the card
contract and the open-in-place contract — and both deserve to be right before anything renders.

## Tracing

Every issue names the `DESIGN.md` section it implements. The reverse mapping:

| Design decision | Issues |
|---|---|
| Julia package serving a prebuilt TypeScript bundle | 001, 005, 007 |
| The chrome is Lit; a card's output is light DOM | 007, 009, 011 |
| Shared state travels through `@lit/context` | 007, 012 |
| The bundler is what replaced the browser shim | 007 |
| The built bundle is committed | 001, 007, 015 |
| The deck is a separate JSON file | 003 |
| Cards address cells by a `card` metadata key | 002, 003 |
| Layout gridstack-shaped, hand-authored first | 003, 011 |
| Cards render through Pluto's own renderer | 009 |
| One kernel per instance, never multi-tenant | 004 |
| Cards show placeholders until the kernel is live | 010, 012 |
| Cards render through Pluto's own renderer | 009, 016 |
| Spike findings carried forward | 005, 008, 013 |
| Speaker cues are the deck's, and reach the lecturer without a popup | 018, 019, 025 |
| Math is Pluto's markup, drawn by Pluto's renderer | 025 |

`DESIGN.md` § Open produced no issues on purpose. `persist_js_state` and Plotly zoom retention,
the sanitization posture, navigation deep links and schema versioning all settle better against
real code, and 012 explicitly declines to decide the navigation one.

## Not in this plan

The visual layout editor, cached snapshots, static export, PlutoSliderServer publishing, and
authoring support for writing `card` keys from inside Pluto. Each is named in `DESIGN.md` as
deferred, and each was kept cheap by a decision above rather than left to a future rewrite.
