"""
Writes the Lecture 3 hands-on deck's checkpoint figures into `slides/images/handson-03/`.

    julia +dyad-3.4.0 --project=. scripts/export_handson03_figures.jl

Runs the reference solutions in `dyad/HandsOn03/` and the library analyses beside them, and
saves one SVG per step. `slides/scripts/images.mjs` copies the folder into the deck.
"""

using VehicleSystemsComponents, Plots
using DyadInterface: symbolic_container, ODEAlg

const V = VehicleSystemsComponents.Vehicle
const H = VehicleSystemsComponents.HandsOn03
const OUT = normpath(@__DIR__, "..", "slides", "images", "handson-03")
const G = 9.80665
const T_PEAK = 1.0 * 1400 * G * 0.31

stop_time(mu, a_max = Inf) = 0.5 + 1.5 * 25 / min(0.7 * mu * G, a_max) + 1.0
# A 2 ms grid resolves the 30 Hz ABS cycle and keeps each SVG a few hundred kB.
function trace(run, f; dt = 0.002)
    ts = collect(0:dt:run.sol.t[end])
    return ts, run.sol(ts, idxs = f(symbolic_container(run))).u
end

default(; size = (900, 520), lw = 2.5, fontfamily = "sans-serif", legend = :topright,
    titlefontsize = 13, guidefontsize = 11, tickfontsize = 10, legendfontsize = 10,
    left_margin = 6Plots.mm, bottom_margin = 4Plots.mm)

function save(plot, name)
    path = joinpath(OUT, "$name.svg")
    savefig(plot, path)
    filesize(path) > 0 || error("$name.svg was written empty")
    println("  $name.svg")
end

mkpath(OUT)

locked = H.LockedStopTransient()
let (t, v) = trace(locked, m -> m.body.mass.v), (_, w) = trace(locked, m -> m.wheel.inertia.w),
    (_, kappa) = trace(locked, m -> m.wheel.kappa)
    d = V.braking_distance(locked)
    p1 = plot(t, 3.6 .* v; label = "car", color = :firebrick, ylabel = "speed [km/h]",
        title = "Locked stop: $(round(d; digits = 1)) m from 90 km/h")
    plot!(p1, t, 3.6 .* 0.31 .* w; label = "wheel (ω·r)", color = :black, ls = :dash)
    p2 = plot(t, kappa; label = "wheel.kappa", color = :firebrick, ylabel = "slip [–]",
        xlabel = "time [s]", ylims = (-1.05, 0.05), legend = :right)
    save(plot(p1, p2; layout = (2, 1), size = (900, 620)), "step02-locked-stop")
end

present = H.ABSStopTransient(T_p = 0.0)
ahead = H.ABSStopTransient()
let
    d_a, d_c = V.braking_distance(present), V.braking_distance(ahead)
    p1 = plot(; ylabel = "brake torque [N·m]", ylims = (0, 6500), legend = :bottomright,
        title = "Your ABS: $(round(d_a; digits = 1)) m without look-ahead, $(round(d_c; digits = 1)) m with it")
    plot!(p1, trace(present, m -> m.wheel.brake.tau_actual)...; label = "A: T_p = 0", color = :darkorange)
    plot!(p1, trace(ahead, m -> m.wheel.brake.tau_actual)...; label = "C: T_p = 30 ms", color = :steelblue)
    hline!(p1, [T_PEAK]; color = :gray, ls = :dot, label = "tire peak 4256 N·m")
    p2 = plot(; ylabel = "slip [–]", xlabel = "time [s]", ylims = (-0.4, 0.02), legend = :bottomright)
    plot!(p2, trace(present, m -> m.wheel.kappa)...; label = "A", color = :darkorange, lw = 1.5)
    plot!(p2, trace(ahead, m -> m.wheel.kappa)...; label = "C", color = :steelblue, lw = 1.5)
    hline!(p2, [-0.04]; color = :gray, ls = :dot, label = "peak −0.04")
    hline!(p2, [-0.12]; color = :gray, ls = :dash, label = "sliding −0.12")
    save(plot(p1, p2; layout = (2, 1), size = (900, 620), xlims = (0, 4.5)), "step03-abs-torque-slip")
end

wheel_only = H.ABSStopWheelOnlyTransient()
let (t, v) = trace(wheel_only, m -> m.body.mass.v), (_, v_ref) = trace(wheel_only, m -> m.est.v_ref),
    (_, v_w) = trace(wheel_only, m -> m.est.v_w)
    d = V.braking_distance(wheel_only)
    p = plot(t, 3.6 .* v; label = "car (speed.v)", color = :black,
        xlabel = "time [s]", ylabel = "speed [km/h]", xlims = (0.4, 2.6), ylims = (40, 92),
        title = "Wheel speed only, a_ref = 8 m/s²: $(round(d; digits = 1)) m")
    plot!(p, t, 3.6 .* v_w; label = "wheel (ω·r)", color = :gray, lw = 1.5)
    plot!(p, t, 3.6 .* v_ref; label = "estimate (est.v_ref)", color = :purple, ls = :dash)
    save(p, "step04-vref")
end

let mus = [1.0, 0.5, 0.3]
    rows = map(mus) do mu
        [V.braking_distance(H.LockedStopTransient(road_mu = mu, stop = stop_time(mu))),
         V.braking_distance(H.ABSStopTransient(road_mu = mu, stop = stop_time(mu))),
         V.braking_distance(H.ABSStopWheelOnlyTransient(road_mu = mu, stop = stop_time(mu, 8.0))),
         V.braking_distance(V.ABSBrakeTransient(road_mu = mu, stop = stop_time(mu, 8.0),
             alg = ODEAlg.Tsit5(), dtmax = 1e-3))]
    end
    table = permutedims(reduce(hcat, rows))
    labels = ["locked" "ABS, true slip" "ABS, wheel only (yours)" "ABS, wheel only (library, 5 ms)"]
    groups = ["μ = 1.0", "μ = 0.5", "μ = 0.3"]
    p = plot(; xlabel = "", ylabel = "braking distance [m]", legend = :topleft,
        title = "Braking distance from 90 km/h", xticks = (1:3, groups), ylims = (0, 165))
    colors = [:firebrick, :seagreen, :purple, :steelblue]
    w = 0.2
    for j in 1:4
        x = (1:3) .+ (j - 2.5) * w
        bar!(p, x, table[:, j]; bar_width = w, label = labels[j], color = colors[j], lw = 0)
        annotate!(p, [(x[i], table[i, j] + 4, text(string(round(table[i, j]; digits = 1)), 8)) for i in 1:3])
    end
    save(p, "step05-surfaces")
    for (mu, row) in zip(mus, eachrow(table))
        println("  μ $mu: ", join(round.(row; digits = 1), " · "))
    end
end
