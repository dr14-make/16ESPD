# `pluto` — live cards in a Slidev deck

A deck that names this addon in its headmatter can place cells of a running Pluto notebook on
its slides. Static decks do not name it, so they carry none of its libraries. A live deck also
names its notebook, relative to the deck file, as `pluto.notebook`; that is what makes it live,
so the workspace checks its cues but never builds or publishes it.

```md
---
addons:
  - ./addon-pluto
pluto:
  notebook: ../../pluteSpike/backend/notebook.jl
---

## Proportional

<Grid>
  <Card :x="0" :y="0" :w="3" :h="3"><PlutoCard name="gain-p" /></Card>
  <Card :x="3" :y="0" :w="9" :h="12"><PlutoCard name="speed-plot" /></Card>
</Grid>
```

`name` is the card a notebook cell declares in its metadata. A name no cell declares shows that
in red on its card. `Grid` and `Card` come from
`addon-course` and place any block, not only live cards: a `Card` spans `w` columns and `h` rows
from column `x` and row `y` of a `Grid` (12 × 12 unless `cols` and `rows` say otherwise). A `Card`
that does not fit its `Grid`, or sits outside one, shows that in red instead of its content. A live
card fills its `Card`, and shows its name in a dashed box until the kernel is live.

## Running against a kernel

PlutoDeck.jl starts the deck's notebook and answers `/api/session` and `/api/deck`; `slidev dev`
proxies `/api` to it, on port 8099 unless `PLUTODECK_URL` says otherwise. The browser opens its
own websocket to Pluto. To present the lecture-01 live deck from the repository root, after
`npm ci` in `slides/`, run these in two terminals:

```sh
julia --project=pluteSpike/PlutoDeck.jl -e 'using Pkg; Pkg.instantiate(); using PlutoDeck; present("slides/lecture-01-live/slides.md")'
cd slides && npx slidev lecture-01-live/slides.md
```

The kernel is ready about 30 s after the first command prints its URLs. Edits to the slides
hot-reload without restarting it. Pluto saves the notebook it opens, so presenting leaves
`notebook.jl` modified.

## What it does for a deck

- **One kernel session per window.** The audience window and presenter mode each connect.
- **Every input reports.** Slidev mounts only the slides near the current one, and three seconds
  later every slide not marked `preload: false`. A hidden layer (`global-top.vue`) renders every
  card whose cell holds `@bind` as soon as the deck opens, so a plot that reads an input from a
  later slide draws on the first live slide.
- **Copies of a widget agree.** Moving one copy updates the others, in every window, without a
  second bond write.
- **Plots and math need no network.** Plotly, MathJax, and the lodash and interact.js modules a
  plot script imports by CDN URL are served from the deck under `pluto/` (`vendor.plugin.ts`,
  `index.html`).
- **Plots fill their card** on a slide Slidev has scaled to the window (`src/plot.size.ts`).
- **Dark mode reaches the plots** of a notebook that declares a `deck_theme` bond. Only the
  audience window writes it.

The browser suite in `pluteSpike/PlutoDeck.jl/test/browser.jl` drives `pluto-fixture/` against a
real kernel. The unit tests in `src/` run with the workspace's `npm test`.
