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

# ╔═╡ 60e4623c-a261-43fd-a3ad-0d51af35b770
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, "..", ".."))
    include(joinpath(@__DIR__, "..", "lecture01", "support.jl"))
    using .Lecture01Support

    # PlutoPlotly is no dependency of the library, so it comes from a shared environment stacked
    # behind the project: the project's Manifest stays the library's own.
    let env = "@lecture02-plotly"
        env in LOAD_PATH || push!(LOAD_PATH, env)
        if isnothing(Base.identify_package("PlutoPlotly"))
            project = Base.active_project()
            try
                Pkg.activate(env[2:end]; shared = true)
                Pkg.add(Pkg.PackageSpec(; name = "PlutoPlotly", version = "0.6.6"))
            finally
                Pkg.activate(project)
            end
        end
    end

    # Not bound as `VehicleSystemsComponents`: run as a script, that global would collide with
    # the module of the same name that `setup` defines in `Main`.
    library = setup()
    using PlutoUI
    import PlutoPlotly as PP
    InjectorPulseTransient = library.Lecture2.InjectorPulseTransient
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

# ╔═╡ 4d6a5916-bc8b-4a88-acef-43fb631a9e73
begin
    const ASSETS = joinpath(@__DIR__, "assets")
    const DECK_PPTX = joinpath(@__DIR__, "..", "..", "slides", "decks", "lecture-02", "public", "pptx")

    "A figure of the lecturer's deck: from `assets/` when the deck no longer shows it, else from the deck."
    function deck_figure(name; width = 420)
        path = isfile(joinpath(ASSETS, name)) ? joinpath(ASSETS, name) : joinpath(DECK_PPTX, name)
        isfile(path) || throw(ArgumentError("no deck figure `$name`"))
        LocalResource(path, :width => width)
    end

    "First time after `after` at which `y` crosses `level`, interpolated between samples."
    function crossing(t, y, level; after = first(t) - 1)
        for i in max(2, searchsortedfirst(t, after)):length(t)
            a, b = y[i - 1] - level, y[i] - level
            (a == 0 || a * b < 0) || continue
            tc = t[i - 1] + (level - y[i - 1]) / (y[i] - y[i - 1]) * (t[i] - t[i - 1])
            tc > after && return tc
        end
        nothing
    end

    "Least-squares straight line through `(x, y)`."
    function linear_fit(x, y)
        mx, my = sum(x) / length(x), sum(y) / length(y)
        slope = sum((x .- mx) .* (y .- my)) / sum((x .- mx) .^ 2)
        (; slope, intercept = my - slope * mx)
    end

    deck_layout(; kwargs...) = PP.Layout(;
        template = PP.templates[:plotly_white],
        font = PP.attr(size = 15),
        margin = PP.attr(l = 80, r = 20, t = 30, b = 60),
        kwargs...)

    const ACTIVATION, I_COIL, LIFT = "pulse.y", "injector.solenoid.i", "injector.lift"
    const MDOT_INJ, FUEL_MASS, V_SWITCH = "injector.mdot_f", "fuel_mass.y", "transistor.v"
    const RHO_FUEL, Q_STATIC, LIFT_STOP = 740.0, 146.0, 0.05e-3
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
needle travel stops at 0.05 mm, slide 43's figure, and the orifice is sized so that full lift
gives the datasheet flow. The inductance curve, the needle mass and the spring are *(assumed)*:
no manufacturer publishes them, and they are set so the dead time lands in the expected band.
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
"""

# ╔═╡ 7dbe25f0-deca-4742-8413-f1dda9f8256a
begin
    U_NOMINAL, T_START, T_PULSE = 14.0, 0.5e-3, 3e-3
    pulse_run(; U_batt = U_NOMINAL, t_pulse = T_PULSE) =
        InjectorPulseTransient(; U_batt, t_pulse, t_start = T_START, stop = T_START + t_pulse + 3e-3)
    nominal = pulse_run()

    "Start and end of the activation pulse, read from the run."
    function activation(r)
        t, a = signal(r, ACTIVATION)
        on = crossing(t, a, 0.5)
        (; on, off = crossing(t, a, 0.5; after = on))
    end

    "Pickup and dropout times: activation edge to full lift, and to the needle back on its seat."
    function pickup_dropout(r)
        t, x = signal(r, LIFT)
        a = activation(r)
        open_at = crossing(t, x, 0.95LIFT_STOP; after = a.on)
        closed_at = crossing(t, x, 0.05LIFT_STOP; after = a.off)
        (t_on = open_at - a.on, t_off = closed_at - a.off)
    end
    nominal_times = pickup_dropout(nominal)
end

# ╔═╡ 7d639560-d8cd-4d78-b830-914034943073
"""
    pulse_figure(runs) -> PlutoPlotly plot

Slide 45's four traces, stacked on one time axis: a) activation, b) coil current, c) needle lift,
d) injected fuel. `runs` pairs a run with its label and line dash; the first is the one whose
`t_on` and `t_off` are marked.
"""
function pulse_figure(runs)
    ms(t) = round.(1e3 .* t; digits = 4)
    rows = ((ACTIVATION, 1.0, "a) activation"), (I_COIL, 1.0, "b) current [A]"),
        (LIFT, 1e3, "c) lift [mm]"), (FUEL_MASS, 1e6, "d) fuel [mg]"))
    colors = ("#455a64", "#1e88e5", "#e53935", "#43a047")
    traces = Any[]
    for (k, (run, label, dash)) in enumerate(runs), (row, (path, scale, _)) in enumerate(rows)
        t, y = signal(run, path)
        push!(traces, PP.scatter(; x = ms(t), y = round.(scale .* y; sigdigits = 5), mode = "lines",
            name = label, legendgroup = label, showlegend = row == 2 && length(runs) > 1,
            line = PP.attr(; width = 3, color = colors[row], dash),
            xaxis = row == 1 ? "x" : "x$row", yaxis = row == 1 ? "y" : "y$row"))
    end
    lead = first(first(runs))
    edges, times = activation(lead), pickup_dropout(lead)
    t_open, t_closed = 1e3 * (edges.on + times.t_on), 1e3 * (edges.off + times.t_off)
    marker(x) = PP.attr(type = "line", xref = "x4", yref = "paper", x0 = x, x1 = x, y0 = 0, y1 = 1,
        line = PP.attr(color = "#9e9e9e", width = 1.5, dash = "dot"))
    span(x0, x1, text) = (
        PP.attr(type = "line", xref = "x3", yref = "y3", x0 = x0, x1 = x1, y0 = 0.065, y1 = 0.065,
            line = PP.attr(color = "#424242", width = 2)),
        PP.attr(xref = "x3", yref = "y3", x = (x0 + x1) / 2, y = 0.065, text = text, showarrow = false,
            yshift = 12, font = PP.attr(size = 14)))
    on_span, off_span = span(1e3edges.on, t_open, "t<sub>on</sub>"), span(1e3edges.off, t_closed, "t<sub>off</sub>")
    domains = ([0.82, 1.0], [0.55, 0.77], [0.28, 0.50], [0.0, 0.23])
    axes = Dict{Symbol, Any}()
    for (row, (_, _, title)) in enumerate(rows)
        suffix = row == 1 ? "" : string(row)
        axes[Symbol("xaxis$suffix")] = row == 4 ?
            PP.attr(anchor = "y4", title = "time [ms]") :
            PP.attr(anchor = "y$suffix", matches = "x4", showticklabels = false)
        axes[Symbol("yaxis$suffix")] = row == 3 ?
            PP.attr(domain = domains[row], anchor = "x3", title = PP.attr(text = title, font = PP.attr(size = 13)), range = [-0.004, 0.08]) :
            PP.attr(domain = domains[row], anchor = "x$suffix", title = PP.attr(text = title, font = PP.attr(size = 13)))
    end
    PP.plot(identity.(traces), deck_layout(;
        axes...,
        shapes = [marker(t_open), marker(t_closed), on_span[1], off_span[1]],
        annotations = [on_span[2], off_span[2]],
        legend = PP.attr(x = 0.98, xanchor = "right", y = 0.77, yanchor = "top"),
        margin = PP.attr(l = 80, r = 20, t = 10, b = 50)))
end

# ╔═╡ 8c1c165c-82a5-454e-8945-5c2d28534078
# ╠═╡ card = "injector-pulse"
pulse_figure([(nominal, "$(Int(U_NOMINAL)) V", "solid")])

# ╔═╡ ef5932bc-7639-4fdd-a1d7-efb6e161cbad
md"""
The battery voltage is the knob: it sets how fast the current can rise. The dashed traces follow
the slider.

battery voltage [V] $(@bind u_batt Slider(8.0:0.5:16.0; default = 14.0, show_value = true))
"""

# ╔═╡ dd992532-e951-4654-ab62-8dab247ea04e
let live = pulse_run(U_batt = u_batt)
    PlutoUI.ExperimentalLayout.hbox([
        deck_figure("slide45-injector.png"; width = 300),
        pulse_figure([(nominal, "$(Int(U_NOMINAL)) V", "solid"), (live, "$(u_batt) V", "dash")]),
    ]; style = Dict("gap" => "1.5em", "align-items" => "center"))
end

# ╔═╡ 30acd0d8-e5bb-41da-a66c-3c76b97b2381
let
    t, i = signal(nominal, I_COIL)
    _, x = signal(nominal, LIFT)
    on = findall(k -> T_START < t[k] < T_START + T_PULSE, eachindex(t))
    dent = findfirst(<(0), diff(i[on]))
    @assert !isnothing(dent) "the current never falls while the switch is on: no pickup kink"
    @assert x[on][dent] > 0 "the current falls before the needle moves"
    @assert nominal_times.t_on > 0 && nominal_times.t_off > 0
    md"""
    **Pickup** `t_on` = $(round(1e3nominal_times.t_on; digits = 2)) ms, **dropout** `t_off` =
    $(round(1e3nominal_times.t_off; digits = 2)) ms at $(Int(U_NOMINAL)) V. The current peaks at
    $(round(i[on][dent]; digits = 2)) A, then falls while the needle moves.
    """
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

The offset `t_dead` is the dead time notebook 04's formula adds back. On short pulses the needle
spends a large part of the pulse in motion, and on very short ones it never reaches its stop:
the delivered fuel falls below the straight line. That is the injector's **ballistic** region,
which ECUs avoid or calibrate separately. Where the straight line starts depends on the battery:
at 14 V the needle is open after about 1.2 ms, so pulses from 2 ms on lie on the line; at 8 V it
needs nearly 3 ms, so the line starts at 4 ms.

The sweep runs pulse widths from 0.5 to 8 ms at 14 V and at 8 V.
"""

# ╔═╡ a22bb430-31a0-4e52-9aef-69eeeb90407a
begin
    PULSES = collect(0.5e-3:0.5e-3:8e-3)
    fuel_per_pulse(r) = last(last(signal(r, FUEL_MASS)))
    pulse_sweep(U) = [pulse_run(U_batt = U, t_pulse = tp) for tp in PULSES]

    """
        dead_time_fit(runs) -> (; slope, intercept, t_dead, from, t_open)

    Straight line through the pulses that open the needle fully at least 1 ms before they end, and
    never shorter than 2 ms; its intercept with zero fuel is the dead time.
    """
    function dead_time_fit(runs)
        t_open = pickup_dropout(last(runs)).t_on
        from = max(2e-3, t_open + 1e-3)
        long = PULSES .>= from - 1e-9
        fit = linear_fit(PULSES[long], fuel_per_pulse.(runs[long]))
        (; fit..., t_dead = -fit.intercept / fit.slope, from, t_open)
    end
    sweep_14, sweep_8 = pulse_sweep(14.0), pulse_sweep(8.0)
    fit_14, fit_8 = dead_time_fit(sweep_14), dead_time_fit(sweep_8)
end

# ╔═╡ 055e9a18-a622-4b70-918d-48f9782f1c9d
let
    traces = Any[]
    for (runs, fit, U, color) in ((sweep_14, fit_14, 14, "#1e88e5"), (sweep_8, fit_8, 8, "#e53935"))
        push!(traces, PP.scatter(; x = 1e3 .* PULSES, y = round.(1e6 .* fuel_per_pulse.(runs); sigdigits = 5),
            mode = "markers", name = "$U V", marker = PP.attr(; size = 9, color)))
        line = [fit.t_dead, last(PULSES)]
        push!(traces, PP.scatter(; x = round.(1e3 .* line; digits = 4),
            y = round.(1e6 .* (fit.slope .* line .+ fit.intercept); sigdigits = 5), mode = "lines",
            name = "$U V: line through ≥ $(round(1e3fit.from; digits = 1)) ms, offset $(round(1e3fit.t_dead; digits = 2)) ms",
            line = PP.attr(; color, dash = "dash", width = 2)))
    end
    PP.plot(identity.(traces), deck_layout(; xaxis_title = "pulse width [ms]", yaxis_title = "fuel per pulse [mg]",
        legend = PP.attr(x = 0.02, y = 0.98)))
end

# ╔═╡ 68955cb3-5329-4289-8ff7-24dff2c3c635
let
    long = PULSES .>= fit_14.from - 1e-9
    m = fuel_per_pulse.(sweep_14[long])
    residual = maximum(abs.(fit_14.slope .* PULSES[long] .+ fit_14.intercept .- m) ./ m)
    @assert 0.6e-3 <= fit_14.t_dead <= 1.0e-3 "offset $(fit_14.t_dead) s at 14 V outside 0.6–1.0 ms"
    @assert 1.5e-3 <= fit_8.t_dead <= 2.5e-3 "offset $(fit_8.t_dead) s at 8 V outside 1.5–2.5 ms"
    @assert residual < 0.02 "fuel line misses a 14 V pulse by $(100residual) %"
    @assert fit_14.t_open > fit_14.t_dead && fit_8.t_open > fit_8.t_dead
    md"""
    **Offset** $(round(1e3fit_14.t_dead; digits = 3)) ms at 14 V (band 0.6–1.0) and
    $(round(1e3fit_8.t_dead; digits = 3)) ms at 8 V (band 1.5–2.5). **Opening delay**
    $(round(1e3fit_14.t_open; digits = 3)) and $(round(1e3fit_8.t_open; digits = 3)) ms, longer
    than the offset as it must be. **Straight line** within $(round(100residual; digits = 2)) %
    from 2 ms at 14 V (band 2 %).
    """
end

# ╔═╡ 4fad9943-2ca1-44d4-80ba-d8e7f69c9bd1
md"""
### Two dead times

"Dead time" names two different numbers, and they are easy to confuse.

- The **opening delay** is the pickup time `t_on` of slide 45: from the start of the pulse until
  the needle is fully open. It is what the eye sees on the traces.
- The **offset** is where the straight line above meets zero fuel. It is what the ECU adds to
  every pulse (notebook 04), and what the EV14 table lists.

They differ because the needle is also late to close. After the pulse ends it needs the dropout
time `t_off` to return to its seat, and fuel keeps flowing meanwhile. That late fuel pays back
part of the fuel lost while opening, so the offset is shorter than the opening delay. The
expected band, 0.6–1.0 ms at 14 V from the EV14 table, belongs to the offset. The opening delay
lands above that band, at about 1.2 ms at 14 V and 2.8 ms at 8 V, as it should if the table
lists offsets.
"""

# ╔═╡ 9a61b176-7e18-4a1e-b871-3e26f3dd6a72
md"""
## 4 · Why the battery matters

The current through an RL circuit rises toward `U/R` with the time constant `L/R`. The needle
moves when the current reaches the value whose magnetic force beats the spring preload, the
pickup current `i_pick`. The time to get there is

```math
t_\text{pick} = -\frac{L}{R}\,\ln\!\left(1 - \frac{i_\text{pick}\,R}{U_\text{batt}}\right)
```

which grows without bound as `U_batt` falls toward `i_pick R`: a weak battery cannot open the
injector at all. Near the bottom of the slider's range, 8 V, the injector is close to that limit,
which is why the dead time climbs so steeply there; a car cranking on a weak battery lives in
this corner. The slider stops at 8 V because that is where the EV14 table ends. The coil and the
spring are the same at every voltage; only the end point of the current rise moves. That is why
notebook 04's formula carries a battery-voltage correction, and why the correction is a curve
rather than a constant.
"""

# ╔═╡ 4eaab806-1c5d-4760-a76c-8487898925df
begin
    BATTERY = [8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0]
    battery_fits = [dead_time_fit(pulse_sweep(U)) for U in BATTERY]
    EV14_DEAD_TIME = (U = [8.0, 12.0, 14.0, 16.0], t = [2.000, 0.903, 0.800, 0.558])
end

# ╔═╡ 767e17d8-c4c2-4783-b59e-3f871aa8569b
PP.plot(
    [
        PP.scatter(; x = BATTERY, y = [round(1e3f.t_dead; digits = 4) for f in battery_fits],
            mode = "lines+markers", name = "model: offset (intercept of the fuel line)",
            line = PP.attr(width = 3, color = "#1e88e5")),
        PP.scatter(; x = BATTERY, y = [round(1e3f.t_open; digits = 4) for f in battery_fits],
            mode = "lines+markers", name = "model: opening delay t<sub>on</sub>",
            line = PP.attr(width = 2, dash = "dash", color = "#9e9e9e")),
        PP.scatter(; x = EV14_DEAD_TIME.U, y = EV14_DEAD_TIME.t, mode = "markers",
            name = "EV14 table (retailer data, not verified at Bosch)",
            marker = PP.attr(symbol = "diamond", size = 12, color = "#fb8c00")),
    ],
    deck_layout(; xaxis_title = "battery voltage [V]", yaxis_title = "dead time [ms]",
        shapes = [
            PP.attr(type = "rect", x0 = 13.6, x1 = 14.4, y0 = 0.6, y1 = 1.0, fillcolor = "#43a047",
                opacity = 0.15, line_width = 0),
            PP.attr(type = "rect", x0 = 7.6, x1 = 8.4, y0 = 1.5, y1 = 2.5, fillcolor = "#43a047",
                opacity = 0.15, line_width = 0),
        ],
        legend = PP.attr(x = 0.98, xanchor = "right", y = 0.98)))

# ╔═╡ 6ec6c133-8a37-4754-854f-5cb1094bb815
md"""
The green boxes are the expected bands, and they apply to the offset. The model follows the
table's shape, with the offset about 0.1 ms short at 14 and 16 V and 0.3 ms long at 8 V: the
inductance and spring are tuned to the 8 V and 14 V bands, not fitted to every point.
"""

# ╔═╡ 25ed2a9b-1588-4bac-92b2-3a23115670c8
md"""
## 5 · Static flow

The datasheet number is the flow with the needle held fully open at 3 bar: 146 cm³/min for the
smallest EV14. It is the slope of the straight line above, and it is also what flows once the
needle sits on its stop during a long pulse.
"""

# ╔═╡ 928faeb1-a41a-47b4-9eba-a2a3861e68b3
let
    _, mdot = signal(nominal, MDOT_INJ)
    _, x = signal(nominal, LIFT)
    q = maximum(mdot) / RHO_FUEL * 60e6
    q_line = fit_14.slope / RHO_FUEL * 60e6
    @assert abs(q / Q_STATIC - 1) <= 0.05 "static flow $q cm³/min outside 146 ± 5 %"
    @assert abs(q_line / Q_STATIC - 1) <= 0.05 "fuel-line slope $q_line cm³/min outside 146 ± 5 %"
    @assert abs(maximum(x) / LIFT_STOP - 1) <= 0.02 "maximum lift $(maximum(x)) m not within 2 % of the stop"
    md"""
    **Static flow** $(round(q; digits = 1)) cm³/min at full lift, $(round(q_line; digits = 1))
    cm³/min from the slope of the fuel line (band 146 ± 5 %). **Maximum lift**
    $(round(1e3maximum(x); digits = 4)) mm against the 0.05 mm stop: the needle overshoots its stop
    by $(round(100(maximum(x) / LIFT_STOP - 1); digits = 1)) % on impact.
    """
end

# ╔═╡ 7441e392-71c0-4735-bfc5-6337e7e9a8f3
md"""
## 6 · Switching off: the flyback

Slide 45 notes that at switch-off the *"magnetic field is not decreased abruptly"*. The coil's
current cannot stop instantly, and when the switch opens the inductance drives it on by raising
the voltage across the switch, `v = L di/dt`, until something conducts. A bare transistor would
break down. Injector drivers clamp the voltage with a Zener diode, and the clamp level is a
trade-off: a higher clamp dissipates the stored energy faster and closes the needle sooner, at
the price of more stress on the driver. The model's driver has a 60 V Zener with 10 Ω of dynamic
resistance across the transistor *(assumed, the range of a real driver)*, so the switch voltage
jumps to 60 V plus the current's drop across it, then decays with the current.
"""

# ╔═╡ 635f8119-c558-4167-9bf9-10def058aa42
let live = pulse_run(U_batt = u_batt)
    t, v = signal(live, V_SWITCH)
    _, i = signal(live, I_COIL)
    off = activation(live).off
    window = findall(s -> off - 0.3e-3 <= s <= off + 1e-3, t)
    ms = round.(1e3 .* t[window]; digits = 4)
    PP.plot(
        [
            PP.scatter(; x = ms, y = round.(v[window]; sigdigits = 5), mode = "lines", name = "switch voltage [V]",
                line = PP.attr(width = 3, color = "#e53935")),
            PP.scatter(; x = ms, y = round.(i[window]; sigdigits = 5), mode = "lines", name = "current [A]",
                yaxis = "y2", line = PP.attr(width = 3, color = "#1e88e5")),
        ],
        deck_layout(; xaxis_title = "time [ms]", yaxis_title = "switch voltage [V]",
            yaxis2 = PP.attr(title = "current [A]", overlaying = "y", side = "right"),
            shapes = [PP.attr(type = "rect", xref = "paper", x0 = 0, x1 = 1, y0 = 60, y1 = 80,
                fillcolor = "#9e9e9e", opacity = 0.15, line_width = 0)],
            margin = PP.attr(l = 80, r = 80, t = 30, b = 60),
            legend = PP.attr(x = 0.98, xanchor = "right", y = 0.6)))
end

# ╔═╡ 549b38be-b2a5-4081-945d-e571dcfa8e2d
let
    _, v = signal(nominal, V_SWITCH)
    v_peak = maximum(v)
    @assert 60 <= v_peak <= 80 "flyback peak $v_peak V outside a 60–80 V driver clamp"
    md"""
    **Flyback peak** $(round(v_peak; digits = 1)) V at 14 V (a real driver's clamp: 60–80 V).
    """
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
diameter, and the driver's Zener clamp. No manufacturer publishes them. They are set so the
dead time lands in its band, so the dead time this notebook reproduces is a calibration target,
not a prediction. What the model does predict is the shape: the kink, the ballistic region, the
dead time's rise as the battery weakens, and the difference between the opening delay and the
offset.

**Where the tuning had to stretch.** The coil's time constant with the needle seated is
`L/R` = 14.4 mH / 12 Ω = 1.2 ms, twice the 0.3–0.6 ms the design brief expected. With the time
constant held at 0.6 ms, no spring or gap in this model brings the 14 V offset above about
0.45 ms while the injector still opens at 8 V: the needle closes so late that it pays back most of
what it lost opening. A real injector also builds its force through eddy currents in the
magnetic circuit, a delay this model does not have, and the longer time constant stands in for
it.
"""

# ╔═╡ 342e64d9-d669-4613-96e8-2d1953c5a285
md"""
## What this bought us

- An injector opens late because the coil current needs time to reach the force that beats the
  spring. That time is the dead time, and it depends on the battery voltage.
- Once the needle opens fully, the fuel per pulse is a straight line offset by the dead time,
  which is exactly the form notebook 04's formula assumes. That offset is shorter than the
  opening delay, because the needle also closes late. Below it the needle never settles, and the
  formula stops being true.
- The current trace carries a signature of the needle's motion, and the switch-off needs a clamp
  to survive the coil's stored energy.

**Next: 06 — Lambda control and the catalyst.** Feed-forward has now been carried down to the
needle. Everything it still gets wrong lands in the exhaust, where a sensor can see it.
"""

# ╔═╡ 2494fe1f-5b0b-4d04-a1ec-9042cc9b3cb5
details("Model contract: what this notebook reads from the Dyad side", md"""
### `Lecture2.InjectorPulseTransient` (harness `Lecture2.InjectorPulse`)

| Knob | Unit | Default | Values used here | Slider |
|---|---|---|---|---|
| `U_batt` | V | 14 | 8–16 | 8.0:0.5:16.0 |
| `t_pulse` | s | 3e-3 | 0.5–8 ms | – |
| `t_start` | s | 0.5e-3 | 0.5e-3 | – |
| `stop` | s | 6.5e-3 | `t_start + t_pulse + 3e-3` | – |

| Signal read | Path | Unit |
|---|---|---|
| activation | `pulse.y` | – |
| coil current | `injector.solenoid.i` | A |
| needle lift | `injector.lift` | m |
| fuel mass flow | `injector.mdot_f` | kg/s |
| cumulative fuel | `fuel_mass.y` | kg |
| switch voltage | `transistor.v` | V |

### Checks

| Check | Runs | Expected |
|---|---|---|
| pickup kink | 3 ms at 14 V | the current falls while the switch is on and the needle moves |
| dead time and linearity | `t_pulse` 0.5–8 ms at 14 V and 8 V | offset 0.6–1.0 ms at 14 V, 1.5–2.5 ms at 8 V; opening delay longer than the offset; line within 2 % from 2 ms at 14 V |
| static flow and stop | 3 ms at 14 V | 146 cm³/min ± 5 % at full lift and from the line's slope; maximum lift within 2 % of 0.05 mm |
| flyback | 3 ms at 14 V | peak switch voltage 60–80 V |
""")

# ╔═╡ Cell order:
# ╟─5316326f-6f92-4171-ab34-9d07bb1b47a1
# ╠═60e4623c-a261-43fd-a3ad-0d51af35b770
# ╟─4d6a5916-bc8b-4a88-acef-43fb631a9e73
# ╟─7da36eb8-fa97-4c18-9544-dd82a1b7ae3a
# ╟─69961718-ad3c-4ef7-8331-cfbf1d8aa562
# ╠═e1756e70-c6a4-4c7c-9d0d-98124e75842e
# ╠═63f02df0-88ce-4717-b1eb-bcf8a0a85925
# ╟─0e5ba80c-2fa0-4c4e-9cfe-101a4ab959ae
# ╠═7dbe25f0-deca-4742-8413-f1dda9f8256a
# ╟─7d639560-d8cd-4d78-b830-914034943073
# ╠═8c1c165c-82a5-454e-8945-5c2d28534078
# ╟─ef5932bc-7639-4fdd-a1d7-efb6e161cbad
# ╠═dd992532-e951-4654-ab62-8dab247ea04e
# ╠═30acd0d8-e5bb-41da-a66c-3c76b97b2381
# ╟─42b277cd-6a08-49af-891f-789422267d22
# ╟─6ce31197-9830-4e38-b79a-b005ed3a924b
# ╠═a22bb430-31a0-4e52-9aef-69eeeb90407a
# ╠═055e9a18-a622-4b70-918d-48f9782f1c9d
# ╠═68955cb3-5329-4289-8ff7-24dff2c3c635
# ╟─4fad9943-2ca1-44d4-80ba-d8e7f69c9bd1
# ╟─9a61b176-7e18-4a1e-b871-3e26f3dd6a72
# ╠═4eaab806-1c5d-4760-a76c-8487898925df
# ╠═767e17d8-c4c2-4783-b59e-3f871aa8569b
# ╟─6ec6c133-8a37-4754-854f-5cb1094bb815
# ╟─25ed2a9b-1588-4bac-92b2-3a23115670c8
# ╠═928faeb1-a41a-47b4-9eba-a2a3861e68b3
# ╟─7441e392-71c0-4735-bfc5-6337e7e9a8f3
# ╠═635f8119-c558-4167-9bf9-10def058aa42
# ╠═549b38be-b2a5-4081-945d-e571dcfa8e2d
# ╟─2fc120b8-1c13-450f-ad24-f39afb98dcb7
# ╟─342e64d9-d669-4613-96e8-2d1953c5a285
# ╟─2494fe1f-5b0b-4d04-a1ec-9042cc9b3cb5
