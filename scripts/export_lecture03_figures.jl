"""
Writes the Lecture 3 deck's notebook figures into `slides/decks/lecture-03/public/figures/`.

    julia +dyad-3.4.0 --project=. scripts/export_lecture03_figures.jl

Runs `notebooks/lecture03/01-abs.pluto.jl` and `02-brake-hydraulics.pluto.jl` top to bottom with
their sliders at the defaults, and saves the plots the deck shows as SVG. Each notebook runs in a
module of its own: a notebook assigns the global `VehicleSystemsComponents`, which would collide
with the package `setup()` loads into `Main`.
"""

const ROOT = normpath(@__DIR__, "..")
const NOTEBOOKS = joinpath(ROOT, "notebooks", "lecture03")
const OUT = joinpath(ROOT, "slides", "decks", "lecture-03", "public", "figures")

const FIGURES = Dict(
    "01-abs.pluto.jl" => [
        "03-speed-over-distance" => :distance_plot,
        "03-vehicle-and-wheel-speed" => :speed_plot,
        "03-wheel-slip" => :slip_plot,
        "03-brake-torque" => :torque_plot,
        "03-where-on-the-curve" => :friction_plot,
        "03-distance-vs-mu" => :sweep_plot,
    ],
    "02-brake-hydraulics.pluto.jl" => [
        "02-pedal-to-pressure" => :pressure_plot,
    ],
)

mkpath(OUT)
for (notebook, figures) in sort!(collect(FIGURES))
    mod = Core.eval(Main, :(module $(Symbol("Notebook_", replace(notebook, r"\W" => "_"))) end))
    Base.include(mod, joinpath(NOTEBOOKS, notebook))
    for (name, plot) in figures
        path = joinpath(OUT, "$name.svg")
        Core.eval(mod, :(Plots.savefig($plot, $path)))
        filesize(path) > 0 || error("$name.svg was written empty")
        println("  $name.svg")
    end
end
