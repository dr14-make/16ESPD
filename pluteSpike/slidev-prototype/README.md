# PROTOTYPE — PlutoDeck's live cards inside Slidev

Throwaway. It answers one question: can [Slidev](https://sli.dev) host PlutoDeck's live cards,
so lectures could be written in Slidev Markdown instead of the `ui/` Lit shell? It ports the
"Proportional" and "Proportional-integral" slides of `backend/lecture-01.deck.json`, with their
speaker notes, and reuses PlutoDeck's frontend modules unchanged through a `@plutodeck` alias.

## Run it

```sh
# 1. PlutoDeck starts Pluto, opens the notebook and answers /api/session and /api/deck on :8099
julia --project=../PlutoDeck.jl -e 'using PlutoDeck; present("../backend/lecture-01.deck.json")'
# 2. Slidev on :3030, proxying /api to PlutoDeck (needs ../PlutoDeck.jl/frontend `npm ci` first)
npm install && npm run dev
```

Open <http://localhost:3030/#/2>, and <http://localhost:3030/#/presenter/2> for the presenter.
The yellow bar on every slide is the probe: kernel status, which cards are mounted in which
Slidev render context, and the bond writes this window sent.

## Findings (Slidev 53.0.0, 2026-10-07)

**Pluto's renderer works inside Vue.** Vue renders into light DOM, so `closest("pluto-cell")`
reaches the payloads. PlutoPlotly plots, markdown tables and `@bind` sliders all render through
`render.painter.ts` with no change. A slider move reaches the settings readout in 200–350 ms
(measured to the table text, not the 80–125 ms chart figure in `../README.md`, so not
like-for-like).

**Widgets self-report, but only once mounted, and Slidev mounts only nearby slides.** PlutoDeck
mounts every slide at once, so every widget reports its value on load. Slidev mounts the current
slide and preloads its neighbors, so an input that sits only on a later slide stays `missing` and
the simulation never runs — the plot showed "waiting for the deck to send inputs". The prototype
works around it with a hidden preamble of those input cards in `global-top.vue`. An addon would
derive that list from the notebook's bonds instead of hand-writing it.

**Copies of one widget drift apart — in PlutoDeck too.** A card placed on several slides is
several independent `<input>`s. Moving `gain-p` on one slide leaves its copies on the others at
their old value, so the next slide shows Kp = 2 while the kernel holds 9. Reproduced on PlutoDeck
itself (one copy at 15, four at 9), so this is a gap in the shared card code, not in Slidev. A
widget would need to repaint when its bond changes, not only when its own cell re-runs.

**Presenter mode works and costs a second connection.** The presenter window renders the current
slide and the next-slide preview as live cards: 14 card mounts, 3 Plotly plots, one more websocket
to Pluto. Mounting it wrote no bonds, so opening it does not trigger a notebook run. Navigation
syncs between windows. Speaker notes render as Markdown, including the existing note files pasted
in verbatim.

**A built deck does not open as a file.** `slidev build --base ./` produces a page whose module
script and stylesheets Chrome blocks over `file://` (CORS, origin `null`): a blank page. Served
over HTTP it renders. Live decks are unaffected — PlutoDeck's server could serve `dist/` in place
of `frontend-dist/` — but static decks on a memory stick lose ADR 0001's no-server guarantee.

**Smaller things.**
- `slidev build` fails on Vite 8's CSS minifier over Slidev's own theme CSS; `cssMinify: false`
  works around it.
- PlutoDeck's esbuild `define` of `process.env.NODE_ENV` is not needed under Vite (its dependency
  optimizer defines it), and setting it globally turns off Vue's hot reload.
- Authored math is KaTeX; card math stays MathJax through `math.typesetter.ts`. Both coexist.
- Presenting needs Node for `slidev dev`, or a build step beforehand — DESIGN.md currently
  promises Node only to *edit* the frontend.
- Ki from the PI slide is in effect on the P slide, because every input is live at once. True of
  PlutoDeck too by the same reasoning, since it mounts every slide (not checked there); the P
  slide's "steady-state error is never zero" reads 0.0.

## Verdict

Feasible. Nothing about Pluto's renderer or bond model blocks Slidev. A `slidev-addon-pluto`
would be: `PlutoCard` plus the session composable here, a bond preamble derived from the
notebook, and the fix for drifting widget copies, which PlutoDeck needs anyway. The real cost is
the static-deck story: Slidev gives up opening from a file.
