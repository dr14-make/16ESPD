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

# ╔═╡ 15aa5900-084c-4b69-a9c7-7253f9d364ae
md"""
# Lecture 2 · 06 — Lambda control and the catalyst

> **The λ loop does not settle. It oscillates on purpose, and the catalyst is what makes that
> acceptable.**

Notebook 04 metered the fuel feed-forward: measure the air, divide by the stoichiometric ratio,
correct for the wall film. Feed-forward gets λ close to 1, but every error in it lands directly in
the exhaust: an injector that flows a little more than its data sheet says, an air-mass sensor
that drifts, fuel vapor from the canister. A three-way catalyst converts CO, HC and NOx at the
same time only in a narrow window around λ = 1, so "close" is not enough. Slide 57: *"Ensure
conversion rate of the catalyzer, must ensure stoichiometric ratio. Mixture formation is followed
up in a control loop."*

Closing that loop brings three surprises:

1. The sensor that closes it can only tell rich from lean, so the controller is a relay, and a
   relay loop never settles (sections 1–3).
2. How fast it oscillates is set by the engine, not by the controller, because the loop delay
   shrinks as the engine speeds up (section 4).
3. The oscillation is harmless because the catalyst stores oxygen, and a second sensor behind
   the catalyst watches that store (sections 5–7).

The notebook ends with a disturbance the loop must reject (canister purge, slide 56) and with the
alternative a modern ECU has: a wideband sensor that measures λ, and a PI controller that does
settle (sections 8–9).

**Model.** `Lecture2.LambdaLoopTransient` holds notebook 03's mean-value engine at a constant
speed on a dynamometer and closes the λ loop around it: notebook 04's fuel metering, the exhaust
transport delay, the upstream λ sensor, the controller, the catalyst and a downstream sensor.
"""

# ╔═╡ cf0ae6af-8f1f-476e-b900-319d31771b59
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
    LambdaLoopTransient = bind_analysis(:LambdaLoopTransient, library; stubs)
    LambdaSensorRampTransient = bind_analysis(:LambdaSensorRampTransient, library; stubs)
    show_dyad = isnothing(stubs) ? Lecture01Support.show_dyad : stubs.show_dyad
end

# ╔═╡ c1e6bfa5-0d0d-4056-bb89-f070ab51142b
md"""
## The loop

The fuel the controller corrects now reaches the sensor only after it has passed through every
part of the plant:

| Stage | What delays it | Model |
|---|---|---|
| injector → cylinder | wall film (x–τ, notebook 04) and the induction stroke, 180° of crank | `WallWetting`, `SpeedScheduledDelay` |
| cylinder → sensor | the exhaust stroke and the gas travel to the sensor | `ExhaustTransport` |
| sensor | the response of the ceramic element | first-order lag `τ_s` |

Both transport delays are tied to crank angle, so they are fixed in degrees, not in seconds:

```math
\theta(\omega) = \frac{\varphi}{\omega} + \theta_0,
\qquad \varphi_\text{ind} = \pi \;(180^\circ),
\qquad \varphi_\text{exh} \approx 3\pi \;(540^\circ)
```

with `θ₀` a speed-independent gas-travel time. A delay that changes with speed cannot be a
fixed-length Padé approximation, so the model uses a chain of first-order lags whose time
constants follow `θ(ω)`. The exhaust angle and `θ₀` are *(assumed)*: no open source gives them,
and they are set so that the injection-to-sensor delay falls in the design band of 0.15–0.35 s at
idle and 0.04–0.10 s at 3000 rpm. Slide 57 names this delay as the loop's limit: *"Limited
control dynamic determined by the sum of response times."*
"""

# ╔═╡ 3abbfad6-ba33-45a3-8d05-f22ea1976eb4
show_dyad("LambdaLoop")

# ╔═╡ bf8b1608-c093-42ea-ae5e-cf4f5340f985
md"""
## 1 · The sensor can only say "rich" or "lean"

$(deck_figure("slide58-sensor-construction.jpeg"; width = 200))

The switching sensor of slide 58 is a thimble of zirconia ceramic with exhaust gas outside and
ambient air inside. Above about 300 °C the ceramic conducts oxygen ions, and the difference in
oxygen partial pressure between its two faces produces a Nernst voltage:

```math
V = \frac{R\,T}{4F}\,\ln\frac{p_{\mathrm{O_2},\text{air}}}{p_{\mathrm{O_2},\text{exh}}}
```

Lean exhaust still carries free oxygen. Rich exhaust carries almost none, so `p_O₂,exh` falls by
many orders of magnitude as λ crosses 1 and the voltage jumps from about 0.1 V to about 0.9 V.
In the slide's words, the sensor "does not actually measure oxygen concentration, but rather the
difference" between the exhaust and the air.

The model replaces the chemistry by the shape of the slide 58 curve:

```math
V_\text{static} = V_\text{lean} + \frac{V_\text{rich}-V_\text{lean}}{2}
\left(1+\tanh\frac{1-\lambda}{w}\right),
\qquad \tau_s\,\dot V = V_\text{static} - V
```

`V_rich = 0.9 V` and `V_lean = 0.1 V` are read off slide 58. `w = 0.005` makes the switch span
λ 0.98–1.02, as the slide's axis does *(derived)*. `τ_s = 0.07 s` is *(assumed)*. No
manufacturer publishes a two-step sensor curve openly, so this one is fitted to the slide, not
to a data sheet.
"""

# ╔═╡ 5d3ada23-a790-4776-8f68-5c3ee9540dd2
show_dyad("LambdaSensorSwitching")

# ╔═╡ 12b7d8af-16c6-40f1-8199-c7b41df659f9
let
    ramp = LambdaSensorRampTransient(lambda_start = 0.96, lambda_stop = 1.04)
    _, λ = signal(ramp, RAMP_LAMBDA)
    _, V = signal(ramp, RAMP_V_SWITCHING)
    p = plot(λ, V; lw = 3, color = :steelblue, label = "model",
        xlabel = "λ", ylabel = "sensor voltage [V]", xlims = (0.96, 1.04), ylims = (0, 1),
        title = figure_title(ramp, "Switching λ sensor characteristic"), legend = :topright)
    vspan!(p, [0.98, 1.02]; color = :gray, alpha = 0.12, label = "slide 58 axis, λ 0.98–1.02")
    hline!(p, [0.45]; color = :gray, ls = :dash, label = "controller threshold V_ref")
    compare(
        deck_figure("slide58-sensor-curve.jpeg"; width = 320),
        captioned(p, """
            Slide 58's curve and the model's. The slide labels the axes in its own text: sensor
            voltage 0, 0.3, 0.6, 0.9 V upward, normalized air–fuel ratio λ 0.98, 1.0, 1.02 to the
            right. The model's characteristic is read from a slow λ ramp through
            `LambdaSensorSwitching`.
            """ * placeholder_note(ramp,
                "`LambdaSensorRampTransient` signals `$RAMP_LAMBDA` and `$RAMP_V_SWITCHING`")))
end

# ╔═╡ aa424799-7244-4e8c-9fd9-8bd95ae966d6
md"""
At λ = 1 the characteristic is as steep as it will ever be:

```math
\left.\frac{dV}{d\lambda}\right|_{\lambda=1} = -\frac{V_\text{rich}-V_\text{lean}}{2w}
```

which is the whole 0.8 V swing for one percent of λ. Two percent away from λ = 1 the slope is
nearly zero. The voltage therefore says which side of λ = 1 the mixture is on, and almost nothing
about how far. The ECU compares it with a threshold `V_ref = 0.45 V` and keeps only the sign. A
controller that knows only the sign of its error is a **relay**.
"""

# ╔═╡ 6f5ca7f5-4c40-4ef2-8d56-9a31f3de1595
md"""
## 2 · A relay can only make a loop oscillate

Put a relay in a loop with a delay and the loop cannot settle. By the time the sensor reports
that a correction has worked, the controller has been pushing the same way for a whole delay,
and the mixture has already overshot to the other side. The sensor flips, the relay flips, and
the same happens in reverse. Lecture 1's tuning notebook (08) met this twice: as the limit cycle
a cruise loop falls into against the engine's torque clamp, and as the relay autotune that
provokes such a cycle on purpose to read the ultimate period.

Since the oscillation cannot be avoided, the controller's job is to keep it small and centered on
λ = 1. The two-step (jump/ramp) controller does that with two moves:

```math
s = \tanh\frac{V - V_\text{ref}}{\varepsilon_V} \approx
\begin{cases} +1 & \text{rich} \\ -1 & \text{lean} \end{cases},
\qquad \dot F_I = -k_\text{ramp}\,s,
\qquad \lambda_\text{trim} = 1 + F_I - k_\text{jump}\,s
```

`λ_trim` multiplies notebook 04's fuel command (the `lambda_trim` input of `FuelMetering`).

- The **ramp** is integral action. It moves the fuel slowly in the direction the sensor asks for,
  and it is what removes a steady error in the feed-forward.
- The **jump** is proportional action, applied at the moment the sensor flips. It takes back at
  once the overshoot the ramp built up during the delay, so the next half-cycle starts near
  λ = 1 instead of far beyond it.

`tanh(·/ε_V)` is a smoothed sign, so the solver does not have to stop at every switch.
`k_jump = 0.03` and `k_ramp = 0.05 /s` are *(assumed)*, tuned for slide 57's "typical variation
2–3 %" at idle.
"""

# ╔═╡ e877c153-eff2-465f-8437-9321c49d8ac8
show_dyad("TwoStepLambdaController")

# ╔═╡ a785ebe6-8cbb-468d-bdca-1e9116bb2133
md"""
### The knobs

**Engine speed** sets the loop delay. **`k_jump`** sets the size of the jump. The check cells use
the default runs (800 rpm, `k_jump = 0.03`), so a slider moves the figures and never a check.
"""

# ╔═╡ 10df2e43-af36-43cd-ab53-4e24a93140a3
md"engine speed [rpm] $(@bind engine_rpm Slider(800:200:4000; default = 800, show_value = true))"

# ╔═╡ 2c81f11c-798e-4b91-8f79-9c2618820237
md"`k_jump` [–] $(@bind k_jump Slider(0.005:0.005:0.06; default = 0.03, show_value = true))"

# ╔═╡ 343f19bc-7f8f-4764-9ef1-b9d1b0b7bd45
begin
    IDLE_RPM = 800
    # Idle runs on the closed throttle's bypass air; above idle a light part-load opening keeps
    # the operating point fired rather than on overrun. Both openings are (assumed).
    U_IDLE, U_PART = 0.0, 0.1
    throttle_at(n) = n <= IDLE_RPM ? U_IDLE : U_PART
    loop_run(n; kwargs...) =
        LambdaLoopTransient(; omega_set = rad_per_s(n), u_thr = throttle_at(n), kwargs...)

    idle = loop_run(IDLE_RPM)
    cruise = loop_run(3000)
    live = loop_run(engine_rpm; k_jump)
end

# ╔═╡ 19166c12-5242-4dea-8714-a1ed88dc5735
md"""
## 3 · Slide 57, regenerated

The Bosch figure on slide 57 stacks the sensor voltage above the controller output, the
"manipulated variable", on one time axis. Below are the same two signals from the model, in the
same order.
"""

# ╔═╡ c35ac0f6-7bcf-47bc-8411-b405b32364ea
let
    window = (6.0, 8.0)
    t, trim = signal(live, LAMBDA_TRIM)
    _, V = signal(live, V_UP)
    p1 = plot(t, V; lw = 2.5, color = :firebrick, label = "", ylabel = "sensor voltage [V]",
        xlims = window, ylims = (0, 1),
        title = figure_title(live, "Two-step λ control at $(engine_rpm) rpm"))
    hline!(p1, [0.45]; color = :gray, ls = :dash, label = "V_ref")
    p2 = plot(t, trim; lw = 2.5, color = :steelblue, label = "", ylabel = "λ_trim",
        xlabel = "time [s]", xlims = window)
    hline!(p2, [1.0]; color = :gray, ls = :dot, label = "")
    compare(
        deck_figure("slide57-two-step.png"; width = 440),
        captioned(plot(p1, p2; layout = (2, 1), size = (560, 440), link = :x), """
            Slide 57 (Bosch, figure 4) and the model: the upstream sensor voltage (top) and the
            controller output `λ_trim`, the manipulated variable (bottom).
            """ * placeholder_note(live,
                "`LambdaLoopTransient` signals `$LAMBDA_TRIM` and `$V_UP`")))
end

# ╔═╡ a591cde2-27bc-4c99-a3c1-24433260018f
md"""
Each time the sensor voltage crosses `V_ref`, the manipulated variable jumps by `2 k_jump` and
then ramps until the sensor crosses back. The sensor's square wave lags the manipulated variable
by the loop delay: the mixture the sensor reports was made one delay earlier. The slide's figure
also shows a pause `t_v` after the jump on one side. That pause is the λ shift of section 5.

What the catalyst receives is the λ in the cylinder, which follows the manipulated variable
inverted (more fuel, smaller λ) and smoothed by the wall film:
"""

# ╔═╡ 6f20fd17-f9ac-45c5-b7d5-879cd9e5911b
let
    window = (6.0, 8.0)
    t, λ = signal(live, LAMBDA_CYL)
    p = plot(t, λ; lw = 2.5, color = :steelblue, label = "λ in the cylinder",
        xlabel = "time [s]", ylabel = "λ", xlims = window, legend = :topright,
        title = figure_title(live, "λ excursion at $(engine_rpm) rpm, k_jump = $(k_jump)"))
    hspan!(p, [0.97, 1.03]; color = :seagreen, alpha = 0.10, label = "slide 57: ±3 %")
    hspan!(p, [0.98, 1.02]; color = :seagreen, alpha = 0.15, label = "slide 57: ±2 %")
    hline!(p, [1.0]; color = :gray, ls = :dot, label = "")
    captioned(p, """
        The green bands are slide 57's "typical variation 2–3 %".
        """ * placeholder_note(live, "`LambdaLoopTransient` signal `$LAMBDA_CYL`"))
end

# ╔═╡ f00db145-70d6-42f0-9705-36dc7b1dc2cc
check("`LambdaLoopTransient` at 800 rpm, signal `$LAMBDA_CYL`", idle) do
    a = limit_cycle(signal(idle, LAMBDA_CYL)...).amplitude
    (0.02 <= a <= 0.03,
        "λ excursion at idle ±$(round(100a; digits = 2)) %, band ±2–3 % (deck slide 57)")
end

# ╔═╡ 97d6ba75-0c1a-485d-850a-01f0d106f757
md"""
## 4 · The period is the plant

Take the ideal loop: a pure delay `θ` between the controller and its own sensor, and nothing
else. Start just after the sensor has switched to "lean" (`s = −1`), with the ramp at its lowest
point `−A`. There are two cases.

**Jump-dominated, `k_jump ≥ k_ramp θ / 2`.** The jump alone already makes the mixture rich, so
the sensor sees it exactly one delay later. Every half-cycle lasts `θ`:

```math
T = 2\theta, \qquad A = \tfrac12 k_\text{ramp}\,\theta,
\qquad \max|\lambda - 1| \approx k_\text{jump} + \tfrac12 k_\text{ramp}\,\theta
```

**Ramp-dominated, `k_jump < k_ramp θ / 2`.** After the jump the mixture is still lean, and the
ramp must carry it across λ = 1 before the delay even starts to run:

```math
T = 4\theta - \frac{4\,k_\text{jump}}{k_\text{ramp}},
\qquad T \to 4\theta \text{ for a pure ramp } (k_\text{jump} \to 0)
```

So the period lies between `2θ` and `4θ`, and the controller gains decide only where in that
range. The delay belongs to the engine: `θ(ω) = φ/ω + θ₀` shrinks as the speed rises, so the loop
oscillates faster at 3000 rpm than at idle whatever the calibration. The excursion, meanwhile,
can never be smaller than `k_jump`: the jump is the price of a short period.

In the model the effective delay is longer than the transport delay alone, because the wall film
and the sensor lag add to it. The plot overlays `2θ` and `4θ` computed from the transport delay,
so expect the measured periods above the `2θ` line.
"""

# ╔═╡ 5eb9d9b3-bc17-489a-afd2-fc17f3cf5499
begin
    SWEEP_RPM = [800, 1200, 1600, 2000, 2500, 3000, 3500, 4000]
    sweep_runs = [loop_run(n) for n in SWEEP_RPM]
    sweep_cycles = [limit_cycle(signal(r, LAMBDA_CYL)...) for r in sweep_runs]
    sweep_delays = [first(last(signal(r, LOOP_DELAY))) for r in sweep_runs]
end

# ╔═╡ d24206e5-dfbc-4b2d-a853-68d7768e3175
let
    p = plot(SWEEP_RPM, [c.period for c in sweep_cycles]; lw = 2.5, marker = :circle,
        color = :steelblue, label = "limit-cycle period T", xlabel = "engine speed [rpm]",
        ylabel = "time [s]", legend = :topright,
        title = figure_title(sweep_runs, "λ limit-cycle period against engine speed"))
    plot!(p, SWEEP_RPM, 2 .* sweep_delays; lw = 2, ls = :dash, color = :gray,
        label = "2θ, jump-dominated")
    plot!(p, SWEEP_RPM, 4 .* sweep_delays; lw = 2, ls = :dot, color = :black,
        label = "4θ, pure ramp")
    captioned(p, """
        Default gains at every speed; θ is the transport delay the harness reports.
        """ * placeholder_note(sweep_runs,
            "`LambdaLoopTransient` swept over `omega_set`, signals `$LAMBDA_CYL` and `$LOOP_DELAY`"))
end

# ╔═╡ f743ae68-8e71-4c96-8531-4298c0f19fb5
let
    rows = map([800, 2000, 3000]) do n
        i = findfirst(==(n), SWEEP_RPM)
        r, c, θ = sweep_runs[i], sweep_cycles[i], sweep_delays[i]
        "| $n | $(measured(() -> θ, r)) | $(measured(() -> c.period, r)) | " *
        "$(measured(() -> c.period / θ, r; digits = 2)) | " *
        "$(measured(() -> c.frequency, r; digits = 2)) | " *
        "$(measured(() -> 100c.amplitude, r; digits = 2)) |"
    end
    Markdown.parse("""
        | engine speed [rpm] | transport delay θ [s] | period T [s] | T / θ | frequency [Hz] | λ excursion [± %] |
        |---:|---:|---:|---:|---:|---:|
        $(join(rows, "\n"))
        """)
end

# ╔═╡ fb976e6a-85a0-4928-868d-fad369537733
check("`LambdaLoopTransient` at 800 and 3000 rpm, signal `$LAMBDA_CYL`", idle, cruise) do
    f_idle = limit_cycle(signal(idle, LAMBDA_CYL)...).frequency
    f_3000 = limit_cycle(signal(cruise, LAMBDA_CYL)...).frequency
    (0.5 <= f_idle <= 5 && 0.5 <= f_3000 <= 5 && f_3000 > f_idle,
        "limit-cycle frequency $(round(f_idle; digits = 2)) Hz at idle and " *
        "$(round(f_3000; digits = 2)) Hz at 3000 rpm; band 0.5–5 Hz, rising with speed")
end

# ╔═╡ 79aca748-5a3a-40aa-8132-58c8cc867c98
md"""
## 5 · Moving the mean: the λ shift

A symmetric limit cycle averages out at the sensor's switching point. That point is close to the
λ the catalyst converts best at, but not necessarily on it, and it moves as the sensor ages.
Slide 57's figure 4 shows the correction: a *"λ shift (delay time t_v) due to pre-control
proportion and post cat control"*. The controller holds off its reaction to one of the two sensor
edges for a dwell time `t_v`. During the dwell the ramp keeps going the old way, so the mixture
spends longer on that side and the mean moves there: (a) shifts rich, (b) shifts lean.

The model moves the mean with **asymmetric jumps** instead: the jump toward rich is larger than
the jump toward lean by `k_jump_shift`. A dwell needs a timer, which a model without discrete
events cannot hold cheaply. Both move the mean; the controller's docstring gives the dwell that
corresponds to a given asymmetry. Which side to shift to, and by how much, is the post-cat
controller's decision (section 7).
"""

# ╔═╡ b4420744-ce01-4db7-9d5c-6f83043f3e5a
begin
    SHIFT = 0.01
    shifted = loop_run(IDLE_RPM; k_jump_shift = SHIFT)
end

# ╔═╡ 3fc32baa-6347-4902-b6c2-27ca701ffc71
let
    window = (4.0, 10.0)
    period = limit_cycle(signal(idle, LAMBDA_CYL)...).period
    t, λ0 = signal(idle, LAMBDA_CYL)
    ts, λs = signal(shifted, LAMBDA_CYL)
    p = plot(t, λ0; lw = 1.5, alpha = 0.5, color = :steelblue, label = "symmetric jumps",
        xlabel = "time [s]", ylabel = "λ", xlims = window, legend = :topright,
        title = figure_title((idle, shifted), "Rich shift by asymmetric jumps, 800 rpm"))
    plot!(p, ts, λs; lw = 1.5, alpha = 0.5, color = :darkorange,
        label = "k_jump_shift = $(SHIFT)")
    plot!(p, t, cycle_mean(t, λ0, period); lw = 3, color = :steelblue, label = "mean over one period")
    plot!(p, ts, cycle_mean(ts, λs, period); lw = 3, color = :darkorange, label = "")
    hline!(p, [1.0]; color = :gray, ls = :dot, label = "")
    compare(
        deck_figure("slide57-two-step.png"; width = 360),
        captioned(p, """
            Thin: λ in the cylinder. Thick: its mean over one limit-cycle period.
            `k_jump_shift = $(SHIFT)` is a demonstration value *(assumed)*.
            """ * placeholder_note((idle, shifted),
                "`LambdaLoopTransient` with `k_jump_shift`, signal `$LAMBDA_CYL`")))
end

# ╔═╡ aec46355-d156-4cc7-9cb2-29dc09881bd3
md"""
## 6 · The catalyst absorbs the oscillation

A three-way catalyst (slide 59) reduces NOx and oxidizes CO and HC on the same precious-metal
surface. Reduction wants exhaust with no spare oxygen, oxidation wants exhaust with some, and the
gas offers each only on its own side of λ = 1. The washcoat therefore carries an oxygen store:
on the lean half of the cycle it soaks up the excess oxygen, on the rich half it gives it back.
As long as the store is neither full nor empty, the gas leaving the catalyst is close to λ = 1
whatever the gas entering it does.

Brandt, Wang and Grizzle model the store with one state, the fraction `θ` of occupied oxygen
sites, integrated and limited to `[0, 1]`:

```math
\dot\theta = \frac{y_{\mathrm{O_2}}\,\dot m_\text{air}}{C}\,\frac{\lambda_\text{in}-1}{\lambda_\text{in}}
\begin{cases}
\alpha_L\, f_L(\theta) & \lambda_\text{in} > 1 \text{ (storing)} \\
\alpha_R\, f_R(\theta) & \lambda_\text{in} < 1 \text{ (releasing)}
\end{cases},
\qquad 0 \le \theta \le 1
```

`ṁ_air (λ − 1)/λ` is the air that found no fuel to burn (negative when rich), and `y_O₂` is the
oxygen mass fraction of air. `f_L` falls from 1 to 0 as the store fills, `f_R` rises from 0 to 1,
and release is faster than storage (`α_R > α_L`). The exact `f_L`, `f_R` come from the paper.
The capacity `C` is *(assumed)* 0.5 g of O₂. What leaves the catalyst is the part the store
could not take:

```math
\lambda_\text{out} - 1 = (\lambda_\text{in} - 1)\,\bigl(1 - f(\theta)\bigr)
```

with `f` the active one of `f_L`, `f_R`.
"""

# ╔═╡ b903d52c-6d71-4550-b4a3-3ef846cf86c8
show_dyad("Catalyst")

# ╔═╡ 441c7164-7138-4535-87e1-39379234b92a
let
    t, λin = signal(idle, LAMBDA_IN)
    _, λout = signal(idle, LAMBDA_OUT)
    _, θ = signal(idle, THETA_CAT)
    p1 = plot(t, λin; lw = 1.5, color = :steelblue, label = "λ entering", ylabel = "λ",
        legend = :topright, title = figure_title(idle, "Catalyst under the limit cycle, 800 rpm"))
    plot!(p1, t, λout; lw = 3, color = :seagreen, label = "λ leaving")
    p2 = plot(t, θ; lw = 3, color = :purple, label = "θ, oxygen sites occupied",
        xlabel = "time [s]", ylabel = "θ", ylims = (0, 1), legend = :topright)
    hspan!(p2, [0.2, 0.8]; color = :gray, alpha = 0.12, label = "check band 0.2–0.8")
    captioned(plot(p1, p2; layout = (2, 1), size = (620, 460), link = :x), """
        The store breathes in and out with each cycle and the gas behind it stays at λ ≈ 1.
        """ * placeholder_note(idle,
            "`LambdaLoopTransient` signals `$LAMBDA_IN`, `$LAMBDA_OUT`, `$THETA_CAT`"))
end

# ╔═╡ 1f48abae-78b5-4453-834b-607dad6d3d65
check("`LambdaLoopTransient` at 800 rpm, signals `$THETA_CAT`, `$V_UP`, `$V_DOWN`", idle) do
    t, θ = signal(idle, THETA_CAT)
    _, v_up = signal(idle, V_UP)
    _, v_down = signal(idle, V_DOWN)
    settled = t .>= last(t) / 2
    swing(v) = maximum(v[settled]) - minimum(v[settled])
    lo, hi = extrema(θ)
    (0.2 < lo && hi < 0.8 && swing(v_down) < swing(v_up) / 4,
        "θ in [$(round(lo; digits = 3)), $(round(hi; digits = 3))], band (0.2, 0.8); " *
        "downstream sensor swing $(round(swing(v_down); digits = 3)) V against upstream " *
        "$(round(swing(v_up); digits = 3)) V, must stay below a quarter of it")
end

# ╔═╡ 3bd8faa6-4870-4807-ad94-399b9693ba74
md"""
## 7 · Why a second sensor

The upstream loop holds the mixture wherever its own sensor switches. If that sensor ages, its
switching point moves and the loop faithfully holds the wrong λ. Nothing upstream can notice: the
controller is doing exactly what it is told.

The second sensor sits behind the catalyst. Slide 57's figure 5 shows two-sensor control (a) and
three-sensor control with one more sensor behind the main catalyst (b); slide 59 lists the
"control system (second oxygen sensor)". While the store absorbs the oscillation, the
downstream sensor reads a steady voltage. When the store fills or empties, oxygen or CO breaks
through, and it switches. A slow integrator on its voltage, the **post-cat trim**, shifts the
upstream loop until the breakthrough stops. That is the "post cat control" in the title of
figure 4.

The experiment: move the upstream sensor's switching point 5 % lean (`lambda_bias = 0.05`, an
*(assumed)* stand-in for an aged sensor) and run for a minute, once without and once with the
post-cat trim.
"""

# ╔═╡ 3639d36d-2d03-4a48-b500-72757e4107b2
show_dyad("PostCatTrim")

# ╔═╡ 2edbdfeb-d4fa-4738-93a0-0cea04102b1e
begin
    BIAS = 0.05
    biased = loop_run(IDLE_RPM; lambda_bias = BIAS, stop = 60.0)
    trimmed = loop_run(IDLE_RPM; lambda_bias = BIAS, with_trim = true, stop = 60.0)
end

# ╔═╡ 233b6ba8-8f27-4159-98c5-27690cbd14b7
let
    t, θb = signal(biased, THETA_CAT)
    tt, θt = signal(trimmed, THETA_CAT)
    _, vb = signal(biased, V_DOWN)
    _, vt = signal(trimmed, V_DOWN)
    p1 = plot(t, θb; lw = 3, color = :firebrick, label = "no trim", ylabel = "θ",
        ylims = (0, 1.05), legend = :bottomright,
        title = figure_title((biased, trimmed), "Upstream sensor biased 5 % lean, 800 rpm"))
    plot!(p1, tt, θt; lw = 3, color = :seagreen, label = "post-cat trim")
    hspan!(p1, [0.2, 0.8]; color = :gray, alpha = 0.12, label = "")
    p2 = plot(t, vb; lw = 2, color = :firebrick, label = "", xlabel = "time [s]",
        ylabel = "downstream sensor [V]", ylims = (0, 1))
    plot!(p2, tt, vt; lw = 2, color = :seagreen, label = "")
    hline!(p2, [0.45]; color = :gray, ls = :dash, label = "V_ref")
    compare(
        deck_figure("slide57-sensor-locations.png"; width = 300),
        captioned(plot(p1, p2; layout = (2, 1), size = (620, 460), link = :x), """
            Slide 57's sensor locations (Bosch, figure 5), and the model's catalyst store and
            downstream sensor with the upstream sensor biased lean.
            """ * placeholder_note((biased, trimmed),
                "`LambdaLoopTransient` with `lambda_bias` and `with_trim`, signals " *
                "`$THETA_CAT`, `$V_DOWN`, `$TRIM_SHIFT`")))
end

# ╔═╡ 7cb65fb9-eb71-4a75-84bd-aa721f8c7b05
check("`LambdaLoopTransient` with `lambda_bias = $(BIAS)`, with and without `with_trim`, " *
      "signals `$THETA_CAT`, `$V_DOWN`", biased, trimmed) do
    _, θb = signal(biased, THETA_CAT)
    _, vb = signal(biased, V_DOWN)
    t, θt = signal(trimmed, THETA_CAT)
    back = first_time(t, 0.2 .< θt .< 0.8)
    saturates = maximum(θb) > 0.95 && minimum(vb) < 0.45
    restored = 0.2 < last(θt) < 0.8 && !isnothing(back)
    (saturates && restored,
        "without trim: max θ $(round(maximum(θb); digits = 3)) (must exceed 0.95), downstream " *
        "minimum $(round(minimum(vb); digits = 3)) V (must fall below 0.45 V); with trim: " *
        "final θ $(round(last(θt); digits = 3)), band (0.2, 0.8), inside from t = $(back) s")
end

# ╔═╡ 8f40c9fe-b17f-4242-905e-22435a36b5f0
md"""
## 8 · A disturbance: canister purge

The fuel tank is sealed, and the vapor it breathes out is caught in a charcoal canister
(slide 56). When the engine runs, a purge valve opens and manifold vacuum draws the vapor into the
intake, where it *"is sucked into the engine cylinder together with the fuel injected from the
injector and air"*. The feed-forward knows nothing about it: purge is unmetered fuel, a step
disturbance at the plant input. How much richer it makes the mixture depends on how loaded the
canister is. The model adds 8 % of the operating fuel flow *(assumed)* at `t = 5 s`.

The two-step loop rejects it with the ramp. In the ideal loop, the cycle-averaged excess `Δ` is
gone after about

```math
t_\text{reject} \approx \theta + \frac{\Delta - k_\text{jump}}{k_\text{ramp}}
```

one delay before the sensor notices, then the jump, then the ramp at `k_ramp` per second. The
ramp rate, not the jump, decides how fast a disturbance goes away, so `k_ramp` trades rejection
speed against the oscillation amplitude of section 4.
"""

# ╔═╡ 263a7bd2-b292-4ad6-9565-07f500dcb20c
begin
    T_PURGE = 5.0
    purge_two_step = loop_run(IDLE_RPM; t_purge = T_PURGE, stop = 15.0)
    purge_wideband = loop_run(IDLE_RPM; t_purge = T_PURGE, with_wideband = true, stop = 15.0)
    idle_period = limit_cycle(signal(idle, LAMBDA_CYL)...).period
end

# ╔═╡ 1664fea9-fe7e-4e5b-bb1d-42740d9895bc
let
    t, λ = signal(purge_two_step, LAMBDA_CYL)
    p = plot(t, λ; lw = 1.5, alpha = 0.6, color = :steelblue, label = "λ in the cylinder",
        xlabel = "time [s]", ylabel = "λ", legend = :bottomright,
        title = figure_title(purge_two_step, "Canister purge step, two-step loop, 800 rpm"))
    plot!(p, t, cycle_mean(t, λ, idle_period); lw = 3, color = :steelblue,
        label = "mean over one period")
    hspan!(p, [0.99, 1.01]; color = :seagreen, alpha = 0.15, label = "±1 %")
    vline!(p, [T_PURGE]; color = :black, ls = :dash, label = "purge valve opens")
    captioned(p, "" * placeholder_note(purge_two_step,
        "`LambdaLoopTransient` with `t_purge`, signal `$LAMBDA_CYL`"))
end

# ╔═╡ 99a2ffa9-6878-4294-b8ea-47ee8e181139
check("`LambdaLoopTransient` with `t_purge = $(T_PURGE)`, signal `$LAMBDA_CYL`",
      purge_two_step, idle) do
    t, λ = signal(purge_two_step, LAMBDA_CYL)
    m = cycle_mean(t, λ, idle_period)
    back = first_time(t, (t .< T_PURGE) .| (abs.(m .- 1) .<= 0.01))
    recovery = isnothing(back) ? Inf : back - T_PURGE
    (recovery < 3,
        "cycle-mean λ back within ±1 % $(round(recovery; digits = 2)) s after the purge " *
        "step; band under 3 s")
end

# ╔═╡ 69f0cb38-a36f-44d3-b9a9-36d0260b06f3
md"""
## 9 · Measuring λ instead: the wideband sensor and PI

A wideband sensor (Bosch LSU 4.9; the "broad-band λ sensor" at position 1 in slide 57's figure 5)
adds a pump cell to the Nernst cell. Its electronics pump oxygen into or out of a small diffusion
gap until the Nernst cell reads λ = 1 there, and the pump current that takes is proportional to
the oxygen excess (lean) or deficit (rich) of the exhaust. So this sensor too measures a current,
not λ, and the ECU converts it through the manufacturer's table. `LambdaSensorWideband` is that
table (Bosch datasheet) and its inverse, plus a first-order lag of 0.1 s *(assumed)*.
"""

# ╔═╡ 5aadd6ba-1267-4325-ae0e-e72a074826c0
let
    ramp = LambdaSensorRampTransient(lambda_start = 0.7, lambda_stop = 1.4)
    _, λ = signal(ramp, RAMP_LAMBDA)
    _, ip = signal(ramp, RAMP_I_PUMP)
    _, λm = signal(ramp, RAMP_LAMBDA_MEAS)
    p1 = plot(λ, ip; lw = 3, color = :steelblue, label = "", xlabel = "λ",
        ylabel = "pump current [mA]", title = figure_title(ramp, "Wideband sensor: what it measures"))
    hline!(p1, [0.0]; color = :gray, ls = :dot, label = "")
    p2 = plot(λ, λm; lw = 3, color = :seagreen, label = "", xlabel = "λ",
        ylabel = "ECU's λ estimate", title = "and what the ECU makes of it")
    plot!(p2, λ, λ; color = :gray, ls = :dot, label = "")
    captioned(plot(p1, p2; layout = (1, 2), size = (700, 300)), """
        A slow λ ramp through `LambdaSensorWideband`: the LSU 4.9 pump-current table, then its
        inverse.
        """ * placeholder_note(ramp,
            "`LambdaSensorRampTransient` signals `$RAMP_I_PUMP` and `$RAMP_LAMBDA_MEAS`"))
end

# ╔═╡ 5385c5c5-f531-4e9d-93e4-bd76f00e37f4
md"""
Now the sensor reports *how far* from λ = 1 the mixture is, so the controller can act in
proportion and the loop can settle. The wideband loop is an ordinary PI on the error
`e = λ_meas − 1` (lean asks for more fuel), with its output clipped:

```math
\lambda_\text{trim} = 1 + k_p\,e + k_i \int e\,dt,
\qquad 0.8 \le \lambda_\text{trim} \le 1.2
```

The delay has not gone away. It still limits how hard the PI may push, exactly as Lecture 1's
transport delay limited the cruise controller; a Smith predictor is the standard way around it.
"""

# ╔═╡ 6b1e85bb-dc33-4017-b567-52f48d30b32a
show_dyad("WidebandLambdaPI")

# ╔═╡ 6eaaec9d-879d-458e-af8f-a1cce16a8c91
let
    t2, λ2 = signal(purge_two_step, LAMBDA_CYL)
    tw, λw = signal(purge_wideband, LAMBDA_CYL)
    p = plot(t2, λ2; lw = 1.5, alpha = 0.6, color = :steelblue, label = "two-step sensor + jump/ramp",
        xlabel = "time [s]", ylabel = "λ in the cylinder", legend = :bottomright,
        title = figure_title((purge_two_step, purge_wideband),
            "Two loops, same purge step, 800 rpm"))
    plot!(p, tw, λw; lw = 3, color = :seagreen, label = "wideband sensor + PI")
    hspan!(p, [0.99, 1.01]; color = :seagreen, alpha = 0.12, label = "±1 %")
    vline!(p, [T_PURGE]; color = :black, ls = :dash, label = "purge valve opens")
    captioned(p, "" * placeholder_note((purge_two_step, purge_wideband),
        "`LambdaLoopTransient` with `with_wideband` and `t_purge`, signals `$LAMBDA_CYL` and `$LAMBDA_MEAS`"))
end

# ╔═╡ 946b6394-2065-49cd-b846-e32a6672a84f
check("`LambdaLoopTransient` with `with_wideband = true`, signal `$LAMBDA_CYL`",
      purge_wideband) do
    t, λ = signal(purge_wideband, LAMBDA_CYL)
    steady = (t .< T_PURGE) .| (t .> T_PURGE + 5)
    worst = maximum(abs.(λ[steady] .- 1))
    (worst <= 0.01,
        "wideband PI: largest steady-state |λ − 1| $(round(100worst; digits = 2)) %, " *
        "band ±1 % (outside the 5 s after the purge step)")
end

# ╔═╡ 27c3c5e1-f467-4b07-aa82-bf8f707acc9f
md"""
## Honest numbers

**From a source.** The switching sensor's 0.1 V and 0.9 V levels and its operating temperature
above 300 °C (deck slide 58). The 2–3 % excursion the loop is tuned to (deck slide 57). The
wideband pump-current table (Bosch LSU 4.9 datasheet). The structure of the catalyst model
(Brandt, Wang and Grizzle).

**Assumed, with no open source.** The exhaust transport angle and `θ₀`, set to land the
injection-to-sensor delay in its design band. The sensor lags. The switching sensor's curve as a
whole, fitted to slide 58 because no manufacturer publishes one. `k_jump`, `k_ramp` and the
shift, tuned to slide 57's band rather than taken from a calibration. The catalyst capacity and
rates. The purge size, the 5 % sensor bias, and the throttle openings of the operating points.

**Design bands, not measurements.** The 0.5–5 Hz frequency band follows from the delay band; it
checks that the model is self-consistent, not that it matches an engine.

The loop only closes once the sensor is above 300 °C. Before that, on a cold start, the ECU runs
on notebook 04's feed-forward alone; notebook 10 follows the warm-up.
"""

# ╔═╡ 1c46f98a-7e21-4652-8852-a7f1c5b47820
md"""
## What this bought us

- The λ loop is a relay loop by necessity, because its sensor only knows the sign of the error.
  It never settles. The jump/ramp controller keeps the oscillation small (never below `k_jump`)
  and centered.
- Its period is set by the engine: the transport delay is fixed in crank angle, so the loop
  speeds up with engine speed, its period between `2θ` and `4θ`.
- The catalyst's oxygen store integrates the oscillation away, and the second sensor watches
  that store, slowly correcting what the first sensor gets wrong.
- The ramp removes a disturbance such as canister purge. A wideband sensor allows a PI loop that
  settles, but the delay still sets how fast.

**Next: 07 — Idle speed control.** The second loop the ECU closes around the same engine, this
time with two actuators, air and spark, that differ in speed and authority as much as the jump
and the ramp do here.
"""

# ╔═╡ f6b6ec01-2407-4652-a730-40ad20243c8b
details("Model contract: what this notebook needs from the Dyad side", md"""
Everything below is requested from Dyad task 5 (`docs/lecture-02-dyad-tasks.md`). Names in
**bold** are not in that spec yet.

### `Lecture2.LambdaLoopTransient` (harness `Lecture2.LambdaLoop`)

| Knob | Unit | Default | Values used here | Slider |
|---|---|---|---|---|
| `omega_set` | rad/s | 83.78 (800 rpm) | 800–4000 rpm | 800:200:4000 rpm |
| `u_thr` | – (0 closed, 1 wide open) | 0.0 | 0.0 at idle, 0.1 above | – |
| `k_jump` | – | 0.03 | 0.03 | 0.005:0.005:0.06 |
| `k_ramp` | 1/s | 0.05 | 0.05 | – |
| **`k_jump_shift`** | – | 0.0 | 0.01 | – |
| **`lambda_bias`** (upstream sensor switching-point offset) | – | 0.0 | 0.05 | – |
| **`with_wideband`** (structural) | Bool | false | true | – |
| **`with_trim`** (structural) | Bool | false | true | – |
| `t_purge` | s | **1000** (no purge within a run) | 5.0 | – |
| `stop` | s | 10 | 10, 15, 60 | – |

| Signal read | Path | Unit |
|---|---|---|
| λ in the cylinder | `engine.lambda_cyl` | – |
| controller output | `controller.lambda_trim` | – |
| controller ramp state | `controller.F_I` | – |
| upstream switching sensor | `sensor_up.V` | V |
| λ into the catalyst | `catalyst.lambda_in` | – |
| λ out of the catalyst | `catalyst.lambda_out` | – |
| oxygen storage | `catalyst.theta` | – |
| downstream switching sensor | `sensor_down.V` | V |
| post-cat trim output | **`post_cat.shift`** | – |
| wideband λ estimate | **`sensor_wb.lambda_meas`** | – |
| injection-to-sensor transport delay | **`loop_delay`** | s |

### **`Lecture2.LambdaSensorRampTransient`** (harness **`Lecture2.LambdaSensorRamp`**)

A slow λ ramp from `lambda_start` to `lambda_stop` over `stop` seconds through one
`LambdaSensorSwitching` and one `LambdaSensorWideband`.

| Knob | Unit | Default | Values used here |
|---|---|---|---|
| `lambda_start` | – | 0.9 | 0.96, 0.7 |
| `lambda_stop` | – | 1.1 | 1.04, 1.4 |
| `stop` | s | 20 | 20 |

Signals: `lambda_src.y` (λ imposed), `switching.V` [V], `wideband.I_p` [mA],
`wideband.lambda_meas`.

### Checks

| Check | Run | Signals | Expected |
|---|---|---|---|
| λ excursion at idle | 800 rpm, defaults | `engine.lambda_cyl` | half peak-to-peak 2–3 % (deck slide 57) |
| limit-cycle frequency | 800 and 3000 rpm | `engine.lambda_cyl` | both 0.5–5 Hz, higher at 3000 rpm |
| catalyst under the limit cycle | 800 rpm | `catalyst.theta`, `sensor_up.V`, `sensor_down.V` | θ inside (0.2, 0.8); downstream swing below ¼ of upstream swing |
| lean bias | 800 rpm, `lambda_bias = 0.05`, 60 s, without and with `with_trim` | `catalyst.theta`, `sensor_down.V` | without: max θ > 0.95 and downstream below 0.45 V; with: final θ inside (0.2, 0.8) |
| purge rejection | 800 rpm, `t_purge = 5`, 15 s | `engine.lambda_cyl` (mean over one idle period) | back within ±1 % in under 3 s |
| wideband steady state | 800 rpm, `with_wideband`, `t_purge = 5`, 15 s | `engine.lambda_cyl` | within ±1 % outside 5–10 s |
""")

# ╔═╡ Cell order:
# ╟─15aa5900-084c-4b69-a9c7-7253f9d364ae
# ╠═cf0ae6af-8f1f-476e-b900-319d31771b59
# ╟─c1e6bfa5-0d0d-4056-bb89-f070ab51142b
# ╠═3abbfad6-ba33-45a3-8d05-f22ea1976eb4
# ╟─bf8b1608-c093-42ea-ae5e-cf4f5340f985
# ╠═5d3ada23-a790-4776-8f68-5c3ee9540dd2
# ╠═12b7d8af-16c6-40f1-8199-c7b41df659f9
# ╟─aa424799-7244-4e8c-9fd9-8bd95ae966d6
# ╟─6f5ca7f5-4c40-4ef2-8d56-9a31f3de1595
# ╠═e877c153-eff2-465f-8437-9321c49d8ac8
# ╟─a785ebe6-8cbb-468d-bdca-1e9116bb2133
# ╠═10df2e43-af36-43cd-ab53-4e24a93140a3
# ╠═2c81f11c-798e-4b91-8f79-9c2618820237
# ╠═343f19bc-7f8f-4764-9ef1-b9d1b0b7bd45
# ╟─19166c12-5242-4dea-8714-a1ed88dc5735
# ╠═c35ac0f6-7bcf-47bc-8411-b405b32364ea
# ╟─a591cde2-27bc-4c99-a3c1-24433260018f
# ╠═6f20fd17-f9ac-45c5-b7d5-879cd9e5911b
# ╠═f00db145-70d6-42f0-9705-36dc7b1dc2cc
# ╟─97d6ba75-0c1a-485d-850a-01f0d106f757
# ╠═5eb9d9b3-bc17-489a-afd2-fc17f3cf5499
# ╠═d24206e5-dfbc-4b2d-a853-68d7768e3175
# ╠═f743ae68-8e71-4c96-8531-4298c0f19fb5
# ╠═fb976e6a-85a0-4928-868d-fad369537733
# ╟─79aca748-5a3a-40aa-8132-58c8cc867c98
# ╠═b4420744-ce01-4db7-9d5c-6f83043f3e5a
# ╠═3fc32baa-6347-4902-b6c2-27ca701ffc71
# ╟─aec46355-d156-4cc7-9cb2-29dc09881bd3
# ╠═b903d52c-6d71-4550-b4a3-3ef846cf86c8
# ╠═441c7164-7138-4535-87e1-39379234b92a
# ╠═1f48abae-78b5-4453-834b-607dad6d3d65
# ╟─3bd8faa6-4870-4807-ad94-399b9693ba74
# ╠═3639d36d-2d03-4a48-b500-72757e4107b2
# ╠═2edbdfeb-d4fa-4738-93a0-0cea04102b1e
# ╠═233b6ba8-8f27-4159-98c5-27690cbd14b7
# ╠═7cb65fb9-eb71-4a75-84bd-aa721f8c7b05
# ╟─8f40c9fe-b17f-4242-905e-22435a36b5f0
# ╠═263a7bd2-b292-4ad6-9565-07f500dcb20c
# ╠═1664fea9-fe7e-4e5b-bb1d-42740d9895bc
# ╠═99a2ffa9-6878-4294-b8ea-47ee8e181139
# ╟─69f0cb38-a36f-44d3-b9a9-36d0260b06f3
# ╠═5aadd6ba-1267-4325-ae0e-e72a074826c0
# ╟─5385c5c5-f531-4e9d-93e4-bd76f00e37f4
# ╠═6b1e85bb-dc33-4017-b567-52f48d30b32a
# ╠═6eaaec9d-879d-458e-af8f-a1cce16a8c91
# ╠═946b6394-2065-49cd-b846-e32a6672a84f
# ╟─27c3c5e1-f467-4b07-aa82-bf8f707acc9f
# ╟─1c46f98a-7e21-4652-8852-a7f1c5b47820
# ╟─f6b6ec01-2407-4652-a730-40ad20243c8b
