# pluteSpike — interactive slides driven by a live Pluto kernel

A working spike of the framework: a static HTML page whose controls write Pluto `@bind`
values and whose readouts are Pluto cell outputs, over [`@plutojl/rainbow`][rainbow]. The
car model is the L0 parameter set from `docs/HANDOVER.md`, so the numbers on screen are the
lecture's numbers.

## Run it

```
./start.sh          # then open http://localhost:8099
```

First run installs Pluto into `backend/` and takes a minute. Ctrl-C stops both processes.
Julia comes from the `dyad-3.3.0` channel, matching `.vscode/settings.json`; override with
`PLUTE_JULIA_CHANNEL`. Ports are `PLUTE_UI_PORT` (8099) and `PLUTE_PLUTO_PORT` (1235).

## Shape

```
backend/server.jl        Pluto server, secret on, writes .session
backend/notebook.jl      the notebook: car model, 6 @bind inputs, 2 output cells
bridge/orchestrator.mjs  uploads the notebook, serves the deck, exposes /api/session
frontend/rainbow-bridge.js   <pluto-bind> / <pluto-out> custom elements  ← the framework
frontend/index.html      the slide — static markup, no per-slide JavaScript
```

A slide says what it wants and nothing else:

```html
<pluto-bind var="Kp" label="Kp" min="0" max="20" step="0.1" value="2"></pluto-bind>
<pluto-out cell="metrics"></pluto-out>
```

`var` and `cell` are Julia names. The bridge resolves a name to a cell id by matching
`@bind <name>` or `<name> =` in the cell source, so slides never carry notebook UUIDs.

## Open the notebook itself

`start.sh` prints the editor URL, and `/api/session` carries it as `editUrl`:

```
curl -s localhost:8099/api/session | python3 -m json.tool
```

It is `http://localhost:1235/edit?id=<notebook_id>&secret=<secret>` — the secret is
generated per run, so the URL changes each time you start the stack.

The notebook runs **in place** from `backend/notebook.jl`, so edits made in the Pluto editor
save straight back to the repo file. The editor and the deck share one kernel and one set of
bonds: move a slider in Pluto and the deck follows, and vice versa. That is the shared-state
limit below, visible from the inside.

Pluto rewrites the file into its canonical form on first open — the `@bind` mock-macro
preamble, its own version stamp, cell ordering. That diff is expected, and committing it is
correct.

## Things that cost time, recorded so they only cost it once

**Uploads park in `waiting_for_permission`.** A notebook opened over `/notebookupload` will
not run until someone clicks "Run notebook code", which a deck cannot do. The upload needs
`?execution_allowed=true`. `warn_about_untrusted_code` is not the lever.

**`createWorker` cannot reach a secret-protected server.** It builds
`` `${server_url}/notebookupload` `` by concatenation and never forwards the secret, so it
400s or 403s. The upload therefore happens in the bridge, and the browser attaches to the
returned id — the websocket URL *does* carry the secret. Leaving the secret off is not an
option: Pluto answers websockets from any origin, so an unsecured server lets any page the
browser visits run Julia on the machine.

**`worker.isIdle()` is true before the run starts.** It reports idle in the window between
sending a bond and the server beginning work, so it alone means "settled" instantly. The
bridge waits for the watched cells' `last_run_timestamp` to advance as well.

**Downstream cells finish after their dependency.** Watching only `sim` hands back the
previous run's `metrics`, which looks exactly like bonds not working. Watch every cell the
deck reads.

**One `setBond` per slider is one reactive run each.** Pushing six bonds sequentially runs
the notebook six times, and the early runs see bonds that are still `missing`. The bridge
writes the whole batch as a single notebook update.

**`worker.execute()` races the reactive run.** Pluto rotates to a fresh workspace module as
cells re-run, and an out-of-band eval hits `UndefVarError` for variables that run has not
republished. Anything the deck needs is published as a cell output instead — here
`series_out`, a JSON string the page parses. `execute()` is fine for one-off queries against
a settled notebook, not for data bound to the reactive cycle.

**`worker.execute()` writes to your notebook file.** The first call inserts a hidden
`eval_in_pluto` cell to register the js-link, and with the notebook opened in place that cell
is saved to disk. Harmless but permanent; another reason to publish data as ordinary cells.

**Bonds start as `missing`, and who fixes that depends on who owns the widget.** A
widget's own `value=` is never reported to the kernel by the act of rendering it. In this
spike the sliders are plain HTML in the deck's own page, outside anything Pluto rendered, so
nothing would ever report them and the bridge states every input once on load
(`pushAllBinds`). That is a property of *this* architecture and not of Pluto.

PlutoDeck does not work this way and must not copy it. Its widgets are Julia-defined, so they
arrive as `<bond>` elements inside cell output, and `RawHTMLContainer` calls
`set_bound_elements_to_their_value` and `add_bonds_listener` over that output itself: each
widget reports its own value as its card's scripts finish. A deck that also pushed every bond
on load would be writing values that are already on their way, and the batching in
`kernel.js` exists precisely because those self-reports arrive as a burst.

**The ESM build is not browser-ready as published.** It expects a bundler: immer reads
`process.env.NODE_ENV`, and the embedded browserify bundles reference `process` and
`global`. Importing `dist/index.esm.js` straight into a page throws `ReferenceError:
process is not defined` before anything connects. `frontend/vendor/browser-shim.js` supplies
the three globals and must stay the first import in `rainbow-bridge.js`. A jsdom or Node
harness cannot catch this, because Node defines `process` itself — only a real browser does.

**The Node integration has undeclared dependencies.** `@plutojl/rainbow/node-polyfill`
imports `ws` and `jsdom` without listing them. Only relevant off-browser.

## Measured

Steady-state on this machine, after the first run: **80–125 ms** from slider to redrawn
chart and metrics. `rainbow.esm.js` is 464 KB and imports nothing, so it vendors into an
offline deck the same way `reveal` and `katex` already do.

## What this does not solve

One server and one notebook mean one shared state: two browsers move each other's sliders.
Per-student isolation needs a worker per browser (a Julia process each) or
[PlutoSliderServer.jl][pss]. The deck also has no offline fallback yet — when no kernel is
reachable it should degrade to static figures, the way `deck.js` already handles a missing
figure.

[rainbow]: https://www.npmjs.com/package/@plutojl/rainbow
[pss]: https://github.com/JuliaPluto/PlutoSliderServer.jl
