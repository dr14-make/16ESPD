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

On 15 October 2026 Tesla showed its new Roadster. It reached 60 mph in under a second, clung to a
ramp that curled past vertical, and jumped over a row of cars.

We take each claim and ask one question: **does it fit basic physics?** For every claim we do
four things:

1. Write down what Tesla claimed.
2. Check it on paper with a short calculation.
3. Build a small model in Dyad.
4. Simulate the model and compare.

*Start the notebook with `julia +dyad-3.4.0 notebooks/roadster/present.jl`. Pluto's worker
processes cannot load the Dyad packages with this Julia build, so the launcher runs the notebook
in its own process.*
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
    nothing
end

# ╔═╡ 40ef78e6-32c9-5c2d-9f7e-b2839b5a029d
md"""
## What Tesla showed

The event took place at SpaceX's test site in McGregor, Texas. We check five claims, one section
each:

1. **The tires** grip up to 1.26 g.
2. **The suction fan** presses the car down with 4,700 kg and gives 0–60 mph in under 1.6 s.
3. **The cold-gas thrusters** push with over 80 kN, from 600 L of compressed air.
4. **0–60 mph in under a second:** 1.0 s recorded, 0.81 s live, and under 0.59 s for the top trim.
5. **"It can fly":** an 8 m hop over a row of cars, and short hovers.

Every section has the same four parts: **Tesla's claim**, a **physics check** on paper, **our
model** in Dyad, and a **simulation**. Each one ends with a verdict.
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
<div style="display:flex;gap:10px;flex-wrap:wrap">
<iframe style="flex:1 1 300px;aspect-ratio:16/9;border:0" src="https://www.youtube-nocookie.com/embed/7p5LxFdc-Qg" title="The Ramp | Roadster" allow="encrypted-media; picture-in-picture; fullscreen" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
<iframe style="flex:1 1 300px;aspect-ratio:16/9;border:0" src="https://www.youtube-nocookie.com/embed/r5vsHHPVhJg" title="The Kickflip | Roadster" allow="encrypted-media; picture-in-picture; fullscreen" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
</div>
"""

# ╔═╡ d73c9887-b6d8-5fad-9d96-d7566fc823bb
md"""
## What Tesla said, and what it did not

Each number is marked by how solid it is: **T** Tesla said it · **P** a press report that Tesla
has not confirmed · **M** measured or estimated by a third party · **?** not known.
"""

# ╔═╡ b80af6e2-b5e3-5bdd-97dd-0a6ecf66c074
html_table(["Item", "Value", "Source"], [
    ("0–60 mph claims", "Performance < 1.6 s, Thrust < 0.9 s, Rocket < 0.59 s", "**T**"),
    ("0–60 mph runs", "1.0 s recorded, 0.81 s live", "**T**"),
    ("Thrusters", "10 cold-gas thrusters, 600 L of air in COPVs", "**T**"),
    ("Downforce", "4,700 kg readout; holds the car upside down", "**T**"),
    ("Tire grip limit", "1.26 g", "**P**"),
    ("Rear thrust", "over 80 kN from 4 rear nozzles", "**P**"),
    ("Air mass", "about 250 kg; Electrek splits 200 L Thrust + 400 L Rocket", "**P**"),
    ("Tank pressure", "380 bar (5,500 psi cabin readout) **or** 690 bar (10,000 psi, Electrek)", "**P**, conflicting"),
    ("Drive", "rear-wheel drive, 2 rear motors, over 1 MW, about 1,400 N·m", "**P**"),
    ("Fans", "about 4 × 20 kW", "**M**"),
    ("Mass", "under 1,700 kg (Electrek), about 1,900 kg, about 2,350 kg (CellCog)", "**M**, conflicting"),
    ("Video fits", "kickflip apex 8.0 m, roll 177 °/s; ramp early fall 2.3 g", "**M**"),
    ("Not disclosed", "mass, tank pressure, battery capacity, thrust per nozzle, gear ratio", "**?**"),
]; widths = ["22%", "58%", "20%"])

# ╔═╡ 6db050a1-68fc-5767-abf9-74ddea7261d8
md"""
## What we assume for the unknowns

Where Tesla gave no number, the models use the values below. The panel in the bottom-right corner
changes the mass and the drive layout for every section.
"""

# ╔═╡ 1bf3759a-417c-5ada-8ebd-6a35dad71f88
html_table(["Unknown", "Model value", "Why"], [
    ("Mass", "**2,000 kg**, panel slider 1,700–2,350", "middle of the estimates"),
    ("Drive", "at most 12,000 N·m at the wheels and 1 MW; wheel radius 0.35 m", "1,400 N·m × an assumed 8.5:1 gear"),
    ("Tire", "peak grip `μ = 1.26`; traction control holds 98 % of it", "Tesla's figure, ideal controller"),
    ("Layout", "RWD: 55 % of the weight on the rear axle, `h/L = 0.17`; AWD for comparison", "assumed geometry"),
    ("Drag", "`C_dA = 0.6` m²", "assumed"),
    ("Fan", "4 m² floor, 10 m of skirt, 3 mm gap", "assumed; pressure sized to 4,700 kg"),
    ("Tank", "600 L at **380 bar** and 20 °C: 271 kg of air", "the cabin readout"),
    ("Nozzles", "throat area sized for 80 kN at 380 bar", "the press figure"),
]; widths = ["16%", "50%", "34%"])

# ╔═╡ f1ce64c1-2d6f-5c29-9ba3-ed6dbb15ddc3
md"""
## How the simulations run

The simulation results come from Dyad models in `dyad/Roadster/`. Each model is compiled once,
when the notebook opens. A slider then only changes parameter values and solves the model again,
which takes milliseconds.

The panel in the bottom-right corner holds two settings that every section shares: the **car
mass** and the **drive layout** (RWD is rear-wheel drive, AWD is all-wheel drive). Above it,
**Claim vs model** collects the verdicts as we go.
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
# The "Try" lines quote these: the baseline car (2,000 kg, RWD) with one setting changed.
hints = let
    base = (; m = 2000.0, LAYOUTS["RWD"]...)
    t(; kw...) = t60(solve_with(launch_rig; merge(base, kw)...), launch_rig.sys)
    marks(; kw...) = blowdown_marks(solve_with(stand_rig; kw...), stand_rig.sys)
    apex(; kw...) = hop_apex(solve_with(hop_rig; kw...), hop_rig.sys).apex
    (
        tires_mu15 = t(mu_A = 1.5),
        tires_P05 = t(P_max = 0.5e6),
        tires_P05_awd = t(; P_max = 0.5e6, LAYOUTS["AWD"]...),
        tires_CdA12 = t(CdA = 1.2),
        tires_m2350 = t(m = 2350.0),
        suction_T20 = t(fan_cmd = 1.0, T_max = 20e3),
        suction_fan03 = t(fan_cmd = 0.3),
        suction_m2350 = t(fan_cmd = 1.0, m = 2350.0),
        stand_690 = marks(p0 = 690e5),
        stand_690_scaled = marks(p0 = 690e5, A_t = 1.286e-3 * 380 / 690),
        stand_n1 = marks(n = 1.0),
        stand_200L = marks(V = 0.2),
        thrust_off_suction = t(fan_cmd = 1.0),
        thrust_200L = t(thrust_cmd = 1.0, tank_volume = 0.2),
        thrust_m2350 = t(thrust_cmd = 1.0, fan_cmd = 1.0, m = 2350.0),
        thrust_300bar = t(thrust_cmd = 1.0, fan_cmd = 1.0, tank_pressure = 300e5),
        thrust_300bar_200L = t(thrust_cmd = 1.0, fan_cmd = 1.0, tank_pressure = 300e5,
            tank_volume = 0.2),
        thrust_all_down = t(thrust_cmd = 1.0, down_fraction = 1.0),
        hop_03 = apex(t_b = 0.3),
        hop_06 = apex(t_b = 0.6),
        hop_m2350 = apex(t_b = 0.413, m = 2350.0),
    )
end;

# ╔═╡ 0a85f4c7-90ac-595f-b127-8474860e03df
md"""
## Warm-up: is the ramp video real time?

A falling object is a clock. In free fall it accelerates at ``g = 9.81`` m/s². If a clip plays
``k`` times too fast, every acceleration on screen looks ``k^2`` times too large. So a fall that
measures ``a`` on screen gives

```math
k = \sqrt{a / g}.
```

Frame-by-frame fits of Tesla's videos (third party, 15–20 % error) give **2.3 g** for the early
fall in the ramp's main shot and **0.92 g** for the kickflip's flight.

playback speed-up k $(@bind k_play Slider(0.8:0.02:2.0; default = 1.0, show_value = true))
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
md"""
- **Axes:** video time [s] across, distance fallen [m] up.
- **Lines:** black is the fall measured in the ramp shot (2.3 g). Dashed blue is a real fall at
  1 g, played ``k`` times fast.
- **Look at:** the two curves lie on top of each other when ``k = \sqrt{2.3} =`` $(fmt(warmup.k_ramp)).
- **What it means:** the ramp shot plays about 1.5 times too fast. Speeds read from that shot
  must be divided by 1.5, and accelerations by 2.3. The kickflip gives
  ``k =`` $(fmt(warmup.k_kick)), close to real time.
- **Try:** drag ``k`` to 1.52.
"""

# ╔═╡ ca3fab0a-57b4-5859-b505-19746d073c33
md"""
## Claim 1: what can the tires do?

**Tesla's claim.** The tires grip up to **1.26 g** (press report: Electrek, quoting a Tesla
engineer). The tires are Pirelli P Zero Trofeo RS. The car drives the rear wheels with two
motors, over 1 MW and about 1,400 N·m in total (press reports).

**What "1.26 g" means.** The tires can push the car forward with at most 1.26 times its weight.
Here ``g = 9.81`` m/s² is the acceleration of gravity.

**The question.** With only the tires pushing, how fast can the car reach 60 mph? Tesla's runs
took 1.0 s (recorded) and 0.81 s (live).
"""

# ╔═╡ ceba3a95-cacc-5e9b-9677-0c3d0016913f
md"""
## Claim 1 · Physics check: the acceleration a 1 s run needs

60 mph is ``v_{60} = 26.8`` m/s. A car that speeds up evenly for a time ``t`` has the
acceleration

```math
a = \frac{v_{60}}{t}.
```

For ``t = 1.0`` s:

```math
a = \frac{26.8\ \text{m/s}}{1.0\ \text{s}} = 26.8\ \text{m/s}^2 = \frac{26.8}{9.81}\,g = 2.73\,g.
```

A 1 s run needs **2.73 g** on average. The live 0.81 s run needs **3.38 g**.
"""

# ╔═╡ 831bd16d-58f9-5236-867e-d5ed00adcf63
md"""
## Claim 1 · Physics check: the most a tire can push

A tire can push forward with at most

```math
F_x \le \mu\, F_z
```

- ``F_x``: the forward force of the tire [N]
- ``F_z``: the normal load, the force that presses the tire onto the road [N]
- ``\mu``: the peak friction coefficient of the tire, here 1.26

Take all-wheel drive first. All four tires push, and together they carry the whole weight, so
``F_z = m g``, with ``m`` the mass of the car. Newton's second law, ``m a = F_x``, then gives

```math
a \le \mu\, g = 1.26 \cdot 9.81 = 12.4\ \text{m/s}^2
\quad\Rightarrow\quad
t \ge \frac{26.8}{12.4} = 2.17\ \text{s}.
```

The mass cancels. A heavier car presses harder on the road, but it also needs more force.
"""

# ╔═╡ 3359a5d2-7aac-5f95-b6cf-d3420dd9d51b
md"""
## Claim 1 · Physics check: rear-wheel drive

With rear-wheel drive only the rear tires push. When the car accelerates, it pitches back, and
the rear tires carry more load:

```math
F_z = s\, m g + m a\, \frac{h}{L}
```

- ``s = 0.55``: the share of the weight on the rear axle at rest
- ``h/L = 0.17``: the height ``h`` of the center of mass over the wheelbase ``L``

The traction control holds the tire at 98 % of its peak, so ``m a = 0.98\, \mu F_z``. Put that
in and solve for ``a``:

```math
\frac{a}{g} = \frac{0.98\, \mu\, s}{1 - 0.98\, \mu\, h/L}
= \frac{0.98 \cdot 1.26 \cdot 0.55}{1 - 0.98 \cdot 1.26 \cdot 0.17} = 0.86 .
```

So ``a = 0.86\,g = 8.4`` m/s² and ``t = 26.8 / 8.4 = 3.18`` s. That is far from the 2.73 g a 1 s
run needs.
"""

# ╔═╡ 330c2302-e7e4-5849-be68-b75c86f3cacb
md"""
## Claim 1 · Physics check: is the motor strong enough?

The drive has two limits of its own.

**Torque.** The most torque at the wheels is ``T_{max} = 12{,}000`` N·m (1,400 N·m times an
assumed 8.5:1 gear). With wheel radius ``r = 0.35`` m that is a force of

```math
F = \frac{T_{max}}{r} = \frac{12{,}000\ \text{N·m}}{0.35\ \text{m}} = 34.3\ \text{kN},
\quad\text{which is } 1.75\,g \text{ for } 2{,}000\ \text{kg}.
```

**Power.** Force times speed cannot exceed the power ``P = 1`` MW, so ``F \le P / v``. At 60 mph
that is ``1{,}000{,}000 / 26.8 = 37.3`` kN.

**The tires** give at most ``0.98 \cdot 1.26 \cdot 2{,}000 \cdot 9.81 = 24.2`` kN, even with
all-wheel drive. Both drive limits are higher. Up to 60 mph the tires run out first, not the
motor.
"""

# ╔═╡ 0bcfb8b9-0d28-5c3c-baf7-8b3900960826
grip_need = let
    needed(t) = V60 / t / G0
    awd(t) = needed(t) / 0.98
    rwd(t) = needed(t) / (0.98 * (0.55 + 0.17 * needed(t)))
    (awd_1 = awd(1.0), rwd_1 = rwd(1.0), awd_16 = awd(1.6), rwd_16 = rwd(1.6))
end;

# ╔═╡ 4920fcd2-add1-5e85-8807-ebc7b0c0798f
md"""
## Claim 1 · Physics check: how much grip would a 1 s run need?

The same two formulas, now solved for many values of ``\mu``.
"""

# ╔═╡ ed540754-92a5-512d-ad4e-3ffb141b2bf1
let
    grip = 0.98
    mu = range(0.8, 3.0; length = 200)
    a_awd = grip .* mu
    a_rwd = grip .* mu .* 0.55 ./ (1 .- grip .* mu .* 0.17)
    plt = plot(mu, V60 ./ (a_rwd .* G0); lw = 3, color = :firebrick, label = "RWD",
        xlabel = "peak friction coefficient μ", ylabel = "time to 60 mph [s]", ylims = (0, 5),
        legend = :topright,
        title = "1 s needs μ ≈ $(fmt(grip_need.rwd_1, 1)) (RWD) or $(fmt(grip_need.awd_1, 1)) (AWD)")
    plot!(plt, mu, V60 ./ (a_awd .* G0); lw = 3, color = :steelblue, label = "AWD")
    hline!(plt, [1.0]; color = :black, ls = :dash, label = "1 s")
    hline!(plt, [1.6]; color = :gray, ls = :dot, label = "1.6 s (Performance)")
    vline!(plt, [1.26]; color = :seagreen, label = "μ = 1.26 (Tesla)")
    plt
end

# ╔═╡ 1ce0d1b7-5ec1-580b-b0bd-934fb74a86fc
md"""
- **Axes:** the tire's peak friction coefficient ``\mu`` (no unit) across, the time to 60 mph [s]
  up. No drag and no wheel inertia.
- **Lines:** red is rear-wheel drive, blue is all-wheel drive. Dashed black marks 1 s, dotted gray
  1.6 s. The green vertical line is Tesla's tire, ``\mu = 1.26``.
- **Look at:** where each curve drops below the 1 s line. That happens near ``\mu =``
  $(fmt(grip_need.rwd_1, 1)) for RWD and $(fmt(grip_need.awd_1, 1)) for AWD.
- **What it means:** a 1 s run on tires alone needs more than twice the grip of Tesla's own
  tire. Even 1.6 s needs ``\mu =`` $(fmt(grip_need.awd_16, 2)) (AWD) or $(fmt(grip_need.rwd_16, 2)) (RWD).
"""

# ╔═╡ 490fee27-240a-52a6-b9cb-9b40cd4d6fb6
md"""
## Claim 1 · Our model: the launch car

One Dyad model, `RoadsterLaunch`, covers every launch in this notebook. In this section the fan
and the thrusters are switched off, so only the bottom-right chain matters: traction control
sets the torque, the motor delivers it, and the wheel pushes the body.
"""

# ╔═╡ 066d157f-659c-5115-ad05-d595ff52c35c
diagrams([joinpath(img_dir, "roadster-launch.png") =>
    "`RoadsterLaunch`. Top: fan and downforce. Middle left: tank and nozzle. Bottom right: traction control, motor, wheel and body."]; height = "340px")

# ╔═╡ 83b3f4a6-3a68-5399-bba1-ab286974d915
md"""
- **motor** (`PowerLimitedMotor`): gives the torque that traction control asks for, but never
  more than 12,000 N·m or 1 MW.
- **wheel\_inertia** and **wheel** (`LoadedSlipWheel1D`): the spinning wheel and the tire. The
  tire force depends on the slip, how much faster the tire turns than the car moves, and on the
  normal load.
- **body** (`VehicleBody`): the car's mass, air drag and rolling resistance.
- **axle** (`AxleLoad`) and **traction** (`TractionControl`): the normal load on the driven tires,
  and the controller that keeps the tire near its peak grip.
- **fan**, **tank**, **nozzle**: switched off here. Claims 2 to 4 switch them on.
"""

# ╔═╡ 341af294-bb6c-55d2-990c-78bbbe190ade
md"""
## Claim 1 · Our model: three blocks we wrote

The rest of the car comes from the existing component library.
"""

# ╔═╡ 10d92e2a-0efa-53cb-908f-508a45c53fad
diagrams([
    joinpath(img_dir, "power-limited-motor.png") =>
        "**`PowerLimitedMotor`** (equations only, so the picture shows just its connections) delivers the smallest of three torques: the request, 12,000 N·m, and 1 MW divided by the wheel speed.",
    joinpath(img_dir, "axle-load.png") =>
        "**`AxleLoad`** (equations only) computes the load on the driven axle: its share of the weight and downforce, plus the load that moves back as the car accelerates. That extra load follows with a 0.1 s delay, like a suspension settling.",
    joinpath(img_dir, "traction-control.png") =>
        "**`TractionControl`**, shown in its test with a fixed load of 10,000 N and a fixed slip of 0.03, asks for 98 % of the torque the tire can take, `0.98·μ·F_z·r`. If the tire starts to slip past its peak, it cuts the request.",
]; height = "300px")

# ╔═╡ abae1e2d-05e7-57ce-94c1-ccf3253dde53
dyad_fold("AxleLoad", "TractionControl", "PowerLimitedMotor")

# ╔═╡ f260e1c6-2e3d-5709-bc2b-16b4bd5a8abf
md"""
## Claim 1 · Simulation: speed against time

peak tire grip μ $(@bind mu_A Slider(1.0:0.02:1.6; default = 1.26, show_value = true)) ·
motor power [MW] $(@bind P_MW Slider(0.5:0.1:2.0; default = 1.0, show_value = true)) ·
drag area [m²] $(@bind CdA Slider(0.3:0.05:1.2; default = 0.6, show_value = true))
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
md"""
- **Axes:** time [s] across, speed [km/h] up.
- **Lines:** blue is the car set in the panel ($(drive_layout)), gray is the other drive layout.
  Dotted black is 60 mph (96.6 km/h). The dashed orange and red lines are Tesla's runs.
- **Look at:** where blue crosses the dotted line. That is the 0–60 time:
  **$(fmt(tires.t60)) s**. The line is nearly straight, because the tire limit barely changes.
- **What it means:** at Tesla's 1.0 s mark this car is only at $(fmt(tires.v_at_1s, 0)) km/h.
- **Try** (2,000 kg, RWD): grip 1.5 gives $(fmt(hints.tires_mu15)) s. Power 0.5 MW gives
  $(fmt(hints.tires_P05)) s, no change. Drag area 1.2 m² gives $(fmt(hints.tires_CdA12)) s.
  Only the grip matters. *Re-solved in $(fmt(tires.ms, 0)) ms.*
"""

# ╔═╡ 44ec27a2-ce80-5e03-af44-7104307276d6
md"""
## Claim 1 · Simulation: which limit holds the car back?

The tire, the torque and the power each cap the force at the wheel. The car gets the lowest cap.
"""

# ╔═╡ ca0bd79d-2962-5f45-93f1-af7cbd159796
limit_map(tires.sol, launch_rig.sys; until = min(tires.t60, 6.0),
    title = "Tires only, $(drive_layout): the tire is the limit")

# ╔═╡ 39c8664b-3505-5411-b5c7-87d75a2d2305
md"""
- **Axes:** speed [m/s] across (not time), force at the wheel [kN] up.
- **Lines:** green is the tire limit ``\mu F_z``. Orange is the torque cap ``T_{max}/r``. Purple
  is the power cap ``P/v``; it falls as the car speeds up. The thick dark line is the force the
  tire actually delivers. Dotted gray marks 60 mph.
- **Look at:** the dark line runs just under green all the way, far below orange and purple.
  With RWD, green rises at first: load moves onto the rear tires as the car pitches back.
- **What it means:** the tire is the limit for $(fmt(100 * tires.limits.tire, 0)) % of the run.
  A stronger motor would not help.
"""

# ╔═╡ 9dd44b2e-19e5-50f3-8ecd-ca1b60b39231
md"## Claim 1 · Verdict"

# ╔═╡ 998d436b-2a45-5394-96f2-f88ec80b4ff7
verdict_box(tires.t60 <= 1.0 ? :yes : :no,
    tires.t60 <= 1.0 ? "Verdict: plausible at this grip" : "Verdict: not plausible on tires alone",
    """
    With Tesla's tire (μ = 1.26) the model needs **$(fmt(reference.rwd.t60)) s** with
    rear-wheel drive and **$(fmt(reference.awd.t60)) s** with all-wheel drive, against Tesla's
    1.0 s. At the current settings: $(fmt(tires.t60)) s ($(drive_layout)).

    The 1.26 g grip itself is believable. It just cannot give a 1 s run: that needs μ near
    $(fmt(grip_need.awd_1, 1)). The limit is the tire, not the 1 MW motor.

    **Next:** press the car onto the road with suction.
    """)

# ╔═╡ 51d1218c-32e7-5d65-8a3a-d739ab7262fe
md"""
## Claim 2: the suction fan

**Tesla's claim.**
- **Performance trim:** fans only, road legal, 0–60 mph in **under 1.6 s** (Tesla).
- **Downforce:** an on-screen readout showed **4,700 kg** (Tesla). The fans held the car on a ramp
  that curled past vertical, so the car hung upside down.
- **Fan power:** about 4 × 20 kW (Electrek's estimate).

**How it works.** Fans pump air out from under the floor. Flexible skirts along the edges keep
outside air from rushing back in. The pressure under the car drops, and the air above presses the
car onto the road. Race cars used this in the 1970s (Chaparral 2J, Brabham BT46B). Unlike a wing,
it works at standstill.
"""

# ╔═╡ cdb131a1-2d0a-5daa-b6af-25a40c21865a
md"""
## Claim 2 · Physics check: how strong is the suction?

"4,700 kg of downforce" means a force equal to the weight of 4,700 kg:

```math
D = 4{,}700\ \text{kg} \cdot 9.81\ \text{m/s}^2 = 46.1\ \text{kN}.
```

The fan makes this force by lowering the pressure under the floor by ``\Delta p``. With a floor
area ``A = 4`` m² (assumed):

```math
\Delta p = \frac{D}{A} = \frac{46{,}100\ \text{N}}{4\ \text{m}^2} = 11.5\ \text{kPa}.
```

That is about 11 % of the air pressure around us (101 kPa). A small pressure drop over a large
floor gives a large force: 2.35 times the weight of a 2,000 kg car.
"""

# ╔═╡ 69cf5e21-22ec-5751-802d-b115c54e4080
md"""
## Claim 2 · Physics check: the motor becomes the limit

The downforce adds to the normal load. With all-wheel drive:

```math
F_z = m g + D = 19.6\ \text{kN} + 46.1\ \text{kN} = 65.7\ \text{kN}.
```

The tires could now push ``0.98 \cdot 1.26 \cdot 65.7 = 81.1`` kN, which is **4.1 g**. But the
motor's torque cap is still ``T_{max}/r = 34.3`` kN, which is **1.75 g**. Now the motor runs out
first:

```math
t = \frac{v_{60}}{a} = \frac{26.8\ \text{m/s}}{1.75 \cdot 9.81\ \text{m/s}^2} = 1.56\ \text{s}.
```

Suction moves the limit from the tire to the motor, and the time lands right at Tesla's
"under 1.6 s".
"""

# ╔═╡ b575dc3a-6334-52cd-948f-ec0c294dafc5
md"""
## Claim 2 · Physics check: what does the fan cost?

Air leaks in through the gap under the skirt, and the fan must pump it out again. The leak flow
``Q`` [m³/s] is

```math
Q = C_d \cdot \ell \cdot \delta \cdot \sqrt{\frac{2\, \Delta p}{\rho}}
= 0.6 \cdot 10\ \text{m} \cdot 0.003\ \text{m} \cdot 139\ \text{m/s} = 2.49\ \text{m}^3/\text{s}
```

- ``\ell = 10`` m: the length of skirt around the car; ``\delta = 3`` mm: the gap under it
- ``C_d = 0.6``: the share of the gap that really flows; ``\rho = 1.2`` kg/m³: air density

The fan power is flow times pressure, divided by the fan efficiency ``\eta = 0.6``:

```math
P_{fan} = \frac{Q\, \Delta p}{\eta} = \frac{2.49 \cdot 11{,}500}{0.6} = 47.9\ \text{kW}.
```

The power grows in step with the gap: 160 kW at 10 mm. To hang a 2,000 kg car upside down, the
downforce must at least equal its weight: ``\Delta p \ge 2{,}000 \cdot 9.81 / 4 = 4.9`` kPa,
which costs 13.3 kW at 3 mm.
"""

# ╔═╡ 2afd0c56-0bf0-5b33-ae6d-73199a0b234b
md"""
## Claim 2 · Our model: the suction fan

We added one block, `SuctionFan`, to the launch car.
"""

# ╔═╡ b8dc0784-9c5f-5800-b997-369529968c00
diagrams([joinpath(img_dir, "suction-fan.png") =>
    "`SuctionFan` in its upside-down hold test: a constant command drives the fan, which outputs downforce and fan power."]; height = "300px")

# ╔═╡ a0a1a723-c8b2-57e1-99a2-fcf781edb50a
md"""
- **Input:** the fan command, from 0 (off) to 1 (full).
- **Pressure:** ``\Delta p`` moves toward command × 11.5 kPa with a 0.3 s delay, like a fan
  spinning up.
- **Outputs:** the downforce ``\Delta p \cdot A``, and the fan power from the leak formula.
- **In the launch car:** the downforce feeds `AxleLoad`, so the tires get more load, and adds a
  little rolling resistance. The fan is at full pressure before the car starts, because the car
  sits on suction before the launch.
"""

# ╔═╡ 68175a2d-7eea-5582-ba04-fe7751ce648d
dyad_fold("SuctionFan")

# ╔═╡ d2b00eee-ac62-5585-9237-78aba3ec9489
md"""
## Claim 2 · Simulation: the launch with suction

fan command $(@bind fan_cmd Slider(0.0:0.05:1.0; default = 1.0, show_value = true)) ·
skirt gap [mm] $(@bind gap_mm Slider(1.0:0.5:10.0; default = 3.0, show_value = true)) ·
wheel torque cap [kN·m] $(@bind T_kNm Slider(8:1:20; default = 12, show_value = true))
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

# ╔═╡ 71b6de44-ece9-5e3f-ad46-e1a5f649b945
limit_map(suction.sol, launch_rig.sys; until = min(suction.t60, 6.0),
    title = "Suction, $(drive_layout): 0–60 mph in $(fmt(suction.t60)) s")

# ╔═╡ 138ea814-3a72-52c2-942f-bbaae57968a0
let
    l = suction.limits
    binding = l.torque >= max(l.tire, l.power) ? "the torque cap (orange)" :
              l.tire >= l.power ? "the tire (green)" : "the power cap (purple)"
    md"""
    - **Axes:** as before: speed [m/s] across, force at the wheel [kN] up.
    - **Lines:** green, the tire limit, now sits far above the rest: suction has raised it.
      Orange is the torque cap, $(fmt(T_kNm / 0.35, 1)) kN at this setting.
    - **Look at:** the dark line, the delivered force, follows $(binding) for most of the run
      (torque $(fmt(100 * l.torque, 0)) %, tire $(fmt(100 * l.tire, 0)) %, power
      $(fmt(100 * l.power, 0)) % of the time).
    - **What it means:** 0–60 mph in **$(fmt(suction.t60)) s**. With suction, the grip no longer
      matters; the motor does.
    - **Try** (2,000 kg, RWD): torque cap 20 kN·m gives $(fmt(hints.suction_T20)) s, and the
      limit moves back to the tire and the power. Fan command 0.3 gives
      $(fmt(hints.suction_fan03)) s; the tire limits again. Mass 2,350 kg gives
      $(fmt(hints.suction_m2350)) s, because a torque cap does not grow with mass. The skirt gap
      does not change the time at all. *Re-solved in $(fmt(suction.ms, 0)) ms.*
    """
end

# ╔═╡ a3d6b00c-9a9c-5405-a396-0c3f88a25de3
md"""
## Claim 2 · Simulation: the fan's power bill

The skirt gap changes what the fan costs, not how fast the car goes.
"""

# ╔═╡ c46c6e9a-7269-5b19-8662-d14ef54554ad
let
    gaps = range(1, 10; length = 100)
    dp = fan_cmd * 4700 * G0 / 4.0
    plt = plot(gaps, fan_power_closed_form.(dp, gaps ./ 1e3) ./ 1e3; lw = 3, color = :steelblue,
        label = "formula, Δp = $(fmt(dp / 1e3, 1)) kPa", xlabel = "skirt gap [mm]",
        ylabel = "fan power [kW]", legend = :topleft, title = "Fan power at launch")
    plot!(plt, gaps, fan_power_closed_form.(car.m * G0 / 4.0, gaps ./ 1e3) ./ 1e3; lw = 2,
        color = :seagreen, label = "least Δp to hang $(car.m) kg upside down")
    hline!(plt, [80]; color = :gray, ls = :dot, label = "4 × 20 kW (Electrek estimate)")
    scatter!(plt, [gap_mm], [suction.fan_power / 1e3]; ms = 8, color = :black,
        label = "launch model: $(fmt(suction.fan_power / 1e3, 1)) kW")
    plt
end

# ╔═╡ 691785d8-5309-5564-8bdf-c62da7f64403
let
    margin, mass, gap = fmt(suction.hold_margin), car.m, gap_mm
    dp, power = fmt(suction.hold_dp, 0), fmt(suction.hold_power / 1e3, 1)
    md"""
    - **Axes:** skirt gap [mm] across, fan power [kW] up.
    - **Lines:** blue is the formula ``Q \Delta p / \eta`` at the current fan command. Green is
      the least power that keeps the car hanging upside down. Dotted gray is Electrek's 80 kW
      estimate. The black dot is the power the Dyad launch model reports at the current gap.
    - **Look at:** both lines are straight: double the gap, double the power. The black dot sits
      on the blue line, so the model matches the formula.
    - **What it means:** at 3 mm the fan needs about 48 kW, in line with Electrek's estimate. A
      sloppy 10 mm seal would need 160 kW.
    - **Upside down:** at this command the downforce is **$(margin)×** the weight. Hanging
      $(mass) kg needs at least ``\Delta p =`` $(dp) Pa, which costs $(power) kW at a $(gap) mm
      gap.
    - **Try:** drag the skirt gap to 10 mm and watch the dot climb to about 160 kW.
    """
end

# ╔═╡ 3fa37ac3-eeae-5b31-8c9d-0ee094052260
md"## Claim 2 · Verdict"

# ╔═╡ b699e8ab-5de0-5351-b54c-703476a2f793
let
    ok = suction.t60 <= 1.05 * 1.6 && suction.hold_margin >= 1
    verdict_box(ok ? :yes : :no,
        ok ? "Verdict: plausible, if the skirt seals well" : "Verdict: not plausible at these settings",
        """
        The baseline car with full suction reaches 60 mph in **$(fmt(reference.suction.t60)) s**,
        within 2 % of Tesla's "under 1.6 s". At the current settings: $(fmt(suction.t60)) s.
        The limit is the motor's torque, not the tire.

        The downforce is $(fmt(suction.hold_margin))× the weight, so the car can hang upside down,
        while it stands still on a smooth surface. The fan needs about 48 kW at a 3 mm gap; the
        gap sets the power bill.

        **Next:** push the body directly with compressed air.
        """)
end

# ╔═╡ b6f85d2f-d29d-57a7-8e5a-f88d50751bff
md"""
## Claim 3: the cold-gas thrusters

**Tesla's claim** (the "SpaceX package").
- **10 cold-gas thrusters** run on compressed air stored in **600 L** of tanks, refillable
  (Tesla).
- **Over 80 kN** of thrust from 4 rear nozzles (press report).
- About **250 kg** of air (press report).
- The tank pressure was not published. A cabin readout showed **380 bar**; Electrek says
  **690 bar**.

**How it works.** The air sits in composite tanks: a thin liner wrapped in carbon fiber. A valve
opens, the air rushes out through a nozzle, and the jet pushes the car the other way. Nothing
burns, so the jet is slow: about 700 m/s, against about 3,000 m/s for a rocket engine.
"""

# ╔═╡ 9af7179d-1a05-5fbb-84e8-358e9a628405
md"""
## Claim 3 · Physics check: how much air is in the tank?

The ideal gas law, ``p V = m R T``, gives the mass of air ``m``:

- ``p = 380`` bar ``= 380 \cdot 10^5`` Pa: the tank pressure
- ``V = 0.6`` m³: the tank volume
- ``R = 287`` J/(kg·K): the gas constant of air
- ``T = 293`` K: the temperature, 20 °C

```math
m = \frac{p V}{R T} = \frac{380 \cdot 10^5 \cdot 0.6}{287 \cdot 293} = 271\ \text{kg}.
```

That fits the reported 250 kg. Real air at this pressure is slightly stiffer than an ideal gas,
so the tank holds a little less.
"""

# ╔═╡ 4a0da2f8-be59-5215-abc1-0471fdfeb2a1
md"""
## Claim 3 · Physics check: thrust at full pressure

Thrust is mass flow times jet speed:

```math
F = \dot m \, v_e
```

- ``\dot m`` [kg/s]: air mass leaving per second. In the narrowest part of the nozzle, the
  throat, the air reaches the speed of sound. Then ``\dot m`` grows in step with the pressure
  ``p`` and the throat area ``A_t``.
- ``v_e`` [m/s]: the jet speed after the air has expanded to outside pressure.

The full formulas are in the model. With ``A_t = 1{,}286`` mm² (four nozzles of about 20 mm,
sized for 80 kN) at 380 bar and 20 °C:

```math
\dot m = 115\ \text{kg/s}, \qquad v_e = 693\ \text{m/s}, \qquad
F = 115 \cdot 693 = 80\ \text{kN}.
```

At that rate the 271 kg would last ``271 / 115 = 2.35`` s.
"""

# ╔═╡ e2dddf66-0017-55ad-b309-5f9cc11d72ee
md"""
## Claim 3 · Physics check: the tank runs down

As air leaves, the pressure drops, and with it the flow and the thrust. We assume

```math
\frac{p}{p_0} = \Big(\frac{m}{m_0}\Big)^{n}
```

- ``p_0``, ``m_0``: pressure and air mass at the start; ``p``, ``m``: the same later
- ``n = 1.4``: the air expands too fast to take heat from the tank walls, so it cools
- ``n = 1``: the air stays at room temperature

These equations can be solved by hand. With ``n = 1.4`` at 380 bar:
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
80 kN is the thrust at the moment the valve opens. Half a second later it is down to 59 kN.
"""

# ╔═╡ 7048f135-2533-5d1b-90f4-68eb7f5e573c
md"""
## Claim 3 · Our model: tank and nozzle on a test stand

Before we put the thrusters on the car, we test them on a fixed stand.
"""

# ╔═╡ 1ee75699-b8fe-5cad-beb0-d3e0967e7041
diagrams([joinpath(img_dir, "cold-gas-thrust-stand.png") =>
    "`TestColdGasThrustStand`: tank, nozzle and a fixed stand, valve wide open."]; height = "340px")

# ╔═╡ ea134b48-2c80-5bff-bb4f-655b714d9049
md"""
- **AirTank:** holds the air mass ``m``. Its pressure and temperature follow the rule on the
  previous slide.
- **ColdGasNozzle:** computes ``\dot m``, ``v_e`` and ``F`` from the tank's pressure and
  temperature. The valve command scales the throat area. Below 2 bar the valve closes, because
  the formulas only hold while the throat runs at the speed of sound.
- **Fixed stand:** holds the nozzle still, so we measure thrust without anything moving.
"""

# ╔═╡ 6d1930fd-1787-5449-acfa-579396d3b31b
dyad_fold("AirTank", "ColdGasNozzle")

# ╔═╡ 098ef777-bbf4-5a29-9f6f-e994f3418774
md"""
## Claim 3 · Simulation: emptying the tank on the stand

start pressure [bar] $(@bind p0_bar Slider(300:10:690; default = 380, show_value = true)) ·
tank [L] $(@bind V_L Slider(200:50:600; default = 600, show_value = true)) ·
n $(@bind n_poly Slider(1.0:0.05:1.4; default = 1.4, show_value = true)) ·
throat $(@bind throat Select(["fixed" => "fixed: 80 kN at 380 bar", "scaled" => "scaled: 80 kN at any pressure"]))
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

# ╔═╡ 454b7935-c1c3-5914-b6f5-ad13edd86d01
let
    sys = stand_rig.sys
    ts = range(0, 6; length = 600)
    F(sol) = sol(ts, idxs = sys.nozzle.F).u ./ 1e3
    (; F0, t80, t50) = blowdown.marks
    plt = plot(ts, F(blowdown.ghost); lw = 2, color = :gray, alpha = 0.6,
        label = "n = $(blowdown.ghost_n)", xlabel = "time [s]", ylabel = "thrust [kN]",
        legend = :topright, title = "Thrust: $(fmt(F0 / 1e3, 0)) kN at the start")
    plot!(plt, ts, F(blowdown.sol); lw = 3, color = :black, label = "n = $(n_poly)")
    plot!(plt, ts, [blowdown_closed_form(t; tank_setup...).F / 1e3 for t in ts]; lw = 2,
        ls = :dot, color = :darkorange, label = "formula")
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
    md"""
    - **Axes:** time [s] across. Left: thrust [kN]. Right, in green: air left in the tank [kg].
    - **Lines:** black is the Dyad model with your settings. Dotted orange is the formula; it lies
      on top of black. Gray is the same tank with the other extreme of ``n``. The dashed blue
      lines mark 80 % and 50 % of the starting thrust, and the dotted blue verticals mark when
      the thrust falls below them.
    - **Look at:** the steep drop just after the start. Thrust falls below 80 % after
      **$(fmt(t80)) s** and below half after $(fmt(t50)) s.
    - **What it means:** the green line falls slowly, but the thrust falls fast, because pressure
      and temperature both drop. Full thrust is a short pulse from $(fmt(blowdown.m0, 0)) kg of air.
    - **Try:** 690 bar with the fixed throat starts at $(fmt(hints.stand_690.F0 / 1e3, 0)) kN.
      Switch the throat to "scaled": back to $(fmt(hints.stand_690_scaled.F0 / 1e3, 0)) kN, held
      above 80 % for $(fmt(hints.stand_690_scaled.t80)) s. ``n = 1`` holds 80 % for
      $(fmt(hints.stand_n1.t80)) s. A 200 L tank only for $(fmt(hints.stand_200L.t80)) s.
      *Re-solved in $(fmt(blowdown.ms, 0)) ms.*
    """
end

# ╔═╡ a1eebfaa-ac28-5511-80f8-83ac87cbd423
md"## Claim 3 · Verdict"

# ╔═╡ e7533517-ea75-5361-b8a2-bb60c67ca3af
let
    (; F0, t80, t50) = blowdown.marks
    ref = blowdown_marks(stand_rig.default, stand_rig.sys)
    verdict_box(:partly, "Verdict: plausible as a peak, not as a steady push",
        """
        At 380 bar, four nozzles of about 20 mm give **$(fmt(ref.F0 / 1e3, 0)) kN** when the valves
        open, and 600 L holds 271 kg of air, close to the reported 250 kg. But the thrust falls
        below 80 % after **$(fmt(ref.t80)) s** and to half after $(fmt(ref.t50)) s. "Over 80 kN"
        is true only for an instant. At the current settings: $(fmt(F0 / 1e3, 0)) kN, 80 % held
        for $(fmt(t80)) s.

        **Next:** put the thrusters on the car.
        """)
end

# ╔═╡ b5dbdf36-0e13-5f76-bf1f-e829202924f3
md"""
## Claim 4: 0–60 mph in under a second

**Tesla's claim.**
- A recorded run took **1.0 s**. A live run took **0.81 s**; problems with the timer were
  reported.
- **Thrust trim** (rear thrusters): **under 0.9 s**. Electrek says it carries 200 L of air.
- **Rocket trim** (10 thrusters, 600 L): **under 0.59 s**.
- A 0.55 s figure used a "1 ft rollout": the clock starts after the car has rolled 30 cm. That is
  worth about 0.1 s.

**The question.** The thrust pushes the body directly. With it, are these times possible?
"""

# ╔═╡ be9624be-871f-5fd8-a3e7-ee4bf5bc1943
md"""
## Claim 4 · Physics check: what the times demand

Average acceleration ``a = v_{60} / t``, with ``v_{60} = 26.8`` m/s:
"""

# ╔═╡ 28d1e0a8-9372-54b2-bad9-020c0efdcf5f
html_table(["target", "time", "average acceleration"], [
    ("recorded run", "1.0 s", "$(fmt(V60 / 1.0 / G0)) g"),
    ("Thrust trim", "0.9 s", "$(fmt(V60 / 0.9 / G0)) g"),
    ("live run", "0.81 s", "$(fmt(V60 / 0.81 / G0)) g"),
    ("Rocket trim", "0.59 s", "$(fmt(V60 / 0.59 / G0)) g"),
]; widths = ["40%", "25%", "35%"], numeric = 2:3)

# ╔═╡ 8af337a6-0282-50b5-a98e-142755a66f42
md"""
## Claim 4 · Physics check: what the thrust adds

The thrust pushes the body, not the tires, so it adds to whatever the tires deliver. At the
start, for 2,000 kg:

```math
\frac{F}{m g} = \frac{80{,}000\ \text{N}}{2{,}000\ \text{kg} \cdot 9.81\ \text{m/s}^2} = 4.08\,g.
```

- **Thrust and tires, RWD:** 4.08 g plus 0.7 g from the rear tires at rest, about **4.8 g**.
- **Thrust and suction:** 4.08 g plus 1.75 g from the motor's torque cap, **5.8 g**.

Both start well above the 3.38 g that 0.81 s needs. But Claim 3 showed the thrust falling to
half within about 1.2 s, so only a simulation tells whether the average stays high enough.
"""

# ╔═╡ c7f8f3b8-8871-5e02-8132-9b03ce6868af
md"""
## Claim 4 · Our model: the full launch car

The same `RoadsterLaunch` as in Claim 1, now with the tank and the rear nozzles switched on.
"""

# ╔═╡ 3b0984f3-b69f-54b9-91f1-30fab8cc7881
diagrams([joinpath(img_dir, "roadster-launch.png") =>
    "`RoadsterLaunch`. Middle row: tank, nozzle, forward gain and forward force. Part of the nozzle's thrust also goes up into the downforce sum."]; height = "340px")

# ╔═╡ 8a7b118f-8b55-51e9-aca7-347662feb106
md"""
- **tank** and **nozzle:** the same blocks as on the test stand. The valves open fully at
  ``t = 0``, with no delay.
- **forward\_gain** and **forward\_force:** the share ``1 - d`` of the thrust that pushes the car
  forward.
- **downforce\_sum:** the share ``d`` of the thrust that points down and presses the car onto the
  road. It adds to the fan's downforce.
- ``d`` is `down_fraction`, from 0 (all back) to 1 (all down). The thrust acts at the height of
  the center of mass, so it does not tip the car.
"""

# ╔═╡ 75e1037e-5a0a-50f2-a755-29e7037ba07e
dyad_fold("RoadsterLaunch")

# ╔═╡ 72348138-0b2c-5966-bd28-17c6185490bf
md"""
## Claim 4 · Simulation: speed with thrust

thrust $(@bind use_thrust CheckBox(default = true)) ·
suction $(@bind use_suction CheckBox(default = false)) ·
tank $(@bind tank_choice Select(["600 L" => "600 L (Tesla, total)", "200 L" => "200 L (Thrust trim, Electrek)"])) ·
share pushed down d $(@bind down_fraction Slider(0.0:0.05:1.0; default = 0.0, show_value = true))
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
let
    time60, air = fmt(thrust_launch.t60), fmt(thrust_launch.air, 1)
    off, small, heavy = fmt(hints.thrust_off_suction), fmt(hints.thrust_200L), fmt(hints.thrust_m2350)
    low, lowsmall = fmt(hints.thrust_300bar), fmt(hints.thrust_300bar_200L)
    ms = fmt(thrust_launch.ms, 0)
    md"""
    - **Axes:** time [s] across, speed [km/h] up.
    - **Lines:** blue is your settings; the tank pressure, ``n`` and throat come from the Claim 3
      sliders. The three gray lines are fixed baselines (2,000 kg, RWD, 380 bar). Dotted black
      is 60 mph; dashed red is Tesla's live run, dashed purple the Rocket claim.
    - **Look at:** where blue crosses the dotted line: **$(time60) s**, using **$(air) kg** of
      air. The line bends over: the push is strongest at the start and fades as the tank empties.
    - **What it means:** with thrust, the car beats 0.81 s and even 0.59 s.
    - **Try** (2,000 kg, RWD): untick thrust and tick suction: $(off) s. Thrust alone with
      200 L: $(small) s. Suction and thrust at 2,350 kg: $(heavy) s, which misses the Rocket
      claim. At 300 bar: $(low) s, and $(lowsmall) s with 200 L. *Re-solved in $(ms) ms.*
    """
end

# ╔═╡ 8a0fa3f8-202e-50f4-9581-98cbd5938f11
md"""
## Claim 4 · Simulation: where the push comes from
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
        color = :firebrick, label = "+ thrust pushing forward")
    plot!(plt, ts, grip; lw = 2, ls = :dash, color = :seagreen, label = "tire limit μ·F_z")
    hline!(plt, [sol.ps[sys.motor.T_max] / sol.ps[sys.radius] / 1e3]; lw = 2, ls = :dash,
        color = :darkorange, label = "torque cap T_max/r")
    plt
end

# ╔═╡ 594df3dd-969c-5e42-bbfd-2a5521492f45
let
    sys = launch_rig.sys
    sol = thrust_launch.sol
    ts = range(0, min(thrust_launch.t60, 3.0); length = 300)
    tire = sum(sol(ts, idxs = sys.wheel.F_x).u)
    forward = (1 - down_fraction) * sum(sol(ts, idxs = sys.nozzle.F).u)
    share = forward / (tire + forward)
    md"""
    - **Axes:** time [s] across, up to 60 mph; force on the car [kN] up.
    - **Areas:** the blue area is the tire force. The red area on top is the forward thrust. The
      top edge of the red area is the total push.
    - **Lines:** dashed green is the tire limit ``\mu F_z``, dashed orange the torque cap
      ``T_{max}/r``.
    - **Look at:** the red band gets thinner as the tank pressure falls. The blue area stays
      under both dashed lines.
    - **What it means:** the thrust gives **$(fmt(100 * share, 0)) %** of the push up to 60 mph.
      It acts on the body, so it adds speed whichever limit holds the tires back.
    """
end

# ╔═╡ e3fe65ed-ec1f-52ef-a417-d8ef143deb5f
md"""
## Claim 4 · Simulation: push down or push back?

A plume over the roof in the video suggests that some air pushes the car down for grip. Each
newton pushed down gives at most 0.86 N of tire force with RWD, and 1.23 N with AWD, and only
until the torque cap is reached. Each newton pushed back is a full newton forward.
"""

# ╔═╡ 0aeb3bc7-8037-575b-ad36-d81a5834ea0c
let
    plt = plot(xlabel = "share of the thrust pushed down, d", ylabel = "time to 60 mph [s]",
        legend = :topleft, title = "Point the air backward")
    for c in down_grid.curves
        plot!(plt, down_grid.fractions, c.t60; lw = 2, marker = :circle, ms = 3,
            label = "$(c.layout), fan $(c.fan_cmd == 1 ? "on" : "off"), best at d = $(c.best)")
    end
    scatter!(plt, [down_fraction], [thrust_launch.t60]; ms = 9, marker = :star5,
        color = :black, label = "current")
    plt
end

# ╔═╡ 4e29c85b-03d2-5502-8fed-f7d389f406bc
let
    awd_off = only(filter(c -> c.layout == "AWD" && c.fan_cmd == 0, down_grid.curves))
    i_best = argmin(awd_off.t60)
    md"""
    - **Axes:** the share of thrust pushed down, ``d``, across (0 is all back, 1 is all down);
      the time to 60 mph [s] up.
    - **Lines:** four cases computed at load (2,000 kg, 380 bar): RWD and AWD, each with the fan
      off and on. The legend gives each case's best ``d``. The black star is your current
      settings.
    - **Look at:** every curve rises to the right. Only AWD with the fan off dips, from
      $(fmt(awd_off.t60[1], 3)) s at ``d = 0`` to $(fmt(awd_off.t60[i_best], 3)) s at
      ``d =`` $(awd_off.best).
    - **What it means:** point the air backward. Pushing down pays only for AWD without suction,
      and only a little: past about 8 kN pushed down, the torque cap is reached and the extra
      grip is wasted.
    - **Try:** set ``d = 1``, all air pushing down: $(fmt(hints.thrust_all_down)) s (RWD, fan
      off), slower than suction alone.
    """
end

# ╔═╡ 9ae7361b-cbcb-5ef8-8f87-8b1b4f5af276
md"## Claim 4 · Verdict"

# ╔═╡ 92d82a98-af32-53ec-8efc-79ce25173c66
let
    ok = trims.thrust < 0.9 && trims.rocket < 0.59
    verdict_box(ok ? :yes : :partly,
        ok ? "Verdict: plausible, with a full tank at 380 bar" : "Verdict: only with a lighter car or more pressure",
        """
        Baseline car (2,000 kg, RWD, 380 bar): tires and thrust **$(fmt(reference.tires_thrust.t60)) s**,
        suction and thrust **$(fmt(reference.suction_thrust.t60)) s**, suction and thrust with
        200 L **$(fmt(reference.thrust_200l.t60)) s**. The run uses about
        $(fmt(reference.suction_thrust.air, 0)) kg of air, a fifth of the tank.

        At the current panel and tank settings: Thrust trim $(fmt(trims.thrust)) s (claim: under
        0.9 s), Rocket trim $(fmt(trims.rocket)) s (claim: under 0.59 s).

        This holds only if the valves open fully at the start, the tank is near 380 bar, and the
        car weighs about 2,000 kg. At 2,350 kg, suction and thrust take
        $(fmt(hints.thrust_m2350)) s, and the Rocket claim fails.

        **Next:** point the thrust at the ground.
        """)
end

# ╔═╡ 4c7104d2-88a3-5822-a1d7-3b2cba51faea
md"""
## Claim 5: "it can fly"

**Tesla's claim.**
- The event was billed as a car that flies. TechCrunch's headline: "Tesla reveals
  SpaceX-powered Roadster that flies".
- **Kickflip:** the car jumped over a row of cars while rolling a full turn. A frame-by-frame fit
  of the video gives an apex of about **8 m** and a roll rate of 177 °/s (third party).
- **What was shown:** hops, flips and short hovers. No sustained flight.
- **Rocket trim:** 4 of its 10 nozzles point down, at the corners.

**The question.** How high can 600 L of air lift the car, and how long can it hover?
"""

# ╔═╡ 1a79a088-861a-5983-8a1e-856a5dd2110a
md"""
## Claim 5 · Physics check: an 8 m hop

To coast up to a height ``h``, the car must leave the ground at speed

```math
v = \sqrt{2 g h} = \sqrt{2 \cdot 9.81 \cdot 8} = 12.5\ \text{m/s}.
```

The push it needs is the momentum ``m v``, called the impulse ``J``:

```math
J = m v = 2{,}000\ \text{kg} \cdot 12.5\ \text{m/s} = 25.1\ \text{kN·s}.
```

Each kilogram of air leaves at ``v_e = 693`` m/s, so the air needed is about
``J / v_e = 25{,}100 / 693 = 36`` kg. With 80 kN up and 19.6 kN of weight down, the net push is
60.4 kN, so the burn lasts about ``25.1 / 60.4 = 0.42`` s. Holding up the weight during the burn
costs some extra air.
"""

# ╔═╡ 7c3d9060-9dde-5d5c-9c00-5b194e10e521
md"""
## Claim 5 · Physics check: hovering

To hover, the thrust must equal the weight: ``\dot m\, v_e = m g``. So the air flow is

```math
\dot m = \frac{m g}{v_e} = \frac{2{,}000 \cdot 9.81\ \text{N}}{693\ \text{m/s}} = 28\ \text{kg/s}.
```

At that rate 271 kg would last ``271 / 28 = 9.6`` s. The real limit comes sooner: as the
pressure falls, even a wide-open valve can no longer carry the weight. Adding up the flow until
that moment gives about **5.4 s** (2,000 kg, 380 bar).
"""

# ╔═╡ 12ebe6b9-cf3d-5ac7-b05d-b34b359fd7d2
md"""
## Claim 5 · Physics check: hover time against mass

The same calculation for every mass and three tank pressures.
"""

# ╔═╡ 65410189-b0b1-5e52-b267-63adb383edc6
let
    masses = range(1500, 2600; length = 56)
    plt = plot(xlabel = "car mass [kg]", ylabel = "hover time [s]", legend = :topright,
        title = "Seconds, not minutes", ylims = (0, 16))
    vspan!(plt, [1700, 2350]; color = :gray, alpha = 0.15, label = "mass estimates")
    for (p0, color) in ((300e5, :steelblue), (380e5, :black), (690e5, :firebrick))
        plot!(plt, masses, hover_closed_form.(masses; p0); lw = 3, color,
            label = "600 L at $(round(Int, p0 / 1e5)) bar")
    end
    plt
end

# ╔═╡ e5e85a35-3f2a-5b7d-a6b2-b0d959c24302
md"""
- **Axes:** car mass [kg] across, hover time [s] up, from the formula above.
- **Lines:** one per start pressure: blue 300 bar, black 380 bar, red 690 bar, all 600 L and the
  same nozzles. The gray band covers the published mass estimates.
- **Look at:** inside the gray band, every line stays below
  $(fmt(hover_closed_form(1700.0; p0 = 690e5), 0)) s.
- **What it means:** hover lasts seconds, not minutes, even for a light car at 690 bar.
"""

# ╔═╡ beed5f9f-8952-52ec-99b0-990d9b107f48
md"""
## Claim 5 · Our model: the car as a vertical hopper

A new model, `VerticalHop`: the car can only move up and down.
"""

# ╔═╡ 14d97564-3dfc-5b16-b9a7-e6437ceee636
diagrams([joinpath(img_dir, "vertical-hop.png") =>
    "`VerticalHop`: the command opens the nozzle, the thrust pushes the body up, and the ground contact holds it from below."]; height = "320px")

# ╔═╡ cf43fa07-26f2-5780-88cd-4a4d5d6e5ab5
md"""
- **body:** the car's mass, pulled down by gravity.
- **ground** (`VerticalGroundContact`): a stiff spring and damper that can push the car up but
  never pull it down, so the car can leave the ground and land again.
- **tank** and **nozzle:** the same as in Claim 3, now pointing down.
- **Hop test:** the valves stay fully open for a burn time ``t_b``, then shut.
- **Hover test:** a controller sets the valve to hold 2 m. It reacts to the height error and its
  running sum (a PI controller), and adds the valve opening that would carry the weight.
"""

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
        label = "formula h(t_b) + v(t_b)²/2g")
    hline!(plt, [8.0]; color = :gray, ls = :dot, label = "kickflip apex, 8 m")
    vline!(plt, [t_b]; color = :firebrick, ls = :dot, label = "valves close")
    plt
end

# ╔═╡ 05e11080-54c1-5b8c-8a82-34521a4482e8
let
    burn, mass = fmt(t_b, 3), car.m
    apex, air = fmt(hop_run.apex.apex, 1), fmt(hop_run.air, 1)
    short, long, heavy = fmt(hints.hop_03, 1), fmt(hints.hop_06, 1), fmt(hints.hop_m2350, 1)
    ms = fmt(hop_run.ms, 0)
    md"""
    - **Axes:** time [s] across, altitude [m] up.
    - **Lines:** blue is the car's altitude from the model. Dashed orange is the apex from the
      formula: the height and speed when the valves close, then a free coast up. Dotted gray is
      the 8 m kickflip apex. The dotted red vertical marks when the valves close.
    - **Look at:** blue climbs steeply while the valves are open, then follows a free-fall arc
      and lands. Its peak touches the orange line, so model and formula agree.
    - **What it means:** a $(burn) s burn lifts $(mass) kg to **$(apex) m** for
      **$(air) kg** of air, out of 271 kg.
    - **Try** (2,000 kg): a 0.3 s burn reaches $(short) m; 0.6 s reaches $(long) m. At 2,350 kg,
      0.413 s reaches only $(heavy) m. *Re-solved in $(ms) ms.*
    """
end

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
        ylabel = "valve opening (0 to 1)", ylims = (0, 1.1), label = "")
    plt
end

# ╔═╡ 1eb22217-6b48-5fd1-bbd0-29ab9b184fdf
let
    mass, p0 = car.m, p0_hover
    hover, closed = fmt(hover_run.time, 2), fmt(hover_run.closed, 2)
    left, pleft = fmt(hover_run.air_left, 0), fmt(hover_run.p_left / 1e5, 0)
    high, heavy = fmt(hover_grid.times[2, 3], 1), fmt(hover_grid.times[3, 2], 1)
    ms = fmt(hover_run.ms, 0)
    md"""
    - **Axes:** time [s] across. Left: altitude [m]. Right, in orange: the valve opening, from 0
      (shut) to 1 (wide open).
    - **Lines:** blue is the altitude. Orange is the valve. The dashed red vertical marks the
      moment the valve is wide open.
    - **Look at:** the car climbs, overshoots a little and settles at 2 m. The orange line creeps
      up: as the pressure falls, the same weight needs a wider valve. Once it reaches 1, blue
      drops.
    - **What it means:** $(mass) kg at $(p0) bar hovers for **$(hover) s** (formula: $(closed) s).
      The tank still holds $(left) kg at $(pleft) bar, but that pressure can no longer carry the
      car.
    - **Try:** 690 bar gives $(high) s at 2,000 kg. A 2,350 kg car at 380 bar: $(heavy) s.
      *Re-solved in $(ms) ms.*
    """
end

# ╔═╡ 915b1cfd-3760-5fcf-8a85-8ed0e1e48109
md"""
## Claim 5 · Simulation: hover time for every mass and pressure

Each cell is one run of the Dyad hover model, done when the notebook opens. Rows are the car
mass, columns the start pressure of the 600 L tank.
"""

# ╔═╡ 62cc1624-ca88-5b76-9cef-c99bf1e68897
html_table(["hover time [s]", "300 bar", "380 bar", "690 bar"],
    [("**$(m) kg**", fmt.(hover_grid.times[i, :], 2)...) for (i, m) in enumerate(hover_grid.masses)];
    numeric = 2:4)

# ╔═╡ 01e4001b-78f3-53f2-b887-c5730fb68f6e
md"""
The best case, a 1,700 kg car at 690 bar, hovers for $(fmt(maximum(hover_grid.times), 1)) s.
The worst, 2,350 kg at 300 bar, for $(fmt(minimum(hover_grid.times), 1)) s.
"""

# ╔═╡ b05ee7f3-2185-518f-9536-7635c28a8067
md"""
## Claim 5 · Extra: what does the kickflip roll cost?

Spinning the car is cheap compared with lifting it.

- ``I \approx 870`` kg·m²: the car's resistance to rolling (its moment of inertia, estimated)
- ``\omega``: the roll rate; ``L = I \omega`` is the angular momentum
- the nozzles sit an arm ``a`` from the roll axis, so they must deliver an impulse ``L / a``
- the air is impulse over ``v_e = 693`` m/s, and twice that to stop the roll again

roll rate [°/s] $(@bind roll_rate Slider(90:1:360; default = 177, show_value = true)) ·
arm a [m] $(@bind arm Slider(0.6:0.05:1.2; default = 0.9, show_value = true))
"""

# ╔═╡ efcd227c-be87-5b78-b0a3-49f80f436147
let
    I_roll, v_e = 870.0, 693.0
    L = I_roll * deg2rad(roll_rate)
    air = L / arm / v_e
    md"""
    ``L =`` $(fmt(L / 1e3, 2)) kN·m·s, impulse $(fmt(L / arm / 1e3, 2)) kN·s: **$(fmt(air, 1)) kg**
    of air to start the roll, **$(fmt(2air, 1)) kg** to start and stop it, against
    $(fmt(hop_run.air, 0)) kg for the hop. Rotation is cheap; lift is expensive.
    """
end

# ╔═╡ 1d30f2e4-a668-58d4-8945-17fc3d94ef27
md"## Claim 5 · Verdict"

# ╔═╡ 4130d78a-3223-5804-899c-07e48ca7ae66
let
    hop_air = air_used(hop_rig.default, hop_rig.sys, 0.413; tank = "hop.tank")
    verdict_box(:partly, "Verdict: the hop is plausible; flying is not",
        """
        **Hop:** a 0.413 s burn lifts the 2,000 kg car to $(fmt(hop_apex(hop_rig.default, hop_rig.sys).apex, 1)) m
        for $(fmt(hop_air, 0)) kg of air, a sixth of the tank. The 8 m kickflip fits. At the current
        settings: $(fmt(hop_run.apex.apex, 1)) m.

        **Hover:** $(fmt(hover_grid.times[2, 2], 1)) s at 2,000 kg and 380 bar, and at most
        $(fmt(maximum(hover_grid.times), 1)) s in any case we tried. Then the tank can no longer
        carry the car. It hops; it does not fly.
        """)
end

# ╔═╡ 4f6ecd1c-90bb-52bd-85da-d989ab7adc4a
score_rows = let
    (; F0, t80) = blowdown.marks
    [
        verdict_row("Warm-up: the ramp shot plays in real time", "shown as footage",
            "about $(fmt(warmup.k_ramp))× fast", :no),
        verdict_row("1: 0–60 mph in about 1 s on tires", "1.0 s, 0.81 s live",
            "$(fmt(tires.t60)) s ($(drive_layout))", tires.t60 <= 1.0 ? :yes : :no),
        verdict_row("2: Performance trim, fans", "under 1.6 s", "$(fmt(suction.t60)) s",
            suction.t60 <= 1.05 * 1.6 ? :yes : :no),
        verdict_row("2: holds the car upside down", "4,700 kg",
            "$(fmt(suction.hold_margin))× weight", suction.hold_margin >= 1 ? :yes : :no),
        verdict_row("3: 80 kN rear thrust", "over 80 kN",
            "$(fmt(F0 / 1e3, 0)) kN, ≥ 80 % for $(fmt(t80)) s", F0 >= 0.95 * 80e3 ? :yes : :no),
        verdict_row("4: Thrust trim, 200 L", "under 0.9 s", "$(fmt(trims.thrust)) s",
            trims.thrust < 0.9 ? :yes : :no),
        verdict_row("4: Rocket trim, 600 L", "under 0.59 s", "$(fmt(trims.rocket)) s",
            trims.rocket < 0.59 ? :yes : :no),
        verdict_row("5: 8 m kickflip hop", "about 8 m",
            "$(fmt(hop_run.apex.apex, 1)) m, $(fmt(hop_run.air, 0)) kg air",
            isfinite(hop_run.apex.apex) ? :yes : :pending),
        verdict_row("5: it can fly", "\"it can fly\"", "hovers $(fmt(hover_run.time, 1)) s",
            isfinite(hover_run.time) && hover_run.time > 60 ? :yes : :no),
    ]
end;

# ╔═╡ 4378f115-d8fc-5392-9deb-ead3ccf2eb03
md"""
## Scoreboard

One row per claim. The model column follows the panel and the sliders.
"""

# ╔═╡ 1a1cf665-5227-5108-b6d8-6a9c8e955454
let
    word = Dict(:yes => "plausible", :no => "**not plausible**", :pending => "not reached")
    html_table(["claim", "Tesla", "model", "verdict"],
        [(r.claim, r.tesla, r.model, word[r.verdict]) for r in score_rows];
        widths = ["34%", "20%", "28%", "18%"])
end

# ╔═╡ 14bd41f4-6154-55bd-84db-91319ba078bd
scoreboard(score_rows)

# ╔═╡ fd52d12c-fa1f-5fc5-bf6c-369a33a56041
md"""
## Summary

- **Tires alone cannot do it.** Tesla's own 1.26 g tire gives 3.3 s with rear-wheel drive.
- **Suction can give 1.6 s.** It moves the limit from the tire to the motor's torque. The skirt
  gap sets the fan's power bill.
- **The thrusters give 80 kN only as a peak.** The thrust halves within about 1.2 s.
- **With thrust, under a second is possible:** 0.53–0.68 s, for about 50 kg of air.
- **It hops; it does not fly.** An 8 m hop costs 43 kg of air; hover lasts about 5 s.

What to take away:
- **Write the limit down first.** Every verdict started from one inequality: grip, torque, power,
  or the air in the tank.
- **Find which limit is active.** Suction did not add power; it moved the limit.
- **A peak is not a level.** A tank that blows down gives a pulse, not a steady force.
- **Check the simulation with a hand calculation.** Each Dyad result matched its formula.

Open questions for the hands-on: what changes at 690 bar, at 2,350 kg, or with a 1 ft rollout?
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

Tesla published neither the mass nor the tank pressure. The 80 kN and 250 kg figures are press
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
# ╟─73d1f345-c3c2-4f93-9873-b260ea105299
# ╟─0642455c-1da3-51e6-81ff-e990d6acb591
# ╟─40ef78e6-32c9-5c2d-9f7e-b2839b5a029d
# ╟─d1e686ea-7b9d-50b5-8585-e5b5bd5a5077
# ╟─d3171829-f6d6-55d0-b2eb-713d6ad7a265
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
# ╟─0a85f4c7-90ac-595f-b127-8474860e03df
# ╟─532b5431-9db1-5e77-b0bc-66f8324ca14c
# ╟─213033f3-32af-536b-a121-8c95e70f4fd0
# ╟─796e0f71-bc73-545d-8bc1-3375d8be9bcd
# ╟─ca3fab0a-57b4-5859-b505-19746d073c33
# ╟─ceba3a95-cacc-5e9b-9677-0c3d0016913f
# ╟─831bd16d-58f9-5236-867e-d5ed00adcf63
# ╟─3359a5d2-7aac-5f95-b6cf-d3420dd9d51b
# ╟─330c2302-e7e4-5849-be68-b75c86f3cacb
# ╟─0bcfb8b9-0d28-5c3c-baf7-8b3900960826
# ╟─4920fcd2-add1-5e85-8807-ebc7b0c0798f
# ╟─ed540754-92a5-512d-ad4e-3ffb141b2bf1
# ╟─1ce0d1b7-5ec1-580b-b0bd-934fb74a86fc
# ╟─490fee27-240a-52a6-b9cb-9b40cd4d6fb6
# ╟─066d157f-659c-5115-ad05-d595ff52c35c
# ╟─83b3f4a6-3a68-5399-bba1-ab286974d915
# ╟─341af294-bb6c-55d2-990c-78bbbe190ade
# ╟─10d92e2a-0efa-53cb-908f-508a45c53fad
# ╟─abae1e2d-05e7-57ce-94c1-ccf3253dde53
# ╟─f260e1c6-2e3d-5709-bc2b-16b4bd5a8abf
# ╟─112888f3-ea48-57b3-b534-15f0aaf2bb32
# ╟─481ffd01-b7ce-5a10-83be-4a9908d528c4
# ╟─ca3eb955-a7dc-5d89-aabc-fdee7a2c596b
# ╟─44ec27a2-ce80-5e03-af44-7104307276d6
# ╟─ca0bd79d-2962-5f45-93f1-af7cbd159796
# ╟─39c8664b-3505-5411-b5c7-87d75a2d2305
# ╟─9dd44b2e-19e5-50f3-8ecd-ca1b60b39231
# ╟─998d436b-2a45-5394-96f2-f88ec80b4ff7
# ╟─51d1218c-32e7-5d65-8a3a-d739ab7262fe
# ╟─cdb131a1-2d0a-5daa-b6af-25a40c21865a
# ╟─69cf5e21-22ec-5751-802d-b115c54e4080
# ╟─b575dc3a-6334-52cd-948f-ec0c294dafc5
# ╟─2afd0c56-0bf0-5b33-ae6d-73199a0b234b
# ╟─b8dc0784-9c5f-5800-b997-369529968c00
# ╟─a0a1a723-c8b2-57e1-99a2-fcf781edb50a
# ╟─68175a2d-7eea-5582-ba04-fe7751ce648d
# ╟─d2b00eee-ac62-5585-9237-78aba3ec9489
# ╟─3a2db6cd-e77b-548c-b081-6b3feb62e936
# ╟─71b6de44-ece9-5e3f-ad46-e1a5f649b945
# ╟─138ea814-3a72-52c2-942f-bbaae57968a0
# ╟─a3d6b00c-9a9c-5405-a396-0c3f88a25de3
# ╟─c46c6e9a-7269-5b19-8662-d14ef54554ad
# ╟─691785d8-5309-5564-8bdf-c62da7f64403
# ╟─3fa37ac3-eeae-5b31-8c9d-0ee094052260
# ╟─b699e8ab-5de0-5351-b54c-703476a2f793
# ╟─b6f85d2f-d29d-57a7-8e5a-f88d50751bff
# ╟─9af7179d-1a05-5fbb-84e8-358e9a628405
# ╟─4a0da2f8-be59-5215-abc1-0471fdfeb2a1
# ╟─e2dddf66-0017-55ad-b309-5f9cc11d72ee
# ╟─d61b4d3f-20b3-52e0-ba5a-9412c5c0dacf
# ╟─269eead9-b7e2-51f8-824a-cf060460e1f5
# ╟─7048f135-2533-5d1b-90f4-68eb7f5e573c
# ╟─1ee75699-b8fe-5cad-beb0-d3e0967e7041
# ╟─ea134b48-2c80-5bff-bb4f-655b714d9049
# ╟─6d1930fd-1787-5449-acfa-579396d3b31b
# ╟─098ef777-bbf4-5a29-9f6f-e994f3418774
# ╟─82ddb7df-c1e1-5e05-829e-9a3486abaa4e
# ╟─16a8f827-cd4b-55dc-8b1b-0feb358c99aa
# ╟─454b7935-c1c3-5914-b6f5-ad13edd86d01
# ╟─d656e5a8-e471-5ec3-a538-ed704c557b90
# ╟─a1eebfaa-ac28-5511-80f8-83ac87cbd423
# ╟─e7533517-ea75-5361-b8a2-bb60c67ca3af
# ╟─b5dbdf36-0e13-5f76-bf1f-e829202924f3
# ╟─be9624be-871f-5fd8-a3e7-ee4bf5bc1943
# ╟─28d1e0a8-9372-54b2-bad9-020c0efdcf5f
# ╟─8af337a6-0282-50b5-a98e-142755a66f42
# ╟─c7f8f3b8-8871-5e02-8132-9b03ce6868af
# ╟─3b0984f3-b69f-54b9-91f1-30fab8cc7881
# ╟─8a7b118f-8b55-51e9-aca7-347662feb106
# ╟─75e1037e-5a0a-50f2-a755-29e7037ba07e
# ╟─72348138-0b2c-5966-bd28-17c6185490bf
# ╟─ea852136-7152-5722-88c5-d7269a9dcb3e
# ╟─c526562d-9690-5b95-b0f9-67f9765b3fdf
# ╟─309bafac-d1f8-5e0a-b637-83a654847224
# ╟─1c4c5bb1-294b-5030-8745-8fcf24911c6b
# ╟─8a0fa3f8-202e-50f4-9581-98cbd5938f11
# ╟─6a75b042-0d4f-54dc-937d-1f8ecffd98f4
# ╟─594df3dd-969c-5e42-bbfd-2a5521492f45
# ╟─e3fe65ed-ec1f-52ef-a417-d8ef143deb5f
# ╟─0aeb3bc7-8037-575b-ad36-d81a5834ea0c
# ╟─4e29c85b-03d2-5502-8fed-f7d389f406bc
# ╟─9ae7361b-cbcb-5ef8-8f87-8b1b4f5af276
# ╟─92d82a98-af32-53ec-8efc-79ce25173c66
# ╟─4c7104d2-88a3-5822-a1d7-3b2cba51faea
# ╟─1a79a088-861a-5983-8a1e-856a5dd2110a
# ╟─7c3d9060-9dde-5d5c-9c00-5b194e10e521
# ╟─12ebe6b9-cf3d-5ac7-b05d-b34b359fd7d2
# ╟─65410189-b0b1-5e52-b267-63adb383edc6
# ╟─e5e85a35-3f2a-5b7d-a6b2-b0d959c24302
# ╟─beed5f9f-8952-52ec-99b0-990d9b107f48
# ╟─14d97564-3dfc-5b16-b9a7-e6437ceee636
# ╟─cf43fa07-26f2-5780-88cd-4a4d5d6e5ab5
# ╟─490fbb26-bcc0-5883-9550-6bc4488356da
# ╟─d7234072-bd91-5008-a8c7-bd27bf75fc30
# ╟─8be17925-68bd-5081-9994-2fa7bc043a49
# ╟─7297e311-1114-51f5-9256-06ee3e0555a4
# ╟─05e11080-54c1-5b8c-8a82-34521a4482e8
# ╟─0c45b5dd-4778-5b23-867c-ce6b58559e15
# ╟─72c966ff-94be-574b-9a41-d1909b728c48
# ╟─4ce799f5-e25f-5455-92cf-7868dc713552
# ╟─1eb22217-6b48-5fd1-bbd0-29ab9b184fdf
# ╟─915b1cfd-3760-5fcf-8a85-8ed0e1e48109
# ╟─62cc1624-ca88-5b76-9cef-c99bf1e68897
# ╟─01e4001b-78f3-53f2-b887-c5730fb68f6e
# ╟─b05ee7f3-2185-518f-9536-7635c28a8067
# ╟─efcd227c-be87-5b78-b0a3-49f80f436147
# ╟─1d30f2e4-a668-58d4-8945-17fc3d94ef27
# ╟─4130d78a-3223-5804-899c-07e48ca7ae66
# ╟─4f6ecd1c-90bb-52bd-85da-d989ab7adc4a
# ╟─4378f115-d8fc-5392-9deb-ead3ccf2eb03
# ╟─1a1cf665-5227-5108-b6d8-6a9c8e955454
# ╟─14bd41f4-6154-55bd-84db-91319ba078bd
# ╟─fd52d12c-fa1f-5fc5-bf6c-369a33a56041
# ╟─d58a74a2-207c-5a35-a637-ac0ec44ff8b3
# ╟─a34943ff-7ff3-55a6-9bd4-bca6a4c03be9
# ╟─95229d19-866e-5fbf-952e-52ae748c5604
# ╟─67ad1529-9b11-596d-8256-6ed6365d8d8e
