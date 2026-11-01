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

# ╔═╡ dcbb7dba-6a48-4fbe-bd9b-5834f3c82bfc
md"""
### Moving the line: voltage and field

The same machine in steady state, `di/dt = 0` and `dω/dt = 0`, with the flux scaled by the field
fraction *f*: *i* = (*V* − *f K*Φ ω)/*R*, and the shaft torque is *f K*Φ *i* less the loss torques
*T*<sub>f</sub> + *K*<sub>i</sub> + *k*<sub>w</sub>ω² + *C*/ω. Every parameter is read from the
350 V dyno run above, so this is the model's own steady-state line, not a second model. Lowering
*V* moves the line in speed and keeps its slope (*f K*Φ)²/*R*. Lowering *f* raises the no-load
speed *V*/(*f K*Φ) and flattens the slope, but each ampere now makes only *f K*Φ of torque.
"""

# ╔═╡ d5b55265-e6b5-46e4-8134-3cc84a5b7a82
steady = let
    s, m = dyno.r350.sol, symbolic_container(dyno.r350)
    ps = (; (n => s.ps[getproperty(m.machine, n)] for n in (:R, :k, :T_f, :K_i, :k_w, :C))...)
    tau_loss(w) = ps.T_f + ps.K_i + ps.k_w * w^2 + ps.C / w
    torque(V, f, w) = f * ps.k * (V - f * ps.k * w) / ps.R - tau_loss(w)
    a = dyno_line(dyno.r350)
    i = a.i[1]
    "Speed in rad/s and shaft torque where the line for `V`, `f` draws the current `i`."
    function at_current(V, f)
        w = (V - ps.R * i) / (f * ps.k)
        return (; w, tau = f * ps.k * i - tau_loss(w))
    end
    (; ps, torque, at_current, i_corner = i, check = torque(350.0, 1.0, a.rpm[1] * pi / 30) - a.tau[1])
end;

# ╔═╡ 9e32505e-671a-43ec-93e6-7f694ef2e43b
control_family_plot = let
    (; ps, torque, at_current, i_corner) = steady
    p = plot(; layout = (1, 2), size = (1100, 420), legend = false)
    rpm = range(100.0, 8000.0; length = 750)
    for (c, V) in enumerate((100.0, 200.0, 350.0))
        keep = rpm .<= rpm_of(V / ps.k) + 150
        plot!(p[1], rpm[keep], [torque(V, 1.0, r * pi / 30) for r in rpm[keep]]; color = c, lw = 2.5)
        q = at_current(V, 1.0)
        scatter!(p[1], [rpm_of(q.w)], [q.tau]; color = c, ms = 5)
        annotate!(p[1], [(rpm_of(V / ps.k) + 60, 70.0, text("$(round(Int, V)) V", 10, :left, palette(:default)[c]))])
    end
    hline!(p[1], [0.0]; color = :black, lw = 0.5)
    plot!(p[1]; xlabel = "machine speed [rpm]", ylabel = "shaft torque [N·m]", xlims = (0, 4000),
        ylims = (-150, 800), title = "Voltage V, full field: the line moves; dots $(round(i_corner; digits = 1)) A")
    for (c, f) in enumerate((1.0, 0.7, 0.5))
        keep = rpm .<= rpm_of(350.0 / (f * ps.k)) + 250
        plot!(p[2], rpm[keep], [torque(350.0, f, r * pi / 30) for r in rpm[keep]]; color = c, lw = 2.5)
        q = at_current(350.0, f)
        scatter!(p[2], [rpm_of(q.w)], [q.tau]; color = c, ms = 5)
        annotate!(p[2], [(rpm_of(q.w) + 120, q.tau, text("$(round(Int, q.tau)) N·m", 10, :left, palette(:default)[c])),
            (rpm_of(350.0 / (f * ps.k)) + 120, 70.0, text("f = $(f == 1 ? "1" : f)", 10, :left, palette(:default)[c]))])
    end
    hline!(p[2], [0.0]; color = :black, lw = 0.5)
    plot!(p[2]; xlabel = "machine speed [rpm]", ylabel = "shaft torque [N·m]", xlims = (0, 8000),
        ylims = (-150, 800), title = "Field f at 350 V: faster, less torque per ampere; " *
        "dots $(round(i_corner; digits = 1)) A")
    p
end

# ╔═╡ edd4e960-6800-4827-9ffc-fb0e2f9f6277
md"""
The steady-state line meets the dyno: at 3283 rpm on 350 V it differs from the simulated
torque by $(round(steady.check; sigdigits = 2)) N·m.
"""

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

# ╔═╡ 8e6a94b1-3c0e-4580-82a2-4c95ede53ad9
md"""
### Power costs efficiency

Every ampere the pack delivers costs `R₀ i` of its voltage, so the share of the cells' energy
that reaches the terminals is `η = v/E = 1 − R₀ i / E`, and the terminal power is
`P = E i − R₀ i²`. Both are read below from the same bench, held at one current after another.
The power peaks where `i = E / 2R₀`, at `E²/4R₀`, with half of the cells' energy lost in the
pack: past that point more current gives less power. On a Ragone chart (specific energy against
specific power) the same sweep is the pack's own trade-off: the faster it is emptied, the less
of its energy arrives. The pack mass is the Leaf ZE1's 303 kg (Nissan).
"""

# ╔═╡ 1fc9b799-840d-4df7-be5c-a3a2fdc535e0
ragone = let
    probe = E4.BatteryTransient(I_load = 100.0)
    ps, mp = probe.sol.ps, symbolic_container(probe)
    E, R0, Q = ps[mp.battery.E], ps[mp.battery.R0], ps[mp.battery.Q_nom]
    current(P) = (E - sqrt(E^2 - 4R0 * P)) / 2R0
    named = [current(10e3), current(117.25e3), E / 2R0]
    I = sort(vcat(collect(range(5.0, E / 2R0; length = 40)), named))
    pts = map(I) do i
        r = E4.BatteryTransient(I_load = i)
        s, m = r.sol, symbolic_container(r)
        v = s[m.battery.v][end]
        (; i, v, P = v * i, eta = v / E)
    end
    (; E, R0, Q, mass = 303.0, pts, named = [pts[findfirst(p -> p.i == i, pts)] for i in named])
end;

# ╔═╡ 6ab11e61-b97d-4872-917b-8fedab02f964
ragone_plot = let
    (; E, Q, mass, pts, named) = ragone
    P = [p.P for p in pts] ./ 1e3
    eta = [100 * p.eta for p in pts]
    p = plot(layout = (1, 2), size = (960, 440), legend = false)
    plot!(p[1], P, eta; color = 1, lw = 2.5, xlabel = "terminal power [kW]",
        ylabel = "energy efficiency v / E [%]", ylims = (45, 102), xlims = (0, 330),
        title = "η = 1 − R₀ i / E")
    scatter!(p[1], [n.P for n in named] ./ 1e3, [100 * n.eta for n in named]; color = 2, ms = 5)
    annotate!(p[1], [(n.P / 1e3 + (k == 3 ? -6 : 6), 100 * n.eta + (k == 3 ? 3 : 0),
        text("$(round(n.P / 1e3; digits = 1)) kW: $(round(100 * n.eta; digits = 1)) %", 10,
            k == 3 ? :right : :left)) for (k, n) in enumerate(named)])
    # Specific energy: the charge Q delivered at the terminal voltage, per kilogram of pack.
    Wh_kg = [p.v * Q / 3600 / mass for p in pts]
    W_kg = [p.P / mass for p in pts]
    plot!(p[2], W_kg, Wh_kg; color = 1, lw = 2.5, xscale = :log10, yscale = :log10,
        xlabel = "specific power [W/kg]", ylabel = "specific energy [Wh/kg]",
        title = "Ragone: the pack's own trade-off ($(round(Int, mass)) kg)",
        xticks = ([10, 30, 100, 300, 1000], ["10", "30", "100", "300", "1000"]),
        yticks = ([60, 80, 100, 120, 140], ["60", "80", "100", "120", "140"]),
        ylims = (60, 145))
    scatter!(p[2], [n.P / mass for n in named], [n.v * Q / 3600 / mass for n in named];
        color = 2, ms = 5)
    p
end

# ╔═╡ 9b9bff5f-8326-458a-ae99-ad3e0acb6ffe
let
    (; E, R0, named) = ragone
    r1(x) = round(x; digits = 1)
    rows = join(["| $(r1(n.P / 1e3)) | $(r1(n.i)) | $(r1(n.v)) | $(r1(100 * (1 - n.eta))) |"
                 for n in named], "\n")
    Markdown.parse("""
    | terminal power [kW] | current [A] | terminal voltage [V] | lost in R₀ [%] |
    |---:|---:|---:|---:|
    $rows

    A WLTC-like 10 kW costs the pack under 1 % of its energy; the machine's full input,
    117.25 kW (notebook 01's converter at the corner), costs about a tenth; and the most the
    pack can deliver, `E²/4R₀` = $(r1(E^2 / 4R0 / 1e3)) kW, costs half. A real pack's BMS stops
    far below that peak: INL measured a 30 s discharge capability of 103.3 kW at 80 % depth
    of discharge on a 2013 Leaf pack.
    """)
end

# ╔═╡ 7c8f87f4-00d0-40a9-b06c-6a9661ea1006
md"""
## 4. Regen on a hard stop

Build step 05's car on Lecture 3's straight ABS stop from 80 km/h: the driver asks for far more
braking than the tires carry, and `RegenBlend` gives the machine as much of it as the smallest of
three ceilings allows: its 320 N·m, the pack's 80.5 kW charge limit over the machine speed, and a
linear fade below 10 km/h. The rest goes to Lecture 3's friction brakes through the ABS. The same
stop with `P_charge = 0` brakes on friction alone: 26.94 m. The dry default enables withdrawal
(`withdraw = 1`): 27.102036224 m in 2.340 s after the pedal, machine/friction
2.951/348.908 kJ (0.839 % gross motor share), battery positive recovery 2.957 kJ.
The shared `ABSModulatorDiscrete` now uses its existing `k_inc_fast`/`k_inc_slow` build ramps
when `tau_lock < tau_memory_min` (1 N·m, assumed); otherwise memory-scaled reapply,
release memory and decrement are unchanged, with the threshold tagged (assumed). The stop is 0.16414 m
(0.61 %) longer than friction alone, inside the `<= 1.01 * friction_distance` regression.
The meaningful motor-share goal is NOT met: blanket front-active withdrawal suppresses regen
almost throughout. With `withdraw = 0`: 27.238292677 m, 2.425 s, 28.7 % gross motor share,
but minimum front slip −5.893705 above 3 m/s means reversed wheels, not a physical regen
benchmark. Keep the rule ON: shorter and keeps slip above −0.2 while vx > 3 m/s (front/rear slip −0.126072/−0.090554).
Low grip with withdrawal (`stop = 12`): 87.594615426 m, 7.665 s after pedal, minimum
front/rear slip −0.187106/−0.104377 above 3 m/s. Off: 95.098241553 m and reversed wheels
(minimum front slip −17.35918), not a physical benchmark. Use 12 s for both low-grip benches:
20 s fails during parking at 15.835 s, after stopping at 8.165 s absolute. HandsOn
low-grip is 87.604052512 m (Success, `stop = 12`). WLTC is unchanged (23.85 %,
34.25 Wh/km recovered, 131.15 Wh/km consumption).
"""

# ╔═╡ 43682d73-077d-446a-9d02-3f704293fd1e
# Use the coordinated dry default; the hardware envelope remains visible as reference curves.
stop = (; on = PL.PlanarBEVHardStopTransient(), off = PL.PlanarBEVHardStopTransient(P_charge = 0.0));

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
        title = "ABS withdrawal scales the hardware envelope")
    a, b = stop_trace(stop.on), stop_trace(stop.off)
    plot!(p[2], b.x, b.kmh; color = 2, lw = 2.5, label = "")
    plot!(p[2], a.x, a.kmh; color = 1, lw = 2.5, label = "")
    xmax = 1.15 * max(a.d, b.d)
    x_label = min(a.d, b.d) - 1.5
    annotate!(p[2], [(x_label, 4.0, text("regen + friction: $(round(a.d; digits = 1)) m", 10, :right, palette(:default)[1])),
        (x_label, 12.0, text("friction only: $(round(b.d; digits = 1)) m", 10, :right, palette(:default)[2]))])
    plot!(p[2]; xlabel = "distance from the pedal [m]", ylabel = "car speed [km/h]",
        legend = false, ylims = (0, 85), xlims = (0, xmax), title = "Hard stop from 80 km/h")
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
# ╟─dcbb7dba-6a48-4fbe-bd9b-5834f3c82bfc
# ╠═d5b55265-e6b5-46e4-8134-3cc84a5b7a82
# ╟─9e32505e-671a-43ec-93e6-7f694ef2e43b
# ╟─edd4e960-6800-4827-9ffc-fb0e2f9f6277
# ╟─8c15e1f1-211b-4b8b-b43d-4c38d38bdfb3
# ╠═10962649-cde5-4bea-ab84-08874291b7a3
# ╟─3ef3be46-a5e3-4e27-a1d2-6b0a714ba563
# ╟─74586281-9ffa-41d6-b0bb-1ad008b39e1a
# ╟─f1508342-69b2-4bf5-9cc0-764009078ed2
# ╠═611c1b72-0377-41ce-9476-6dd3d9f96b83
# ╟─4e9ef33b-325f-4971-b2e8-86cad3875f70
# ╟─8e6a94b1-3c0e-4580-82a2-4c95ede53ad9
# ╠═1fc9b799-840d-4df7-be5c-a3a2fdc535e0
# ╟─6ab11e61-b97d-4872-917b-8fedab02f964
# ╟─9b9bff5f-8326-458a-ae99-ad3e0acb6ffe
# ╟─7c8f87f4-00d0-40a9-b06c-6a9661ea1006
# ╠═43682d73-077d-446a-9d02-3f704293fd1e
# ╠═7e8d1c4b-a689-45c1-b6f1-9e840a99baaf
# ╟─71f6cc67-7827-4bfd-b7d5-24c597140f58
# ╟─ad1a1d09-661d-44b0-8b60-3bd41905f501
