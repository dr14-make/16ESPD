"""
Writes the Lecture 6 deck's multiplexing figures into `slides/decks/lecture-06/public/figures/`.

    julia +dyad-3.5.0 --project=. scripts/export_lecture06_figures.jl [figure ...]

Each figure runs its `dyad/Lecture6` bench and draws two messages sharing one wire and the
receivers separating them again:

- `01-fdm`: `FrequencyDivisionBenchTransient`, the wire over a tenth of a second, its spectrum
  with one band per carrier, and both messages against the filtered receiver outputs;
- `01-tdm`: `TimeDivisionBenchTransient` and `TimeDivisionDriftTransient`, the wire colored by
  slot, the rebuilt staircases with the receiver clock in step, and with it 2.5 % fast;
- `01-cdm`: `CodeDivisionBenchTransient`, each sender's labeled bits and spread signal, the
  summed wire, and the three receivers' integrate-and-dump outputs, with lines at the bit edges.

With no arguments it writes all three.
"""
module Lecture06Figures

using Plots
import PlotlyBase, PlotlyKaleido
plotly()
include(joinpath(@__DIR__, "plotly_svg.jl"))
import VehicleSystemsComponents
using DyadInterface: symbolic_container

const ROOT = normpath(@__DIR__, "..")
const OUT = joinpath(ROOT, "slides", "decks", "lecture-06", "public", "figures")
const L6 = VehicleSystemsComponents.Lecture6

# Okabe-Ito blue, vermillion and green: apart under every common color-vision deficiency.
const BLUE = "#0072B2"
const VERMILLION = "#D55E00"
const GREEN = "#009E73"
const GRAY = "#555555"

const STYLE = (; grid = true, gridalpha = 0.25, legend = false, left_margin = 10Plots.mm,
    bottom_margin = 7Plots.mm, top_margin = 1Plots.mm, right_margin = 4Plots.mm,
    guidefontsize = 16, tickfontsize = 14, titlefontsize = 17)

"`text` in `color`, for titles that name their curves instead of a legend covering them."
colored(text, color) = "<span style=\"color:$color\">$text</span>"

"The solution's values of `x` on the uniform grid `ts`."
at(run, x, ts) = run.sol(ts; idxs = x).u

"""
One-sided amplitude spectrum of `y` sampled every `dt`, at the frequencies `fs`. A direct sum
rather than an FFT: the record holds a whole number of every period, so each line falls on a bin.
"""
function amplitude_spectrum(y, dt, fs)
    t = (0:length(y)-1) .* dt
    return [2 * abs(sum(y .* cis.(-2π * f .* t))) / length(y) for f in fs]
end

const SPEED = colored("vehicle speed", BLUE)
const ENGINE = colored("engine speed", VERMILLION)

function fdm()
    run = L6.FrequencyDivisionBenchTransient()
    m = symbolic_container(run)
    f_speed, f_engine = 100.0, 300.0

    tw = 0.0:5e-5:0.1
    a = plot(tw .* 1e3, at(run, m.wire.y, tw); color = GRAY, lw = 1.5, xlims = (0, 100),
        xlabel = "time [ms]", ylabel = "wire [–]", title = "One wire carries both messages at once")

    dt = 1 / 2000
    ts = 0.0:dt:(4.0 - dt)
    fs = 0.0:0.25:400.0
    spec = amplitude_spectrum(at(run, m.wire.y, ts), dt, fs)
    b = plot(fs, spec; color = GRAY, lw = 1.5, xlims = (0, 400), ylims = (0, 0.75),
        xlabel = "frequency [Hz]", ylabel = "amplitude [–]", title = "Each message has its own band")
    annotate!(b, f_speed + 8, 0.6, text("vehicle speed on 100 Hz", 14, BLUE, :left))
    annotate!(b, f_engine + 8, 0.45, text("engine speed on 300 Hz", 14, VERMILLION, :left))

    tm = 0.0:0.005:4.0
    c = plot(; xlims = (0, 4), ylims = (0, 1.05), xlabel = "time [s]", ylabel = "signal [–]",
        title = "Each receiver filters its band back out: $SPEED, $ENGINE (dashed: sent)")
    for (msg, rx, color) in ((m.speed.y, m.filter_speed.y, BLUE),
            (m.engine.y, m.filter_engine.y, VERMILLION))
        plot!(c, tm, at(run, msg, tm); color, lw = 2, ls = :dash)
        plot!(c, tm, at(run, rx, tm); color, lw = 3)
    end
    return plot(a, b, c; layout = (3, 1), size = (1280, 760), STYLE...)
end

"`y` where `keep` holds, NaN elsewhere, so one trace draws only its own stretches."
masked(y, keep) = ifelse.(keep, y, NaN)

function tdm()
    run = L6.TimeDivisionBenchTransient()
    drift = L6.TimeDivisionDriftTransient()
    m = symbolic_container(run)

    tw = 0.0:2e-4:1.0
    wire = at(run, m.wire.y, tw)
    speed_slot = at(run, m.tx_clock.y, tw) .> 0
    a = plot(; xlims = (0, 1), ylims = (0, 1.05), xlabel = "time [s]", ylabel = "wire [–]",
        title = "The messages take turns on the wire: $SPEED slot, $ENGINE slot")
    plot!(a, tw, masked(wire, speed_slot); color = BLUE, lw = 2.5)
    plot!(a, tw, masked(wire, .!speed_slot); color = VERMILLION, lw = 2.5)

    tm = 0.0:0.002:4.0
    function staircases(r, title)
        mr = symbolic_container(r)
        p = plot(; xlims = (0, 4), ylims = (0, 1.05), xlabel = "time [s]", ylabel = "signal [–]",
            title)
        for (msg, hold, color) in ((mr.speed.y, mr.hold_speed.y, BLUE),
                (mr.engine.y, mr.hold_engine.y, VERMILLION))
            plot!(p, tm, at(r, msg, tm); color, lw = 2, ls = :dash)
            plot!(p, tm, at(r, hold, tm); color, lw = 2.5)
        end
        return p
    end
    b = staircases(run, "Receiver clock in step: each receiver rebuilds its own message (dashed: sent)")
    c = staircases(drift, "Receiver clock 2.5 % fast: the messages mix, then swap")
    return plot(a, b, c; layout = (3, 1), size = (1280, 760), STYLE...)
end

function cdm()
    run = L6.CodeDivisionBenchTransient()
    m = symbolic_container(run)
    ts = 0.0:0.002:8.0
    xlims = (0, 8.15)
    centers = collect(1.0:8.0) .- 0.5
    bit_lines!(p) = vline!(p, 1:7; color = GRAY, lw = 1, alpha = 0.35)

    function sender(bits, spread, color, name, code)
        p = plot(; xlims, ylims = (-1.5, 1.6), yticks = [-1, 0, 1], ylabel = "$name [–]",
            title = "Sender $name: bits (dashed) × code $code = " * colored("spread signal", color))
        bit_lines!(p)
        plot!(p, ts, at(run, spread, ts); color, lw = 1.5)
        plot!(p, ts, at(run, bits, ts); color = :black, lw = 2.5, ls = :dash)
        for (x, bit) in zip(centers, at(run, bits, centers))
            annotate!(p, x, 1.32, text(bit > 0 ? "1" : "0", 14, :black, :center))
        end
        return p
    end
    a = sender(m.bits_a.y, m.spread_a.y, BLUE, "A", "+ − + −")
    b = sender(m.bits_b.y, m.spread_b.y, VERMILLION, "B", "+ + − −")
    c = plot(; xlims, ylims = (-2.5, 2.5), yticks = [-2, 0, 2], ylabel = "wire [–]",
        title = "The wire: A + B, both at once, looks like noise")
    bit_lines!(c)
    plot!(c, ts, at(run, m.wire.y, ts); color = GRAY, lw = 1.5)

    # The integrate-and-dump output just before each bit's end is that bit's average.
    ends = collect(1.0:8.0) .- 0.011
    d = plot(; xlims, ylims = (-1.5, 1.5), yticks = [-1, 0, 1], xlabel = "time [bit periods]",
        ylabel = "sum ÷ 4 [–]",
        title = "Running sum of wire × code ÷ 4, restarts each bit; dot = decoded bit: " *
            join((colored("● A", BLUE), colored("■ B", VERMILLION),
                colored("◆ C = + − − +, nobody sent it", GREEN)), ", "))
    bit_lines!(d)
    # A and B often send the same bit; side by side, neither marker hides the other.
    for (rx, color, shape, dx) in ((m.receiver_a, BLUE, :circle, -0.08),
            (m.receiver_b, VERMILLION, :rect, 0.08), (m.receiver_c, GREEN, :diamond, 0.0))
        plot!(d, ts, at(run, rx.correlation, ts); color, lw = 1.5, alpha = 0.6)
        scatter!(d, ends .+ dx, at(run, rx.correlation, ends); color, markersize = 9,
            markershape = shape, markerstrokewidth = 0)
    end
    return plot(a, b, c, d; layout = (4, 1), size = (1280, 760), STYLE..., bottom_margin = 3Plots.mm)
end

const FIGURES = Dict("01-fdm" => fdm, "01-tdm" => tdm, "01-cdm" => cdm)

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

Lecture06Figures.main(ARGS)
