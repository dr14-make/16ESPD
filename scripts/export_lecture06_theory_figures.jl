"""
Writes the Lecture 6 deck's theory figures into `slides/decks/lecture-06/public/figures/`.

    julia +dyad-3.5.0 --project=. scripts/export_lecture06_theory_figures.jl [figure ...]

Each figure is computed from a closed-form formula on its slide, with no Dyad model and no
notebook. Figure names as arguments (e.g. `08-phase-lag`) export only those.

- `04-bus-length`: the longest bus at which a bit's round trip still reaches the sample point.
- `05-frame-time`: the worst-case length of a classic base data frame against its data bytes.
- `08-phase-lag`: the phase a pure delay costs a sinusoid, against its frequency.
"""
module Lecture06TheoryFigures

using Plots
import PlotlyBase, PlotlyKaleido
plotly()
include(joinpath(@__DIR__, "plotly_svg.jl"))

const ROOT = normpath(@__DIR__, "..")
const OUT = joinpath(ROOT, "slides", "decks", "lecture-06", "public", "figures")

# Okabe–Ito: distinguishable under the common color-vision deficiencies.
const COLORS = ["#0072B2", "#E69F00", "#009E73", "#CC79A7"]

# Sized to read on a projected slide with the figure in half the slide's width.
Plots.default(; left_margin = 8Plots.mm, bottom_margin = 6Plots.mm, top_margin = 3Plots.mm,
    right_margin = 5Plots.mm, guidefontsize = 20, tickfontsize = 18, legendfontsize = 18,
    grid = true, gridalpha = 0.25)

# Bus length: a dominant edge from one end must reach the far end and the far node's own
# dominant bit must travel back before the sender samples. The electronics in that loop are two
# transceiver loop delays (TX driver + RX comparator, ≈ 150 ns each, typical datasheet value)
# and the two controllers (≈ 25 ns each).
const NS_PER_M = 5.0
const LOOP_NS = 2 * 150.0 + 2 * 25.0

"Longest bus [m] at `bitrate` [bit/s] with the sample point at fraction `sp` of the bit."
max_length(bitrate, sp) = max(0.0, (sp * 1e9 / bitrate - LOOP_NS) / (2 * NS_PER_M))

const RULE_OF_THUMB = [1e6 => 40, 500e3 => 100, 250e3 => 250, 125e3 => 500]

function bus_length_plot()
    rates = exp10.(range(5, 6; length = 200))
    kbit = rates ./ 1e3
    early, late = max_length.(rates, 0.75), max_length.(rates, 0.875)
    p = plot(; size = (900, 620), xscale = :log10, yscale = :log10,
        xlabel = "bit rate [kbit/s]", ylabel = "longest bus [m]", legend = :topright,
        xticks = ([100, 125, 250, 500, 1000], ["100", "125", "250", "500", "1000"]),
        yticks = ([20, 50, 100, 200, 500, 1000], ["20", "50", "100", "200", "500", "1000"]),
        xlims = (100, 1000), ylims = (20, 1000))
    plot!(p, kbit, late; fillrange = early, fillalpha = 0.25, color = COLORS[1], lw = 0,
        label = "")
    plot!(p, kbit, late; color = COLORS[1], lw = 3, label = "sample point 87.5 %")
    plot!(p, kbit, early; color = COLORS[1], lw = 3, ls = :dash, label = "sample point 75 %")
    scatter!(p, first.(RULE_OF_THUMB) ./ 1e3, last.(RULE_OF_THUMB); color = COLORS[2],
        markersize = 10, markerstrokecolor = :black, label = "rule of thumb")
    return p
end

# Classic base data frame with n data bytes: 47 fixed bits plus the data; stuffing can add one
# bit per four after the first over the 34 + 8n stuffed bits (SOF to the end of the CRC).
frame_bits(n) = 8n + 47
worst_frame_bits(n) = 8n + 47 + fld(34 + 8n - 1, 4)

const BITRATES = [125e3 => "125 kbit/s", 250e3 => "250 kbit/s", 500e3 => "500 kbit/s",
    1e6 => "1 Mbit/s"]

function frame_time_plot()
    n = 0:8
    p = plot(; size = (900, 620), xlabel = "data bytes", ylabel = "worst-case frame time [µs]",
        legend = :topleft, xticks = 0:8, xlims = (-0.3, 8.6), ylims = (0, 1150))
    for (k, (rate, label)) in enumerate(BITRATES)
        t = worst_frame_bits.(n) ./ rate .* 1e6
        plot!(p, n, t; color = COLORS[k], lw = 3, marker = :circle, markersize = 6,
            markerstrokewidth = 0, label)
        annotate!(p, 8.15, t[end], text("$(round(Int, t[end]))", 16, :left, COLORS[k]))
    end
    return p
end

const DELAYS_MS = [5, 10, 20, 40]

function phase_lag_plot()
    f = range(0, 10; length = 201)
    p = plot(; size = (900, 620), xlabel = "frequency [Hz]", ylabel = "phase lag [°]",
        legend = :topleft, xlims = (0, 10.9), ylims = (0, 150), xticks = 0:2:10, yticks = 0:30:150)
    for (k, tau) in enumerate(DELAYS_MS)
        phi = 360 .* f .* tau ./ 1e3
        plot!(p, f, phi; color = COLORS[k], lw = 3, label = "τ = $tau ms")
        annotate!(p, 10.1, phi[end], text("$(round(Int, phi[end]))°", 16, :left, COLORS[k]))
    end
    return p
end

const FIGURES = Dict("04-bus-length" => bus_length_plot, "05-frame-time" => frame_time_plot,
    "08-phase-lag" => phase_lag_plot)

function main(wanted = String[])
    wanted = isempty(wanted) ? sort!(collect(keys(FIGURES))) : wanted
    unknown = setdiff(wanted, keys(FIGURES))
    isempty(unknown) || error("no such figure: $(join(sort!(unknown), ", "))")
    mkpath(OUT)
    for name in wanted
        path = save_svg(FIGURES[name](), joinpath(OUT, "$name.svg"))
        println("wrote $(relpath(path, ROOT))")
    end
end

end # module

Lecture06TheoryFigures.main(ARGS)
