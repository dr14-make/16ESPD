# pluteSpike — what the spike proved, and what it cost to learn

The spike that became `PlutoDeck.jl/`. It was a static page whose controls wrote Pluto `@bind`
values and whose readouts were Pluto cell outputs, driven over [`@plutojl/rainbow`][rainbow] by
a Node bridge.

**Its code is gone.** Every technique it proved is in the package now — the kernel client in
`PlutoDeck.jl/frontend/kernel.js`, the renderer in `render.js`, the repaint rule in `card.js`,
the browser shim in `frontend/vendor/`, and opening a notebook in place in `src/session.jl`.
The spike's own `frontend/`, `bridge/` and `start.sh` were kept only as reference
implementations, and a reference implementation nobody reads is a second copy that drifts. Read
them in the history if you need them; `PlutoDeck.jl` is what runs.

What could not move into code is below. Each of these cost real debugging time once, and every
one of them is still true of Pluto.

## Things that cost time, recorded so they only cost it once

**Uploads park in `waiting_for_permission`.** A notebook opened over `/notebookupload` will
not run until someone clicks "Run notebook code", which a deck cannot do. The upload needs
`?execution_allowed=true`. `warn_about_untrusted_code` is not the lever.

**`createWorker` cannot reach a secret-protected server.** It builds
`` `${server_url}/notebookupload` `` by concatenation and never forwards the secret, so it
400s or 403s. This is the whole reason the spike needed a Node bridge at all; the package
opens the notebook from Julia instead and the browser attaches to the returned id — the websocket URL *does* carry the secret. Leaving the secret off is not an
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
widget's own `value=` is never reported to the kernel by the act of rendering it. In the
spike the sliders were plain HTML in the deck's own page, outside anything Pluto rendered, so
nothing would ever report them and the bridge stated every input once on load. That was a
property of *that* architecture and not of Pluto.

PlutoDeck does not work this way and must not copy it. Its widgets are Julia-defined, so they
arrive as `<bond>` elements inside cell output, and `RawHTMLContainer` calls
`set_bound_elements_to_their_value` and `add_bonds_listener` over that output itself: each
widget reports its own value as its card's scripts finish. A deck that also pushed every bond
on load would be writing values that are already on their way, and the batching in
`kernel.js` exists precisely because those self-reports arrive as a burst.

**The ESM build is not browser-ready as published.** It expects a bundler: immer reads
`process.env.NODE_ENV`, and the embedded browserify bundles reference `process` and
`global`. Importing `dist/index.esm.js` straight into a page throws `ReferenceError:
process is not defined` before anything connects. `PlutoDeck.jl/frontend/vendor/browser-shim.js`
supplies the three globals and must stay the first import in `render.js`. A jsdom or Node
harness cannot catch this, because Node defines `process` itself — only a real browser does.

**The Node integration has undeclared dependencies.** `@plutojl/rainbow/node-polyfill`
imports `ws` and `jsdom` without listing them. Only relevant off-browser.

## Measured

Steady-state, after the first run: **80–125 ms** from slider to redrawn chart and metrics.
`rainbow.esm.js` is 464 KB and imports nothing, which is why it vendors into an offline deck the
same way `reveal` and `katex` already do.

## What the spike did not solve

One server and one notebook mean one shared state: two browsers move each other's sliders.
`DESIGN.md` settles that as a decision rather than a gap — one kernel per running instance,
never a multi-tenant server — and names [PlutoSliderServer.jl][pss] as the separate target for
a student opening a link on a phone. Degrading to static figures with no kernel reachable is
still open, deferred as cached snapshots.

[rainbow]: https://www.npmjs.com/package/@plutojl/rainbow
[pss]: https://github.com/JuliaPluto/PlutoSliderServer.jl
