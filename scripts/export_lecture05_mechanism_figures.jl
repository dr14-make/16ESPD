"""
Writes the Lecture 5 deck's CVT, K0 and SoC-window figures into
`slides/decks/lecture-05/public/figures/`.

    julia +dyad-3.5.0 --project=. scripts/export_lecture05_mechanism_figures.jl [figure ...]

With no arguments it writes the figures computed from the models' parameters, with no
simulation:

- `04-cvt-ratio-map`: engine speed against wheel speed, the reachable wedge between the CVT's
  `i_launch` and `i_overdrive`, and the pedal schedule's 1800 and 6000 rpm targets
  (`Vehicle.P2Variator`);
- `04-k0-clutch`: K0's actuator step response and its slip law, `tau_max · tanh(w_slip /
  w_regularization)` (`Vehicle.DisconnectClutch`);
- `05-cvt-band`: the BSFC map of `notebooks/lecture05/bsfc_map.jl` with the engine speeds the
  CVT can reach at 90 km/h on the course car's 0.31 m wheel, and the two 10 kW points of the
  `cvt-on-the-line` slide.

`06-soc-window` is written only when named: it simulates `Lecture5.P2HybridWLTCTransient` and
draws the battery's SoC over the WLTC against the manager's charge latch.
"""
module Lecture05MechanismFigures

using Plots, Printf
import PlotlyBase, PlotlyKaleido
plotly()
include(joinpath(@__DIR__, "plotly_svg.jl"))
const NOTEBOOKS = normpath(@__DIR__, "..", "notebooks", "lecture05")
include(joinpath(NOTEBOOKS, "operating_points.jl"))
include(joinpath(NOTEBOOKS, "bsfc_map.jl"))
using .BsfcMap: bsfc_map_plot, LINE_COLOR
using .OperatingPoints.BsfcLine: load_maps, bsfc_at, torque_for, RPM_MAX

const ROOT = normpath(@__DIR__, "..")
const OUT = joinpath(ROOT, "slides", "decks", "lecture-05", "public", "figures")

# Vehicle.P2Variator
const I_LAUNCH = 12.0
const I_OVERDRIVE = 2.8
const TARGET_RPM = (1800.0, 6000.0)
# Vehicle.DisconnectClutch
const K0_TIME = 0.15
const K0_TAU_MAX = 230.0
const K0_W_REG = 0.5
# Vehicle.Planar.RoadCar and the Lecture 5 test models
const WHEEL_RADIUS = 0.31
# Lecture5.P2HybridWLTC's manager
const SOC_ON, SOC_OFF = 0.52, 0.55

const ORANGE = "#a75d00"
const GREEN = "#2e8b57"

const FONTS = (; left_margin = 8Plots.mm, bottom_margin = 6Plots.mm, top_margin = 2Plots.mm,
    right_margin = 4Plots.mm, guidefontsize = 19, tickfontsize = 17, legendfontsize = 17,
    titlefontsize = 19)

rpm_of(v_kmh) = v_kmh / 3.6 / WHEEL_RADIUS * 60 / 2π

function cvt_ratio_map()
    w_max = RPM_MAX / I_OVERDRIVE
    p = plot(; size = (1280, 520), xlims = (0, 2500), ylims = (0, 7000),
        xlabel = "wheel speed ω<sub>w</sub> [rpm]", ylabel = "engine speed ω<sub>e</sub> [rpm]",
        legend = :bottomright, grid = true, gridalpha = 0.25, FONTS...)
    ws = range(0, w_max; length = 400)
    plot!(p, ws, min.(I_LAUNCH .* ws, RPM_MAX); fillrange = I_OVERDRIVE .* ws,
        fillcolor = LINE_COLOR, fillalpha = 0.15, color = LINE_COLOR, lw = 2, label = "")
    plot!(p, ws, I_OVERDRIVE .* ws; color = LINE_COLOR, lw = 2, label = "")
    annotate!(p, RPM_MAX / I_LAUNCH + 40, 6750,
        text(@sprintf("i = %.1f (launch)", I_LAUNCH), 17, LINE_COLOR, :center))
    annotate!(p, w_max - 20, 6750, text(@sprintf("i = %.1f (top)", I_OVERDRIVE), 17, LINE_COLOR,
        :right))
    annotate!(p, 1000, 4600, text("any ratio in this range", 19, LINE_COLOR, :center))
    annotate!(p, 1750, 2500, text("not reachable: i < 2.8", 17, :gray, :center))
    for (target, color, name) in zip(TARGET_RPM, (GREEN, ORANGE), ("pedal up", "pedal down"))
        w_lock, w_end = target / I_LAUNCH, target / I_OVERDRIVE
        plot!(p, [0, w_lock], [target, target]; color, lw = 3, ls = :dash, label = "")
        ws = range(w_lock, w_max; length = 200)
        plot!(p, ws, clamp.(target, I_OVERDRIVE .* ws, I_LAUNCH .* ws); color, lw = 3.5,
            label = @sprintf("%s: %.0f rpm target", name, target))
        scatter!(p, [w_end], [target]; color, markersize = 8, markerstrokewidth = 0, label = "")
    end
    plot!(p, [-200, -100], [0, 0]; color = :gray, lw = 3, ls = :dash,
        label = "left of i = 12: only with the clutch slipping")
    annotate!(p, 1450, 3500, text("ratio at its limit:<br>the engine leaves its target", 16,
        :black, :left))
    return p
end

function k0_clutch()
    t = range(0, 1.0; length = 400)
    x = 1 .- exp.(-t ./ K0_TIME)
    t90 = K0_TIME * log(10)
    a = plot(t, x; color = LINE_COLOR, lw = 3.5, label = "", xlims = (0, 1.0), ylims = (0, 1.05),
        xlabel = "time after the close command [s]", ylabel = "actuator position [–]")
    hline!(a, [0.9]; color = :gray, ls = :dot, lw = 1.5, label = "")
    plot!(a, [t90, t90], [0, 0.9]; color = :gray, ls = :dot, lw = 1.5, label = "")
    scatter!(a, [t90], [0.9]; color = ORANGE, markersize = 8, markerstrokewidth = 0, label = "")
    annotate!(a, t90 + 0.04, 0.78, text(@sprintf("90 %% at %.2f s", t90), 17, ORANGE, :left))
    annotate!(a, 0.55, 0.45, text(@sprintf("τ = %.2f s", K0_TIME), 17, LINE_COLOR, :left))

    w = range(-3, 3; length = 400)
    tau = K0_TAU_MAX .* tanh.(w ./ K0_W_REG)
    b = plot(w, tau; color = GREEN, lw = 3.5, label = "", xlims = (-3, 3), ylims = (-260, 260),
        xlabel = "slip ω<sub>a</sub> − ω<sub>b</sub> [rad/s]", ylabel = "friction torque [N·m]")
    hline!(b, [-K0_TAU_MAX, K0_TAU_MAX]; color = :gray, ls = :dot, lw = 1.5, label = "")
    full = K0_TAU_MAX * tanh(1 / K0_W_REG)
    scatter!(b, [1.0], [full]; color = ORANGE, markersize = 8, markerstrokewidth = 0, label = "")
    annotate!(b, 1.15, 150, text(@sprintf("1 rad/s: %.0f %%", 100 * full / K0_TAU_MAX), 17,
        ORANGE, :left))
    annotate!(b, -2.9, 205, text("± 230 N·m, fully closed", 17, :gray, :left))
    return plot(a, b; layout = (1, 2), size = (1280, 440), legend = false, grid = true,
        gridalpha = 0.25, FONTS..., left_margin = 10Plots.mm)
end

function cvt_band(; v_kmh = 90.0, P_kw = 10.0, n_schedule = 2182.0, n_line = 1420.0)
    m = load_maps()
    w = rpm_of(v_kmh)
    lo, hi = I_OVERDRIVE * w, min(I_LAUNCH * w, RPM_MAX)
    p = bsfc_map_plot(; title = "")
    # A smaller canvas than the deck's full-width map: shown in half a slide, its text must grow.
    plot!(p; size = (960, 560), legend = false, top_margin = 4Plots.mm)
    plot!(p, [lo, hi], [160, 160]; fillrange = 0, fillcolor = GREEN, fillalpha = 0.12,
        linewidth = 0, label = @sprintf("CVT at %.0f km/h: i ≤ 2.8, %.0f rpm and up", v_kmh, lo))
    plot!(p, [lo, lo], [0, 160]; color = GREEN, lw = 2.5, ls = :dash, label = "")
    ns = range(900, 4000; length = 300)
    plot!(p, ns, torque_for.(P_kw, ns); color = :gray, ls = :dot, lw = 2, label = "")
    for (n, color, name) in [(n_schedule, ORANGE, "CVT schedule"), (n_line, LINE_COLOR, "line")]
        T = torque_for(P_kw, n)
        b = bsfc_at(m, n, T).bsfc
        scatter!(p, [n], [T]; color, markersize = 12, markerstrokecolor = :white,
            markerstrokewidth = 2, label = @sprintf("%s, %.0f kW: %.0f rpm, %.0f g/kWh", name, P_kw, n, b))
        @printf("%s: %.0f kW at %.0f rpm, %.1f N·m, %.1f g/kWh, i = %.2f\n", name, P_kw, n, T, b,
            n / w)
    end
    @printf("%.0f km/h on r = %.2f m: wheel %.1f rpm, i = %.1f gives %.0f rpm\n", v_kmh,
        WHEEL_RADIUS, w, I_OVERDRIVE, lo)
    return p
end

soc_window() = soc_plot(soc_data())

"SoC and charge latch of the P2 hybrid's WLTC run, every 0.5 s."
function soc_data()
    Base.include(Main, joinpath(ROOT, "notebooks", "lecture01", "support.jl"))
    pkg = Base.invokelatest(Main.Lecture01Support.setup; backend = :plotly)
    run = Base.invokelatest(() -> pkg.Lecture5.P2HybridWLTCTransient())
    return Base.invokelatest() do
        sym = Main.DyadInterface.symbolic_container(run)
        t = collect(0.0:0.5:last(run.sol.t))
        (; t, soc = run.sol(t; idxs = sym.powertrain.SoC).u,
            charge = run.sol(t; idxs = sym.manager.charge.y).u)
    end
end

function soc_plot(d)
    (; t, soc, charge) = d
    on = charge .> 0.5
    @printf("SoC over WLTC: %.3f to %.3f, start %.3f, end %.3f; %s\n",
        minimum(soc), maximum(soc), first(soc), last(soc),
        @sprintf("charging %.0f %% of the time, %d times", 100 * count(on) / length(t),
            length(runs(on))))
    lo, hi = minimum(soc) - 0.01, maximum(soc) + 0.05
    a = plot(; xlims = (0, last(t)), ylims = (lo, hi), xlabel = "WLTC time [s]",
        ylabel = "state of charge [–]", legend = :topleft)
    hline!(a, [SOC_ON]; color = ORANGE, ls = :dash, lw = 2, label = "SoC<sub>on</sub>")
    hline!(a, [SOC_OFF]; color = GREEN, ls = :dash, lw = 2, label = "SoC<sub>off</sub>")
    plot!(a, t, soc; color = LINE_COLOR, lw = 2.5, label = "SoC")
    # Line segments rather than filled areas: plotly chains successive fills to each other.
    for (k, r) in enumerate(runs(on))
        plot!(a, t[[first(r), last(r)]], fill(lo + 0.004, 2); color = ORANGE, lw = 10,
            label = k == 1 ? "latch on: the engine charges" : "")
    end
    b = plot(soc, charge; color = LINE_COLOR, lw = 2, label = "", legend = false,
        xlims = (lo, maximum(soc) + 0.01), ylims = (-0.1, 1.15), xlabel = "state of charge [–]",
        ylabel = "charge latch [–]")
    vline!(b, [SOC_ON]; color = ORANGE, ls = :dash, lw = 2, label = "")
    vline!(b, [SOC_OFF]; color = GREEN, ls = :dash, lw = 2, label = "")
    return plot(a, b; layout = Plots.grid(1, 2; widths = [0.66, 0.34]), size = (1280, 440),
        grid = true, gridalpha = 0.25, FONTS..., left_margin = 10Plots.mm)
end

"Index ranges of the `true` stretches of `mask`."
function runs(mask)
    out = UnitRange{Int}[]
    i = 1
    while i <= length(mask)
        mask[i] || (i += 1; continue)
        j = something(findnext(!, mask, i), length(mask) + 1) - 1
        push!(out, i:j)
        i = j + 1
    end
    return out
end

const FIGURES = Dict("04-cvt-ratio-map" => cvt_ratio_map, "04-k0-clutch" => k0_clutch,
    "05-cvt-band" => cvt_band, "06-soc-window" => soc_window)
const DEFAULT = ["04-cvt-ratio-map", "04-k0-clutch", "05-cvt-band"]

function main(wanted = String[])
    wanted = isempty(wanted) ? DEFAULT : wanted
    unknown = setdiff(wanted, keys(FIGURES))
    isempty(unknown) || error("no such figure: $(join(sort!(unknown), ", "))")
    mkpath(OUT)
    for name in wanted
        p = Base.invokelatest(FIGURES[name])
        path = Base.invokelatest(save_svg, p, joinpath(OUT, "$name.svg"))
        println("wrote $(relpath(path, ROOT))")
    end
end

end # module

Lecture05MechanismFigures.main(ARGS)
