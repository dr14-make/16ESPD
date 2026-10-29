"""
Writes the Lecture 4 deck's notebook figures into `slides/decks/lecture-04/public/figures/`.

    julia +dyad-3.5.0 --project=. scripts/export_lecture04_figures.jl

Runs `notebooks/lecture04/02-switching.pluto.jl` and `03-energy-bill.pluto.jl` top to bottom
with their controls at their defaults, and saves the plots the deck shows as SVG. Each notebook
runs in a module of its own: it assigns the global `VehicleSystemsComponents`, which would
collide with the package `setup()` loads into `Main`.

The dyad-3.5 kernel ships Plots' plotly backend with Kaleido, not GR, so the figures go through
Kaleido. Plots hands Kaleido no size, and Kaleido then draws every figure at 700 x 500, so the
plot is converted here and its own size passed on. Plotly also simplifies lines at screen
resolution by default, which turns smooth curves into visible polygons; that is switched off.
"""

const ROOT = normpath(@__DIR__, "..")
const NOTEBOOKS = joinpath(ROOT, "notebooks", "lecture04")
const OUT = joinpath(ROOT, "slides", "decks", "lecture-04", "public", "figures")

const FIGURES = Dict(
    "02-switching.pluto.jl" => [
        "05-buck-currents" => :buck_currents_plot,
        "05-buck-losses" => :buck_losses_plot,
        "05-buck-frequency" => :buck_frequency_plot,
        "05-hbridge-square" => :hbridge_square_plot,
        "05-pwm-gates" => :pwm_gates_plot,
        "05-pwm-current" => :pwm_current_plot,
        "05-pwm-spectrum" => :pwm_spectrum_plot,
        "05-pwm-carrier" => :pwm_carrier_plot,
    ],
    "03-energy-bill.pluto.jl" => [
        "08-wltc-tracking" => :tracking_plot,
        "08-energy-bill" => :bill_plot,
        "08-mj-comparison" => :mj_plot,
    ],
)

"Save the plotly-backend plot `p` as SVG at its own size."
function save_svg(Plots, PlotlyKaleido, p, path)
    Plots.prepare_output(p)
    width, height = p[:size]
    figure = Plots.plotlybase_syncplot(p)
    for trace in figure.data
        haskey(trace.fields, :line) && (trace["line.simplify"] = false)
    end
    PlotlyKaleido.is_running() || PlotlyKaleido.restart()
    PlotlyKaleido.savefig(path, figure; width, height, format = "svg")
    filesize(path) > 0 || error("$(basename(path)) was written empty")
    return path
end

mkpath(OUT)
for (notebook, figures) in sort!(collect(FIGURES))
    mod = Core.eval(Main, :(module $(Symbol("Notebook_", replace(notebook, r"\W" => "_"))) end))
    Base.include(mod, joinpath(NOTEBOOKS, notebook))
    Plots = Core.eval(mod, :Plots)
    PlotlyKaleido = Base.loaded_modules[Base.identify_package("PlotlyKaleido")]
    for (name, plot) in figures
        path = joinpath(OUT, "$name.svg")
        Base.invokelatest(save_svg, Plots, PlotlyKaleido, Core.eval(mod, plot), path)
        println("  $name.svg  $(filesize(path) ÷ 1000) kB")
    end
    Base.invokelatest(PlotlyKaleido.kill_kaleido)
end
