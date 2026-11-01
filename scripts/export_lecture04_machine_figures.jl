"""
Writes the Lecture 4 deck's machine-theory figures into
`slides/decks/lecture-04/public/figures/`.

    julia +dyad-3.5.0 --project=. scripts/export_lecture04_machine_figures.jl

`03-bldc-pmsm-waveforms`: over one electrical revolution, for a trapezoidal (BLDC) and a
sinusoidal (PMSM) machine, the three back-EMFs, the currents the drive puts in, and the torque
Σ e·i / ω. The waveforms are the textbook ideal shapes, in per unit of their peak. The one computed
curve is the BLDC's torque with winding inductance: a six-step inverter at a fixed average voltage.

`04-what-envelope`: a schematic torque–speed envelope at the course machine's corner, with the
reachable region, a few operating points and the power.

`03-field-weakening`: the current and voltage limits of a PMSM in the i_d–i_q plane at several
speeds, and the torque and power along the limits, for an illustrative per-unit machine.

All are computed here, with no Dyad model; `scripts/export_lecture04_figures.jl` runs this file
after the notebooks.
"""
module Lecture04MachineFigures

using Plots
import PlotlyBase, PlotlyKaleido
plotly()
include(joinpath(@__DIR__, "plotly_svg.jl"))

const ROOT = normpath(@__DIR__, "..")
const OUT = joinpath(ROOT, "slides", "decks", "lecture-04", "public", "figures")

# The phase colors of the FocMachine animation on the next slide.
const PHASE_COLORS = ["#1f5fa8", "#a75d00", "#2e8b57"]
const PHASE_NAMES = ["A", "B", "C"]

Plots.default(; left_margin = 6Plots.mm, bottom_margin = 3Plots.mm, top_margin = 2Plots.mm,
    right_margin = 3Plots.mm, titlefontsize = 16, guidefontsize = 15, tickfontsize = 13)

"Trapezoidal back-EMF of phase A in per unit: flat at ±1 for 120°, linear between, at angle `θ` [°]."
function trapezoid(θ)
    θ = mod(θ, 360)
    θ < 30 ? θ / 30 :
    θ <= 150 ? 1.0 :
    θ < 210 ? (180 - θ) / 30 :
    θ <= 330 ? -1.0 : (θ - 360) / 30
end

"The current block of phase A: +1 under its positive flat top, −1 under its negative one."
block(θ) = (θ = mod(θ, 360); 30 < θ < 150 ? 1.0 : 210 < θ < 330 ? -1.0 : 0.0)

# The six 60° steps, from 30° on: (phase switched to the + rail, phase switched to the − rail).
const STEPS = [(1, 2), (1, 3), (2, 3), (2, 1), (3, 1), (3, 2)]
step_at(θ) = STEPS[floor(Int, mod(θ - 30, 360) / 60)+1]

"""
    six_step_torque(; E, R, L, d, dθ, turns)

Simulate a star-connected trapezoidal machine at constant speed on a six-step inverter, with the
pack voltage 1 and the high-side switch at average voltage `d`; resistance `R` and inductance `L`
per phase, `L` in per unit of voltage per (current per electrical degree), so `L/R` is the
winding's time constant in electrical degrees. An outgoing phase keeps conducting through its
freewheeling diode, clamped to the opposite rail, until its current reaches zero. Returns the
angles and Σ e·i over the last of `turns` revolutions, in per unit of 2·E·I with I the
current between commutations.
"""
function six_step_torque(; E = 0.4, R = 0.05, L = 0.4, d = 0.9, dθ = 0.002, turns = 3)
    i = zeros(3)
    I = (d - 2E) / 2R
    θs, P = Float64[], Float64[]
    for θ in 0:dθ:360turns
        e = E .* trapezoid.(θ .- (0, 120, 240))
        hi, lo = step_at(θ)
        v = zeros(3)
        on = falses(3)
        for k in 1:3
            if k == hi
                v[k], on[k] = d, true
            elseif k == lo
                v[k], on[k] = 0.0, true
            elseif i[k] != 0
                v[k], on[k] = i[k] > 0 ? 0.0 : 1.0, true
            end
        end
        vn = sum((v[k] - e[k] - R * i[k]) for k in 1:3 if on[k]) / count(on)
        if θ >= 360(turns - 1)
            push!(θs, θ - 360(turns - 1))
            push!(P, sum(e .* i) / (2E * I))
        end
        for k in 1:3
            on[k] || continue
            di = (v[k] - e[k] - R * i[k] - vn) / L * dθ
            freewheeling = k != hi && k != lo
            i[k] = freewheeling && sign(i[k] + di) != sign(i[k]) ? 0.0 : i[k] + di
        end
    end
    return θs, P
end

"Keep a point where the curve has moved by `tol` or the angle by `step` since the last one kept."
function thin(θ, y; tol = 0.003, step = 1.0)
    keep = [1]
    for n in 2:length(θ)
        (abs(y[n] - y[keep[end]]) > tol || θ[n] - θ[keep[end]] >= step || n == length(θ)) &&
            push!(keep, n)
    end
    return θ[keep], y[keep]
end

function waveform_plot()
    # Every corner and jump of the trapezoids and blocks sits on a multiple of 30°.
    corners = sort!([0.0; 360.0; [30k + s for k in 1:11 for s in (-1e-6, 1e-6)]])
    θ = 0:1.0:360
    p = plot(; layout = grid(3, 2; heights = [0.36, 0.36, 0.28]), size = (1280, 620),
        legend = false, link = :x, xlims = (0, 360), xticks = 0:60:360)
    for k in 1:3
        shift, c = 120(k - 1), PHASE_COLORS[k]
        plot!(p[1], corners, trapezoid.(corners .- shift); color = c, lw = 3)
        plot!(p[3], corners, block.(corners .- shift); color = c, lw = 3)
        plot!(p[2], θ, sind.(θ .- shift); color = c, lw = 3)
        plot!(p[4], θ, sind.(θ .- shift); color = c, lw = 3)
        annotate!(p[1], mod(90 + shift, 360), 1.32, text(PHASE_NAMES[k], 15, :center, c))
        annotate!(p[2], mod(90 + shift, 360), 1.32, text(PHASE_NAMES[k], 15, :center, c))
    end
    for sp in (1, 3, 5)
        vline!(p[sp], 30:60:330; color = :gray, ls = :dot, lw = 1.5)
    end
    for (j, (hi, lo)) in enumerate(STEPS)
        label = "$(PHASE_NAMES[hi])+ $(PHASE_NAMES[lo])−"
        if j == 6
            annotate!(p[3], 6, 1.32, text("…$(PHASE_NAMES[lo])−", 12, :left, :black))
            annotate!(p[3], 345, 1.32, text("$(PHASE_NAMES[hi])+…", 12, :center, :black))
        else
            annotate!(p[3], 60j, 1.32, text(label, 13, :center, :black))
        end
    end
    plot!(p[1]; ylims = (-1.25, 1.55), yticks = [-1, 0, 1], ylabel = "back-EMF e",
        title = "BLDC: trapezoidal back-EMF, 120° current blocks")
    plot!(p[2]; ylims = (-1.25, 1.55), yticks = [-1, 0, 1],
        title = "PMSM: sinusoidal back-EMF, sine currents")
    plot!(p[3]; ylims = (-1.25, 1.55), yticks = [-1, 0, 1], ylabel = "current i")
    plot!(p[4]; ylims = (-1.25, 1.55), yticks = [-1, 0, 1])

    θs, P = thin(six_step_torque()...)
    plot!(p[5], [0, 360], [1, 1]; color = :gray, lw = 2.5, ls = :dash)
    plot!(p[5], θs, P; color = :black, lw = 2.5, ylims = (0, 1.3), yticks = [0, 0.5, 1],
        ylabel = "torque Σe·i/ω")
    annotate!(p[5], 4, 0.18, text("dashed: ideal blocks; solid: with winding inductance",
        13, :left, :black))
    plot!(p[6], [0, 360], [1, 1]; color = :black, lw = 2.5, ylims = (0, 1.3),
        yticks = [0, 0.5, 1])
    annotate!(p[6], 4, 0.18, text("three sin² 120° apart add up to a constant",
        13, :left, :black))
    xlabel!(p[5], "rotor angle [electrical degrees]")
    xlabel!(p[6], "rotor angle [electrical degrees]")
    return p
end

# Illustrative per-unit PMSM with L_d = L_q, so no reluctance torque, as in the course model.
# ψ/L just above I_max: the power stays near level over the speed range, with a finite top speed
# ψ / (ψ − L·I_max) times base speed. Base
# speed is 1: the voltage limit is set so the voltage circle there passes through (0, I_max).
const ψ_PM, L_S, I_MAX = 1.0, 0.9, 1.0
const V_MAX = hypot(ψ_PM, L_S * I_MAX)
const FW_SPEEDS = [1.0 => "#1f5fa8", 1.5 => "#a75d00", 2.5 => "#2e8b57", 4.0 => "#7b3fa0"]
const CURRENT_RED = "#c0392b"

"""
The current that gives the most torque at speed `ω` within both limits, resistance neglected:
i_q = I_max below base speed, else the upper crossing of the current and voltage circles.
"""
function operating_point(ω)
    r2 = (V_MAX / ω)^2
    i_d = min(0.0, (r2 - ψ_PM^2 - (L_S * I_MAX)^2) / (2ψ_PM * L_S))
    return i_d, sqrt(max(I_MAX^2 - i_d^2, 0.0))
end

function field_weakening_plot()
    p = plot(; layout = grid(1, 2; widths = [0.6, 0.4]), size = (1280, 480), legend = false)
    a = 0:0.5:360
    plot!(p[1], I_MAX .* cosd.(a), I_MAX .* sind.(a); color = :black, lw = 2.5)
    annotate!(p[1], 0.5, 1.0, text("current limit", 13, :left, :black))
    c = -ψ_PM / L_S
    for (ω, col) in FW_SPEEDS
        r = V_MAX / (ω * L_S)
        plot!(p[1], c .+ r .* cosd.(a), r .* sind.(a); color = col, lw = 2.5)
        label = ω == 1 ? "voltage limit, base speed" : "$(isinteger(ω) ? Int(ω) : ω)× base"
        annotate!(p[1], c + r * cosd(125) - 0.04, r * sind(125) + 0.04,
            text(label, 13, :right, col))
        i_d, i_q = operating_point(ω)
        scatter!(p[1], [i_d], [i_q]; color = col, ms = 9, markerstrokewidth = 0)
    end
    arc = range(0, operating_point(6.0)[1]; length = 200)
    plot!(p[1], arc, sqrt.(I_MAX^2 .- arc .^ 2); color = CURRENT_RED, lw = 5)
    i_d, i_q = operating_point(2.5)
    plot!(p[1], [0, i_d], [0, i_q]; color = CURRENT_RED, lw = 3, arrow = true)
    annotate!(p[1], i_d / 2 + 0.06, i_q / 2 - 0.06, text("i", 16, :left, CURRENT_RED))
    scatter!(p[1], [c], [0]; color = :black, ms = 6, marker = :x)
    annotate!(p[1], c + 0.05, -0.13, text("−ψ<sub>PM</sub> / L<sub>d</sub>", 13, :right, :black))
    plot!(p[1]; xlims = (-2.95, 1.25), ylims = (-0.25, 1.75), aspect_ratio = :equal,
        xlabel = "i<sub>d</sub> / I<sub>max</sub>   (negative: against the magnets)",
        ylabel = "i<sub>q</sub> / I<sub>max</sub>",
        xticks = -2.5:0.5:1, yticks = 0:0.5:1.5,
        title = "Current and voltage limits, illustrative per-unit PMSM")

    ω = range(0.02, 5; length = 500)
    T = [operating_point(w)[2] for w in ω]
    plot!(p[2], ω, 1 ./ ω; color = :gray, ls = :dot, lw = 1.5)
    plot!(p[2], ω, T; color = :black, lw = 3)
    plot!(p[2], ω, ω .* T; color = :black, lw = 3, ls = :dash)
    vline!(p[2], [1]; color = :gray, ls = :dash, lw = 1.5)
    for (w, col) in FW_SPEEDS
        t = operating_point(w)[2]
        scatter!(p[2], [w, w], [t, w * t]; color = col, ms = 8, markerstrokewidth = 0)
    end
    annotate!(p[2], 4.9, 0.48, text("torque ∝ i<sub>q</sub>", 13, :right, :black))
    annotate!(p[2], 3.0, 1.46, text("power ∝ ω·i<sub>q</sub>", 13, :center, :black))
    annotate!(p[2], 4.9, 0.12, text("1/ω", 12, :right, :gray))
    annotate!(p[2], 1.08, 0.08, text("base speed", 12, :left, :gray))
    plot!(p[2]; xlims = (0, 5), ylims = (0, 1.55), xticks = 0:1:5, yticks = 0:0.5:1.5,
        xlabel = "speed ω / base speed", ylabel = "per unit of the base-speed value",
        title = "Torque and power at the limits")
    return p
end

# The corner and the top speed of the course machine's envelope, as notebook 01 computes them for
# `04-envelope` and the base-speed slide states them; the schematic leaves out the shaft losses.
const T_RATED, N_BASE, N_MAX = 320.0, 3283.0, 10100.0

function envelope_schematic_plot()
    n = collect(range(0, N_MAX; length = 400))
    T = [x <= N_BASE ? T_RATED : T_RATED * N_BASE / x for x in n]
    P = T .* n .* (π / 30) ./ 1e3
    p = plot(; layout = grid(2, 1; heights = [0.72, 0.28]), size = (1280, 600), legend = false,
        link = :x, xlims = (0, 10600), xticks = 0:2000:10000)
    for sp in (1, 2)
        vline!(p[sp], [N_BASE]; color = :gray, ls = :dash, lw = 1.5)
        vline!(p[sp], [N_MAX]; color = :gray, ls = :dot, lw = 1.5)
    end
    plot!(p[1], Shape([n; N_MAX; 0], [T; 0; 0]); color = "#1f5fa8", fillalpha = 0.12,
        linealpha = 0)
    plot!(p[1], n, T; color = :black, lw = 3.5, ylims = (0, 400), yticks = 0:100:400,
        ylabel = "torque [N·m]")
    scatter!(p[1], [N_BASE], [T_RATED]; color = :black, ms = 9)
    annotate!(p[1], N_BASE + 120, T_RATED + 22,
        text("base speed: $(round(Int, N_BASE)) rpm, $(round(Int, T_RATED)) N·m", 13, :left, :black))
    annotate!(p[1], N_BASE / 2, 375, text("constant torque", 15, :center, "#1f5fa8"))
    annotate!(p[1], N_BASE / 2, 350, text("current limit", 13, :center, "#1f5fa8"))
    annotate!(p[1], (N_BASE + N_MAX) / 2 + 300, 375,
        text("constant power, torque ∝ 1/ω", 15, :center, "#a75d00"))
    annotate!(p[1], (N_BASE + N_MAX) / 2 + 300, 350,
        text("voltage limit: field weakening", 13, :center, "#a75d00"))
    annotate!(p[1], N_MAX - 80, 300, text("max speed", 12, :right, :gray))
    annotate!(p[1], 900, 205, text("reachable", 15, :left, "#1f5fa8"))
    # A few operating points inside the envelope and one outside it, placed by hand.
    pts = [(600, 260), (1200, 140), (1800, 60), (2600, 210), (3500, 40), (4300, 110),
        (5200, 70), (6200, 30), (7000, 120), (8200, 55)]
    scatter!(p[1], first.(pts), last.(pts); color = "#2e8b57", ms = 8, markerstrokewidth = 0)
    annotate!(p[1], 4400, 160, text("operating points", 13, :left, "#2e8b57"))
    scatter!(p[1], [7200], [250]; color = "#c0392b", marker = :x, ms = 10)
    annotate!(p[1], 7350, 250, text("out of reach", 13, :left, "#c0392b"))
    plot!(p[2], n, P; color = :black, lw = 3, ylims = (0, 140), yticks = 0:50:100,
        ylabel = "power [kW]", xlabel = "machine speed [rpm]")
    annotate!(p[2], N_BASE + 120, 125,
        text("$(round(Int, T_RATED * N_BASE * π / 30 / 1e3)) kW from base speed on", 13, :left, :black))
    return p
end

const FIGURES = [
    "03-bldc-pmsm-waveforms" => waveform_plot,
    "03-field-weakening" => field_weakening_plot,
    "04-what-envelope" => envelope_schematic_plot,
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

Lecture04MachineFigures.export_all()
