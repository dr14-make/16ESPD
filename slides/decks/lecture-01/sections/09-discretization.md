---
routeAlias: discretization
layout: section
---

###### Notebook 09

# Discretization

The same controller gets worse purely because it looks less often.

`notebooks/lecture01/09-discretization.ipynb`

<!--
**Say:** everything we have designed today is continuous. Nothing you will ever ship is. This
section is the bridge, and it uses the gains we just derived in section 08 — same controller,
nothing re-tuned.

**Timing:** 8 minutes, and no build: this section is a demo on the reference
`SampledCruiseLoop`. Students watch; their own controller stays continuous. The sample-time
sweep is the slide that carries the point.
-->

---

## A digital controller does nothing, most of the time

<div class="grid grid-cols-2 gap-8">
<div>

Every sample period, in order:

1. read the sensors
2. compute
3. command the actuators
4. **hold that command, and do nothing at all, until the next tick**

</div>
<div>

> **The part that matters**
>
> Step four. Between ticks the actuator is holding a decision made with old information, and the
> plant has moved on since. Everything in this section follows from that.

</div>
</div>

<!--
**Say:** an analog controller is changing its output continuously and smoothly. A digital one
changes it in steps and then stops thinking. If the steps are small enough and frequent enough,
nobody can tell the difference — and that is the whole engineering question: how fast is fast
enough?

**Say:** digital control brings other effects too — quantization, and the transport delay of
the computation itself. We are only going to look at sample time, because it is the one that
will bite you first.

**Terms, if anyone asks**

- **Sample time T<sub>s</sub>** — the interval between one update and the next, seconds.
- **Sample rate** — its reciprocal, in Hz.
- **Zero-order hold** — holding the last commanded value constant until the next tick. The
  staircase.
- **Quantization** — the other digital effect, from finite word length. Real, and not our
  subject today.
-->

---

## The strobe light

<div class="grid grid-cols-2 gap-8">
<div>

You have to walk a winding corridor.

- **Lights on:** you can see everything as it happens and correct continuously. You could run.
- **Fast strobe:** indistinguishable from the lights being on. Still running.
- **One flash a second:** you slow right down.
- **One flash every few seconds:** you walk into a wall.

</div>
<div>

> **The point of the analogy**
>
> The corridor never changed. Your *information rate* did. And the correct response to less
> information is to move more cautiously — which for a controller means *lower gains*.

</div>
</div>

<!--
**Say it as a story, not as a diagram.** Walk a couple of steps while you describe it. The
room remembers this one.

**Ask the room:** if the strobe slows down, what do you do differently? *(Slow down. Everyone
says it. Then: that is exactly what re-tuning for a slower sample rate means — the fix at the
end of this section is not clever, it is the obvious thing you already said.)*

**They get wrong:** assuming a slow loop is merely less responsive. It is not — it goes
*unstable*. Less information does not degrade the loop gently; past a point it destroys it.
-->

---

## The same gains, at four sample times

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [09-discretization.ipynb · cell The sample-time sweep]
Scenarios = VehicleSystemsComponents.Lecture1
SPEED = "loop.plant.v_kmh"
V_START, SETPOINT, UNLIMITED = 90.0, 110.0, 1.0e6

# Notebook 08's gains and the measurement they came from, restated
# rather than imported: this notebook is its own kernel.
K_ZN, TI_ZN, TD_ZN = 67.41, 1.092, 0.273
KU, PU = 114.59, 2.185          # N.m per km/h, s

# `Ts` is structural: it defines the periodic clock and the
# discrete controller sample time. Build one model per rate.
sampled(Ts; k = K_ZN, Ti = TI_ZN, Td = TD_ZN) =
    Scenarios.SampledCruiseStep(; name = :SampledCruiseStep, Ts = Ts,
        with_I = true, with_D = true, wd = 0.0, k = k, Ti = Ti, Td = Td,
        v_lo = V_START, v_hi = SETPOINT,
        T_max = UNLIMITED, y_max = UNLIMITED)

problem(Ts; kw...) =
    ODEProblem(mtkcompile(sampled(Ts; kw...)), [], (0.0, 120.0))
solve_at(Ts; kw...) = solve(problem(Ts; kw...))

# The problems are kept, not just their solutions: the next cell
# re-solves the one at Ts = 1 s with different gains.
problems = [Ts => problem(Ts) for Ts in [0.01, 0.1, 0.4, 1.0]]
runs = [Ts => solve(p) for (Ts, p) in problems]
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/09-discretization.ipynb)

*Overshoot grows. Then the loop rings. Then it does not come back.*

</div>
<div>

![Four step responses at increasing sample time: peak speed and persistent ringing increase as the controller update rate slows.](/figures/09-sample-time-family.svg)

*One car and one standard-form gain set. Only the sample and update rate changes.*

</div>
</div>

<!--
**Point at** the fastest run and say: this is the best the sampled controller does here. Do not
claim it matches section 08's continuous run: even the fastest run overshoots far more, probably
because this demo leaves its discrete derivative unseeded. The lesson is the trend across the
family.

**Then walk out along the family** and name each failure as it appears: overshoot, ringing,
divergence.

**Say:** nothing was re-tuned. Nobody touched a gain. The controller that was correct at ten
milliseconds is dangerous at one second, and it is the same controller.

**Ask the room:** which sample time would you pick for a cruise control? *(Steer towards the
reasoning rather than a number: fast compared with what? The plant's time constant is about a
minute; the loop's own bandwidth is seconds. That second number is the one that matters.)*

**Readout — every symbol on this slide**

- **T<sub>s</sub> = 0.01, 0.1, 0.4, 1.0 s** — the sweep.
- **k_zn, Ti_zn, Td_zn** — the Ziegler-Nichols gains from section 08, untouched. Nothing is
  re-tuned.
- **Ringing** — oscillation that decays, but slowly. **Diverging** — it does not decay at all.
-->

---

## What you are looking at

> **A genuine sampled-data loop**
>
> A periodic clock samples the reference and speed, a **DiscretePIDStandard** updates once per
> tick, and a zero-order hold keeps its torque command constant until the next tick.

<div class="grid grid-cols-2 gap-8">
<div>

- **Sampler:** continuous signals become clocked values.
- **Discrete PID:** integral and derivative terms use discrete update equations.
- **Zero-order hold:** the continuous car receives a staircase command.

</div>
<div>

![A staircase torque command held between one-second controller updates, with continuous vehicle speed overlaid.](/figures/09-held-command.svg)

*The command changes only at ticks; the car moves continuously between them.*

</div>
</div>

<!--
**Point at the signal chain.** The car remains continuous. Only sensing, control computation
and command updates occur on the clock.

**Say:** the car can move between ticks, but the applied torque cannot change until the next
controller update. That held command is where the staircase comes from.

**Ask the room:** why can this still be approximated as half a sample of delay near crossover?
*(Because a zero-order hold delays the average command. Next slide.)*
-->

---

## The sampled loop, in Studio

![SampledCruiseLoop: a periodic clock drives two samplers on the setpoint and the measured speed, a DiscretePIDStandard controller, and a zero-order hold feeding the GradeCar plant.](/img/lecture-01/step09-sampler.png)

*Demo only · `SampledCruiseLoop` · clock → samplers → `DiscretePIDStandard` → hold → `plant`*

**Open in Dyad** `dyad/Lecture1/SampledCruiseLoop.dyad`

<!--
**Demo, not a build.** Open `SampledCruiseLoop` in the lecturer's Studio; students do not
reproduce it. The plant is the same `HandsOn.GradeCar` they have been driving all lecture, so
the only new things on the screen are on the controller's side.

**Walk the diagram left to right:**

- `clock` — `DiscreteComponents.PeriodicClock(dt = Ts)`. One tick every `Ts`; 0.1 s by
  default.
- `setpoint_sampler` and `measurement_sampler` — `DiscreteComponents.Sampler`. The setpoint
  and `plant.v_kmh` become clocked values. Point out that the clock wire joins the setpoint
  sampler's output and the controller: that one connection puts the whole controller on the
  clock.
- `controller` — `DiscreteComponents.DiscretePIDStandard`, the library's discrete PID, with
  `K`, `Ti`, `Td`, `Nd`, `Ts`. Not the students' `CruiseController`: the point is what any
  sampled controller does, and this one ships with the library.
- `hold` — `DiscreteComponents.ZeroOrderHold`. The staircase from the previous slide is its
  output.
- `plant` — continuous, untouched.

**Say:** `Ts` is a structural parameter, because it defines the clock. Changing it is a
recompile, which is why the notebook builds one model per sample time.

**If anyone asks how to put their own controller on a clock:** the same two samplers and the
hold, around a discrete controller. The diagram on the screen is the template.
-->

---

## Why it goes unstable

<div class="grid grid-cols-2 gap-8">
<div>

A zero-order hold delays the average command by about half a sample period, so at frequency
$\omega$ it costs

$$
\Delta\varphi \;\approx\; -\,\frac{\omega\,T_s}{2} \ \text{rad}
$$

Phase margin is a finite budget that your tuning already spent most of.

- Spend a little: more overshoot.
- Spend most of it: the loop rings.
- Spend all of it: it does not recover.

</div>
<div>

> **A rule of thumb worth keeping**
>
> Spend at most about 0.2 rad — roughly 12° — of phase on sampling at the loop's crossover
> frequency $\omega_c$. That is $T_s < 0.4/\omega_c$: sample some **20 to 30 times faster** than
> the closed-loop bandwidth, not than the plant.

</div>
</div>

<!--
**Say:** this is the same currency as the dead time in section 01. The engine's transport
delay was the reason this plant could be driven to sustained oscillation at all; sampling adds
more of exactly the same thing, only this time *we* added it, by choosing a cheaper processor.
Delay is delay, whether it comes from fuel injection or from a scheduler. Your loop has a
fixed tolerance for it and every source draws on the same account.

**Say:** and notice the ordering. Overshoot first, ringing next, then divergence. That
ordering is a diagnostic — if a loop that used to be fine starts overshooting after a software
change, ask what happened to the loop rate before you touch a gain.

**Readout — every symbol on this slide**

- **Δφ ≈ −ωT<sub>s</sub>/2** — the phase a zero-order hold costs, in radians, at frequency ω.
- **ω** — angular frequency, rad/s. **ω<sub>c</sub>** — the crossover frequency: where the
  loop gain passes through 1, and the frequency at which phase margin is measured.
- **Phase margin** — how much extra phase lag the loop can absorb before it oscillates. A
  budget, measured in degrees.
- **The rule of thumb** — spend at most 0.2 rad (≈12°) on sampling: T<sub>s</sub> &lt;
  0.4/ω<sub>c</sub>, i.e. 20–30× the *closed-loop bandwidth*, not the plant's time constant.
- **Bandwidth** — roughly, the fastest thing the closed loop can follow.
-->

---

## Two fixes

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [09-discretization.ipynb · cell The fixes]
# Fix one — sample faster, standard-form settings untouched.
faster = solve_at(0.05)

# Fix two — reduce closed-loop bandwidth for the available rate.
# This conservative discrete tuning is verified at Ts = 1 s.
retuned_slow = solve_at(1.0; k = 20.0, Ti = 3.0, Td = 0.5)
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/09-discretization.ipynb)

*Re-tuning buys back stability, not performance. The slow loop is a slower loop, permanently.*

</div>
<div>

![Two responses at the same slow sample time: the original gains ringing badly, and the re-tuned gains settling smoothly but noticeably slower than the continuous design.](/figures/09-retuned.svg)

*Same slow rate, two gain sets. The re-tuned one is stable — and slower than the design we started from.*

</div>
</div>

<!--
**Point at** the re-tuned curve and then, from memory, at where the continuous design sat.
The gap between them is what the cheap processor cost.

**Say:** this is a real design conversation and it happens on every project. Faster loop rate
means more expensive hardware, more power, more heat. Slower means less performance. Somebody
has to put a number on that trade, and it is usually the control engineer, because nobody else
can.

**Ask the room:** is there a third option? *(Yes — a better discrete design rather than a
continuous design converted. That is a course of its own, and it is why the conversion method
matters.)*

**Readout — every symbol on this slide**

- **Faster sampling** — reduces measurement-to-actuation delay without changing the
  standard-form settings.
- **Conservative re-tuning** — reduces bandwidth so the one-second update rate consumes less
  phase margin.
- **Re-tuning buys stability, not the original bandwidth** — the slow loop remains slower.
-->

---

## So why design in continuous time at all?

- The mathematics is easier and far better tooled.
- The plant is continuous anyway — the car does not tick.
- Modeling plant and controller in the same domain keeps the problem simple.

### Design continuous. Convert. **Then verify that the rate you actually have held up** — which is the plot we just made.

<!--
**Say:** it is the same argument as using a linear model for a nonlinear plant. We work where
the tools are good and then we check the approximation, rather than working where it is hard
and being right from the start. The checking is not optional; it is the price of the shortcut.

**Say:** this notebook keeps the standard-form k, T<sub>i</sub> and T<sub>d</sub> values, then
implements the integral with forward Euler and the filtered derivative with backward Euler.
Other conversion methods produce different discrete coefficients; verification at the deployed
rate is still required.
-->

---

## What this bought us

- A loop that we broke without touching a single gain.
- The reason: sampling costs phase, and phase margin is a budget.
- A workflow: design continuous, convert, verify the rate.

### Next: the tire is an actuator too. <Link to="wheel-and-slip">→ 10, wheel and slip</Link>

<!--
**Say:** last section. The controller is finished; now the car changes underneath it.
-->
