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
| [008](issues/008-kernel-client-connect-bonds-settle.md) | Kernel client: connect, bonds, settle | `enhancement` | `high` | `m` | yes | 007 | todo |
| [009](issues/009-card-renderer-via-rainbow-ui.md) | Card renderer via rainbow ui | `enhancement` | `high` | `m` | yes | 007 | **spiked** |
| [010](issues/010-card-state-machine-placeholder-to-live.md) | Card state machine: placeholder to live | `enhancement` | `high` | `s` | yes | 008, 009 | todo |
| [011](issues/011-slide-and-gridstack-layout-rendering.md) | Slide and gridstack layout rendering | `enhancement` | `high` | `m` | yes | 003, 010 | todo |
| [012](issues/012-deck-chrome-navigation-and-kernel-status.md) | Deck chrome: navigation and kernel status | `enhancement` | `medium` | `s` | yes | 011 | todo |
| [013](issues/013-end-to-end-browser-test-harness.md) | End-to-end browser test harness | `enhancement` | `medium` | `m` | yes | 006, 012 | todo |
| [014](issues/014-example-deck-lecture-1-cruise-control.md) | Example deck: lecture 1 cruise control | `enhancement` | `medium` | `s` | no | 006, 012 | todo |
| [015](issues/015-release-process-build-force-add-bundle-tag.md) | Release process: build, force-add bundle, tag | `enhancement` `tech-debt` | `medium` | `s` | yes | 001, 007 | todo |

009 was run first as a de-risking spike, out of dependency order, because it is the only
issue whose failure would invalidate the design. It is **proven**: scripts execute, Julia-defined
widgets render, and an interactive Plotly card redraws from a slider in 38-84 ms. The package
code is still unwritten — `spiked` means the approach is settled, not that the issue is done. `../HANDOFF.md`
carries the detail. Two findings from it are new and are not in `DESIGN.md`: decks need a
hidden preamble card, and offline Plotly costs 3.82 MB of notebook state.

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
| Spike findings carried forward | 005, 008, 013 |

`DESIGN.md` § Open produced no issues on purpose. `persist_js_state` and Plotly zoom retention,
the sanitization posture, navigation deep links and schema versioning all settle better against
real code, and 012 explicitly declines to decide the navigation one.

## Not in this plan

The visual layout editor, cached snapshots, static export, PlutoSliderServer publishing, and
authoring support for writing `card` keys from inside Pluto. Each is named in `DESIGN.md` as
deferred, and each was kept cheap by a decision above rather than left to a future rewrite.
