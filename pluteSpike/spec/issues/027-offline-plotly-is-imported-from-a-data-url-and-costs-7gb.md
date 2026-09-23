# 027 — Offline Plotly is imported from a `data:` URL, and the renderer pays 7 GB for it

- **Labels** — `bug` · `priority:high` · `complexity:s` · `agent-ready`
- **Depends on** — 014
- **Traces to** — HANDOFF.md § A 7.4 GB renderer, and it is one `import()`

## Context

A deck tab measured **7,430,164K** in Chrome's own task manager. It is reproducible, it is the
deck's own tab rather than a test harness, and it is what pushes `earlyoom` — which runs
`--prefer (julia|node)` on this machine — into killing the Pluto kernel. In a lecture it takes
the tab down mid-class.

The cost is one `import()`, paid once at load. It is not a leak, nothing accumulates with use,
and no amount of presenting makes it worse.

`enable_plutoplotly_offline()` ships the Plotly bundle to the browser through
`PlutoPlotly.import_local_js`, which builds a `data:` URL out of it and imports that:

```js
reader.readAsDataURL(new Blob([code], { type: "text/javascript" }))
// reader.onload:
resolve(await import(reader.result))
```

`reader.result` is `data:text/javascript;base64,` followed by 4,987,816 bytes of base64. Chrome
answers a single import of that URL with gigabytes.

## Evidence

**Reduced to one variable.** The same file — `plotly-esm-min.mjs`, 3,740,861 bytes, the artifact
PlutoPlotly ships — imported three ways into an otherwise empty page with nothing else on it:

| `import()` of `plotly-esm-min.mjs` | renderer RSS |
|---|---|
| over `http://` | 0.18 GB |
| from a `blob:` URL | 0.17 GB |
| from a `data:text/javascript;base64,` URL | ≥4.70 GB, still climbing when the run was stopped |

No deck, no Pluto, no kernel, no repaints. The `data:` row is the whole bug.

**What the 7.4 GB is made of**, read out of the live renderer while it was still running. Of
7.04 GB resident, `[anon:partition_alloc]` holds 7,022 MB and `[anon:v8]` — the JavaScript heap —
holds **40.6 MB**. Scanning partition_alloc for long base64 runs accounts for 6.79 GB in 2,907
runs, **100% of its non-zero bytes**, and those runs are copies of that one data URL: the bytes
after `data:text/javascript;base64,` match `base64 plotly-esm-min.mjs` exactly. About 1,430
retentions of a 4.76 MB string, from one import.

**Causation.** `Page.addScriptToEvaluateOnNewDocument` wrapped `FileReader.prototype.readAsDataURL`
to swap the blob for a stub after the first call. The deck then loaded — kernel `ready`, cards
painted, math typeset — and the renderer sat **flat at 0.31 GB**, against 7.45 GB uncapped on the
same deck. Four `readAsDataURL` calls, one carrying 3,740,861 bytes;
`window.created_imports.size` was 1.

**Why this was missed before.** The retained bytes are Blink strings, not JS objects.
`usedJSHeapSize` reports 40 MB of a 7.4 GB renderer and `Runtime.queryObjects(Document.prototype)`
cannot see them at all, so the reload experiment recorded in HANDOFF.md was blind to this by
construction and its conclusion has been narrowed to what it measured. **The honest instrument is
the renderer's RSS in `/proc`, not a JS-heap reading.**

Headed versus headless is not the axis: the headed tab plateaued at 7.43 GB and a headless
renderer on the same deck at 7.45 GB.

## Scope

Establish that a presented deck does not put a multi-gigabyte renderer in front of a lecturer.

The bug is upstream, in `PlutoPlotly/src/local_plotly_library.jl`. Pluto's own frontend already
treats large payloads the other way — `CellOutput.js` builds a `blob:` URL with
`URL.createObjectURL` and revokes it on detach, and reserves `readAsDataURL` for hashing — so the
fix is the pattern Pluto already uses, not a new one:

```js
const url = URL.createObjectURL(new Blob([code], { type: "text/javascript" }))
const mod = await import(url)
URL.revokeObjectURL(url)
return mod
```

The `blob:` row above is that change measured on the real bundle: 0.17 GB.

**Chosen route — 028.** The deck serves Plotly as a file, the way `build.mjs` already serves
MathJax, and populates `window.plutoplotly_imports` itself. That is the `http://` row above,
0.18 GB, and it keeps offline plots working without waiting on an upstream release. The two
routes not taken:

- **Upstream.** Patch `import_local_js` in PlutoPlotly. The more correct fix, and still worth
  reporting there, since every caller of `enable_plutoplotly_offline()` pays this. Rejected as
  the primary route only because it puts a lecture behind someone else's release.
- **Drop offline mode.** Delete the call from `backend/notebook.jl` and fetch Plotly from the
  network. One line, and it gives up exactly what offline mode exists to provide. Worth keeping
  in mind as the emergency move if a lecture lands before 028 does.

## Done when

- Presenting the lecture-1 deck leaves the renderer under 500 MB of RSS, measured from `/proc`
  after the kernel reports `ready`, rather than 7.4 GB.
- Plots still draw and still redraw from a bond, offline.
- The suite has a check that reads the renderer's RSS rather than its JS heap, so a regression
  here cannot pass the way it passed before.

## Out of scope

- The paint model. Repaint is not implicated: the balloon is finished inside a second of load,
  sampled at `plots=0`, before any bond is driven.
- `PAYLOAD_DEPTH`, `isolate`, detached graphs, Plotly resize listeners, MathJax's SVG output.
  All of these live on the 40.6 MB JS heap, and there is no room in it for this.
- Issue 023, whose `present` interrupt behavior is unrelated and separately filed.
