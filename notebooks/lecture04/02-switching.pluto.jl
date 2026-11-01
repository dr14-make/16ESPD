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

# ╔═╡ b7fb221f-fa13-49f7-8168-74b2164a27fa
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, "..", ".."))
    include(joinpath(@__DIR__, "..", "lecture01", "support.jl"))
    using .Lecture01Support
    # The dyad-3.5 kernel ships Plots with the plotly backend and Kaleido, but not GR.
    VehicleSystemsComponents = setup(backend = :plotly)
    using ModelingToolkit, Plots
    using DyadInterface: symbolic_container
    using PlutoUI
end

# ╔═╡ 463c7f1a-8bcf-459a-bbd6-2f5bab4a6475
md"""
# Lecture 4 — Power electronics, switched

The car in this lecture carries an **average** converter: `V_out = d·V_in`, with no switching
at all, because a WLTC run lasts 1800 s and a switching edge lasts a microsecond (plan S4: never
stack time scales). This notebook puts the switching back, on two small circuits that run for a
few milliseconds beside the car, and regenerates deck 7's power-electronics slides from them:

| section | deck 7 | model |
|:---|:---|:---|
| 1. Step-down chopper: ripple and losses | slide 28 | `Vehicle.Electric.BuckChopper` |
| 2. H-bridge: square wave | slide 30 | `Vehicle.Electric.HBridge` |
| 3. Pulse-width modulation and harmonics | slide 31 | `Vehicle.Electric.HBridge` |

Slide 29 (the boost converter) and slide 32 (the three-phase bridge) have no switched model
here; their figures are circuit diagrams and stay theory.

Every number below is read from a simulation of the Dyad models shown.
"""

# ╔═╡ 196c917c-6e07-4f95-9bbe-689adf079f6e
md"""
## The switch

The standard library has no switch, so a power transistor here is a resistance that the gate
moves between `R_on` = 10 mΩ and `R_off` = 1 MΩ. Two details turn that idea into a model that
shows the deck's losses:

- **The transition takes time.** The gate command `g` ramps from 0 to 1 over `t_sw`, and the
  resistance follows geometrically, `R = R_off (R_on/R_off)^g`. While it sweeps through the
  middle of its range, the switch carries current *and* holds voltage: that overlap is the
  **switching loss**, a fixed energy per edge, so it grows with the switching frequency. A
  switch that jumped would switch for free.
- **The switch has an output capacitance** `C_oss` = 1 nF. A real switch node slews through it,
  and so must the simulated one: without it, the solver has to jump the node between the diode's
  drop and the supply in one algebraic step at every turn-on, and at ordinary tolerances it
  fails on the second pulse.

While fully on the switch burns `R_on i²`, the deck's `R_DSon × I²` **conduction loss**.
"""

# ╔═╡ 51796cc3-c6d9-4541-9bdd-af08fc881fe6
show_dyad("Switch")

# ╔═╡ 70ba4fbb-8d27-4a8c-8a0f-608992d3bddc
md"""
## Pulse-width modulation

The gate signal comes from comparing the duty command `u` with a triangular **carrier** at the
switching frequency `f_s`: the switch is on while the carrier is below `u`, so over each period
it is on for the fraction `u` of the time. The edges are ramps of `t_sw`, centered on the
crossings.
"""

# ╔═╡ 66040faf-e6be-4ccf-b0cc-0cd8e055ef47
show_dyad("PWM")

# ╔═╡ 2bd2d021-277c-4c9f-8d59-fbba4dbf75bb
md"""
### How the notebook reads a switching run

Two conventions matter, and the cell below holds them.

- **Average power is integrated over the solver's own steps** (trapezoid rule). The solver lands
  steps all through each switching edge, so this resolves the nanosecond loss pulses. Sampling
  a fixed time grid misses them, and interpolating between steps misreads the fast currents that
  charge the switches' capacitance; at 10 kHz both overstate the H-bridge loss several times.
- **Spectra are computed directly** from the definition, on a 1 µs grid over exactly two cycles
  of 50 Hz, so every line falls on the 25 Hz grid and nothing leaks between lines.

Plotted traces are the solver's points, thinned only where a point lies within a small fraction
of the axis (0.01 A, 0.5 V) of the line through its neighbours.
"""

# ╔═╡ fb532565-4103-4098-ae57-6b6aa18dc1d5
begin
    E4 = VehicleSystemsComponents.Vehicle.Electric

    "Time average of `x` over [t1, t2]: trapezoid over the solver steps, ends interpolated."
    function window_mean(sol, x, t1, t2)
        t, y = sol.t, sol[x]
        k = findall(τ -> t1 < τ < t2, t)
        tt = vcat(t1, t[k], t2)
        yy = vcat(sol(t1, idxs = x), y[k], sol(t2, idxs = x))
        return sum((yy[1:end-1] .+ yy[2:end]) ./ 2 .* diff(tt)) / (t2 - t1)
    end

    "Average of the power `P` over [t1, t2], split by the gate `g`: fully on, switching, off."
    function switch_split(sol, P, g, t1, t2)
        t, p, gg = sol.t, sol[P], sol[g]
        on = trans = off = 0.0
        for k in 1:length(t)-1
            (t[k] >= t1 && t[k+1] <= t2) || continue
            e = (p[k] + p[k+1]) / 2 * (t[k+1] - t[k])
            if gg[k] >= 1 && gg[k+1] >= 1
                on += e
            elseif gg[k] <= 0 && gg[k+1] <= 0
                off += e
            else
                trans += e
            end
        end
        return (; on = on / (t2 - t1), trans = trans / (t2 - t1), off = off / (t2 - t1))
    end

    "The solver's points of `x` inside [t1, t2], with the ends interpolated."
    function trace(sol, x, t1, t2)
        k = findall(τ -> t1 < τ < t2, sol.t)
        return vcat(t1, sol.t[k], t2), vcat(sol(t1, idxs = x), sol[x][k], sol(t2, idxs = x))
    end

    """
    Drop the points of a polyline that lie within `tol` (vertically) of the line through the
    points kept around them (Douglas-Peucker). Every simulated point stays within `tol` of
    the drawn line, so nothing the solver produced is hidden or invented.
    """
    function thin(t, y; tol)
        n = length(t)
        keep = falses(n)
        keep[1] = keep[n] = true
        stack = [(1, n)]
        while !isempty(stack)
            i, j = pop!(stack)
            j - i < 2 && continue
            k, dmax = 0, 0.0
            for m in i+1:j-1
                yl = t[j] == t[i] ? y[i] : y[i] + (y[j] - y[i]) * (t[m] - t[i]) / (t[j] - t[i])
                d = abs(y[m] - yl)
                d > dmax && ((k, dmax) = (m, d))
            end
            if dmax > tol
                keep[k] = true
                push!(stack, (i, k), (k, j))
            end
        end
        return t[keep], y[keep]
    end

    "Shade [x1, x2] × [lo, hi] on a subplot."
    shade!(sp, x1, x2, lo, hi; color = :gold, alpha = 0.2) =
        plot!(sp, Shape([x1, x2, x2, x1], [lo, lo, hi, hi]); color, fillalpha = alpha,
            linealpha = 0, label = "")

    "Complex amplitudes of `x` at the frequencies `fs` over the run's window [t1, t2)."
    function spectrum(h, x, fs)
        ts = range(h.t1, h.t2; step = 1e-6)[1:end-1]
        v = h.sol(ts, idxs = x).u
        return [(f == 0 ? 1 : 2) * sum(v[k] * cis(-2π * f * (ts[k] - h.t1)) for k in eachindex(v)) /
                length(v) for f in fs]
    end

    "The 50 Hz component of `x` as a function of time."
    function fundamental(h, x)
        c = only(spectrum(h, x, [50.0]))
        return t -> abs(c) * cos(2π * 50 * (t - h.t1) + angle(c))
    end

    """
    Run `Vehicle.Electric.BuckChopperTransient` and average over the whole switching periods
    in its last half millisecond, by which time the 0.14 ms start-up has died away.
    """
    function run_buck(; d = 0.3, f_s = 20e3, kwargs...)
        r = E4.BuckChopperTransient(; d, f_s, dtmax = min(1e-6, 0.05 / f_s), kwargs...)
        C = symbolic_container(r).chopper
        t2 = r.sol.t[end]
        t1 = t2 - max(1, round(Int, 0.5e-3 * f_s)) / f_s
        P(x) = window_mean(r.sol, x, t1, t2)
        sw = switch_split(r.sol, C.P_switch, C.pwm.y, t1, t2)
        iL = r.sol(range(t1, t2; length = 100_001), idxs = C.i_L).u
        return (; sol = r.sol, C, d, f_s, t1, t2,
            I = sum(iL) / length(iL), ripple = maximum(iL) - minimum(iL), V_out = P(C.v_out),
            P_in = P(C.P_in), P_out = P(C.P_out), P_diode = P(C.P_diode),
            P_winding = P(C.P_winding), P_conduction = sw.on, P_switching = sw.trans + sw.off)
    end

    """
    Run `Vehicle.Electric.HBridgeTransient` and keep the window of two whole cycles from 20 ms,
    after the load current's 1 ms offset has decayed.
    """
    function run_hbridge(; m = 0.8, f_s = 1e3, kwargs...)
        r = E4.HBridgeTransient(; m, f_s, dtmax = min(10e-6, 0.1 / f_s), kwargs...)
        B = symbolic_container(r).bridge
        t1, t2 = 0.02, 0.06
        P(x) = window_mean(r.sol, x, t1, t2)
        return (; sol = r.sol, B, m, f_s, t1, t2,
            P_dc = P(B.P_dc), P_ac = P(B.P_ac), P_loss = P(B.P_loss))
    end
end

# ╔═╡ df3a8bf3-db51-414a-b70f-8a5392e120a8
md"""
## 1. The step-down chopper (slide 28)

```
  48 V --- switch ---+--- inductor --- winding ---+
                     |                            |
                   diode                        load 0.7 Ω
                     |                            |
   0 V --------------+----------------------------+
```

While the switch is on, the supply drives current through the inductor into the load. When it
opens, the inductor keeps the current flowing, and the **freewheeling diode** gives it a path.
The inductor current therefore never stops; it rises while the switch is on and falls while it
is off, around an average set by the duty cycle `d`: the switch node averages `d·V_in`. The
design point is a 48 V to 13 V converter of about 250 W at 20 kHz (assumed), the kind of
non-isolated converter that feeds a 12 V bus from a 48 V mild-hybrid battery.

The diode is the standard library's exponential diode: 0.6 V at 3.3 A, rising to 0.8 V at 20 A,
the deck's "0.6 × I".
"""

# ╔═╡ 178ef64c-1023-41e7-93aa-15910855ff3c
show_dyad("BuckChopper")

# ╔═╡ d1997359-00c8-4ae9-8b3d-bf00e40f2e9b
md"""
### Experiment

**Duty cycle** `d`, the fraction of each period the switch is on:
"""

# ╔═╡ 178bbcb0-e003-41ff-bff0-c90026a872a7
@bind duty Slider(0.1:0.05:0.9; default = 0.3, show_value = true)

# ╔═╡ 0a98b8e4-1d1b-4b1a-93f6-daae3c5741ad
md"""
**Switching frequency** $(@bind f_buck Select([5e3 => "5 kHz", 10e3 => "10 kHz", 20e3 => "20 kHz", 50e3 => "50 kHz", 100e3 => "100 kHz"]; default = 20e3))
"""

# ╔═╡ 196a08db-d2b8-447e-b9c3-940b7b4fd52f
buck = run_buck(d = duty, f_s = f_buck);

# ╔═╡ 73398ebf-b276-4178-be66-e692e172d0ae
md"""
### Three currents

The deck's three traces, three periods in steady state. The supply delivers current only while
the switch is on (shaded); the diode carries it while the switch is off; the load sees their
sum, a continuous current with a ripple.
"""

# ╔═╡ 8ed9e4a6-8f65-45ac-8521-c71c357f3f0b
buck_currents_plot = let b = buck
    T = 1 / b.f_s
    t1, t2 = b.t2 - 3T, b.t2
    rows = ((b.C.transistor.i, "source (switch) [A]"), (b.C.diode.i, "diode [A]"),
        (b.C.i_L, "load [A]"))
    ymax = 1.15 * maximum(b.sol(range(t1, t2; length = 2001), idxs = b.C.i_L).u)
    p = plot(layout = (3, 1), size = (960, 620), legend = false, link = :x)
    for (k, (x, label)) in enumerate(rows)
        t, y = trace(b.sol, x, t1, t2)
        tt, yy = thin(t, y; tol = 0.01)
        for j in 0:2
            shade!(p[k], (((1 - b.d) / 2, (1 + b.d) / 2) .+ j) .* T .* 1e6..., -0.05ymax, ymax)
        end
        plot!(p[k], (tt .- t1) .* 1e6, yy; lw = 2.5, color = :steelblue, ylabel = label,
            ylims = (-0.05ymax, ymax), xlims = (0, 3T * 1e6))
    end
    plot!(p[1]; title = "Buck chopper, three switching periods: switch on (shaded) and off")
    xlabel!(p[3], "time [µs]")
    p
end

# ╔═╡ fad8609c-7faf-4eea-9bc3-9f692a05130a
let b = buck
    r1(x) = round(x; digits = 1)
    r2(x) = round(x; digits = 2)
    loss = b.P_in - b.P_out
    Markdown.parse("""
    | quantity | value |
    |:---|---:|
    | textbook output, `d·V_in` | $(r1(b.d * 48)) V |
    | simulated output | $(r2(b.V_out)) V |
    | load current, mean | $(r2(b.I)) A |
    | ripple, peak to peak | $(r2(b.ripple)) A ($(round(Int, 100b.ripple / b.I)) % of the mean) |
    | power in / out | $(r1(b.P_in)) W / $(r1(b.P_out)) W |
    | **efficiency** | **$(r1(100b.P_out / b.P_in)) %** |
    | losses: diode, winding, conduction, switching | $(r2(b.P_diode)), $(r2(b.P_winding)), $(r2(b.P_conduction)), $(r2(b.P_switching)) W |
    | losses summed against input minus output | $(r2(b.P_diode + b.P_winding + b.P_conduction + b.P_switching)) W against $(r2(loss)) W |

    The output sits below `d·V_in` by the diode's drop during the off time, the resistive drops,
    and a little lost duty: the switch node rises late in each turn-on ramp and falls early in
    each turn-off ramp, because the resistance has to fall below `V/I` before the voltage
    follows.
    """)
end

# ╔═╡ 74ba3fc3-32d1-4cb7-88fa-784db089c260
buck_losses_plot = let b = buck
    names = ["switching", "conduction, R_on i²", "winding, R_L i²", "diode, ≈ 0.8 V × i"]
    vals = [b.P_switching, b.P_conduction, b.P_winding, b.P_diode]
    eta = 100 * b.P_out / b.P_in
    p = bar(1:4, vals; orientation = :horizontal, bar_width = 0.6,
        color = [:darkorange, :steelblue, :seagreen, :firebrick], legend = false,
        xlabel = "average loss [W]", size = (960, 400), yticks = (1:4, names), ylims = (0.4, 4.6),
        xlims = (0, 1.25maximum(vals)),
        title = "Buck chopper losses at $(round(Int, b.P_out)) W out: efficiency $(round(eta; digits = 1)) %")
    annotate!(p, [(v + 0.02maximum(vals), i, text("$(round(v; digits = 2)) W", 10, :left))
                  for (i, v) in enumerate(vals)])
    p
end

# ╔═╡ 47459729-3b43-454e-9068-1615e6fe2573
md"""
The deck lists four losses, and each is a part of the model with its own power. At the design
point the **diode is the largest**: 0.8 V against a 13 V output, for 70 % of every period. That
is why low-voltage converters replace the diode with a second switch (synchronous
rectification), which drops 10 mΩ × 19 A = 0.2 V instead. The winding comes second, then the
switch: its switching loss already exceeds its conduction loss at 20 kHz.
"""

# ╔═╡ 7433ba23-7db5-4f72-93bc-244e9c56b511
buck_sweep = [run_buck(d = duty, f_s = f) for f in (5e3, 10e3, 20e3, 50e3, 100e3)];

# ╔═╡ c5856c79-e759-4edf-b042-7e85adcee5fa
buck_frequency_plot = let sweep = buck_sweep
    f = [b.f_s for b in sweep] ./ 1e3
    rip = [b.ripple for b in sweep]
    eta = [100 * b.P_out / b.P_in for b in sweep]
    psw = [b.P_switching for b in sweep]
    rest = [b.P_conduction + b.P_winding + b.P_diode for b in sweep]
    ticks = (f, string.(round.(Int, f)))
    k20 = findfirst(==(20.0), f)
    p = plot(layout = (1, 2), size = (960, 440), legend = (0.58, 0.62))
    plot!(p[1], f, rip[k20] .* f[k20] ./ f; ls = :dash, lw = 1.5, color = :gray, label = "")
    plot!(p[1], f, rip; marker = :circle, lw = 2.5, color = :steelblue, label = "",
        xscale = :log10, xticks = ticks, xlabel = "switching frequency [kHz]",
        ylabel = "current ripple, peak to peak [A]", title = "Ripple falls as 1 / f_s (dashed)")
    plot!(p[2], f, psw; marker = :circle, lw = 2.5, color = :darkorange, label = "switching")
    plot!(p[2], f, rest; marker = :square, lw = 2.5, color = :gray,
        label = "diode, winding, conduction", xscale = :log10, xticks = ticks,
        xlabel = "switching frequency [kHz]", ylabel = "average loss [W]",
        ylims = (0, 1.15maximum(vcat(psw, rest))),
        title = "Losses: efficiency $(round(eta[1]; digits = 1)) % at $(ticks[2][1]) kHz, $(round(eta[end]; digits = 1)) % at $(ticks[2][end]) kHz")
    p
end

# ╔═╡ c4e0960a-9cea-4dba-91e3-b43595774bf1
let s = buck_sweep
    r1(x) = round(x; digits = 1)
    r2(x) = round(x; digits = 2)
    rows = join(("| $(round(Int, b.f_s / 1e3)) | $(r2(b.ripple)) | $(r2(b.P_switching)) | $(r1(100b.P_out / b.P_in)) |" for b in s), "\n")
    Markdown.parse("""
    ### The designer's trade-off

    The ripple is the inductor's volt-seconds, `ΔI = (V_out + V_diode)(1 − d)/(L f_s)`: double the
    frequency and it halves, or the inductor can be half the size. The switching loss is a fixed
    energy per edge, so it doubles instead. Between them sits the choice of switching frequency,
    and better switches (shorter edges) move it up.

    | f_s [kHz] | ripple [A] | switching loss [W] | efficiency [%] |
    |---:|---:|---:|---:|
    $rows

    The other losses fall a little with frequency only because the edges take a larger share of
    each period, which trims the effective duty and with it the current.
    """)
end

# ╔═╡ 8244054c-9765-4b5d-b8df-c94ea2e5c113
md"""
### A faster switch

The switching loss is a fixed energy per edge, proportional to the edge time `t_sw`. A faster
device, a wide-bandgap (SiC or GaN) transistor in place of a silicon one, shortens the edge. The
same sweep is rerun below with the edge five times shorter, `t_sw` = 0.1 µs instead of the
default 0.5 µs, everything else unchanged; the run overrides only that one parameter of the
chopper.
"""

# ╔═╡ 444749ed-79f5-45c7-8e46-497f62f60600
T_SW_FAST = 0.1e-6;

# ╔═╡ c79e229c-f9d5-4172-aad9-56d860629df5
buck_sweep_fast = let
    spec = E4.BuckChopperTransient__Spec()
    t_sw = ModelingToolkit.toggle_namespacing(spec.model, false).chopper.t_sw
    [run_buck(d = duty, f_s = b.f_s, __overrides = Dict(t_sw => T_SW_FAST)) for b in buck_sweep]
end;

# ╔═╡ b9e88eeb-b18d-4697-8ac1-a2c2682b01c4
faster_switch_plot = let
    f = [b.f_s for b in buck_sweep] ./ 1e3
    ticks = (f, string.(round.(Int, f)))
    p = plot(layout = (1, 2), size = (960, 440), legend = false)
    for (sweep, lbl, c) in ((buck_sweep, "t_sw = 0.5 µs", :darkorange), (buck_sweep_fast, "t_sw = 0.1 µs", :seagreen))
        psw = [b.P_switching for b in sweep]
        eta = [100 * b.P_out / b.P_in for b in sweep]
        plot!(p[1], f, psw; marker = :circle, lw = 2.5, color = c)
        plot!(p[2], f, eta; marker = :circle, lw = 2.5, color = c)
        # Plotly places annotations on a log axis by the exponent.
        annotate!(p[1], [(log10(f[end - 1]), psw[end - 1], text(lbl * "  ", 10, c, :right, :bottom))])
        annotate!(p[2], [(log10(f[end - 1]), eta[end - 1], text(lbl * "  ", 10, c, :right, :top))])
    end
    plot!(p[1]; xscale = :log10, xticks = ticks, xlabel = "switching frequency [kHz]",
        ylabel = "switching loss [W]", title = "Switching loss: a fifth of the edge, a fifth of the loss")
    plot!(p[2]; xscale = :log10, xticks = ticks, xlabel = "switching frequency [kHz]",
        ylabel = "efficiency [%]", title = "Efficiency: the faster switch can switch faster")
    p
end

# ╔═╡ 4cf9f054-7c10-458b-b291-441fcc83720f
let
    r1(x) = round(x; digits = 1)
    r2(x) = round(x; digits = 2)
    rows = join(("| $(round(Int, a.f_s / 1e3)) | $(r2(a.P_switching)) | $(r2(b.P_switching)) | $(r1(100a.P_out / a.P_in)) | $(r1(100b.P_out / b.P_in)) |"
                 for (a, b) in zip(buck_sweep, buck_sweep_fast)), "\n")
    Markdown.parse("""
    | f_s [kHz] | switching loss, 0.5 µs [W] | switching loss, 0.1 µs [W] | η, 0.5 µs [%] | η, 0.1 µs [%] |
    |---:|---:|---:|---:|---:|
    $rows

    The switching loss scales with the edge time. With the faster switch the chopper can run
    at a higher frequency, with a smaller inductor and less ripple, for the efficiency the slow
    switch had at a low one. The diode's loss does not change: it is the same diode.
    """)
end

# ╔═╡ 4810296a-23f7-4bb4-89e1-e4941891fdb2
md"""
## 2. The H-bridge (slide 30)

```
  p ---+--------------+          A, B: upper switches
       A              B          C, D: lower switches
  a ---+              +--- b     each with a freewheeling diode across it
       C              D          the load, 10 Ω + 10 mH, goes from a to b
  n ---+--------------+
```

Four switches turn the DC link into AC. With **A and D on**, `a` sits at the positive rail and
`b` at the negative one: the load sees `+V_dc`. With **B and C on** it sees `−V_dc`. The DC link
is the Leaf pack's 350 V (Nissan); the load is a motor-winding-like R-L (assumed).

Holding each pair on for a whole half cycle gives a **square wave**, as on slide 30. Here that is
the PWM of section 3 with its reference pushed far beyond 1 (`m = 20`), so the pulses merge.
"""

# ╔═╡ d5786319-b328-45cb-a85b-a4b3e6587ed3
show_dyad("HBridge")

# ╔═╡ 3c6d67ba-e58b-4080-9b3a-f48e5d2e6747
square = run_hbridge(m = 20.0);

# ╔═╡ 57c41acd-6707-47b2-a3f3-18a5b6668bba
hbridge_square_plot = let h = square
    t1, t2 = h.t1, h.t2
    p = plot(layout = (2, 1), size = (960, 540), legend = false, link = :x)
    rows = ((h.B.v_ab, "output voltage v_ab [V]", 0.5, 420), (h.B.i_ab, "load current [A]", 0.02, 42))
    for (k, (x, label, tol, lim)) in enumerate(rows)
        for j in 0:1
            shade!(p[k], (t1 + j * 0.02) * 1e3, (t1 + j * 0.02 + 0.01) * 1e3, -lim, lim;
                color = :steelblue, alpha = 0.10)
            shade!(p[k], (t1 + j * 0.02 + 0.01) * 1e3, (t1 + (j + 1) * 0.02) * 1e3, -lim, lim;
                color = :firebrick, alpha = 0.10)
        end
        t, y = trace(h.sol, x, t1, t2)
        tt, yy = thin(t, y; tol)
        plot!(p[k], tt .* 1e3, yy; lw = 2.5, color = :black, ylabel = label, ylims = (-lim, lim),
            xlims = (t1, t2) .* 1e3)
    end
    for j in 0:1
        annotate!(p[1], (t1 + j * 0.02 + 0.005) * 1e3, 385, text("A and D on", 10, :center, :steelblue))
        annotate!(p[1], (t1 + j * 0.02 + 0.015) * 1e3, 385, text("B and C on", 10, :center, :firebrick))
    end
    plot!(p[1]; title = "H-bridge in square-wave operation, 350 V into 10 Ω + 10 mH at 50 Hz")
    xlabel!(p[2], "time [ms]")
    p
end

# ╔═╡ efcbe3d1-2420-4af6-8430-f089007d7420
let h = square
    A = abs.(spectrum(h, h.B.v_ab, [50.0, 150.0, 250.0]))
    i = h.sol(range(h.t1, h.t2; length = 40_001), idxs = h.B.i_ab).u
    i_steady = 350 / 10 * tanh(0.02 / 4 / 1e-3)
    r1(x) = round(x; digits = 1)
    Markdown.parse("""
    Each half cycle the current climbs towards `V_dc / R` = 35 A with the load's time constant
    `L / R` = 1 ms, and reaches $(r1(maximum(i))) A (the square-wave response predicts
    $(r1(i_steady)) A). The square wave carries the largest fundamental a bridge can make,
    `4 V_dc / π` = $(r1(4 * 350 / π)) V (simulated $(r1(A[1])) V), but every odd harmonic comes
    with it: the 3rd at $(round(A[2] / A[1]; digits = 3)) of the fundamental, the 5th at
    $(round(A[3] / A[1]; digits = 3)), as `1/n` predicts. A motor driven like this sees them as
    torque ripple and extra losses, which is what pulse-width modulation removes.
    """)
end

# ╔═╡ 5160ab5f-06d1-4a46-bf9c-af58b9f1680e
md"""
## 3. Pulse-width modulation and harmonics (slide 31)

To make a sine instead, the bridge switches fast and varies the pulse width along the cycle. The
gate pattern is the deck's: while the wanted voltage `u = m sin(2π·50 t)` is positive, **D stays
on and A pulses** with duty `u`; while it is negative, **B stays on and C pulses**. When the
pulsing switch is off, the current freewheels through the diode below (or above) it and the
switch that stays on, so the output pulses between 0 and `±V_dc`. Averaged over one carrier
period it is `u·V_dc`.

**Modulation index** `m`, the amplitude of the reference:
"""

# ╔═╡ 3931e513-0bb7-4de8-ad28-5fa1642d2c9d
@bind m_index Slider(0.1:0.1:1.0; default = 0.8, show_value = true)

# ╔═╡ 602ead73-b2eb-4f55-b757-7626044c9e14
md"""
**Carrier (switching) frequency** $(@bind f_carrier Select([1e3 => "1 kHz, as on slide 31", 2e3 => "2 kHz", 5e3 => "5 kHz", 10e3 => "10 kHz, a real inverter"]; default = 1e3))
"""

# ╔═╡ 65174300-c3c8-4324-98a2-cf86d411979a
pwm = run_hbridge(m = m_index, f_s = f_carrier);

# ╔═╡ 26883db2-06b5-4dc3-b887-b6f107263cf0
pwm_gates_plot = let h = pwm
    t1, t2 = h.t1, h.t1 + 0.02
    p = plot(layout = grid(5, 1; heights = [0.28, 0.18, 0.18, 0.18, 0.18]), size = (960, 700),
        legend = false, link = :x)
    t, c = trace(h.sol, h.B.pwm_a.carrier, t1, t2)
    tc, cc = thin(t, c; tol = 1e-3)
    plot!(p[1], tc .* 1e3, cc; color = :gray, lw = 1)
    t, u = trace(h.sol, h.B.u, t1, t2)
    tu, uu = thin(t, abs.(u); tol = 1e-3)
    plot!(p[1], tu .* 1e3, uu; color = :black, lw = 2.5, ylabel = "|u|, carrier", ylims = (0, 1.05),
        title = "Sine PWM at $(round(Int, h.f_s / 1e3)) kHz, m = $(h.m): A pulses and D holds while u > 0, C pulses and B holds while u < 0")
    switches = ((h.B.switch_a, "A", :steelblue), (h.B.switch_d, "D", :steelblue),
        (h.B.switch_c, "C", :firebrick), (h.B.switch_b, "B", :firebrick))
    for (k, (sw, name, color)) in enumerate(switches)
        t, g = trace(h.sol, sw.g, t1, t2)
        tg, gg = thin(t, g; tol = 1e-3)
        plot!(p[k+1], tg .* 1e3, gg; color, lw = 2, ylims = (-0.1, 1.15),
            yticks = ([0, 1], ["off", "on"]), ylabel = name)
    end
    xlabel!(p[5], "time [ms], one cycle at 50 Hz")
    p
end

# ╔═╡ 932f9481-9f40-4dae-a898-c0a9aaab43be
pwm_current_plot = let h = pwm
    t1, t2 = h.t1, h.t1 + 0.02
    p = plot(layout = (2, 1), size = (960, 560), legend = false, link = :x)
    rows = ((h.B.v_ab, "output voltage v_ab [V]", 0.5, :gray, 1),
        (h.B.i_ab, "load current [A]", 0.02, :black, 2.5))
    for (k, (x, label, tol, color, lw)) in enumerate(rows)
        t, y = trace(h.sol, x, t1, t2)
        tt, yy = thin(t, y; tol)
        plot!(p[k], tt .* 1e3, yy; color, lw, ylabel = label)
        F = fundamental(h, x)
        tf = range(t1, t2; length = 401)
        plot!(p[k], tf .* 1e3, F.(tf); color = :darkorange, lw = 2, ls = :dash)
    end
    V1 = abs(only(spectrum(h, h.B.v_ab, [50.0])))
    I1 = abs(only(spectrum(h, h.B.i_ab, [50.0])))
    plot!(p[1]; title = "Output: pulses between 0 and ±350 V; fundamental (dashed) $(round(Int, V1)) V, current $(round(I1; digits = 1)) A")
    xlabel!(p[2], "time [ms], one cycle at 50 Hz")
    p
end

# ╔═╡ cd1a03c0-690c-4c23-b1eb-c348c63c0486
md"""
### The spectrum

The deck: *any periodic waveform can be represented by the addition of harmonics to a
fundamental sine wave*. The pulse train's spectrum shows what PWM does with them: the
fundamental is the wanted `m·V_dc`, and the unwanted energy is pushed up to the carrier
frequency and its multiples, in clusters of sidebands. There the load's inductance is a large
impedance (`2π f L` = 63 Ω at 1 kHz against 3 Ω at 50 Hz), so the current is nearly a clean sine.
"""

# ╔═╡ 9dbd68c2-aced-419d-b835-f6d368056389
pwm_spectrum_plot = let h = pwm
    fs = collect(0.0:25.0:5h.f_s)
    V = abs.(spectrum(h, h.B.v_ab, fs))
    I = abs.(spectrum(h, h.B.i_ab, fs))
    p = plot(layout = (2, 1), size = (960, 560), legend = false, link = :x)
    plot!(p[1], fs ./ 1e3, V; seriestype = :sticks, lw = 2, color = :steelblue, ylabel = "|V_ab| [V]",
        title = "Spectrum over two cycles: fundamental at 50 Hz, switching harmonics around multiples of $(round(Int, h.f_s / 1e3)) kHz")
    plot!(p[2], fs ./ 1e3, I; seriestype = :sticks, lw = 2, color = :firebrick, ylabel = "|I| [A]",
        xlabel = "frequency [kHz]")
    k1 = findfirst(==(50.0), fs)
    kc = findfirst(==(h.f_s - 50), fs)
    annotate!(p[1], 0.02h.f_s / 1e3, V[k1], text("  $(round(Int, V[k1])) V at 50 Hz", 9, :left))
    annotate!(p[2], 0.02h.f_s / 1e3, I[k1], text("  $(round(I[k1]; digits = 1)) A at 50 Hz", 9, :left))
    annotate!(p[1], fs[kc] / 1e3, V[kc] + 25,
        text("f_s ± 50 Hz: $(round(Int, V[kc])) V, $(round(Int, V[kc+4])) V", 9, :center))
    annotate!(p[2], fs[kc] / 1e3, I[kc] + 2.5,
        text("$(round(I[kc]; digits = 1)) A, $(round(I[kc+4]; digits = 1)) A: the inductance filters", 9, :left))
    p
end

# ╔═╡ f05047e5-e8ba-4fb2-8945-332191ac4619
let h = pwm
    fs = [50.0, 150.0, 250.0, 350.0, h.f_s - 50, h.f_s + 50]
    V = spectrum(h, h.B.v_ab, fs)
    I = spectrum(h, h.B.i_ab, fs)
    Z = 10 + im * 2π * 50 * 10e-3
    lag = rad2deg(angle(V[1]) - angle(I[1]))
    r1(x) = round(x; digits = 1)
    r2(x) = round(x; digits = 2)
    Markdown.parse("""
    | line | voltage | current |
    |:---|---:|---:|
    | fundamental, 50 Hz | $(r1(abs(V[1]))) V (`m·V_dc` = $(r1(h.m * 350)) V) | $(r2(abs(I[1]))) A (`m·V_dc` over $(r2(abs(Z))) Ω = $(r2(h.m * 350 / abs(Z))) A), lagging $(r1(lag))° |
    | f_s − 50 Hz | $(r1(abs(V[5]))) V | $(r2(abs(I[5]))) A |
    | f_s + 50 Hz | $(r1(abs(V[6]))) V | $(r2(abs(I[6]))) A |
    | 3rd, 5th, 7th | $(r1(abs(V[2]))), $(r1(abs(V[3]))), $(r1(abs(V[4]))) V | $(r2(abs(I[2]))), $(r2(abs(I[3]))), $(r2(abs(I[4]))) A |

    The bridge loses $(r1(h.P_loss)) W of $(round(Int, h.P_dc)) W drawn, $(r1(100h.P_ac / h.P_dc)) %
    efficient.

    **Where the 3rd, 5th and 7th come from.** They are not the carrier's; they are this gate
    pattern meeting an inductive load. The current lags the voltage by $(round(Int, lag))°, so for
    that long after each zero crossing it still flows the old way. In the positive half, with A
    off, a negative current cannot freewheel through C's diode: it flows up through A's diode
    instead and puts the output at the full rail, whatever the reference asks. With a nearly
    resistive load the three lines fall to a tenth of a volt (see the `switching` tests). Real
    inverters switch both transistors of a leg in turn, so the gates, not the diodes, decide the
    output.
    """)
end

# ╔═╡ 61c20cf9-6fe5-4912-ba4c-652766811c18
carrier_runs = [run_hbridge(m = m_index, f_s = f) for f in (1e3, 10e3)];

# ╔═╡ 83b7a0dd-31cc-422e-8c10-58b79c0c12b8
pwm_carrier_plot = let runs = carrier_runs
    t1, t2 = runs[1].t1, runs[1].t1 + 0.02
    p = plot(layout = (2, 1), size = (960, 560), legend = false, link = :all)
    for (k, h) in enumerate(runs)
        t, y = trace(h.sol, h.B.i_ab, t1, t2)
        tt, yy = thin(t, y; tol = 0.02)
        F = fundamental(h, h.B.i_ab)
        tf = range(t1, t2; length = 401)
        fs = collect(0.0:25.0:5h.f_s)
        I = abs.(spectrum(h, h.B.i_ab, fs))
        ripple = maximum(I[fs .> 0.5h.f_s])
        plot!(p[k], tt .* 1e3, yy; color = :black, lw = 2, ylabel = "load current [A]")
        plot!(p[k], tf .* 1e3, F.(tf); color = :darkorange, lw = 2, ls = :dash,
            title = "Carrier $(round(Int, h.f_s / 1e3)) kHz: largest switching harmonic $(round(ripple; digits = 2)) A, losses $(round(h.P_loss; digits = 1)) W")
    end
    xlabel!(p[2], "time [ms], one cycle at 50 Hz")
    p
end

# ╔═╡ 6cbdf5ac-e94f-4c82-93f4-dd17fcb16127
md"""
### The carrier frequency

Ten times the carrier frequency puts the switching harmonics ten times higher, where the
inductance is ten times the impedance: the current ripple falls about tenfold, and the motor's
current is a sine to the eye. The price is ten times as many edges, so the switching loss rises;
an EV inverter settles at 5 to 20 kHz, above hearing and below the point where switching loss
dominates. The deck's warning stands for what is left: *higher frequency harmonics can increase
the iron losses* in the motor, because eddy currents grow with frequency.

## What these models leave out

- **Diode reverse recovery.** The library diode stops conducting the instant its voltage
  reverses; a real one first conducts backwards for a moment, which adds to the turn-on loss.
- **Dead time.** The deck's gate pattern never turns on both switches of a leg, so it needs
  none; a complementary pattern would.
- **The switching-loss shape.** The resistance ramp gives `2 V I t_sw / ln(R_off/R_on)` per edge,
  the textbook `V I t / 2` of an edge 0.22 `t_sw` long. `t_sw` is therefore an effective edge
  time, not a datasheet one.
- **Heat.** The switches dissipate into a fixed temperature; nothing warms up.
- **The DC link** is a stiff source. A real one is a capacitor that the ripple current flows
  through.

In the car all of this collapses into the average converter, `V_out = d·V_in` with an
efficiency, which is what the switched runs above justify: they settle in a millisecond, and
a drive cycle lasts half an hour.
"""

# ╔═╡ Cell order:
# ╟─463c7f1a-8bcf-459a-bbd6-2f5bab4a6475
# ╠═b7fb221f-fa13-49f7-8168-74b2164a27fa
# ╟─196c917c-6e07-4f95-9bbe-689adf079f6e
# ╟─51796cc3-c6d9-4541-9bdd-af08fc881fe6
# ╟─70ba4fbb-8d27-4a8c-8a0f-608992d3bddc
# ╟─66040faf-e6be-4ccf-b0cc-0cd8e055ef47
# ╟─2bd2d021-277c-4c9f-8d59-fbba4dbf75bb
# ╠═fb532565-4103-4098-ae57-6b6aa18dc1d5
# ╟─df3a8bf3-db51-414a-b70f-8a5392e120a8
# ╟─178ef64c-1023-41e7-93aa-15910855ff3c
# ╟─d1997359-00c8-4ae9-8b3d-bf00e40f2e9b
# ╟─178bbcb0-e003-41ff-bff0-c90026a872a7
# ╟─0a98b8e4-1d1b-4b1a-93f6-daae3c5741ad
# ╠═196a08db-d2b8-447e-b9c3-940b7b4fd52f
# ╟─73398ebf-b276-4178-be66-e692e172d0ae
# ╠═8ed9e4a6-8f65-45ac-8521-c71c357f3f0b
# ╟─fad8609c-7faf-4eea-9bc3-9f692a05130a
# ╠═74ba3fc3-32d1-4cb7-88fa-784db089c260
# ╟─47459729-3b43-454e-9068-1615e6fe2573
# ╠═7433ba23-7db5-4f72-93bc-244e9c56b511
# ╠═c5856c79-e759-4edf-b042-7e85adcee5fa
# ╟─c4e0960a-9cea-4dba-91e3-b43595774bf1
# ╟─8244054c-9765-4b5d-b8df-c94ea2e5c113
# ╠═444749ed-79f5-45c7-8e46-497f62f60600
# ╟─c79e229c-f9d5-4172-aad9-56d860629df5
# ╟─b9e88eeb-b18d-4697-8ac1-a2c2682b01c4
# ╟─4cf9f054-7c10-458b-b291-441fcc83720f
# ╟─4810296a-23f7-4bb4-89e1-e4941891fdb2
# ╟─d5786319-b328-45cb-a85b-a4b3e6587ed3
# ╠═3c6d67ba-e58b-4080-9b3a-f48e5d2e6747
# ╠═57c41acd-6707-47b2-a3f3-18a5b6668bba
# ╟─efcbe3d1-2420-4af6-8430-f089007d7420
# ╟─5160ab5f-06d1-4a46-bf9c-af58b9f1680e
# ╟─3931e513-0bb7-4de8-ad28-5fa1642d2c9d
# ╟─602ead73-b2eb-4f55-b757-7626044c9e14
# ╠═65174300-c3c8-4324-98a2-cf86d411979a
# ╠═26883db2-06b5-4dc3-b887-b6f107263cf0
# ╠═932f9481-9f40-4dae-a898-c0a9aaab43be
# ╟─cd1a03c0-690c-4c23-b1eb-c348c63c0486
# ╠═9dbd68c2-aced-419d-b835-f6d368056389
# ╟─f05047e5-e8ba-4fb2-8945-332191ac4619
# ╠═61c20cf9-6fe5-4912-ba4c-652766811c18
# ╠═83b7a0dd-31cc-422e-8c10-58b79c0c12b8
# ╟─6cbdf5ac-e94f-4c82-93f4-dd17fcb16127
