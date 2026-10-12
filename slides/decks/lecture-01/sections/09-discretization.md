---
routeAlias: discretization
layout: section
---

###### Notebook 09

# Discretization

The same controller gets worse purely because it looks less often.

`notebooks/lecture01/09-discretization.ipynb`

<!--
Everything we have designed today is continuous. Nothing you will ever ship is. This section is
the bridge, and it uses the gains we just derived in section 08. It is the same controller, and
nothing is re-tuned.

This section is a demo, not a build. Just watch. Your own controller stays continuous. The demo
runs on the reference model, `SampledCruiseLoop`.
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
An analog controller changes its output continuously and smoothly. A digital one changes it in
steps, and then it stops thinking. If the steps are small enough and frequent enough, nobody can
tell the difference. And that is the whole engineering question: how fast is fast enough?

Digital control brings other effects too. There is quantization, and there is the transport
delay of the computation itself. We are only going to look at sample time, because it is the one
that will bite you first.

A few words you will hear. The sample time, T s, is the interval between one update and the
next, in seconds. The sample rate is its reciprocal, in hertz. A zero-order hold keeps the last
commanded value constant until the next tick. That is the staircase. Quantization comes from
finite word length. It is real, but it is not our subject today.
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
Picture yourself walking a winding corridor. With the lights on, you see everything as it
happens and you correct continuously. You could run. A fast strobe is no different from the
lights being on. You are still running. One flash a second, and you slow right down. One flash
every few seconds, and you walk into a wall.

So if the strobe slows down, what do you do differently? You slow down. Anyone would. And that
is exactly what re-tuning for a slower sample rate means. The fix at the end of this section is
not clever. It is the obvious thing you just said.

Here is what people get wrong. They assume a slow loop is merely less responsive. It is not. It
goes **unstable**. Less information does not degrade the loop gently. Past a point, it destroys
it.
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
Look at the fastest run first. This is the best the sampled controller does here. It does not
match the continuous run from section 08. Even the fastest run overshoots far more, probably
because this demo leaves its discrete derivative unseeded. The lesson is the trend across the
family.

Now follow the family outward. First the overshoot grows. Then the loop rings. Then it diverges.
Ringing means an oscillation that decays, but slowly. Diverging means it does not decay at all.

The sweep is T s equal to 0.01, 0.1, 0.4 and 1.0 seconds, with the Ziegler-Nichols gains from
section 08. Nothing was re-tuned. Nobody touched a gain. The controller that was correct at ten
milliseconds is dangerous at one second, and it is the same controller.

So which sample time would you pick for a cruise control? The real question is: fast compared
with what? The plant's time constant is about a minute. The loop's own bandwidth is seconds.
That second number is the one that matters.
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
Look at the signal chain. The car remains continuous. Only the sensing, the control computation
and the command updates happen on the clock.

The car can move between ticks, but the applied torque cannot change until the next controller
update. That held command is where the staircase comes from.

Why can this still be approximated as half a sample of delay near crossover? Because a
zero-order hold delays the average command. That is the next slide.
-->

---

## The sampled loop, in Studio

![SampledCruiseLoop: a periodic clock drives two samplers on the setpoint and the measured speed, a DiscretePIDStandard controller, and a zero-order hold feeding the GradeCar plant.](/img/lecture-01/step09-sampler.png)

*Demo only · `SampledCruiseLoop` · clock → samplers → `DiscretePIDStandard` → hold → `plant`*

**Open in Dyad** `dyad/Lecture1/SampledCruiseLoop.dyad`

<!--
This is a demo, not a build, so you do not need to reproduce it. The plant is the same
`HandsOn.GradeCar` you have been driving all lecture. So the only new things on the screen are
on the controller's side.

Let us go through the diagram from left to right.

First, `clock`. It is a `DiscreteComponents.PeriodicClock` with dt equal to `Ts`. One tick
every `Ts`, and that is 0.1 seconds by default.

Next, `setpoint_sampler` and `measurement_sampler`. Both are a `DiscreteComponents.Sampler`.
They turn the setpoint and `plant.v_kmh` into clocked values. Notice that the clock wire joins
the setpoint sampler's output and the controller. That one connection puts the whole controller
on the clock.

Then `controller`. It is `DiscreteComponents.DiscretePIDStandard`, the library's discrete PID,
with K, T i, T d, N d and T s. It is not your `CruiseController`. The point is what any sampled
controller does, and this one ships with the library.

Then `hold`, a `DiscreteComponents.ZeroOrderHold`. The staircase from the previous slide is its
output.

And last, `plant`. Continuous, and untouched.

`Ts` is a structural parameter, because it defines the clock. Changing it is a recompile. That
is why the notebook builds one model per sample time.

If you want to put your own controller on a clock, use the same two samplers and the hold,
around a discrete controller. The diagram on the screen is the template.
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
This is the same currency as the dead time in section 01. The engine's transport delay was the
reason this plant could be driven to sustained oscillation at all. Sampling adds more of exactly
the same thing. Only this time **we** added it, by choosing a cheaper processor. Delay is delay,
whether it comes from fuel injection or from a scheduler. Your loop has a fixed tolerance for
it, and every source draws on the same account.

Here is the arithmetic. At frequency omega, a zero-order hold costs about minus omega T s over
two radians of phase. Omega is angular frequency, in radians per second. Omega c is the
crossover frequency. That is where the loop gain passes through one, and where phase margin is
measured. Phase margin is how much extra phase lag the loop can absorb before it oscillates. It
is a budget, measured in degrees.

The rule of thumb is to spend at most 0.2 radians, about 12 degrees, on sampling. That means T s
less than 0.4 over omega c. In other words, sample 20 to 30 times faster than the closed-loop
bandwidth, not the plant's time constant. Bandwidth is, roughly, the fastest thing the closed
loop can follow.

And notice the ordering. Overshoot first, ringing next, then divergence. That ordering is a
diagnostic. If a loop that used to be fine starts overshooting after a software change, ask what
happened to the loop rate before you touch a gain.
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
There are two fixes. Sampling faster reduces the delay from measurement to actuation, without
changing the standard-form settings. Conservative re-tuning reduces the bandwidth, so the
one-second update rate consumes less phase margin.

Look at the re-tuned curve, and remember where the continuous design sat. The gap between them
is what the cheap processor cost. Re-tuning buys stability, not the original bandwidth. The slow
loop remains slower.

This is a real design conversation, and it happens on every project. A faster loop rate means
more expensive hardware, more power, more heat. Slower means less performance. Somebody has to
put a number on that trade, and it is usually the control engineer, because nobody else can.

Is there a third option? Yes. A better discrete design, rather than a continuous design
converted. That is a course of its own, and it is why the conversion method matters.
-->

---

## So why design in continuous time at all?

- The mathematics is easier and far better tooled.
- The plant is continuous anyway — the car does not tick.
- Modeling plant and controller in the same domain keeps the problem simple.

### Design continuous. Convert. **Then verify that the rate you actually have held up** — which is the plot we just made.

<!--
It is the same argument as using a linear model for a nonlinear plant. We work where the tools
are good, and then we check the approximation. The alternative is working where it is hard and
being right from the start. The checking is not optional. It is the price of the shortcut.

This notebook keeps the standard-form values of k, T i and T d. It then implements the integral
with forward Euler, and the filtered derivative with backward Euler. Other conversion methods
produce different discrete coefficients. Verification at the deployed rate is still required.
-->

---

## What this bought us

- A loop that we broke without touching a single gain.
- The reason: sampling costs phase, and phase margin is a budget.
- A workflow: design continuous, convert, verify the rate.

### Next: the tire is an actuator too. <Link to="wheel-and-slip">→ 10, wheel and slip</Link>

<!--
One more section, and it is the last one. The controller is finished. Now the car changes
underneath it.
-->
