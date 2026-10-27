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

# ╔═╡ b519eab0-5aed-5d96-9f02-4c18458705d3
md"""
# Tesla Roadster: is it physically possible?

On 15 October 2026 Tesla showed its new Roadster. It reached 60 mph (97 km/h) in under a
second, drove on a ramp that curled past vertical, and jumped over a row of cars.

We take each claim through the same four steps:

1. **The claim:** what Tesla said.
2. **A physics check:** one short calculation on paper.
3. **Our model:** a small computer model of the car, built in Dyad.
4. **The simulation:** run the model, and compare it with the claim.

*To start the notebook: `julia +dyad-3.5.0 notebooks/roadster/present.jl`. The launcher runs it
in its own process, because Pluto's helper processes cannot load Dyad with this Julia build.*
"""

# ╔═╡ c54392d6-d24f-54c8-8e3d-e9c893d7f2b4
html"<button onclick='present()'>present</button>"

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
    Plots.default(size = (1200, 520))
    Roadster = components.Roadster
    img_dir = joinpath(@__DIR__, "img")
    nothing
end

# ╔═╡ 8356f8de-1589-5f84-9769-f90f600c385a
md"""
**Car** · mass [kg] $(@bind m_car Slider(1700:50:2350; default = 2000, show_value = true)) · drive $(@bind drive_layout Select(["RWD", "AWD"]))
"""

# ╔═╡ e3e16d90-e0a7-5499-89ad-ec3ffac00c74
car_panel_style("8356f8de-1589-5f84-9769-f90f600c385a")

# ╔═╡ 73d1f345-c3c2-4f93-9873-b260ea105299
# Pluto caps the column at 700 px, which leaves half of a projector empty.
html"""
<style>
main { max-width: min(1300px, 94vw) !important; }
</style>
"""

# ╔═╡ 0642455c-1da3-51e6-81ff-e990d6acb591
begin
    car = (; m = m_car, LAYOUTS[drive_layout]...)
    other_layout = drive_layout == "RWD" ? "AWD" : "RWD"
    layout_name = Dict("RWD" => "rear-wheel drive", "AWD" => "all-wheel drive")
    nothing
end

# ╔═╡ 40ef78e6-32c9-5c2d-9f7e-b2839b5a029d
md"""
## What Tesla showed

The event took place at SpaceX's test site in McGregor, Texas. We check five claims, one
section each:

1. **The tires** grip up to 1.26 g.
2. **The suction fan** presses the car onto the road with 4,700 kg, and gives 0–60 mph in under
   1.6 s.
3. **The air thrusters** push with over 80 kN, from 600 L of compressed air.
4. **0–60 mph in under a second:** 1.0 s recorded, 0.81 s live, and under 0.59 s for the top
   version.
5. **"It can fly":** an 8 m hop over a row of cars, and short hovers.

Each section ends with a verdict: green for plausible, amber for partly, red for not plausible.
"""

# ╔═╡ d1e686ea-7b9d-50b5-8585-e5b5bd5a5077
md"""
## The videos

Tesla's official clips. Offline, follow the links instead:
[The Ramp | Roadster](https://www.youtube.com/watch?v=7p5LxFdc-Qg) ·
[The Kickflip | Roadster](https://www.youtube.com/watch?v=r5vsHHPVhJg).
"""

# ╔═╡ d3171829-f6d6-55d0-b2eb-713d6ad7a265
html"""
<div style="display:flex;gap:12px">
<iframe style="flex:1 1 0;min-width:0;aspect-ratio:16/9;border:0" src="https://www.youtube-nocookie.com/embed/7p5LxFdc-Qg" title="The Ramp | Roadster" allow="encrypted-media; picture-in-picture; fullscreen" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
<iframe style="flex:1 1 0;min-width:0;aspect-ratio:16/9;border:0" src="https://www.youtube-nocookie.com/embed/r5vsHHPVhJg" title="The Kickflip | Roadster" allow="encrypted-media; picture-in-picture; fullscreen" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
</div>
"""

# ╔═╡ 594f15a5-e0fa-48db-90fe-c4e7000f5a53
md"""
## The car in one picture

Five forces decide everything in this talk. The car drives to the right.
"""

# ╔═╡ bba2cff6-1f60-4b91-8e2b-4fd99af262b0
let
    plt = plot(; xlims = (-1.5, 13.5), ylims = (-1.9, 4.6), aspect_ratio = :equal,
        framestyle = :none, legend = false, size = (1200, 520))
    circle(x, y, r) = Shape(x .+ r .* cos.(range(0, 2π; length = 60)),
        y .+ r .* sin.(range(0, 2π; length = 60)))
    arrow!(x0, y0, x1, y1, color) = plot!(plt, [x0, x1], [y0, y1]; arrow = true, lw = 5, color)
    label!(x, y, s, color; h = :left) = annotate!(plt, x, y, text(s, 15, color, h))
    plot!(plt, [-1.5, 13.5], [0, 0]; color = :gray, lw = 3)
    plot!(plt, Shape([1.5, -1.3, -1.3], [1.05, 0.6, 1.5]); color = "#f4c7c7", lw = 0)
    plot!(plt, Shape([1.5, 9.5, 9.9, 9.5, 7.2, 6.0, 3.6, 1.5],
        [0.55, 0.55, 0.9, 1.5, 1.6, 2.4, 2.4, 1.5]); color = "#d6dee8", linecolor = :black, lw = 2)
    for x in (3.0, 8.0)
        plot!(plt, circle(x, 0.5, 0.5); color = :black)
    end
    arrow!(2.2, -0.4, 5.0, -0.4, :seagreen)
    label!(2.2, -0.95, "push from the tires", :seagreen)
    arrow!(6.0, 1.3, 6.0, -1.2, :black)
    label!(6.2, -1.25, "weight", :black)
    arrow!(12.6, 1.15, 10.1, 1.15, :purple)
    label!(10.2, 1.7, "air drag", :purple)
    for x in (3.6, 5.0, 6.4)
        arrow!(x, 4.1, x, 2.65, :steelblue)
    end
    label!(6.9, 3.5, "suction: the air above\npresses the car down", :steelblue)
    arrow!(1.7, 1.05, 4.6, 1.05, :firebrick)
    label!(-1.4, 2.7, "thrust: air blows out\nthe back, the car is\npushed forward", :firebrick)
    label!(10.4, -1.2, "direction of travel →", :gray)
    plt
end

# ╔═╡ a7fe0fee-f9f4-42d4-8665-e3e62243f675
md"""
## Words we use
"""

# ╔═╡ e4766715-9580-44d7-8765-673c658347de
html_table(["Word", "In everyday language"], [
    ("**μ** (mu), grip", "How hard a tire can push, compared with how hard it is pressed onto the road. Grip 1.26: pressed down by 1 kN, it can push with 1.26 kN."),
    ("**g**", "The pull of gravity, 9.81 m/s². \"1 g\" of push is a push as strong as the car's own weight."),
    ("**N, kN**", "Newton, the unit of force. 1 kN is about the weight of $(fmt(everyday.kg_per_kN, 0)) kg."),
    ("**torque**, **N·m**", "Twisting force. 1 N·m is a push of 1 N on a spanner 1 m long."),
    ("**power**, **kW**, **MW**", "How fast the motor delivers energy: push × speed. 1 MW is about $(fmt(everyday.hp, 0)) horsepower."),
    ("**downforce**", "A force that presses the car onto the road, on top of its weight."),
    ("**bar**", "Pressure. 1 bar is about the air pressure around us. A car tire is pumped to about $(fmt(everyday.tire_bar, 0)) bar."),
    ("**60 mph**", "$(fmt(3.6 * V60, 1)) km/h, or $(fmt(V60, 1)) m/s."),
]; widths = ["22%", "78%"])

# ╔═╡ d73c9887-b6d8-5fad-9d96-d7566fc823bb
md"""
## What Tesla said, and what it did not

Each number is marked by how solid it is: **T** Tesla said it · **P** a press report that Tesla
has not confirmed · **M** measured or estimated by someone else · **?** not known.
"""

# ╔═╡ b80af6e2-b5e3-5bdd-97dd-0a6ecf66c074
html_table(["Item", "Value", "Source"], [
    ("0–60 mph claims", "Performance < 1.6 s, Thrust < 0.9 s, Rocket < 0.59 s", "**T**"),
    ("0–60 mph runs", "1.0 s recorded, 0.81 s live", "**T**"),
    ("Thrusters", "10 air thrusters, 600 L of air in carbon-wrapped tanks", "**T**"),
    ("Downforce", "4,700 kg readout; holds the car upside down", "**T**"),
    ("Tire grip limit", "1.26 g", "**P**"),
    ("Rear thrust", "over 80 kN from 4 rear nozzles", "**P**"),
    ("Air mass", "about 250 kg; Electrek splits 200 L Thrust + 400 L Rocket", "**P**"),
    ("Tank pressure", "380 bar (5,500 psi cabin readout) **or** 690 bar (10,000 psi, Electrek)", "**P**, conflicting"),
    ("Drive", "rear-wheel drive, 2 rear motors, over 1 MW, about 1,400 N·m", "**P**"),
    ("Fans", "about 4 × 20 kW", "**M**"),
    ("Mass", "under 1,700 kg (Electrek), about 1,900 kg, about 2,350 kg (CellCog)", "**M**, conflicting"),
    ("Video measurements", "kickflip top height 8.0 m, spin 177° per second", "**M**"),
    ("Not disclosed", "mass, tank pressure, battery size, thrust per nozzle, gear ratio", "**?**"),
]; widths = ["22%", "58%", "20%"])

# ╔═╡ 6db050a1-68fc-5767-abf9-74ddea7261d8
md"""
## What we assume for the unknowns

Where Tesla gave no number, the models use the values below. The panel in the bottom-right
corner changes the mass and the drive for every section.
"""

# ╔═╡ 1bf3759a-417c-5ada-8ebd-6a35dad71f88
html_table(["Unknown", "Model value", "Why"], [
    ("Mass", "**2,000 kg**, panel slider 1,700–2,350", "middle of the estimates"),
    ("Motor", "at most 12,000 N·m at the wheels and 1 MW; wheel radius 0.35 m", "1,400 N·m × an assumed 8.5:1 gear"),
    ("Tire", "best grip 1.26; traction control keeps the tire just below it, at 98 %", "Tesla's figure, a perfect controller"),
    ("Drive", "rear-wheel drive, 55 % of the weight on the rear wheels; all-wheel drive for comparison", "assumed"),
    ("Air drag", "drag area 0.6 m²", "assumed"),
    ("Fan", "4 m² floor, 10 m of skirt, 3 mm gap under it", "assumed; suction sized to 4,700 kg"),
    ("Tank", "600 L at **380 bar** and 20 °C: $(fmt(paper.m_air, 0)) kg of air", "the cabin readout"),
    ("Nozzles", "opening sized for 80 kN at 380 bar", "the press figure"),
]; widths = ["16%", "50%", "34%"])

# ╔═╡ f1ce64c1-2d6f-5c29-9ba3-ed6dbb15ddc3
md"""
## How the simulations run

The results come from models built in Dyad, in `dyad/Roadster/`. Each model is built once, when
the notebook opens. After that, a slider only changes numbers in a ready model and runs it
again. That takes a few hundredths of a second, so the plots follow the sliders live.

The panel in the bottom-right corner holds two settings that every section shares: the **car
mass** and the **drive** (RWD: rear-wheel drive, AWD: all-wheel drive). Above it, **Claim vs
model** collects the verdicts as we go.
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

# ╔═╡ 9c543dcc-f871-5328-901c-efe1abd6c9de
# The "Try this" lines quote these: the baseline car (2,000 kg, RWD) with one setting changed.
hints = let
    base = (; m = 2000.0, LAYOUTS["RWD"]...)
    t(; kw...) = t60(solve_with(launch_rig; merge(base, kw)...), launch_rig.sys)
    marks(; kw...) = blowdown_marks(solve_with(stand_rig; kw...), stand_rig.sys)
    apex(; kw...) = hop_apex(solve_with(hop_rig; kw...), hop_rig.sys).apex
    (
        tires_mu15 = t(mu_A = 1.5),
        tires_P05 = t(P_max = 0.5e6),
        suction_T20 = t(fan_cmd = 1.0, T_max = 20e3),
        stand_200L = marks(V = 0.2),
        thrust_off_suction = t(fan_cmd = 1.0),
        thrust_m2350 = t(thrust_cmd = 1.0, fan_cmd = 1.0, m = 2350.0),
        thrust_all_down = t(thrust_cmd = 1.0, down_fraction = 1.0),
        hop_06 = apex(t_b = 0.6),
    )
end;

# ╔═╡ 7780ed0f-6df7-4acc-b67a-4cb4a7c9f608
# The worked examples on the physics slides, for the baseline car: 2,000 kg, RWD, 380 bar.
paper = let
    m, mu, grip, share, h_over_L = 2000.0, 1.26, 0.98, 0.55, 0.17
    r, T_max, P_max = 0.35, 12_000.0, 1e6
    W = m * G0
    rwd_g = grip * mu * share / (1 - grip * mu * h_over_L)
    D, A = 4700 * G0, 4.0
    dp = D / A
    Q = 0.6 * 10.0 * 0.003 * sqrt(2 * dp / 1.2)
    noz = nozzle_closed_form(380e5, 293.15)
    m_air = blowdown_closed_form(0.0).m
    v_hop = sqrt(2 * G0 * 8.0)
    J = m * v_hop
    (; m, W, a_1 = V60 / 1.0 / G0, a_081 = V60 / 0.81 / G0,
        F_mu = mu * W, t_awd = V60 / (mu * G0), rwd_g, t_rwd = V60 / (rwd_g * G0),
        F_torque = T_max / r, F_power60 = P_max / V60, F_tire = grip * mu * W,
        D, dp, Fz_suction = W + D, F_tire_suction = grip * mu * (W + D),
        t_suction = V60 / (T_max / r / m),
        Q, P_fan = Q * dp / 0.6, P_fan10 = fan_power_closed_form(dp, 0.010),
        hold_dp = W / A, P_hold = fan_power_closed_form(W / A, 0.003),
        m_air, mdot = noz.mdot, v_e = noz.v_e, F0 = noz.F, t_empty = m_air / noz.mdot,
        thrust_g = noz.F / W, rwd_rest_g = grip * mu * share,
        v_hop, J, air_hop = J / noz.v_e, t_burn = J / (noz.F - W),
        mdot_hover = W / noz.v_e, t_hover_ideal = m_air * noz.v_e / W,
        t_hover = hover_closed_form(m))
end;

# ╔═╡ 81a4f22b-73e4-4385-9c09-5cadf0bdf949
# Everyday reference objects; each slide that uses one names it.
everyday = let
    small_car, adult, tire_bar, city_engine, story = 1000.0, 70.0, 2.0, 50.0, 3.0
    (; small_car, adult, tire_bar, city_engine, story,
        cars_80kN = 80e3 / (small_car * G0),
        adults_air = paper.m_air / adult,
        tire_x = 380 / tire_bar,
        engine_x = paper.P_fan / 1e3 / city_engine,
        hp = 1e6 / 745.7,
        stories = 8.0 / story,
        kg_per_kN = 1e3 / G0,
        hop_kmh = 3.6 * paper.v_hop,
        weight_x = 4700 / 2000)
end;

# ╔═╡ ca3fab0a-57b4-5859-b505-19746d073c33
md"""
## Claim 1: what can the tires do?

**The question:** how hard can the tires push the car forward before they slip?

**Like pushing a heavy box across a floor.** Your legs can push only as hard as the floor
pushes back on your shoes. Push harder, and your shoes slip. A tire has the same limit.

**Tesla's claim.** The tires grip up to **1.26 g** (press report, Electrek, quoting a Tesla
engineer). That means: **the tire can push with 1.26 times the car's weight.** Two rear motors
drive the car: over 1 MW, about $(fmt(everyday.hp, 0)) horsepower (press report).

**To check:** on tires alone, can the car reach 60 mph in 1.0 s, as in Tesla's recorded run?
"""

# ╔═╡ ceba3a95-cacc-5e9b-9677-0c3d0016913f
md"""
## Claim 1 · Physics check: how hard must the car push?

**In words:** speed gained = push ÷ mass × time. So the push per kilogram the car needs is
speed ÷ time.

```math
a = \frac{v_{60}}{t}
```
"""

# ╔═╡ e2facb87-8c7c-4e2b-813e-5b5661d79edd
html_table(["", "Symbol", "Value"], [
    ("speed at 60 mph", "v₆₀", "$(fmt(V60, 1)) m/s"),
    ("time, Tesla's recorded run", "t", "1.0 s"),
    ("push per kilogram needed", "a", "$(fmt(V60, 1)) m/s² = **$(fmt(paper.a_1)) g**"),
]; widths = ["45%", "15%", "40%"])

# ╔═╡ 385f5d07-26a6-4510-a60c-1f78175a3f38
md"""
**So what?** A 1 s run needs a push of **$(fmt(paper.a_1)) times the car's weight**, the whole
way. Tesla's live 0.81 s run needs $(fmt(paper.a_081)) times.
"""

# ╔═╡ 831bd16d-58f9-5236-867e-d5ed00adcf63
md"""
## Claim 1 · Physics check: the most a tire can push

**In words:** most push = grip × how hard the tire is pressed onto the road.

```math
F_x \le \mu \, F_z
```

Take the best case first: all four wheels drive, so the tires carry the whole weight.
"""

# ╔═╡ eca7b04d-a281-47a3-a911-0678c8510130
html_table(["", "Symbol", "Value"], [
    ("grip, Tesla's tire", "μ", "1.26"),
    ("pressed onto the road: the weight of 2,000 kg", "F_z", "$(fmt(paper.W / 1e3, 1)) kN"),
    ("most push", "F_x", "$(fmt(paper.F_mu / 1e3, 1)) kN = 1.26 × the weight"),
    ("fastest 0–60 mph", "t", "$(fmt(V60, 1)) ÷ (1.26 × 9.81) = **$(fmt(paper.t_awd)) s**"),
]; widths = ["45%", "15%", "40%"])

# ╔═╡ 406c6a43-740c-4e56-8a57-35b6a07ba2b7
md"""
**So what?** Even with all four wheels driven, the tires cannot beat **$(fmt(paper.t_awd)) s**.
The mass does not matter: a heavier car presses harder, but also needs more push.
"""

# ╔═╡ 3359a5d2-7aac-5f95-b6cf-d3420dd9d51b
details("Details: rear-wheel drive, and the load that moves onto the rear tires", md"""
With rear-wheel drive only the rear tires push. As the car speeds up it tips back, and the rear
tires carry more load:

```math
F_z = s\, m g + m a\, \frac{h}{L}
```

- ``s = 0.55``: the share of the weight on the rear wheels at rest
- ``h/L = 0.17``: the height of the center of mass over the wheelbase

Traction control keeps the tire at 98 % of its best grip, so ``m a = 0.98\, \mu F_z``. Solved
for ``a``:

```math
\frac{a}{g} = \frac{0.98\, \mu\, s}{1 - 0.98\, \mu\, h/L}
```

With ``\mu = 1.26`` that is ``a/g =`` $(fmt(paper.rwd_g)), and 60 mph takes
$(fmt(paper.t_rwd)) s.
""")

# ╔═╡ 330c2302-e7e4-5849-be68-b75c86f3cacb
md"""
## Claim 1 · Physics check: is the motor strong enough?

**In words:** push at the road = twisting force at the wheel ÷ wheel radius.

```math
F = \frac{T_{max}}{r}
```
"""

# ╔═╡ 9713dcda-8181-45e7-8fd5-c62bf9134aa7
html_table(["", "Symbol", "Value"], [
    ("twisting force at the wheels: 1,400 N·m × an 8.5:1 gear", "T_max", "12,000 N·m"),
    ("wheel radius", "r", "0.35 m"),
    ("most push from the motor", "F", "$(fmt(paper.F_torque / 1e3, 1)) kN = **$(fmt(paper.F_torque / paper.W)) × the weight**"),
    ("most push from the tires (all-wheel drive, 98 %)", "", "$(fmt(paper.F_tire / 1e3, 1)) kN = $(fmt(paper.F_tire / paper.W)) × the weight"),
]; widths = ["45%", "15%", "40%"])

# ╔═╡ 77615046-bbf9-4318-8da9-1d7aca21ca94
md"""
**So what?** The motor can push harder than the tires can grip. **The tires run out first, not
the motor.**
"""

# ╔═╡ 15a463e7-7217-484f-a1e4-ed198c9b05c7
details("Details: the power limit", md"""
Push times speed cannot exceed the motor power ``P = 1`` MW, so ``F \le P / v``. At 60 mph that
is ``10^6 / 26.8 =`` $(fmt(paper.F_power60 / 1e3, 1)) kN, still above the tires'
$(fmt(paper.F_tire / 1e3, 1)) kN. Below 60 mph the power never limits.
""")

# ╔═╡ 0bcfb8b9-0d28-5c3c-baf7-8b3900960826
grip_need = let
    needed(t) = V60 / t / G0
    awd(t) = needed(t) / 0.98
    rwd(t) = needed(t) / (0.98 * (0.55 + 0.17 * needed(t)))
    (awd_1 = awd(1.0), rwd_1 = rwd(1.0), awd_16 = awd(1.6), rwd_16 = rwd(1.6))
end;

# ╔═╡ 4920fcd2-add1-5e85-8807-ebc7b0c0798f
md"""
## Claim 1 · Physics check: how much grip would 1 s need?

The same formulas as before, for every grip from 0.8 to 3.
"""

# ╔═╡ 92516938-164d-41b8-991e-ca5c4216898c
headline("A 1 s run needs grip of about $(fmt(max(grip_need.rwd_1, grip_need.awd_1), 1)). Tesla's tire has 1.26.")

# ╔═╡ ed540754-92a5-512d-ad4e-3ffb141b2bf1
let
    grip = 0.98
    mu = range(0.8, 3.0; length = 200)
    t_awd(μ) = V60 / (grip * μ * G0)
    t_rwd(μ) = V60 / (grip * μ * 0.55 / (1 - grip * μ * 0.17) * G0)
    plt = plot(mu, t_rwd.(mu); lw = 3, color = :firebrick, label = "rear-wheel drive",
        xlabel = "Tire grip μ", ylabel = "Time to 60 mph (s)", ylims = (0, 5),
        legend = :topright)
    plot!(plt, mu, t_awd.(mu); lw = 3, color = :steelblue, label = "all-wheel drive")
    hline!(plt, [1.0]; color = :black, ls = :dash, label = "Tesla's run: 1.0 s")
    vline!(plt, [1.26]; color = :seagreen, lw = 2, label = "Tesla's tire: grip 1.26")
    mark!(plt, 1.26, t_rwd(1.26), "rear-wheel drive: $(fmt(t_rwd(1.26))) s"; dx = 0.25, dy = 0.6)
    mark!(plt, 1.26, t_awd(1.26), "all-wheel drive: $(fmt(t_awd(1.26))) s"; dx = 0.15,
        dy = -0.75, valign = :top, color = :steelblue)
    need = max(grip_need.rwd_1, grip_need.awd_1)
    mark!(plt, need, 1.0, "1 s needs grip $(fmt(need, 1))"; dx = -0.1, dy = 1.2, halign = :right)
    plt
end

# ╔═╡ 1ce0d1b7-5ec1-580b-b0bd-934fb74a86fc
md"""
**So what?** A 1 s run on tires alone needs more than twice the grip of Tesla's own tire. Even
Tesla's 1.6 s needs grip $(fmt(grip_need.awd_16, 2)) with all-wheel drive.
"""

# ╔═╡ 490fee27-240a-52a6-b9cb-9b40cd4d6fb6
md"""
## Claim 1 · Our model: the launch car

One model, `RoadsterLaunch`, covers every launch in this talk. Here the fan and the air jets are
off. **Look at the bottom right of the diagram:** traction → motor → wheel → body.
"""

# ╔═╡ 886b889c-74be-46fe-9e2d-db5add63771c
html_table(["Block", "In the real car", "What it does"], [
    ("traction", "the traction control in the car's computer", "asks for just under the most the tire can take, so the wheel does not spin"),
    ("motor", "the two rear motors and their gears", "gives that twisting force, up to 12,000 N·m and 1 MW"),
    ("wheel", "the rear wheel and tire", "turns the twisting force into a push on the road"),
    ("axle", "the rear suspension", "works out how hard the tires press on the road"),
    ("body", "the car itself", "its mass, plus air drag and rolling resistance"),
]; widths = ["14%", "36%", "50%"])

# ╔═╡ 066d157f-659c-5115-ad05-d595ff52c35c
diagrams([joinpath(img_dir, "roadster-launch.png") =>
    "`RoadsterLaunch`. Top left: the fan. Middle left: the air tank and nozzle. Bottom right: traction, motor, wheel and body."]; height = "300px")

# ╔═╡ 341af294-bb6c-55d2-990c-78bbbe190ade
md"""
## Claim 1 · Our model: three blocks we wrote

The rest of the car comes from the existing component library.
"""

# ╔═╡ 10d92e2a-0efa-53cb-908f-508a45c53fad
diagrams([
    joinpath(img_dir, "power-limited-motor.png") =>
        "**`PowerLimitedMotor`**, the motor. It is only equations, so the picture shows its connections. It gives the smallest of: what traction control asks for, 12,000 N·m, and what 1 MW allows at this speed.",
    joinpath(img_dir, "axle-load.png") =>
        "**`AxleLoad`**, the rear suspension. Also only equations. It adds the rear share of the weight, the downforce, and the load that moves back as the car speeds up, with a 0.1 s delay like a settling spring.",
    joinpath(img_dir, "traction-control.png") =>
        "**`TractionControl`**, shown in its test with a fixed load and slip. It asks for 98 % of the twisting force the tire can take. If the tire starts to spin, it asks for less.",
]; height = "300px")

# ╔═╡ abae1e2d-05e7-57ce-94c1-ccf3253dde53
dyad_fold("AxleLoad", "TractionControl", "PowerLimitedMotor")

# ╔═╡ f260e1c6-2e3d-5709-bc2b-16b4bd5a8abf
md"""
## Claim 1 · Simulation: speed against time

tire grip μ $(@bind mu_A Slider(1.0:0.02:1.6; default = 1.26, show_value = true)) ·
motor power [MW] $(@bind P_MW Slider(0.5:0.1:2.0; default = 1.0, show_value = true)) ·
air drag area [m²] $(@bind CdA Slider(0.3:0.05:1.2; default = 0.6, show_value = true))
"""

# ╔═╡ 112888f3-ea48-57b3-b534-15f0aaf2bb32
tires = let
    t_start = time()
    cfg = (; mu_A, P_max = P_MW * 1e6, CdA)
    sol = solve_with(launch_rig; car..., cfg...)
    ghost = solve_with(launch_rig; m = car.m, LAYOUTS[other_layout]..., cfg...)
    t = t60(sol, launch_rig.sys)
    (; sol, ghost, t60 = t, t60_ghost = t60(ghost, launch_rig.sys),
        v_at_1s = 3.6 * sol(1.0, idxs = launch_rig.sys.v),
        limits = binding_limit(sol, launch_rig.sys; until = min(t, 6.0)),
        ms = 1000 * (time() - t_start))
end;

# ╔═╡ 388d7049-aebf-433e-8ff0-870e62b57c74
headline(tires.t60 <= 1.0 ?
    "At this grip the tires alone reach 60 mph in $(fmt(tires.t60)) s, as fast as Tesla's run" :
    "Tires alone: 60 mph after $(fmt(tires.t60)) s. Tesla's run took 1.0 s.")

# ╔═╡ 481ffd01-b7ce-5a10-83be-4a9908d528c4
let
    sys = launch_rig.sys
    plt = plot(tires.ghost.t, 3.6 .* tires.ghost[sys.v]; lw = 2, color = :gray, alpha = 0.6,
        label = "$(layout_name[other_layout]): $(fmt(tires.t60_ghost)) s",
        xlabel = "Time since start (s)", ylabel = "Speed (km/h)", xlims = (0, 4),
        ylims = (0, 130), legend = :bottomright)
    plot!(plt, tires.sol.t, 3.6 .* tires.sol[sys.v]; lw = 3, color = :steelblue,
        label = "$(layout_name[drive_layout]) (the panel's car)")
    hline!(plt, [3.6 * V60]; color = :black, ls = :dot, label = "60 mph")
    vline!(plt, [1.0]; color = :darkorange, ls = :dash, label = "Tesla's recorded run: 1.0 s")
    tires.t60 < 3.9 && mark!(plt, tires.t60, 3.6 * V60, "60 mph after $(fmt(tires.t60)) s";
        dx = -0.15, dy = 20, halign = :right)
    mark!(plt, 1.0, tires.v_at_1s, "at 1.0 s: only $(fmt(tires.v_at_1s, 0)) km/h"; dx = 0.15,
        dy = 40, color = :darkorange)
    plt
end

# ╔═╡ ca3eb955-a7dc-5d89-aabc-fdee7a2c596b
md"""
**Try this:** set the tire grip to 1.5. The time drops to $(fmt(hints.tires_mu15)) s (2,000 kg,
RWD). Halve the motor power instead: still $(fmt(hints.tires_P05)) s. Only the grip matters.
"""

# ╔═╡ 44ec27a2-ce80-5e03-af44-7104307276d6
md"""
## Claim 1 · Simulation: which limit holds the car back?

Three things cap the push at the road: the tires, the motor's twisting force and the motor's
power. The car gets the lowest of the three.
"""

# ╔═╡ 186bdace-d646-40e4-8269-91a5eb5525a9
let l = main_limit(tires.limits)
    headline("$(uppercasefirst(l.name)) $(l.verb) the push for $(fmt(100 * l.share, 0)) % of the run$(l.name == "the tires" ? ": a stronger motor would not help" : "")")
end

# ╔═╡ ca0bd79d-2962-5f45-93f1-af7cbd159796
limit_map(tires.sol, launch_rig.sys; until = min(tires.t60, 6.0))

# ╔═╡ 39c8664b-3505-5411-b5c7-87d75a2d2305
md"""
**Try this:** switch the panel to AWD. All four tires push, the green line rises, and 60 mph
comes after $(fmt(reference.awd.t60)) s (2,000 kg). The tires still set the limit.
"""

# ╔═╡ 9dd44b2e-19e5-50f3-8ecd-ca1b60b39231
md"## Claim 1 · Verdict"

# ╔═╡ 998d436b-2a45-5394-96f2-f88ec80b4ff7
verdict_box(verdicts.tires.light, verdicts.tires.sentence,
    "**The number that decides it:** $(verdicts.tires.decides)")

# ╔═╡ 51d1218c-32e7-5d65-8a3a-d739ab7262fe
md"""
## Claim 2: the suction fan

**The question:** if the tires are the limit, can we press them onto the road harder?

**Like a vacuum cleaner that sticks to the carpet.** The fan sucks air from under the car, and
the air above presses it down. A tire pressed down harder can push harder.

**Tesla's claim.**
- **Downforce:** an on-screen readout showed **4,700 kg**, which is
  **$(fmt(everyday.weight_x)) times the weight** of our 2,000 kg car (Tesla). The car hung
  upside down on a ramp that curled past vertical.
- **Performance version:** fans only, 0–60 mph in **under 1.6 s** (Tesla).
- **Fan power:** about 4 × 20 kW (Electrek's estimate).

Flexible skirts along the edges keep outside air from rushing in. Unlike a wing, this works
while the car stands still.
"""

# ╔═╡ cdb131a1-2d0a-5daa-b6af-25a40c21865a
md"""
## Claim 2 · Physics check: how strong is the suction?

**In words:** pressing force = pressure drop under the car × floor area. So the pressure drop
the fan must make is force ÷ area.

```math
\Delta p = \frac{D}{A}
```
"""

# ╔═╡ d6d7070c-88ff-4b93-8093-7fe8baaef3c2
html_table(["", "Symbol", "Value"], [
    ("pressing force: the weight of 4,700 kg", "D", "$(fmt(paper.D / 1e3, 1)) kN"),
    ("floor area (assumed)", "A", "4 m²"),
    ("pressure drop under the car", "Δp", "$(fmt(paper.dp / 1e3, 1)) kPa = **$(fmt(100 * paper.dp / 101325, 0)) % of the air pressure around us**"),
]; widths = ["45%", "15%", "40%"])

# ╔═╡ bbb95b6c-ba92-42c0-9122-086a8b11c8f3
md"""
**So what?** A small pressure drop over a big floor gives a big force. The fan needs only about
a tenth of normal air pressure to press the car down with $(fmt(everyday.weight_x)) times its
weight.
"""

# ╔═╡ 69cf5e21-22ec-5751-802d-b115c54e4080
md"""
## Claim 2 · Physics check: now the motor is the limit

**In words:** time to 60 mph = speed ÷ push per kilogram. With suction, the tires could push
far harder, so the motor's most push sets the time.

```math
t = \frac{v_{60}}{F_{motor} / m}
```
"""

# ╔═╡ c4f6c8ba-fbbb-443c-943a-a4ca5ae739e3
html_table(["", "Symbol", "Value"], [
    ("most push from the tires, with suction", "", "$(fmt(paper.F_tire_suction / 1e3, 1)) kN = $(fmt(paper.F_tire_suction / paper.W, 1)) × the weight"),
    ("most push from the motor", "F_motor", "$(fmt(paper.F_torque / 1e3, 1)) kN = $(fmt(paper.F_torque / paper.W)) × the weight"),
    ("car mass", "m", "2,000 kg"),
    ("time to 60 mph", "t", "**$(fmt(paper.t_suction)) s**"),
]; widths = ["45%", "15%", "40%"])

# ╔═╡ e8497bf1-2a8a-4661-9c06-863a44ed8885
md"""
**So what?** Suction moves the limit from the tires to the motor, and the time lands right at
Tesla's "under 1.6 s".
"""

# ╔═╡ d72fb098-bed2-4f26-86e7-62ba790df5dd
details("Details: how hard the tires press with suction", md"""
The downforce adds to the weight. With all-wheel drive:

```math
F_z = m g + D
```

That is $(fmt(paper.W / 1e3, 1)) kN + $(fmt(paper.D / 1e3, 1)) kN =
$(fmt(paper.Fz_suction / 1e3, 1)) kN, and the tires could push ``0.98 \cdot 1.26 \cdot F_z =`` $(fmt(paper.F_tire_suction / 1e3, 1)) kN.
The motor's limit is the same as before: ``T_{max}/r = 12{,}000 / 0.35 =``
$(fmt(paper.F_torque / 1e3, 1)) kN.
""")

# ╔═╡ b575dc3a-6334-52cd-948f-ec0c294dafc5
md"""
## Claim 2 · Physics check: what does the fan cost?

Air leaks in under the skirt, and the fan must pump it out again. **In words:** fan power =
air flow × pressure drop ÷ fan efficiency.

```math
P_{fan} = \frac{Q\, \Delta p}{\eta}
```
"""

# ╔═╡ 71b43864-9a54-4b9b-ae1a-671b80c1b95d
html_table(["", "Symbol", "Value"], [
    ("air leaking in through a 3 mm gap", "Q", "$(fmt(paper.Q, 2)) m³ per second"),
    ("pressure drop", "Δp", "$(fmt(paper.dp / 1e3, 1)) kPa"),
    ("fan efficiency", "η", "0.6"),
    ("fan power", "P_fan", "**$(fmt(paper.P_fan / 1e3, 0)) kW**, about a small city car's engine ($(fmt(everyday.city_engine, 0)) kW)"),
]; widths = ["45%", "15%", "40%"])

# ╔═╡ 467406f3-ce75-421e-9a87-d3559eeb35ee
md"""
**So what?** The fan costs about as much power as a small car's engine, in line with Electrek's
4 × 20 kW. A sloppy 10 mm gap would need $(fmt(paper.P_fan10 / 1e3, 0)) kW.
"""

# ╔═╡ 86cfa609-8086-426a-b6ce-2e140ecec052
details("Details: the leak flow, and hanging upside down", md"""
The air leaking in under the skirt:

```math
Q = C_d \cdot \ell \cdot \delta \cdot \sqrt{\frac{2\, \Delta p}{\rho}}
```

- ``\ell = 10`` m: the length of skirt around the car; ``\delta = 3`` mm: the gap under it
- ``C_d = 0.6``: the share of the gap that really flows; ``\rho = 1.2`` kg/m³: air density

To hang a 2,000 kg car upside down, the suction must at least carry its weight:
``\Delta p \ge 2{,}000 \cdot 9.81 / 4 =`` $(fmt(paper.hold_dp / 1e3, 1)) kPa, which costs
$(fmt(paper.P_hold / 1e3, 1)) kW at 3 mm.
""")

# ╔═╡ 2afd0c56-0bf0-5b33-ae6d-73199a0b234b
md"""
## Claim 2 · Our model: the suction fan

We added one block, `SuctionFan`, to the launch car. **Look at the top left of the launch
diagram** (Claim 1): fan command → fan → downforce sum → axle.
"""

# ╔═╡ bf70bd81-1b6a-4cf9-9dd8-594f92efea16
html_table(["Block", "In the real car", "What it does"], [
    ("fan\\_command", "the driver's fan switch", "0 is off, 1 is full power"),
    ("fan", "the fans and the skirts", "lowers the pressure under the floor, taking 0.3 s to spin up; gives the downforce and the fan power"),
    ("downforce\\_sum", "nothing; a sum", "adds the fan's downforce to any thrust pointed down"),
    ("axle", "the rear suspension", "adds the downforce to how hard the tires press on the road"),
]; widths = ["18%", "30%", "52%"])

# ╔═╡ b8dc0784-9c5f-5800-b997-369529968c00
diagrams([joinpath(img_dir, "suction-fan.png") =>
    "`SuctionFan` in its upside-down test: a fixed command drives the fan, which gives the downforce and the fan power."]; height = "260px")

# ╔═╡ 68175a2d-7eea-5582-ba04-fe7751ce648d
dyad_fold("SuctionFan")

# ╔═╡ d2b00eee-ac62-5585-9237-78aba3ec9489
md"""
## Claim 2 · Simulation: the launch with suction

fan setting $(@bind fan_cmd Slider(0.0:0.05:1.0; default = 1.0, show_value = true)) ·
skirt gap [mm] $(@bind gap_mm Slider(1.0:0.5:10.0; default = 3.0, show_value = true)) ·
motor twisting force at the wheels [kN·m] $(@bind T_kNm Slider(8:1:20; default = 12, show_value = true))
"""

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

# ╔═╡ ea9d018d-4072-4aa5-985a-ee34fcae04d3
let l = main_limit(suction.limits)
    headline("With suction, $(l.name) $(l.verb) the push for $(fmt(100 * l.share, 0)) % of the run: 60 mph in $(fmt(suction.t60)) s")
end

# ╔═╡ 71b6de44-ece9-5e3f-ad46-e1a5f649b945
limit_map(suction.sol, launch_rig.sys; until = min(suction.t60, 6.0))

# ╔═╡ 138ea814-3a72-52c2-942f-bbaae57968a0
md"""
**Try this:** raise the motor's twisting force to 20 kN·m. The time drops to
$(fmt(hints.suction_T20)) s (2,000 kg, RWD), and the tires and the power become the limit again.
"""

# ╔═╡ a3d6b00c-9a9c-5405-a396-0c3f88a25de3
md"""
## Claim 2 · Simulation: the fan's power bill

The skirt gap changes what the fan costs, not how fast the car goes.
"""

# ╔═╡ 80ced0ea-f948-40a3-89e3-42a4f303733c
headline("At a $(gap_mm) mm gap the fan needs $(fmt(suction.fan_power / 1e3, 0)) kW. Upside down, the suction holds $(fmt(suction.hold_margin))× the car's weight.")

# ╔═╡ c46c6e9a-7269-5b19-8662-d14ef54554ad
let
    gaps = range(1, 10; length = 100)
    dp = fan_cmd * 4700 * G0 / 4.0
    power = fan_power_closed_form.(dp, gaps ./ 1e3) ./ 1e3
    plt = plot(gaps, power; lw = 3, color = :steelblue, label = "fan power at this fan setting",
        xlabel = "Gap under the skirt (mm)", ylabel = "Fan power (kW)", legend = :topleft,
        ylims = (0, 1.1 * max(maximum(power), 80)))
    plot!(plt, gaps, fan_power_closed_form.(car.m * G0 / 4.0, gaps ./ 1e3) ./ 1e3; lw = 2,
        color = :seagreen, label = "least power to hang $(car.m) kg upside down")
    hline!(plt, [80]; color = :gray, ls = :dot, label = "4 × 20 kW (Electrek's estimate)")
    right = gap_mm < 6
    mark!(plt, gap_mm, suction.fan_power / 1e3,
        "the model: $(fmt(suction.fan_power / 1e3, 0)) kW at $(gap_mm) mm";
        dx = right ? 0.3 : -0.3, dy = (right ? 0.45 : -0.2) * max(maximum(power), 80),
        halign = right ? :left : :right, valign = right ? :bottom : :top)
    plt
end

# ╔═╡ 691785d8-5309-5564-8bdf-c62da7f64403
md"""
**Try this:** set the skirt gap to 10 mm. The fan needs
$(fmt(fan_power_closed_form(fan_cmd * 4700 * G0 / 4.0, 0.010) / 1e3, 0)) kW, and the car is no
faster.
"""

# ╔═╡ 3fa37ac3-eeae-5b31-8c9d-0ee094052260
md"## Claim 2 · Verdict"

# ╔═╡ b699e8ab-5de0-5351-b54c-703476a2f793
verdict_box(verdicts.suction.light, verdicts.suction.sentence,
    "**The number that decides it:** $(verdicts.suction.decides)")

# ╔═╡ b6f85d2f-d29d-57a7-8e5a-f88d50751bff
md"""
## Claim 3: the air thrusters

**The question:** how hard can a jet of compressed air push the car, and for how long?

**Like letting go of a blown-up balloon.** The air rushes out the back, and the balloon shoots
forward. Here the air is at 380 bar, about **$(fmt(everyday.tire_x, 0)) times the pressure in a
car tire**, which holds about $(fmt(everyday.tire_bar, 0)) bar.

**Tesla's claim** (the "SpaceX package").
- **10 thrusters** run on compressed air in **600 L** of carbon-wrapped tanks (Tesla).
- **Over 80 kN** from 4 rear nozzles (press report). That is the weight of
  **$(fmt(everyday.cars_80kN, 0)) small cars** of $(fmt(everyday.small_car, 0)) kg.
- About **250 kg** of air (press report).
- The tank pressure was not published. A cabin readout showed **380 bar**; Electrek says
  **690 bar**.
"""

# ╔═╡ 9af7179d-1a05-5fbb-84e8-358e9a628405
md"""
## Claim 3 · Physics check: how much air is in the tank?

**In words:** mass of air = pressure × volume ÷ (gas constant × temperature). This is the ideal
gas law.

```math
m = \frac{p V}{R T}
```
"""

# ╔═╡ 77381c04-003d-4a68-907f-09a10e7c9cc4
html_table(["", "Symbol", "Value"], [
    ("tank pressure", "p", "380 bar = 38,000,000 Pa"),
    ("tank volume", "V", "600 L = 0.6 m³"),
    ("gas constant of air", "R", "287 J/(kg·K)"),
    ("temperature, 20 °C", "T", "293 K"),
    ("mass of air", "m", "**$(fmt(paper.m_air, 0)) kg**, about $(fmt(everyday.adults_air, 0)) adults of $(fmt(everyday.adult, 0)) kg"),
]; widths = ["45%", "15%", "40%"])

# ╔═╡ c5510e19-2ca7-4658-bfb8-21edfae45a79
md"""
**So what?** That fits the reported 250 kg. The car carries the weight of about
$(fmt(everyday.adults_air, 0)) adults in air, and every kilogram it blows out is gone.
"""

# ╔═╡ 4a0da2f8-be59-5215-abc1-0471fdfeb2a1
md"""
## Claim 3 · Physics check: thrust at full pressure

**In words:** thrust = air leaving per second × jet speed.

```math
F = \dot m \, v_e
```
"""

# ╔═╡ ef405783-9048-45f7-93f9-bac786ee13b5
html_table(["", "Symbol", "Value"], [
    ("air leaving per second, 4 nozzles of about 20 mm", "ṁ", "$(fmt(paper.mdot, 0)) kg/s"),
    ("jet speed", "v_e", "$(fmt(paper.v_e, 0)) m/s, about twice the speed of sound"),
    ("thrust", "F", "**$(fmt(paper.F0 / 1e3, 0)) kN**"),
]; widths = ["45%", "15%", "40%"])

# ╔═╡ 3df111a6-c669-442d-9299-fe480bf3f762
md"""
**So what?** 80 kN is possible at 380 bar. But at $(fmt(paper.mdot, 0)) kg per second, the
$(fmt(paper.m_air, 0)) kg of air would last only $(fmt(paper.t_empty, 1)) s.
"""

# ╔═╡ 05406320-5e1c-4b2a-9d07-2323b0976b24
details("Details: the air per second and the jet speed", md"""
In the narrowest part of the nozzle, the throat, the air reaches the speed of sound and cannot
go faster. Then the air per second grows in step with the tank pressure ``p`` and the throat
area ``A_t``:

```math
\dot m = A_t\, p\, \sqrt{\frac{\gamma}{R T}} \left(\frac{2}{\gamma + 1}\right)^{\frac{\gamma + 1}{2(\gamma - 1)}},
\qquad
v_e = \sqrt{2 c_p T \left(1 - \left(\frac{p_a}{p}\right)^{\frac{\gamma - 1}{\gamma}}\right)}
```

with ``A_t = 1{,}286`` mm², ``\gamma = 1.4`` and ``c_p = 1005`` J/(kg·K) for air, and outside
pressure ``p_a = 1`` bar. After the throat the air expands to outside pressure and speeds up to
``v_e``.
""")

# ╔═╡ e2dddf66-0017-55ad-b309-5f9cc11d72ee
md"""
## Claim 3 · Physics check: the tank runs down

**In words:** as air leaves, the pressure in the tank falls, and the thrust falls with it. The
air also cools as it expands, which lowers the pressure further.

Worked out by hand for 380 bar:
"""

# ╔═╡ d61b4d3f-20b3-52e0-ba5a-9412c5c0dacf
let
    ts = (0.0, 0.5, 1.0, 2.0)
    rows = [blowdown_closed_form(t) for t in ts]
    html_table(["", ("t = $(t) s" for t in ts)...], [
        ("air left [kg]", (fmt(r.m, 0) for r in rows)...),
        ("pressure [bar]", (fmt(r.p / 1e5, 0) for r in rows)...),
        ("thrust [kN]", (fmt(r.F / 1e3, 0) for r in rows)...),
    ]; numeric = 2:5)
end

# ╔═╡ 269eead9-b7e2-51f8-824a-cf060460e1f5
md"""
**So what?** 80 kN is the thrust at the moment the valve opens. Half a second later only
$(fmt(blowdown_closed_form(0.5).F / 1e3, 0)) kN is left.
"""

# ╔═╡ b6af0980-5e1c-4e9a-bfc5-0c6c33605abc
details("Details: how fast the pressure falls", md"""
We assume

```math
\frac{p}{p_0} = \Big(\frac{m}{m_0}\Big)^{n}
```

- ``p_0``, ``m_0``: pressure and air mass at the start; ``p``, ``m``: the same later
- ``n`` says how much the air cools as it expands. ``n = 1.4``: the air leaves too fast to warm
  up from the tank walls, so it cools as much as it can. ``n = 1``: it stays at room temperature.

With the air per second from the previous slide, this gives an equation for ``m(t)`` that can be
solved by hand. The table uses ``n = 1.4``.
""")

# ╔═╡ 7048f135-2533-5d1b-90f4-68eb7f5e573c
md"""
## Claim 3 · Our model: tank and nozzle on a test stand

Before we put the thrusters on the car, we test them on a stand bolted to the floor. **Read the
diagram left to right:** tank → nozzle → stand.
"""

# ╔═╡ 021a90c8-0fd4-456d-bdbb-2e3af63f88d0
html_table(["Block", "In the real car", "What it does"], [
    ("command", "the driver's thrust button", "1 opens the valve fully"),
    ("tank", "the carbon-wrapped air tanks", "holds the air; its pressure and temperature fall as air leaves"),
    ("nozzle", "the four rear nozzles", "turns the tank pressure into air per second, jet speed and thrust; shuts below 2 bar"),
    ("fixed", "a test stand bolted to the floor", "holds the nozzle still, so we can read the thrust"),
]; widths = ["14%", "32%", "54%"])

# ╔═╡ 1ee75699-b8fe-5cad-beb0-d3e0967e7041
diagrams([joinpath(img_dir, "cold-gas-thrust-stand.png") =>
    "`TestColdGasThrustStand`: tank, nozzle and a fixed stand, valve fully open."]; height = "300px")

# ╔═╡ 6d1930fd-1787-5449-acfa-579396d3b31b
dyad_fold("AirTank", "ColdGasNozzle")

# ╔═╡ 098ef777-bbf4-5a29-9f6f-e994f3418774
md"""
## Claim 3 · Simulation: emptying the tank on the stand

start pressure [bar] $(@bind p0_bar Slider(300:10:690; default = 380, show_value = true)) ·
tank [L] $(@bind V_L Slider(200:50:600; default = 600, show_value = true)) ·
cooling n (1 = stays warm, 1.4 = cools) $(@bind n_poly Slider(1.0:0.05:1.4; default = 1.4, show_value = true)) ·
nozzle $(@bind throat Select(["fixed" => "fixed: 80 kN at 380 bar", "scaled" => "resized: 80 kN at any pressure"]))
"""

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
        m0 = sol(0.0, idxs = stand_rig.sys.tank.m_g), ms = 1000 * (time() - t_start))
end;

# ╔═╡ 3e1d4055-ed9a-40be-950b-0b23d345952d
headline("Thrust starts at $(fmt(blowdown.marks.F0 / 1e3, 0)) kN and falls below 80 % after $(fmt(blowdown.marks.t80)) s")

# ╔═╡ 454b7935-c1c3-5914-b6f5-ad13edd86d01
let
    sys = stand_rig.sys
    ts = range(0, 6; length = 600)
    F(sol) = sol(ts, idxs = sys.nozzle.F).u ./ 1e3
    (; F0, t80, t50) = blowdown.marks
    plt = plot(ts, F(blowdown.ghost); lw = 2, color = :gray, alpha = 0.6,
        label = blowdown.ghost_n == 1.0 ? "same tank, air kept warm" : "same tank, air cooling",
        xlabel = "Time since the valve opened (s)", ylabel = "Thrust (kN)", legend = :topright)
    plot!(plt, ts, F(blowdown.sol); lw = 3, color = :black, label = "thrust from the model")
    plot!(plt, ts, [blowdown_closed_form(t; tank_setup...).F / 1e3 for t in ts]; lw = 2,
        ls = :dot, color = :darkorange, label = "thrust from the hand formula")
    isfinite(t80) && mark!(plt, t80, 0.8 * F0 / 1e3, "below 80 % after $(fmt(t80)) s";
        dx = 0.4, dy = 0.1 * F0 / 1e3)
    isfinite(t50) && mark!(plt, t50, 0.5 * F0 / 1e3, "half after $(fmt(t50)) s"; dx = 0.4,
        dy = 0.1 * F0 / 1e3)
    air = twinx(plt)
    plot!(air, ts, blowdown.sol(ts, idxs = sys.tank.m_g).u; lw = 2, color = :seagreen,
        ylabel = "Air left in the tank (kg), green", label = "", ylims = (0, Inf))
    plt
end

# ╔═╡ d656e5a8-e471-5ec3-a538-ed704c557b90
md"""
**Try this:** set the tank to 200 L. The thrust stays above 80 % for only
$(fmt(hints.stand_200L.t80)) s.
"""

# ╔═╡ a1eebfaa-ac28-5511-80f8-83ac87cbd423
md"## Claim 3 · Verdict"

# ╔═╡ e7533517-ea75-5361-b8a2-bb60c67ca3af
verdict_box(verdicts.thrusters.light, verdicts.thrusters.sentence,
    "**The number that decides it:** $(verdicts.thrusters.decides)")

# ╔═╡ b5dbdf36-0e13-5f76-bf1f-e829202924f3
md"""
## Claim 4: 0–60 mph in under a second

**The question:** the air jets push the car's body directly. With that extra push, can it beat
one second?

**Like getting a shove in the back while you sprint.** Your legs still push on the ground, and
the shove adds to it. The shove does not need grip.

**Tesla's claim.**
- A recorded run took **1.0 s**. A live run took **0.81 s**; problems with the timer were
  reported.
- **Thrust version** (rear thrusters): **under 0.9 s**. Electrek says it carries 200 L of air.
- **Rocket version** (10 thrusters, 600 L): **under 0.59 s**.
- A 0.55 s figure started the clock after the car had rolled 30 cm, which is worth about 0.1 s.
"""

# ╔═╡ be9624be-871f-5fd8-a3e7-ee4bf5bc1943
md"""
## Claim 4 · Physics check: what the times demand

**In words:** push per kilogram needed = speed ÷ time, as in Claim 1.

```math
a = \frac{v_{60}}{t}
```
"""

# ╔═╡ 28d1e0a8-9372-54b2-bad9-020c0efdcf5f
html_table(["Target", "Time", "Push needed, in car weights"], [
    ("recorded run", "1.0 s", "$(fmt(V60 / 1.0 / G0))"),
    ("Thrust version", "0.9 s", "$(fmt(V60 / 0.9 / G0))"),
    ("live run", "0.81 s", "$(fmt(V60 / 0.81 / G0))"),
    ("Rocket version", "0.59 s", "$(fmt(V60 / 0.59 / G0))"),
]; widths = ["40%", "25%", "35%"], numeric = 2:3)

# ╔═╡ 84175052-570e-4611-b506-cc1593c6a03d
md"""
**So what?** Every one of Tesla's times needs a push of more than
$(fmt(V60 / 1.0 / G0, 1)) times the car's weight. The tires alone give at most
$(fmt(paper.F_tire / paper.W)).
"""

# ╔═╡ 8af337a6-0282-50b5-a98e-142755a66f42
md"""
## Claim 4 · Physics check: what the thrust adds

**In words:** extra push, in car weights = thrust ÷ the car's weight.

```math
\frac{F}{m g}
```
"""

# ╔═╡ 5a772d46-7fc0-4baf-bf62-6f59e18c3e19
html_table(["", "Symbol", "Value"], [
    ("thrust at the start", "F", "$(fmt(paper.F0 / 1e3, 0)) kN"),
    ("weight of a 2,000 kg car", "m g", "$(fmt(paper.W / 1e3, 1)) kN"),
    ("extra push", "F / m g", "**$(fmt(paper.thrust_g)) car weights**"),
]; widths = ["45%", "15%", "40%"])

# ╔═╡ 5e0e82fd-9a18-4646-b41e-db24632ba70c
md"""
**So what?** At the start, the jets alone push with $(fmt(paper.thrust_g, 1)) car weights, more
than the $(fmt(paper.a_081)) that 0.81 s needs. But Claim 3 showed the thrust fading fast, so
only a simulation can tell whether the average stays high enough.
"""

# ╔═╡ 86a55819-b811-42f1-acfd-9f41bd490ea9
details("Details: thrust plus tires", md"""
The thrust pushes the body, not the tires, so it adds to whatever the tires give:

- **Thrust and tires, RWD:** $(fmt(paper.thrust_g)) plus $(fmt(paper.rwd_rest_g)) from the rear
  tires at rest, about **$(fmt(paper.thrust_g + paper.rwd_rest_g, 1)) car weights**.
- **Thrust and suction:** $(fmt(paper.thrust_g)) plus $(fmt(paper.F_torque / paper.W)) from the
  motor, **$(fmt(paper.thrust_g + paper.F_torque / paper.W, 1)) car weights**.
""")

# ╔═╡ c7f8f3b8-8871-5e02-8132-9b03ce6868af
md"""
## Claim 4 · Our model: the full launch car

The same `RoadsterLaunch` as in Claim 1, now with the tank and the rear nozzles on. **Look at
the middle row of the diagram:** tank → nozzle → forward gain → forward force.
"""

# ╔═╡ f44d1e93-7039-49f5-82fb-c3b857140a62
html_table(["Block", "In the real car", "What it does"], [
    ("tank, nozzle", "the air tanks and the rear nozzles", "the same as on the test stand; the valves open fully at the start"),
    ("forward\\_gain", "the direction the nozzles point", "keeps the share of the thrust that points backward"),
    ("forward\\_force", "the nozzle mounts", "pushes the car body forward with that share"),
    ("downforce\\_sum", "nothing; a sum", "adds the share pointed down to the fan's downforce"),
]; widths = ["18%", "32%", "50%"])

# ╔═╡ 3b0984f3-b69f-54b9-91f1-30fab8cc7881
diagrams([joinpath(img_dir, "roadster-launch.png") =>
    "`RoadsterLaunch`. Middle row: tank, nozzle, forward gain and forward force. The line from the nozzle up to the downforce sum carries the share pointed down."]; height = "300px")

# ╔═╡ 75e1037e-5a0a-50f2-a755-29e7037ba07e
dyad_fold("RoadsterLaunch")

# ╔═╡ 72348138-0b2c-5966-bd28-17c6185490bf
md"""
## Claim 4 · Simulation: speed with thrust

air jets $(@bind use_thrust CheckBox(default = true)) ·
suction fan $(@bind use_suction CheckBox(default = false)) ·
tank $(@bind tank_choice Select(["600 L" => "600 L (Tesla, total)", "200 L" => "200 L (Thrust version, Electrek)"])) ·
share of the jet pointed down $(@bind down_fraction Slider(0.0:0.05:1.0; default = 0.0, show_value = true))

*Tank pressure, cooling and nozzle come from the Claim 3 sliders.*
"""

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

# ╔═╡ 77c576de-e638-4bf2-96fa-8892c107d220
headline(!isfinite(thrust_launch.t60) ? "These settings never reach 60 mph" :
    "Your settings: 60 mph after $(fmt(thrust_launch.t60)) s, $(thrust_launch.t60 < 0.81 ? "faster" : "slower") than Tesla's live 0.81 s")

# ╔═╡ 309bafac-d1f8-5e0a-b637-83a654847224
let
    sys = launch_rig.sys
    kmh(sol) = 3.6 .* sol[sys.v]
    plt = plot(xlabel = "Time since start (s)", ylabel = "Speed (km/h)", xlims = (0, 1.6),
        ylims = (0, 130), legend = :bottomright)
    for (case, name, style) in ((:tires_thrust, "tires + air jets", :solid),
                                (:suction_thrust, "suction + air jets", :dash),
                                (:thrust_200l, "suction + air jets, 200 L", :dot))
        r = reference[case]
        plot!(plt, r.sol.t, kmh(r.sol); lw = 1.5, color = :gray, ls = style,
            label = "2,000 kg, $(name): $(fmt(r.t60)) s")
    end
    plot!(plt, thrust_launch.sol.t, kmh(thrust_launch.sol); lw = 3, color = :steelblue,
        label = "your settings")
    hline!(plt, [3.6 * V60]; color = :black, ls = :dot, label = "60 mph")
    vline!(plt, [0.81]; color = :firebrick, ls = :dash, label = "Tesla's live run: 0.81 s")
    vline!(plt, [0.59]; color = :purple, ls = :dash, label = "Rocket version claim: 0.59 s")
    thrust_launch.t60 < 1.5 && mark!(plt, thrust_launch.t60, 3.6 * V60,
        "60 mph after $(fmt(thrust_launch.t60)) s, $(fmt(thrust_launch.air, 0)) kg of air";
        dx = -0.05, dy = 18, halign = :right, color = :steelblue)
    plt
end

# ╔═╡ 1c4c5bb1-294b-5030-8745-8fcf24911c6b
md"""
**Try this:** untick the air jets and tick the suction fan: $(fmt(hints.thrust_off_suction)) s.
The air jets are what get the car under a second.
"""

# ╔═╡ 8a0fa3f8-202e-50f4-9581-98cbd5938f11
md"""
## Claim 4 · Simulation: where the push comes from
"""

# ╔═╡ b67d030f-c790-4d9f-a386-9a1033b2bb9f
push_share = let
    sys = launch_rig.sys
    function share(sol, d, t_end)
        ts = range(0, min(t_end, 3.0); length = 300)
        tire = sum(sol(ts, idxs = sys.wheel.F_x).u)
        forward = (1 - d) * sum(sol(ts, idxs = sys.nozzle.F).u)
        forward / (tire + forward)
    end
    (now = share(thrust_launch.sol, down_fraction, thrust_launch.t60),
        suction = share(reference.suction_thrust.sol, 0.0, reference.suction_thrust.t60))
end;

# ╔═╡ bb4fc2ab-3377-49fd-917d-f02229d4bd40
headline("The air jets give $(fmt(100 * push_share.now, 0)) % of the push up to 60 mph")

# ╔═╡ 6a75b042-0d4f-54dc-937d-1f8ecffd98f4
let
    sys = launch_rig.sys
    sol = thrust_launch.sol
    ts = range(0, min(thrust_launch.t60, 3.0); length = 300)
    tire = sol(ts, idxs = sys.wheel.F_x).u ./ 1e3
    forward = (1 - down_fraction) .* sol(ts, idxs = sys.nozzle.F).u ./ 1e3
    grip = sol.ps[sys.mu_A] .* sol(ts, idxs = sys.axle.F_z).u ./ 1e3
    plt = plot(ts, tire; fillrange = 0, fillalpha = 0.35, lw = 2, color = :steelblue,
        label = "push from the tires", xlabel = "Time since start (s)",
        ylabel = "Push on the car (kN)", legend = :topright)
    plot!(plt, ts, tire .+ forward; fillrange = tire, fillalpha = 0.35, lw = 2,
        color = :firebrick, label = "+ push from the air jets")
    plot!(plt, ts, grip; lw = 2, ls = :dash, color = :seagreen, label = "most the tires can push")
    hline!(plt, [sol.ps[sys.motor.T_max] / sol.ps[sys.radius] / 1e3]; lw = 2, ls = :dash,
        color = :darkorange, label = "most the motor's torque allows")
    top = tire[1] + forward[1]
    forward[1] > 0 && mark!(plt, ts[1], top, "jets strongest at the start: $(fmt(forward[1], 0)) kN";
        dx = 0.25 * ts[end], dy = 0.05 * top)
    plt
end

# ╔═╡ 594df3dd-969c-5e42-bbfd-2a5521492f45
md"""
**Try this:** tick the suction fan. The tires push harder, and the jets' share drops to
$(fmt(100 * push_share.suction, 0)) % (2,000 kg, RWD, 380 bar).
"""

# ╔═╡ e3fe65ed-ec1f-52ef-a417-d8ef143deb5f
md"""
## Claim 4 · Simulation: push down or push back?

A plume over the roof in the video suggests that some air pushes the car down, for grip. Each
newton pushed down adds at most 0.86 N of tire push with RWD, and only until the motor's limit.
Each newton pushed back is a full newton forward.
"""

# ╔═╡ 7964c1c8-d477-4ae5-a695-a05b27451201
let
    n_back = count(c -> c.best == 0.0, down_grid.curves)
    headline("Point the air backward: that is fastest in $(n_back == length(down_grid.curves) ? "every case" : "$(n_back) of $(length(down_grid.curves)) cases")")
end

# ╔═╡ 0aeb3bc7-8037-575b-ad36-d81a5834ea0c
let
    plt = plot(xlabel = "Share of the jet pointed down (0 = all backward, 1 = all down)",
        ylabel = "Time to 60 mph (s)", legend = :topleft)
    for c in down_grid.curves
        plot!(plt, down_grid.fractions, c.t60; lw = 2, marker = :circle, ms = 3,
            label = "$(layout_name[c.layout]), fan $(c.fan_cmd == 1 ? "on" : "off")")
    end
    scatter!(plt, [down_fraction], [thrust_launch.t60]; ms = 9, marker = :star5,
        color = :black, label = "your settings")
    for c in down_grid.curves
        c.best > 0 && mark!(plt, c.best, minimum(c.t60),
            "$(layout_name[c.layout]), fan $(c.fan_cmd == 1 ? "on" : "off"): best at $(c.best)"; dx = 0.05, dy = -0.08,
            valign = :top)
    end
    plt
end

# ╔═╡ 4e29c85b-03d2-5502-8fed-f7d389f406bc
md"""
**Try this:** set the share pointed down to 1, all air pushing down:
$(fmt(hints.thrust_all_down)) s (RWD, fan off). That is no faster than suction alone, at
$(fmt(hints.thrust_off_suction)) s.
"""

# ╔═╡ 9ae7361b-cbcb-5ef8-8f87-8b1b4f5af276
md"## Claim 4 · Verdict"

# ╔═╡ 92d82a98-af32-53ec-8efc-79ce25173c66
verdict_box(verdicts.subsecond.light, verdicts.subsecond.sentence,
    "**The number that decides it:** $(verdicts.subsecond.decides)")

# ╔═╡ 4c7104d2-88a3-5822-a1d7-3b2cba51faea
md"""
## Claim 5: "it can fly"

**The question:** how high can 600 L of air lift the car, and how long can it stay up?

**Like holding a heavy bag at arm's length.** Lifting it once is quick. Holding it up costs
effort every second. A hover burns air every second, just to stay in place.

**Tesla's claim.**
- The event was billed as a car that flies. TechCrunch's headline: "Tesla reveals SpaceX-powered
  Roadster that flies".
- **Kickflip:** the car jumped over a row of cars while rolling a full turn. Video measurements
  give a top height of about **8 m**, about $(fmt(everyday.stories, 1)) floors of a house of
  $(fmt(everyday.story, 0)) m each.
- **What was shown:** hops, flips and short hovers. No longer flight.
- **Rocket version:** 4 of its 10 nozzles point down, at the corners.
"""

# ╔═╡ 1a79a088-861a-5983-8a1e-856a5dd2110a
md"""
## Claim 5 · Physics check: an 8 m hop

**In words:** take-off speed = √(2 × gravity × height). A ball thrown up at that speed just
reaches that height.

```math
v = \sqrt{2 g h}
```
"""

# ╔═╡ de59bdae-32bb-435c-822d-800fcb503940
html_table(["", "Symbol", "Value"], [
    ("height of the hop", "h", "8 m"),
    ("gravity", "g", "9.81 m/s²"),
    ("take-off speed", "v", "**$(fmt(paper.v_hop, 1)) m/s = $(fmt(everyday.hop_kmh, 0)) km/h**, straight up"),
]; widths = ["45%", "15%", "40%"])

# ╔═╡ f24b6a12-205d-47a2-a4e1-eb7db030e8f9
md"""
**So what?** The jets must throw a 2,000 kg car upward at $(fmt(everyday.hop_kmh, 0)) km/h. That
takes about $(fmt(paper.air_hop, 0)) kg of air, plus some more to carry the weight during the
burn: a small part of the $(fmt(paper.m_air, 0)) kg.
"""

# ╔═╡ cfb8fca3-eb96-4fb4-8876-497f9dcb5cae
details("Details: how much air the hop needs", md"""
To reach that speed, the jets must give the car a push × time of

```math
m v
```

That is 2,000 kg × $(fmt(paper.v_hop, 1)) m/s = $(fmt(paper.J / 1e3, 1)) kN·s.

Each kilogram of air leaves at ``v_e =`` $(fmt(paper.v_e, 0)) m/s, so the air needed is about
$(fmt(paper.J, 0)) ÷ $(fmt(paper.v_e, 0)) = $(fmt(paper.air_hop, 0)) kg. With 80 kN up and
$(fmt(paper.W / 1e3, 1)) kN of weight down, the burn lasts about $(fmt(paper.t_burn, 2)) s.
""")

# ╔═╡ 7c3d9060-9dde-5d5c-9c00-5b194e10e521
md"""
## Claim 5 · Physics check: hovering

To hover, the thrust must equal the weight. **In words:** air per second = the car's weight ÷
jet speed.

```math
\dot m = \frac{m g}{v_e}
```
"""

# ╔═╡ 7848f4a7-1e17-440d-bc6b-cb8348e8bc73
html_table(["", "Symbol", "Value"], [
    ("weight of a 2,000 kg car", "m g", "$(fmt(paper.W / 1e3, 1)) kN"),
    ("jet speed", "v_e", "$(fmt(paper.v_e, 0)) m/s"),
    ("air per second", "ṁ", "**$(fmt(paper.mdot_hover, 0)) kg/s**"),
]; widths = ["45%", "15%", "40%"])

# ╔═╡ 25979fe7-5ceb-4fbc-8947-938728d24341
md"""
**So what?** At $(fmt(paper.mdot_hover, 0)) kg per second, the $(fmt(paper.m_air, 0)) kg of air
would last at most $(fmt(paper.t_hover_ideal, 1)) s. In practice it lasts
**only $(fmt(paper.t_hover, 1)) s**: seconds, not minutes.
"""

# ╔═╡ 610466fd-c56a-459c-bd9c-1fbdd143a007
details("Details: why the real hover is shorter", md"""
As the pressure falls, even a fully open valve gives less thrust. Below some pressure it can no
longer carry the weight, and the car sinks, with air still in the tank. Adding up the air per
second until that moment gives

```math
t_{hover} = \frac{m_0}{m g} \int_{x^*}^{1} v_e(x)\, dx
```

where ``x = m / m_0`` is the share of air left and ``x^*`` the share at which full thrust drops
below the weight. For 2,000 kg at 380 bar that is $(fmt(paper.t_hover, 2)) s.
""")

# ╔═╡ 12ebe6b9-cf3d-5ac7-b05d-b34b359fd7d2
md"""
## Claim 5 · Physics check: hover time against mass

The same calculation for every mass and three tank pressures.
"""

# ╔═╡ ace950cb-604f-4e97-80ab-d2b72ba6fa26
headline("Even a 1,700 kg car at 690 bar hovers only $(fmt(hover_closed_form(1700.0; p0 = 690e5), 1)) s")

# ╔═╡ 65410189-b0b1-5e52-b267-63adb383edc6
let
    masses = range(1500, 2600; length = 56)
    plt = plot(xlabel = "Car mass (kg)", ylabel = "Time it can hover (s)", legend = :topright,
        ylims = (0, 16))
    vspan!(plt, [1700, 2350]; color = :gray, alpha = 0.15, label = "range of mass estimates")
    for (p0, color) in ((300e5, :steelblue), (380e5, :black), (690e5, :firebrick))
        plot!(plt, masses, hover_closed_form.(masses; p0); lw = 3, color,
            label = "600 L at $(round(Int, p0 / 1e5)) bar")
    end
    mark!(plt, 2000, paper.t_hover, "2,000 kg at 380 bar: $(fmt(paper.t_hover, 1)) s"; dx = 80,
        dy = -2.5, valign = :top)
    best = hover_closed_form(1700.0; p0 = 690e5)
    mark!(plt, 1700, best, "best case: $(fmt(best, 1)) s"; dx = 100, dy = 1.0,
        color = :firebrick)
    plt
end

# ╔═╡ beed5f9f-8952-52ec-99b0-990d9b107f48
md"""
## Claim 5 · Our model: the car as a vertical hopper

A new model, `VerticalHop`: the car can only move up and down. **Read the diagram left to
right:** command → tank → nozzle → thrust → body, with the ground under the body.
"""

# ╔═╡ 190fbe6b-f8d5-4df4-acf7-6184d91aa965
html_table(["Block", "In the real car", "What it does"], [
    ("command", "the driver, or the hover controller", "opens the valve: fully for a hop; just enough for a hover, like cruise control for height"),
    ("tank, nozzle", "the air tanks and the downward nozzles", "the same as on the test stand, now pointing down"),
    ("thrust", "the nozzle mounts", "pushes the car up"),
    ("body", "the car", "its mass, pulled down by gravity"),
    ("ground", "the road", "a stiff spring that can push the car up but never pull it down, so it can take off and land"),
]; widths = ["16%", "32%", "52%"])

# ╔═╡ 14d97564-3dfc-5b16-b9a7-e6437ceee636
diagrams([joinpath(img_dir, "vertical-hop.png") =>
    "`VerticalHop`: the command opens the nozzle, the thrust pushes the body up, and the ground holds it from below."]; height = "260px")

# ╔═╡ 490fbb26-bcc0-5883-9550-6bc4488356da
dyad_fold("VerticalGroundContact", "VerticalHop", "TestVerticalHop")

# ╔═╡ d7234072-bd91-5008-a8c7-bd27bf75fc30
md"""
## Claim 5 · Simulation: the hop

burn time [s] $(@bind t_b Slider(0.2:0.001:0.8; default = 0.413, show_value = true))
"""

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

# ╔═╡ c4612db8-63e1-468b-8af2-f96ea23abbee
headline("A $(t_b) s burn lifts $(car.m) kg to $(fmt(hop_run.apex.apex, 1)) m, for $(fmt(hop_run.air, 0)) kg of air")

# ╔═╡ 7297e311-1114-51f5-9256-06ee3e0555a4
let
    sys = hop_rig.sys
    t_end = min(2 * hop_run.apex.t_apex + 0.3, hop_run.sol.t[end])
    ts = range(0, t_end; length = 500)
    top = max(10, 1.2 * hop_run.apex.apex)
    plt = plot(ts, hop_run.sol(ts, idxs = sys.hop.altitude).u; lw = 3, color = :steelblue,
        label = "the car's height (model)", xlabel = "Time since the valves opened (s)",
        ylabel = "Height (m)", legend = :topright, ylims = (-0.5, top))
    hline!(plt, [hop_run.closed_apex]; color = :darkorange, ls = :dash,
        label = "highest point, hand formula")
    hline!(plt, [8.0]; color = :gray, ls = :dot, label = "kickflip height: 8 m")
    vline!(plt, [t_b]; color = :firebrick, ls = :dot, label = "valves close")
    mark!(plt, hop_run.apex.t_apex, hop_run.apex.apex,
        "highest point: $(fmt(hop_run.apex.apex, 1)) m"; dx = 0.25 * t_end, dy = -0.15 * top)
    plt
end

# ╔═╡ 05e11080-54c1-5b8c-8a82-34521a4482e8
md"""
**Try this:** set the burn time to 0.6 s. The car climbs to $(fmt(hints.hop_06, 1)) m
(2,000 kg).
"""

# ╔═╡ 0c45b5dd-4778-5b23-867c-ce6b58559e15
md"""
## Claim 5 · Simulation: hover

start pressure [bar] $(@bind p0_hover Slider(300:10:690; default = 380, show_value = true))
"""

# ╔═╡ 72c966ff-94be-574b-9a41-d1909b728c48
hover_run = let
    t_start = time()
    sol = solve_with(hover_rig; m = car.m, tank_pressure = p0_hover * 1e5)
    t_hover = hover_time(sol, hover_rig.sys)
    air_left = isfinite(t_hover) ? sol(t_hover, idxs = hover_rig.sys.hover.tank.m_g) : NaN
    p_left = isfinite(t_hover) ? sol(t_hover, idxs = hover_rig.sys.hover.tank.p) : NaN
    (; sol, time = t_hover, air_left, p_left,
        closed = hover_closed_form(car.m; p0 = p0_hover * 1e5), ms = 1000 * (time() - t_start))
end;

# ╔═╡ 0aea8a28-ea91-4cb3-af7a-5f8a56f400d8
headline(isfinite(hover_run.time) ?
    "The car stays up for $(fmt(hover_run.time, 1)) s. Then $(fmt(hover_run.air_left, 0)) kg of air at $(fmt(hover_run.p_left / 1e5, 0)) bar can no longer carry it." :
    "At these settings the car does not get off the ground")

# ╔═╡ 4ce799f5-e25f-5455-92cf-7868dc713552
let
    sys = hover_rig.sys
    ts = range(0, 15; length = 1500)
    plt = plot(ts, hover_run.sol(ts, idxs = sys.hover.altitude).u; lw = 3, color = :steelblue,
        label = "the car's height", xlabel = "Time since start (s)", ylabel = "Height (m)",
        legend = :topright, ylims = (-0.5, 3.5))
    if isfinite(hover_run.time)
        vline!(plt, [hover_run.time]; color = :firebrick, ls = :dash, label = "valve fully open")
        h = hover_run.sol(hover_run.time, idxs = sys.hover.altitude)
        # Late saturation would push a right-hand label past the plot edge.
        late = hover_run.time > 7.5
        mark!(plt, hover_run.time, h, "valve fully open after $(fmt(hover_run.time, 1)) s: the car sinks";
            dx = late ? -1.0 : 1.0, dy = 0.9, color = :firebrick, halign = late ? :right : :left)
    end
    # The valve curve lives on the twin axis, which has no legend of its own.
    plot!(plt, [NaN], [NaN]; lw = 2, color = :darkorange, label = "valve opening (right axis)")
    valve = twinx(plt)
    plot!(valve, ts, hover_run.sol(ts, idxs = sys.hover.command).u; lw = 2, color = :darkorange,
        ylabel = "Valve opening (0 = shut, 1 = fully open)", ylims = (0, 1.1), label = "")
    plt
end

# ╔═╡ 1eb22217-6b48-5fd1-bbd0-29ab9b184fdf
md"""
**Try this:** set the start pressure to 690 bar. The hover lasts
$(fmt(hover_grid.times[2, 3], 1)) s (2,000 kg): still seconds.
"""

# ╔═╡ 915b1cfd-3760-5fcf-8a85-8ed0e1e48109
md"""
## Claim 5 · Simulation: hover time for every mass and pressure

Each cell is one run of the hover model, done when the notebook opens. Rows are the car mass,
columns the start pressure of the 600 L tank.
"""

# ╔═╡ 62cc1624-ca88-5b76-9cef-c99bf1e68897
html_table(["hover time [s]", "300 bar", "380 bar", "690 bar"],
    [("**$(m) kg**", fmt.(hover_grid.times[i, :], 2)...) for (i, m) in enumerate(hover_grid.masses)];
    numeric = 2:4)

# ╔═╡ 01e4001b-78f3-53f2-b887-c5730fb68f6e
md"""
**So what?** The best case, a 1,700 kg car at 690 bar, hovers for
$(fmt(maximum(hover_grid.times), 1)) s. The worst, 2,350 kg at 300 bar, for
$(fmt(minimum(hover_grid.times), 1)) s.
"""

# ╔═╡ b05ee7f3-2185-518f-9536-7635c28a8067
md"""
## Claim 5 · Extra: what does the kickflip roll cost?

Spinning the car takes little air compared with lifting it. **In words:** air needed = spin to
give ÷ (how far the nozzles sit from the middle × jet speed).

```math
m_{air} = \frac{I\, \omega}{a\, v_e}
```

- ``I \approx 870`` kg·m²: how hard the car is to spin (estimated)
- ``\omega``: how fast it rolls; ``a``: how far the nozzles sit from the roll axis

roll rate [°/s] $(@bind roll_rate Slider(90:1:360; default = 177, show_value = true)) ·
nozzle distance a [m] $(@bind arm Slider(0.6:0.05:1.2; default = 0.9, show_value = true))
"""

# ╔═╡ efcd227c-be87-5b78-b0a3-49f80f436147
let
    I_roll = 870.0
    air = I_roll * deg2rad(roll_rate) / arm / paper.v_e
    md"""
    **So what?** **$(fmt(air, 1)) kg** of air starts the roll, and **$(fmt(2air, 1)) kg** starts
    and stops it, against $(fmt(hop_run.air, 0)) kg for the hop. Spinning is cheap; lifting is
    expensive.
    """
end

# ╔═╡ 1d30f2e4-a668-58d4-8945-17fc3d94ef27
md"## Claim 5 · Verdict"

# ╔═╡ 4130d78a-3223-5804-899c-07e48ca7ae66
verdict_box(verdicts.fly.light, verdicts.fly.sentence,
    "**The number that decides it:** $(verdicts.fly.decides)")

# ╔═╡ bf6dd588-2b9e-42d9-a78c-27325c45b5ca
# One source for the verdict slides and the scoreboard, so the two always agree.
verdicts = let
    (; F0, t80) = blowdown.marks
    tires_ok = tires.t60 <= 1.0
    suction_ok = suction.t60 <= 1.05 * 1.6 && suction.hold_margin >= 1
    thrust_ok = F0 >= 0.95 * 80e3
    n_trims = (trims.thrust < 0.9) + (trims.rocket < 0.59)
    hop_ok = hop_run.apex.apex >= 7.5
    flies = isfinite(hover_run.time) && hover_run.time > 60
    (
        tires = (light = tires_ok ? :yes : :no, claim = "1: 0–60 mph in 1 s on tires",
            tesla = "1.0 s", model = "$(fmt(tires.t60)) s",
            sentence = tires_ok ? "At this grip, the tires alone could do it." :
                       "Tires alone can't do it.",
            decides = "a 1 s run needs grip $(fmt(max(grip_need.rwd_1, grip_need.awd_1), 1)); real tires have 1.26. On tires alone the model needs $(fmt(tires.t60)) s."),
        suction = (light = suction_ok ? :yes : :no, claim = "2: suction fan, under 1.6 s, upside down",
            tesla = "under 1.6 s", model = "$(fmt(suction.t60)) s, holds $(fmt(suction.hold_margin))× weight",
            sentence = suction_ok ? "Suction can give about 1.6 s and hold the car upside down." :
                       "At these settings, suction falls short of Tesla's claim.",
            decides = "with suction the motor sets the pace: $(fmt(suction.t60)) s against Tesla's 1.6 s, and the suction holds $(fmt(suction.hold_margin)) times the car's weight."),
        thrusters = (light = thrust_ok ? :partly : :no, claim = "3: over 80 kN of thrust",
            tesla = "over 80 kN", model = "$(fmt(F0 / 1e3, 0)) kN, above 80 % for $(fmt(t80)) s",
            sentence = thrust_ok ? "80 kN is real, but only for a moment." :
                       "At this pressure the thrusters do not reach 80 kN.",
            decides = thrust_ok ? "the thrust stays above 80 % of its start for only $(fmt(t80)) s." :
                      "$(fmt(F0 / 1e3, 0)) kN at the start."),
        subsecond = (light = n_trims == 2 ? :yes : n_trims == 1 ? :partly : :no,
            claim = "4: under 0.59 s with thrust", tesla = "under 0.59 s",
            model = "$(fmt(trims.rocket)) s",
            sentence = n_trims == 2 ? "With the air jets, under a second is possible." :
                       n_trims == 1 ? "With the air jets, under a second works, but not every claimed time." :
                       "At these settings, the air jets do not reach Tesla's times.",
            decides = "with suction and air jets the model needs $(fmt(trims.rocket)) s (claim: under 0.59 s), and $(fmt(trims.thrust)) s with 200 L (claim: under 0.9 s). At 2,350 kg: $(fmt(hints.thrust_m2350)) s."),
        fly = (light = flies ? :yes : hop_ok ? :partly : :no, claim = "5: it can fly",
            tesla = "8 m hop, \"it can fly\"",
            model = "hop $(fmt(hop_run.apex.apex, 1)) m, hover $(fmt(hover_run.time, 1)) s",
            sentence = flies ? "It can fly." : hop_ok ? "It can hop, but it can't fly." :
                       "At these settings it can't even make the 8 m hop.",
            decides = "the air lasts $(fmt(hover_run.time, 1)) s of hovering, so it can hop $(fmt(hop_run.apex.apex, 1)) m but not fly."),
    )
end;

# ╔═╡ 4f6ecd1c-90bb-52bd-85da-d989ab7adc4a
score_rows = [verdict_row(v.claim, v.tesla, v.model, v.light) for v in values(verdicts)];

# ╔═╡ 4378f115-d8fc-5392-9deb-ead3ccf2eb03
md"""
## Scoreboard

One row per verdict. The model column follows the panel and the sliders.
"""

# ╔═╡ 1a1cf665-5227-5108-b6d8-6a9c8e955454
let
    word = Dict(:yes => "plausible", :partly => "partly", :no => "**not plausible**",
        :pending => "not reached")
    html_table(["claim", "Tesla", "model", "verdict"],
        [(r.claim, r.tesla, r.model, word[r.verdict]) for r in score_rows];
        widths = ["34%", "20%", "30%", "16%"])
end

# ╔═╡ 14bd41f4-6154-55bd-84db-91319ba078bd
scoreboard(score_rows)

# ╔═╡ fd52d12c-fa1f-5fc5-bf6c-369a33a56041
let
    rwd, half = fmt(reference.rwd.t60, 1), fmt(blowdown_marks(stand_rig.default, stand_rig.sys).t50, 1)
    fast, slow = fmt(reference.suction_thrust.t60), fmt(reference.thrust_200l.t60)
    air = fmt(reference.suction_thrust.air, 0)
    hop_air = fmt(air_used(hop_rig.default, hop_rig.sys, 0.413; tank = "hop.tank"), 0)
    hover = fmt(hover_grid.times[2, 2], 0)
    md"""
    ## Summary

    - **Tires alone cannot do it.** Tesla's own 1.26 g tire gives $(rwd) s with rear-wheel
      drive.
    - **Suction can give 1.6 s.** It moves the limit from the tires to the motor. The skirt gap
      sets the fan's power bill.
    - **The thrusters give 80 kN only for a moment.** The thrust halves within about $(half) s.
    - **With the air jets, under a second is possible:** $(fast) to $(slow) s, for about $(air) kg
      of air.
    - **It hops; it does not fly.** The 8 m hop costs $(hop_air) kg of air; a hover lasts about
      $(hover) s.

    What to take away:
    - **Write the limit down first.** Every verdict started from one limit: grip, motor, or the
      air in the tank.
    - **Find which limit is active.** Suction did not add power; it moved the limit.
    - **A peak is not a level.** A tank that empties gives a short burst, not a steady push.
    - **Check the simulation with a hand calculation.** Each model result matched its formula.
    """
end

# ╔═╡ d58a74a2-207c-5a35-a637-ac0ec44ff8b3
md"""
## Sources

- Tesla: [The Ramp | Roadster](https://www.youtube.com/watch?v=7p5LxFdc-Qg) and
  [The Kickflip | Roadster](https://www.youtube.com/watch?v=r5vsHHPVhJg).
- Electrek: [technical look](https://electrek.co/2026/10/15/an-updated-technical-look-at-teslas-kick-flipping-0-60-in-1s-next-gen-roadster/)
  and [unveil](https://electrek.co/2026/10/15/tesla-unveils-cyberfied-new-roadster-kickflip/).
- Paul Tan, on-screen readouts: [article](https://paultan.org/2026/10/16/tesla-roadster-revealed-flies-on-spacex-air-thrusters-0-96-km-h-in-0-81s-production-2028/).
- [TechCrunch](https://techcrunch.com/2026/10/15/tesla-reveals-spacex-powered-roadster-that-flies-and-falls-with-style/),
  [Motor1](https://www.motor1.com/news/812195/tesla-roadster-stunt-2028-production/),
  [Teslarati on the fans](https://www.teslarati.com/tesla-roadster-downforce-fan-system/).
- Third-party physics: [CellCog](https://cellcog.ai/blog/tesla-roadster-physics/).

Tesla published neither the mass nor the tank pressure. The 80 kN and 250 kg figures are press
reports.
"""

# ╔═╡ a34943ff-7ff3-55a6-9bd4-bca6a4c03be9
md"""
## Appendix: checks against the recorded results

*This slide is for checking the notebook, not for the talk.* It runs the default cases again,
independent of the sliders, and compares them with the numbers in `docs/roadster-dyad-tasks.md`
and `test/roadster_plausibility.jl`. A failing check stops the headless run.
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
# ╟─73d1f345-c3c2-4f93-9873-b260ea105299
# ╟─0642455c-1da3-51e6-81ff-e990d6acb591
# ╟─40ef78e6-32c9-5c2d-9f7e-b2839b5a029d
# ╟─d1e686ea-7b9d-50b5-8585-e5b5bd5a5077
# ╟─d3171829-f6d6-55d0-b2eb-713d6ad7a265
# ╟─594f15a5-e0fa-48db-90fe-c4e7000f5a53
# ╟─bba2cff6-1f60-4b91-8e2b-4fd99af262b0
# ╟─a7fe0fee-f9f4-42d4-8665-e3e62243f675
# ╟─e4766715-9580-44d7-8765-673c658347de
# ╟─d73c9887-b6d8-5fad-9d96-d7566fc823bb
# ╟─b80af6e2-b5e3-5bdd-97dd-0a6ecf66c074
# ╟─6db050a1-68fc-5767-abf9-74ddea7261d8
# ╟─1bf3759a-417c-5ada-8ebd-6a35dad71f88
# ╟─f1ce64c1-2d6f-5c29-9ba3-ed6dbb15ddc3
# ╟─95427193-c160-57c3-b436-5cf573efc3bc
# ╟─4840cb3d-63a4-519e-b5e9-3cb89de6a41b
# ╟─bb74c430-4f14-5088-bcf4-a82715e51758
# ╟─f8dc7c02-1ddb-5ae9-b536-1c2c2679a8fb
# ╟─9c543dcc-f871-5328-901c-efe1abd6c9de
# ╟─7780ed0f-6df7-4acc-b67a-4cb4a7c9f608
# ╟─81a4f22b-73e4-4385-9c09-5cadf0bdf949
# ╟─ca3fab0a-57b4-5859-b505-19746d073c33
# ╟─ceba3a95-cacc-5e9b-9677-0c3d0016913f
# ╟─e2facb87-8c7c-4e2b-813e-5b5661d79edd
# ╟─385f5d07-26a6-4510-a60c-1f78175a3f38
# ╟─831bd16d-58f9-5236-867e-d5ed00adcf63
# ╟─eca7b04d-a281-47a3-a911-0678c8510130
# ╟─406c6a43-740c-4e56-8a57-35b6a07ba2b7
# ╟─3359a5d2-7aac-5f95-b6cf-d3420dd9d51b
# ╟─330c2302-e7e4-5849-be68-b75c86f3cacb
# ╟─9713dcda-8181-45e7-8fd5-c62bf9134aa7
# ╟─77615046-bbf9-4318-8da9-1d7aca21ca94
# ╟─15a463e7-7217-484f-a1e4-ed198c9b05c7
# ╟─0bcfb8b9-0d28-5c3c-baf7-8b3900960826
# ╟─4920fcd2-add1-5e85-8807-ebc7b0c0798f
# ╟─92516938-164d-41b8-991e-ca5c4216898c
# ╟─ed540754-92a5-512d-ad4e-3ffb141b2bf1
# ╟─1ce0d1b7-5ec1-580b-b0bd-934fb74a86fc
# ╟─490fee27-240a-52a6-b9cb-9b40cd4d6fb6
# ╟─886b889c-74be-46fe-9e2d-db5add63771c
# ╟─066d157f-659c-5115-ad05-d595ff52c35c
# ╟─341af294-bb6c-55d2-990c-78bbbe190ade
# ╟─10d92e2a-0efa-53cb-908f-508a45c53fad
# ╟─abae1e2d-05e7-57ce-94c1-ccf3253dde53
# ╟─f260e1c6-2e3d-5709-bc2b-16b4bd5a8abf
# ╟─112888f3-ea48-57b3-b534-15f0aaf2bb32
# ╟─388d7049-aebf-433e-8ff0-870e62b57c74
# ╟─481ffd01-b7ce-5a10-83be-4a9908d528c4
# ╟─ca3eb955-a7dc-5d89-aabc-fdee7a2c596b
# ╟─44ec27a2-ce80-5e03-af44-7104307276d6
# ╟─186bdace-d646-40e4-8269-91a5eb5525a9
# ╟─ca0bd79d-2962-5f45-93f1-af7cbd159796
# ╟─39c8664b-3505-5411-b5c7-87d75a2d2305
# ╟─9dd44b2e-19e5-50f3-8ecd-ca1b60b39231
# ╟─998d436b-2a45-5394-96f2-f88ec80b4ff7
# ╟─51d1218c-32e7-5d65-8a3a-d739ab7262fe
# ╟─cdb131a1-2d0a-5daa-b6af-25a40c21865a
# ╟─d6d7070c-88ff-4b93-8093-7fe8baaef3c2
# ╟─bbb95b6c-ba92-42c0-9122-086a8b11c8f3
# ╟─69cf5e21-22ec-5751-802d-b115c54e4080
# ╟─c4f6c8ba-fbbb-443c-943a-a4ca5ae739e3
# ╟─e8497bf1-2a8a-4661-9c06-863a44ed8885
# ╟─d72fb098-bed2-4f26-86e7-62ba790df5dd
# ╟─b575dc3a-6334-52cd-948f-ec0c294dafc5
# ╟─71b43864-9a54-4b9b-ae1a-671b80c1b95d
# ╟─467406f3-ce75-421e-9a87-d3559eeb35ee
# ╟─86cfa609-8086-426a-b6ce-2e140ecec052
# ╟─2afd0c56-0bf0-5b33-ae6d-73199a0b234b
# ╟─bf70bd81-1b6a-4cf9-9dd8-594f92efea16
# ╟─b8dc0784-9c5f-5800-b997-369529968c00
# ╟─68175a2d-7eea-5582-ba04-fe7751ce648d
# ╟─d2b00eee-ac62-5585-9237-78aba3ec9489
# ╟─3a2db6cd-e77b-548c-b081-6b3feb62e936
# ╟─ea9d018d-4072-4aa5-985a-ee34fcae04d3
# ╟─71b6de44-ece9-5e3f-ad46-e1a5f649b945
# ╟─138ea814-3a72-52c2-942f-bbaae57968a0
# ╟─a3d6b00c-9a9c-5405-a396-0c3f88a25de3
# ╟─80ced0ea-f948-40a3-89e3-42a4f303733c
# ╟─c46c6e9a-7269-5b19-8662-d14ef54554ad
# ╟─691785d8-5309-5564-8bdf-c62da7f64403
# ╟─3fa37ac3-eeae-5b31-8c9d-0ee094052260
# ╟─b699e8ab-5de0-5351-b54c-703476a2f793
# ╟─b6f85d2f-d29d-57a7-8e5a-f88d50751bff
# ╟─9af7179d-1a05-5fbb-84e8-358e9a628405
# ╟─77381c04-003d-4a68-907f-09a10e7c9cc4
# ╟─c5510e19-2ca7-4658-bfb8-21edfae45a79
# ╟─4a0da2f8-be59-5215-abc1-0471fdfeb2a1
# ╟─ef405783-9048-45f7-93f9-bac786ee13b5
# ╟─3df111a6-c669-442d-9299-fe480bf3f762
# ╟─05406320-5e1c-4b2a-9d07-2323b0976b24
# ╟─e2dddf66-0017-55ad-b309-5f9cc11d72ee
# ╟─d61b4d3f-20b3-52e0-ba5a-9412c5c0dacf
# ╟─269eead9-b7e2-51f8-824a-cf060460e1f5
# ╟─b6af0980-5e1c-4e9a-bfc5-0c6c33605abc
# ╟─7048f135-2533-5d1b-90f4-68eb7f5e573c
# ╟─021a90c8-0fd4-456d-bdbb-2e3af63f88d0
# ╟─1ee75699-b8fe-5cad-beb0-d3e0967e7041
# ╟─6d1930fd-1787-5449-acfa-579396d3b31b
# ╟─098ef777-bbf4-5a29-9f6f-e994f3418774
# ╟─82ddb7df-c1e1-5e05-829e-9a3486abaa4e
# ╟─16a8f827-cd4b-55dc-8b1b-0feb358c99aa
# ╟─3e1d4055-ed9a-40be-950b-0b23d345952d
# ╟─454b7935-c1c3-5914-b6f5-ad13edd86d01
# ╟─d656e5a8-e471-5ec3-a538-ed704c557b90
# ╟─a1eebfaa-ac28-5511-80f8-83ac87cbd423
# ╟─e7533517-ea75-5361-b8a2-bb60c67ca3af
# ╟─b5dbdf36-0e13-5f76-bf1f-e829202924f3
# ╟─be9624be-871f-5fd8-a3e7-ee4bf5bc1943
# ╟─28d1e0a8-9372-54b2-bad9-020c0efdcf5f
# ╟─84175052-570e-4611-b506-cc1593c6a03d
# ╟─8af337a6-0282-50b5-a98e-142755a66f42
# ╟─5a772d46-7fc0-4baf-bf62-6f59e18c3e19
# ╟─5e0e82fd-9a18-4646-b41e-db24632ba70c
# ╟─86a55819-b811-42f1-acfd-9f41bd490ea9
# ╟─c7f8f3b8-8871-5e02-8132-9b03ce6868af
# ╟─f44d1e93-7039-49f5-82fb-c3b857140a62
# ╟─3b0984f3-b69f-54b9-91f1-30fab8cc7881
# ╟─75e1037e-5a0a-50f2-a755-29e7037ba07e
# ╟─72348138-0b2c-5966-bd28-17c6185490bf
# ╟─ea852136-7152-5722-88c5-d7269a9dcb3e
# ╟─c526562d-9690-5b95-b0f9-67f9765b3fdf
# ╟─77c576de-e638-4bf2-96fa-8892c107d220
# ╟─309bafac-d1f8-5e0a-b637-83a654847224
# ╟─1c4c5bb1-294b-5030-8745-8fcf24911c6b
# ╟─8a0fa3f8-202e-50f4-9581-98cbd5938f11
# ╟─b67d030f-c790-4d9f-a386-9a1033b2bb9f
# ╟─bb4fc2ab-3377-49fd-917d-f02229d4bd40
# ╟─6a75b042-0d4f-54dc-937d-1f8ecffd98f4
# ╟─594df3dd-969c-5e42-bbfd-2a5521492f45
# ╟─e3fe65ed-ec1f-52ef-a417-d8ef143deb5f
# ╟─7964c1c8-d477-4ae5-a695-a05b27451201
# ╟─0aeb3bc7-8037-575b-ad36-d81a5834ea0c
# ╟─4e29c85b-03d2-5502-8fed-f7d389f406bc
# ╟─9ae7361b-cbcb-5ef8-8f87-8b1b4f5af276
# ╟─92d82a98-af32-53ec-8efc-79ce25173c66
# ╟─4c7104d2-88a3-5822-a1d7-3b2cba51faea
# ╟─1a79a088-861a-5983-8a1e-856a5dd2110a
# ╟─de59bdae-32bb-435c-822d-800fcb503940
# ╟─f24b6a12-205d-47a2-a4e1-eb7db030e8f9
# ╟─cfb8fca3-eb96-4fb4-8876-497f9dcb5cae
# ╟─7c3d9060-9dde-5d5c-9c00-5b194e10e521
# ╟─7848f4a7-1e17-440d-bc6b-cb8348e8bc73
# ╟─25979fe7-5ceb-4fbc-8947-938728d24341
# ╟─610466fd-c56a-459c-bd9c-1fbdd143a007
# ╟─12ebe6b9-cf3d-5ac7-b05d-b34b359fd7d2
# ╟─ace950cb-604f-4e97-80ab-d2b72ba6fa26
# ╟─65410189-b0b1-5e52-b267-63adb383edc6
# ╟─beed5f9f-8952-52ec-99b0-990d9b107f48
# ╟─190fbe6b-f8d5-4df4-acf7-6184d91aa965
# ╟─14d97564-3dfc-5b16-b9a7-e6437ceee636
# ╟─490fbb26-bcc0-5883-9550-6bc4488356da
# ╟─d7234072-bd91-5008-a8c7-bd27bf75fc30
# ╟─8be17925-68bd-5081-9994-2fa7bc043a49
# ╟─c4612db8-63e1-468b-8af2-f96ea23abbee
# ╟─7297e311-1114-51f5-9256-06ee3e0555a4
# ╟─05e11080-54c1-5b8c-8a82-34521a4482e8
# ╟─0c45b5dd-4778-5b23-867c-ce6b58559e15
# ╟─72c966ff-94be-574b-9a41-d1909b728c48
# ╟─0aea8a28-ea91-4cb3-af7a-5f8a56f400d8
# ╟─4ce799f5-e25f-5455-92cf-7868dc713552
# ╟─1eb22217-6b48-5fd1-bbd0-29ab9b184fdf
# ╟─915b1cfd-3760-5fcf-8a85-8ed0e1e48109
# ╟─62cc1624-ca88-5b76-9cef-c99bf1e68897
# ╟─01e4001b-78f3-53f2-b887-c5730fb68f6e
# ╟─b05ee7f3-2185-518f-9536-7635c28a8067
# ╟─efcd227c-be87-5b78-b0a3-49f80f436147
# ╟─1d30f2e4-a668-58d4-8945-17fc3d94ef27
# ╟─4130d78a-3223-5804-899c-07e48ca7ae66
# ╟─bf6dd588-2b9e-42d9-a78c-27325c45b5ca
# ╟─4f6ecd1c-90bb-52bd-85da-d989ab7adc4a
# ╟─4378f115-d8fc-5392-9deb-ead3ccf2eb03
# ╟─1a1cf665-5227-5108-b6d8-6a9c8e955454
# ╟─14bd41f4-6154-55bd-84db-91319ba078bd
# ╟─fd52d12c-fa1f-5fc5-bf6c-369a33a56041
# ╟─d58a74a2-207c-5a35-a637-ac0ec44ff8b3
# ╟─a34943ff-7ff3-55a6-9bd4-bca6a4c03be9
# ╟─95229d19-866e-5fbf-952e-52ae748c5604
# ╟─67ad1529-9b11-596d-8256-6ed6365d8d8e
