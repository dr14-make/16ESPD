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
| [007](issues/007-typescript-build-pipeline.md) | TypeScript build pipeline | `enhancement` | `high` | `m` | yes | 001 | todo |
| [008](issues/008-kernel-client-connect-bonds-settle.md) | Kernel client: connect, bonds, settle | `enhancement` | `high` | `m` | yes | 007 | **done** |
| [009](issues/009-card-renderer-via-rainbow-ui.md) | Card renderer via rainbow ui | `enhancement` | `high` | `m` | yes | 007 | **done** |
| [010](issues/010-card-state-machine-placeholder-to-live.md) | Card state machine: placeholder to live | `enhancement` | `high` | `s` | yes | 008, 009 | **done** |
| [011](issues/011-slide-layout-geometry-and-broken-cards.md) | Slide layout: geometry, overlap and broken cards | `enhancement` | `high` | `s` | yes | 003, 010 | **partial** |
| [012](issues/012-deck-chrome-navigation-and-kernel-status.md) | Deck chrome: navigation and kernel status | `enhancement` | `medium` | `s` | yes | 011 | **done** |
| [013](issues/013-end-to-end-browser-test-harness.md) | End-to-end browser test harness | `enhancement` | `medium` | `m` | yes | 006, 012 | **done** |
| [014](issues/014-example-deck-lecture-1-cruise-control.md) | Example deck: lecture 1 cruise control | `enhancement` | `medium` | `s` | no | 006, 012 | **done** |
| [015](issues/015-release-process-build-force-add-bundle-tag.md) | Release process: build, force-add bundle, tag | `enhancement` `tech-debt` | `medium` | `s` | yes | 001, 007 | todo |
| [016](issues/016-publish-the-deck-theme-as-a-bond.md) | Publish the deck's theme as a bond | `enhancement` | `high` | `m` | no | 008, 012 | **done** |
| [017](issues/017-repainting-a-plotly-card-mutates-a-shared-payload.md) | Repainting a Plotly card mutates the payload it was given | `bug` | `high` | `s` | yes | 009, 010 | **done** |
| [018](issues/018-speaker-cues-and-the-on-slide-overlay.md) | Speaker cues and the on-slide overlay | `enhancement` | `high` | `m` | yes | 003, 012 | **done** |
| [019](issues/019-cue-only-speaker-window.md) | Cue-only speaker window | `enhancement` | `medium` | `s` | no | 018 | **done** |
| [020](issues/020-on-demand-clipping-check-across-every-card.md) | On-demand clipping check across every card | `enhancement` `tech-debt` | `medium` | `s` | yes | 011, 012 | todo |
| [021](issues/021-the-deck-cannot-tell-a-dead-kernel-from-a-cold-one.md) | The deck cannot tell a dead kernel from a cold one | `bug` | `high` | `s` | no | 012 | todo |

009 was run first as a de-risking spike, out of dependency order, because it is the only issue
whose failure would invalidate the design. Two findings from that spike were new and are not in
`DESIGN.md`: decks need a hidden preamble card, and offline Plotly costs 3.82 MB of notebook
state. `../HANDOFF.md` carries the detail; the preamble is now part of the deck schema.

008, 009 and 010 landed together, against the plain ES modules `frontend_directory()` already
serves. 007 stays deferred, so `frontend/vendor/` holds the Rainbow bundles rather than a build
producing them.

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

Still open, and not 013's to close: no browser ever loads a deck out of `frontend-dist`,
because 007 has not built one. `server.jl` covers which directory `frontend_directory()`
picks and how a hashed asset is cached, against a stand-in bundle; a real one arrives with
007 and 015.

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
| Bundle gitignored, force-added on release | 001, 015 |
| The deck is a separate JSON file | 003 |
| Cards address cells by a `card` metadata key | 002, 003 |
| Layout gridstack-shaped, hand-authored first | 003, 011 |
| Cards render through Pluto's own renderer | 009 |
| One kernel per instance, never multi-tenant | 004 |
| Cards show placeholders until the kernel is live | 010, 012 |
| Cards render through Pluto's own renderer | 009, 016 |
| Spike findings carried forward | 005, 008, 013 |
| Speaker cues are the deck's, and reach the lecturer without a popup | 018, 019 |

`DESIGN.md` § Open produced no issues on purpose. `persist_js_state` and Plotly zoom retention,
the sanitization posture, navigation deep links and schema versioning all settle better against
real code, and 012 explicitly declines to decide the navigation one.

## Not in this plan

The visual layout editor, cached snapshots, static export, PlutoSliderServer publishing, and
authoring support for writing `card` keys from inside Pluto. Each is named in `DESIGN.md` as
deferred, and each was kept cheap by a decision above rather than left to a future rewrite.
