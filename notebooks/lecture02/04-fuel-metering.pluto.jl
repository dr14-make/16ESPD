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

# ╔═╡ 7d05873f-0b3d-4515-9525-709c3634a134
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

# ╔═╡ 155c6716-b6be-446a-9540-7c88b84e13ed
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
| `ṁ_air / AFR_s` | the base: fuel for a stoichiometric charge | air-mass sensor, optionally through a manifold model (section 6); `AFR_s = 14.7` (deck) |
| `1/λ_tgt` | the target mixture from the speed × load map | slide 44, transcribed |
| `F_cool` | warm-up enrichment, 1.3 at 20 °C falling to 1.0 at 80 °C | *(assumed)* |
| `λ_trim` | the λ controller's correction (notebook 06); 1 here | – |
| `4π/(ω n_cyl)` | turns a flow into a mass per injection: one injection per cylinder every two revolutions | – |
| `q_inj` | the injector's static flow, 146 cm³/min at 3 bar | Bosch EV14 datasheet |
| `t_dead` | the time the injector needs to open, added on top | EV14 table, retailer data, *not verified at Bosch* |

Load is the manifold pressure as a fraction of ambient. `ṁ_air` is what the hot-film air-mass
sensor reports (slide 37): the air flowing through the throttle. In steady running that equals
the air entering the cylinders. During a transient it does not, as notebook 03 showed, and that
difference will matter in section 5.
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

Take the numbers as an illustration. The table comes from the tuning video linked on the slide,
not from a manufacturer's calibration, and production engines built for current emission limits
enrich far less, staying close to λ = 1 over most of the full-load line.
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

The experiment: hold the engine at 2000 rpm with the throttle at 5 %, open it to 15 % at
`t = 1 s` (a tip-in), and close it back at `t = 3 s` (a tip-out). That takes the load from
about a third to about three quarters, inside the part of the map where the target stays at
14.7, so the target does not move and only the error does. The error is measured against the
run's own steady λ just before the tip-in, so that a cold engine's planned enrichment does not
count as an error:

```math
e(t) = \frac{\lambda_\text{cyl}(t)}{\lambda_\text{cyl}(t_\text{tip}^-)} - 1
```

positive when the cylinder runs leaner than before. Two effects act at once, in opposite
directions:

- **The sensor reads the air too early.** The throttle air flow jumps the moment the plate
  opens, but the cylinders receive the extra air only as the manifold fills (notebook 03). For
  that moment the formula meters fuel for air that has not arrived yet: **rich**.
- **The film steals fuel.** Part of the extra fuel lands on the port wall instead of entering
  the cylinder: **lean**.

Which wins depends on the manifold's time constant against the film's. At tip-out both effects
reverse.
"""

# ╔═╡ 89749897-ab52-48d7-8ff3-a63321994e9d
md"estimate error in `X̂` [%] $(@bind xh_error Slider(-50:10:50; default = 0, show_value = true))"

# ╔═╡ 3ca1716c-f079-4bed-b720-c3205e5d31ec
md"estimate error in `τ̂` [%] $(@bind tauh_error Slider(-50:10:50; default = 0, show_value = true))"

# ╔═╡ 30f49316-adc3-4798-80c0-b485d1798a7e
begin
    TIP = (omega_set = rad_per_s(2000), u_thr = 0.05, u_tip = 0.15, t_tip_in = 1.0, t_tip_out = 3.0, stop = 5.0)
    WARM, COLD = 90.0, 20.0
    # The warm film's own parameters, from the WallWetting defaults (assumed).
    FILM_WARM = (X = 0.3, tau = 0.2)
    tip(; kwargs...) = TipInTestTransient(; TIP..., kwargs...)
    warm_open = tip(T_cool = WARM)
    cold_open = tip(T_cool = COLD)
    warm_film = tip(T_cool = WARM, with_comp = true, Xh = FILM_WARM.X, tauh = FILM_WARM.tau)
    warm_both = tip(T_cool = WARM, with_air_model = true, with_comp = true, Xh = FILM_WARM.X,
        tauh = FILM_WARM.tau)
    warm_off30 = tip(T_cool = WARM, with_air_model = true, with_comp = true, Xh = 0.7FILM_WARM.X,
        tauh = 0.7FILM_WARM.tau)
    warm_live = tip(T_cool = WARM, with_air_model = true, with_comp = true,
        Xh = (1 + xh_error / 100) * FILM_WARM.X, tauh = (1 + tauh_error / 100) * FILM_WARM.tau)
    "λ error relative to the run's own steady λ just before the tip-in."
    function lambda_error(r)
        t, λ = signal(r, LAMBDA_CYL)
        λ0 = λ[searchsortedlast(t, TIP.t_tip_in) - 1]
        return (t, λ ./ λ0 .- 1)
    end
    worst_error(r) = maximum(abs, last(lambda_error(r)))
end

# ╔═╡ cc2d7860-d429-4f8d-98ad-ed3dd1016711
let
    t, u = signal(warm_open, U_THR)
    _, p_m = signal(warm_open, P_M)
    _, m_thr = signal(warm_open, MDOT_THR)
    _, m_cyl = signal(warm_open, MDOT_CYL)
    _, λ = signal(warm_open, LAMBDA_CYL)
    p1 = plot(t, 100 .* u; lw = 2.5, color = :black, label = "throttle [%]", ylabel = "",
        legend = :right, title = figure_title(warm_open, "Tip-in and tip-out, warm, no compensation"))
    plot!(p1, t, kpa.(p_m); lw = 2.5, color = :gray, label = "p_m [kPa]")
    p2 = plot(t, 1000 .* m_thr; lw = 2.5, color = :darkorange, label = "air-mass sensor",
        ylabel = "air [g/s]", legend = :right)
    plot!(p2, t, 1000 .* m_cyl; lw = 2.5, color = :steelblue, label = "into the cylinders")
    p3 = plot(t, λ; lw = 3, color = :steelblue, label = "λ in the cylinder", ylabel = "λ",
        xlabel = "time [s]", legend = :topright)
    captioned(plot(p1, p2, p3; layout = (3, 1), size = (620, 620), link = :x), """
        The sensor's air flow leads the cylinders' air at every throttle change; the film then
        delays the fuel. λ shows the sum of the two.
        """ * placeholder_note(warm_open,
            "`TipInTestTransient`, signals `$U_THR`, `$P_M`, `$MDOT_THR`, `$MDOT_CYL`, `$LAMBDA_CYL`"))
end

# ╔═╡ 1fe46b56-5771-4580-a565-91be0f7058ff
check("`TipInTestTransient` warm, without compensation, signal `$LAMBDA_CYL`", warm_open) do
    e = worst_error(warm_open)
    (e >= 0.05, "worst λ error over tip-in and tip-out $(round(100e; digits = 1)) %, either " *
        "direction; expected at least 5 %")
end

# ╔═╡ 40f06c8d-8fb4-4f0b-ae7a-c9ceac130159
md"""
## 6 · Inverting the plant, twice

Feed-forward has to invert every piece of plant between its sensor and the cylinder, and here
there are two.

**The film.** Run a copy of the x–τ model inside the ECU, with estimates `X̂` and `τ̂`, and inject
what the film will take on top of what the cylinder needs:

```math
\dot m_{f,\text{cmd}} = \frac{\dot m_{f,\text{des}} - \hat m_\text{film}/\hat\tau}{1 - \hat X},
\qquad
\dot{\hat m}_\text{film} = \hat X\,\dot m_{f,\text{cmd}} - \frac{\hat m_\text{film}}{\hat\tau}
```

**The manifold.** Run a copy of notebook 03's manifold equation, driven by the sensor reading, to
estimate the air that actually reaches the cylinders, and meter fuel for that instead:

```math
\dot{\hat p}_m = \frac{R\,T_m}{V_m}\left(\dot m_\text{air,meas} - \hat{\dot m}_\text{cyl}\right),
\qquad
\hat{\dot m}_\text{cyl} = \eta_v\,V_d\,\frac{\omega}{4\pi}\,\frac{\hat p_m}{R\,T_m}
```

Production ECUs carry both, under names like *air-charge model* and *wall-film compensation*.

The plot below adds them one at a time. With the film compensation alone, the tip-in gets
**worse**: uncompensated, the sensor's rich error and the film's lean error partly cancelled, and
removing only the lean one leaves the rich one standing. With both inversions the cylinder gets
the fuel it needs. With wrong film estimates part of the error comes back, and the two estimates
fail differently: a wrong `X̂` changes the size of the leftover spike, a wrong `τ̂` its shape and
how long it lasts. The sliders set each error, with both inversions on; the dashed curve keeps
both estimates 30 % low. Finding `X` and `τ_f` across temperature and load, on a real engine, is
a large part of a calibration engineer's work.
"""

# ╔═╡ 8c9c0dfb-575c-479b-933e-28637cc78087
let
    p = plot(; xlabel = "time [s]", ylabel = "λ error e [%]", legend = :topright,
        title = figure_title((warm_open, warm_film, warm_both, warm_off30, warm_live),
            "λ error at tip-in and tip-out, warm"))
    for (r, label, style) in ((warm_open, "no compensation", (color = :firebrick, lw = 2.5)),
            (warm_film, "film only", (color = :black, lw = 2, ls = :dot)),
            (warm_off30, "both, film estimates 30 % low", (color = :darkorange, lw = 2.5, ls = :dash)),
            (warm_live, "both, X̂ $(xh_error) %, τ̂ $(tauh_error) % (sliders)", (color = :purple, lw = 2)),
            (warm_both, "both, exact", (color = :seagreen, lw = 3)))
        t, e = lambda_error(r)
        plot!(p, t, 100 .* e; label, style...)
    end
    hspan!(p, [-1, 1]; color = :seagreen, alpha = 0.12, label = "±1 %")
    captioned(p, "\"Both\" is the manifold model and the film compensation together." *
        placeholder_note((warm_open, warm_film, warm_both, warm_off30, warm_live),
        "`TipInTestTransient` with `with_air_model`, `with_comp`, `Xh`, `tauh`, signal `$LAMBDA_CYL`"))
end

# ╔═╡ e8b07dda-e228-49f5-86bc-492997169288
check("`TipInTestTransient` warm, film only and both inversions, signal `$LAMBDA_CYL`",
      warm_both, warm_film) do
    both, film = worst_error(warm_both), worst_error(warm_film)
    (both < 0.01 && both < film,
        "worst λ error $(round(100both; digits = 2)) % with both inversions exact (below 1 %), " *
        "$(round(100film; digits = 1)) % with the film compensation alone (must be larger)")
end

# ╔═╡ 48f37ad2-18af-452c-b798-2e47333f6764
md"""
## 7 · Cold engine

Slide 28's warm-up strategy asks the ECU to *"keep the engine operating smoothly (i.e. no stalls
or driveability problems)"* while the engine is cold. A cold port wall holds more of the fuel,
for longer, so the same tip-in starves a cold engine of more fuel than a warm one, and the
excursion is larger. Warm-up enrichment (`F_cool`) shifts the whole mixture rich to keep a cold
engine from stumbling, but does nothing for the transient: only the film compensation does.
"""

# ╔═╡ d938698a-2d12-4f5f-8d54-1adbb5c21bb8
let
    p = plot(; xlabel = "time [s]", ylabel = "λ error e [%]", legend = :topright,
        title = figure_title((warm_open, cold_open), "Tip-in without compensation, cold and warm"))
    for (r, label, color) in ((cold_open, "cold, 20 °C", :steelblue), (warm_open, "warm, 90 °C", :firebrick))
        t, e = lambda_error(r)
        plot!(p, t, 100 .* e; lw = 2.5, label, color)
    end
    captioned(p, "" * placeholder_note((warm_open, cold_open),
        "`TipInTestTransient` with `T_cool`, signal `$LAMBDA_CYL`"))
end

# ╔═╡ b750db65-c6d4-4120-980b-56ee86022769
check("`TipInTestTransient` cold and warm, without compensation, signal `$LAMBDA_CYL`",
      cold_open, warm_open) do
    cold, warm = worst_error(cold_open), worst_error(warm_open)
    (cold > warm, "worst λ error cold $(round(100cold; digits = 1)) %, warm " *
        "$(round(100warm; digits = 1)) %; cold must be larger")
end

# ╔═╡ bd4b4fe5-2a81-4cae-bfbe-9b36f3388a2a
md"""
### Acceleration enrichment, deceleration enleanment

Slide 28 lists *"Acceleration Enrichment (fuel mixture richness is required)"* and
*"Deceleration Enleanment (inverse than in acceleration)"* among the control strategies. They
are this compensation by another name. On a tip-in the inverse film injects extra fuel, and the
ECU's injected mixture is richer than the cylinder's; on a tip-out it injects less. The names
describe what the injector does. The purpose is that the cylinder sees neither.
"""

# ╔═╡ 9f1bc987-1e1e-4309-8bdf-3e17e5cbe2ae
md"""
## Honest numbers

**From a source.** The target map (deck slide 44, transcribed cell by cell); the stoichiometric
ratio 14.7 (deck); the injector's static flow (Bosch EV14 datasheet).

**Not verified.** The dead-time table is a retailer's copy of EV14 data that is not in Bosch's
own datasheet.

**Assumed.** The film parameters `X` and `τ_f` and their temperature dependence; the warm-up
enrichment curve; the tip-in scenario, with throttle openings chosen to keep the load inside
the stoichiometric part of the map. Each fixes the size of an excursion; none changes its
shape or the direction it goes.

The 5 % and 1 % bands in the check cells are the task's acceptance criteria, not measurements of
a real engine.
"""

# ╔═╡ 22833249-3c73-430a-b19d-661799ddcefe
md"""
## What this bought us

- The pulse width is a product of lookup tables (slide 44), and the base of the product is an
  inversion of the plant: air in, fuel out, at the λ the map asks for.
- The map is stoichiometric where the catalyst needs it and rich only at full load and high
  speed, for power and for component protection.
- Feed-forward has to invert every piece of plant between the sensor and the cylinder: here the
  manifold filling and the fuel film. Inverting only one can make things worse, because their
  errors partly cancel. Inverting both, exactly, removes the tip-in error; inverting them
  approximately leaves part of it, and that part is left to a feedback loop.
- The dead time is a property of the injector, not of the fuel: it depends on the battery.

**Next: 05 — Inside an injector.** The formula's last term, `t_dead(U_batt)`, came from a table.
The next notebook opens the injector and finds where that table comes from.
"""

# ╔═╡ 28590e83-2d80-47af-a7b5-b200eb34239d
details("Model contract: what this notebook needs from the Dyad side", md"""
Everything below is requested from Dyad task 3 (`docs/lecture-02-dyad-tasks.md`). Names in
**bold** are not in that spec yet.

### `Lecture2.TipInTestTransient` (harness `Lecture2.TipInTest`)

| Knob | Unit | Default | Values used here | Slider |
|---|---|---|---|---|
| **`omega_set`** | rad/s | 209.4 (2000 rpm) | 800–6000 rpm | – |
| **`u_thr`** (before the tip-in) | – | 0.05 | 0–1 | – |
| **`u_tip`** (after the tip-in) | – | 0.15 | 0.15 | – |
| **`t_tip_in`**, **`t_tip_out`** | s | 1.0, 3.0 | 1, 3; 1000 and 2000 for steady runs | – |
| `T_cool` | °C | 90 | 20, 90 | – |
| **`with_air_model`** (structural; manifold model in `FuelMetering`) | Bool | false | false, true | – |
| `with_comp` (structural) | Bool | false | false, true | – |
| `Xh` | – | 0.3 | 0.3, 0.21, 0.3 × (1 + error) | error −50:10:50 % |
| `tauh` | s | 0.2 | 0.2, 0.14, 0.2 × (1 + error) | error −50:10:50 % |
| **`U_batt`** | V | 14 | 8–16 | – |
| `stop` | s | 5.0 | 5.0; 0.5 for steady runs | – |

| Signal read | Path | Unit |
|---|---|---|
| λ in the cylinder | `engine.lambda_cyl` | – |
| map target | **`metering.lambda_tgt`** | – |
| air-mass sensor reading (throttle air flow), the metering's `mdot_air_meas` | `engine.mdot_thr` | kg/s |
| cylinder air flow | `engine.mdot_cyl` | kg/s |
| pulse width | `metering.t_inj` | s |
| manifold pressure | `engine.p_m` | Pa |
| throttle command | **`throttle.y`** | – |

### Checks

| Check | Runs | Signals | Expected |
|---|---|---|---|
| map reproduction | 11 speeds × 9 throttles, warm, 14 V, steady | `metering.lambda_tgt`, `engine.p_m` | within 0.05 AFR of the transcribed map at the run's speed and load |
| uncompensated tip-in | 2000 rpm, throttle 5 → 15 %, warm | `engine.lambda_cyl` (relative to its value just before the tip-in) | worst error, either direction, ≥ 5 % |
| compensated tip-in | same, film only (`with_comp`) and both (`with_air_model` + `with_comp`), exact estimates | same | both: worst error below 1 %; film only: larger than both |
| cold vs warm | same, uncompensated, 20 and 90 °C | same | cold worst error larger |

`FuelMetering` reads the throttle air flow as `mdot_air_meas` (the air-mass sensor). With
**`with_air_model`** it passes that reading through a copy of the manifold equation (the
`IntakeManifold` and `CylinderAirflow` equations of task 1) and meters fuel for the estimated
cylinder air; this is an addition to task 3. The harness
should move the throttle plate with a short lag or ramp (an electronic throttle takes tens of
milliseconds); an ideal step makes the air-mass reading, and so the fuel, jump without limit.
""")

# ╔═╡ Cell order:
# ╟─7d05873f-0b3d-4515-9525-709c3634a134
# ╠═155c6716-b6be-446a-9540-7c88b84e13ed
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
# ╠═1fe46b56-5771-4580-a565-91be0f7058ff
# ╟─40f06c8d-8fb4-4f0b-ae7a-c9ceac130159
# ╠═8c9c0dfb-575c-479b-933e-28637cc78087
# ╠═e8b07dda-e228-49f5-86bc-492997169288
# ╟─48f37ad2-18af-452c-b798-2e47333f6764
# ╠═d938698a-2d12-4f5f-8d54-1adbb5c21bb8
# ╠═b750db65-c6d4-4120-980b-56ee86022769
# ╟─bd4b4fe5-2a81-4cae-bfbe-9b36f3388a2a
# ╟─9f1bc987-1e1e-4309-8bdf-3e17e5cbe2ae
# ╟─22833249-3c73-430a-b19d-661799ddcefe
# ╟─28590e83-2d80-47af-a7b5-b200eb34239d
