# `pluto` — live cards in a Slidev deck

A deck that names this addon in its headmatter can place cells of a running Pluto notebook on
its slides. Static decks do not name it, so they carry none of its libraries. A live deck also
names its notebook, relative to the deck file, as `pluto.notebook`. The workspace builds and
publishes a live deck like any other; with no kernel behind it, each card shows only its name.

```md
---
addons:
  - pluto
pluto:
  notebook: browser.jl
---

## Proportional

<Grid>
  <Card :x="0" :y="0" :w="3" :h="3"><PlutoCard name="gain-p" /></Card>
  <Card :x="3" :y="0" :w="9" :h="12"><PlutoCard name="speed-plot" /></Card>
</Grid>
```

`name` is the card a notebook cell declares in its metadata. The deck reads those declarations
from the running notebook, so a name no cell declares, or one that two cells declare, shows that
in red on its card. `Grid` and `Card` come from the course addon (`slides/addons/course/`) and
place any block, not only live cards: a `Card` spans `w` columns and `h` rows from column `x` and
row `y` of a `Grid` (12 × 12 unless `cols` and `rows` say otherwise). A `Card`
that does not fit its `Grid`, or sits outside one, shows that in red instead of its content. A live
card fills its `Card`, and shows its name in a dashed box until the kernel is live.

## Running against a kernel

`slidev dev` starts Pluto itself when the deck it serves names a notebook: `kernel/pluto.jl` opens
the notebook, allowed to run, on a free port and behind a fresh secret. Its output goes to the dev
server's terminal, prefixed `[pluto]`. The page imports the URL and secret as the module
`virtual:pluto-session` (`setup/vite-plugins.ts`), which the dev server answers once Pluto does.
Vite refuses a request addressed to any host but this machine, so another site cannot read them by
rebinding its name to 127.0.0.1, and a build never carries them. The browser then opens its own
websocket to Pluto and finds the notebook among the ones Pluto is running by its path. Stopping
the dev server stops Julia and every worker it started. To present a deck from the repository
root, after `npm ci` in `slides/`:

```sh
mise run present slides/decks/<deck>/slides.md
```

Julia is `julia` on the path, or the binary `JULIA` names, and juliaup's `JULIAUP_CHANNEL` picks
another channel; Pluto's workers run on the same Julia. The first start resolves Pluto 1.0.4 into
`kernel/`. The kernel is ready about 30 s after the deck starts, and each card fills in as its cell
runs. Edits to the slides hot-reload without restarting it, but a deck that names another notebook
needs slidev restarted (`r`). Pluto saves the notebook it opens, so presenting can leave the
notebook file modified.

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

The live suite in `test/live.test.ts` drives `slides/decks/pluto-fixture/` in headless Chromium,
through Playwright, against a real kernel: it starts `slidev dev` itself, cuts the network, and
checks that stopping slidev leaves no Julia process behind. It needs Julia, as above, so it stays
out of `npm test` and CI. From the repository root:

```sh
(cd slides && npx playwright install chromium)   # once, if Playwright's Chromium is missing
mise run test:live
```

The unit tests in `src/` run with the workspace's `npm test`, and the types and lint of the whole
addon with `npm run typecheck` and `npm run lint`.
