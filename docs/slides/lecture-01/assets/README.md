# Deck assets

Everything the deck loads is in this directory. The deck is presented from a lecture hall and
must render with the network off, so nothing here is fetched from a CDN at run time.

| Path | What | Version |
|---|---|---|
| `reveal/` | reveal.js — `dist/`, and the `notes`, `highlight`, `math`, `zoom`, `search` plugins | 5.2.1 |
| `katex/` | KaTeX, loaded by reveal's math plugin through `katex: { local: 'assets/katex' }` | 0.16.11 |
| `deck.css` | light-theme overrides, demo cards, figure placeholders | — |
| `deck.js` | copy buttons, figure drop-in, the on-slide cue panel, the footer | — |
| `highlight-light.css` | light syntax theme; the bundled reveal themes are both dark | — |
| `figures/` | plots exported from the notebooks — see below | — |

Trimmed from the upstream packages: source maps, ESM builds, the MathJax variants of the math
plugin, the unused reveal themes, KaTeX's `.ttf` fonts (`.woff2`/`.woff` cover every browser
that runs reveal.js 5), and reveal's League Gothic face.

## Figures

Nine of the deck's thirty-one figures are in — all of sections 03, 04 and 05. Every other
slot renders as a hatched placeholder naming the plot that belongs there and the call that
fills it. Filling it is the whole hand-off: no markup changes.

Naming: `<notebook number>-<slug>.svg`, matching the `<img src>` already in the deck.

**This file's `index.html` is the authoritative list of figure names.** `save_figure` in
`notebooks/lecture01/support.jl` reads the slots out of it and refuses a name that is not one,
so a typo cannot go quiet in either direction — the notebook would otherwise write a file
nothing loads while the slide went on showing a placeholder. Two consequences:

- **Renaming a slot orphans its file.** Rename here, rename the file on disk, and re-run the
  notebook that writes it.
- `deck_figures()` caches the slot list per session, so a slot added while a kernel is live is
  not visible to it until the kernel restarts.

    figures/01-speed-to-terminal.svg
    figures/03-gain-family.svg
    figures/06-three-way-antiwindup.svg

Rules:

- **SVG preferred.** It stays sharp on a projector and in the `?print-pdf` handout. A `.png`
  under the same base name is picked up automatically if the SVG is absent, so a raster
  backend needs no edit either.
- **Export at the aspect ratio the slot expects** — landscape, roughly 4:3 to 16:9. Figures are
  capped by height, so a tall plot shrinks to nothing.
- **Titles and axis labels come from the plot**, not from the slide. The caption under each
  slot says what the plot must show; it does not repeat the axis labels.
- **Do not hand-draw a figure.** A placeholder is the honest state; an illustrative curve that
  looks like a simulation result is worse than a gap, because a student cannot tell them apart.

From a notebook, with the plot in `plt`:

    save_figure(plt, "03-gain-family")

### Slots with no producer yet

Notebook 01 is executed and draws all three of its plots, but calls `save_figure` for none of
them, so section 01 still shows placeholders. The three slots match its three plots one for
one:

| slot | notebook 01's plot |
|---|---|
| `01-speed-to-terminal.svg` | section 4, full torque from rest |
| `01-step-response.svg` | section 5, the speed response to the torque step |
| `01-torque-step.svg` | section 5, commanded against delivered torque, zoomed |

There is deliberately no slot for an *annotated* step: the notebook prints `K`, `tau` and
`theta` rather than drawing them on the curve, and the slide points at the plain response
while the lecturer names the regions.

## Which figure belongs to which slide

The deck is the index: every slot carries the source notebook and the cell heading that
produces it in the card directly above or beside it. Searching this file for a slug finds
nothing; searching `../index.html` for it finds the slide.

## What the code on the demo slides assumes

Sections 01, 03, 04 and 05 quote the executed notebooks verbatim — the shipped Dyad analyses,
the real signal paths, the real numbers. Sections 02 and 06–10 have no notebook yet; their
cards use the same idiom against models that do exist, and are a proposal until those
notebooks land.

Shipped and used as documented:

- `notebooks/lecture01/support.jl` — `setup`, `CAR`, `sweep`, `rerun`, `signal`, `save_figure`,
  `plot_speed`, `plot_sweep`, `plot_torque`, `bracket_error!`, `steady_state_error`,
  `overshoot`, `rise_time`, `fopdt_fit`.
- `test/tuning_tables.jl` — `cohen_coon(K, tau, theta)`, `ziegler_nichols(Ku, Pu)`,
  `tyreus_luyben(Ku, Pu)`, each returning `(k, Ti, Td)`.
- The Dyad analyses, called directly as the notebooks call them:

      Scenarios = VehicleSystemsComponents.Lecture1
      Scenarios.WideOpenThrottleTransient()
      Scenarios.CarStepTestTransient(tau_lo =, tau_hi =, v0 =, t_step =)
      Scenarios.CruiseLoopTransient(k =, Ti =, Td =, T_max =, y_max =, stop =)

  PI and PID come from passing a differently-configured harness, because `with_I` and `with_D`
  are structural:

      model = Scenarios.CruiseLoopStep(; name = :CruiseLoopStep, with_I = true, with_D = false)

- Signal paths: `plant.v_kmh` and `plant.engine.limiter.y` inside the open-loop harnesses;
  `loop.plant.v_kmh`, `loop.controller.y`, `loop.controller.integrator.y`,
  `loop.controller.proportional.y`, `loop.controller.derivative.y` inside the loop.

Still proposed, for the notebooks that do not exist yet — the climb, the sampler, the noise
source and the slip scenarios have no harness in `dyad/Lecture1/` yet:

    cruise_climb(; grade, t_climb, v_set, antiwindup)
    cruise_sampled(; Ts, ...)     cruise_noisy(; Nd, ...)
    wheeled_cruise_loop(...)      standing_start(; mu_scale)     ice_patch(; mu_low, t_ice)

**The notebook filename and the cell heading are the load-bearing part of a card**; the code
block is a convenience, and a rename is a search-and-replace rather than a redesign.

## "Open in Dyad" strips

A demo card says what to *run*. A `.model` strip says what to *open beside it* and what to
point at:

    <div class="model">
      <span class="label">Open in Dyad</span>
      <code>dyad/Vehicle/IdealEngine.dyad</code>
      <span class="show">show — <b>delay → lag → limiter</b>, in that order.</span>
    </div>

Add `class="model solo"` when it stands on a concept slide with no demo card above it.

These are deliberately sparse. A strip earns its place only where the diagram says something
the plot cannot — the four forces on one flange in `VehicleBody`, the constant ceiling in
`IdealEngine`'s limiter, the feedback wire and the two `structural parameter` lines in
`CruiseLoop`, the finite `duration` in `GradeProfile`. Everywhere else the model is a
distraction from the plot.

## Editing the deck

`index.html` is assembled from `../src/` — one file per horizontal section, plus `_head.html`
and `_foot.html`:

    src/_head.html                 <head>, the stylesheets, the opening <div class="slides">
    src/00-front-matter.html       horizontal index 0
    src/01-the-car.html            horizontal index 1
    ...
    src/10-wheel-and-slip.html     horizontal index 10
    src/_foot.html                 the scripts and Reveal.initialize

    python3 build.py               rebuild index.html
    python3 build.py --check       fail if index.html is stale (for CI or a pre-commit hook)
    python3 build.py --figures     which slots are filled, and which notebook writes each

**Filename order is slide order, and the deck's deep links depend on it** — `#/3` is
`03-proportional.html`. Renaming a file moves a section and breaks the landing page's links.

`index.html` is committed as well as generated. The deck is presented from a laptop in a
lecture hall, sometimes from a copied directory, so it must never need a build step to open.
Edit under `src/`, run `build.py`, commit both.

Splitting per *slide* rather than per section was considered and rejected: a section is the
unit anyone actually edits, 99 files would need a manifest to keep ordered, and reveal.js needs
every slide in one document anyway — `data-markdown` external files are fetched over XHR, which
a `file://` origin blocks, so runtime splitting would break the one requirement that matters
most.
