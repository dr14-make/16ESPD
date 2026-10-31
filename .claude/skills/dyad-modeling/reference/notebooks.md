# Notebooks, exported figures, guides and reference copies

The course's notebooks are Pluto files (`notebooks/lecture0N/NN-name.pluto.jl`); a script in
`scripts/` with a `mise.toml` task runs them headless and writes the deck's figures. Copy the
shape of the newest lecture's notebook and export script, `@bind` mock and cell markers included.

## Setup cell

`notebooks/lecture01/support.jl` holds `setup()`, which activates the project and loads the library.
On the Dyad 3.5 distribution pass `setup(backend = :plotly)`: the distribution ships Plots with
PlotlyBase and PlotlyKaleido, and the default `:gr` fails with `Package GR not found`.

## Plotly traps

Each one exports without an error:

- `Plots.savefig` hands Kaleido no size, so every SVG comes out 700 × 500 whatever `size` says.
  Convert the plot to its plotly figure and pass its size to Kaleido.
- Plotly simplifies lines by default, which draws smooth curves as visible polygons: set
  `line.simplify = false` on every trace.
- `vspan!` and `hspan!` write infinite bounds, which the JSON writer rejects (`-Inf not allowed`);
  shade with a finite `Shape`.

## Iterate in the warm session

`include` the export script as a warm-session step: the models stay compiled, so a figure change
costs seconds. Once the figures are right, run the `mise` task once from a fresh process — that is
the "runs headless" check.

## Look at each figure

`savefig` a PNG copy beside each SVG into the scratch directory and read the PNG. A rendering of
the plotly SVG by another tool (ImageMagick) misdraws it. Check the figure against the deck slide
it replaces.

## Size

A figure carries every point handed to it, clipped ones included (HANDOVER has the case): hand
each panel only its window, and thin the saved grid of a switching run before plotting.

## Stage only the figures you meant

An export rewrites every figure it touches, and plotly gives each SVG fresh random ids, so figures
whose content did not change show up as modified. `git checkout -- <path>` each of those before
staging, and stage the figures you meant by name.

## Guides and reference copies

A guide that prints a component's code, and a hands-on module that holds a copy of a library
component, are users of that component (SKILL.md, step 1). Keep them from drifting:

- Generate a guide's code blocks from the `.dyad` source by stripping the annotations (`{^tag}`s
  and the `metadata` block), rather than pasting them; regenerate after every change.
- A reference copy in a hands-on module is the library file with only its name changed, compiled
  in that module, and checked by a test that runs the copy and the original on one case and
  compares the results.
- Run every REPL snippet the guide prints, in the warm session, exactly as printed.
