"""
Writes the theory deck's brake-and-steer figures, the planar car braking fully from 80 km/h on
a dry road while the driver steers left around an obstacle, with ABS and with the wheels locked,
into `slides/decks/lecture-03/public/figures/`:

    julia +dyad-3.5.0 --project=. scripts/export_lecture03_steer_figures.jl

It runs `Lecture3.BrakeAndSteerTransient` twice, with `abs_on = 1` and `abs_on = 0`, Tsit5 with
dtmax 5 ms and no load transfer, and prints every number the slides quote: the stopping
distance from brake onset, the lateral offset at the obstacle and at standstill, the peak yaw
rate, and the front wheels' slip and lateral force. The clocked ABS makes each run take about
half a minute.

The dyad-3.5 kernel has no GR, so the figures go through Plots' plotly backend and Kaleido at
their own size, by `save_svg` in `scripts/plotly_svg.jl`.
"""

using VehicleSystemsComponents
using DyadInterface: symbolic_container
using Plots
import PlotlyBase, PlotlyKaleido

plotly()
include("plotly_svg.jl")

const L3 = VehicleSystemsComponents.Lecture3
const OUT = normpath(@__DIR__, "..", "slides", "decks", "lecture-03", "public", "figures")
const T = collect(range(0.0, 6.0; length = 3001))
const BRAKE_TIME = 0.5
const STEER_TIME = 0.8
const OBSTACLE_AFTER = 25.0

r1(x) = round(x; digits = 1)
r2(x) = round(x; digits = 2)

"""Sampled signals of one run and its numbers; the solution is dropped."""
function brake_and_steer(abs_on)
    result = L3.BrakeAndSteerTransient(; abs_on)
    sol, model = result.sol, symbolic_container(result)
    s = model.car.bus
    get(x) = sol(T, idxs = x).u
    x, y, vx, vy = get(s.x), get(s.y), get(s.vx), get(s.vy)
    v = hypot.(vx, vy)
    ib = findfirst(>=(BRAKE_TIME), T)
    isteer = findfirst(>=(STEER_TIME), T)
    # A locked wheel's slip is undefined at standstill, so the stop is read at 0.05 m/s.
    is = something(findfirst(i -> T[i] > BRAKE_TIME && v[i] < 0.05, eachindex(T)), length(T))
    x_obstacle = x[ib] + OBSTACLE_AFTER
    io = findfirst(>=(x_obstacle), x)
    moving = (v .> 3.0) .& (T .> BRAKE_TIME)
    kappa_f = (get(s.kappa_fl) .+ get(s.kappa_fr)) ./ 2
    Fy_f = get(model.car.fl.F_y) .+ get(model.car.fr.F_y)
    r = get(s.r)
    return (; t = T, x, y, psi = get(s.psi), r, v, kappa_f, Fy_f, moving, ib, isteer, is,
        x_obstacle,
        t_stop = T[is],
        distance = sum(hypot.(diff(x[ib:is]), diff(y[ib:is]))),
        y_obstacle = isnothing(io) ? NaN : y[io],
        v_obstacle = isnothing(io) ? 0.0 : v[io],
        y_stop = y[is],
        r_peak = maximum(abs, r),
        kappa_min = minimum(min.(get(s.kappa_fl), get(s.kappa_fr))[moving]),
        Fy_mean = sum(Fy_f[moving .& (T .> STEER_TIME + 0.2)]) /
                  count(moving .& (T .> STEER_TIME + 0.2)))
end

function report(label, d)
    println("  $label: stop at $(r2(d.t_stop)) s, distance from brake onset $(r1(d.distance)) m, ",
        "speed at the obstacle $(r1(3.6 * d.v_obstacle)) km/h, ",
        "lateral offset at the obstacle $(r2(d.y_obstacle)) m and at standstill $(r2(d.y_stop)) m, ",
        "peak yaw rate $(r1(rad2deg(d.r_peak)))°/s, heading at standstill ",
        "$(r1(rad2deg(d.psi[d.is])))°, lowest front slip while moving $(round(d.kappa_min; digits = 3)), ",
        "mean front lateral force after the steer $(round(Int, d.Fy_mean)) N")
end

const ABS_OFF = ("ABS off, wheels locked", :firebrick, :dash)
const ABS_ON = ("ABS on", :royalblue, :solid)

println("Brake and steer from 80 km/h, dry road:")
on = brake_and_steer(1.0)
report("ABS on", on)
off = brake_and_steer(0.0)
report("ABS off", off)

mkpath(OUT)

const CAR_LENGTH, CAR_WIDTH = 4.6, 1.8
function outline(x, y, psi)
    c, s = cos(psi), sin(psi)
    corners = [(CAR_LENGTH / 2, CAR_WIDTH / 2), (-CAR_LENGTH / 2, CAR_WIDTH / 2),
        (-CAR_LENGTH / 2, -CAR_WIDTH / 2), (CAR_LENGTH / 2, -CAR_WIDTH / 2),
        (CAR_LENGTH / 2, CAR_WIDTH / 2)]
    return [x + c * u - s * v for (u, v) in corners], [y + s * u + c * v for (u, v) in corners]
end
function draw_car!(p, d, color, indices)
    for i in indices
        plot!(p, outline(d.x[i], d.y[i], d.psi[i])...; seriestype = :shape,
            fillcolor = color, fillalpha = 0.25, linecolor = color, lw = 1.5, label = "")
    end
end

x_max = max(on.x[on.is], off.x[off.is]) + 6
traj = plot(; xlabel = "x [m]", ylabel = "y [m], left up", aspect_ratio = :equal,
    title = "Full braking and a steer to the left from 80 km/h: seen from above",
    legend = :topleft, size = (960, 360), dpi = 100, left_margin = 4Plots.mm,
    bottom_margin = 4Plots.mm, xlims = (-4, x_max), ylims = (-3, 14))
for ((label, color, ls), d) in ((ABS_OFF, off), (ABS_ON, on))
    plot!(traj, d.x[1:d.is], d.y[1:d.is]; lw = 2.5, color, ls, label)
    draw_car!(traj, d, color, (d.ib:250:d.is..., d.is))
end
draw_car!(traj, on, :gray40, (1,))
# The obstacle sits in the car's original lane, its near edge where it is checked.
plot!(traj, [on.x_obstacle, on.x_obstacle + 2, on.x_obstacle + 2, on.x_obstacle,
        on.x_obstacle], [-1.0, -1.0, 1.0, 1.0, -1.0];
    seriestype = :shape, fillcolor = :gray50, fillalpha = 0.6, linecolor = :gray30, label = "")
annotate!(traj, on.x_obstacle + 1, -1.8, Plots.text("obstacle", 8, :center, :gray25))
for (i, text) in ((1, "start, 80 km/h"), (on.ib, "brake, 0.5 s"), (on.isteer, "steer, 0.8 s"))
    scatter!(traj, [on.x[i]], [on.y[i]]; color = :black, ms = 4, label = "")
    annotate!(traj, on.x[i], on.y[i] + 1.6, Plots.text(text, 8, :center, :gray25))
end
save_svg(traj, joinpath(OUT, "03-brake-steer-path.svg"))
println("  03-brake-steer-path.svg")

window(d) = d.ib:d.is
force_plot = plot(; ylabel = "front lateral force [kN]", legend = :topright,
    title = "Front axle: lateral force and slip, steering from 0.8 s", bottom_margin = 4Plots.mm)
slip_plot = plot(; xlabel = "time [s]", ylabel = "front slip κ", legend = false,
    ylims = (-1.05, 0.05))
for ((label, color, ls), d) in ((ABS_OFF, off), (ABS_ON, on))
    w = window(d)
    plot!(force_plot, d.t[w], d.Fy_f[w] ./ 1000; lw = 2.5, color, ls, label)
    plot!(slip_plot, d.t[w], d.kappa_f[w]; lw = 2.5, color, ls)
end
hline!(force_plot, [0.0]; color = :gray, lw = 1, label = "")
hline!(slip_plot, [-0.2]; color = :black, ls = :dot)
annotate!(slip_plot, 2.0, -0.15, Plots.text("κ = −0.2", 8, :left, :gray25))
for p in (force_plot, slip_plot)
    vline!(p, [BRAKE_TIME, STEER_TIME]; color = :gray, ls = :dot, label = "")
end
fig = plot(force_plot, slip_plot; layout = grid(2, 1, heights = [0.55, 0.45]),
    size = (960, 540), dpi = 100, left_margin = 6Plots.mm, xlims = (0.4, max(on.t_stop, off.t_stop) + 0.1))
save_svg(fig, joinpath(OUT, "03-brake-steer-forces.svg"))
println("  03-brake-steer-forces.svg")
PlotlyKaleido.kill_kaleido()
