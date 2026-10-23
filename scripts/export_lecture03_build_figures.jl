"""
Writes the checkpoint figures of the Lecture 3 live build into `slides/images/lecture-03/`.

    julia +dyad-3.4.0 --project=. scripts/export_lecture03_build_figures.jl

Runs the reference solutions in `dyad/HandsOn03/` and the library analyses beside them, and
saves one SVG per build step. `slides/scripts/images.mjs` copies the folder into the lecture-03
deck and the build guide page.
"""

using VehicleSystemsComponents, Plots
using DyadInterface: symbolic_container, ODEAlg

const V = VehicleSystemsComponents.Vehicle
const H = VehicleSystemsComponents.HandsOn03
const OUT = normpath(@__DIR__, "..", "slides", "images", "lecture-03")
const G = 9.80665
const T_PEAK = 1.0 * 1400 * G * 0.31
# Wheel pressure at which the two calipers of HydraulicBrakedWheel put T_PEAK on the wheel.
const P_PEAK = T_PEAK / (49.0e-5 + 19.9e-5) + 0.5e5
const BAR = 1e-5

stop_time(mu, a_max = Inf) = 0.5 + 1.5 * 25 / min(0.7 * mu * G, a_max) + 1.0
# A 2 ms grid resolves the true-slip ABS's 26 Hz ripple and keeps each SVG a few hundred kB.
function trace(run, f; dt = 0.002, from = 0.0, to = run.sol.t[end])
    ts = collect(from:dt:to)
    return ts, run.sol(ts, idxs = f(symbolic_container(run))).u
end
in_bar((t, p)) = (t, BAR .* p)

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

pedal_stop = H.PedalStopTransient()
let (t, v) = trace(pedal_stop, m -> m.body.mass.v), (_, w) = trace(pedal_stop, m -> m.wheel.inertia.w),
    (_, kappa) = trace(pedal_stop, m -> m.wheel.kappa)
    d = V.braking_distance(pedal_stop)
    p1 = plot(t, 3.6 .* v; label = "car", color = :firebrick, ylabel = "speed [km/h]",
        title = "Hydraulic pedal stop: $(round(d; digits = 1)) m from 90 km/h")
    plot!(p1, t, 3.6 .* 0.31 .* w; label = "wheel (ω·r)", color = :black, ls = :dash)
    p2 = plot(t, kappa; label = "wheel.kappa", color = :firebrick, ylabel = "slip [–]",
        xlabel = "time [s]", ylims = (-1.05, 0.05), legend = :right)
    save(plot(p1, p2; layout = (2, 1), size = (900, 620)), "step02-locked-stop")
end

present = H.ABSStopTransient(T_p = 0.0)
ahead = H.ABSStopTransient()
let
    d_a, d_c = V.braking_distance(present), V.braking_distance(ahead)
    p1 = plot(; ylabel = "front wheel pressure [bar]", ylims = (0, 100), legend = :bottomright,
        title = "Your ABS: $(round(d_a; digits = 1)) m without look-ahead, $(round(d_c; digits = 1)) m with it")
    plot!(p1, in_bar(trace(ahead, m -> m.master.p_mc))...; label = "master cylinder", color = :gray, lw = 1.5)
    plot!(p1, in_bar(trace(present, m -> m.wheel.caliper_f.p))...; label = "A: T_p = 0", color = :darkorange)
    plot!(p1, in_bar(trace(ahead, m -> m.wheel.caliper_f.p))...; label = "C: T_p = 30 ms", color = :steelblue)
    hline!(p1, [BAR * P_PEAK]; color = :gray, ls = :dot, label = "tire peak")
    p2 = plot(; ylabel = "slip [–]", xlabel = "time [s]", ylims = (-0.4, 0.02), legend = :bottomright)
    plot!(p2, trace(present, m -> m.wheel.kappa)...; label = "A", color = :darkorange, lw = 1.5)
    plot!(p2, trace(ahead, m -> m.wheel.kappa)...; label = "C", color = :steelblue, lw = 1.5)
    hline!(p2, [-0.04]; color = :gray, ls = :dot, label = "peak −0.04")
    hline!(p2, [-0.12]; color = :gray, ls = :dash, label = "sliding −0.12")
    save(plot(p1, p2; layout = (2, 1), size = (900, 620), xlims = (0, 4.5)), "step03-abs-torque-slip")
end

# Snow, where each dump empties the caliper and the wheel spins back up past +a_plus: all three
# phases show.
snow = H.ABSStopWheelOnlyTransient(road_mu = 0.3, stop = stop_time(0.3, 8.0))
let win = (1.0, 2.5), zoom(f) = trace(snow, f; dt = 5e-4, from = win[1], to = win[2]),
    (t, phase) = zoom(m -> m.abs.phase), (_, p) = zoom(m -> m.abs.p_cmd),
    (_, p_w) = zoom(m -> m.wheel.caliper_f.p),
    (_, v) = zoom(m -> m.body.mass.v), (_, v_w) = zoom(m -> m.est.v_w),
    (_, v_ref) = zoom(m -> m.est.v_ref)
    d = V.braking_distance(snow)
    p1 = plot(; ylabel = "pressure [bar]", ylims = (0, 30), legend = :topright,
        title = "Your three-phase ABS, wheel speed only, μ = 0.3: $(round(d; digits = 1)) m")
    # One shaded span per phase run; the colors match the state diagram on the slide.
    shades = Dict(-1 => (:firebrick, "dump"), 0 => (:goldenrod, "hold"), 1 => (:seagreen, "build"))
    seen = Set{Int}()
    k = 1
    while k !== nothing
        ph = round(Int, phase[k])
        e = something(findnext(x -> round(Int, x) != ph, phase, k), length(t))
        color, name = shades[ph]
        vspan!(p1, [t[k], t[e]]; color, alpha = 0.18, lw = 0,
            label = ph in seen ? "" : name)
        push!(seen, ph)
        k = e < length(t) ? e : nothing
    end
    plot!(p1, t, BAR .* p; label = "allowed (abs.p_cmd)", color = :black, lw = 2)
    plot!(p1, t, BAR .* p_w; label = "front caliper", color = :steelblue, lw = 1.5, ls = :dash)
    p2 = plot(; ylabel = "speed [km/h]", xlabel = "time [s]", legend = :bottomleft)
    plot!(p2, t, 3.6 .* v; label = "car (speed.v)", color = :black)
    plot!(p2, t, 3.6 .* v_w; label = "wheel (ω·r)", color = :gray, lw = 1.5)
    plot!(p2, t, 3.6 .* v_ref; label = "estimate (est.v_ref)", color = :purple, ls = :dash)
    save(plot(p1, p2; layout = (2, 1), size = (900, 620), xlims = win), "step04-phase-cycle")
end

let mus = [1.0, 0.5, 0.3]
    rows = map(mus) do mu
        [V.braking_distance(H.PedalStopTransient(road_mu = mu, stop = stop_time(mu))),
         V.braking_distance(H.ABSStopTransient(road_mu = mu, stop = stop_time(mu))),
         V.braking_distance(H.ABSStopWheelOnlyTransient(road_mu = mu, stop = stop_time(mu, 8.0))),
         V.braking_distance(V.ABSBrakeTransient(road_mu = mu, stop = stop_time(mu, 8.0),
             alg = ODEAlg.Tsit5(), dtmax = 1e-3))]
    end
    table = permutedims(reduce(hcat, rows))
    labels = ["locked, pedal 0.6" "ABS, true slip" "ABS, wheel only (yours)" "ABS, wheel only (library, 5 ms)"]
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
