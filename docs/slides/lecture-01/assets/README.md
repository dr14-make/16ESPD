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

**The notebooks have not been executed, so no figure in this directory exists yet.** Each
figure slot in the deck renders as a hatched placeholder naming the plot that belongs there
and the file to drop in. Dropping the file in is the whole hand-off: no markup changes.

Naming: `<notebook number>-<slug>.svg`, matching the `<img src>` already in the deck.

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

    savefig(plt, joinpath(@__DIR__, "..", "..", "docs", "slides", "lecture-01",
                          "assets", "figures", "03-gain-family.svg"))

## Which figure belongs to which slide

The deck is the index: every slot carries the source notebook and the cell heading that
produces it in the card directly above or beside it. Searching this file for a slug finds
nothing; searching `../index.html` for it finds the slide.

## What the code on the demo slides assumes

The notebooks did not exist when the deck was written, so the snippets on the demo cards were
written against what *does* exist and one thing that does not yet.

Real, and used as documented:

- `notebooks/lecture01/support.jl` — `setup`, `CAR`, `sweep`, `signal`, `plot_speed`,
  `plot_sweep`, `plot_torque`, `bracket_error!`, `steady_state_error`, `overshoot`, `rise_time`,
  `fopdt_fit`, and the `SPEED_KMH` / `TORQUE_CMD` / `TORQUE_DELIVERED` signal paths.
- `test/tuning_tables.jl` — `cohen_coon(K, tau, theta)`, `ziegler_nichols(Ku, Pu)`,
  `tyreus_luyben(Ku, Pu)`, each returning `(k, Ti, Td)`.
- The Dyad component and parameter names from `docs/lecture-01-dyad-tasks.md` — `CarPlant`,
  `CruiseLoop`, `with_I`, `with_D`, `k`, `Ti`, `Td`, `Nd`, `GradeProfile`, `FrictionProfile`.

Proposed, and named consistently across all ten sections — the scenario builders that
`lecture-01-plan.md` places in the shared helper under `src/`. Each returns an uncompiled
system, so a notebook either solves it or hands it to `sweep`:

    car_plant(; tau_cmd, grade = 0.0, m, CdA)      open loop at a constant torque
    car_step_test(; tau_lo, tau_hi, t_step)        open-loop torque step
    cruise_loop(; with_I, with_D, k, Ti, Td, v_set)   the 90 -> 110 km/h step scenario
    cruise_climb(; grade, t_climb, v_set, antiwindup)  the sustained climb
    cruise_sampled(; Ts, k, Ti, Td)                the sampled loop
    cruise_noisy(; Nd, k, Ti, Td)                  the noisy speedometer
    wheeled_cruise_loop(...)  standing_start(; mu_scale)  ice_patch(; mu_low, t_ice)

Two internal signal paths are also assumed, for plotting a controller path on its own:
`controller.P.y`, `controller.I.y`, `controller.D.y`.

**If the notebooks land under different names, the slides need a search and replace, not a
redesign.** Each card's notebook filename and cell heading are the load-bearing part; the code
block is a convenience.
