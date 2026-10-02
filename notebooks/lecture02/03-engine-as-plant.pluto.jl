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

# ╔═╡ c7ab16e2-fc97-43c3-8dcd-09045c6af094
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, "..", ".."))
    include(joinpath(@__DIR__, "..", "lecture01", "support.jl"))
    include(joinpath(@__DIR__, "support.jl"))
    using .Lecture01Support, .Lecture02Support
    # Not bound as `VehicleSystemsComponents`: run as a script, that global would collide with
    # the module of the same name that `setup` defines in `Main`.
    library = setup()
    using Plots, PlutoUI

    # draft_stubs.jl stands in for each analysis whose Dyad task has not landed. Deleting a
    # stub binds the real analysis here and no other cell changes.
    DRAFT_STUBS = joinpath(@__DIR__, "draft_stubs.jl")
    stubs = isfile(DRAFT_STUBS) ? include(DRAFT_STUBS) : nothing
    EngineDynoTransient = bind_analysis(:EngineDynoTransient, library; stubs)
    show_dyad = isnothing(stubs) ? Lecture01Support.show_dyad : stubs.show_dyad
end

# ╔═╡ 9da840dc-366a-4eb0-8bac-89c6ddddd2d1
md"""
# Lecture 2 · 03 — The engine as a plant

> **Lecture 1's engine was a lag and a delay. Here is where they come from, and why they are not
> constant.**

In Lecture 1 the cruise controller commanded a torque, and `Vehicle.IdealEngine` delivered it
through a 0.3 s transport delay, a 0.3 s first-order lag and a 150 N·m limit. That block was a
stand-in. A real ECU never commands torque directly. It moves a throttle plate, meters fuel and
times a spark, and the torque is whatever the engine makes of those three.

This notebook opens the block. It builds the plant the ECU actually controls and asks three
questions of it:

1. What pressure does the intake manifold sit at, at idle, at full load and on overrun?
2. Where does Lecture 1's lag come from, and why does it get shorter as the engine speeds up?
3. Where does the delay come from, and how long is it really?

It ends with the engine's own maps (torque, fuel consumption, efficiency), the tables every
later notebook reads.

**Model.** `Lecture2.EngineDynoTransient` holds `Vehicle.Engine.MeanValueEngine` at a fixed speed
on a dynamometer, the way an engine is calibrated on a test bed. Fuel is metered open loop at
λ = 1 from the cylinder air flow; there is no ECU yet (notebook 04 adds one).
"""

# ╔═╡ 37009922-fa74-446c-a4af-e50631a4328c
md"""
## The plant the ECU sees

Slide 24 splits an engine control system into sensors, the ECU and actuators. Strip away the
ECU and what is left is the plant, with three inputs the ECU moves and the outputs its sensors
read:

| | Signal | Actuator or sensor |
|---|---|---|
| in | throttle opening `u_thr` (0 closed, 1 wide open) | electronic throttle |
| in | fuel mass flow `ṁ_f` | injectors (notebooks 04 and 05) |
| in | spark advance `σ` [° before top dead center] | ignition (notebook 08) |
| out | engine speed `ω` | crankshaft sensor |
| out | manifold pressure `p_m` | manifold pressure sensor |
| out | air mass flow through the throttle `ṁ_thr` | hot-film air-mass sensor (slide 37) |

The model is **mean-value**: it averages over an engine cycle and ignores the individual
strokes. Crank-angle events (one cylinder's pressure trace, an injector pulse, a spark) live in
their own models with their own time scale (notebooks 02, 05, 08). A mean-value engine is the
right size for a control loop, which acts over tens of milliseconds and longer.
"""

# ╔═╡ 7b0e2e4e-986c-43c4-b5b9-68b15d69db34
md"""
## 1 · The air path

Air passes three components in series, each a two-line equation.

**Throttle.** A plate at angle `α` leaves an open area `A(α)`. The flow through it is that of an
orifice, a nozzle once the pressure ratio falls far enough:

```math
\dot m_\text{thr} = C_d\,A(\alpha)\,\frac{p_a}{\sqrt{R\,T_a}}\,\Psi\!\left(\frac{p_m}{p_a}\right),
\qquad
\Psi(\Pi) = \sqrt{\frac{2\gamma}{\gamma-1}\left(\Pi^{2/\gamma} - \Pi^{(\gamma+1)/\gamma}\right)}
\quad \text{for } \Pi \ge \Pi_\text{cr}
```

Below the critical ratio `Π_cr = (2/(γ+1))^(γ/(γ−1)) ≈ 0.528` the flow reaches the speed of sound
in the gap, `Ψ` stays at its value at `Π_cr`, and the throttle flow no longer depends on the
manifold pressure at all. The throttle is then **choked**: a closed throttle at idle is.

**Manifold.** The volume between the throttle and the intake valves fills with what the throttle
lets in and empties into the cylinders:

```math
\dot p_m = \frac{R\,T_m}{V_m}\left(\dot m_\text{thr} - \dot m_\text{cyl}\right)
```

**Cylinders.** Each cylinder draws its displacement once every two revolutions, filled to a
fraction `η_v` (the volumetric efficiency) at manifold density:

```math
\dot m_\text{cyl} = \eta_v\,V_d\,\frac{\omega}{4\pi}\,\frac{p_m}{R\,T_m}
```

`V_d = 1.5 L` and `V_m = 1.0 L` *(MathWorks)*; the plate diameter and intake temperature are
MathWorks defaults too. `C_d`, the closed-plate angle and the `η_v` table are *(assumed)*, and the
leakage area at a closed plate is *(derived)*, set so the idle manifold pressure lands on 33 kPa.
"""

# ╔═╡ 68c9be8c-2963-45c1-aea1-01dbf5fe5d68
show_dyad("AirPath")

# ╔═╡ 0f3ffc37-193c-4425-8909-230e856ed996
begin
    IDLE, CRUISE = 800, 3000
    idle = EngineDynoTransient(omega_set = rad_per_s(IDLE), u_thr = 0.0)
    wot = EngineDynoTransient(omega_set = rad_per_s(CRUISE), u_thr = 1.0)
    overrun = EngineDynoTransient(omega_set = rad_per_s(CRUISE), u_thr = 0.0)
    operating_points = (idle, wot, overrun)
end

# ╔═╡ 45b160bf-b4c0-4fad-b3a3-b57f278a3528
let
    names = ["idle, 800 rpm,\nclosed", "wide open,\n3000 rpm", "overrun, 3000 rpm,\nclosed"]
    p_m = [kpa(last(last(signal(r, P_M)))) for r in operating_points]
    bands = [(30, 36), (90, 101.3), (0, p_m[1])]
    p = plot(; xticks = (1:3, names), ylabel = "manifold pressure [kPa]", ylims = (0, 110),
        xlims = (0.4, 3.6), legend = :topright,
        title = figure_title(operating_points, "Manifold pressure at three operating points"))
    for (i, (lo, hi)) in enumerate(bands)
        plot!(p, [i, i], [lo, hi]; lw = 28, color = :seagreen, alpha = 0.25,
            label = i == 1 ? "expected band" : "")
    end
    scatter!(p, 1:3, p_m; ms = 8, color = :steelblue, label = "model")
    hline!(p, [kpa(ENGINE.p_a)]; color = :gray, ls = :dot, label = "ambient")
    captioned(p, """
        Expected: idle 30–36 kPa and wide open above 90 kPa (the plan's reality anchors); overrun
        below idle.
        """ * placeholder_note(operating_points, "`EngineDynoTransient` signal `$P_M`"))
end

# ╔═╡ 2fc540af-db21-4742-8986-794a82e21aa0
check("`EngineDynoTransient` at idle, wide open and overrun, signal `$P_M`", operating_points...) do
    p_idle, p_wot, p_over = (kpa(last(last(signal(r, P_M)))) for r in operating_points)
    (30 <= p_idle <= 36 && p_wot > 90 && p_over < p_idle,
        "p_m idle $(round(p_idle; digits = 1)) kPa (30–36), wide open $(round(p_wot; digits = 1)) " *
        "kPa (> 90), overrun $(round(p_over; digits = 1)) kPa (below idle)")
end

# ╔═╡ 09cdecd1-4811-44cf-88e8-3b60f1ebde3e
md"""
### Why overrun goes so deep

With the throttle closed, the only air entering the manifold is the leakage past the plate, and
a choked throttle passes the same leakage at any manifold pressure. At 3000 rpm the cylinders
pump that same trickle away almost four times as fast as at 800 rpm, so the manifold settles at
roughly a quarter of the idle pressure, a deeper vacuum than real engines run at on overrun
(about 17–34 kPa). The difference is an ECU function, not physics: on overrun the ECU opens the
throttle or an idle-air valve slightly (a *dashpot*), which limits the vacuum, and with it the
oil drawn past the piston rings and the hydrocarbons that come with it. The bare plant here has
no ECU yet, so it shows the vacuum the ECU has to prevent.
"""

# ╔═╡ 77d8556a-c6b7-443e-bb8b-9ec19fc02014
md"""
## 2 · Where the lag comes from

Hold the speed and nudge the throttle open. The manifold is a volume being filled through one
orifice and emptied through another, so its pressure moves to the new balance along a
first-order curve. Linearize the manifold equation around an operating point with a choked
throttle, so that `ṁ_thr` does not depend on `p_m`:

```math
\frac{V_m}{R\,T_m}\,\delta\dot p_m = \delta\dot m_\text{thr} - \frac{\partial \dot m_\text{cyl}}{\partial p_m}\,\delta p_m
\quad\Longrightarrow\quad
\tau_m = \frac{V_m}{R\,T_m}\Big/\frac{\partial \dot m_\text{cyl}}{\partial p_m}
= \frac{4\pi\,V_m}{\eta_v\,V_d\,\omega}
= \frac{120\,V_m}{\eta_v\,V_d\,N}
```

with `N` in rpm. Two things follow. The time constant is a ratio of volumes, the manifold
against what the cylinders swallow per second; nothing about it is chosen. And it is inversely
proportional to engine speed: the faster the engine pumps, the faster the manifold settles. The
expected bands are 0.08–0.2 s at 800 rpm and 0.02–0.05 s at 3000 rpm.

The experiment: at each speed, start from a closed throttle, where the throttle is choked and the
formula applies, and open it by 1 % at `t = 0.5 s`.

The formula has a limit, and one more step shows it. With the throttle partly open, the
throttle is no longer choked: its flow falls as `p_m` rises, which adds to `∂ṁ_cyl/∂p_m` and
makes the manifold settle faster than the formula says. The dashed black curve is the same 1 %
step at 2000 rpm, starting from a throttle 15 % open.
"""

# ╔═╡ 858c333a-b6dc-474d-8f1c-942501a6d438
md"engine speed for the live step [rpm] $(@bind step_rpm Slider(800:200:6000; default = 2000, show_value = true))"

# ╔═╡ 863bfb24-23cb-47d4-bf6c-6f28dd0ce7af
begin
    STEP_RPM = [800, 2000, 3000, 4000]
    T_STEP, DU = 0.5, 0.01
    throttle_step(n) = EngineDynoTransient(omega_set = rad_per_s(n), u_thr = 0.0, du_thr = DU,
        t_step = T_STEP, stop = T_STEP + 1.5)
    step_runs = [throttle_step(n) for n in STEP_RPM]
    PART_LOAD = 0.15
    part_load_step = EngineDynoTransient(omega_set = rad_per_s(2000), u_thr = PART_LOAD, du_thr = DU,
        t_step = T_STEP, stop = T_STEP + 1.5)
    live_step = throttle_step(step_rpm)
    step_p_m = [step_response(signal(r, P_M)..., T_STEP) for r in step_runs]
    "Volumetric efficiency read back from the run's own signals at its final operating point."
    eta_v_of(r) = let p = last(last(signal(r, P_M))), m = last(last(signal(r, MDOT_CYL))),
            w = last(last(signal(r, OMEGA)))
        m * 4pi * ENGINE.R * ENGINE.T_m / (ENGINE.V_d * w * p)
    end
    tau_formula(r) = 120 * ENGINE.V_m / (eta_v_of(r) * ENGINE.V_d * rpm(last(last(signal(r, OMEGA)))))
end

# ╔═╡ 3d711860-cfa8-4acf-8c70-87dc768ac1f5
let
    p = plot(; xlabel = "time after the throttle step [s]", ylabel = "normalized p_m",
        xlims = (-0.05, 0.6), legend = :bottomright,
        title = figure_title(step_runs, "Manifold pressure after a 1 % throttle step"))
    for (n, s) in zip(STEP_RPM, step_p_m)
        plot!(p, s.t, s.y; lw = 2.5, label = "$n rpm")
    end
    let s = step_response(signal(part_load_step, P_M)..., T_STEP)
        plot!(p, s.t, s.y; lw = 2.5, ls = :dash, color = :black,
            label = "2000 rpm from $(round(Int, 100PART_LOAD)) % throttle (not choked)")
    end
    let s = step_response(signal(live_step, P_M)..., T_STEP)
        plot!(p, s.t, s.y; lw = 2, ls = :dot, color = :purple, label = "$(step_rpm) rpm (slider)")
    end
    hline!(p, [1 - exp(-1)]; color = :gray, ls = :dot, label = "63 %: one time constant")
    captioned(p, """
        Each curve is normalized from its pre-step to its final pressure, so only the speed of
        the response differs.
        """ * placeholder_note((step_runs, part_load_step, live_step),
            "`EngineDynoTransient` with `du_thr`, signal `$P_M`"))
end

# ╔═╡ 1f08eed6-57d1-4bd1-9360-b2300794afeb
let
    measured_tau = [s.tau for s in step_p_m]
    n = range(700, 4200; length = 100)
    eta = eta_v_of(first(step_runs))
    p = scatter(STEP_RPM, measured_tau; ms = 7, color = :steelblue, label = "measured, 63 % time",
        xlabel = "engine speed [rpm]", ylabel = "manifold time constant [s]", legend = :topright,
        title = figure_title(step_runs, "Manifold time constant against engine speed"))
    scatter!(p, STEP_RPM, tau_formula.(step_runs); marker = :x, ms = 7, color = :black,
        label = "120 V_m / (η_v V_d N), η_v from each run")
    scatter!(p, [2000], [step_response(signal(part_load_step, P_M)..., T_STEP).tau]; marker = :diamond,
        ms = 7, color = :darkorange, label = "2000 rpm from $(round(Int, 100PART_LOAD)) % throttle")
    plot!(p, [700, 900], [0.08, 0.08]; fillrange = 0.2, color = :seagreen, alpha = 0.2, lw = 0,
        label = "expected bands")
    plot!(p, [2900, 3100], [0.02, 0.02]; fillrange = 0.05, color = :seagreen, alpha = 0.2, lw = 0,
        label = "")
    plot!(p, n, 120 * ENGINE.V_m ./ (eta * ENGINE.V_d .* n); color = :gray, ls = :dash,
        label = "1/N shape at idle η_v")
    hline!(p, [0.3]; color = :firebrick, ls = :dot, label = "Lecture 1: τ_e = 0.3 s")
    captioned(p, "" * placeholder_note((step_runs, part_load_step),
        "`EngineDynoTransient` with `du_thr`, signals `$P_M`, `$MDOT_CYL`, `$OMEGA`"))
end

# ╔═╡ 71655b4f-f110-47f3-bc75-5ed1f2041eb8
let
    rows = map(zip(STEP_RPM, step_runs, step_p_m)) do (n, r, s)
        "| $n | $(measured(() -> eta_v_of(r), r; digits = 2)) | $(measured(() -> s.tau, r)) | " *
        "$(measured(() -> tau_formula(r), r)) | $(measured(() -> s.tau / tau_formula(r), r; digits = 2)) |"
    end
    Markdown.parse("""
        | engine speed [rpm] | η_v | measured τ_m [s] | 120 V_m/(η_v V_d N) [s] | ratio |
        |---:|---:|---:|---:|---:|
        $(join(rows, "\n"))
        """)
end

# ╔═╡ a1920490-be21-4d9b-bbf9-03f5828becbd
check("`EngineDynoTransient` throttle steps at 800, 2000, 3000 and 4000 rpm, signal `$P_M`", step_runs...) do
    tau = Dict(zip(STEP_RPM, (s.tau for s in step_p_m)))
    (0.08 <= tau[800] <= 0.2 && 0.02 <= tau[3000] <= 0.05 && tau[4000] < tau[800],
        "τ_m $(round(tau[800]; digits = 3)) s at 800 rpm (0.08–0.2), " *
        "$(round(tau[3000]; digits = 3)) s at 3000 rpm (0.02–0.05), " *
        "$(round(tau[4000]; digits = 3)) s at 4000 rpm (below 800 rpm)")
end

# ╔═╡ 9b1984d0-7c58-4659-8ac1-bd2d57db9e6a
md"""
### What the air-mass sensor sees

The slider's step shows one more thing. The throttle flow `ṁ_thr` jumps the moment the plate
opens, and the cylinder flow `ṁ_cyl` follows only as the manifold fills. While the manifold is
filling, the air the hot-film sensor measures (slide 37) is not the air the cylinders get. Notebook
04 meters fuel from a measurement of air, and this gap is one of the reasons a tip-in disturbs λ.
"""

# ╔═╡ 33cdc0bb-c175-4e7c-9518-17b8d551bcbb
let
    t, m_thr = signal(live_step, MDOT_THR)
    _, m_cyl = signal(live_step, MDOT_CYL)
    p = plot(t .- T_STEP, 1000 .* m_thr; lw = 2.5, color = :darkorange,
        label = "through the throttle (what the sensor measures)", xlims = (-0.05, 0.4),
        xlabel = "time after the throttle step [s]", ylabel = "air mass flow [g/s]",
        legend = :bottomright,
        title = figure_title(live_step, "Throttle and cylinder air flow at $(step_rpm) rpm"))
    plot!(p, t .- T_STEP, 1000 .* m_cyl; lw = 2.5, color = :steelblue, label = "into the cylinders")
    captioned(p, "" * placeholder_note(live_step,
        "`EngineDynoTransient` with `du_thr`, signals `$MDOT_THR` and `$MDOT_CYL`"))
end

# ╔═╡ aa5fdada-d09d-49a9-89d2-8aa228dd03dd
md"""
## 3 · Where the delay comes from

The air a cylinder draws during its intake stroke burns only after the compression stroke, half
a revolution later. A change in air or fuel therefore reaches the crankshaft as torque after
about 180° of crank, a delay fixed in angle and so inversely proportional to speed:

```math
\theta_\text{ind} = \frac{\pi}{\omega} = \frac{30}{N}\ \text{s}
```

which is 37.5 ms at 800 rpm and 10 ms at 3000 rpm. The model carries it as a speed-scheduled
chain of first-order lags (plan S8), because a fixed-length Padé delay cannot follow a delay that
changes with speed. The measurement below reads it from the same throttle steps, as the time
between the cylinder air flow and the torque each crossing half of their change.
"""

# ╔═╡ 446d4dd7-5ea3-4331-962c-bb3c3f31e04d
begin
    delays = map(step_runs) do r
        t, m = signal(r, MDOT_CYL)
        _, τ = signal(r, TAU_E)
        step_response(t, τ, T_STEP).t50 - step_response(t, m, T_STEP).t50
    end
    let n = range(700, 4200; length = 100)
        p = scatter(STEP_RPM, 1000 .* delays; ms = 7, color = :steelblue,
            label = "measured: torque behind cylinder air", xlabel = "engine speed [rpm]",
            ylabel = "induction-to-torque delay [ms]", legend = :topright,
            title = figure_title(step_runs, "Induction delay against engine speed"))
        plot!(p, n, 30_000 ./ n; color = :black, lw = 2, label = "180° of crank = 30/N s")
        hline!(p, [300]; color = :firebrick, ls = :dot, label = "")
        annotate!(p, 3000, 280, text("Lecture 1: θ_e = 0.3 s (off scale above)", 8, :firebrick))
        ylims!(p, 0, 320)
        captioned(p, "" * placeholder_note(step_runs,
            "`EngineDynoTransient` with `du_thr`, signals `$MDOT_CYL` and `$TAU_E`"))
    end
end

# ╔═╡ 63f918a1-c8bf-4c2f-8f00-876eb585c375
check("`EngineDynoTransient` throttle steps, signals `$MDOT_CYL` and `$TAU_E`", step_runs...) do
    errors = [abs(d / (30 / n) - 1) for (d, n) in zip(delays, STEP_RPM)]
    worst = maximum(errors)
    (worst <= 0.05,
        "induction delay within $(round(100worst; digits = 1)) % of 180° of crank at every " *
        "speed; band 5 %")
end

# ╔═╡ 62007c1d-6aa6-49c0-91a3-18c42caf04e3
md"""
## 4 · Lecture 1's lag and delay, honestly

Lecture 1 gave its engine a **0.3 s lag** and a **0.3 s delay**. Put them next to what the plant
above says:

| | Lecture 1 (`IdealEngine`) | physical, at 800 rpm | physical, at 3000 rpm |
|---|---:|---:|---:|
| lag (manifold filling) | 0.3 s | 0.08–0.2 s (expected band) | 0.02–0.05 s (expected band) |
| delay (induction) | 0.3 s | 37.5 ms | 10 ms |

The physical values are smaller, the delay by an order of magnitude. Lecture 1 knew this. Its
delay started at 0.04 s, about one engine cycle, and was raised to 0.3 s on purpose
(`docs/HANDOVER.md`, Risk 1). With a 0.04 s delay, the loop's ultimate period is short and
Ziegler–Nichols returns a proportional gain of 455 N·m per km/h, which on a 20 km/h speed step
commands 9100 N·m, sixty times what the engine can give. At 0.3 s the same method gives 67.5,
still nine times over the limit, but recognizably a controller for this car. A delay of
0.2–0.3 s is defensible as the whole path from torque request to wheel torque (ECU, fueling,
combustion, driveline compliance), and that is how Lecture 1 should be read: a lumped
powertrain, not an engine.

The more important difference is in the second and third columns: **the plant is not
constant**. Between idle and 3000 rpm the lag shrinks by a factor of about four and the delay by
the ratio of the speeds. A controller tuned at one operating point sees a different plant at
every other one. That is why engine controllers schedule their gains with speed and load, and
why an ECU is full of maps.
"""

# ╔═╡ 4d8a32dc-f9da-4c39-96dc-3b298ad3cc40
md"""
## 5 · Torque: the efficiency chain

The air the cylinders draw sets the fuel the engine can burn at a given λ, and the fuel sets the
heat released. Torque is that heat, discounted by a chain of efficiencies (plan S3, the
structure of MathWorks' SI Core Engine):

```math
\tau_i = \eta_i \, M_\sigma(\sigma_\text{mbt} - \sigma)\, M_\lambda(\lambda)\,
\frac{H_l\,\dot m_\text{burned}}{\omega},
\qquad
\tau_e = \tau_i - \frac{V_d}{4\pi}\left(\text{FMEP}(N) + p_\text{exh} - p_m\right)
```

- `η_i` is the indicated efficiency at the best spark timing and λ = 1 *(assumed)*.
- `M_σ` takes torque away when the spark is not at its best timing, MBT (notebook 02); about
  4 % at 10° from MBT *(assumed; expected band 2–5 %)*.
- `M_λ` is the effect of mixture: slightly more torque rich, more efficiency lean *(assumed
  shape)*. `ṁ_burned` is the fuel the air can burn, so a rich mixture's extra fuel is wasted.
- The last term is the work lost per cycle: friction (`FMEP`, the Barnes-Moss correlation
  *(textbook)*, scaled for a modern engine), and **pumping**, `p_exh − p_m`, the work of drawing
  air through a nearly closed throttle against exhaust back-pressure.

Notebook 03's dynamometer runs the spark at its MBT table, and λ is 1, so both multipliers are
1 here.
"""

# ╔═╡ 64b2142a-da0a-4e7e-8aec-fef7a797d289
show_dyad("TorqueProduction")

# ╔═╡ 63fd9022-4ad2-49d9-aa20-40b8ba09ad8c
begin
    MAP_RPM = [1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000]
    MAP_THROTTLE = [0.0, 0.02, 0.05, 0.1, 0.15, 0.2, 0.3, 0.5, 1.0]
    engine_map = operating_grid(EngineDynoTransient, [TAU_E, ETA_B, MDOT_FUEL, P_M];
        speeds = MAP_RPM, throttles = MAP_THROTTLE, stop = 0.5)
    map_torque = engine_map.values[TAU_E]
    map_bsfc = [τ > 5 ? 3.6e9 * f / (τ * rad_per_s(n)) : NaN
        for (τ, f, n) in zip(map_torque, engine_map.values[MDOT_FUEL], repeat(MAP_RPM, 1, length(MAP_THROTTLE)))]
    map_eta = [τ > 5 ? e : NaN for (τ, e) in zip(map_torque, engine_map.values[ETA_B])]
    TORQUE_GRID = collect(10.0:5.0:150.0)
end

# ╔═╡ c1664120-574a-4520-b370-9f3307b9fe8c
let
    wot_torque = map_torque[:, end]
    p = plot(MAP_RPM, wot_torque; lw = 3, marker = :circle, color = :steelblue,
        label = "wide-open throttle", xlabel = "engine speed [rpm]", ylabel = "brake torque [N·m]",
        legend = :bottomright, ylims = (0, 170),
        title = figure_title(engine_map.runs, "Full-load torque curve"))
    hspan!(p, [130, 150]; color = :seagreen, alpha = 0.15, label = "expected peak, 130–150 N·m")
    hline!(p, [CAR.T_max]; color = :firebrick, ls = :dot, label = "Lecture 1: T_max = 150 N·m")
    captioned(p, "" * placeholder_note(engine_map.runs,
        "`EngineDynoTransient` over speed at `u_thr = 1`, signal `$TAU_E`"))
end

# ╔═╡ 06702515-54bf-4770-a2b8-cb73236e23c2
let
    bsfc = permutedims(regrid(map_torque, map_bsfc, TORQUE_GRID))
    eta = permutedims(regrid(map_torque, map_eta, TORQUE_GRID))
    p1 = contour(float.(MAP_RPM), TORQUE_GRID, bsfc; fill = true, levels = collect(220.0:20.0:500.0), clims = (220, 500), color = :viridis,
        xlabel = "engine speed [rpm]", ylabel = "brake torque [N·m]", colorbar_title = "g/kWh",
        title = figure_title(engine_map.runs, "Brake-specific fuel consumption"))
    plot!(p1, MAP_RPM, map_torque[:, end]; lw = 3, color = :black, label = "")
    p2 = contour(float.(MAP_RPM), TORQUE_GRID, 100 .* eta; fill = true, levels = collect(10.0:3.0:40.0), color = :plasma,
        xlabel = "engine speed [rpm]", ylabel = "brake torque [N·m]", colorbar_title = "%",
        title = "Brake efficiency")
    plot!(p2, MAP_RPM, map_torque[:, end]; lw = 3, color = :black, label = "")
    compare(
        deck_figure("slide24-ecu-map.png"; width = 320),
        captioned(plot(p1, p2; layout = (2, 1), size = (620, 640)), """
            The engine's own maps: speed across, load as brake torque up, the way engine maps are
            published; the black line is the full-load curve. Slide 44 and notebook 04 measure load
            as manifold pressure in percent of ambient instead, which puts every speed's full-load
            point near 100 %. Beside them, slide 24's picture of the kind of map an ECU stores.
            """ * placeholder_note(engine_map.runs,
                "`EngineDynoTransient` over speed and throttle, signals `$TAU_E`, `$ETA_B`, `$MDOT_FUEL`")))
end

# ╔═╡ 24942dea-2b61-441d-9f49-56566ae253e1
check("`EngineDynoTransient` over speed and throttle, signals `$TAU_E`, `$ETA_B`, `$MDOT_FUEL`",
      engine_map.runs) do
    peak_torque = maximum(map_torque)
    peak_eta = maximum(filter(!isnan, map_eta))
    min_bsfc = minimum(filter(!isnan, map_bsfc))
    (130 <= peak_torque <= 150 && 0.33 <= peak_eta <= 0.38 && 225 <= min_bsfc <= 260,
        "peak torque $(round(peak_torque; digits = 1)) N·m (130–150), peak efficiency " *
        "$(round(100peak_eta; digits = 1)) % (33–38), minimum BSFC $(round(min_bsfc; digits = 0)) " *
        "g/kWh (225–260)")
end

# ╔═╡ c89b1957-ecef-456b-8983-bfcf74c3cb30
md"""
### Where the energy goes

Slide 23 quotes **37 %** as an engine's efficiency; the expected band for this engine's best
point is 33–38 %. That best point sits at moderate speed and high load. Everywhere else the map
falls away, for two different reasons:

- **At light load, pumping.** A nearly closed throttle holds the manifold far below the exhaust
  pressure, and the pistons spend work pulling the charge in. The term `p_exh − p_m` in the torque
  equation is largest exactly where the engine spends most of its life in town traffic. This is
  why downsized, turbocharged engines run at higher load for the same power.
- **At high speed, friction.** FMEP grows with speed, and at full speed a large share of the
  indicated work never leaves the crankshaft.

The rest of the 63 % leaves as heat in the exhaust and the coolant (notebook 10) and is not in
this model at all: `η_i` lumps it.
"""

# ╔═╡ a3618744-1419-4f71-86eb-b1c082921a12
md"""
## Honest numbers

**From a source.** Displacement, manifold volume, throttle diameter and intake temperature
(MathWorks); stoichiometric ratio 14.7 (deck slide 44; slide 23 says 14.6, a fuel-composition
difference); heating value and gas constants (textbook); the friction correlation's shape
(Barnes-Moss, textbook).

**Assumed.** The throttle discharge coefficient and closed-plate angle; the volumetric-efficiency
table; the indicated efficiency and the friction scale factor, both tuned to land the torque and
efficiency anchors; the spark and λ multipliers; the exhaust back-pressure.

**Derived.** The leakage area at a closed plate, set for 33 kPa at idle; the bands for the
manifold time constant and the induction delay, both from the equations above.

The bands in the check cells are the plan's reality anchors. A model that lands outside one is
wrong, or needs a stated reason.
"""

# ╔═╡ 53b937b0-7f89-41c2-8c52-04a736441465
md"""
## What this bought us

- The engine is a nonlinear plant with three inputs, and its manifold is a first-order lag whose
  time constant is fixed by volumes and falls as `1/N`.
- The torque delay is half a revolution of the crankshaft, so it too falls as `1/N`. Lecture 1's
  0.3 s lag and delay were a deliberate lumping of the whole powertrain, not an engine.
- A controller tuned at one speed meets a different plant at another, which is why the ECU's
  calibration is a set of maps, and this engine's own maps are now on the table.

**Next: 04 — How much fuel.** The dyno metered fuel from the true cylinder air. The ECU cannot see
that: it has to compute the fuel from what its sensors report, before the air arrives.
"""

# ╔═╡ b2c33413-2e03-4a33-96e0-d9c3b11917cc
details("Model contract: what this notebook needs from the Dyad side", md"""
Everything below is requested from Dyad task 2 (`docs/lecture-02-dyad-tasks.md`). Names in
**bold** are not in that spec yet.

### `Lecture2.EngineDynoTransient` (harness `Lecture2.EngineDyno`)

| Knob | Unit | Default | Values used here | Slider |
|---|---|---|---|---|
| `omega_set` | rad/s | 83.78 (800 rpm) | 800–6000 rpm | 800:200:6000 rpm (live step) |
| `u_thr` | – (0 closed, 1 wide open) | 0.0 | 0, 0.02 … 1.0 | – |
| **`du_thr`** (throttle step size) | – | 0.0 | 0.01 | – |
| **`t_step`** (throttle step time) | s | 0.5 | 0.5 | – |
| `sigma` | ° BTDC | the `sigma_mbt` table | not varied | – |
| `stop` | s | 2.0 | 0.5 (maps), 2.0 (steps) | – |

| Signal read | Path | Unit |
|---|---|---|
| engine speed | `engine.omega` | rad/s |
| manifold pressure | `engine.p_m` | Pa |
| throttle air flow | `engine.mdot_thr` | kg/s |
| cylinder air flow | `engine.mdot_cyl` | kg/s |
| brake torque | `engine.tau_e` | N·m |
| brake efficiency | `engine.eta_b` | – |
| injected fuel flow | **`fuel.y`** | kg/s |
| throttle command | **`throttle.y`** | – |

The maps are built from final values of 99 short `EngineDynoTransient` runs over
11 speeds × 9 throttle openings (`operating_grid` in `support.jl`). `EngineMapSweep` as a
steady-state analysis would replace those runs if the Dyad side provides one.

### Checks

| Check | Runs | Signals | Expected |
|---|---|---|---|
| manifold pressure | idle (800 rpm, closed); wide open and overrun at 3000 rpm | `engine.p_m` | idle 30–36 kPa; wide open > 90 kPa; overrun below idle |
| manifold time constant | 1 % step from closed at 800, 2000, 3000, 4000 rpm; one more from 15 % at 2000 rpm (shown, not checked) | `engine.p_m` (63 % time) | 0.08–0.2 s at 800; 0.02–0.05 s at 3000; 4000 below 800 |
| induction delay | same steps | `engine.mdot_cyl`, `engine.tau_e` (50 % times) | 180° of crank within 5 % |
| maps | 11 speeds × 9 throttles | `engine.tau_e`, `engine.eta_b`, `fuel.y` | peak torque 130–150 N·m; peak efficiency 33–38 %; minimum BSFC 225–260 g/kWh |
""")

# ╔═╡ Cell order:
# ╟─9da840dc-366a-4eb0-8bac-89c6ddddd2d1
# ╠═c7ab16e2-fc97-43c3-8dcd-09045c6af094
# ╟─37009922-fa74-446c-a4af-e50631a4328c
# ╟─7b0e2e4e-986c-43c4-b5b9-68b15d69db34
# ╠═68c9be8c-2963-45c1-aea1-01dbf5fe5d68
# ╠═0f3ffc37-193c-4425-8909-230e856ed996
# ╠═45b160bf-b4c0-4fad-b3a3-b57f278a3528
# ╠═2fc540af-db21-4742-8986-794a82e21aa0
# ╟─09cdecd1-4811-44cf-88e8-3b60f1ebde3e
# ╟─77d8556a-c6b7-443e-bb8b-9ec19fc02014
# ╠═858c333a-b6dc-474d-8f1c-942501a6d438
# ╠═863bfb24-23cb-47d4-bf6c-6f28dd0ce7af
# ╠═3d711860-cfa8-4acf-8c70-87dc768ac1f5
# ╠═1f08eed6-57d1-4bd1-9360-b2300794afeb
# ╠═71655b4f-f110-47f3-bc75-5ed1f2041eb8
# ╠═a1920490-be21-4d9b-bbf9-03f5828becbd
# ╟─9b1984d0-7c58-4659-8ac1-bd2d57db9e6a
# ╠═33cdc0bb-c175-4e7c-9518-17b8d551bcbb
# ╟─aa5fdada-d09d-49a9-89d2-8aa228dd03dd
# ╠═446d4dd7-5ea3-4331-962c-bb3c3f31e04d
# ╠═63f918a1-c8bf-4c2f-8f00-876eb585c375
# ╟─62007c1d-6aa6-49c0-91a3-18c42caf04e3
# ╟─4d8a32dc-f9da-4c39-96dc-3b298ad3cc40
# ╠═64b2142a-da0a-4e7e-8aec-fef7a797d289
# ╠═63fd9022-4ad2-49d9-aa20-40b8ba09ad8c
# ╠═c1664120-574a-4520-b370-9f3307b9fe8c
# ╠═06702515-54bf-4770-a2b8-cb73236e23c2
# ╠═24942dea-2b61-441d-9f49-56566ae253e1
# ╟─c89b1957-ecef-456b-8983-bfcf74c3cb30
# ╟─a3618744-1419-4f71-86eb-b1c082921a12
# ╟─53b937b0-7f89-41c2-8c52-04a736441465
# ╟─b2c33413-2e03-4a33-96e0-d9c3b11917cc
