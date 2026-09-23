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
deck, with no Node anywhere. The frontend is TypeScript and Lit under `frontend/src/`, bundled by
esbuild into `frontend-dist/`, which is committed and is what a deck serves. Every dependency
comes from npm — `@plutojl/rainbow`, `marked`, `lit`, `@lit/context` — and `frontend/vendor/` is
gone. Node is a build-time tool: it is needed to *edit* the frontend and never to present one.

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
    [x] Issue 007     TypeScript + Lit + @lit/context, bundled by esbuild; the shim is gone
    [ ] Issue 015

## Run the deck

    mise run deck          # presents lecture 1, prints the URL and the Pluto editor link
    mise run deck-check    # what a deck publishes, without starting a kernel
    mise run deck-test     # the suite, browser tests included (needs Chrome, ~2 GB free)

Presenting needs Julia and a browser. It does not need Node: `frontend-dist/` is committed, and
that is the whole of what `frontend_directory()` serves.

## Editing the frontend

    mise run frontend-install   # npm ci — once per checkout, and only to edit the frontend
    mise run frontend-check     # typecheck, lint, and the Node unit tests
    mise run frontend-watch     # rebuild the bundle on every save
    mise run frontend-build     # one build

**The loop is still edit and refresh**, but what the browser reads is the bundle, so an edit
reaches it through a rebuild. `mise run deck` starts esbuild in watch mode alongside the deck for
exactly this reason — about 200 ms per save — and stops it with the deck. A checkout that has not
run `frontend-install` presents the committed bundle and says so, which is all a lecturer needs.

**A watcher over a committed bundle leaves a development build behind.** `npm run dev` rebuilds
into `frontend-dist/`, and its builds carry source maps — so the content hashes differ from the
release build and `*.js.map` files appear beside them. Present a deck and the committed bundle is
replaced by a development one; commit without looking and that is what ships. `.gitignore` covers
the maps, and `mise run deck` now runs `npm run build` from its exit trap so the release build is
restored when the deck stops. `npm run build` empties the directory first, so the restored bundle
is byte-identical to what was committed.

**The trap this was expected to be, and what it turned out to be.** Committing a bundle was
expected to shadow the source: `frontend_directory()` used to prefer `frontend/` in a development
checkout and `frontend-dist/` otherwise, so a committed bundle would have meant every checkout
silently served the bundle and editing a source file did nothing. That shape cannot arise,
because `frontend/` no longer holds anything a browser can run — there is no source-serving mode
left to shadow. So the fork went away rather than gaining an inverse: `frontend_directory()`
names one directory, `JULIA_PLUTODECK_FORCE_BUNDLED` is gone with nothing to force, and `serve`
refuses a missing bundle naming the command that builds one. The failure that replaces it is
"I edited a `.ts` file and nothing changed", whose cause is a watcher that is not running, and
`mise run deck` is what keeps that from being the default.

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

## Found while implementing 007

**`@plutojl/rainbow` does not type what `getState()` returns, and `skipLibCheck` hides it.**
`dist/standalone/client.d.ts` declares `getState(): NotebookData | null` without importing
`NotebookData` anywhere in the file — the name is simply unresolved. TypeScript reports that as
an error *inside* a declaration file, which `skipLibCheck: true` suppresses, and the type then
degrades to `any`. So `tsc` was clean over a kernel client that had no type safety at all on its
main read path, and it was ESLint's `no-unsafe-member-access` that said so. The deck now declares
the slice of the notebook state it reads in `pluto.interface.ts` and narrows `getState()` through
`isNotebookState`, which is also where a Rainbow upgrade that changes the shape stops being a
card that renders nothing. Worth reporting upstream; the file also carries
`export * from "./getters.ts"`, a `.ts` extension inside a `.d.ts`.

**`tsc --noEmit` silently ignores a file whose name begins with a dot.** A `src/.probe.ts`
written to check whether a type resolved was excluded from the program by the `include: ["src"]`
glob, so the check passed by not running. It cost a wrong conclusion about the above, and the
only reason it was caught is that ESLint disagreed. A scratch file used to answer a question
needs an ordinary name.

**The shim was the whole issue, and `define` alone was enough.** Counted rather than assumed:
the root bundle has six bare `process.env.NODE_ENV` reads, all of them immer's, and one
`process.cwd` that turned out to be inside a string. Every `global` reference in either bundle is
the browserify `typeof` probe, and `dist/ui/ui.esm.js` assigns `window.process` itself in a
`try`. So one `define` entry retires `frontend/vendor/browser-shim.js`, `inject` was not needed,
and defining `global` would have changed no byte. `DESIGN.md` § The bundler is what replaced the
browser shim carries this, and `browser.jl` asserts it in a real browser.

**Three tests were importing frontend modules over HTTP, and a bundle has no such URLs.** The
browser suite unit-tested `kernelStatus`, the `Card` placeholder and the bond batching by
`import("/status.js")` and friends. Two of those are pure functions that were written to be
decidable without a browser, and the third became one: the batching and settling rules moved out
of `Kernel` into `bond.queue.ts`, which imports nothing. They are now `node --test` files beside
the source — Node 22 discovers and type-strips `*.test.ts` with no flag and no added dependency —
and the browser keeps what genuinely needs one. The `Card` test became an assertion on the deck
that has no kernel, where a labelled placeholder is what a lecturer is actually looking at, which
is a better test than the hand-built object it replaced.

**A Lit component whose children belong to another renderer must render one constant template.**
A card's body is painted by Preact and a cue body by `marked`, both writing into an element Lit
created. Lit only revisits the bindings in a template, so a `render` returning a template with no
bindings inside that element leaves its children alone on every subsequent update. Getting this
wrong would not error; it would quietly restore a placeholder over a rendered plot.

**A context update reaches a card on Lit's next turn, and `whenScriptsSettled` cannot see that.**
The preamble has to finish running its scripts before any plot card draws, and the old code got
that ordering from calling `show()` synchronously. Publishing content through a context is
asynchronous, so `whenScriptsSettled` was being asked about a card that had not painted yet and
answered "nothing running" immediately. `#cardsPainted` awaits the cards' own `updateComplete`
before the wait begins. The cost of getting it wrong is the one 009 already documented: a plot
card drawn against a library that has not loaded shows nothing and reports `live`.

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

Nothing the deck's **paint model** does across a reload explains a renderer crash, and the
paint model needs no change on this account. That is the whole of what this experiment covers:
it varied reloads, it counted documents, and it read `usedJSHeapSize`. A renderer can hold
gigabytes that none of those three can see — see the next section, which found exactly that.

**A 7.4 GB renderer, and it is one `import()`.** A deck tab measured 7,430,164K in Chrome's own
task manager. The cause is not the paint model and not the deck: presenting a deck loads the
offline Plotly bundle by importing it from a `data:text/javascript;base64,` URL, and Chrome
answers a single such import with gigabytes.

Reduced to one variable. The same file — `plotly-esm-min.mjs`, 3,740,861 bytes, the artifact
PlutoPlotly ships — imported three ways into an otherwise empty page, nothing else on it:

| `import()` of `plotly-esm-min.mjs` | renderer RSS |
|---|---|
| over `http://` | 0.18 GB |
| from a `blob:` URL | 0.17 GB |
| from a `data:text/javascript;base64,` URL | ≥4.70 GB, still climbing when the run was stopped |

`PlutoPlotly.import_local_js` builds the third one: `readAsDataURL` over a `Blob` of the bundle,
then `import(reader.result)`. So the cost is not the deck's and not this notebook's — it is paid
by anything that calls `enable_plutoplotly_offline()`.

**What the 7.4 GB is made of, read out of the live process.** The tab was still running, so it
was dissected rather than inferred. Of 7.04 GB resident, `[anon:partition_alloc]` holds 7,022 MB
and `[anon:v8]` — the JavaScript heap — holds **40.6 MB**. Scanning partition_alloc for long
base64 runs accounts for 6.79 GB in 2,907 runs, which is **100% of its non-zero bytes**, and the
runs are copies of that one data URL: the first bytes after `data:text/javascript;base64,` match
`base64 plotly-esm-min.mjs` exactly. At 4,987,816 base64 bytes per copy that is about 1,430
retentions of a 4.76 MB string, from one import.

This is why the reload experiment above found nothing and was right not to. The retained bytes
are Blink strings, not JS objects: `usedJSHeapSize` reports 40 MB of a 7.4 GB renderer, and
`Runtime.queryObjects(Document.prototype)` cannot see them at all. **A JS-heap instrument is the
wrong instrument for this bug** — the honest one is the renderer's RSS in `/proc`.

**Causation, not just correlation.** `Page.addScriptToEvaluateOnNewDocument` wrapped
`FileReader.prototype.readAsDataURL` to swap the blob for a stub after the first call. The deck
then loaded — kernel `ready`, cards painted, math typeset — and the renderer sat **flat at
0.31 GB** for the whole run, against 7.45 GB uncapped on the same deck. The probe counted four
`readAsDataURL` calls, one of them carrying 3,740,861 bytes; `window.created_imports.size` was 1.
One call, ~7.1 GB.

**Eliminated, each by measurement rather than argument.**

- **Repaint.** The balloon is finished inside a second of load, sampled at `plots=0`, before any
  bond was driven. Nothing repaint-proportional is left to find: the data URL is already 100% of
  the non-zero bytes.
- **Detached graphs, resize listeners, retained payloads, `PAYLOAD_DEPTH`.** All of these live on
  the JS heap, which is 40.6 MB. There is no room in it for this.
- **MathJax's SVG output.** Present and drawn in the capped run that stayed at 0.31 GB.
- **Headed versus headless.** Settled, and it is not the axis: the user's headed tab plateaued at
  7.43 GB and a headless renderer on the same deck at 7.45 GB. The earlier all-clear and this
  measurement disagreed because one read the JS heap and the other reads RSS, not because one
  browser was headed.

**The fix is not in this repo, and is not made here.** `import_local_js` in
`PlutoPlotly/src/local_plotly_library.jl` would swap `readAsDataURL` for
`URL.createObjectURL(blob)` — the `blob:` row above, same module, 0.17 GB — and revoke it after
the import resolves. That is the pattern Pluto's own frontend already uses: `CellOutput.js`
builds a `blob:` URL for an image and for an iframe and revokes it on detach, and the only
`readAsDataURL` in Pluto's frontend is in `PlutoHash.js`, where nothing is imported. PlutoPlotly
is the outlier here, not the precedent. A deck-side workaround would drop `enable_plutoplotly_offline()` from
`backend/notebook.jl` and pay a network fetch for Plotly instead, which is the thing offline mode
exists to avoid. Issue 027 carries both and the evidence.

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
- The published ESM build reads `process.env.NODE_ENV` as a bare global, and **no Node-side test
  harness can catch this**, because Node defines `process` itself. esbuild's `define` is what
  answers it now; `browser.jl` is what checks that the answer still holds.

## Conventions

Issues carry a kind, `tech-debt` where the payoff is lower future cost, a priority and a
complexity, per the repository's CLAUDE.md. `agent-ready` marks an issue that states its own
done-condition, holds its blast radius to one subsystem, and leaves no judgment call open.
Fourteen of the fifteen are agent-ready; 014 is not, because it needs pedagogical judgment.

Status lives only in `spec/PLAN.md`. Recording progress never means editing an issue file.

## State of the tree

The package is `pluteSpike/PlutoDeck.jl/`. Its `.gitignore` now covers `frontend/node_modules`
and `Manifest.toml`: **`frontend-dist/` is committed**, for the reasons in `DESIGN.md` § The
built bundle is committed, which also records what would move that back. `frontend/` holds
TypeScript, `package.json`, `package-lock.json`, `tsconfig.json`, `eslint.config.js` and
`build.mjs`; `frontend/vendor/` is gone and every dependency comes from npm, pinned exactly. `backend/notebook.jl` now carries the lecture-1 deck: 13
cards, six labelled widget cells, and the plot and readout cells the slides place. Its 009
scaffolding is kept on purpose, for the reason recorded above. `backend/lecture-01.deck.json`
is the deck itself.

The `card` keys were written through Pluto's own reader and writer rather than by a text patch,
with no server holding the notebook open — the mechanism `test/fixtures/generate.jl` uses. That
round trip was checked first on a copy: same cell set, same `Cell order:` footer, both nbpkg
cells intact, and the only difference is Pluto canonicalising body order to match its own
footer, which it does on the next open regardless.
