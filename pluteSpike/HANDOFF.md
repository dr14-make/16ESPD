# Handover — PlutoDeck

Everything needed to pick this up cold. Read this file first, then the three it points to.

| Document | Holds |
|---|---|
| `spec/START-HERE.md` | **brief for the first implementing agent — read this if you are here to build** |
| `DESIGN.md` | the eight decisions, why each went the way it did, what was ruled out and on what evidence |
| `spec/PLAN.md` | fifteen issues, status table, dependency order, tracing back to design decisions |
| `spec/issues/*.md` | one file per issue: context, scope, done-condition, out of scope |
| `README.md` | the working spike and the ten findings that cost real debugging time |

## One-paragraph summary

PlutoDeck turns a Pluto notebook into a slide deck. Cells opt in by declaring a `card` name in
their own Pluto metadata; a hand-authored `deck.json` arranges those cards onto slides as
gridstack layouts; a Julia package serves a prebuilt TypeScript frontend that renders each card
with Pluto's own renderer, so plots stay interactive and `@bind` widgets defined in Julia keep
working. One kernel per running instance, never a multi-tenant server. The package lives in
`PlutoDeck.jl/` and so far carries the card contract and the deck loader; everything that
renders is still the spike in this directory that proves the transport works.

## Status

    [x] Research      @plutojl/rainbow verified end to end against a real kernel
    [x] Spike         pluteSpike/ — bonds in, outputs out, 80-125 ms round trip
    [x] Design        DESIGN.md, eight decisions settled
    [x] Spec          spec/PLAN.md, fifteen issues
    [x] Issue 009     de-risking spike PROVEN — Plotly renders and updates live
    [x] Issues 001-003  PlutoDeck.jl/ — skeleton, card keys, deck loader; `] test PlutoDeck` green
    [ ] Issues 004-008, 010-015

## Run the spike

    ./start.sh          # then open http://localhost:8099

First run installs Pluto into `backend/` and takes a minute. Julia comes from the `dyad-3.3.0`
channel, matching `.vscode/settings.json`. `start.sh` prints the Pluto editor URL; the secret is
regenerated per run. Ctrl-C stops both processes — note the trap takes Pluto down with the
bridge, so killing one kills both.

The `rainbow/ui` probe is a second page on the same server: `http://localhost:8099/ui-probe.html`.

## Issue 009 — proven

009 is the only issue whose failure would invalidate the design, so it was run first. It is
now **proven end to end** in real headless Chrome: a Plotly card renders, keeps its modebar,
and redraws from a slider in 38-84 ms.

    [x] script execution     a cell emitting <div>+<script> renders as "SCRIPT EXECUTED"
    [x] @bind widget         a Julia-defined range input renders with its value
    [x] interactive Plotly   plotlyDiv true, 12 svg nodes, modebar live
    [x] live update          slider -> bond -> Julia -> redraw, verified by zero-crossings
    [x] no page errors

Frequencies 1.0 / 3.0 / 0.5 / 4.7 produced 3 / 9 / 1 / 14 zero-crossings, which is `f*10/pi`
each time — the plot really is being recomputed in Julia, not relabelled.

**The three things that had to be right.**

`PlutoJSInitializingContext` must be given a `Set`. `RawHTMLContainer` calls
`js_init_set.add(container)` while scripts run and `.delete(container)` after. Passing the
wrong shape fails with `TypeError: js_init_set?.delete is not a function` and **no script ever
runs**.

A card needs a `<pluto-cell>` ancestor carrying `getPublishedObject`. `execute_scripttags`
resolves a script's published objects through

    const cell = root_node.closest("pluto-cell")
    getPublishedObject: (id) => cell.getPublishedObject(id)

so without that ancestor `cell` is null and the script dies **silently — no exception, nothing
rendered**. This is how `published_to_js` payloads are reached, which is how PlutoPlotly ships
both its library and its plot data: a 1 KB cell body against a 3.82 MB library payload and an
11.6 KB plot payload, all living in `notebook.published_objects` rather than in the body.
Supplying `get_published_object` in the actions object is necessary but not sufficient.

A card must repaint **only when its own cell re-runs**. A notebook diff arrives for every cell,
many times per run; repainting every card on every diff rebuilds each card's scripts, and for a
Plotly card that means rebuilding the graph against a multi-megabyte payload repeatedly. Keying
a repaint on the card's own `last_run_timestamp` took the plot from dozens of rebuilds to
exactly one per slider position.

**Where it lives.** `frontend/ui-probe.html` and `frontend/ui-probe.js`, served at
`/ui-probe.html` by the same bridge. The `freq` slider and the cell it drives were added
**over the websocket**, not by editing `notebook.jl` — Pluto owns that file and wrote them to
disk itself, which is the mechanism `PlutoDeck` should use for any cell it needs to inject.

## Open risks

### Risk 1 — offline Plotly costs 3.8 MB through the notebook state

`enable_plutoplotly_offline()` is what keeps Plotly working without a network, and it works by
pushing the whole plotly ESM bundle through `published_to_js`. That is 3.82 MB crossing the
websocket into `notebook.published_objects` on every kernel start. Untested against a slow
machine or a lecture-hall laptop. Without it, PlutoPlotly fetches from `cdn.plot.ly`,
`esm.sh` and `jsdelivr`, which forfeits the offline guarantee the existing deck states three
times.

### Risk 2 — a deck needs a card that is rendered but not shown

`enable_plutoplotly_offline()` is a cell whose output is a *side-effecting script*: it must be
in the DOM and executed before any plot card renders, yet it is not something a slide should
display. `deck.json` therefore needs a notion of a preamble card — rendered, hidden, ordered
first. This is not in DESIGN.md and not in any issue; it was found by this spike.

### Risk 2b — the kernel gets OOM-killed, and the deck does not notice

`earlyoom` on this machine runs `--prefer (julia|node)`, so it targets exactly these processes.
Pluto was killed twice during one session (22:20 and 22:30), each time while several 2 GB Julia
workers and a large browser were resident on a 30 GB box.

Both times **the bridge survived and kept answering 200 with a dead kernel underneath**, so the
deck looked healthy and served a page that could never update. An HTTP check is not a health
check. The only honest probe is to change a bond and confirm a watched cell re-runs; a
throwaway version of that is worth keeping as part of issue 013.

This is also the strongest argument yet for cached snapshots, which v1 defers: a lecturer whose
kernel is killed mid-lecture currently gets a deck that silently stops responding.

### Risk 3 — the 3.7 MB ui bundle against the offline guarantee

`dist/ui/ui.esm.js` is 3.7 MB against 464 KB for the standalone client. Acceptable for a
locally-served deck, unexamined for anything published.

### Risk 4 — cold start is thirty seconds and nothing covers it in v1

Measured at 12.1 s to serving HTML, 29.1 s to kernel ready, 31.2 s to first real content, on a
notebook loading **no** packages. The notebook this course needs will be far worse. Issues 010
and 012 make that legible rather than shorter; cached snapshots are deliberately deferred.

## Gotchas

All ten live in `README.md` with the reasoning. The three that cost the most:

- `worker.isIdle()` returns true *before* a run starts, so it alone means "settled" instantly.
- Watching only the root cell hands back the previous run's downstream output.
- The published ESM build needs `process` and `global` shimmed before import, and **no Node-side
  test harness can catch this**, because Node defines `process` itself.

## Conventions

Issues carry a kind, `tech-debt` where the payoff is lower future cost, a priority and a
complexity, per the repository's CLAUDE.md. `agent-ready` marks an issue that states its own
done-condition, holds its blast radius to one subsystem, and leaves no judgment call open.
Fourteen of the fifteen are agent-ready; 014 is not, because it needs pedagogical judgment.

Status lives only in `spec/PLAN.md`. Recording progress never means editing an issue file.

## State of the tree

Nothing is committed; `pluteSpike/` is untracked in full. The package is `pluteSpike/PlutoDeck.jl/`,
whose own `.gitignore` covers `frontend-dist`, `frontend-dist-*` and `Manifest.toml`. `backend/notebook.jl` has been
canonicalized by Pluto and carries three probe cells added for the 009 spike
(`script_probe`, `plotly_offline`, `plotly_demo`) plus a hidden `eval_in_pluto` cell left by
`worker.execute()` diagnostics. All four are spike scaffolding, not design, and should be
removed or deliberately kept before a first commit.
