### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ d733a7d0-135f-4ace-8f02-8159688077fe
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, "..", ".."))
    include(joinpath(@__DIR__, "..", "lecture01", "support.jl"))
    using .Lecture01Support
    # The dyad-3.5 kernel ships Plots with the plotly backend and Kaleido, but not GR.
    VehicleSystemsComponents = setup(backend = :plotly)
    using ModelingToolkit, Plots
    using DyadInterface: symbolic_container
end

# ╔═╡ f6acb09c-5c44-4121-9b81-595d773a3be3
md"""
# Lecture 4 — The machine, the battery and regen, on their benches

Three links of the energy chain, each on the bench its build step uses, run with the course
library's copies of the students' parts:

| section | deck section | build step | bench |
|:---|:---|:---|:---|
| 1. The DC machine on a fixed supply | 02 The DC machine | 01 | `Vehicle.Electric.DCMachineTransient` |
| 2. Where the machine's losses go | 02 The DC machine | 01–02 | `Vehicle.Electric.ConverterTransient` |
| 3. The battery under load | 06 Batteries, simply | 03 | `Vehicle.Electric.BatteryTransient` |
| 4. Regen on a hard stop | 07 The car and regen | 05 | `Vehicle.Planar.PlanarBEVHardStopTransient` |

The envelope and the efficiency map are notebook 01's; the switching models notebook 02's; the
WLTC energy bill notebook 03's.

Every number below is read from a simulation of the Dyad models named.
"""

# ╔═╡ 377ed78d-9288-4b91-8268-7d78999b47a2
begin
    E4 = VehicleSystemsComponents.Vehicle.Electric
    PL = VehicleSystemsComponents.Vehicle.Planar
    rpm_of(w) = w * 30 / pi
end

# ╔═╡ d91ae61d-5421-43d0-a222-edaa0839acdd
md"""
## 1. The DC machine on a fixed supply

Build step 01's dyno: the terminals on a stiff supply, the shaft held by a dyno that ramps its
speed. With the supply fixed, the current is whatever the gap between supply and back-EMF drives
through the armature resistance, so the torque is a straight line in speed. It falls by
(*K*Φ)²/*R* per rad/s and reaches zero where the back-EMF has caught up with the supply. A lower
supply moves the line down in speed and keeps its slope: the deck's first way of controlling a DC
motor, by its voltage.
"""

# ╔═╡ 2964dcd0-e985-4c5a-8f48-336c25d8936e
dyno = (; r350 = E4.DCMachineTransient(V = 350.0, rpm_start = 3283.0, rpm_end = 3600.0),
    r200 = E4.DCMachineTransient(V = 200.0, rpm_start = 1500.0, rpm_end = 2200.0));

# ╔═╡ 3682b634-a0dd-4436-97fa-61a8499843a0
"Speed in rpm and shaft torque along the ramp of a dyno run, from 1 s on."
function dyno_line(run)
    s, m = run.sol, symbolic_container(run)
    k = s.t .>= 1.0
    return (; rpm = rpm_of.(s[m.machine.w][k]), tau = s[m.machine.tau][k],
        i = s[m.machine.i][k], P_cu = s[m.machine.P_cu][k], R = s.ps[m.machine.R],
        k = s.ps[m.machine.k])
end

# ╔═╡ bfdfb407-06cd-44bf-acbd-d56762c8e2dd
torque_speed_plot = let
    a, b = dyno_line(dyno.r350), dyno_line(dyno.r200)
    slope = (a.tau[end] - a.tau[1]) / (a.rpm[end] - a.rpm[1])
    noload(V) = round(Int, rpm_of(V / a.k))
    p = plot(; xlabel = "machine speed [rpm]", ylabel = "shaft torque [N·m]",
        size = (960, 500), legend = false, ylims = (-520, 1020),
        title = "Fixed supply: the torque falls $(round(-slope; digits = 2)) N·m per rpm, to zero " *
                "near V / KΦ: $(noload(350.0)) rpm on 350 V, $(noload(200.0)) rpm on 200 V")
    plot!(p, b.rpm, b.tau; color = 2, lw = 2.5, label = "200 V supply")
    plot!(p, a.rpm, a.tau; color = 1, lw = 2.5, label = "350 V supply")
    hline!(p, [320.0]; color = :gray, ls = :dash, lw = 1.5, label = "Leaf peak torque, 320 N·m")
    hline!(p, [0.0]; color = :black, lw = 0.5, label = "")
    scatter!(p, [a.rpm[1]], [a.tau[1]]; color = 1, ms = 6, label = "")
    annotate!(p, [(a.rpm[1] - 40, a.tau[1] - 45,
        text("$(round(a.tau[1]; digits = 1)) N·m at 3283 rpm, $(round(a.i[1]; digits = 1)) A", 10, :right))])
    scatter!(p, [b.rpm[1]], [b.tau[1]]; color = 2, ms = 6, label = "")
    annotate!(p, [(b.rpm[1] + 40, b.tau[1] + 30,
        text("$(round(Int, b.tau[1])) N·m at 1500 rpm, $(round(Int, b.i[1])) A", 10, :left))])
    annotate!(p, [(2050.0, 450.0, text("200 V supply", 11, :left, palette(:default)[2])),
        (3480.0, 80.0, text("350 V supply", 11, :left, palette(:default)[1])),
        (2400.0, 340.0, text("Leaf peak torque, 320 N·m", 10, :left, :bottom, :gray))])
    annotate!(p, [(a.rpm[end] - 40, a.tau[end],
        text("generating: $(round(Int, a.tau[end])) N·m, $(round(Int, a.i[end])) A", 10, :right))])
    p
end

# ╔═╡ 17c1868c-da16-4f2f-ad4a-a2003a870851
let
    a = dyno_line(dyno.r350)
    j = argmin(abs.(a.rpm .- 3283.0))
    md"""
    At 3283 rpm on 350 V the shaft gives **$(round(a.tau[j]; digits = 1)) N·m** for
    **$(round(a.i[j]; digits = 1)) A**; the copper loss is
    **$(round(a.P_cu[j] / 1e3; digits = 2)) kW**, and *R i²* is
    $(round(a.R * a.i[j]^2 / 1e3; digits = 2)) kW. At 3600 rpm the machine is generating:
    **$(round(a.tau[end]; digits = 1)) N·m** and **$(round(a.i[end]; digits = 1)) A** back into
    the supply.
    """
end

# ╔═╡ 8c15e1f1-211b-4b8b-b43d-4c38d38bdfb3
md"""
## 2. Where the machine's losses go

The deck's loss formula, `C + k_w ω³ + T_f ω + K_i ω + K_c T²`, with each term a part of the
machine. The copper loss depends on the current, the others on the speed alone, so the machine is
run along its whole envelope at one current: build step 02's converter holds the current limit,
332.2 A, from standstill to 10 000 rpm, and turns the field down above base speed. The copper loss
is then the same at every speed, and the speed terms grow under it: friction and iron as ω,
windage as ω³. At part load the current, and with it the copper loss, falls as the square of the
torque, and the speed terms are what is left: that is why the efficiency map of section 04
collapses at light load.
"""

# ╔═╡ 10962649-cde5-4bea-ab84-08874291b7a3
envelope = let
    run = E4.ConverterTransient()
    s, m = run.sol, symbolic_container(run)
    k = s.t .>= 1.0
    (; rpm = rpm_of.(s[m.machine.w][k]), P_cu = s[m.machine.P_cu][k],
        P_fric = s[m.machine.P_fric][k], P_iron = s[m.machine.P_iron][k],
        P_wind = s[m.machine.P_wind][k], P_const = s[m.machine.P_const][k],
        P_mech = s[m.machine.P_mech][k])
end;

# ╔═╡ 3ef3be46-a5e3-4e27-a1d2-6b0a714ba563
losses_plot = let
    e = envelope
    j = argmin(abs.(e.rpm .- 3283.0))
    shaft = e.P_fric[j] + e.P_iron[j] + e.P_wind[j] + e.P_const[j]
    p = plot(; xlabel = "machine speed [rpm]", ylabel = "loss [W]", yscale = :log10,
        size = (960, 480), legend = :bottomright, ylims = (1.0, 2.0e4),
        yticks = ([1, 10, 100, 1000, 10000], ["1", "10", "100", "1 000", "10 000"]),
        title = "At the current limit, 332.2 A: copper $(round(e.P_cu[j] / 1e3; digits = 2)) kW " *
                "at every speed, the shaft losses $(round(shaft / 1e3; digits = 2)) kW at base speed")
    series = [("copper, R i²", e.P_cu, 1), ("iron, K_i ω", e.P_iron, 2),
        ("constant, C", e.P_const, 3), ("friction, T_f ω", e.P_fric, 4),
        ("windage, k_w ω³", e.P_wind, 5)]
    for (name, P, c) in series
        keep = (e.rpm .>= 100.0) .& (P .>= 1.0)
        plot!(p, e.rpm[keep], P[keep]; color = c, lw = 2.5, label = name)
    end
    plot!(p, [3283.0, 3283.0], [1.0, 2.0e4]; color = :gray, ls = :dash, lw = 1,
        label = "base speed, 3283 rpm")
    p
end

# ╔═╡ 74586281-9ffa-41d6-b0bb-1ad008b39e1a
let
    e = envelope
    j = argmin(abs.(e.rpm .- 3283.0))
    r(x) = round(Int, x)
    md"""
    At base speed: copper **$(r(e.P_cu[j])) W**, iron **$(r(e.P_iron[j])) W**, constant
    **$(r(e.P_const[j])) W**, friction **$(r(e.P_fric[j])) W**, windage **$(r(e.P_wind[j])) W**,
    for **$(round(e.P_mech[j] / 1e3; digits = 1)) kW** at the shaft. At 10 000 rpm windage has
    grown to **$(r(e.P_wind[end])) W** and iron to **$(r(e.P_iron[end])) W**.
    """
end

# ╔═╡ f1508342-69b2-4bf5-9cc0-764009078ed2
md"""
## 3. The battery under load

Build step 03's pack: a constant open-circuit voltage *E* = 350 V behind *R*₀ = 0.1 Ω, and a
state of charge counted from the current. Open circuit for a minute, then a constant load for
half an hour: 100 A, a car cruising, and 330 A, about the machine's 110 kW. The terminal voltage
sags by *R*₀·*i* the instant the load comes on and stays there, because *E* is constant; SoC falls
on a straight line, and nothing stops it at zero.
"""

# ╔═╡ 611c1b72-0377-41ce-9476-6dd3d9f96b83
battery = (; r100 = E4.BatteryTransient(I_load = 100.0), r330 = E4.BatteryTransient(I_load = 330.0));

# ╔═╡ 4e9ef33b-325f-4971-b2e8-86cad3875f70
battery_plot = let
    p = plot(; layout = (2, 1), size = (960, 560), link = :x)
    for (run, I, c) in ((battery.r100, 100, 1), (battery.r330, 330, 2))
        s, m = run.sol, symbolic_container(run)
        ts = range(0.0, 1860.0; length = 621)
        tmin = ts ./ 60
        v = s(ts; idxs = m.battery.v).u
        soc = s(ts; idxs = m.battery.SoC).u
        plot!(p[1], tmin, v; color = c, lw = 2.5, label = "$I A")
        plot!(p[2], tmin, soc; color = c, lw = 2.5, label = "")
        annotate!(p[1], [(5.0, v[end] + 2, text("$(round(v[end]; digits = 1)) V", 10, :left, :bottom))])
        annotate!(p[2], [(31.0, soc[end] + 0.05,
            text("SoC $(round(soc[end]; digits = 4))", 10, :right, :bottom))])
    end
    hline!(p[1], [350.0]; color = :gray, ls = :dash, lw = 1, label = "E = 350 V")
    hline!(p[2], [0.0]; color = :black, lw = 0.8, label = "")
    plot!(p[1]; ylabel = "terminal voltage [V]", legend = :topright, ylims = (300, 360),
        title = "Constant load from 1 min: the voltage sags by R₀ i, SoC falls on a straight line")
    plot!(p[2]; ylabel = "state of charge", xlabel = "time [min]")
    p
end

# ╔═╡ 7c8f87f4-00d0-40a9-b06c-6a9661ea1006
md"""
## 4. Regen on a hard stop

Build step 05's car on Lecture 3's straight ABS stop from 80 km/h: the driver asks for far more
braking than the tires carry, and `RegenBlend` gives the machine as much of it as the smallest of
three ceilings allows: its 320 N·m, the pack's 80.5 kW charge limit over the machine speed, and a
linear fade below 10 km/h. The rest goes to Lecture 3's friction brakes through the ABS. The same
stop with `P_charge = 0` brakes on friction alone. The dry default is `withdraw = 0`:
36.22 m, 49.32 % motor braking (176.9 kJ motor, 181.8 kJ friction), about half the stop.
ABS withdrawal remains opt-in pending the gentle ABS calibration #156. The guide demonstrates
`Vehicle.Planar.PlanarBEVLowGripStopTransient()` / `HandsOn04.BEVLowGripStopTransient()`
(default `withdraw = 1`, `stop = 28`), compared with `withdraw = 0, stop = 12`. Low-grip bench
measurements: 275.02 m enabled, minimum front slip −0.04931 above 3 m/s; 112.35 m disabled with
locked/reversing wheels, not a physical benchmark. WLTC is unchanged.
"""

# ╔═╡ 43682d73-077d-446a-9d02-3f704293fd1e
# Keep the dry envelope/deck figure explicit; the guide demonstrates withdrawal on low grip.
stop = (; on = PL.PlanarBEVHardStopTransient(withdraw = 0.0), off = PL.PlanarBEVHardStopTransient(P_charge = 0.0));

# ╔═╡ 7e8d1c4b-a689-45c1-b6f1-9e840a99baaf
"Speed against distance from the brake application at 0.5 s, and the distance to the first sample under 0.5 m/s."
function stop_trace(run)
    s, m = run.sol, symbolic_container(run)
    ts = collect(range(0.5, 6.0; length = 1101))
    v = s(ts; idxs = m.car.bus.vx).u
    x = s(ts; idxs = m.car.bus.x).u .- s(0.5; idxs = m.car.bus.x)
    i = findfirst(<(0.5), v)
    return (; x = x[1:i], kmh = 3.6 .* v[1:i], d = x[i])
end

# ╔═╡ 71f6cc67-7827-4bfd-b7d5-24c597140f58
regen_stop_plot = let
    s, m = stop.on.sol, symbolic_container(stop.on)
    tg = collect(0.65:0.002:3.6)
    v = s(tg; idxs = m.kmh.y).u
    regen = s(tg; idxs = m.blend.tau_regen).u
    vv = range(0.5, 82.0; length = 400)
    w = vv ./ 3.6 .* 8.193 ./ 0.31
    p = plot(; layout = grid(1, 2; widths = [0.55, 0.45]), size = (1100, 480))
    keep = 80.5e3 ./ w .<= 480.0
    plot!(p[1], vv, fill(320.0, length(vv)); color = :gray, ls = :dash, lw = 1.5, label = "")
    plot!(p[1], vv[keep], 80.5e3 ./ w[keep]; color = :gray, ls = :dot, lw = 1.5, label = "")
    plot!(p[1], [0.0, 10.0], [0.0, 320.0]; color = :gray, ls = :dashdot, lw = 1.5, label = "")
    plot!(p[1], v, regen; color = 1, lw = 3, label = "")
    v_corner = 80.5e3 / 320.0 * 0.31 / 8.193 * 3.6
    annotate!(p[1], [(60.0, 335.0, text("torque limit, 320 N·m", 10, :bottom)),
        (27.0, 440.0, text("charge power, 80.5 kW / ω", 10, :left)),
        (11.0, 120.0, text("fade below 10 km/h", 10, :left)),
        (62.0, 205.0, text("machine, regenerating", 10, :left, palette(:default)[1])),
        (v_corner - 1.0, 305.0, text("corner, $(round(v_corner; digits = 1)) km/h", 10, :right, :top))])
    plot!(p[1]; xlabel = "car speed [km/h]", ylabel = "braking torque at the machine [N·m]",
        ylims = (0, 480), xlims = (0, 82), legend = false,
        title = "The machine takes the smallest ceiling")
    a, b = stop_trace(stop.on), stop_trace(stop.off)
    plot!(p[2], b.x, b.kmh; color = 2, lw = 2.5, label = "")
    plot!(p[2], a.x, a.kmh; color = 1, lw = 2.5, label = "")
    annotate!(p[2], [(33.0, 4.0, text("regen + friction: $(round(a.d; digits = 1)) m", 10, :right, palette(:default)[1])),
        (33.0, 12.0, text("friction only: $(round(b.d; digits = 1)) m", 10, :right, palette(:default)[2]))])
    plot!(p[2]; xlabel = "distance from the pedal [m]", ylabel = "car speed [km/h]",
        legend = false, ylims = (0, 85), xlims = (0, 42), title = "Hard stop from 80 km/h")
    p
end

# ╔═╡ ad1a1d09-661d-44b0-8b60-3bd41905f501
split_plot = let
    kJ(run, x) = run.sol[getproperty(symbolic_container(run), x)][end] / 1e3
    names = ["machine, back through the reduction", "friction brakes", "tire slip"]
    on = [kJ(stop.on, :E_shaft_in), kJ(stop.on, :E_brake), kJ(stop.on, :E_tire)]
    off = [kJ(stop.off, :E_shaft_in), kJ(stop.off, :E_brake), kJ(stop.off, :E_tire)]
    share = round(100 * on[1] / (on[1] + on[2]); digits = 1)
    x = 1:3
    p = bar(x .- 0.2, on; bar_width = 0.38, color = 1, label = "regen + friction",
        size = (960, 420), xticks = (x, names), ylabel = "energy over the stop [kJ]",
        title = "Where the car's $(round(Int, stop.on.sol[symbolic_container(stop.on).E_kin][1] / 1e3)) kJ went: " *
                "the machine takes $(share) % of the braking")
    bar!(p, x .+ 0.2, off; bar_width = 0.38, color = 2, label = "friction only")
    annotate!(p, [(k - 0.2, v + 6, text("$(round(v; digits = 1))", 10, :bottom)) for (k, v) in zip(x, on)])
    annotate!(p, [(k + 0.2, v + 6, text("$(round(v; digits = 1))", 10, :bottom)) for (k, v) in zip(x, off)])
    ylims!(p, 0, 1.15 * max(maximum(on), maximum(off)))
    p
end

# ╔═╡ Cell order:
# ╟─f6acb09c-5c44-4121-9b81-595d773a3be3
# ╠═d733a7d0-135f-4ace-8f02-8159688077fe
# ╠═377ed78d-9288-4b91-8268-7d78999b47a2
# ╟─d91ae61d-5421-43d0-a222-edaa0839acdd
# ╠═2964dcd0-e985-4c5a-8f48-336c25d8936e
# ╠═3682b634-a0dd-4436-97fa-61a8499843a0
# ╟─bfdfb407-06cd-44bf-acbd-d56762c8e2dd
# ╟─17c1868c-da16-4f2f-ad4a-a2003a870851
# ╟─8c15e1f1-211b-4b8b-b43d-4c38d38bdfb3
# ╠═10962649-cde5-4bea-ab84-08874291b7a3
# ╟─3ef3be46-a5e3-4e27-a1d2-6b0a714ba563
# ╟─74586281-9ffa-41d6-b0bb-1ad008b39e1a
# ╟─f1508342-69b2-4bf5-9cc0-764009078ed2
# ╠═611c1b72-0377-41ce-9476-6dd3d9f96b83
# ╟─4e9ef33b-325f-4971-b2e8-86cad3875f70
# ╟─7c8f87f4-00d0-40a9-b06c-6a9661ea1006
# ╠═43682d73-077d-446a-9d02-3f704293fd1e
# ╠═7e8d1c4b-a689-45c1-b6f1-9e840a99baaf
# ╟─71f6cc67-7827-4bfd-b7d5-24c597140f58
# ╟─ad1a1d09-661d-44b0-8b60-3bd41905f501
