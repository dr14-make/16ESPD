"""
Writes the Lecture 3 vacuum-booster demo figures into `slides/decks/lecture-03/public/figures/`:

    julia +dyad-3.5.0 --project=. scripts/export_lecture03_vacuum_figures.jl

It runs `Vehicle.Brake.BrakeVacuumTransient` with one 400 N application at idle (800 rpm), at
cruise (2000 rpm, throttle 0.06, 45 kPa) and at wide-open throttle (3000 rpm);
`Vehicle.Brake.BoosterCharacteristicTransient` at 33 and 50 kPa of source pressure;
`Vehicle.Brake.BrakeVacuumReserveTransient`, five applications with the engine off; and
`Lecture3.VacuumPedalStopTransient` at pedal 0.3 at idle, at wide-open throttle with a fresh and
a spent reserve, with the engine off after the reserve is gone, and on the electric pump. All are
Tsit5 with dtmax 1 ms. It prints every number the slides quote, and takes about a minute and a
half.

`02-throttle-vacuum.svg` needs no simulation: the steady manifold pressure against throttle
opening, where `Vehicle.Engine.Throttle`'s flow equals `CylinderAirflow`'s, solved by bisection
on the same equations with `AirPath`'s defaults, and the booster's run-out assist at that
vacuum.
"""

using VehicleSystemsComponents
using DyadInterface: symbolic_container
using Plots

const VB = VehicleSystemsComponents.Vehicle.Brake
const V = VehicleSystemsComponents.Vehicle
const L3 = VehicleSystemsComponents.Lecture3
const OUT = normpath(@__DIR__, "..", "slides", "decks", "lecture-03", "public", "figures")
const KPA = 1e-3
const BAR = 1e-5

r1(x) = round(x; digits = 1)
r2(x) = round(x; digits = 2)

default(; size = (900, 520), lw = 2.5, fontfamily = "sans-serif", legend = :topright,
    titlefontsize = 13, guidefontsize = 11, tickfontsize = 10, legendfontsize = 10,
    left_margin = 6Plots.mm, bottom_margin = 4Plots.mm)

function save(plot, name)
    path = joinpath(OUT, "$name.svg")
    savefig(plot, path)
    filesize(path) > 0 || error("$name.svg was written empty")
    println("  $name.svg")
end

static_F_out(F_in, p_vac) =
    max(0.0, F_in < 40.0 ? 0.0 : min(500.0 + 5.0 * (F_in - 40.0), F_in + 0.0533 * (101325.0 - p_vac) - 97.0))

mkpath(OUT)

# Manifold and booster front chamber through one 400 N application, 2 s on from t = 2 s.
const T_APPLY, T_RELEASE = 2.0, 4.0
const ENGINE_CASES = (
    (label = "idle, 800 rpm", color = :seagreen, u_thr = 0.0, omega = 800 * pi / 30),
    (label = "cruise, 2000 rpm", color = :darkorange, u_thr = 0.06, omega = 2000 * pi / 30),
    (label = "wide open, 3000 rpm", color = :firebrick, u_thr = 1.0, omega = 3000 * pi / 30),
)
println("Manifold through one 400 N application:")
manifold = plot(; xlabel = "time [s]", ylabel = "absolute pressure [kPa]",
    title = "Manifold (solid) and booster vacuum chamber (dashed), one 400 N stop",
    legend = :bottomright, ylims = (0, 105))
for c in ENGINE_CASES
    run = VB.BrakeVacuumTransient(; stop = 7.0, t0 = T_APPLY, T_on = T_RELEASE - T_APPLY,
        T_cyc = 10.0, u_thr = c.u_thr, omega = c.omega, p_m0 = 101325.0)
    m = symbolic_container(run)
    ts = collect(1.0:0.002:7.0)
    p_m = run.sol(ts, idxs = m.air.p_m).u
    p_f = run.sol(ts, idxs = m.booster.p_f).u
    before = run.sol(T_APPLY - 0.01, idxs = m.air.p_m)
    after = ts .>= T_RELEASE
    i_last = findlast(k -> abs(p_m[k] - before) > 2e3, eachindex(ts))
    recovery = isnothing(i_last) || ts[i_last] < T_RELEASE ? 0.0 : ts[i_last] - T_RELEASE
    println("  $(c.label): p_m $(r1(before * KPA)) kPa before, peak after release ",
        "$(r1(maximum(p_m[after]) * KPA)) kPa, back within 2 kPa $(r2(recovery)) s after release; ",
        "booster p_f $(r1(p_f[1] * KPA)) -> $(r1(p_f[end] * KPA)) kPa, ",
        "peak p_mc $(r1(maximum(run.sol[m.master.p_mc]) * BAR)) bar")
    plot!(manifold, ts, KPA .* p_m; color = c.color, label = c.label)
    plot!(manifold, ts, KPA .* p_f; color = c.color, ls = :dash, lw = 2, label = "")
end
hline!(manifold, [101.325]; color = :gray, ls = :dot, lw = 1.5, label = "ambient")
vspan!(manifold, [T_APPLY, T_RELEASE]; color = :gray, alpha = 0.12, label = "pedal at 400 N")
save(manifold, "02-vacuum-manifold")

# Booster characteristic: a slow pushrod-force triangle, 10 s up and 10 s down.
println("Booster characteristic, slow triangle to 1200 N at the pushrod:")
characteristic = plot(; xlabel = "input (pushrod) force F_in [kN]", ylabel = "output force F_out [kN]",
    title = "Vacuum booster characteristic: apply and release", legend = :bottomright,
    xlims = (0, 1.2), ylims = (0, 5))
for (p_vac, color) in ((33e3, :royalblue), (50e3, :darkorange))
    run = VB.BoosterCharacteristicTransient(p_vac = p_vac)
    m = symbolic_container(run)
    t, F_in, F_out = run.sol.t, run.sol[m.booster.F_in], run.sol[m.booster.F_out]
    p_r, p_mc = run.sol[m.booster.p_r], run.sol[m.master.p_mc]
    up = t .< 10.5
    i_runout = findfirst(k -> up[k] && p_r[k] >= 101325.0 - 1e3, eachindex(t))
    at(F, branch) = F_out[findfirst(k -> branch[k] && (up[k] ? F_in[k] >= F : F_in[k] <= F), eachindex(t))]
    println("  source $(r1(p_vac * KPA)) kPa: run-out at F_in $(round(Int, F_in[i_runout])) N, ",
        "p_mc $(r1(p_mc[i_runout] * BAR)) bar; at F_in 450 N apply $(round(Int, at(450.0, up))) N, ",
        "release $(round(Int, at(450.0, .!up))) N, StaticBooster $(round(Int, static_F_out(450.0, p_vac))) N")
    label = "source $(round(Int, p_vac * KPA)) kPa"
    ts = collect(0.0:0.01:21.0)
    plot!(characteristic, 1e-3 .* run.sol(ts, idxs = m.booster.F_in).u,
        1e-3 .* run.sol(ts, idxs = m.booster.F_out).u; color, label)
    F = collect(0.0:2.0:1200.0)
    plot!(characteristic, 1e-3 .* F, 1e-3 .* static_F_out.(F, p_vac); color, ls = :dot, lw = 1.5,
        label = "")
end
plot!(characteristic, [NaN], [NaN]; color = :gray, ls = :dot, lw = 1.5, label = "StaticBooster")
annotate!(characteristic, 0.30, 2.6, Plots.text("release", 10, :right, :gray25))
annotate!(characteristic, 0.52, 1.9, Plots.text("apply", 10, :left, :gray25))
save(characteristic, "02-booster-characteristic")

# Reserve after the engine stops: five 400 N applications with the check valve shut.
println("Engine off, five 400 N applications:")
reserve = VB.BrakeVacuumReserveTransient()
mr = symbolic_container(reserve)
starts = 1.0 .+ 4.0 .* (0:4)
assist = [reserve.sol(a - 1e-3, idxs = mr.booster.F_assist_max) for a in starts]
p_f_before = [reserve.sol(a - 1e-3, idxs = mr.booster.p_f) for a in starts]
t, p_mc = reserve.sol.t, reserve.sol[mr.master.p_mc]
peak_p_mc = [maximum(p_mc[(t .>= a) .& (t .< a + 2.0)]) for a in starts]
for k in eachindex(starts)
    println("  stop $k: booster at $(r1(p_f_before[k] * KPA)) kPa, assist available ",
        "$(r2(max(assist[k], 0.0) * 1e-3)) kN, peak p_mc $(r1(peak_p_mc[k] * BAR)) bar")
end
reserve_plot = bar(1:5, 1e-3 .* max.(assist, 0.0); color = :royalblue, label = "",
    xlabel = "application after the engine stops", ylabel = "assist available [kN]",
    title = "Engine off: the booster's reserve, 400 N applications", ylims = (0, 4.2),
    xticks = 1:5, bar_width = 0.6)
for k in 1:5
    annotate!(reserve_plot, k, 1e-3 * max(assist[k], 0.0) + 0.15,
        Plots.text("$(r1(max(assist[k], 0.0) * 1e-3)) kN, $(round(Int, peak_p_mc[k] * BAR)) bar", 9, :center))
end
save(reserve_plot, "02-vacuum-reserve")

# Stopping distance from 25 m/s at pedal 0.3 (150 N) with each vacuum source.
const STOPS = (
    (label = "idle", kw = (;), stop = 6.0),
    (label = "wide open, fresh reserve", kw = (u_thr = 1.0, omega_e = 3000 * pi / 30), stop = 6.0),
    (label = "wide open, reserve gone", kw = (u_thr = 1.0, omega_e = 3000 * pi / 30, n_apply = 4.0), stop = 60.0),
    (label = "engine off, reserve gone", kw = (engine_on = 0.0, n_apply = 4.0), stop = 60.0),
    (label = "electric pump, from 40 kPa", kw = (engine_on = 0.0, ev_pump = 1.0, p_vac0 = 40e3), stop = 6.0),
)
println("Stopping distance from 25 m/s at pedal 0.3 (150 N):")
static = VehicleSystemsComponents.HandsOn03.PedalStopTransient(pedal = 0.3)
println("  StaticBooster (HandsOn03.PedalStop): $(r1(V.braking_distance(static))) m, ",
    "peak p_mc $(r1(maximum(static.sol[symbolic_container(static).master.p_mc]) * BAR)) bar")
distances = Float64[]
for s in STOPS
    run = L3.VacuumPedalStopTransient(; pedal = 0.3, stop = s.stop, s.kw...)
    ms = symbolic_container(run)
    d = V.braking_distance(run)
    push!(distances, d)
    println("  $(s.label): $(r1(d)) m, peak p_mc $(r1(maximum(run.sol[ms.master.p_mc]) * BAR)) bar, ",
        "booster starts at $(r1(run.sol[ms.booster.p_f][1] * KPA)) kPa")
end
stops_plot = plot(; xlabel = "stopping distance from 25 m/s [m]", legend = false,
    title = "Pedal at 150 N: where the booster's vacuum comes from",
    xlims = (0, 1.18 * maximum(distances)), ylims = (0.4, length(STOPS) + 0.6),
    yticks = (1:length(STOPS), reverse([s.label for s in STOPS])), yflip = false,
    left_margin = 4Plots.mm, size = (900, 420))
for (k, d) in enumerate(reverse(distances))
    plot!(stops_plot, Shape([0, d, d, 0], [k - 0.3, k - 0.3, k + 0.3, k + 0.3]);
        color = :royalblue, linecolor = :royalblue)
    annotate!(stops_plot, d + 0.01 * maximum(distances), k, Plots.text("$(r1(d)) m", 10, :left))
end
save(stops_plot, "02-vacuum-stopping")

# Steady state of `Vehicle.Engine.AirPath`: throttle flow = cylinder flow, with its defaults.
const P_A, T_A, R_AIR, GAMMA, PI_LIN = 101325.0, 298.15, 287.05, 1.4, 0.95
const PI_CR = (2 / (GAMMA + 1))^(GAMMA / (GAMMA - 1))
psi(Π) = sqrt(2GAMMA / (GAMMA - 1) * (Π^(2 / GAMMA) - Π^((GAMMA + 1) / GAMMA)))
function throttle_flow(u, p_m; alpha_0 = 0.122173, D = 0.05, A_idle = 7.4e-6, C_d = 0.8)
    alpha = alpha_0 + clamp(u, 0, 1) * (pi / 2 - alpha_0)
    A = A_idle + pi * D^2 / 4 * (1 - cos(alpha) / cos(alpha_0))
    Π = max(p_m / P_A, PI_CR)
    Ψ = Π > PI_LIN ? psi(PI_LIN) * (1 - Π) / (1 - PI_LIN) : psi(Π)
    return C_d * A * P_A / sqrt(R_AIR * T_A) * Ψ
end
function cylinder_flow(p_m, n; V_d = 1.5e-3)
    N = clamp(n, 500, 6750) / 1000
    eta = (0.777026 + 0.148753N - 0.020452N^2) * (1 - 0.898877 + 0.898877 * p_m / 95000)
    return eta * p_m * V_d * n / (120 * R_AIR * T_A)
end
function manifold_pressure(u, n)
    lo, hi = 1.0, P_A
    for _ in 1:100
        mid = (lo + hi) / 2
        throttle_flow(u, mid) > cylinder_flow(mid, n) ? (lo = mid) : (hi = mid)
    end
    return lo
end
assist_kN(p_m) = (0.0533 * (P_A - p_m) - 97.0) / 1000

println("Steady manifold pressure against throttle opening:")
const U_THR = collect(range(0.0, 0.5; length = 501))
tv = plot(; xlabel = "throttle opening [%]", ylabel = "manifold absolute pressure [kPa]",
    title = "Open the throttle and the vacuum is gone", legend = :right,
    xlims = (0, 50), ylims = (0, 105), size = (900, 480), right_margin = 18Plots.mm)
for (n, color) in ((800, :seagreen), (2000, :darkorange), (3000, :firebrick))
    p = manifold_pressure.(U_THR, n)
    println("  $n rpm: ", join(["$(round(Int, 100u)) % $(r1(manifold_pressure(u, n) * KPA)) kPa"
        for u in (0.0, 0.05, 0.1, 0.2, 0.5, 1.0)], ", "))
    plot!(tv, 100 .* U_THR, KPA .* p; color, label = "$n rpm")
end
hline!(tv, [101.325]; color = :gray, ls = :dot, lw = 1.5, label = "ambient, no vacuum")
scatter!(tv, [0.0], [KPA * manifold_pressure(0.0, 800)]; color = :seagreen, ms = 6, label = "")
annotate!(tv, 14, 8, Plots.text("idle, throttle shut: 33 kPa, 3.5 kN of assist", 9, :left, :seagreen))
plot!(tv, [1, 13.5], [KPA * manifold_pressure(0.0, 800) - 1, 10]; color = :seagreen, lw = 1, label = "")
tv2 = twinx(tv)
plot!(tv2; ylims = (assist_kN(105e3), assist_kN(0.0)), yflip = true,
    ylabel = "booster's most assist [kN]", legend = false, grid = false)
println("  most assist: $(r2(assist_kN(33e3))) kN at 33 kPa, $(r2(assist_kN(54e3))) at 54, ",
    "$(r2(assist_kN(90e3))) at 90")
save(tv, "02-throttle-vacuum")
