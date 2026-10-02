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

# ╔═╡ 155c6716-b6be-446a-9540-7c88b84e13ed
md"""
# Lecture 2 · 04 — How much fuel

> **The ECU's pulse-width formula is feed-forward: it inverts the plant so that λ stays at 1
> before any sensor sees an error.**

Notebook 03's dynamometer cheated: it metered fuel from the true air flow into the cylinders. An
ECU has no such signal. It has sensors (an air-mass meter, a manifold pressure sensor, the
crankshaft speed, the coolant temperature, the battery voltage) and it must turn their readings
into an injector opening time, every cycle, before the air it is fueling reaches the cylinder.

Slide 44 says how: *"The engine control unit uses a formula and a large number of lookup tables
to determine the pulse width for given operating conditions. The equation will be a series of
many factors multiplied by each other"*, and a production calibration *"may have more than 100
parameters, each with its own lookup table"*. This notebook builds that formula with the handful
of factors that matter most, and then finds the one piece of plant it has to invert as well: the
film of fuel on the intake port wall.

**Model.** `Lecture2.TipInTestTransient` holds notebook 03's engine at a fixed speed, now fueled
by `Vehicle.ECU.FuelMetering` instead of the dyno's ideal metering, with the wall film
(`Vehicle.Engine.WallWetting`) between the injector and the cylinder.
"""

# ╔═╡ 7d05873f-0b3d-4515-9525-709c3634a134
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
    TipInTestTransient = bind_analysis(:TipInTestTransient, library; stubs)
    show_dyad = isnothing(stubs) ? Lecture01Support.show_dyad : stubs.show_dyad
end

# ╔═╡ 88d04085-0de4-4de6-a096-7cf99e7dc116
md"""
## 1 · The formula

Slide 44 writes it as *pulse width = (base pulse width) × (factor A) × (factor B) × …*. Written
out with the factors this model carries:

```math
\lambda_\text{tgt} = \frac{\text{AFR}_\text{map}(N,\ p_m/p_a)}{\text{AFR}_s},
\qquad
\dot m_{f,\text{des}} = \frac{\dot m_\text{air}}{\text{AFR}_s\,\lambda_\text{tgt}}
\cdot F_\text{cool}(T_\text{cool}) \cdot \lambda_\text{trim}
```

```math
t_\text{inj} = \frac{4\pi}{\omega\,n_\text{cyl}}\,\frac{\dot m_{f,\text{cmd}}}{q_\text{inj}}
+ t_\text{dead}(U_\text{batt})
```

| Factor | What it does | Source |
|---|---|---|
| `ṁ_air / AFR_s` | the base: fuel for a stoichiometric charge | sensors; `AFR_s = 14.7` (deck) |
| `1/λ_tgt` | the target mixture from the speed × load map | slide 44, transcribed |
| `F_cool` | warm-up enrichment, 1.3 at 20 °C falling to 1.0 at 80 °C | *(assumed)* |
| `λ_trim` | the λ controller's correction (notebook 06); 1 here | – |
| `4π/(ω n_cyl)` | turns a flow into a mass per injection: one injection per cylinder every two revolutions | – |
| `q_inj` | the injector's static flow, 146 cm³/min at 3 bar | Bosch EV14 datasheet |
| `t_dead` | the time the injector needs to open, added on top | EV14 table, retailer data, *not verified at Bosch* |

Load is the manifold pressure as a fraction of ambient. `ṁ_air` is the air flow into the
cylinders; a production ECU estimates it from its air-mass and manifold-pressure sensors, and
this model hands it the cylinder air flow directly so that the film, not the sensor, is what
this notebook studies.
"""

# ╔═╡ 18e73f8f-ddf9-43df-8b7f-9f142e484935
show_dyad("FuelMetering")

# ╔═╡ b7e4c116-9161-4af4-a73b-0937df41f4a1
md"""
## 2 · The target: slide 44's map

At part load the map asks for 14.7, stoichiometric, which is where the catalyst works
(notebook 06). It turns rich in two places:

- **Full load, at every speed** (the 90 % and 100 % columns). Slightly rich mixture gives the
  most torque (slide 23: *"To increase power we need to make FA mixture rich"*), and the extra
  fuel evaporating in the cylinder cools the charge.
- **High speed, at every load** (the bottom rows). Here the extra fuel is component protection:
  it lowers the exhaust temperature that the exhaust valves and the catalyst have to survive.

Both cost fuel and both put the catalyst out of its window, which is why they are confined to
corners of the map a driver rarely visits.
"""

# ╔═╡ 604d25ee-7602-4a54-9c11-ea587524abdc
let
    afr = afr_map_slide44()
    p = heatmap(afr.load, afr.rpm, afr.afr; color = cgrad(:RdYlGn), clims = (10.5, 14.7),
        xlabel = "engine load [%]", ylabel = "engine speed [rpm]", colorbar_title = "AFR",
        yflip = true, xticks = afr.load, yticks = afr.rpm, size = (620, 460),
        title = "Slide 44's AFR map, transcribed")
    for (i, n) in enumerate(afr.rpm), (j, l) in enumerate(afr.load)
        annotate!(p, l, n, text(string(afr.afr[i, j]), 7))
    end
    compare(
        deck_figure("slide44-afr-map.png"; width = 420),
        captioned(p, """
            The slide's table and its transcription in `data/engine/afr_map_slide44.csv`, which
            `FuelMetering` reads. This figure is data, not a model result.
            """))
end

# ╔═╡ 859aabc6-a7e2-41e9-b860-8838ef023c05
md"""
## 3 · From mass to milliseconds

The fuel per injection is the commanded flow over one cycle of one cylinder,
`ṁ_f · 4π/(ω n_cyl)`. Dividing by the injector's static flow turns it into the time the needle
must stay open. On top comes the dead time: the injector opens late, so the ECU opens it early.
The dead time depends on the battery voltage, because the coil current rises more slowly from a
weak battery (notebook 05 rebuilds this from the injector's physics). The EV14 table the model
reads is retailer data, and is marked so.

The map below comes from steady runs over speed and throttle, warm, at 14 V.
"""

# ╔═╡ b9a35f18-9dd5-4ca0-9bb3-111f6c78b131
begin
    MAP_RPM = [800, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000]
    MAP_THROTTLE = [0.0, 0.02, 0.05, 0.1, 0.15, 0.2, 0.3, 0.5, 1.0]
    steady = (t_tip_in = 1e3, t_tip_out = 2e3, stop = 0.5)
    fuel_map = operating_grid(TipInTestTransient, [T_INJ, LAMBDA_TGT, P_M];
        speeds = MAP_RPM, throttles = MAP_THROTTLE, T_cool = 90.0, U_batt = 14.0, steady...)
    map_load = 100 .* fuel_map.values[P_M] ./ ENGINE.p_a
    LOAD_GRID = collect(10.0:5.0:100.0)
    BATTERY = [8.0, 10.0, 12.0, 14.0, 16.0]
    battery_runs = [TipInTestTransient(; omega_set = rad_per_s(800), u_thr = 0.0, U_batt = U, steady...)
        for U in BATTERY]
    EV14_DEAD_TIME = (U = [8.0, 12.0, 14.0, 16.0], t = [2.000, 0.903, 0.800, 0.558])
end

# ╔═╡ 1e3ee7d6-23eb-49f0-a92a-f79f29d96430
let
    t_inj = regrid(map_load, 1000 .* fuel_map.values[T_INJ], LOAD_GRID)
    p1 = heatmap(LOAD_GRID, MAP_RPM, t_inj; yflip = true, color = :viridis,
        xlabel = "engine load [%]", ylabel = "engine speed [rpm]", colorbar_title = "ms",
        title = figure_title(fuel_map.runs, "Injection pulse width, warm, 14 V"))
    t_idle = [1000 * last(last(signal(r, T_INJ))) for r in battery_runs]
    p2 = plot(BATTERY, t_idle; lw = 3, marker = :circle, color = :steelblue,
        label = "pulse width at idle (model)", xlabel = "battery voltage [V]", ylabel = "time [ms]",
        legend = :topright, title = figure_title(battery_runs, "The dead time rides on top"))
    scatter!(p2, EV14_DEAD_TIME.U, EV14_DEAD_TIME.t; marker = :diamond, ms = 7, color = :darkorange,
        label = "EV14 dead time (retailer table)")
    captioned(plot(p1, p2; layout = (2, 1), size = (620, 640)), """
        Top: pulse width across the map in the slide 44 layout. Bottom: at idle the fuel part of
        the pulse is short, so the dead time is a large share of it; the EV14 table adds 1.2 ms
        between 14 V and 8 V.
        """ * placeholder_note((fuel_map.runs, battery_runs),
            "`TipInTestTransient` over speed, throttle and `U_batt`, signals `$T_INJ` and `$P_M`"))
end

# ╔═╡ f5347915-885e-4c58-82ad-0f0906922dd3
check("`TipInTestTransient` over speed and throttle, signals `$LAMBDA_TGT` and `$P_M`", fuel_map.runs) do
    afr = afr_map_slide44()
    worst = maximum(abs(ENGINE.AFR_s * λ - bilinear(afr.rpm, afr.load, afr.afr, n, l))
        for (λ, n, l) in zip(fuel_map.values[LAMBDA_TGT], repeat(MAP_RPM, 1, length(MAP_THROTTLE)), map_load))
    (worst <= 0.05,
        "the metering's target reproduces the transcribed map within $(round(worst; digits = 3)) " *
        "AFR at every run; band 0.05 AFR")
end

# ╔═╡ 68c5c61c-603d-4879-a828-e0049dff4526
md"""
## 4 · The fuel film

In a port-injected engine the injector sprays at the back of the intake valve, and not all of
the fuel arrives as vapor. A fraction `X` lands on the port wall and forms a film, which
evaporates into the passing air with a time constant `τ_f`. The classic x–τ model (Aquino):

```math
\dot m_\text{film} = X\,\dot m_\text{inj} - \frac{m_\text{film}}{\tau_f},
\qquad
\dot m_{f,\text{cyl}} = (1-X)\,\dot m_\text{inj} + \frac{m_\text{film}}{\tau_f}
```

In steady state the film gives back exactly what it takes, and the cylinder gets all the fuel.
Only when the injected flow changes does it matter: the film absorbs part of an increase and
releases it later. A cold port wall holds more fuel for longer: `X` falls from 0.5 cold to 0.3
warm, and `τ_f` from 0.6 s to 0.2 s, between 20 and 90 °C *(assumed)*.
"""

# ╔═╡ 9dc364a6-75b5-44f6-aac8-551df91c57bb
show_dyad("WallWetting")

# ╔═╡ 0f7e0fa7-bf5c-41ac-98f4-e0704b969e25
md"""
## 5 · Tip-in without compensation

The experiment: hold the engine at 2000 rpm with the throttle at 10 %, open it to 40 % at
`t = 1 s` (a tip-in), and close it back at `t = 3 s` (a tip-out). The error is measured against
the λ the metering intends, its map target divided by the warm-up enrichment, so that a planned
enrichment does not count as an error:

```math
e(t) = \frac{\lambda_\text{cyl}(t)}{\lambda_\text{cmd}(t)} - 1
```

positive when the cylinder runs leaner than intended. Without compensation the formula meters
the right fuel, the film steals part of the increase, and the cylinder runs lean. At tip-out the
film gives the fuel back, and it runs rich.
"""

# ╔═╡ 89749897-ab52-48d7-8ff3-a63321994e9d
md"estimate error in `X̂` [%] $(@bind xh_error Slider(-50:10:50; default = 0, show_value = true))"

# ╔═╡ 3ca1716c-f079-4bed-b720-c3205e5d31ec
begin
    TIP = (omega_set = rad_per_s(2000), u_thr = 0.1, u_tip = 0.4, t_tip_in = 1.0, t_tip_out = 3.0, stop = 5.0)
    WARM, COLD = 90.0, 20.0
    # The warm film's own parameters, from the WallWetting defaults (assumed).
    FILM_WARM = (X = 0.3, tau = 0.2)
    tip(; kwargs...) = TipInTestTransient(; TIP..., kwargs...)
    warm_open = tip(T_cool = WARM)
    cold_open = tip(T_cool = COLD)
    warm_exact = tip(T_cool = WARM, with_comp = true, Xh = FILM_WARM.X, tauh = FILM_WARM.tau)
    warm_off30 = tip(T_cool = WARM, with_comp = true, Xh = 0.7FILM_WARM.X, tauh = 0.7FILM_WARM.tau)
    warm_live = tip(T_cool = WARM, with_comp = true, Xh = (1 + xh_error / 100) * FILM_WARM.X,
        tauh = FILM_WARM.tau)
    "Relative λ error against the metering's intent."
    function lambda_error(r)
        t, λ = signal(r, LAMBDA_CYL)
        _, λc = signal(r, LAMBDA_CMD)
        return (t, λ ./ λc .- 1)
    end
    function lean_excursion(r)
        t, e = lambda_error(r)
        return maximum(e[TIP.t_tip_in .<= t .< TIP.t_tip_out])
    end
    worst_error(r) = maximum(abs, last(lambda_error(r)))
end

# ╔═╡ 30f49316-adc3-4798-80c0-b485d1798a7e
let
    t, u = signal(warm_open, U_THR)
    _, p_m = signal(warm_open, P_M)
    _, λ = signal(warm_open, LAMBDA_CYL)
    _, λc = signal(warm_open, LAMBDA_CMD)
    p1 = plot(t, 100 .* u; lw = 2.5, color = :black, label = "throttle [%]", ylabel = "",
        legend = :right, title = figure_title(warm_open, "Tip-in and tip-out, warm, no compensation"))
    plot!(p1, t, kpa.(p_m); lw = 2.5, color = :gray, label = "p_m [kPa]")
    p2 = plot(t, λ; lw = 3, color = :steelblue, label = "λ in the cylinder", ylabel = "λ",
        xlabel = "time [s]", legend = :topright)
    plot!(p2, t, λc; lw = 2, ls = :dash, color = :black, label = "λ the metering intends")
    captioned(plot(p1, p2; layout = (2, 1), size = (620, 460), link = :x), """
        The map target itself moves at the tip-in, because 40 % throttle at 2000 rpm is high load
        and the map asks for a rich mixture there.
        """ * placeholder_note(warm_open,
            "`TipInTestTransient`, signals `$U_THR`, `$P_M`, `$LAMBDA_CYL`, `$LAMBDA_CMD`"))
end

# ╔═╡ cc2d7860-d429-4f8d-98ad-ed3dd1016711
check("`TipInTestTransient` warm, without compensation, signals `$LAMBDA_CYL` and `$LAMBDA_CMD`", warm_open) do
    e = lean_excursion(warm_open)
    (e >= 0.05, "lean excursion at tip-in $(round(100e; digits = 1)) %; expected at least 5 %")
end

# ╔═╡ 1fe46b56-5771-4580-a565-91be0f7058ff
md"""
## 6 · Inverting the film

The fix is to invert the film: run a copy of the x–τ model inside the ECU, with estimates `X̂`
and `τ̂`, and inject what the film will take on top of what the cylinder needs:

```math
\dot m_{f,\text{cmd}} = \frac{\dot m_{f,\text{des}} - \hat m_\text{film}/\hat\tau}{1 - \hat X},
\qquad
\dot{\hat m}_\text{film} = \hat X\,\dot m_{f,\text{cmd}} - \frac{\hat m_\text{film}}{\hat\tau}
```

With exact estimates the two films cancel and the cylinder receives exactly the desired fuel.
With wrong estimates part of the excursion survives. The slider sets the error in `X̂`; the
dashed curve keeps both estimates 30 % low. Finding `X` and `τ_f` across temperature and load,
on a real engine, is a large part of a calibration engineer's work.
"""

# ╔═╡ 40f06c8d-8fb4-4f0b-ae7a-c9ceac130159
let
    p = plot(; xlabel = "time [s]", ylabel = "λ error e [%]", legend = :topright,
        title = figure_title((warm_open, warm_exact, warm_off30, warm_live),
            "λ error at tip-in and tip-out, warm"))
    for (r, label, style) in ((warm_open, "no compensation", (color = :firebrick, lw = 2.5)),
            (warm_off30, "estimates 30 % low", (color = :darkorange, lw = 2.5, ls = :dash)),
            (warm_live, "X̂ error $(xh_error) % (slider)", (color = :purple, lw = 2)),
            (warm_exact, "exact estimates", (color = :seagreen, lw = 3)))
        t, e = lambda_error(r)
        plot!(p, t, 100 .* e; label, style...)
    end
    hspan!(p, [-1, 1]; color = :seagreen, alpha = 0.12, label = "±1 %")
    captioned(p, "" * placeholder_note((warm_open, warm_exact, warm_off30, warm_live),
        "`TipInTestTransient` with `with_comp`, `Xh`, `tauh`, signals `$LAMBDA_CYL` and `$LAMBDA_CMD`"))
end

# ╔═╡ 8c9c0dfb-575c-479b-933e-28637cc78087
check("`TipInTestTransient` warm, with compensation, signals `$LAMBDA_CYL` and `$LAMBDA_CMD`",
      warm_exact, warm_off30, warm_open) do
    exact, off30, open = worst_error(warm_exact), worst_error(warm_off30), worst_error(warm_open)
    (exact < 0.01 && exact < off30 < open,
        "worst λ error $(round(100exact; digits = 2)) % with exact estimates (below 1 %), " *
        "$(round(100off30; digits = 1)) % with estimates 30 % low, " *
        "$(round(100open; digits = 1)) % uncompensated (must lie between)")
end

# ╔═╡ e8b07dda-e228-49f5-86bc-492997169288
md"""
## 7 · Cold engine

Slide 28's warm-up strategy asks the ECU to *"keep the engine operating smoothly (i.e. no stalls
or driveability problems)"* while the engine is cold. A cold port wall holds more of the fuel,
for longer, so the same tip-in starves a cold engine of more fuel than a warm one, and the
excursion is larger. Warm-up enrichment (`F_cool`) shifts the whole mixture rich to keep a cold
engine from stumbling, but does nothing for the transient: only the film compensation does.
"""

# ╔═╡ 48f37ad2-18af-452c-b798-2e47333f6764
let
    p = plot(; xlabel = "time [s]", ylabel = "λ error e [%]", legend = :topright,
        title = figure_title((warm_open, cold_open), "Tip-in without compensation, cold and warm"))
    for (r, label, color) in ((cold_open, "cold, 20 °C", :steelblue), (warm_open, "warm, 90 °C", :firebrick))
        t, e = lambda_error(r)
        plot!(p, t, 100 .* e; lw = 2.5, label, color)
    end
    captioned(p, "" * placeholder_note((warm_open, cold_open),
        "`TipInTestTransient` with `T_cool`, signals `$LAMBDA_CYL` and `$LAMBDA_CMD`"))
end

# ╔═╡ d938698a-2d12-4f5f-8d54-1adbb5c21bb8
check("`TipInTestTransient` cold and warm, without compensation, signals `$LAMBDA_CYL` and `$LAMBDA_CMD`",
      cold_open, warm_open) do
    cold, warm = lean_excursion(cold_open), lean_excursion(warm_open)
    (cold > warm, "lean excursion cold $(round(100cold; digits = 1)) %, warm " *
        "$(round(100warm; digits = 1)) %; cold must be larger")
end

# ╔═╡ b750db65-c6d4-4120-980b-56ee86022769
md"""
### Acceleration enrichment, deceleration enleanment

Slide 28 lists *"Acceleration Enrichment (fuel mixture richness is required)"* and
*"Deceleration Enleanment (inverse than in acceleration)"* among the control strategies. They
are this compensation by another name. On a tip-in the inverse film injects extra fuel, and the
ECU's injected mixture is richer than the cylinder's; on a tip-out it injects less. The names
describe what the injector does. The purpose is that the cylinder sees neither.
"""

# ╔═╡ bd4b4fe5-2a81-4cae-bfbe-9b36f3388a2a
md"""
## Honest numbers

**From a source.** The target map (deck slide 44, transcribed cell by cell); the stoichiometric
ratio 14.7 (deck); the injector's static flow (Bosch EV14 datasheet).

**Not verified.** The dead-time table is a retailer's copy of EV14 data that is not in Bosch's
own datasheet.

**Assumed.** The film parameters `X` and `τ_f` and their temperature dependence; the warm-up
enrichment curve; the tip-in scenario. Each fixes the size of an excursion; none changes its
shape or the direction it goes.

The 5 % and 1 % bands in the check cells are the task's acceptance criteria, not measurements of
a real engine.
"""

# ╔═╡ 9f1bc987-1e1e-4309-8bdf-3e17e5cbe2ae
md"""
## What this bought us

- The pulse width is a product of lookup tables (slide 44), and the base of the product is an
  inversion of the plant: air in, fuel out, at the λ the map asks for.
- The map is stoichiometric where the catalyst needs it and rich only at full load and high
  speed, for power and for component protection.
- The fuel film is plant dynamics the feed-forward must invert as well. Done exactly, it removes
  the tip-in excursion; done approximately, it removes part of it. What it cannot remove is left
  to a feedback loop.
- The dead time is a property of the injector, not of the fuel: it depends on the battery.

**Next: 05 — Inside an injector.** The formula's last term, `t_dead(U_batt)`, came from a table.
The next notebook opens the injector and finds where that table comes from.
"""

# ╔═╡ 22833249-3c73-430a-b19d-661799ddcefe
details("Model contract: what this notebook needs from the Dyad side", md"""
Everything below is requested from Dyad task 3 (`docs/lecture-02-dyad-tasks.md`). Names in
**bold** are not in that spec yet.

### `Lecture2.TipInTestTransient` (harness `Lecture2.TipInTest`)

| Knob | Unit | Default | Values used here | Slider |
|---|---|---|---|---|
| **`omega_set`** | rad/s | 209.4 (2000 rpm) | 800–6000 rpm | – |
| **`u_thr`** (before the tip-in) | – | 0.1 | 0–1 | – |
| **`u_tip`** (after the tip-in) | – | 0.4 | 0.4 | – |
| **`t_tip_in`**, **`t_tip_out`** | s | 1.0, 3.0 | 1, 3; 1000 and 2000 for steady runs | – |
| `T_cool` | °C | 90 | 20, 90 | – |
| `with_comp` (structural) | Bool | false | false, true | – |
| `Xh` | – | 0.3 | 0.3, 0.21, 0.3 × (1 + error) | error −50:10:50 % |
| `tauh` | s | 0.2 | 0.2, 0.14 | – |
| **`U_batt`** | V | 14 | 8–16 | – |
| `stop` | s | 5.0 | 5.0; 0.5 for steady runs | – |

| Signal read | Path | Unit |
|---|---|---|
| λ in the cylinder | `engine.lambda_cyl` | – |
| λ the metering intends (target ÷ enrichment ÷ trim) | **`metering.lambda_cmd`** | – |
| map target | **`metering.lambda_tgt`** | – |
| pulse width | `metering.t_inj` | s |
| manifold pressure | `engine.p_m` | Pa |
| throttle command | **`throttle.y`** | – |

### Checks

| Check | Runs | Signals | Expected |
|---|---|---|---|
| map reproduction | 11 speeds × 9 throttles, warm, 14 V, steady | `metering.lambda_tgt`, `engine.p_m` | within 0.05 AFR of the transcribed map at the run's speed and load |
| uncompensated tip-in | 2000 rpm, 10 → 40 %, warm | `engine.lambda_cyl`, `metering.lambda_cmd` | lean excursion ≥ 5 % |
| compensated tip-in | same, `with_comp`, exact and 30 % low estimates | same | exact: worst error < 1 %; 30 % low lies between exact and uncompensated |
| cold vs warm | same, uncompensated, 20 and 90 °C | same | cold excursion larger |
""")

# ╔═╡ Cell order:
# ╟─155c6716-b6be-446a-9540-7c88b84e13ed
# ╠═7d05873f-0b3d-4515-9525-709c3634a134
# ╟─88d04085-0de4-4de6-a096-7cf99e7dc116
# ╠═18e73f8f-ddf9-43df-8b7f-9f142e484935
# ╟─b7e4c116-9161-4af4-a73b-0937df41f4a1
# ╠═604d25ee-7602-4a54-9c11-ea587524abdc
# ╟─859aabc6-a7e2-41e9-b860-8838ef023c05
# ╠═b9a35f18-9dd5-4ca0-9bb3-111f6c78b131
# ╠═1e3ee7d6-23eb-49f0-a92a-f79f29d96430
# ╠═f5347915-885e-4c58-82ad-0f0906922dd3
# ╟─68c5c61c-603d-4879-a828-e0049dff4526
# ╠═9dc364a6-75b5-44f6-aac8-551df91c57bb
# ╟─0f7e0fa7-bf5c-41ac-98f4-e0704b969e25
# ╠═89749897-ab52-48d7-8ff3-a63321994e9d
# ╠═3ca1716c-f079-4bed-b720-c3205e5d31ec
# ╠═30f49316-adc3-4798-80c0-b485d1798a7e
# ╠═cc2d7860-d429-4f8d-98ad-ed3dd1016711
# ╟─1fe46b56-5771-4580-a565-91be0f7058ff
# ╠═40f06c8d-8fb4-4f0b-ae7a-c9ceac130159
# ╠═8c9c0dfb-575c-479b-933e-28637cc78087
# ╟─e8b07dda-e228-49f5-86bc-492997169288
# ╠═48f37ad2-18af-452c-b798-2e47333f6764
# ╠═d938698a-2d12-4f5f-8d54-1adbb5c21bb8
# ╟─b750db65-c6d4-4120-980b-56ee86022769
# ╟─bd4b4fe5-2a81-4cae-bfbe-9b36f3388a2a
# ╟─9f1bc987-1e1e-4309-8bdf-3e17e5cbe2ae
# ╟─22833249-3c73-430a-b19d-661799ddcefe
