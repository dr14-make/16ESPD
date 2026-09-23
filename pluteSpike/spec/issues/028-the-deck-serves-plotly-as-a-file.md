# 028 — The deck serves Plotly as a file, the way it already serves MathJax

- **Labels** — `bug` · `priority:high` · `complexity:m` · `agent-ready`
- **Depends on** — 027, 007, 014
- **Traces to** — HANDOFF.md § A 7.4 GB renderer, and it is one `import()`

## Context

027 establishes the defect and its evidence: the offline Plotly bundle reaches the browser as a
*string* rather than a *file*, so something has to invent a URL for it, and the URL it invents is
`data:text/javascript;base64,` + 4.76 MB. One `import()` of that costs the renderer ~7.4 GB.
Read 027 before this; it is not repeated here.

This issue is the chosen route out. **Give Plotly a real URL.** The same module over `http://`
was measured at 0.18 GB against ≥4.70 GB for the data URL, so the fix is to stop asking the
browser to load a library out of a string.

The deck already does exactly this for a library of comparable size. `frontend/build.mjs` copies
`mathjax/es5/tex-svg-full.js` out of `node_modules`, content-hashes it into `frontend-dist/` —
2.2 MB, sitting there as `tex-svg-full-FCOWBU3W.js` — and the page links it. MathJax costs
nothing. Plotly is the same problem with an established answer in the same file.

The route not taken is patching `import_local_js` in PlutoPlotly upstream, which is the more
correct fix and should still be reported there. It is not this issue because it makes a lecture
wait on someone else's release.

## The hinge PlutoPlotly already gives us

Plot cells do not embed the library. `_ImportedHybridJS` emits, per plot:

```js
window.plutoplotly_imports?.['3.0.1'] ?? (await import("https://esm.sh/plotly.js-dist-min@3.0.1")).default
```

So a plot uses whatever is at `window.plutoplotly_imports[version]` and otherwise goes to the
network. `enable_plutoplotly_offline()`'s entire job is populating that global — badly. The deck
can populate it well, and no plot cell has to change.

## Scope

**Bundle Plotly as a served file.** Add the Plotly distribution as a frontend dependency pinned
to the version `PlutoPlotly.get_plotly_version()` reports for the notebook's environment —
`3.0.1` under the current `PlutoPlotly = "~0.6.6"` — and emit it into `frontend-dist/` the way
`copyMathJax()` in `build.mjs` already emits MathJax.

**Populate the global before any plot paints.** The deck sets
`window.plutoplotly_imports = { "<version>": <the Plotly object> }` and awaits that before
painting plot cards. The ordering step exists: `#publish()` in `deck-app.component.ts` already
paints the preamble first and awaits `whenScriptsSettled()` precisely so a plot card is never
drawn before Plotly is on `window`. What changes is where the bundle comes from, not the order.

**Retire the notebook's preamble.** `enable_plutoplotly_offline()` comes out of
`backend/notebook.jl` and `"preamble": ["plotly"]` empties in `lecture-01.deck.json`. The
notebook is Pluto's file — **go through the websocket, never hand-edit it**, per START-HERE.

## Two things to verify rather than assume

Neither is established, and both change the shape of the work if they come out the other way:

- **Does the npm distribution satisfy the hybrid import?** PlutoPlotly ships a custom ESM build
  from `PlotlyArtifactsESM`; npm's `plotly.js-dist-min` is UMD and assigns `window.Plotly`.
  What lands at `window.plutoplotly_imports[v]` must be whatever a plot cell can use where it
  would otherwise have put `(await import(esm.sh)).default`. Check this first — it is the
  assumption the whole route rests on. If the UMD object will not do, serve PlutoPlotly's own
  artifact from a `src/server.jl` route instead: `_respond` falls through to `_asset_response`,
  so a `/vendor/plotly.mjs` route is a two-line addition, at the cost of PlutoDeck needing to
  resolve that artifact path.
- **Version agreement.** If the pinned frontend version and `get_plotly_version()` ever drift,
  the key does not match, nothing errors, and every plot quietly fetches from `esm.sh` — which
  works on a desk and fails in a lecture room with no wifi. This degrades silently, so it needs a
  test, not a comment.

## Done when

- Presenting the lecture-1 deck leaves the renderer **under 500 MB of RSS**, read from
  `/proc/<renderer>/status` after the kernel reports `ready`, against 7.4 GB today.
- No `data:text/javascript` URL is created at any point in a deck load.
- Plots draw, and redraw from a bond, with **no network reachable** — the property offline mode
  exists for. Test it with the network actually cut, not by inspection.
- A test fails if the bundled Plotly version and the version a plot cell asks for disagree.
- The suite gains a check that reads the **renderer's RSS**, not `usedJSHeapSize`. 027 records
  why: the JS heap was 40.6 MB of a 7.4 GB renderer, so every JS-heap instrument passed this bug.

## Out of scope

- Patching PlutoPlotly upstream. Worth reporting, tracked separately, not a prerequisite here.
- Explaining *why* Chrome retains ~1,430 copies of the URL. The number is measured; the mechanism
  is not established, and no route out of this depends on knowing it.
- The paint model, `PAYLOAD_DEPTH`, `isolate`, MathJax. 027 eliminates each by measurement.
