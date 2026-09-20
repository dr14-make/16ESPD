# 009 — Card renderer via rainbow ui

- **Labels** — `enhancement` · `priority:high` · `complexity:m` · `agent-ready`
- **Depends on** — 007
- **Traces to** — DESIGN.md § Cards render through Pluto's own renderer

## Context

Assigning to `innerHTML` never executes inserted script tags. Since most Pluto output is a container plus a script that fills it, a naive renderer shows empty boxes for Plotly, PlutoUI widgets and most `@bind` elements.

## Proven in a spike

A de-risking spike ran this issue first, since it is the only one whose failure would
invalidate the design. It is **proven**: in real headless Chrome a Plotly card renders with a
live modebar and redraws from a slider in 38-84 ms, a Julia-defined `@bind` widget renders,
and there are no page errors. `../../HANDOFF.md` § Issue 009 carries the detail. The package
code still has to be written; what is settled is that the approach works and exactly how.

The spike's probe lives at `frontend/ui-probe.html` and `frontend/ui-probe.js` in the spike,
and is set up to retest in one edit-and-rerun cycle.

## Scope

- Render cell output through `@plutojl/rainbow/ui`'s `OutputBody` and `RawHTMLContainer`, which re-create script nodes so they execute and resolve `published_to_js` payloads.
- Handle `text/html`, `text/plain` and image mime types.
- Wrap each card in a `<pluto-cell>` element carrying `getPublishedObject`. `execute_scripttags` resolves published objects via `root_node.closest("pluto-cell")`, and without that ancestor the script **dies silently** — no exception, nothing rendered.
- Repaint a card only when its own cell's `last_run_timestamp` advances. A notebook diff arrives for every cell many times per run, and repainting on every diff rebuilds a Plotly graph against a multi-megabyte payload over and over.
- Provide the Preact contexts those components require. `PlutoJSInitializingContext` must be a `Set` — `RawHTMLContainer` calls `.add(container)` while scripts run and `.delete(container)` after, and the wrong shape means **no script ever runs**.
- Resolve `published_to_js` payloads. They live in `notebook.published_objects`, not in the cell body, and the body only calls a bare `getPublishedObject("<notebook_id>/<hash>")`. Supplying `get_published_object` in the actions object is necessary but not sufficient: `Cell` attaches `getPublishedObject` onto the cell's DOM node via `useCellApi(node_ref, published_object_keys, pluto_actions)`, and a card has to do the same.
- Support a **preamble card**: rendered, hidden, ordered first. `enable_plutoplotly_offline()` is a cell whose output is a side-effecting script that must execute before any plot card renders, yet must not be shown on a slide.

## Done when

- A Plotly card renders an interactive plot, verified in a real browser — not in jsdom, which cannot see this class of failure.
- A `@bind` widget defined in Julia renders and writes its value back to the kernel.
- A plain-text output renders without markup injection.

## Out of scope

- `CellInput`. Cards show output; the deck is not an editor.

## Note

Bundle budget: `dist/ui/ui.esm.js` is 3.7 MB against 464 KB for the standalone client.

Offline Plotly costs more than bundle size. `enable_plutoplotly_offline()` pushes the whole
plotly ESM library through `published_to_js` — measured at 3.82 MB crossing the websocket into
`notebook.published_objects` on every kernel start. Without it, PlutoPlotly fetches from
`cdn.plot.ly`, `esm.sh` and `jsdelivr`, forfeiting the offline guarantee.
