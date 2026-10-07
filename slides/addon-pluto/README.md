# `pluto` — live cards in a Slidev deck

A deck that names this addon in its headmatter can place cells of a running Pluto notebook on
its slides. Static decks do not name it, so they carry none of its libraries.

```md
---
addons:
  - ./addon-pluto
---

## Proportional

<Grid>
  <PlutoCard name="gain-p" :x="0" :y="0" :w="3" :h="3" />
  <PlutoCard name="speed-plot" :x="3" :y="0" :w="9" :h="12" />
</Grid>
```

`name` is the card a notebook cell declares in its metadata; `x`, `y`, `w` and `h` place it on
the slide's `Grid`, which `addon-course` gives every deck (12 × 12 unless `cols` and `rows` say
otherwise). Without them a card is a block in the slide's own flow. A card shows its name in a
dashed box until the kernel is live.

## Running against a kernel

PlutoDeck.jl starts the notebook and answers `/api/session` and `/api/deck`; `slidev dev`
proxies `/api` to it, on port 8099 unless `PLUTODECK_URL` says otherwise. The browser opens its
own websocket to Pluto.

```sh
julia --project=pluteSpike/PlutoDeck.jl -e 'using PlutoDeck; present("path/to.deck.json")'
cd slides && npx slidev <deck>/slides.md
```

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
