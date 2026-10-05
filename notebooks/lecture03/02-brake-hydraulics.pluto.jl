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

# ╔═╡ 85847456-fad1-472a-8276-c59e9117c6ac
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, "..", ".."))
    include(joinpath(@__DIR__, "..", "lecture01", "support.jl"))
    using .Lecture01Support
    VehicleSystemsComponents = setup()
    using ModelingToolkit, Plots
    using DyadInterface: symbolic_container
    using PlutoUI
end


# ╔═╡ 72518851-e9fd-4acc-99f2-ed2a2c3a24a3
md"""
# Lecture 3 — How a car brake works (hydraulics, part 1)

This notebook follows a driver's foot force through the brake system until it becomes
**brake-line pressure**. Every number in it can be checked against a simulation of the Dyad
model it shows.

The model is the first increment of the brake library in `dyad/Vehicle/Brake/`: a **static
force chain** of pedal lever, vacuum booster and tandem master cylinder. Brake lines,
calipers and the car itself are not built yet, so this notebook stops at master-cylinder
pressure. The last sections say what arrives next.

The physics and the sources behind every parameter are in
`docs/reports/Passenger car brake system modeling.md`, cited below as *the report*.
"""


# ╔═╡ 1f49d5df-7a59-4987-93b8-86182a84c4cb
md"""
## 1. Why brakes need help

To stop at **1 g**, the tires must push back on the car with a force equal to its weight.
On the lecture's lumped car that force acts at the tire radius, so the brakes must hold a
torque of `m·g·r` at the wheels.

The calipers turn line pressure into that torque. With the report's caliper sizes (57 mm front
and 38 mm rear pistons, pad μ = 0.40, textbook values the report marks as unverified), every
bar of line pressure gives **49.0 N·m at the front axle and 19.9 N·m at the rear, 68.9 N·m/bar
in total**.

The driver's foot is the only input, and it is limited: FMVSS 135 caps the pedal force a
brake system may ask for at **500 N**
([49 CFR 571.135](https://www.law.cornell.edu/cfr/text/49/571.135), cited in the report).

The calculation below puts these together using the master-cylinder parameters of the
model further down. It answers one question: how far does a strong foot get on its own?
"""


# ╔═╡ 9d8a8e2c-3c81-42cc-8dbd-1685ab67c4b7
begin
    """
    Run `Vehicle.Brake.ForceChainTransient`, passing any keyword (such as `p_vac` in Pa) through
    to the analysis, and return the model, the solution, and pedal force and master-cylinder
    pressure sampled every 0.01 N of the ramp.
    """
    function force_chain(; kwargs...)
        run = VehicleSystemsComponents.Vehicle.Brake.ForceChainTransient(; kwargs...)
        model, sol = symbolic_container(run), run.sol
        t = range(sol.t[1], sol.t[end]; step = 1e-4)
        (; model, sol,
            p_vac = sol.ps[model.booster.p_vac],
            F_ped = sol(t, idxs = model.pedal.F_ped).u,
            p_bar = sol(t, idxs = model.master.p_mc).u ./ 1e5)
    end

    base = force_chain()
    P_ATM = base.sol.ps[base.model.booster.p_atm]
    no_vacuum = force_chain(p_vac = P_ATM)
    param(part, name) = base.sol.ps[getproperty(getproperty(base.model, part), name)]
    pressure_at(chain, F) = chain.p_bar[argmin(abs.(chain.F_ped .- F))]
end


# ╔═╡ cb6e41f3-6684-4665-b2ee-b75c6b045541
begin
    K_TORQUE = 68.9     # N·m/bar, report: 49.0 front + 19.9 rear
    F_FOOT_MAX = 500.0  # N, FMVSS 135
    p_1g = CAR.m * CAR.g * CAR.r / K_TORQUE

    let
        i_p, A_mc = param(:pedal, :i_p), param(:master, :A_mc)
        F_springs = param(:master, :F_cs0) + param(:master, :F_cf)
        F_rs0 = param(:booster, :F_rs0)

        F_x = CAR.m * CAR.g
        F_rod_1g = p_1g * 1e5 * A_mc + F_springs
        foot_needed = (F_rod_1g + F_rs0) / i_p
        foot_alone = (i_p * F_FOOT_MAX - F_rs0 - F_springs) / A_mc / 1e5

        r0(x) = round(Int, x)
        r1(x) = round(x; digits = 1)
        Markdown.parse("""
        | step | value |
        |:---|---:|
        | braking force at 1 g, `m·g` = $(r0(CAR.m)) kg × $(CAR.g) m/s² | **$(r0(F_x)) N** |
        | wheel torque, × `r` = $(CAR.r) m | **$(r0(F_x * CAR.r)) N·m** |
        | line pressure, ÷ $(K_TORQUE) N·m/bar | **$(r1(p_1g)) bar** |
        | master-cylinder pushrod force, `p·A_mc` + $(r0(F_springs)) N of spring and seal | **$(r0(F_rod_1g)) N** |
        | foot force without assist, + $(r0(F_rs0)) N booster spring, ÷ lever $(i_p) | **$(r0(foot_needed)) N** |
        | pressure from a $(r0(F_FOOT_MAX)) N foot without assist | **$(r1(foot_alone)) bar** |

        A 1 g stop needs about **$(r0(foot_needed)) N** from an unassisted foot, against the
        $(r0(F_FOOT_MAX)) N ceiling. The strongest legal foot alone reaches
        **$(r1(foot_alone)) bar**, about $(round(Int, 100foot_alone / p_1g)) % of the
        $(r1(p_1g)) bar that 1 g needs. The lever cannot close that gap on its own; the vacuum
        booster does.
        """)
    end
end


# ╔═╡ 1185ffe9-86ab-47ef-a50c-f334b44b2059
md"""
## 2. The chain: force is multiplied twice before any fluid moves

```
  driver's foot        F_ped
        │
        ▼
  ┌──────────────┐
  │ pedal lever  │     F_rod = i_p · F_ped                    (×3.5, assumed)
  └──────┬───────┘
         ▼
  ┌──────────────┐
  │ vacuum       │     F_out ≈ F_jump + SR · (F_rod − F_cut)  (×5 above cut-in, assumed)
  │ booster      │     until the vacuum runs out (run-out)
  └──────┬───────┘
         ▼
  ┌──────────────┐
  │ tandem master│     p_mc = (F_out − spring − seal) / A_mc
  │ cylinder     │
  └───┬──────┬───┘
      ▼      ▼
  circuit 1  circuit 2   same pressure in both, to the calipers
```

Following the report's section *"Force is multiplied twice before any fluid moves"*:

1. **Pedal lever.** A rigid lever multiplies foot force and divides travel by the same ratio.
2. **Vacuum booster.** A diaphragm with vacuum on its front face and, when the driver
   pushes, atmosphere on its rear face. The pressure difference across it adds force to the
   pushrod. Its output follows a five-piece curve: nothing below *cut-in*, a vertical
   *jump-in* step, a boosted slope equal to the *servo ratio*, and a knee at *run-out*
   where the rear chamber is fully at atmosphere and only the foot can add more.
3. **Tandem master cylinder.** Two pistons in one bore turn the pushrod force into pressure,
   roughly equal in two separate hydraulic circuits.

In the Dyad model the three stages are joined by translational `Flange` connectors, exactly
as the pushrods join them in the car. The master cylinder's two outputs are hydraulic
ports. Here both ports are capped (`ClosedHydraulicPort`), because the lines and calipers they
will feed do not exist yet.
"""


# ╔═╡ 6f4f30c7-7547-4f15-909e-ee1c2d4f9d65
md"""
## 3. Pedal lever

The pedal pivots on a fixed support. The driver pushes at the long end and the pushrod
attaches near the pivot, so

```math
F_\mathrm{rod} = i_p\,F_\mathrm{ped}, \qquad x_\mathrm{ped} = i_p\,x_\mathrm{rod}.
```

The lever does no work of its own: the product of force and travel is the same on both
sides. The force multiplication of **3.5×** is paid for in travel. Every millimeter the
master-cylinder piston moves costs the driver 3.5 mm of pedal stroke, and that budget runs
out at the floorboard. This is why the ratio cannot simply be raised to remove the booster.
Unboosted cars use **6–7:1**, boosted ones **4.5–5:1**
([Summit Racing](https://help.summitracing.com/knowledgebase/article/SR-05037/en-us)), and
one trade source gives **3.2–4:1** for OEM boosted systems
([Tomorrow's Technician](https://www.tomorrowstechnician.com/boosters-and-master-cylinders-how-pressure-builds/)).
The model's 3.5 is an assumed value inside that cited range.
"""


# ╔═╡ dbf14c8b-682d-4a5b-b734-c1d6c09a9c86
show_dyad("BrakePedal")


# ╔═╡ a9bd8d98-500f-4e45-9e02-b8fc3e34fed5
md"""
## 4. Vacuum booster

A diaphragm splits the booster into a front chamber, always connected to the vacuum source
through a check valve, and a rear working chamber. A poppet valve in the piston hub has three
states. **Released:** both chambers are at vacuum and the booster adds nothing. **Apply:** the
vacuum port closes and atmosphere flows into the rear chamber, so the pressure difference
pushes the diaphragm forward. **Hold:** both ports are closed. A rubber reaction disc splits
the output reaction between the driver's plunger and the power piston. The ratio of those
contact areas, not the diaphragm size, sets the **servo ratio**. The initial clearance between
disc and plunger produces the **jump-in** step (report, citing EduMech, Bosch and US5943937).

The static model keeps the resulting characteristic and drops the air dynamics:

- **cut-in** `F_cut`: below this pushrod force the valve stays closed and the output is zero;
- **jump-in** `F_jump`: at cut-in the output steps straight up, because the reaction disc
  has not yet touched the plunger;
- **servo ratio** `SR`: above cut-in every extra newton at the input gives `SR` newtons at
  the output;
- **run-out**: the assist cannot exceed `A_d·(p_atm − p_vac) − F_rs0`, the full pressure
  difference on the diaphragm minus the return spring. Beyond that knee only the driver's
  own force adds, at slope 1.

Without vacuum (`p_vac = p_atm`) the maximum assist is `−F_rs0`: the driver now has to push
the return spring as well. The outer `max(0, …)` in the model keeps the output from going
negative, because a booster can push the master cylinder but never pull it.

Servo ratio, jump-in and cut-in are **assumed**: the report found no primary source for
production values. The diaphragm area, return spring and 33 kPa idle vacuum are **cited**
from the PATH test car (UCB-ITS-PRR-97-21).

**Where the vacuum comes from** (the subject of the next notebook). A throttled
spark-ignition engine makes it for free: at idle the throttle is almost closed and the
intake manifold sits well below atmosphere. Diesels and unthrottled gasoline engines need a
separate vacuum pump, and the check valve holds stored vacuum at full load and after the
engine stops. Hybrids and EVs use electric vane pumps, or drop vacuum altogether for an
electromechanical booster such as the Bosch iBooster (report, citing de.wikipedia, Hella and
Bosch). Step 2 of the brake plan replaces this static booster with a dynamic one fed by an
intake-manifold model.
"""


# ╔═╡ 12ccf85a-84b8-4f10-af68-e90d9dc6ec73
show_dyad("StaticBooster")


# ╔═╡ 5e018b5c-ccf2-4ccd-9a59-b69910235eff
md"""
## 5. Tandem master cylinder

Two pistons share one bore. The pushrod drives the primary piston; primary pressure plus an
intermediate spring drive the floating secondary piston. In steady state both circuits carry
the same pressure, the pushrod force divided by the bore area after the return spring and
seal friction are paid (PATH's quasi-static form, from the report):

```math
p_\mathrm{mc} = \frac{\max(0,\; F_\mathrm{rod} - F_\mathrm{cs0} - F_\mathrm{cf})}{A_\mathrm{mc}}.
```

The bore is 25 mm (PATH), an area of 4.91 cm². That is the second multiplication: a small
piston turns a modest force into a large pressure.

**Why two circuits.** If one circuit leaks, the other still brakes. The split is either
front/rear (**II**) or diagonal (**X**: one front wheel with the opposite rear). An X split
always keeps one front brake and so about half the capability, but pulls the car toward the
working front wheel (report, citing EduMech and US10988170). The lecture's single lumped wheel
cannot yaw, so it can show a split only as lost deceleration and extra pedal travel.

**Dead stroke.** Before pressure can rise, each piston must first cover its compensating port
(or close its central valve). That travel moves no fluid. The model writes pushrod travel as
`x_rod = s_dead + V_disp/A_mc`, with an assumed `s_dead` of 2.5 mm (textbook range 1.5–3.5 mm).
Displaced volume `V_disp` grows only when fluid flows out to the calipers. Here both ports are
capped, so the pedal sits at its dead-stroke position for the whole run:
"""


# ╔═╡ f78b2985-e3fc-4823-bc75-9a7528126978
show_dyad("TandemMasterCylinder")


# ╔═╡ a8a76feb-9a34-403e-aa61-794eb05cd81d
let
    x_lo, x_hi = extrema(base.sol[base.model.pedal.x_ped])
    V_max = maximum(abs, base.sol[base.model.master.V_disp])
    travel = x_lo == x_hi ? "stays at **$(round(1e3x_lo; digits = 2)) mm**" :
        "moves between **$(round(1e3x_lo; digits = 2)) and $(round(1e3x_hi; digits = 2)) mm**"
    Markdown.parse("""
    Over the whole run, pedal travel $travel, which is `i_p · s_dead`, and the largest displaced
    volume is **$(V_max) m³**. Pedal travel that grows with pressure arrives with the calipers
    in increment 1b.
    """)
end


# ╔═╡ c49d6cba-bc1b-4f5e-9b59-544de0820026
md"""
## 6. Experiment: pedal force → line pressure

The analysis `Vehicle.Brake.ForceChainTransient` runs the test harness `TestForceChain`: a
force source ramps the pedal force from 0 to 500 N over 5 s, through pedal, booster and
master cylinder, with both circuits capped. Its only knob is the booster's vacuum-chamber
pressure `p_vac`, passed straight through to `StaticBooster`. The harness itself is in
[`dyad/Vehicle/Brake/TestForceChain.dyad`](../../dyad/Vehicle/Brake/TestForceChain.dyad).
"""


# ╔═╡ 1cd7e7be-acf0-4ca4-83f4-5b1c3c1ee3a0
show_dyad("ForceChainTransient")


# ╔═╡ b20d1be4-7fcc-4094-8593-08261ec0b4a1
md"""
**Vacuum level.** `p_vac` is an *absolute* pressure, so a larger number means *less* vacuum.
33 kPa is the PATH test car at idle. Higher values stand for altitude (the report, citing
MOTOR, gives the available vacuum falling from 74 to 57 kPa at 5500 ft), a weak engine or
wide-open throttle, and 101.325 kPa for no vacuum at all (engine off, or a diesel or EV whose
pump has failed). The dashed red no-vacuum curve stays on the plot for comparison.
"""


# ╔═╡ 08032172-09a3-4400-8b62-4b5e54e96598
md"`p_vac` [kPa] $(@bind p_vac_kPa Slider([33.0:2.0:99.0; 101.325]; default=33.0, show_value=true))"


# ╔═╡ 4506450d-2581-4773-a58e-2a3e31e4d94a
chain = force_chain(p_vac = 1e3 * p_vac_kPa);


# ╔═╡ 5b48160a-35b8-4e1a-b458-6d73fc87f89d
"""
Cut-in, jump-in, boosted slope and run-out knee, read off a simulated curve. The knee is the
last point where the slope is still above halfway between the boosted and the final slope;
`F_knee` is `nothing` when the curve has no boosted section.
"""
function landmarks(chain)
    F, p = chain.F_ped, chain.p_bar
    slope = diff(p) ./ diff(F)
    i_cut = findfirst(>(0), p)
    s_boost = slope[i_cut + 100]
    s_foot = slope[end]
    i_knee = s_boost > 1.5s_foot ?
        findlast(i -> slope[i] > (s_boost + s_foot) / 2, i_cut:length(slope)) + i_cut - 1 :
        nothing
    (; F_cut = F[i_cut], p_jump = p[i_cut], s_boost, s_foot,
        F_knee = isnothing(i_knee) ? nothing : F[i_knee],
        p_knee = isnothing(i_knee) ? nothing : p[i_knee])
end


# ╔═╡ e39614c4-c09b-462f-aa24-f46d85e94886
pressure_plot = let
    L = landmarks(chain)
    r1(x) = round(x; digits = 1)
    fig = plot(no_vacuum.F_ped, no_vacuum.p_bar;
        lw = 3, ls = :dash, color = :firebrick,
        label = "no vacuum ($(r1(no_vacuum.p_vac / 1e3)) kPa)",
        xlabel = "pedal force [N]", ylabel = "master-cylinder pressure [bar]",
        title = "Pedal force → line pressure", legend = :topleft,
        xlims = (0, 500), ylims = (0, 115))
    if chain.p_vac != base.p_vac
        plot!(fig, base.F_ped, base.p_bar; lw = 1.5, color = :gray, alpha = 0.6,
            label = "idle vacuum ($(r1(base.p_vac / 1e3)) kPa)")
    end
    plot!(fig, chain.F_ped, chain.p_bar; lw = 3, color = :steelblue,
        label = "p_vac = $(p_vac_kPa) kPa")
    hline!(fig, [p_1g]; color = :black, ls = :dot, label = "1 g needs $(r1(p_1g)) bar")

    scatter!(fig, [L.F_cut], [L.p_jump]; ms = 6, color = :steelblue, label = "")
    annotate!(fig, L.F_cut + 6, L.p_jump + 2, text(L.p_jump > 0.5 ?
        "cut-in at $(r1(L.F_cut)) N, jump-in to $(r1(L.p_jump)) bar" :
        "no jump-in: pressure starts at $(r1(L.F_cut)) N", 8, :left))
    if !isnothing(L.F_knee)
        scatter!(fig, [L.F_knee], [L.p_knee]; ms = 6, color = :steelblue, label = "")
        annotate!(fig, L.F_knee + 6, L.p_knee - 6,
            text("run-out at $(round(Int, L.F_knee)) N, $(r1(L.p_knee)) bar", 8, :left))
        F_mid = (L.F_cut + L.F_knee) / 2
        L.F_knee - L.F_cut > 100 && annotate!(fig, F_mid - 4, L.p_jump + L.s_boost * (F_mid - L.F_cut) + 4,
            text("boosted: $(round(L.s_boost; digits = 3)) bar/N", 8, :right))
    end
    annotate!(fig, 470, chain.p_bar[end] + 4,
        text("foot only: $(round(L.s_foot; digits = 3)) bar/N", 8, :right))
    fig
end


# ╔═╡ 1f2c3ee9-7dd1-44ed-8dae-919a4cb01b40
md"""
**What the plot claims.** Above a small cut-in force the booster multiplies the foot until its
vacuum is used up; past the run-out knee only the foot adds pressure, at `1/SR` of the
boosted slope. Raising `p_vac` (less vacuum) moves the knee down and to the left, and with no
vacuum the whole boosted section disappears.
"""


# ╔═╡ b235602d-536c-431f-bc5f-5851aabe2599
let
    L = landmarks(base)
    i_p, SR, A_mc = param(:pedal, :i_p), param(:booster, :SR), param(:master, :A_mc)
    r1(x) = round(x; digits = 1)
    plan = [(50, 19.5), (100, 37.3), (170, 62.3), (232, 84.3), (500, 103.4)]
    rows = join(("| $F | $(r1(pressure_at(base, F))) | $p | $(round(100 * (pressure_at(base, F) / p - 1); digits = 2)) % |"
                 for (F, p) in plan), "\n")
    p_nv = pressure_at(no_vacuum, F_FOOT_MAX)
    Markdown.parse("""
    **Idle vacuum ($(r1(base.p_vac / 1e3)) kPa) against the values the brake plan computed by hand
    from the defaults** (`docs/brake-system-implementation-plan.md`, increment 1a):

    | pedal force [N] | simulated `p_mc` [bar] | plan [bar] | difference |
    |---:|---:|---:|---:|
    $rows

    | landmark | simulated | from the parameters |
    |:---|---:|---:|
    | cut-in pedal force | $(round(L.F_cut; digits = 2)) N | `F_cut / i_p` = $(round(param(:booster, :F_cut) / i_p; digits = 2)) N |
    | jump-in pressure | $(r1(L.p_jump)) bar | `(F_jump − F_cs0 − F_cf) / A_mc` = $(r1((param(:booster, :F_jump) - param(:master, :F_cs0) - param(:master, :F_cf)) / A_mc / 1e5)) bar |
    | boosted slope | $(round(L.s_boost; digits = 4)) bar/N | `SR · i_p / A_mc` = $(round(SR * i_p / A_mc / 1e5; digits = 4)) bar/N |
    | run-out knee | $(r1(L.F_knee)) N, $(r1(L.p_knee)) bar | |
    | slope past run-out | $(round(L.s_foot; digits = 4)) bar/N | `i_p / A_mc` = $(round(i_p / A_mc / 1e5; digits = 4)) bar/N |
    | no vacuum, $(round(Int, F_FOOT_MAX)) N | $(r1(p_nv)) bar | |

    Without vacuum, $(round(Int, F_FOOT_MAX)) N of pedal force makes $(r1(p_nv)) bar,
    $(round(p_nv / p_1g; digits = 2)) of the $(r1(p_1g)) bar a 1 g stop needs. Pressure and
    deceleration are proportional through the caliper gain, so that is about
    $(round(p_nv / p_1g; digits = 2)) g: a failed booster costs deceleration, not the brakes.
    """)
end


# ╔═╡ d06214ba-d012-447e-8a12-d15b8f71bb5e
md"""
## 7. Reality check

The brake plan sets real-world bands that every model must land inside
(`docs/brake-system-implementation-plan.md`, *Reality anchors*). A model outside a band is
wrong, or needs a stated reason, even if it simulates cleanly. The model column below is
computed in this notebook; nothing in it is typed in.
"""


# ╔═╡ 8d291c89-79b8-422c-9a56-a83643a854ae
let
    L = landmarks(base)
    F_hard = base.F_ped[findfirst(>=(p_1g), base.p_bar)]
    r1(x) = round(x; digits = 1)
    check(x, lo, hi) = lo <= x <= hi ? "✓ inside" : "✗ **outside**"
    Markdown.parse("""
    | quantity | model | band | | band source | model value from |
    |:---|---:|---:|:---|:---|:---|
    | line pressure for a 1 g stop | $(r1(p_1g)) bar | 60–100 bar | $(check(p_1g, 60, 100)) | derived from cited caliper sizes | `m·g·r / $(K_TORQUE)`: the vehicle and the report's caliper gain, until 1b simulates the calipers |
    | pedal force for a hard stop (≈ 1 g) | $(r1(F_hard)) N | 150–300 N, never > 500 N | $(check(F_hard, 150, 300)) | judgment; 500 N ceiling cited (FMVSS 135) | simulation: first pedal force where `p_mc` reaches $(r1(p_1g)) bar |
    | booster run-out line pressure | $(r1(L.p_knee)) bar | 80–100 bar | $(check(L.p_knee, 80, 100)) | judgment around a PATH-area estimate | simulation: run-out knee at idle vacuum |
    """)
end


# ╔═╡ 97bec3b6-9449-4c18-a251-d45315611876
md"""
### Where the parameters come from

The brake plan sorts every number into three groups (*Where the numbers come from*):
**cited** numbers are evidence from a source the report links; **assumed** numbers are
textbook-typical values with no readable source, and everything computed from them is only as
real as they are; **judgment** numbers, such as the band edges above, have no source and can
be argued with. The table reads each parameter's value from the simulation and its tag from
the docstring in the Dyad source, so it cannot drift from the model.
"""


# ╔═╡ 1500fc04-33b9-4996-8cd0-d8bd91a56112
let
    group = Dict("PATH" => "cited (PATH UCB-ITS-PRR-97-21)",
        "standard atmosphere" => "cited (standard atmosphere)",
        "assumed" => "assumed",
        "derived" => "computed from the parameters above")
    rows = String[]
    for (part, comp) in ((:pedal, "BrakePedal"), (:booster, "StaticBooster"),
            (:master, "TandemMasterCylinder"))
        lines = split(dyad_source(comp)[3], '\n')
        for (i, line) in enumerate(lines)
            m = match(r"^\s*(?:final\s+)?parameter\s+(\w+)", line)
            isnothing(m) && continue
            doc = strip(lines[i - 1], [' ', '"'])
            tag = match(r"\((assumed|PATH|derived|standard atmosphere)", doc)
            value = round(param(part, Symbol(m.captures[1])); sigdigits = 6)
            push!(rows, "| `$comp` | `$(m.captures[1])` | $value | " *
                        "$(isnothing(tag) ? "untagged" : group[tag.captures[1]]) | $doc |")
        end
    end
    Markdown.parse("""
    | component | parameter | value (SI) | group | docstring |
    |:---|:---|---:|:---|:---|
    $(join(rows, "\n"))
    | notebook | caliper gain | $(K_TORQUE) N·m/bar | computed from assumed caliper sizes (report) | 57/38 mm pistons, pad μ 0.40, radii 0.12/0.11 m |
    | notebook | `CAR.m`, `CAR.r` | $(CAR.m) kg, $(CAR.r) m | the L0 vehicle parameter set | `CAR` in `notebooks/lecture01/support.jl` |
    | notebook | pedal-force ceiling | $(round(Int, F_FOOT_MAX)) N | cited (FMVSS 135) | |
    """)
end


# ╔═╡ 0a1e813e-bc5e-44d8-bb70-719af3189ae2
md"""
## 8. What's next

This notebook covers only increment 1a of the brake plan, the static force chain. It shows
pressure, but no fluid moves, nothing reaches a wheel, and the car does not appear. The rest
of Step 1 arrives in two increments, and this notebook grows with them:

- **1b — lines, calipers and torque.** Brake lines with a viscosity parameter, front and rear
  caliper volumes with a stiffening pressure–volume curve, and caliper torque into the
  existing wheel. That brings **fluid volume**, **pedal travel** that grows with pressure
  (pedal feel), **brake torque** and deceleration in a real stop, and the **cold-fluid**
  comparison of DOT 4 against DOT 4 LV at −40 °C.
- **1c — brake-force distribution.** A proportioning valve on the rear circuit and the
  **front/rear distribution** plot of ideal against installed brake share.

None of those are faked here: until the models exist, there is nothing honest to plot.
"""


# ╔═╡ 7d847976-af12-4f45-b97b-98df776e587e
md"""
## What this bought us

The foot alone, even through a 3.5:1 lever, cannot reach the pressure a hard stop needs; the
booster multiplies it again, and the master cylinder turns the result into pressure in two
independent circuits. We can now read every piece of that chain off one simulated curve:
cut-in, jump-in, the boosted slope and the run-out knee, and see the knee move when the vacuum
weakens. The simulated pressures match the brake plan's hand-computed values, and the
pressure and pedal-force anchors sit inside their real-world bands.

What the curve takes for granted is the vacuum itself. The next notebook,
`03-vacuum-booster.pluto.jl`, builds the intake manifold that supplies it and a dynamic
booster that takes time to fill.
"""


# ╔═╡ Cell order:
# ╟─72518851-e9fd-4acc-99f2-ed2a2c3a24a3
# ╠═85847456-fad1-472a-8276-c59e9117c6ac
# ╟─1f49d5df-7a59-4987-93b8-86182a84c4cb
# ╠═9d8a8e2c-3c81-42cc-8dbd-1685ab67c4b7
# ╠═cb6e41f3-6684-4665-b2ee-b75c6b045541
# ╟─1185ffe9-86ab-47ef-a50c-f334b44b2059
# ╟─6f4f30c7-7547-4f15-909e-ee1c2d4f9d65
# ╠═dbf14c8b-682d-4a5b-b734-c1d6c09a9c86
# ╟─a9bd8d98-500f-4e45-9e02-b8fc3e34fed5
# ╠═12ccf85a-84b8-4f10-af68-e90d9dc6ec73
# ╟─5e018b5c-ccf2-4ccd-9a59-b69910235eff
# ╠═f78b2985-e3fc-4823-bc75-9a7528126978
# ╟─a8a76feb-9a34-403e-aa61-794eb05cd81d
# ╟─c49d6cba-bc1b-4f5e-9b59-544de0820026
# ╠═1cd7e7be-acf0-4ca4-83f4-5b1c3c1ee3a0
# ╟─b20d1be4-7fcc-4094-8593-08261ec0b4a1
# ╟─08032172-09a3-4400-8b62-4b5e54e96598
# ╠═4506450d-2581-4773-a58e-2a3e31e4d94a
# ╠═5b48160a-35b8-4e1a-b458-6d73fc87f89d
# ╠═e39614c4-c09b-462f-aa24-f46d85e94886
# ╟─1f2c3ee9-7dd1-44ed-8dae-919a4cb01b40
# ╟─b235602d-536c-431f-bc5f-5851aabe2599
# ╟─d06214ba-d012-447e-8a12-d15b8f71bb5e
# ╟─8d291c89-79b8-422c-9a56-a83643a854ae
# ╟─97bec3b6-9449-4c18-a251-d45315611876
# ╟─1500fc04-33b9-4996-8cd0-d8bd91a56112
# ╟─0a1e813e-bc5e-44d8-bb70-719af3189ae2
# ╟─7d847976-af12-4f45-b97b-98df776e587e
