"""
Writes the Lecture 4 deck's BLDC/PMSM waveform figure into
`slides/decks/lecture-04/public/figures/`.

    julia +dyad-3.5.0 --project=. scripts/export_lecture04_waveform_figures.jl

Over one electrical revolution it draws, for a trapezoidal (BLDC) and a sinusoidal (PMSM) machine,
the three back-EMFs, the currents the drive puts in, and the torque Σ e·i / ω. The waveforms are
the textbook ideal shapes, in per unit of their peak. The one computed curve is the BLDC's torque
with winding inductance: a six-step inverter at a fixed average voltage, simulated here with no
Dyad model. `scripts/export_lecture04_figures.jl` runs this file after the notebooks.
"""
module Lecture04WaveformFigures

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

const FIGURES = ["03-bldc-pmsm-waveforms" => waveform_plot]

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

Lecture04WaveformFigures.export_all()
