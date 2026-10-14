---
routeAlias: discretization
layout: section
---

###### Notebook 09

# Discretization

The same controller gets worse when it reads the speed less often.

`notebooks/lecture01/09-discretization.ipynb`

<!--
Everything we designed today is continuous: the controller reacts at every instant. A controller
you ship runs on a computer. It reads the speed only at fixed intervals and computes a new command
each time. That is called discrete. Discretization means turning the first kind into the second.
This section connects the two, with the gains from section 08. Same controller, nothing re-tuned.

This is a demo, not a build. Your own controller stays continuous. The demo runs on the reference
model, `SampledCruiseLoop`.
-->

---

## What a digital controller does each sample period

<div class="grid grid-cols-2 gap-8">
<div>

Every sample period, in order:

1. read the sensors
2. compute
3. command the actuators
4. **hold that command, and do nothing at all, until the next tick**

</div>
<div>

> **Step four causes the problems**
>
> Between ticks the actuator holds a decision made with old information, and the plant has moved
> on since. The effects in this section come from this.

</div>
</div>

<!--
A digital controller changes its output in steps, and holds each value until the next update. If
the steps are small and frequent enough, nobody can tell the difference. The question is how fast
is fast enough.

The sample time, T s, is the interval between updates, in seconds. The sample rate is one over
that: updates per second, in hertz. A zero-order hold keeps the last command constant until the
next tick. That is the staircase.

Digital control also brings rounding, because a computer stores numbers with limited digits, and
the delay of the computation itself. Both are real, but today we look only at sample time, because
it usually causes problems first.
-->

---

## An analogy: walking under a strobe light

<div class="grid grid-cols-2 gap-8">
<div>

You have to walk a winding corridor.

- **Lights on:** you can see everything as it happens and correct continuously. You could run.
- **Fast strobe:** indistinguishable from the lights being on. Still running.
- **One flash a second:** you slow right down.
- **One flash every few seconds:** you walk into a wall.

</div>
<div>

> **What the analogy shows**
>
> The corridor did not change. You only got *information less often*. The correct response to
> less information is to move more cautiously, which for a controller means *lower gains*.

</div>
</div>

<!--
Picture yourself walking a winding corridor. With the lights on, you correct continuously, and you
could run. A fast strobe is no different. One flash a second, and you slow right down. One flash
every few seconds, and you walk into a wall.

If the strobe slows down, you slow down. Re-tuning for a slower sample rate means the same thing:
lower gains. The fix at the end of this section is that simple.

A slow loop is not only less responsive. Below some sample rate, it goes **unstable**.
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

*As the sample time grows, the overshoot grows, then the loop rings, then it diverges.*

</div>
<div>

![Four step responses at increasing sample time: peak speed and persistent ringing increase as the controller update rate slows.](/figures/09-sample-time-family.svg)

*One car and one standard-form gain set. Only the sample and update rate changes.*

</div>
</div>

<!--
Look at the fastest run first. It does not match the continuous run from section 08. That one
peaked at about 119 km/h; this one peaks at about 151. This demo starts its discrete controller
less carefully than section 08 did, so ignore the absolute numbers. What matters is the trend
across the four runs.

The sweep is T s equal to 0.01, 0.1, 0.4 and 1.0 seconds, with the Ziegler-Nichols gains from
section 08: k 67.41, T i 1.092, T d 0.273. No gain was changed. The torque limit stays lifted, so
only the sampling differs.

As the sample time grows, the overshoot grows first. The peaks are about 151, 157 and 182 km/h.
Then the loop rings: it oscillates and decays slowly. At one second it peaks at about 203 km/h and
does not settle: over the last 20 seconds of the run it still swings by 3.6 km/h. The controller
that was correct at ten milliseconds is dangerous at one second.

So which sample time would you pick for a cruise control? Fast compared with what? The plant's time
constant is about a minute. The closed-loop bandwidth, roughly the fastest change the loop can
follow, is on the scale of seconds. That second number is the one that matters. With these gains,
0.05 seconds, twenty updates a second, works: we use it as a fix in three slides.
-->

---

## The sampled-data loop

> **A sampled-data loop**
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
The car stays continuous. Only the sensing, the computation and the command updates happen on the
clock.

The car moves between ticks, but the torque cannot change until the next update. That held command
is the staircase.

Near the frequencies that matter for stability, the hold acts like a delay of half a sample. We
come back to this in two slides.
-->

---

## The sampled loop, in Studio

![SampledCruiseLoop: a periodic clock drives two samplers on the setpoint and the measured speed, a DiscretePIDStandard controller, and a zero-order hold feeding the GradeCar plant.](/img/lecture-01/step09-sampler.png)

*Demo only · `SampledCruiseLoop` · clock → samplers → `DiscretePIDStandard` → hold → `plant`*

**Open in Dyad** `dyad/Lecture1/SampledCruiseLoop.dyad`

<!--
You do not need to reproduce this. The plant is the course's `HandsOn.GradeCar`, the same car as
the `GradeCar` you have been driving all lecture. Everything new is on the controller's side.

From left to right. `clock` is a `DiscreteComponents.PeriodicClock` with dt equal to `Ts`: one tick
every `Ts`, 0.1 seconds by default.

`setpoint_sampler` and `measurement_sampler` are each a `DiscreteComponents.Sampler`. They turn the
setpoint and `plant.v_kmh` into clocked values. The clock wire joins the setpoint sampler's output
and the controller. That one connection puts the whole controller on the clock.

`controller` is `DiscreteComponents.DiscretePIDStandard`, the library's discrete PID. Its settings
are K, T i, T d, N d and T s. N d is the derivative filter from section 07; T s is the sample time.
It is not your `CruiseController`, but any sampled controller behaves this way.

`hold` is a `DiscreteComponents.ZeroOrderHold`. Its output is the staircase.

`plant` is continuous, and untouched.

`Ts` is a structural parameter: a value fixed when the model is compiled, because it defines the
clock. Changing it is a recompile, so the notebook builds one model per sample time.

To put your own controller on a clock, use the same two samplers and the hold around a discrete
controller. This diagram is the template.
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

Phase margin is how much extra phase lag the loop can take before it oscillates, and your
tuning already used most of it.

- Use a little: more overshoot.
- Use most of it: the loop rings.
- Use all of it: it does not recover.

</div>
<div>

> **A rule of thumb**
>
> Spend at most about 0.2 rad (roughly 12°) of phase on sampling at the loop's crossover
> frequency $\omega_c$. That is $T_s < 0.4/\omega_c$: sample some **20 to 30 times faster** than
> the closed-loop bandwidth, not than the plant.

</div>
</div>

<!--
Sampling acts like dead time. The engine's transport delay is what let us drive this plant into
sustained oscillation. Sampling adds more delay, and this time **we** added it, by choosing a
cheaper processor. A delay has the same effect whether it comes from fuel injection or from a
scheduler. Your loop tolerates a fixed total delay, and every source adds to it.

The arithmetic. Think of the loop as handling waves of different speeds. Omega is how fast a wave
cycles, in radians per second. Phase lag is how far the response trails behind the wave, measured
as an angle. At angular frequency omega, a zero-order hold adds about omega T s over two radians
of lag. Omega c is the crossover frequency: the wave speed at which the loop neither amplifies nor
shrinks a signal. Phase margin is measured there: how much extra lag the loop can absorb before it
oscillates.

The rule of thumb is to spend at most 0.2 radians, about 12 degrees, on sampling. That means T s
less than 0.4 over omega c: sample 20 to 30 times faster than the closed-loop bandwidth, not the
plant's time constant.

Remember the order: overshoot, then ringing, then divergence. If a loop that used to be fine starts
overshooting after a software change, ask what happened to the loop rate before you touch a gain.
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

*Re-tuning restores stability, not performance. The loop at the slow rate stays slower.*

</div>
<div>

![Two responses at the same slow sample time: the original gains ringing badly, and the re-tuned gains settling smoothly but noticeably slower than the continuous design.](/figures/09-retuned.svg)

*Same slow rate, two gain sets. The re-tuned one is stable, and slower than the design we started from.*

</div>
</div>

<!--
There are two fixes. The first samples faster: 0.05 seconds, with the same gains. That shortens the
delay from measurement to action. The second stays at one second and re-tunes gently: k 20, T i 3
seconds, T d 0.5 seconds. That lowers the bandwidth, so the one-second update costs less phase
margin. Both settle.

Compare the re-tuned curve with where the continuous design sat. The gap is what the cheap
processor cost. Re-tuning restores stability, not the original bandwidth.

This trade-off comes up on every project. A faster loop means more expensive hardware, more power,
more heat. Slower means less performance. The control engineer usually has to put a number on that
trade, because nobody else can.

A third option is to design directly in discrete time instead of converting a continuous design.
That is a course of its own, and it is why the conversion method matters.
-->

---

## So why design in continuous time at all?

- The mathematics is easier and far better tooled.
- The plant is continuous anyway: the car does not tick.
- Modeling plant and controller in the same domain keeps the problem simple.

### Design in continuous time, convert, **then verify the design at the rate you actually have**, as in the plot we just made.

<!--
This is the same argument as using a linear model for a nonlinear plant. We work where the tools
are good, and then we check the approximation. If you take the shortcut, the check is required.

This notebook keeps the same k, T i and T d. It turns the integral and the filtered derivative into
step-by-step sums, using two simple recipes called forward Euler and backward Euler. Other
conversion methods give slightly different numbers. Either way, verify at the rate you deploy.
-->

---

## Summary of section 09

- A loop that became unstable without any change to its gains.
- The reason: sampling adds phase lag, and the phase margin is limited.
- A workflow: design continuous, convert, verify the rate.

### Next: the tire is an actuator too. <Link to="wheel-and-slip">→ 10, wheel and slip</Link>

<!--
One more section. The controller is finished. Now the car changes
underneath it.
-->
