"""
Writes the theory deck's ESP figures, the passive planar car in the FMVSS 126 sine-with-dwell,
into `slides/decks/lecture-03/public/figures/`.

The planar car lives on branch `feat/lecture-03-planar-car`, not on this one, so this script
runs against a checkout of that branch (or a `git archive` of it with its `Manifest.toml`):

    julia +dyad-3.4.0 --project=<planar-car checkout> scripts/export_lecture03_esp_figures.jl

It runs `Lecture3.SineWithDwellRunTransient` (Tsit5, dtmax 5 ms) at three steering-wheel
amplitudes and writes only into this repository's deck. The figures were made at 126ee69.
"""

using VehicleSystemsComponents
using DyadInterface: symbolic_container
using Plots

const OUT = normpath(@__DIR__, "..", "slides", "decks", "lecture-03", "public", "figures")
const A_REF = deg2rad(21.63)
const CASES = [
    (76.0, "76°: stable", :seagreen, :solid),
    (180.0, "180°: spins", :firebrick, :solid),
    (270.0, "270°: plows", :darkorange, :dash),
]

function run(amplitude)
    result = VehicleSystemsComponents.Lecture3.SineWithDwellRunTransient(
        A_sw = deg2rad(amplitude), stop = 6.0)
    sol, model = result.sol, symbolic_container(result)
    s = model.sensors
    m = VehicleSystemsComponents.Vehicle.Planar.fmvss126_metrics(
        sol.t, sol[s.delta_sw], sol[s.r], sol[s.y]; A = A_REF)
    t = collect(range(0.0, 6.0; length = 1201))
    get(x) = sol(t, idxs = x).u
    data = (; t, x = get(s.x), y = get(s.y), psi = get(s.psi), r = get(s.r),
        beta = get(s.beta), swa = get(s.delta_sw), vx = get(s.vx))
    println("  $(amplitude)°: YRR(1.00) $(round(m.yrr_1_00; digits = 2)), ",
        "YRR(1.75) $(round(m.yrr_1_75; digits = 2)), ",
        "y(1.07) $(round(m.y_bos_1_07; digits = 2)) m, ",
        "max |β| $(round(rad2deg(maximum(abs, data.beta)); digits = 1))°, ",
        "pass $(m.passes_stability)")
    return data, m
end

runs = [(c, run(c[1])...) for c in CASES]
mkpath(OUT)

# Top view: the path of the center of gravity, and the car's outline every 0.4 s.
const CAR_LENGTH, CAR_WIDTH = 4.6, 1.8
function outline(x, y, psi)
    c, s = cos(psi), sin(psi)
    corners = [(CAR_LENGTH / 2, CAR_WIDTH / 2), (-CAR_LENGTH / 2, CAR_WIDTH / 2),
        (-CAR_LENGTH / 2, -CAR_WIDTH / 2), (CAR_LENGTH / 2, -CAR_WIDTH / 2),
        (CAR_LENGTH / 2, CAR_WIDTH / 2)]
    return [x + c * u - s * v for (u, v) in corners], [y + s * u + c * v for (u, v) in corners]
end

traj = plot(; xlabel = "x [m]", ylabel = "y [m]", aspect_ratio = :equal,
    title = "Sine-with-dwell from 80 km/h, no ESP: seen from above",
    legend = :bottomleft, size = (960, 360), dpi = 100, left_margin = 4Plots.mm,
    bottom_margin = 4Plots.mm, xlims = (20, 132), ylims = (-17, 9))
for ((amp, label, color, ls), d, _) in runs
    plot!(traj, d.x, d.y; lw = 2.5, color, ls, label)
    for i in 1:80:length(d.t)
        d.t[i] < 1.0 && continue
        plot!(traj, outline(d.x[i], d.y[i], d.psi[i])...; seriestype = :shape,
            fillcolor = color, fillalpha = 0.25, linecolor = color, lw = 1.5, label = "")
    end
end
savefig(traj, joinpath(OUT, "05-swd-path.svg"))
println("  05-swd-path.svg")

# Steering-wheel angle and yaw rate over time, with the two FMVSS 126 check instants.
_, _, m_ref = runs[1]
swa_plot = plot(; ylabel = "steering wheel [°]", legend = false,
    title = "Sine-with-dwell, no ESP: steering and yaw rate", ylims = (-300, 330))
yaw_plot = plot(; xlabel = "time [s]", ylabel = "yaw rate [°/s]", legend = :bottomleft)
for ((amp, label, color, ls), d, _) in runs
    plot!(swa_plot, d.t, rad2deg.(d.swa); lw = 2.5, color, ls, label = "")
    plot!(yaw_plot, d.t, rad2deg.(d.r); lw = 2.5, color, ls, label)
end
for p in (swa_plot, yaw_plot)
    vline!(p, [m_ref.t_cos]; color = :gray, ls = :dot, label = "")
    vline!(p, [m_ref.t_cos + 1.0, m_ref.t_cos + 1.75]; color = :black, ls = :dot, label = "")
end
hline!(yaw_plot, [0.0]; color = :gray, lw = 1, label = "")
for (t, text) in ((m_ref.t_cos, "steering ends"), (m_ref.t_cos + 1.0, "+1.00 s"),
                  (m_ref.t_cos + 1.75, "+1.75 s"))
    annotate!(swa_plot, t + 0.05, 250, Plots.text(text, 8, :left, :gray25))
end
yaw = plot(swa_plot, yaw_plot; layout = grid(2, 1, heights = [0.38, 0.62]),
    link = :x, size = (960, 540), dpi = 100, left_margin = 6Plots.mm)
savefig(yaw, joinpath(OUT, "05-swd-yaw-rate.svg"))
println("  05-swd-yaw-rate.svg")
