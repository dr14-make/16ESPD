### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 70ca7453-e2e9-5fa4-a2a9-af10ca7b3eba
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, "..", ".."))
    include(joinpath(@__DIR__, "..", "lecture01", "support.jl"))
    using .Lecture01Support
    components = setup()
    using ModelingToolkit, Plots
    using DyadInterface: symbolic_container
    using PlutoUI
    include(joinpath(@__DIR__, "support.jl"))
    using .RoadsterSupport
    Plots.default(size = (900, 420))
    Roadster = components.Roadster
    nothing
end

# ╔═╡ b519eab0-5aed-5d96-9f02-4c18458705d3
md"""
# Tesla Roadster: is it physically possible?

On 2026-10-15 Tesla unveiled the new Roadster at SpaceX's McGregor test site: a sub-second
0–60 mph, a car stuck to a ramp curling past vertical, and a kickflip over a row of cars. The
session question is simple: **which of these claims survive Newton, a tire and a tank of air?**

We answer it one layer at a time on the same 1D car: tires, then suction, then thrust, then
"can it fly?".

*Start with `julia +dyad-3.4.0 notebooks/roadster/present.jl`. Pluto's worker processes cannot
load the Dyad packages with this Julia build, so the launcher runs the notebook in its own
process.*
"""

# ╔═╡ c54392d6-d24f-54c8-8e3d-e9c893d7f2b4
html"<button onclick='present()'>present</button>"

# ╔═╡ 8356f8de-1589-5f84-9769-f90f600c385a
md"""
**Car** · mass [kg] $(@bind m_car Slider(1700:50:2350; default = 2000, show_value = true)) · drive $(@bind drive_layout Select(["RWD", "AWD"]))
"""

# ╔═╡ e3e16d90-e0a7-5499-89ad-ec3ffac00c74
car_panel_style("8356f8de-1589-5f84-9769-f90f600c385a")

# ╔═╡ 0642455c-1da3-51e6-81ff-e990d6acb591
begin
    car = (; m = m_car, LAYOUTS[drive_layout]...)
    other_layout = drive_layout == "RWD" ? "AWD" : "RWD"
    nothing
end

# ╔═╡ 40ef78e6-32c9-5c2d-9f7e-b2839b5a029d
md"""
## What Tesla showed on 2026-10-15

- **0–60 mph:** one recorded run in **1.0 s**, a live run in **0.81 s** (timer problems were
  reported).
- **Three trims:** Performance (suction fans) **under 1.6 s**, Thrust (adds rear thrusters)
  **under 0.9 s**, Rocket (10 thrusters) **under 0.59 s**.
- **The ramp:** suction fans hold the car on a ramp past vertical; an on-screen readout shows
  **4,700 kg of downforce**.
- **The kickflip:** the car jumps a row of cars while rolling 360°, on cold-gas thrusters fed by
  **600 L of compressed air**.
- **"It can fly":** what was shown were hops, flips and short hovers.

**Session question:** is each claim physically possible, and what does it cost?
"""

# ╔═╡ d1e686ea-7b9d-50b5-8585-e5b5bd5a5077
md"""
## The presentation videos

Tesla's official clips. Offline, follow the links instead:
[The Ramp | Roadster](https://www.youtube.com/watch?v=7p5LxFdc-Qg) ·
[The Kickflip | Roadster](https://www.youtube.com/watch?v=r5vsHHPVhJg).
"""

# ╔═╡ d3171829-f6d6-55d0-b2eb-713d6ad7a265
html"""
<div style="display:flex;gap:10px;flex-wrap:wrap">
<iframe style="flex:1 1 300px;aspect-ratio:16/9;border:0" src="https://www.youtube-nocookie.com/embed/7p5LxFdc-Qg" title="The Ramp | Roadster" allow="encrypted-media; picture-in-picture; fullscreen" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
<iframe style="flex:1 1 300px;aspect-ratio:16/9;border:0" src="https://www.youtube-nocookie.com/embed/r5vsHHPVhJg" title="The Kickflip | Roadster" allow="encrypted-media; picture-in-picture; fullscreen" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
</div>
"""

# ╔═╡ 4878a8af-4114-5065-9da2-89b1959677b6
md"""
## Theory: Newton and the tire

Newton's second law for the car, with the tire force ``F_x`` as the only push:

```math
m\,a = F_x - \tfrac12 \rho\, C_dA\, v^2 - f_r\, m g, \qquad F_x \le \mu\, F_z .
```

Accelerating moves load onto the rear axle. With a share ``s`` of the weight on the driven axle
and center-of-mass height over wheelbase ``h/L``,

```math
F_z = s\,m g + m a\,\frac{h}{L}
\quad\Rightarrow\quad
\frac{a}{g} = \frac{\mu\, s}{1 - \mu\, h/L}.
```

All-wheel drive is ``s = 1``, ``h/L = 0``, so ``a = \mu g``. At ``\mu = 1.26``: about
**1.2 g** with AWD and **0.86 g** with RWD. A 1 s run to 60 mph needs **2.7 g** on average.
"""

# ╔═╡ 77eacb86-0353-5834-9197-a332cd647a50
md"""
## Theory: the power limit

Energy sets a floor on the time, whatever the tires:

```math
P\,t \ge \tfrac12 m v^2 \quad\Rightarrow\quad t \ge \frac{m v^2}{2P} = 0.72\ \text{s}
\quad (2{,}000\ \text{kg},\ 1\ \text{MW},\ 60\ \text{mph}).
```

The traction ceiling ``\mu m g`` is flat; the power ceiling ``P/v`` falls with speed. They cross at

```math
v^\ast = \frac{P}{\mu\, m g} \approx 40\ \text{m/s} \;>\; 26.8\ \text{m/s} = 60\ \text{mph},
```

so on tires the whole 0–60 run is traction-limited. A third ceiling is the drive torque:
``T_{max}/r = 12{,}000/0.35 = 34.3`` kN, which is **1.75 g**.
"""

# ╔═╡ 8bfba8d7-c0b7-5416-814c-d951af9cddf7
md"""
## Theory: suction downforce

A fan lowers the pressure under the floor by ``\Delta p``. The road pushes back with

```math
D = \Delta p\, A, \qquad F_z = s\,(m g + D) + m a\,\frac{h}{L}.
```

Unlike a wing, ``D`` does not need speed. The 4,700 kgf readout over 4 m² is
``\Delta p = 11.5`` kPa. Air leaks in under the skirt, and the fan has to pump it out:

```math
Q = C_d \cdot \text{perimeter} \cdot \text{gap} \cdot \sqrt{2\Delta p/\rho},
\qquad P_{fan} = \frac{Q\,\Delta p}{\eta}.
```

Fan power grows linearly with the gap and as ``\Delta p^{3/2}``.
"""

# ╔═╡ 1837c786-5be9-5433-9592-fa23679aa51f
md"""
## Theory: cold gas

The tank empties along a polytropic path, ``n = 1.4`` adiabatic and ``n = 1`` isothermal:

```math
\frac{p}{p_0} = \Big(\frac{m}{m_0}\Big)^{n}, \qquad \frac{T}{T_0} = \Big(\frac{m}{m_0}\Big)^{n-1}.
```

The nozzle throat is choked, and the gas expands to ambient pressure:

```math
\dot m = A_t\, p \sqrt{\frac{\gamma}{R T}} \Big(\frac{2}{\gamma+1}\Big)^{\frac{\gamma+1}{2(\gamma-1)}},
\qquad
v_e = \sqrt{2 c_p T \Big(1 - (p_a/p)^{\frac{\gamma-1}{\gamma}}\Big)},
\qquad F = \dot m\, v_e .
```

At 380 bar and 20 °C: ``\dot m = 115`` kg/s and ``v_e = 693`` m/s give 80 kN. The 271 kg of
air would last 2.3 s at that rate, but the thrust falls as the pressure does.
"""

# ╔═╡ 9e4e98b3-0b60-5d19-875e-ba9acad48fe5
md"""
## Theory: hop and hover

A ballistic hop to height ``h`` needs a take-off speed, and so an impulse:

```math
v = \sqrt{2 g h} = 12.5\ \text{m/s for } 8\ \text{m}, \qquad
m_{air} \approx \frac{m\,v}{v_e} + \text{gravity loss during the burn}.
```

Hovering means thrust equals weight, so the air flow is fixed by the exhaust speed:

```math
\dot m = \frac{m g}{v_e} \approx \frac{2{,}000 \cdot 9.81}{693} = 28\ \text{kg/s},
\qquad t_{hover} \approx \frac{\text{usable air}}{\dot m}.
```
"""

# ╔═╡ d73c9887-b6d8-5fad-9d96-d7566fc823bb
md"""
## Knowns and unknowns

**T** Tesla said it · **P** press report, not confirmed by Tesla · **M** measured or estimated by a
third party · **?** unknown.
"""

# ╔═╡ b80af6e2-b5e3-5bdd-97dd-0a6ecf66c074
html_table(["Item", "Value", "Source"], [
    ("0–60 mph claims", "Performance < 1.6 s, Thrust < 0.9 s, Rocket < 0.59 s", "**T**"),
    ("0–60 mph runs", "1.0 s recorded, 0.81 s live", "**T**"),
    ("Thrusters", "10 cold-gas thrusters, 600 L of air in COPVs", "**T**"),
    ("Downforce", "4,700 kg readout; holds the car inverted", "**T**"),
    ("Tire grip limit", "1.26 g", "**P**"),
    ("Rear thrust", "over 80 kN from 4 rear ports", "**P**"),
    ("Air mass", "about 250 kg; Electrek splits 200 L Thrust + 400 L Rocket", "**P**"),
    ("Tank pressure", "380 bar (5,500 psi cabin readout) **vs** 690 bar (10,000 psi, Electrek)", "**P**, conflicting"),
    ("Drive", "RWD, 2 rear motors, over 1 MW, about 1,400 N·m", "**P**"),
    ("Fans", "about 4 × 20 kW", "**M**"),
    ("Mass", "under 1,700 kg (Electrek), about 1,900 kg, about 2,350 kg (CellCog)", "**M**, conflicting"),
    ("Video fits", "kickflip apex 8.0 m, roll 177 °/s; ramp early fall 2.3 g", "**M**"),
    ("Not disclosed", "mass, tank pressure, battery capacity, thrust per nozzle, gear ratio", "**?**"),
]; widths = ["22%", "58%", "20%"])

# ╔═╡ 6db050a1-68fc-5767-abf9-74ddea7261d8
md"""
## What the models assume for the unknowns
"""

# ╔═╡ 1bf3759a-417c-5ada-8ebd-6a35dad71f88
html_table(["Unknown", "Model value", "Why"], [
    ("Mass", "**2,000 kg**, slider 1,700–2,350", "middle of the estimates"),
    ("Drive", "12,000 N·m at the wheel, 1 MW, r = 0.35 m", "1,400 N·m × an assumed 8.5:1 reduction"),
    ("Tire", "`μ_A = 1.26`, traction control at 98 % of peak", "Tesla's figure, ideal controller"),
    ("Layout", "RWD: 55 % rear, h/L = 0.17; AWD for comparison", "assumed geometry"),
    ("Drag", "`C_dA = 0.6` m²", "assumed"),
    ("Fan", "4 m² floor, 10 m skirt, 3 mm gap, `C_d = 0.6`, `η = 0.6`", "assumed; Δp sized to 4,700 kgf"),
    ("Tank", "600 L at **380 bar**, 20 °C, ideal gas: 271 kg", "the cabin readout; 271 kg is close to the reported 250 kg"),
    ("Blowdown", "n = 1.4 (adiabatic), slider down to 1", "the conservative bound"),
    ("Nozzles", "1,286 mm² total throat, 80 kN at 380 bar, valve shut below 2 bar", "sized to the 80 kN figure"),
    ("Hover", "PI altitude hold to 2 m with gravity feed-forward", "assumed gains"),
]; widths = ["16%", "46%", "38%"])

# ╔═╡ b6d7b622-21c6-550c-948d-f5cfb96bf5f1
md"""
## Technology used

- **Tires.** Pirelli P Zero Trofeo RS "Elect" (press report). A tire pushes at most ``\mu F_z``,
  and it reaches that at a few percent of slip; past the peak it slides and grips less.
- **Rear drive units.** Two rear motors with torque vectoring, over 1 MW (press report). The
  reduction gear multiplies motor torque at the wheel; power caps it at speed.
- **Suction fans and skirts.** Fans pump air out from under the floor while flexible skirts
  seal the edge. The idea raced on the Chaparral 2J and the Brabham BT46B.
- **COPV tanks.** Composite-overwrapped pressure vessels: a thin liner wrapped in carbon fiber,
  light for the pressure they hold. Tesla quotes 600 L, rechargeable.
- **Cold-gas nozzles.** Compressed air expands through a nozzle with no combustion, so the
  exhaust is slow: about 700 m/s, against about 3,000 m/s for a rocket engine.
- **Valves.** Electrically actuated valves set the open throat area, and with it the flow and
  the thrust.
"""

# ╔═╡ 0a85f4c7-90ac-595f-b127-8474860e03df
md"""
## Warm-up: is the ramp video real time?

Gravity is a clock. A clip played ``k`` times too fast shows every acceleration ``k^2`` times
too large, so a free fall that measures ``a`` on screen gives ``k = \sqrt{a/g}``.

Third-party frame-by-frame fits (15–20 % scale error): the early fall in the ramp's main shot is
**2.3 g**, and the kickflip's flight is **0.92 g**.

playback factor k $(@bind k_play Slider(0.8:0.02:2.0; default = 1.0, show_value = true))
"""

# ╔═╡ 532b5431-9db1-5e77-b0bc-66f8324ca14c
warmup = (k_ramp = sqrt(2.3), k_kick = sqrt(0.92));

# ╔═╡ 213033f3-32af-536b-a121-8c95e70f4fd0
let
    tv = range(0, 0.8; length = 100)
    plt = plot(tv, 0.5 .* 2.3 .* G0 .* tv .^ 2; lw = 3, color = :black,
        label = "ramp shot, measured 2.3 g", xlabel = "video time [s]",
        ylabel = "fall distance [m]", legend = :topleft,
        title = "A real 1 g fall, played $(k_play)× fast")
    plot!(plt, tv, 0.5 .* G0 .* (k_play .* tv) .^ 2; lw = 3, ls = :dash, color = :steelblue,
        label = "1 g at k = $(k_play)")
    plt
end

# ╔═╡ 796e0f71-bc73-545d-8bc1-3375d8be9bcd
Markdown.parse("""
The ramp's main shot fits a real fall at **k = √2.3 = $(fmt(warmup.k_ramp))**: it plays about
1.5× fast. The kickflip gives k = $(fmt(warmup.k_kick)), close to real time. Speeds read off the
ramp shot must be divided by k, accelerations by k².
""")

# ╔═╡ f1915dd8-39d0-536a-aa80-ecdf6c56bfb1
md"""
## On paper: tires alone

The time to 60 mph at constant acceleration, ``t_{60} = v_{60}/a``, with ``a/g`` from the
weight-transfer formula and the traction controller's 98 % of peak. No drag, no wheel inertia.
"""

# ╔═╡ ed540754-92a5-512d-ad4e-3ffb141b2bf1
let
    grip = 0.98
    mu = range(0.8, 3.0; length = 200)
    a_awd = grip .* mu
    a_rwd = grip .* mu .* 0.55 ./ (1 .- grip .* mu .* 0.17)
    a_needed = V60 / G0
    mu_awd = a_needed / grip
    mu_rwd = a_needed / (grip * (0.55 + 0.17 * a_needed))
    plt = plot(mu, V60 ./ (a_rwd .* G0); lw = 3, color = :firebrick, label = "RWD",
        xlabel = "peak friction coefficient μ", ylabel = "t60 [s]", ylims = (0, 5),
        legend = :topright,
        title = "1 s needs μ ≈ $(fmt(mu_rwd, 1)) (RWD) or $(fmt(mu_awd, 1)) (AWD)")
    plot!(plt, mu, V60 ./ (a_awd .* G0); lw = 3, color = :steelblue, label = "AWD")
    hline!(plt, [1.0]; color = :black, ls = :dash, label = "1 s")
    hline!(plt, [1.6]; color = :gray, ls = :dot, label = "1.6 s (Performance)")
    vline!(plt, [1.26]; color = :seagreen, label = "μ = 1.26 (Tesla)")
    plt
end

# ╔═╡ 4e611ec9-824a-51e9-a0e7-f9a838886b26
md"""
## On paper: fan power and the skirt gap

``P_{fan} = C_d \cdot \text{perimeter} \cdot \text{gap} \cdot \sqrt{2\Delta p/\rho}\;\Delta p/\eta``
with the model's floor (4 m², 10 m of skirt, ``C_d = 0.6``, ``\eta = 0.6``).
"""

# ╔═╡ 343a4f81-c535-5cb3-9f9a-f772db3232b8
let
    gap_mm = range(1, 10; length = 100)
    dp_full = 4700 * G0 / 4.0
    dp_hold = 2000 * G0 / 4.0
    kW(dp, g) = fan_power_closed_form(dp, g / 1e3) / 1e3
    plt = plot(gap_mm, kW.(dp_full, gap_mm); lw = 3, color = :steelblue,
        label = "full suction, Δp = 11.5 kPa (4,700 kgf)", xlabel = "skirt gap [mm]",
        ylabel = "fan power [kW]", legend = :topleft,
        title = "The skirt gap sets the power bill")
    plot!(plt, gap_mm, kW.(dp_hold, gap_mm); lw = 3, color = :seagreen,
        label = "least Δp to hang 2,000 kg upside down, 4.9 kPa")
    hline!(plt, [80]; color = :gray, ls = :dot, label = "4 × 20 kW (Electrek estimate)")
    scatter!(plt, [3, 10], kW.(dp_full, [3, 10]); color = :black, label = "")
    annotate!(plt, [(3.3, kW(dp_full, 3) + 8, text("$(fmt(kW(dp_full, 3), 0)) kW", 9, :left)),
        (9.7, kW(dp_full, 10) - 10, text("$(fmt(kW(dp_full, 10), 0)) kW", 9, :right))])
    plt
end

# ╔═╡ ee1415ba-6b38-50d9-9750-c5206bd25efe
md"""
## On paper: thrust over time

With ``x = m/m_0``, choked flow gives ``\dot m = \dot m_0\, x^{(n+1)/2}``. That integrates in
closed form, so the whole thrust curve needs no simulation:

```math
x(t) = \Big(1 + \frac{n-1}{2}\,\frac{t}{\tau}\Big)^{-\frac{2}{n-1}},
\qquad \tau = \frac{m_0}{\dot m_0} \approx 2.35\ \text{s},
\qquad F = \dot m_0\, x^{\frac{n+1}{2}}\, v_e(x).
```
"""

# ╔═╡ d4f691bf-86ac-511b-b547-b9a1418ebea8
let
    ts = range(0, 4; length = 801)
    curve(; kw...) = [blowdown_closed_form(t; kw...).F / 1e3 for t in ts]
    below(F) = ts[findfirst(<(0.8 * F[1]), F)]
    base = curve()
    plt = plot(ts, base; lw = 3, color = :black, label = "380 bar, n = 1.4",
        xlabel = "time [s]", ylabel = "thrust [kN]", legend = :topright,
        title = "80 kN is a peak: below 80 % after $(fmt(below(base))) s")
    plot!(plt, ts, curve(n = 1.0); lw = 2, color = :steelblue, label = "380 bar, n = 1")
    plot!(plt, ts, curve(p0 = 690e5); lw = 2, color = :firebrick, label = "690 bar, same throat")
    hline!(plt, [64]; color = :gray, ls = :dot, label = "80 % of 80 kN")
    plt
end

# ╔═╡ 27ec9782-781e-5398-b0c1-5d0906183bb9
md"""
## On paper: hover time against mass

Hovering burns ``\dot m = m g / v_e``. Integrating over the air in the tank, until the
wide-open thrust can no longer carry ``m g``:
``t_{hover} = \frac{m_0}{m g}\int_{x_{min}}^{1} v_e(x)\,dx``.
The throat stays at its 80 kN size, so a higher pressure also starts with more thrust.
"""

# ╔═╡ 65410189-b0b1-5e52-b267-63adb383edc6
let
    masses = range(1500, 2600; length = 56)
    plt = plot(xlabel = "car mass [kg]", ylabel = "hover time [s]", legend = :topright,
        title = "Seconds, not minutes", ylims = (0, 12))
    vspan!(plt, [1700, 2350]; color = :gray, alpha = 0.15, label = "mass estimates")
    for (p0, color) in ((300e5, :steelblue), (380e5, :black), (690e5, :firebrick))
        plot!(plt, masses, hover_closed_form.(masses; p0); lw = 3, color,
            label = "600 L at $(round(Int, p0 / 1e5)) bar")
    end
    plt
end

# ╔═╡ f1ce64c1-2d6f-5c29-9ba3-ed6dbb15ddc3
md"""
## Simulations: the Dyad models

From here on the numbers come from Dyad models in `dyad/Roadster/`. Each model is built once
when the notebook loads. A slider then changes parameters on the built problem (`remake`) and
re-solves it with the analysis's own tolerances, in milliseconds.

The car panel in the bottom-right corner sets the mass and the drive layout for every section;
the scoreboard above it compares each claim with the model.
"""

# ╔═╡ 95427193-c160-57c3-b436-5cf573efc3bc
begin
    build_start = time()
    launch_rig = Rig(:launch, Roadster.RoadsterLaunchTransient)
    stand_rig = Rig(:stand, Roadster.ColdGasThrustStandTransient)
    hold_rig = Rig(:hold, Roadster.SuctionFanInvertedHoldTransient)
    hop_rig = Rig(:hop, Roadster.Hop; t_b = 0.413)
    hover_rig = Rig(:hover, Roadster.Hover)
    # The first remake of each problem compiles its solve path; pay for it here, not on a slider.
    solve_with(launch_rig; m = 2000)
    solve_with(stand_rig; p0 = 380e5)
    solve_with(hold_rig; m = 2000)
    solve_with(hop_rig; t_b = 0.413)
    solve_with(hover_rig; m = 2000)
    build_seconds = time() - build_start
    md"*Models built in $(fmt(build_seconds, 0)) s.*"
end

# ╔═╡ 4840cb3d-63a4-519e-b5e9-3cb89de6a41b
reference = let
    sys = launch_rig.sys
    run_case(cfg) = let sol = solve_with(launch_rig; cfg...), t = t60(sol, sys)
        (; sol, t60 = t, air = air_used(sol, sys, t))
    end
    (
        rwd = (sol = launch_rig.default, t60 = t60(launch_rig.default, sys)),
        awd = run_case(LAYOUTS["AWD"]),
        suction = run_case((; fan_cmd = 1.0)),
        tires_thrust = run_case((; thrust_cmd = 1.0)),
        suction_thrust = run_case((; thrust_cmd = 1.0, fan_cmd = 1.0)),
        thrust_200l = run_case((; thrust_cmd = 1.0, fan_cmd = 1.0, tank_volume = 0.2)),
    )
end;

# ╔═╡ bb74c430-4f14-5088-bcf4-a82715e51758
down_grid = let
    fractions = collect(0.0:0.05:1.0)
    curves = map([("RWD", 0.0), ("RWD", 1.0), ("AWD", 0.0), ("AWD", 1.0)]) do (lay, fan)
        times = [t60(solve_with(launch_rig; thrust_cmd = 1.0, fan_cmd = fan, down_fraction = d,
            LAYOUTS[lay]...), launch_rig.sys) for d in fractions]
        (; layout = lay, fan_cmd = fan, t60 = times, best = fractions[argmin(times)])
    end
    (; fractions, curves)
end;

# ╔═╡ f8dc7c02-1ddb-5ae9-b536-1c2c2679a8fb
hover_grid = let
    masses = (1700, 2000, 2350)
    pressures = (300, 380, 690)
    times = [hover_time(solve_with(hover_rig; m, tank_pressure = p * 1e5), hover_rig.sys)
             for m in masses, p in pressures]
    (; masses, pressures, times)
end;

# ╔═╡ f260e1c6-2e3d-5709-bc2b-16b4bd5a8abf
md"""
## Simulation 1: tires only

`RoadsterLaunch` with the fan and the valves off: a torque- and power-limited drive, a traction
controller that asks for 98 % of the tire's peak, and the driven-axle load from `AxleLoad`. The
other drive layout is the gray ghost.

`μ_A` $(@bind mu_A Slider(1.0:0.02:1.6; default = 1.26, show_value = true)) ·
`P_max` [MW] $(@bind P_MW Slider(0.5:0.1:2.0; default = 1.0, show_value = true)) ·
`C_dA` [m²] $(@bind CdA Slider(0.3:0.05:1.2; default = 0.6, show_value = true))
"""

# ╔═╡ abae1e2d-05e7-57ce-94c1-ccf3253dde53
dyad_fold("AxleLoad", "TractionControl", "PowerLimitedMotor")

# ╔═╡ 112888f3-ea48-57b3-b534-15f0aaf2bb32
tires = let
    t_start = time()
    cfg = (; mu_A, P_max = P_MW * 1e6, CdA)
    sol = solve_with(launch_rig; car..., cfg...)
    ghost = solve_with(launch_rig; m = car.m, LAYOUTS[other_layout]..., cfg...)
    t = t60(sol, launch_rig.sys)
    (; sol, ghost, t60 = t, t60_ghost = t60(ghost, launch_rig.sys),
        limits = binding_limit(sol, launch_rig.sys; until = min(t, 6.0)),
        ms = 1000 * (time() - t_start))
end;

# ╔═╡ 481ffd01-b7ce-5a10-83be-4a9908d528c4
let
    sys = launch_rig.sys
    plt = plot(tires.ghost.t, 3.6 .* tires.ghost[sys.v]; lw = 2, color = :gray, alpha = 0.6,
        label = "$(other_layout): $(fmt(tires.t60_ghost)) s", xlabel = "time [s]",
        ylabel = "speed [km/h]", xlims = (0, 4), ylims = (0, 130), legend = :bottomright,
        title = "0–60 mph on tires alone")
    plot!(plt, tires.sol.t, 3.6 .* tires.sol[sys.v]; lw = 3, color = :steelblue,
        label = "$(drive_layout): $(fmt(tires.t60)) s")
    hline!(plt, [3.6 * V60]; color = :black, ls = :dot, label = "60 mph")
    vline!(plt, [1.0]; color = :darkorange, ls = :dash, label = "Tesla, recorded: 1.0 s")
    vline!(plt, [0.81]; color = :firebrick, ls = :dash, label = "Tesla, live: 0.81 s")
    plt
end

# ╔═╡ ca3eb955-a7dc-5d89-aabc-fdee7a2c596b
Markdown.parse("""
**Verdict: no.** $(drive_layout) takes **$(fmt(tires.t60)) s** and $(other_layout)
$(fmt(tires.t60_ghost)) s. The tire sets the wheel torque for
$(fmt(100 * tires.limits.tire, 0)) % of the run. Power and drag barely move the time: below
60 mph grip is the limit, and the mass cancels because grip and inertia both scale with it.
*Re-solved in $(fmt(tires.ms, 0)) ms.*
""")

# ╔═╡ 44ec27a2-ce80-5e03-af44-7104307276d6
md"""
## The limit map

Force at the wheel against speed, with three ceilings: the tire ``\mu_A F_z``, the torque cap
``T_{max}/r`` and the power cap ``P_{max}/(\omega r)``. The car gets the lowest one. On tires
alone the tire line sits well under both drive caps all the way to 60 mph.
**Next:** raise the tire line with suction.
"""

# ╔═╡ ca0bd79d-2962-5f45-93f1-af7cbd159796
limit_map(tires.sol, launch_rig.sys; until = min(tires.t60, 6.0),
    title = "Tires only, $(drive_layout): the tire binds")

# ╔═╡ d2b00eee-ac62-5585-9237-78aba3ec9489
md"""
## Simulation 2: suction

The same car with `SuctionFan` on. The fan is at full pressure before the launch, its downforce
loads the driven axle and the rolling resistance, and its power follows from the skirt leakage.

fan command $(@bind fan_cmd Slider(0.0:0.05:1.0; default = 1.0, show_value = true)) ·
skirt gap [mm] $(@bind gap_mm Slider(1.0:0.5:10.0; default = 3.0, show_value = true)) ·
`T_max` [kN·m] $(@bind T_kNm Slider(8:1:20; default = 12, show_value = true))
"""

# ╔═╡ 68175a2d-7eea-5582-ba04-fe7751ce648d
dyad_fold("SuctionFan")

# ╔═╡ 3a2db6cd-e77b-548c-b081-6b3feb62e936
suction = let
    t_start = time()
    sol = solve_with(launch_rig; car..., fan_cmd, skirt_gap = gap_mm / 1e3, T_max = 1e3 * T_kNm)
    # The harness's least-command default does not follow `m`, so it is set from m·g over the
    # full-suction downforce of 4,700 kgf.
    hold_sol = solve_with(hold_rig; m = car.m, gap = gap_mm / 1e3, cmd = car.m / 4700)
    sys = launch_rig.sys
    t = t60(sol, sys)
    (; sol, t60 = t, limits = binding_limit(sol, sys; until = min(t, 6.0)),
        fan_power = sol(0.0, idxs = sys.fan.power), downforce = sol(0.0, idxs = sys.fan.downforce),
        hold_dp = hold_sol(0.0, idxs = hold_rig.sys.fan.dp),
        hold_power = hold_sol(0.0, idxs = hold_rig.sys.fan.power),
        hold_margin = sol(0.0, idxs = sys.fan.downforce) / (car.m * G0),
        ms = 1000 * (time() - t_start))
end;

# ╔═╡ 71b6de44-ece9-5e3f-ad46-e1a5f649b945
limit_map(suction.sol, launch_rig.sys; until = min(suction.t60, 6.0),
    title = "Suction, $(drive_layout): t60 = $(fmt(suction.t60)) s")

# ╔═╡ 138ea814-3a72-52c2-942f-bbaae57968a0
let
    l = suction.limits
    binding = l.torque >= max(l.tire, l.power) ? "the drive torque" :
              l.tire >= l.power ? "the tire" : "the power"
    Markdown.parse("""
    **Verdict: yes.** **$(fmt(suction.t60)) s** against Tesla's "under 1.6 s"; the limit is
    $(binding) ($(fmt(100 * l.torque, 0)) % torque, $(fmt(100 * l.tire, 0)) % tire,
    $(fmt(100 * l.power, 0)) % power). With suction, μ stops mattering and torque, power and mass
    take over. *Re-solved in $(fmt(suction.ms, 0)) ms.*
    """)
end

# ╔═╡ a3d6b00c-9a9c-5405-a396-0c3f88a25de3
md"""
## Suction: the power bill and the inverted hold

The skirt gap does not change the launch time at all: it only changes what the fan costs.
The dot is the fan in the launch model at the current gap and command.
"""

# ╔═╡ c46c6e9a-7269-5b19-8662-d14ef54554ad
let
    gaps = range(1, 10; length = 100)
    dp = fan_cmd * 4700 * G0 / 4.0
    plt = plot(gaps, fan_power_closed_form.(dp, gaps ./ 1e3) ./ 1e3; lw = 3, color = :steelblue,
        label = "closed form, Δp = $(fmt(dp / 1e3, 1)) kPa", xlabel = "skirt gap [mm]",
        ylabel = "fan power [kW]", legend = :topleft, title = "Fan power at launch")
    plot!(plt, gaps, fan_power_closed_form.(car.m * G0 / 4.0, gaps ./ 1e3) ./ 1e3; lw = 2,
        color = :seagreen, label = "least Δp to hang $(car.m) kg upside down")
    scatter!(plt, [gap_mm], [suction.fan_power / 1e3]; ms = 8, color = :black,
        label = "launch model: $(fmt(suction.fan_power / 1e3, 1)) kW")
    plt
end

# ╔═╡ 691785d8-5309-5564-8bdf-c62da7f64403
Markdown.parse("""
**Upside down:** the fan's downforce is **$(fmt(suction.hold_margin))×** the car's weight at
this command. Hanging $(car.m) kg inverted needs at least Δp = $(fmt(suction.hold_dp, 0)) Pa,
which costs $(fmt(suction.hold_power / 1e3, 1)) kW at a $(gap_mm) mm gap
(`TestSuctionFanInvertedHold`). **Yes**, when stationary on a sealed surface.
**Next:** suction leaves the launch at 1.75 g. Thrust pushes the body directly.
""")

# ╔═╡ 098ef777-bbf4-5a29-9f6f-e994f3418774
md"""
## Simulation 3: the tank blows down

`AirTank` feeding `ColdGasNozzle` on a fixed stand, valve wide open until the tank falls to
2 bar. The ghost is the other end of the polytropic range; the dotted line is the closed form.

p0 [bar] $(@bind p0_bar Slider(300:10:690; default = 380, show_value = true)) ·
V [L] $(@bind V_L Slider(200:50:600; default = 600, show_value = true)) ·
n $(@bind n_poly Slider(1.0:0.05:1.4; default = 1.4, show_value = true)) ·
throat $(@bind throat Select(["fixed" => "fixed: 80 kN at 380 bar", "scaled" => "scaled: 80 kN at any p0"]))
"""

# ╔═╡ 6d1930fd-1787-5449-acfa-579396d3b31b
dyad_fold("AirTank", "ColdGasNozzle")

# ╔═╡ 82ddb7df-c1e1-5e05-829e-9a3486abaa4e
tank_setup = (p0 = p0_bar * 1e5, V = V_L / 1e3, n = n_poly,
    A_t = throat == "fixed" ? 1.286e-3 : 1.286e-3 * 380 / p0_bar);

# ╔═╡ 16a8f827-cd4b-55dc-8b1b-0feb358c99aa
blowdown = let
    t_start = time()
    sol = solve_with(stand_rig; tank_setup...)
    ghost_n = n_poly >= 1.2 ? 1.0 : 1.4
    ghost = solve_with(stand_rig; tank_setup..., n = ghost_n)
    (; sol, ghost, ghost_n, marks = blowdown_marks(sol, stand_rig.sys),
        ms = 1000 * (time() - t_start))
end;

# ╔═╡ 454b7935-c1c3-5914-b6f5-ad13edd86d01
let
    sys = stand_rig.sys
    ts = range(0, 6; length = 600)
    F(sol) = sol(ts, idxs = sys.nozzle.F).u ./ 1e3
    (; F0, t80, t50) = blowdown.marks
    plt = plot(ts, F(blowdown.ghost); lw = 2, color = :gray, alpha = 0.6,
        label = "n = $(blowdown.ghost_n)", xlabel = "time [s]", ylabel = "thrust [kN]",
        legend = :topright, title = "Blowdown: $(fmt(F0 / 1e3, 0)) kN at the start")
    plot!(plt, ts, F(blowdown.sol); lw = 3, color = :black, label = "n = $(n_poly)")
    plot!(plt, ts, [blowdown_closed_form(t; tank_setup...).F / 1e3 for t in ts]; lw = 2,
        ls = :dot, color = :darkorange, label = "closed form")
    hline!(plt, [0.8, 0.5] .* F0 ./ 1e3; color = :steelblue, ls = :dash, label = "80 % and 50 %")
    vline!(plt, [t80, t50]; color = :steelblue, ls = :dot, label = "")
    air = twinx(plt)
    plot!(air, ts, blowdown.sol(ts, idxs = sys.tank.m_g).u; lw = 2, color = :seagreen,
        ylabel = "air in the tank [kg]", label = "", ylims = (0, Inf))
    plt
end

# ╔═╡ d656e5a8-e471-5ec3-a538-ed704c557b90
let
    (; F0, t80, t50) = blowdown.marks
    m0 = blowdown.sol(0.0, idxs = stand_rig.sys.tank.m_g)
    Markdown.parse("""
    **Verdict: 80 kN is a peak, not a level.** $(fmt(F0 / 1e3, 0)) kN at the start, below 80 %
    after **$(fmt(t80)) s** and below 50 % after $(fmt(t50)) s, from $(fmt(m0, 0)) kg of air.
    Raising p0 with a fixed throat raises the thrust too; the "scaled" throat keeps 80 kN and buys
    time instead. *Re-solved in $(fmt(blowdown.ms, 0)) ms (two solves).*
    """)
end

# ╔═╡ 72348138-0b2c-5966-bd28-17c6185490bf
md"""
## Simulation 4: thrust launch

`RoadsterLaunch` with the tank and the rear nozzles: thrust acts on the body, so it adds
acceleration whichever limit binds at the tire. The valves open at t = 0. Pressure, polytropic
index and throat come from Simulation 3.

thrust $(@bind use_thrust CheckBox(default = true)) ·
suction $(@bind use_suction CheckBox(default = false)) ·
tank $(@bind tank_choice Select(["600 L" => "600 L (Tesla, total)", "200 L" => "200 L (Thrust trim, Electrek)"])) ·
`down_fraction` $(@bind down_fraction Slider(0.0:0.05:1.0; default = 0.0, show_value = true))
"""

# ╔═╡ 75e1037e-5a0a-50f2-a755-29e7037ba07e
dyad_fold("RoadsterLaunch")

# ╔═╡ ea852136-7152-5722-88c5-d7269a9dcb3e
thrust_launch = let
    t_start = time()
    cfg = (; car..., thrust_cmd = use_thrust ? 1.0 : 0.0, fan_cmd = use_suction ? 1.0 : 0.0,
        tank_volume = tank_choice == "200 L" ? 0.2 : 0.6, tank_pressure = tank_setup.p0,
        tank_n = tank_setup.n, A_t = tank_setup.A_t, down_fraction)
    sol = solve_with(launch_rig; cfg...)
    t = t60(sol, launch_rig.sys)
    (; sol, cfg, t60 = t, air = isfinite(t) ? air_used(sol, launch_rig.sys, t) : NaN,
        ms = 1000 * (time() - t_start))
end;

# ╔═╡ c526562d-9690-5b95-b0f9-67f9765b3fdf
trims = let
    base = (; car..., thrust_cmd = 1.0, fan_cmd = 1.0, tank_pressure = tank_setup.p0,
        tank_n = tank_setup.n, A_t = tank_setup.A_t)
    (thrust = t60(solve_with(launch_rig; base..., tank_volume = 0.2), launch_rig.sys),
        rocket = t60(solve_with(launch_rig; base..., tank_volume = 0.6), launch_rig.sys))
end;

# ╔═╡ 309bafac-d1f8-5e0a-b637-83a654847224
let
    sys = launch_rig.sys
    kmh(sol) = 3.6 .* sol[sys.v]
    plt = plot(xlabel = "time [s]", ylabel = "speed [km/h]", xlims = (0, 1.6),
        ylims = (0, 130), legend = :bottomright, title = "0–60 mph with thrust")
    for (case, name) in ((:tires_thrust, "tires + thrust"),
                         (:suction_thrust, "suction + thrust"),
                         (:thrust_200l, "suction + thrust, 200 L"))
        r = reference[case]
        plot!(plt, r.sol.t, kmh(r.sol); lw = 1.5, color = :gray, alpha = 0.5,
            label = "baseline $(name): $(fmt(r.t60)) s")
    end
    plot!(plt, thrust_launch.sol.t, kmh(thrust_launch.sol); lw = 3, color = :steelblue,
        label = "current: $(fmt(thrust_launch.t60)) s")
    hline!(plt, [3.6 * V60]; color = :black, ls = :dot, label = "60 mph")
    vline!(plt, [0.81]; color = :firebrick, ls = :dash, label = "Tesla, live: 0.81 s")
    vline!(plt, [0.59]; color = :purple, ls = :dash, label = "Rocket claim: 0.59 s")
    plt
end

# ╔═╡ 1c4c5bb1-294b-5030-8745-8fcf24911c6b
Markdown.parse("""
**Verdict: thrust beats the claims.** The current car reaches 60 mph in
**$(fmt(thrust_launch.t60)) s** and uses **$(fmt(thrust_launch.air, 1)) kg** of air on the way.
At the current tank settings, suction + thrust gives $(fmt(trims.thrust)) s with 200 L (Thrust
trim, under 0.9 s) and $(fmt(trims.rocket)) s with 600 L (Rocket trim, under 0.59 s).
*Re-solved in $(fmt(thrust_launch.ms, 0)) ms.*
""")

# ╔═╡ 8a0fa3f8-202e-50f4-9581-98cbd5938f11
md"""
## Thrust launch: where the force comes from

The tire's share is capped by grip or by the drive torque; the thrust stacks on top of it and
fades as the tank pressure falls.
"""

# ╔═╡ 6a75b042-0d4f-54dc-937d-1f8ecffd98f4
let
    sys = launch_rig.sys
    sol = thrust_launch.sol
    ts = range(0, min(thrust_launch.t60, 3.0); length = 300)
    tire = sol(ts, idxs = sys.wheel.F_x).u ./ 1e3
    forward = (1 - down_fraction) .* sol(ts, idxs = sys.nozzle.F).u ./ 1e3
    grip = sol.ps[sys.mu_A] .* sol(ts, idxs = sys.axle.F_z).u ./ 1e3
    plt = plot(ts, tire; fillrange = 0, fillalpha = 0.35, lw = 2, color = :steelblue,
        label = "tire force", xlabel = "time [s]", ylabel = "force on the car [kN]",
        legend = :topright, title = "Force stack up to 60 mph")
    plot!(plt, ts, tire .+ forward; fillrange = tire, fillalpha = 0.35, lw = 2,
        color = :firebrick, label = "+ rear thrust, backward share")
    plot!(plt, ts, grip; lw = 2, ls = :dash, color = :seagreen, label = "tire limit μ_A·F_z")
    hline!(plt, [sol.ps[sys.motor.T_max] / sol.ps[sys.radius] / 1e3]; lw = 2, ls = :dash,
        color = :darkorange, label = "torque cap T_max/r")
    plt
end

# ╔═╡ e3fe65ed-ec1f-52ef-a417-d8ef143deb5f
md"""
## Down or back?

A plume over the roof suggests air pushing the car down for grip. Each newton pushed down buys
``\mu s/(1-\mu h/L) = 0.86`` N of drive with RWD and 1.23 N with AWD, and only until the torque
cap binds. Each newton pushed back is a full newton. Curves: the baseline 2,000 kg car at
380 bar, computed at load; the star is the current car.
"""

# ╔═╡ 0aeb3bc7-8037-575b-ad36-d81a5834ea0c
let
    plt = plot(xlabel = "down_fraction", ylabel = "t60 [s]", legend = :topleft,
        title = "Point the air backward")
    for c in down_grid.curves
        plot!(plt, down_grid.fractions, c.t60; lw = 2, marker = :circle, ms = 3,
            label = "$(c.layout), fan $(c.fan_cmd == 1 ? "on" : "off"), best at $(c.best)")
    end
    scatter!(plt, [down_fraction], [thrust_launch.t60]; ms = 9, marker = :star5,
        color = :black, label = "current")
    plt
end

# ╔═╡ 4e29c85b-03d2-5502-8fed-f7d389f406bc
md"""
Pushing down pays only for AWD without suction, and only near 0.1: past about 8 kN of downward
thrust the drive torque binds and the extra grip is wasted. With RWD, or with full suction,
all the air should go backward. **Next:** point it at the ground instead, and jump.
"""

# ╔═╡ d7234072-bd91-5008-a8c7-bd27bf75fc30
md"""
## Simulation 5: the hop

`VerticalHop`: the car's mass on a unilateral ground contact, the same 600 L tank at 380 bar,
and four downward nozzles sized like the rear set. Full thrust for a burn time ``t_b``, then the
valves close and the car coasts.

burn time `t_b` [s] $(@bind t_b Slider(0.2:0.001:0.8; default = 0.413, show_value = true))
"""

# ╔═╡ 490fbb26-bcc0-5883-9550-6bc4488356da
dyad_fold("VerticalGroundContact", "VerticalHop", "TestVerticalHop")

# ╔═╡ 8be17925-68bd-5081-9994-2fa7bc043a49
hop_run = let
    t_start = time()
    sol = solve_with(hop_rig; t_b, m = car.m)
    sys = hop_rig.sys
    v_b = sol(t_b, idxs = sys.hop.body.v)
    h_b = sol(t_b, idxs = sys.hop.altitude)
    (; sol, apex = hop_apex(sol, sys), closed_apex = h_b + v_b^2 / (2 * G0),
        air = air_used(sol, sys, t_b; tank = "hop.tank"), ms = 1000 * (time() - t_start))
end;

# ╔═╡ 7297e311-1114-51f5-9256-06ee3e0555a4
let
    sys = hop_rig.sys
    t_end = min(2 * hop_run.apex.t_apex + 0.3, hop_run.sol.t[end])
    ts = range(0, t_end; length = 500)
    plt = plot(ts, hop_run.sol(ts, idxs = sys.hop.altitude).u; lw = 3, color = :steelblue,
        label = "altitude", xlabel = "time [s]", ylabel = "altitude [m]",
        legend = :topright, ylims = (-0.5, max(10, 1.15 * hop_run.apex.apex)),
        title = "Apex $(fmt(hop_run.apex.apex, 1)) m for $(fmt(hop_run.air, 1)) kg of air")
    hline!(plt, [hop_run.closed_apex]; color = :darkorange, ls = :dash,
        label = "closed form h(t_b) + v(t_b)²/2g")
    hline!(plt, [8.0]; color = :gray, ls = :dot, label = "kickflip apex, 8 m")
    vline!(plt, [t_b]; color = :firebrick, ls = :dot, label = "valves close")
    plt
end

# ╔═╡ 05e11080-54c1-5b8c-8a82-34521a4482e8
Markdown.parse("""
**Verdict: yes.** A $(fmt(t_b, 3)) s burn lifts the $(car.m) kg car to
**$(fmt(hop_run.apex.apex, 1)) m** and costs **$(fmt(hop_run.air, 1)) kg** of the 271 kg of air.
An 8 m hop is a fifth of the tank. *Re-solved in $(fmt(hop_run.ms, 0)) ms.*
""")

# ╔═╡ 0c45b5dd-4778-5b23-867c-ce6b58559e15
md"""
## Simulation 6: hover

`TestVerticalHover`: a PI controller with gravity feed-forward drives the valves to hold 2 m from
a standing start. Hover ends when the valves are wide open and the thrust still falls short of
``m g``. The feed-forward assumes the wide-open thrust grows with p0, as it does through the fixed
80 kN throat.

p0 [bar] $(@bind p0_hover Slider(300:10:690; default = 380, show_value = true))
"""

# ╔═╡ e6ad3c77-7a2a-5d49-bfd5-ca40317ca3c3
dyad_fold("TestVerticalHover")

# ╔═╡ 72c966ff-94be-574b-9a41-d1909b728c48
hover_run = let
    t_start = time()
    sol = solve_with(hover_rig; m = car.m, tank_pressure = p0_hover * 1e5)
    (; sol, time = hover_time(sol, hover_rig.sys),
        closed = hover_closed_form(car.m; p0 = p0_hover * 1e5), ms = 1000 * (time() - t_start))
end;

# ╔═╡ 4ce799f5-e25f-5455-92cf-7868dc713552
let
    sys = hover_rig.sys
    ts = range(0, 15; length = 1500)
    plt = plot(ts, hover_run.sol(ts, idxs = sys.hover.altitude).u; lw = 3, color = :steelblue,
        label = "altitude", xlabel = "time [s]", ylabel = "altitude [m]", legend = :topright,
        ylims = (-0.5, 3.5), title = "Hover: $(fmt(hover_run.time, 2)) s at 2 m")
    vline!(plt, [hover_run.time]; color = :firebrick, ls = :dash, label = "valves wide open")
    valve = twinx(plt)
    plot!(valve, ts, hover_run.sol(ts, idxs = sys.hover.command).u; lw = 2, color = :darkorange,
        ylabel = "valve command", ylims = (0, 1.1), label = "")
    plt
end

# ╔═╡ 1eb22217-6b48-5fd1-bbd0-29ab9b184fdf
Markdown.parse("""
**Verdict: no, it cannot fly.** $(car.m) kg at $(p0_hover) bar hovers for
**$(fmt(hover_run.time, 2)) s** (closed form $(fmt(hover_run.closed, 2)) s), then the tank can
no longer carry it. Hops, not flight. *Re-solved in $(fmt(hover_run.ms, 0)) ms.*
""")

# ╔═╡ 62cc1624-ca88-5b76-9cef-c99bf1e68897
html_table(["hover time [s]", "300 bar", "380 bar", "690 bar"],
    [("**$(m) kg**", fmt.(hover_grid.times[i, :], 2)...) for (i, m) in enumerate(hover_grid.masses)];
    numeric = 2:4)

# ╔═╡ 4f6ecd1c-90bb-52bd-85da-d989ab7adc4a
score_rows = let
    (; F0, t80) = blowdown.marks
    [
        verdict_row("Ramp shot plays in real time", "shown as footage",
            "about $(fmt(warmup.k_ramp))× fast", :no),
        verdict_row("0–60 mph under 1 s on tires", "1.0 s, 0.81 s live",
            "$(fmt(tires.t60)) s ($(drive_layout))", tires.t60 <= 1.0 ? :yes : :no),
        verdict_row("Performance trim, fans", "under 1.6 s", "$(fmt(suction.t60)) s",
            suction.t60 <= 1.05 * 1.6 ? :yes : :no),
        verdict_row("Holds the car upside down", "4,700 kgf",
            "$(fmt(suction.hold_margin))× weight", suction.hold_margin >= 1 ? :yes : :no),
        verdict_row("80 kN rear thrust", "over 80 kN",
            "$(fmt(F0 / 1e3, 0)) kN, ≥ 80 % for $(fmt(t80)) s", F0 >= 0.95 * 80e3 ? :yes : :no),
        verdict_row("Thrust trim, 200 L", "under 0.9 s", "$(fmt(trims.thrust)) s",
            trims.thrust < 0.9 ? :yes : :no),
        verdict_row("Rocket trim, 600 L", "under 0.59 s", "$(fmt(trims.rocket)) s",
            trims.rocket < 0.59 ? :yes : :no),
        verdict_row("8 m kickflip hop", "about 8 m",
            "$(fmt(hop_run.apex.apex, 1)) m, $(fmt(hop_run.air, 0)) kg air",
            isfinite(hop_run.apex.apex) ? :yes : :pending),
        verdict_row("It can fly", "\"it can fly\"", "hovers $(fmt(hover_run.time, 1)) s",
            isfinite(hover_run.time) && hover_run.time > 60 ? :yes : :no),
    ]
end;

# ╔═╡ 4378f115-d8fc-5392-9deb-ead3ccf2eb03
md"""
## Verdicts

Tires alone cannot do it; suction moves the limit from the tire to the drive; compressed air
pushes past both, for about a second. It hops; it does not fly.
"""

# ╔═╡ 1a1cf665-5227-5108-b6d8-6a9c8e955454
let
    word = Dict(:yes => "possible", :no => "**not on this physics**", :pending => "not reached")
    html_table(["claim", "Tesla", "model", "verdict"],
        [(r.claim, r.tesla, r.model, word[r.verdict]) for r in score_rows];
        widths = ["30%", "22%", "30%", "18%"])
end

# ╔═╡ 14bd41f4-6154-55bd-84db-91319ba078bd
scoreboard(score_rows)

# ╔═╡ b05ee7f3-2185-518f-9536-7635c28a8067
md"""
## Optional: the kickflip budget

Rolling the car is cheap. With a roll inertia ``I \approx 870`` kg·m², the angular momentum is
``L = I\omega``, the thruster impulse is ``L/\text{arm}``, and the air is impulse over ``v_e``,
twice over to stop the roll.

roll rate [°/s] $(@bind roll_rate Slider(90:1:360; default = 177, show_value = true)) ·
moment arm [m] $(@bind arm Slider(0.6:0.05:1.2; default = 0.9, show_value = true))
"""

# ╔═╡ efcd227c-be87-5b78-b0a3-49f80f436147
let
    I_roll, v_e = 870.0, 693.0
    L = I_roll * deg2rad(roll_rate)
    air = L / arm / v_e
    Markdown.parse("""
    L = $(fmt(L / 1e3, 2)) kN·m·s, impulse $(fmt(L / arm / 1e3, 2)) kN·s: **$(fmt(air, 1)) kg** of
    air to spin up, **$(fmt(2air, 1)) kg** with the stop, against $(fmt(hop_run.air, 0)) kg for the
    hop. Rotation is cheap; lift is expensive.
    """)
end

# ╔═╡ fd52d12c-fa1f-5fc5-bf6c-369a33a56041
md"""
## Wrap-up

- **Write the limit down first.** Every verdict here started from one inequality: grip, torque,
  power, or the air in the tank.
- **Find the binding limit.** Suction did not make the car faster by adding power; it moved the
  limit from the tire to the drive torque.
- **A peak is not a level.** 80 kN lasts a fraction of a second; a blowdown is a pulse.
- **Simulate to check the closed form, not to replace it.** Each Dyad run landed on its
  back-of-envelope number.

Open questions for the hands-on: what happens at 690 bar, at 2,350 kg, and with a 1 ft rollout?
"""

# ╔═╡ d58a74a2-207c-5a35-a637-ac0ec44ff8b3
md"""
## Sources

- Tesla: [The Ramp | Roadster](https://www.youtube.com/watch?v=7p5LxFdc-Qg) and
  [The Kickflip | Roadster](https://www.youtube.com/watch?v=r5vsHHPVhJg).
- Electrek: [technical look](https://electrek.co/2026/10/15/an-updated-technical-look-at-teslas-kick-flipping-0-60-in-1s-next-gen-roadster/)
  and [unveil](https://electrek.co/2026/10/15/tesla-unveils-cyberfied-new-roadster-kickflip/).
- Paul Tan, on-screen telemetry: [article](https://paultan.org/2026/10/16/tesla-roadster-revealed-flies-on-spacex-air-thrusters-0-96-km-h-in-0-81s-production-2028/).
- [TechCrunch](https://techcrunch.com/2026/10/15/tesla-reveals-spacex-powered-roadster-that-flies-and-falls-with-style/),
  [Motor1](https://www.motor1.com/news/812195/tesla-roadster-stunt-2028-production/),
  [Teslarati on the fans](https://www.teslarati.com/tesla-roadster-downforce-fan-system/).
- Third-party physics: [CellCog](https://cellcog.ai/blog/tesla-roadster-physics/).

Tesla published neither the mass nor the tank pressure; the 80 kN and 250 kg figures are press
reports.
"""

# ╔═╡ a34943ff-7ff3-55a6-9bd4-bca6a4c03be9
md"""
## Appendix: checks against the reference runs

The default runs, independent of the sliders, against the numbers in
`docs/roadster-dyad-tasks.md` and `test/roadster_plausibility.jl`. A failing check stops the
headless run.
"""

# ╔═╡ 95229d19-866e-5fbf-952e-52ae748c5604
checks = let
    hop_ref = hop_apex(hop_rig.default, hop_rig.sys)
    hop_air = air_used(hop_rig.default, hop_rig.sys, 0.413; tank = "hop.tank")
    rows = [
        ("t60, RWD, tires [s]", reference.rwd.t60, 3.33, 0.01),
        ("t60, AWD, tires [s]", reference.awd.t60, 2.27, 0.01),
        ("t60, RWD, suction [s]", reference.suction.t60, 1.62, 0.01),
        ("t60, tires + thrust [s]", reference.tires_thrust.t60, 0.554, 0.002),
        ("t60, suction + thrust [s]", reference.suction_thrust.t60, 0.532, 0.002),
        ("t60, suction + thrust, 200 L [s]", reference.thrust_200l.t60, 0.676, 0.002),
        ("stand: thrust below 80 % after [s]", blowdown_marks(stand_rig.default, stand_rig.sys).t80, 0.368, 0.002),
        ("hop, t_b = 0.413 s: apex [m]", hop_ref.apex, 7.99, 0.02),
        ("hop, t_b = 0.413 s: air [kg]", hop_air, 55.0, 15.0),
        ("hover time [s]", hover_time(hover_rig.default, hover_rig.sys), 5.47, 0.02),
    ]
    for (name, value, ref, tol) in rows
        @assert abs(value - ref) <= tol "$name: $value is not within $tol of $ref"
    end
    rows
end;

# ╔═╡ 67ad1529-9b11-596d-8256-6ed6365d8d8e
html_table(["check", "model", "reference", "tolerance"],
    [(n, fmt(v, 3), string(r), "± $(t)") for (n, v, r, t) in checks]; numeric = 2:4)

# ╔═╡ Cell order:
# ╟─b519eab0-5aed-5d96-9f02-4c18458705d3
# ╟─c54392d6-d24f-54c8-8e3d-e9c893d7f2b4
# ╟─70ca7453-e2e9-5fa4-a2a9-af10ca7b3eba
# ╟─8356f8de-1589-5f84-9769-f90f600c385a
# ╟─e3e16d90-e0a7-5499-89ad-ec3ffac00c74
# ╟─0642455c-1da3-51e6-81ff-e990d6acb591
# ╟─40ef78e6-32c9-5c2d-9f7e-b2839b5a029d
# ╟─d1e686ea-7b9d-50b5-8585-e5b5bd5a5077
# ╟─d3171829-f6d6-55d0-b2eb-713d6ad7a265
# ╟─4878a8af-4114-5065-9da2-89b1959677b6
# ╟─77eacb86-0353-5834-9197-a332cd647a50
# ╟─8bfba8d7-c0b7-5416-814c-d951af9cddf7
# ╟─1837c786-5be9-5433-9592-fa23679aa51f
# ╟─9e4e98b3-0b60-5d19-875e-ba9acad48fe5
# ╟─d73c9887-b6d8-5fad-9d96-d7566fc823bb
# ╟─b80af6e2-b5e3-5bdd-97dd-0a6ecf66c074
# ╟─6db050a1-68fc-5767-abf9-74ddea7261d8
# ╟─1bf3759a-417c-5ada-8ebd-6a35dad71f88
# ╟─b6d7b622-21c6-550c-948d-f5cfb96bf5f1
# ╟─0a85f4c7-90ac-595f-b127-8474860e03df
# ╟─532b5431-9db1-5e77-b0bc-66f8324ca14c
# ╟─213033f3-32af-536b-a121-8c95e70f4fd0
# ╟─796e0f71-bc73-545d-8bc1-3375d8be9bcd
# ╟─f1915dd8-39d0-536a-aa80-ecdf6c56bfb1
# ╟─ed540754-92a5-512d-ad4e-3ffb141b2bf1
# ╟─4e611ec9-824a-51e9-a0e7-f9a838886b26
# ╟─343a4f81-c535-5cb3-9f9a-f772db3232b8
# ╟─ee1415ba-6b38-50d9-9750-c5206bd25efe
# ╟─d4f691bf-86ac-511b-b547-b9a1418ebea8
# ╟─27ec9782-781e-5398-b0c1-5d0906183bb9
# ╟─65410189-b0b1-5e52-b267-63adb383edc6
# ╟─f1ce64c1-2d6f-5c29-9ba3-ed6dbb15ddc3
# ╟─95427193-c160-57c3-b436-5cf573efc3bc
# ╟─4840cb3d-63a4-519e-b5e9-3cb89de6a41b
# ╟─bb74c430-4f14-5088-bcf4-a82715e51758
# ╟─f8dc7c02-1ddb-5ae9-b536-1c2c2679a8fb
# ╟─f260e1c6-2e3d-5709-bc2b-16b4bd5a8abf
# ╟─abae1e2d-05e7-57ce-94c1-ccf3253dde53
# ╟─112888f3-ea48-57b3-b534-15f0aaf2bb32
# ╟─481ffd01-b7ce-5a10-83be-4a9908d528c4
# ╟─ca3eb955-a7dc-5d89-aabc-fdee7a2c596b
# ╟─44ec27a2-ce80-5e03-af44-7104307276d6
# ╟─ca0bd79d-2962-5f45-93f1-af7cbd159796
# ╟─d2b00eee-ac62-5585-9237-78aba3ec9489
# ╟─68175a2d-7eea-5582-ba04-fe7751ce648d
# ╟─3a2db6cd-e77b-548c-b081-6b3feb62e936
# ╟─71b6de44-ece9-5e3f-ad46-e1a5f649b945
# ╟─138ea814-3a72-52c2-942f-bbaae57968a0
# ╟─a3d6b00c-9a9c-5405-a396-0c3f88a25de3
# ╟─c46c6e9a-7269-5b19-8662-d14ef54554ad
# ╟─691785d8-5309-5564-8bdf-c62da7f64403
# ╟─098ef777-bbf4-5a29-9f6f-e994f3418774
# ╟─6d1930fd-1787-5449-acfa-579396d3b31b
# ╟─82ddb7df-c1e1-5e05-829e-9a3486abaa4e
# ╟─16a8f827-cd4b-55dc-8b1b-0feb358c99aa
# ╟─454b7935-c1c3-5914-b6f5-ad13edd86d01
# ╟─d656e5a8-e471-5ec3-a538-ed704c557b90
# ╟─72348138-0b2c-5966-bd28-17c6185490bf
# ╟─75e1037e-5a0a-50f2-a755-29e7037ba07e
# ╟─ea852136-7152-5722-88c5-d7269a9dcb3e
# ╟─c526562d-9690-5b95-b0f9-67f9765b3fdf
# ╟─309bafac-d1f8-5e0a-b637-83a654847224
# ╟─1c4c5bb1-294b-5030-8745-8fcf24911c6b
# ╟─8a0fa3f8-202e-50f4-9581-98cbd5938f11
# ╟─6a75b042-0d4f-54dc-937d-1f8ecffd98f4
# ╟─e3fe65ed-ec1f-52ef-a417-d8ef143deb5f
# ╟─0aeb3bc7-8037-575b-ad36-d81a5834ea0c
# ╟─4e29c85b-03d2-5502-8fed-f7d389f406bc
# ╟─d7234072-bd91-5008-a8c7-bd27bf75fc30
# ╟─490fbb26-bcc0-5883-9550-6bc4488356da
# ╟─8be17925-68bd-5081-9994-2fa7bc043a49
# ╟─7297e311-1114-51f5-9256-06ee3e0555a4
# ╟─05e11080-54c1-5b8c-8a82-34521a4482e8
# ╟─0c45b5dd-4778-5b23-867c-ce6b58559e15
# ╟─e6ad3c77-7a2a-5d49-bfd5-ca40317ca3c3
# ╟─72c966ff-94be-574b-9a41-d1909b728c48
# ╟─4ce799f5-e25f-5455-92cf-7868dc713552
# ╟─1eb22217-6b48-5fd1-bbd0-29ab9b184fdf
# ╟─62cc1624-ca88-5b76-9cef-c99bf1e68897
# ╟─4f6ecd1c-90bb-52bd-85da-d989ab7adc4a
# ╟─4378f115-d8fc-5392-9deb-ead3ccf2eb03
# ╟─1a1cf665-5227-5108-b6d8-6a9c8e955454
# ╟─14bd41f4-6154-55bd-84db-91319ba078bd
# ╟─b05ee7f3-2185-518f-9536-7635c28a8067
# ╟─efcd227c-be87-5b78-b0a3-49f80f436147
# ╟─fd52d12c-fa1f-5fc5-bf6c-369a33a56041
# ╟─d58a74a2-207c-5a35-a637-ac0ec44ff8b3
# ╟─a34943ff-7ff3-55a6-9bd4-bca6a4c03be9
# ╟─95229d19-866e-5fbf-952e-52ae748c5604
# ╟─67ad1529-9b11-596d-8256-6ed6365d8d8e
