"""
Writes the Lecture 4 deck's real-world context figures into
`slides/decks/lecture-04/public/figures/`, from the tables in `data/ev_context/`.

    julia +dyad-3.5.0 --startup-file=no scripts/export_lecture04_context_figures.jl

These plots show published market and regulatory data, not model results, so they need no
notebook and no Dyad model; `scripts/export_lecture04_figures.jl` runs this file last. Every value
and its source is in `data/ev_context/README.md`.
"""
module Lecture04ContextFigures

using Plots
import PlotlyBase, PlotlyKaleido
plotly()
include(joinpath(@__DIR__, "plotly_svg.jl"))

const ROOT = normpath(@__DIR__, "..")
const DATA = joinpath(ROOT, "data", "ev_context")
const OUT = joinpath(ROOT, "slides", "decks", "lecture-04", "public", "figures")

Plots.default(; left_margin = 7Plots.mm, bottom_margin = 6Plots.mm, top_margin = 3Plots.mm,
    right_margin = 5Plots.mm, titlefontsize = 12, legendfontsize = 11, guidefontsize = 12,
    tickfontsize = 11)

"Rows of a CSV with a header line, as named tuples of strings; `#` lines are comments."
function read_table(name)
    lines = filter(l -> !isempty(strip(l)) && !startswith(l, "#"),
        readlines(joinpath(DATA, name)))
    header = Symbol.(split(lines[1], ','))
    return [NamedTuple{Tuple(header)}(Tuple(strip.(split(l, ',')))) for l in lines[2:end]]
end

num(s) = parse(Float64, s)

function ev_share_plot()
    rows = read_table("ev_sales_share.csv")
    p = plot(; xlabel = "year", ylabel = "electric share of new-car sales [%]",
        size = (960, 640), legend = :topleft, ylims = (0, 60))
    for (k, region) in enumerate(["China", "Europe", "World", "United States"])
        r = filter(x -> x.region == region, rows)
        x, y = num.(getfield.(r, :year)), num.(getfield.(r, :share_pct))
        plot!(p, x, y; label = region, color = k, lw = 3, marker = :circle, ms = 5)
        c = p.series_list[end][:linecolor]
        annotate!(p, x[end] + 0.2, y[end], text("$(round(Int, y[end])) %", 12, :left, c))
    end
    xlims!(p, minimum(num.(getfield.(rows, :year))) - 0.3,
        maximum(num.(getfield.(rows, :year))) + 1.0)
    return p
end

function co2_plot()
    fleet = read_table("eu_new_car_co2.csv")
    targets = read_table("eu_co2_targets.csv")
    p = plot(; xlabel = "year", ylabel = "new cars, average CO₂ [g/km]", size = (960, 640),
        legend = :topright, ylims = (0, 180), xlims = (2009.5, 2038))
    for (k, test) in enumerate(["NEDC", "WLTP"])
        r = filter(x -> x.test == test, fleet)
        plot!(p, num.(getfield.(r, :year)), num.(getfield.(r, :g_per_km));
            label = "fleet average, $test", color = k, lw = 3, marker = :circle, ms = 5)
    end
    for (i, t) in enumerate(targets)
        a, b, g = num(t.from_year), num(t.to_year) + 1, num(t.g_per_km)
        proposal = t.test == "proposal"
        plot!(p, [a, b], [g, g]; color = proposal ? :gray : t.test == "NEDC" ? 1 : 2, lw = 3,
            ls = proposal ? :dot : :dash,
            label = i == 1 ? "EU target, dashed" : proposal ? "proposed, not adopted" : "")
        annotate!(p, proposal ? b : a, g + (proposal ? 10 : 7),
            text(t.label, 11, proposal ? :right : :left, proposal ? :gray : :black))
    end
    annotate!(p, 2019.3, 160, text("test cycle changes, NEDC → WLTP", 11, :left, :gray))
    return p
end

function battery_price_plot()
    rows = read_table("battery_pack_price.csv")
    x, y = num.(getfield.(rows, :year)), num.(getfield.(rows, :usd_per_kwh))
    p = bar(x, y; label = "", legend = :none, color = 1, ylabel = "Li-ion pack price [\$/kWh]",
        xlabel = "year", size = (960, 640), xticks = x[1]:1:x[end])
    annotate!(p, [(xi, yi, text("$(round(Int, yi))", 10, :bottom)) for (xi, yi) in zip(x, y)])
    ylims!(p, 0, 1.12 * maximum(y))
    return p
end

const FIGURES = [
    "01-ev-share" => ev_share_plot,
    "01-eu-co2" => co2_plot,
    "06-battery-price" => battery_price_plot,
]

function export_all()
    mkpath(OUT)
    for (name, make) in FIGURES
        path = joinpath(OUT, "$name.svg")
        save_svg(make(), path)
        println("  $name.svg  $(filesize(path) ÷ 1000) kB")
    end
    PlotlyKaleido.kill_kaleido()
end

end

Lecture04ContextFigures.export_all()
