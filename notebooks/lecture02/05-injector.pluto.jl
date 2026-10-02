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

# ╔═╡ 5316326f-6f92-4171-ab34-9d07bb1b47a1
md"""
# Lecture 2 · 05 — Inside an injector

> **A pulse width is a command, not a quantity of fuel. The injector's electromagnetics and
> mechanics decide what actually flows.**

Notebook 04 ended with a formula that turns fuel into milliseconds, plus a dead time read from a
table. This notebook opens the injector and finds the table inside it.

**Model.** `Lecture2.InjectorPulseTransient` drives one `Vehicle.Engine.FuelInjector` from a
battery through a low-side switch for one pulse, with the fuel rail 3 bar above the manifold.
"""

# ╔═╡ 60e4623c-a261-43fd-a3ad-0d51af35b770
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
    InjectorPulseTransient = bind_analysis(:InjectorPulseTransient, library; stubs)
    show_dyad = isnothing(stubs) ? Lecture01Support.show_dyad : stubs.show_dyad
end

# ╔═╡ 7da36eb8-fa97-4c18-9544-dd82a1b7ae3a
md"""
$(deck_figure("slide43-injector-section.png"; width = 520))

Slide 43, an injector in section: 1 pintle, 2 needle, 3 armature, 4 spring, 5 solenoid winding,
6 electrical terminals, 7 fuel strainer. *"When the solenoid winding is energized, the nozzle
needle is lifted a mere 0.05 mm off its seat. The injected fuel quantity per unit of time is
essentially determined by the system pressure and the free cross-section of the spray
orifices."*
"""

# ╔═╡ 69961718-ad3c-4ef7-8331-cfbf1d8aa562
md"""
## 1 · Four domains in one component

An injector is a small electromechanical valve, and the model follows the energy through it.

**Electrical.** The winding is a resistance in series with an inductance that depends on the air
gap `g` between armature and core. The flux linkage `ψ = L(g) i` is the electrical state:

```math
v = R\,i + \frac{d\psi}{dt} = R\,i + L(g)\,\frac{di}{dt} + i\,\frac{dL}{dx}\,\dot x,
\qquad
L(g) = L_\infty + L_0\,\frac{g_0}{g + g_0},
\quad g = g_\text{max} - x
```

**Magnetic.** The force on the armature follows from the stored energy, so it pulls toward the
closing gap and grows with the square of the current:

```math
f = \tfrac12\, i^2\, \frac{dL}{dx}
```

**Mechanical.** The armature and needle are one mass, held on the seat by a preloaded spring, and
stopped at full lift by the armature stop. The needle cannot move until the magnetic force beats
the spring preload.

**Fluid.** Fuel flows through whichever is smaller, the annulus the needle uncovers or the
spray-orifice area, driven by the rail pressure:

```math
\dot m_f = C_d\,\min\!\left(\pi\,d_\text{seat}\,x,\ A_\text{orifice}\right)\sqrt{2\,\rho_f\,\Delta p}
```

The coil resistance is 12 Ω and the static flow 146 cm³/min at 3 bar (Bosch EV14 datasheet). The
needle travel stops at 0.06 mm, close to slide 43's 0.05 mm. The inductance curve, the needle
mass and the spring are *(assumed)*: no manufacturer publishes them, and they are set so the
opening dead time lands in the expected band.
"""

# ╔═╡ e1756e70-c6a4-4c7c-9d0d-98124e75842e
show_dyad("Solenoid")

# ╔═╡ 63f02df0-88ce-4717-b1eb-bcf8a0a85925
show_dyad("FuelInjector")

# ╔═╡ 0e5ba80c-2fa0-4c4e-9cfe-101a4ab959ae
md"""
## 2 · Slide 45, regenerated

Slide 45 shows the four things that happen during one pulse, on one time axis: the activation
signal, the coil current, the needle lift and the injected quantity. Two times frame the
pulse. The **pickup time** `t_on` runs from the start of the activation until the needle reaches
full lift; the **dropout time** `t_off` runs from the end of the activation until the needle is
back on its seat.

The battery voltage is the knob: it sets how fast the current can rise.
"""

# ╔═╡ eeb3f849-bfc7-41fe-b68f-2ef92d37d4d8
md"battery voltage [V] $(@bind u_batt Slider(8.0:0.5:16.0; default = 14.0, show_value = true))"

# ╔═╡ 7dbe25f0-deca-4742-8413-f1dda9f8256a
begin
    U_NOMINAL, T_PULSE = 14.0, 3e-3
    nominal = InjectorPulseTransient(U_batt = U_NOMINAL, t_pulse = T_PULSE)
    live = InjectorPulseTransient(U_batt = u_batt, t_pulse = T_PULSE)
    "Start and end of the activation pulse, read from the run."
    function activation(r)
        t, a = signal(r, ACTIVATION)
        on = crossing(t, a, 0.5)
        return (; on, off = crossing(t, a, 0.5; after = on))
    end
    "Pickup and dropout times: activation edge to full lift, and to the needle back on its seat."
    function pickup_dropout(r)
        t, x = signal(r, LIFT)
        a = activation(r)
        x_max = maximum(x)
        open_at = crossing(t, x, 0.95x_max; after = a.on)
        closed_at = crossing(t, x, 0.05x_max; after = a.off)
        return (t_on = open_at - a.on, t_off = closed_at - a.off)
    end
end

# ╔═╡ 8c1c165c-82a5-454e-8945-5c2d28534078
let
    t, a = signal(nominal, ACTIVATION)
    _, i = signal(nominal, I_COIL)
    _, x = signal(nominal, LIFT)
    _, m = signal(nominal, FUEL_MASS)
    tl, il = signal(live, I_COIL)
    _, xl = signal(live, LIFT)
    ms = 1000 .* t
    edges = activation(nominal)
    times = pickup_dropout(nominal)
    common = (xlims = (0, 1000 * last(t)), legend = :topright)
    p1 = plot(ms, a; lw = 2.5, color = :black, label = "", ylabel = "activation", ylims = (-0.1, 1.2),
        title = figure_title((nominal, live), "One injection pulse, $(Int(1000T_PULSE)) ms at $(U_NOMINAL) V"),
        common...)
    p2 = plot(ms, i; lw = 2.5, color = :steelblue, label = "$(U_NOMINAL) V", ylabel = "current [A]", common...)
    plot!(p2, 1000 .* tl, il; lw = 2, ls = :dash, color = :purple, label = "$(u_batt) V (slider)")
    p3 = plot(ms, 1000 .* x; lw = 2.5, color = :steelblue, label = "", ylabel = "lift [mm]", common...)
    plot!(p3, 1000 .* tl, 1000 .* xl; lw = 2, ls = :dash, color = :purple, label = "")
    vline!(p3, 1000 .* [edges.on + times.t_on, edges.off + times.t_off]; color = :gray, ls = :dot, label = "")
    annotate!(p3, 1000 * (edges.on + times.t_on / 2), 0.03, text("t_on", 9))
    annotate!(p3, 1000 * (edges.off + times.t_off / 2), 0.03, text("t_off", 9))
    p4 = plot(ms, 1e6 .* m; lw = 2.5, color = :seagreen, label = "", ylabel = "fuel [mg]",
        xlabel = "time [ms]", common...)
    compare(
        deck_figure("slide45-injector.png"; width = 260),
        captioned(plot(p1, p2, p3, p4; layout = (4, 1), size = (620, 760), link = :x), """
            Slide 45 (Bosch, figure 10) and the model, stacked the same way: activation, current,
            needle lift, injected fuel. The dashed curves follow the battery-voltage slider.
            """ * placeholder_note((nominal, live),
                "`InjectorPulseTransient` signals `$ACTIVATION`, `$I_COIL`, `$LIFT`, `$FUEL_MASS`")))
end

# ╔═╡ 42b277cd-6a08-49af-891f-789422267d22
md"""
### The kink in the current

Slide 45 annotates its own figure: the rising current lifts the needle, *"maximum displacement
achieved when pickup time is reached"*, the needle *"stops at the solenoid armature stop"*, and
the *"current continues to rise (magnetic field not yet at saturation)"*. The model shows why the
current dents on the way. While the armature moves, the gap closes and the inductance rises, and
the term `i (dL/dx) ẋ` in the voltage equation is a back-EMF that takes voltage away from the
resistance. The current dips. Once the armature hits its stop, `ẋ = 0`, the back-EMF vanishes,
and the current resumes its rise, more slowly than before, because the closed gap's inductance is
larger. The dent marks the instant the needle moves; drivers use it to detect the opening.
"""

# ╔═╡ 6ce31197-9830-4e38-b79a-b005ed3a924b
md"""
## 3 · Fuel per pulse

Once the needle is fully open, fuel flows at the static rate. A long pulse therefore delivers fuel
in proportion to its length, offset by the time the injector spends opening and closing:

```math
m_f \approx q_\text{static}\,\bigl(t_\text{pulse} - t_\text{dead}\bigr)
\qquad \text{for long pulses}
```

The offset `t_dead` is the dead time notebook 04's formula adds back. Below about 2 ms the
needle spends a large part of the pulse in motion, and on very short pulses it never reaches its
stop: the delivered fuel falls below the straight line. That is the injector's **ballistic**
region, which ECUs avoid or calibrate separately.

The sweep runs pulse widths from 0.5 to 8 ms at 14 V and at 8 V.
"""

# ╔═╡ a22bb430-31a0-4e52-9aef-69eeeb90407a
begin
    PULSES = collect(0.5e-3:0.5e-3:8e-3)
    LINEAR_FROM = 2e-3
    fuel_per_pulse(r) = last(last(signal(r, FUEL_MASS)))
    pulse_sweep(U) = [InjectorPulseTransient(U_batt = U, t_pulse = tp) for tp in PULSES]
    sweep_14, sweep_8 = pulse_sweep(14.0), pulse_sweep(8.0)
    "Straight line through the long pulses, and its intercept with zero fuel: the dead time."
    function dead_time_fit(runs)
        long = PULSES .>= LINEAR_FROM
        fit = linear_fit(PULSES[long], fuel_per_pulse.(runs[long]))
        return (; fit..., t_dead = -fit.intercept / fit.slope)
    end
    fit_14, fit_8 = dead_time_fit(sweep_14), dead_time_fit(sweep_8)
end

# ╔═╡ 055e9a18-a622-4b70-918d-48f9782f1c9d
let
    p = plot(; xlabel = "pulse width [ms]", ylabel = "fuel per pulse [mg]", legend = :topleft,
        title = figure_title((sweep_14, sweep_8), "Fuel per pulse against pulse width"))
    for (runs, fit, U, color) in ((sweep_14, fit_14, 14, :steelblue), (sweep_8, fit_8, 8, :firebrick))
        scatter!(p, 1000 .* PULSES, 1e6 .* fuel_per_pulse.(runs); ms = 5, color, label = "$U V")
        line = range(fit.t_dead, last(PULSES); length = 2)
        plot!(p, 1000 .* line, 1e6 .* (fit.slope .* line .+ fit.intercept); color, ls = :dash,
            label = "straight line through ≥ 2 ms")
    end
    vspan!(p, [0, 1000LINEAR_FROM]; color = :gray, alpha = 0.1, label = "ballistic region")
    hline!(p, [0]; color = :black, lw = 0.5, label = "")
    captioned(p, """
        Where each dashed line meets zero fuel is that voltage's dead time.
        """ * placeholder_note((sweep_14, sweep_8),
            "`InjectorPulseTransient` swept over `t_pulse` at two `U_batt`, signal `$FUEL_MASS`"))
end

# ╔═╡ 68955cb3-5329-4289-8ff7-24dff2c3c635
check("`InjectorPulseTransient` swept over `t_pulse` at 14 V and 8 V, signal `$FUEL_MASS`",
      sweep_14, sweep_8) do
    long = PULSES .>= LINEAR_FROM
    m = fuel_per_pulse.(sweep_14[long])
    residual = maximum(abs.(fit_14.slope .* PULSES[long] .+ fit_14.intercept .- m) ./ m)
    (0.6e-3 <= fit_14.t_dead <= 1.0e-3 && 1.5e-3 <= fit_8.t_dead <= 2.5e-3 && residual < 0.02,
        "dead time $(round(1000fit_14.t_dead; digits = 3)) ms at 14 V (0.6–1.0), " *
        "$(round(1000fit_8.t_dead; digits = 3)) ms at 8 V (1.5–2.5); straight line within " *
        "$(round(100residual; digits = 2)) % above 2 ms (proposed band 2 %)")
end

# ╔═╡ 4fad9943-2ca1-44d4-80ba-d8e7f69c9bd1
md"""
## 4 · Why the battery matters

The current through an RL circuit rises toward `U/R` with the time constant `L/R`. The needle
moves when the current reaches the value whose magnetic force beats the spring preload, the
pickup current `i_pick`. The time to get there is

```math
t_\text{pick} = -\frac{L}{R}\,\ln\!\left(1 - \frac{i_\text{pick}\,R}{U_\text{batt}}\right)
```

which grows without bound as `U_batt` falls toward `i_pick R`: a weak battery cannot open the
injector at all. The coil and the spring are the same at every voltage; only the end point of the
current rise moves. That is why notebook 04's formula carries a battery-voltage correction, and
why the correction is a curve rather than a constant.
"""

# ╔═╡ 9a61b176-7e18-4a1e-b871-3e26f3dd6a72
begin
    BATTERY = [8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0]
    battery_sweeps = [pulse_sweep(U) for U in BATTERY]
    battery_dead = [dead_time_fit(s).t_dead for s in battery_sweeps]
    EV14_DEAD_TIME = (U = [8.0, 12.0, 14.0, 16.0], t = [2.000, 0.903, 0.800, 0.558])
end

# ╔═╡ 4eaab806-1c5d-4760-a76c-8487898925df
let
    p = plot(BATTERY, 1000 .* battery_dead; lw = 3, marker = :circle, color = :steelblue,
        label = "model: intercept of the fuel line", xlabel = "battery voltage [V]",
        ylabel = "dead time [ms]", legend = :topright,
        title = figure_title(battery_sweeps, "Dead time against battery voltage"))
    scatter!(p, EV14_DEAD_TIME.U, EV14_DEAD_TIME.t; marker = :diamond, ms = 8, color = :darkorange,
        label = "EV14 table (retailer data, not verified at Bosch)")
    plot!(p, [13.5, 14.5], [0.6, 0.6]; fillrange = 1.0, color = :seagreen, alpha = 0.2, lw = 0,
        label = "expected bands")
    plot!(p, [7.5, 8.5], [1.5, 1.5]; fillrange = 2.5, color = :seagreen, alpha = 0.2, lw = 0, label = "")
    captioned(p, "" * placeholder_note(battery_sweeps,
        "`InjectorPulseTransient` swept over `t_pulse` and `U_batt`, signal `$FUEL_MASS`"))
end

# ╔═╡ 767e17d8-c4c2-4783-b59e-3f871aa8569b
md"""
## 5 · Static flow

The datasheet number is the flow with the needle held fully open at 3 bar: 146 cm³/min for the
smallest EV14. It is the slope of the straight line above, and it is also what flows once the
needle sits on its stop during a long pulse.
"""

# ╔═╡ 25ed2a9b-1588-4bac-92b2-3a23115670c8
check("`InjectorPulseTransient` at 14 V, signals `$MDOT_INJ` and `$LIFT`", nominal) do
    _, mdot = signal(nominal, MDOT_INJ)
    _, x = signal(nominal, LIFT)
    q = maximum(mdot) / ENGINE.rho_f * 60e6
    x_max = maximum(x)
    (abs(q / ENGINE.q_static - 1) <= 0.05 && abs(x_max / 0.06e-3 - 1) <= 0.02,
        "static flow $(round(q; digits = 1)) cm³/min, band 146 ± 5 %; maximum lift " *
        "$(round(1000x_max; digits = 4)) mm against the 0.06 mm stop (within 2 %)")
end

# ╔═╡ 928faeb1-a41a-47b4-9eba-a2a3861e68b3
md"""
## 6 · Switching off: the flyback

Slide 45 notes that at switch-off the *"magnetic field is not decreased abruptly"*. The coil's
current cannot stop instantly, and when the switch opens the inductance drives it on by raising
the voltage across the switch, `v = L di/dt`, until something conducts. A bare transistor would
break down. Injector drivers clamp the voltage with a Zener diode, and the clamp level is a
trade-off: a higher clamp dissipates the stored energy faster and closes the needle sooner, at
the price of more stress on the driver. The model has no ideal diode; its switch-off resistance
is chosen so that the voltage clamps near 60–80 V *(assumed, the range of a real driver's Zener)*.
"""

# ╔═╡ 7441e392-71c0-4735-bfc5-6337e7e9a8f3
let
    t, v = signal(live, V_SWITCH)
    _, i = signal(live, I_COIL)
    off = activation(live).off
    window = (1000 * (off - 0.5e-3), 1000 * (off + 2e-3))
    p1 = plot(1000 .* t, v; lw = 2.5, color = :firebrick, label = "", ylabel = "switch voltage [V]",
        xlims = window, title = figure_title(live, "Switch-off at $(u_batt) V"))
    hspan!(p1, [60, 80]; color = :gray, alpha = 0.15, label = "clamp range 60–80 V")
    p2 = plot(1000 .* t, i; lw = 2.5, color = :steelblue, label = "", ylabel = "current [A]",
        xlabel = "time [ms]", xlims = window)
    captioned(plot(p1, p2; layout = (2, 1), size = (620, 460), link = :x), "" *
        placeholder_note(live, "`InjectorPulseTransient` signals `$V_SWITCH` and `$I_COIL`"))
end

# ╔═╡ 635f8119-c558-4167-9bf9-10def058aa42
check("`InjectorPulseTransient` at 14 V, signal `$V_SWITCH`", nominal) do
    peak = maximum(last(signal(nominal, V_SWITCH)))
    (60 <= peak <= 80, "flyback peak $(round(peak; digits = 1)) V; design band 60–80 V (assumed clamp)")
end

# ╔═╡ 2fc120b8-1c13-450f-ad24-f39afb98dcb7
md"""
## Honest numbers

**From a source.** The coil resistance, 12 Ω, and the static flow, 146 cm³/min at 3 bar (Bosch
EV14 datasheet); the needle travel of about 0.05 mm (deck slide 43); the shape of the four
traces (deck slide 45).

**Not verified.** The dead-time table the model is compared against is a retailer's copy of EV14
data and is not in Bosch's own datasheet. The bands for the dead time are built from it.

**Assumed.** The inductance curve, the needle mass, the spring rate and preload, the seat
diameter, and the switch-off resistance. No manufacturer publishes them. They are set so the
dead time lands in its band, so the dead time this notebook reproduces is a calibration target,
not a prediction. What the model does predict is the shape: the kink, the ballistic region, and
the dead time's rise as the battery weakens.
"""

# ╔═╡ 342e64d9-d669-4613-96e8-2d1953c5a285
md"""
## What this bought us

- An injector opens late because the coil current needs time to reach the force that beats the
  spring. That time is the dead time, and it depends on the battery voltage.
- Above about 2 ms the fuel per pulse is a straight line offset by the dead time, which is
  exactly the form notebook 04's formula assumes. Below it the needle never settles, and the
  formula stops being true.
- The current trace carries a signature of the needle's motion, and the switch-off needs a clamp
  to survive the coil's stored energy.

**Next: 06 — Lambda control and the catalyst.** Feed-forward has now been carried down to the
needle. Everything it still gets wrong lands in the exhaust, where a sensor can see it.
"""

# ╔═╡ 2494fe1f-5b0b-4d04-a1ec-9042cc9b3cb5
details("Model contract: what this notebook needs from the Dyad side", md"""
Everything below is requested from Dyad task 4 (`docs/lecture-02-dyad-tasks.md`). Names in
**bold** are not in that spec yet.

### `Lecture2.InjectorPulseTransient` (harness `Lecture2.InjectorPulse`)

| Knob | Unit | Default | Values used here | Slider |
|---|---|---|---|---|
| `U_batt` | V | 14 | 8–16 | 8.0:0.5:16.0 |
| `t_pulse` | s | 3e-3 | 0.5–8 ms | – |
| **`t_start`** (pulse start) | s | 0.5e-3 | 0.5e-3 | – |
| `stop` | s | **`t_start + t_pulse + 3e-3`** | default | – |

| Signal read | Path | Unit |
|---|---|---|
| activation | **`pulse.y`** | – |
| coil current | **`injector.solenoid.i`** | A |
| needle lift | `injector.lift` | m |
| fuel mass flow | `injector.mdot_f` | kg/s |
| cumulative fuel | **`fuel_mass.y`** | kg |
| switch voltage | **`switch.v`** | V |

### Checks

| Check | Runs | Signals | Expected |
|---|---|---|---|
| dead time and linearity | `t_pulse` 0.5–8 ms at 14 V and 8 V | `fuel_mass.y` | intercept of the fit over ≥ 2 ms: 0.6–1.0 ms at 14 V, 1.5–2.5 ms at 8 V; fit within 2 % above 2 ms |
| static flow and stop | 3 ms at 14 V | `injector.mdot_f`, `injector.lift` | 146 cm³/min ± 5 %; maximum lift within 2 % of 0.06 mm |
| flyback | 3 ms at 14 V | `switch.v` | peak 60–80 V |
""")

# ╔═╡ Cell order:
# ╟─5316326f-6f92-4171-ab34-9d07bb1b47a1
# ╠═60e4623c-a261-43fd-a3ad-0d51af35b770
# ╟─7da36eb8-fa97-4c18-9544-dd82a1b7ae3a
# ╟─69961718-ad3c-4ef7-8331-cfbf1d8aa562
# ╠═e1756e70-c6a4-4c7c-9d0d-98124e75842e
# ╠═63f02df0-88ce-4717-b1eb-bcf8a0a85925
# ╟─0e5ba80c-2fa0-4c4e-9cfe-101a4ab959ae
# ╠═eeb3f849-bfc7-41fe-b68f-2ef92d37d4d8
# ╠═7dbe25f0-deca-4742-8413-f1dda9f8256a
# ╠═8c1c165c-82a5-454e-8945-5c2d28534078
# ╟─42b277cd-6a08-49af-891f-789422267d22
# ╟─6ce31197-9830-4e38-b79a-b005ed3a924b
# ╠═a22bb430-31a0-4e52-9aef-69eeeb90407a
# ╠═055e9a18-a622-4b70-918d-48f9782f1c9d
# ╠═68955cb3-5329-4289-8ff7-24dff2c3c635
# ╟─4fad9943-2ca1-44d4-80ba-d8e7f69c9bd1
# ╠═9a61b176-7e18-4a1e-b871-3e26f3dd6a72
# ╠═4eaab806-1c5d-4760-a76c-8487898925df
# ╟─767e17d8-c4c2-4783-b59e-3f871aa8569b
# ╠═25ed2a9b-1588-4bac-92b2-3a23115670c8
# ╟─928faeb1-a41a-47b4-9eba-a2a3861e68b3
# ╠═7441e392-71c0-4735-bfc5-6337e7e9a8f3
# ╠═635f8119-c558-4167-9bf9-10def058aa42
# ╟─2fc120b8-1c13-450f-ad24-f39afb98dcb7
# ╟─342e64d9-d669-4613-96e8-2d1953c5a285
# ╟─2494fe1f-5b0b-4d04-a1ec-9042cc9b3cb5
