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
`PlutoDeck.jl/` and carries the card contract, the deck loader, and the runtime:
`PlutoDeck.present("<a deck.json>")` starts Pluto, opens the notebook in place and serves the
deck, with no Node anywhere. Cards now show live output: the frontend is plain ES modules
served straight from `frontend/`, with its dependencies vendored under `frontend/vendor/`
because the build pipeline of issue 007 is still deferred — the two Rainbow bundles, and
`marked.esm.js` (marked 18.0.13, MIT, no dependencies of its own, copied from the npm tarball's
`lib/marked.esm.js`), which renders speaker cues in the browser so that they survive a kernel
that is slow to start or has been killed.

## Status

    [x] Research      @plutojl/rainbow verified end to end against a real kernel
    [x] Spike         pluteSpike/ — bonds in, outputs out, 80-125 ms round trip
    [x] Design        DESIGN.md, eight decisions settled
    [x] Spec          spec/PLAN.md, fifteen issues
    [x] Issue 009     de-risking spike PROVEN — Plotly renders and updates live
    [x] Issues 001-003  PlutoDeck.jl/ — skeleton, card keys, deck loader; `] test PlutoDeck` green
    [x] Issues 004-006  session, HTTP server, present(); Node is out of the runtime
    [x] Issues 008-010  kernel client, card renderer, card state machine; cards are live
    [~] Issue 011     re-scoped: the geometry already rendered, overlap now refused
    [x] Issue 012     deck chrome — paging by pointer and keyboard, four kernel states
    [x] Issue 013     headless-Chrome harness, driving `present` itself
    [x] Issue 014     lecture-1 deck — six slides, the notebook carries its card keys
    [x] Issue 016     the deck writes `deck_theme`; a plot follows the viewer's scheme
    [x] Issue 017     one payload per draw; the suite asserts a plot is drawn, not present
    [ ] Issues 007, 015

## Run the deck

    mise run deck          # presents lecture 1, prints the URL and the Pluto editor link
    mise run deck-check    # what a deck publishes, without starting a kernel
    mise run deck-test     # the suite, browser tests included (needs Chrome, ~2 GB free)

Julia comes from the `dyad-3.3.0` channel, matching `.vscode/settings.json`. Presenting opens
the notebook **in place**, and Pluto rewrites what it opens, so a deck run leaves the notebook
showing as modified — that is the editing loop working, not a fault. Run against a copy if that
is not what you want.

The spike's own stack is gone: no `start.sh`, no Node bridge, no second frontend. `present`
starts Pluto from Julia and serves the deck from the same process.

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

**Where it lives.** It was proven in a standalone probe page, since removed; the technique is
`PlutoDeck.jl/frontend/render.js` and the repaint rule is `card.js`. The `freq` slider and the
cell it drives were added **over the websocket**, not by editing `notebook.jl` — Pluto owns that
file and wrote them to disk itself, which is the mechanism `PlutoDeck` should use for any cell
it needs to inject.

## Open risks

### Risk 1 — offline Plotly costs 3.8 MB through the notebook state

`enable_plutoplotly_offline()` is what keeps Plotly working without a network, and it works by
pushing the whole plotly ESM bundle through `published_to_js`. That is 3.82 MB crossing the
websocket into `notebook.published_objects` on every kernel start. Untested against a slow
machine or a lecture-hall laptop. Without it, PlutoPlotly fetches from `cdn.plot.ly`,
`esm.sh` and `jsdelivr`, which forfeits the offline guarantee the existing deck states three
times.

### Risk 2 — a deck needs a card that is rendered but not shown — **closed**

`enable_plutoplotly_offline()` is a cell whose output is a *side-effecting script*: it must be
in the DOM and executed before any plot card renders, yet it is not something a slide should
display. `deck.json` now carries an optional top-level `"preamble"`, an array of card names
rendered into a hidden container before any slide and shown on none. The frontend waits for
those cards' scripts to finish — Pluto's own `PlutoJSInitializingContext` set reports that —
before it paints anything else, so a plot card never draws against a library that has not
loaded. This was not in DESIGN.md and not in any issue; it was found by the 009 spike.

### Risk 2b — the kernel gets OOM-killed, and the deck does not notice

`earlyoom` on this machine runs `--prefer (julia|node)`, so it targets exactly these processes.
Pluto was killed twice during one session (22:20 and 22:30), each time while several 2 GB Julia
workers and a large browser were resident on a 30 GB box.

Both times **the server survived and kept answering 200 with a dead kernel underneath**, so the
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

## Found while building 019

**A page outlives the server that served it, and `listenany` hands its port straight back.**
The cold-open test — a speaker page with no deck driving it — served a second deck on
`listenany=true`, which took back the port the offline deck of 018 had been served on. That
server was closed, but its *page* was still open in the browser and still announcing its slide
every two seconds, and a page and a server that share an origin share a `BroadcastChannel`. So
the page that was asserting it had no deck to follow reported `live` on slide 1 / 2, against a
server that had been shut down two testsets earlier. Anything asserting an absence over a
channel now takes `port=free_port()`, not the default one something else has already used.

**The deck's own module has to announce the slide before it reaches its kernel.** `deck.js`
awaits `connect` at the top level, so anything constructed after that await does not exist on a
deck whose Pluto is unreachable — which is the deck the speaker window matters most to. The
publisher is built beside the cues, above the await, for the same reason they are.

## Found while building 019

**`present` exits 1 on an interrupt, about half the time, and the exception is in a background
task.** Three clean runs on main before 019's tests; three clean and three `exit 1` in six runs
with them. 019 added no Julia code — its browser work lengthens the window the interrupt lands
in, which is what made a standing race visible, the same way 017's duplicate modebar only
showed once a card was on two slides. The one trace caught ends in `jl_finish_task` /
`start_task`. `_block_until_interrupted` catches an `InterruptException` in the main task and
nothing covers it arriving elsewhere. Issue 023.

**Leaving browser pages open across testsets is not what causes it.** That was the first
theory — that Chrome's teardown dropping every tab at once while `present` was being
interrupted loaded the exit path — and closing each page per testset did not stop the flake.
Recorded because it is a plausible theory that costs a day, and the evidence against it is
cheap to state and expensive to re-gather.

**`earlyoom` deaths are a different signature and not evidence.** SIGTERM and exit 143, against
this flake's exit 1. Three runs during the investigation died that way on a box whose swap was
exhausted, and reading them as the flake sends you looking in the wrong place.

## Found while pinning 018

**Pluto's client retries a refused websocket forever, so `connect` never settles.** Not a
rejection, not a timeout — it keeps trying. `deck.js` awaits it before registering anything, so
against an unreachable Pluto the `catch` beside the await never runs and the
`onConnectionChange` handler below it is never reached. `connected` stays `true` and `kernel`
stays `null`, which `kernelStatus` reads as a cold start. The chrome says "the kernel is
starting; cards fill in when it is" over a kernel that is dead, and goes on saying it — watched
for 96 seconds. Issue 021 carries it. The cues render throughout, which is the whole point of
parsing their markdown in the browser.

**A page's `load` event fires while the deck's module is still evaluating.** A module script
delays `load` until it has *started*, not finished, and `deck.js` awaits its kernel at the top
level. A key pressed immediately after `navigate` therefore reaches a page that has not bound
its listeners, and the test fails in a way that looks like the key handler being wrong. Wait on
something the module sets after the binding instead — `document.body.dataset.kernel` is the one
the suite uses, and against a live kernel `=== "ready"` doubles as the assertion that a refresh
found the kernel still running. This will bite the next test that navigates and presses.

## Found while fixing 017 and implementing 016

**A blank plot holds all of its data.** Four of the lecture deck's seven plots drew nothing.
Measured on the live deck: `speed-plot` is placed on five slides, and one of the five had its
two lines while the other four had the traces, the 591 points and no line at all. One exception
per draw, `button name 'Copy PNG to Clipboard' is taken`, thrown after Plotly attaches the
traces and before it paints them. So `.js-plotly-plot` exists, the card reports `live`, and
every assertion the suite made about a plot passed over four empty boxes. The suite now asserts
a drawn `path.js-line`, on a cell placed on two slides.

**What crosses between draws is the button array, not the payload.** `published_to_js` sends
one object per cell and every render of that cell is handed it; PlutoPlotly appends its modebar
buttons to that object's `config` each time, through a `_.union` that compares by identity and
so cannot dedupe an object literal. The deck now copies a payload's object spine per draw and
shares everything else, so the 3.82 MB library string and every trace's typed arrays are passed
by reference. Deep-copying the payload is the obvious fix and the expensive one; it was never
needed.

**`bonds` cannot answer whether a notebook declares a bond.** Pluto's notebook state carries
the values a browser has *reported*, so a bond nothing has written is simply absent — which is
exactly the bond the deck wants to write. Measured: a notebook with seven `@bind` cells showed
six, the seventh being the one whose element reports nothing. The name lives in
`cell_dependencies` before it has a value, and that is what the deck tests.

**A card's payloads have to outlive the paint that asked for them, twice over.** Writing a
bond before the first paint adds a reactive run at exactly the wrong moment, and two separate
races came out of it. Both end the same way: `getPublishedObject` returns `undefined`,
PlutoPlotly throws on `plot_obj.layout`, and the card reports `live` showing nothing.

The first is arrival order. A cell's body and the payloads it reaches for come in separate
patches and the body can be first, so a card painted in that window cannot resolve its own
ids. The deck now treats a body whose `getPublishedObject("…")` references are not all present
as output that has not arrived, and paints it on a later patch instead.

The second only appears once the first is fixed, and is the deck's own doing. The resolver
lives on the card's `<pluto-cell>`, and a repaint replaces it — while the previous render's
scripts are still running, because `RawHTMLContainer` executes them asynchronously. Those
scripts then ask the *new* render for ids that went out with the old one. A card now keeps the
payloads of its last three renders, so a script in flight still finds its own.

The cost of getting this wrong is that it looks like nothing: measured on the fixture deck, a
plot card sat empty for the rest of the run with `data-source="live"` and one line in a console
no lecturer has open.

**A Plotly figure never told how tall its box is draws itself 400 px.** Measured across the
lecture deck: every plot was 400 px whatever `h` the deck gave its card — so a twelve-row card
held a plot and 262 px of blank, and a six-row card clipped by 98 px. The container Pluto
renders is as tall as its content, so nothing pushes back. Giving a figure card's chain an
explicit height makes the plot follow: 638 px in a twelve-row card, 302 px in a six-row one.
The rule is scoped to cards holding a figure, because the same height over a card of prose
stretches the paragraph and over a table distributes its rows.

**32 px of a widget card went to a margin.** `.card-body > :first-child` reaches Pluto's
wrapper, not the paragraph one level inside it, so every markdown card kept its `1em` top and
bottom margins. That alone is what made the Ki and Kd cards scroll-boxes: 91 px of content in a
102 px card, plus 32 px of margin.

**Memory across a reload, measured after 017.** One load of the six-slide deck, all seven
Plotly instances live, is 115-127 MB of JS heap. The 3.82 MB payload is a string shared by
reference, so it is neither multiplied per instance nor copied per repaint — nothing here
multiplies the way the crash report suggested.

**Nothing is retained across a reload either** — the counts that read as a leak are Chrome
deferring a collection, and they are a sawtooth rather than a climb. Fifteen reloads of the
lecture deck with nothing forced go 9 → 19 → 29 documents, then 9 again, round and round,
peaking at 31 documents and 261 MB and never passing it. Collect at any point in that cycle and
the page is back to 2 documents, 3942 nodes and 18.2 MB — the floor after a single load,
identical at every one of the fifteen. The two runs that started this, 9 documents with 9470
nodes and 26 with 27702, are that sawtooth sampled at two different phases.

Asked directly rather than counted, the answer is the same and names its objects:
`Runtime.queryObjects(Document.prototype)` collects before it answers, and after six loads the
only documents alive are the page itself — 2542 elements, 40 cards, seven plots — and the
harness's own `about:blank`. No previous deck document survives, so there is no retaining edge
to find and no detached `pluto-cell` to trace one from.

What the counter counts is what made this read as a leak. A single load already stands at 9
documents, of which 7 are garbage the moment they exist; each reload adds about ten more and
about 9470 nodes, which is over twice a whole live deck. Those documents were never decks.
Measured in headless Chrome over the DevTools protocol — a headed Chrome with DevTools open
retains what its console was handed, which is a different experiment.

The renderer crash is therefore not explained by anything the deck does to memory, and the
paint model needs no change on this account.

**The height rule under a figure card does more than fill the box.** `deck.css` gives the chain
under a card holding a figure an explicit height, and the suite now measures that a plot is as
tall as its card body rather than only that it drew — nothing else there would notice the rule
stop matching, since a 400 px plot still draws its lines, still reports `live`, and still
answers every selector the suite uses. Taking the rule out to check the assertion fails turned
out to do something worse than leave blank space: the page stopped answering the DevTools
protocol from the moment the second plot became visible, and every assertion after that point
timed out. A figure with no height inside a card that scrolls its own overflow is evidently not
a layout that settles. The mechanism was not chased — the rule is staying either way — but it is
a stronger reason to keep it than the 262 px of blank it was put there for.

## Found while implementing 011, 012 and 014

**011 asked for a dependency its design decision never did.** The issue file called for
GridStack; DESIGN.md asks only for a schema shaped like GridStack's, and assigns drag-and-drop
to the visual editor it defers. A 12-column CSS grid already renders that schema exactly, so
the 2.1 MB was buying nothing this version uses. The issue has been re-scoped to what the grid
genuinely does not do — complain — and the loader now refuses a deck whose cards overlap or
reach past the last column. Nothing forecloses GridStack; it arrives with the editor that needs
it, against a schema that already carries its geometry.

**A hidden slide must keep its box, not lose it.** Paging means all but one slide is out of
sight, and the obvious `display: none` is wrong: a card hidden that way measures zero wide, and
a Plotly card painted at zero width draws a graph that size. Measured, with the plot on the
slide that is hidden when it first paints — `display: none` gives a card of `offsetWidth` 0 and
a graph 0 px across. `visibility: hidden` keeps layout, so every slide's cards are laid out at
the width they will be shown at. The browser suite asserts this.

**Slide titles went into the deck rather than the notebook.** DESIGN.md says the presentation
layer owns layout and nothing else, which argues for titles as Julia-authored content. Against
that, the stated reason the deck is a separate file is that one notebook backs several decks —
the full lecture, a revision deck, a student-facing cut — and titles in Julia would force all
three to share wording. Slide titles are therefore a `title` key on a slide; a widget's label
stays in Julia, where it is part of the widget. This is the first addition to the 003 schema.

**A cell's top-level assignment is a Pluto global, including inside an `if`.** The two plot
cells were written with `idx = 1:...:length(sim.t)` in their `else` branch, which is not a local
— both cells claimed `idx`, and Pluto answered with "Multiple definitions for idx" on every one
of the six cards those cells back. The card rendered the error, reported `live`, and logged
nothing, so the deck showed six identical 308-byte boxes and a clean console. Reading those 308
bytes rather than inferring them is what found it; a card's `data-source` says where its content
came from, never whether the content is an error. Both cells now bind `idx` in a `let`.

**A published payload is shared, and a library treated it as scratch space.** The lecture deck
draws seven Plotly cards and logs `button name 'Copy PNG to Clipboard' is taken` sixteen times
while rendering perfectly. PlutoPlotly appends its modebar button to the plot's config on every
draw through `_.union`, which compares by identity and so cannot dedupe an object literal —
harmless in a notebook that draws each plot once, and not in a deck, which repaints a card
whenever its cell re-runs and places one cell on as many slides as it likes. Issue 017 carries
it. The measurement that matters before fixing it: the payload is 3.82 MB, so copying it per
repaint is not the answer it looks like.

**The deck's gains are not the lecture's gains.** `simulate` in the spike notebook is a
parallel-form PID in `Kp`, `Ki`, `Kd`; notebooks 03 to 05 run `LimPID` in standard form, `k`,
`T_i` and `T_d`, and notebook 08's tuning tables produce that second set. `Ki = k/T_i` and
`Kd = k*T_d` relate them, but a student moving between the deck and the notebooks meets two
different parameterisations of the same controller. The deck labels its sliders as what they
actually are rather than papering over it. Reconciling the two is a decision for the author,
not a rename.

**The spike's scaffolding cells are still in the notebook.** `script_probe`, `plotly_demo`,
`freq` and the hidden `eval_in_pluto` cell stay in `backend/notebook.jl`. What kept them was the
probe pages that addressed them by name, and those are gone — but removing a cell means going
through Pluto's websocket, because Pluto owns that file, so it is a job rather than an edit.
They cost nothing meanwhile: a cell with no `card` key cannot reach a slide, so no deck sees
them.

## Found while implementing 008-010

**Settling cannot require every watched cell to re-run.** The spike waited for *all* watched
cells' `last_run_timestamp` to advance, which works only because every cell it watched was
downstream of every bond. A deck has cards that no bond reaches, and waiting for those times out
on every slider move. The rule that carries both findings is: believe `isIdle()` only once it
has held, and once no watched cell has produced anything new, for a short quiet window.

**A batch only exists if the write waits for the turn to finish.** Each widget reports its own
value as its card's scripts finish, so writing the first bond the moment it arrives makes it a
reactive run of its own — and that run sees every other bond still `missing`, which is the exact
failure `_setBonds` was written to avoid. A 20 ms collecting window before each write turns a
page-load burst into one run.

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

The package is `pluteSpike/PlutoDeck.jl/`, whose own `.gitignore` covers `frontend-dist`,
`frontend-dist-*` and `Manifest.toml`. `backend/notebook.jl` now carries the lecture-1 deck: 13
cards, six labelled widget cells, and the plot and readout cells the slides place. Its 009
scaffolding is kept on purpose, for the reason recorded above. `backend/lecture-01.deck.json`
is the deck itself.

The `card` keys were written through Pluto's own reader and writer rather than by a text patch,
with no server holding the notebook open — the mechanism `test/fixtures/generate.jl` uses. That
round trip was checked first on a copy: same cell set, same `Cell order:` footer, both nbpkg
cells intact, and the only difference is Pluto canonicalising body order to match its own
footer, which it does on the next open regardless.
