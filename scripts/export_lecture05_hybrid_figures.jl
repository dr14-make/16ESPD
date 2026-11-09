"""
Writes the Lecture 5 deck's hybrid figures into `slides/decks/lecture-05/public/figures/`.

    julia +dyad-3.5.0 --project=. scripts/export_lecture05_hybrid_figures.jl [figure ...]

Runs each notebook in `FIGURES` from `notebooks/lecture05/` top to bottom and saves the plots
the deck shows as SVG. `01-operating-points.pluto.jl` simulates three WLTC runs, one after the
other; `03-machine-size.pluto.jl` reads the pinned sweep of `scripts/machine_size_sweep.jl` and
simulates nothing. Figure names as arguments (e.g. `03-doh-sweep`) export only those, running
only the notebooks that draw them. Each notebook runs in a module of its own: it assigns the
global `VehicleSystemsComponents`, which would collide with the package `setup()` loads into
`Main`.
"""
module Lecture05HybridFigures

using Plots
import PlotlyBase, PlotlyKaleido
plotly()
include(joinpath(@__DIR__, "plotly_svg.jl"))

const ROOT = normpath(@__DIR__, "..")
const NOTEBOOKS = joinpath(ROOT, "notebooks", "lecture05")
const OUT = joinpath(ROOT, "slides", "decks", "lecture-05", "public", "figures")
const FIGURES = Dict(
    "01-operating-points.pluto.jl" => [
        "05-operating-points" => :comparison_plot,
        "07-three-powertrains" => :three_powertrains_plot,
    ],
    "03-machine-size.pluto.jl" => ["03-doh-sweep" => :doh_plot],
)

function export_notebook(notebook, figures)
    mod = Core.eval(Main, :(module $(Symbol("Notebook_", replace(notebook, r"\W" => "_"))) end))
    Base.include(mod, joinpath(NOTEBOOKS, notebook))
    for (name, plot) in figures
        path = Base.invokelatest(save_svg, Core.eval(mod, plot), joinpath(OUT, "$name.svg"))
        println("wrote $(relpath(path, ROOT))")
    end
end

function main(wanted = String[])
    known = [n for fs in values(FIGURES) for (n, _) in fs]
    wanted = isempty(wanted) ? known : wanted
    unknown = setdiff(wanted, known)
    isempty(unknown) || error("no such figure: $(join(sort!(unknown), ", "))")
    mkpath(OUT)
    for (notebook, figures) in sort!(collect(FIGURES))
        figures = filter(f -> first(f) in wanted, figures)
        isempty(figures) || export_notebook(notebook, figures)
    end
end

end # module

Lecture05HybridFigures.main(ARGS)
