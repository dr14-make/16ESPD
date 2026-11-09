"""
Writes the Lecture 5 deck's engine figures into `slides/decks/lecture-05/public/figures/`.

    julia +dyad-3.5.0 --project=. scripts/export_lecture05_figures.jl [figure ...]

With no arguments it writes `05-bsfc-line`: the BSFC map of `notebooks/lecture05/bsfc_map.jl`,
computed from the engine's tables with no Dyad model.

The figures in `NOTEBOOK_FIGURES` are written only when named: each runs its notebook in
`notebooks/lecture05/` top to bottom, simulations included, in a module of its own, since a
notebook assigns the global `VehicleSystemsComponents`, which would collide with the package
`setup()` loads into `Main`. A notebook figure that is still `nothing` is not written.
"""
module Lecture05Figures

using Plots
import PlotlyBase, PlotlyKaleido
plotly()
include(joinpath(@__DIR__, "plotly_svg.jl"))
const NOTEBOOKS = normpath(@__DIR__, "..", "notebooks", "lecture05")
include(joinpath(NOTEBOOKS, "operating_points.jl"))
include(joinpath(NOTEBOOKS, "bsfc_map.jl"))
using .BsfcMap: bsfc_map_plot

const ROOT = normpath(@__DIR__, "..")
const OUT = joinpath(ROOT, "slides", "decks", "lecture-05", "public", "figures")
const MAP_FIGURE = "05-bsfc-line"
const NOTEBOOK_FIGURES = Dict(
    "01-operating-points.pluto.jl" => ["05-operating-points-conventional" => :conventional_plot],
    "02-p-positions.pluto.jl" => ["07-p-position-table" => :position_table_plot],
)

function export_notebook(notebook, figures)
    mod = Core.eval(Main, :(module $(Symbol("Notebook_", replace(notebook, r"\W" => "_"))) end))
    Base.include(mod, joinpath(NOTEBOOKS, notebook))
    for (name, plot) in figures
        p = Core.eval(mod, plot)
        if p === nothing
            @warn "$name: the notebook's `$plot` is `nothing`; not written"
            continue
        end
        path = Base.invokelatest(save_svg, p, joinpath(OUT, "$name.svg"))
        println("wrote $(relpath(path, ROOT))")
    end
end

function main(wanted = String[])
    wanted = isempty(wanted) ? [MAP_FIGURE] : wanted
    known = [MAP_FIGURE; [n for fs in values(NOTEBOOK_FIGURES) for (n, _) in fs]]
    unknown = setdiff(wanted, known)
    isempty(unknown) || error("no such figure: $(join(sort!(unknown), ", "))")
    mkpath(OUT)
    if MAP_FIGURE in wanted
        path = save_svg(bsfc_map_plot(), joinpath(OUT, "$MAP_FIGURE.svg"))
        println("wrote $(relpath(path, ROOT))")
    end
    for (notebook, figures) in sort!(collect(NOTEBOOK_FIGURES))
        figures = filter(f -> first(f) in wanted, figures)
        isempty(figures) || export_notebook(notebook, figures)
    end
end

end # module

Lecture05Figures.main(ARGS)
