---
routeAlias: derivative-and-noise
layout: section
---

###### Notebook 07

# Derivative and noise

The derivative does not care how big the noise is, only how fast.

`notebooks/lecture01/07-derivative-and-noise.ipynb`

<!--
In section 05 the derivative was free. It cost nothing, and it removed the overshoot.

Here is the bill.
-->

---

## Every sensor is noisy

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

Thermal, shot, flicker, coupling from everything else in the vehicle —
noise is not a defect, it is a property. A speedometer has it too.

```julia [07-derivative-and-noise.ipynb · cell 1. Every sensor is noisy]
Scenarios = VehicleSystemsComponents.Lecture1

TRUE_SPEED = "loop.plant.v_kmh"    # what the car is doing
MEASURED   = "loop.noise.y"        # what it is told
COMMAND    = "loop.controller.y"   # what it asks for
UNLIMITED  = 1.0e6                 # N.m, both ways

# Nd = 10 is the controller's default, and what every
# notebook since 05 has silently been running.
noisy = Scenarios.NoisyCruiseTransient(
    k = 56.0, Ti = 10.0, Td = 0.5, Nd = 10.0, wd = 0.0,
    T_max = UNLIMITED, y_max = UNLIMITED,
    y_min = -UNLIMITED, stop = 40.0)

t, v_true = signal(noisy, TRUE_SPEED)
_, v_meas = signal(noisy, MEASURED)
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/07-derivative-and-noise.ipynb)

</div>
<div>

![True and measured speed on one axes: the measured trace has small high-frequency wiggles on top of the true curve and looks essentially harmless.](/figures/07-true-vs-measured.svg)

*The measured trace, against the truth. Small enough to look harmless.*

</div>
</div>

<!--
Look at the measured trace. If I showed you this and asked whether it was good enough, you
would say yes. A fraction of a km/h. Down in the noise, as the phrase goes.

Two signals are on this plot. `plant.v_kmh` is the true speed, what the car is actually doing.
`noise.y` is the measured speed, the same thing with noise added. And the controller runs with
`Nd` equal to 10, a sane derivative filter coefficient for this first run.
-->

---
routeAlias: step-7
---

## Step 7: give the controller a real sensor

<div class="grid grid-cols-3 gap-6">
<div>

![The loop with the noise block inserted between the plant's speed output and the controller's measurement input.](/img/lecture-01/step07-noise-loop.png)

</div>
<div>

![Controller output with derivative setpoint weight 1: a spike at the setpoint step and continuous chatter after it.](/img/lecture-01/step07-noisy-plot.png)

</div>
<div>

![The same plot with derivative setpoint weight 0: the setpoint kick is gone and the chatter remains.](/img/lecture-01/step07-wd0-plot.png)

</div>
</div>

*Duplicate `CruiseLoopStep` → `NoisyCruiseStep` · new component `MeasurementNoise` (paste from
the page) → `noise` between `plant.v_kmh` and `controller.u_m` · limits lifted · run at
`wd = 1`, `xd0 = 0`, then back to `wd = 0`, `xd0 = -90` · later: vary `Nd`*

[page: step 7](../lecture/lecture-01/#step-7) · reference `NoisyCruiseLoop` in `dyad/Lecture1/NoisyCruiseLoop.dyad`

<!--
Every speed we have fed the controller so far was the true one, to fifteen digits. No car has
that sensor. So let us put a realistic one in, and look at the command.

This is a new harness in `MyCar`, beside `CruiseLoopStep` and `CruiseClimb`.

First, duplicate `CruiseLoopStep`. Name the copy `NoisyCruiseStep`, which is the reference
bench's name. `CruiseLoopStep` itself stays clean. In the copy, delete the wire from
`plant.v_kmh` to `controller.u_m`.

Now add a component called `MeasurementNoise`. Toggle it to code and paste the block from
step 7 of the guide page over its contents. We paste it because `MyCar` cannot see the course
library, and this is the code of what the reference uses. Place it as `noise`, and set
`amplitude` to 0.2. That is 0.2 km/h per sinusoid, and there are six of them, from 0.5 to 16
hertz.

Now wire `plant.v_kmh` into `noise.u`, and `noise.y` into `controller.u_m`. The controller now
sees `noise.y`. `plant.v_kmh` stays the truth.

Parameters. The `controller` keeps k equal to 56, `Ti` equal to 10, `Td` equal to 0.5 and `Nd`
equal to 10. Set `controller.wd` to 1, and `controller.xd0` to 0. That zero is the seed, w d
minus one, times m zero, that goes with w d equal to 1. Then lift every limit, as the notebook
does, so the chatter is not clipped. Set `controller.y_max` to 1e6, `controller.y_min` to minus
1e6, and `plant.T_max` to 1e6. That is the parameter from step 6a earning its keep.

Now Run Analysis, choose TransientAnalysis, and name it `NoisyCruiseTransient`, with stop equal
to 40. Run it. Plot `controller.y`, and plot `plant.v_kmh` against `noise.y`.

With w d equal to 1, you should see a tall spike in `controller.y` at the setpoint step. That
spike is the derivative of a step in the setpoint. After it, the command never stops
chattering. And with every limit lifted, the kick throws the car well past the setpoint, to
about 187 km/h, before it comes back to 110.

Now put `controller.wd` back to 0 and `controller.xd0` back to minus 90. Those are the section
05 defaults. Re-run, on the same axes.

With w d equal to 0, you should see the setpoint kick gone, and the chatter unchanged. The kick
came from the setpoint. The chatter comes from the sensor. And w d only removes the first. That
is why every notebook since 05 runs with w d equal to 0.

Later, on the "Filter it" slide, we come back to this model. We will set `controller.Nd` to
100, 20, 5 and 2, and re-run each one. In the notebook, the swing in the 20 to 30 second window
falls from 1751 newton-meters at N d equal to 100, to 316 at N d equal to 2.
-->

---

## Why small noise is not safe

$$
\frac{d}{dt}\bigl[A\sin(\omega t)\bigr] \;=\; A\,\omega\cos(\omega t)
$$

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

- Same amplitude *A*.
- Frequency ten times higher.
- **Slope ten times steeper.**

A derivative reports slope. It does not know or care that the wiggle is small — it only sees
how fast it moves.

*Above ω = 1 rad/s the derivative **amplifies**. High frequencies are exactly where sensor
noise lives.*

</div>
<div>

![Two sine waves of equal amplitude, one slow and one ten times faster, each with a tangent line drawn at its steepest point: the fast one's tangent is far steeper.](/figures/07-two-sines.svg)

*Equal amplitude, ten times the frequency, ten times the slope. The derivative sees the tangent lines, not the envelopes.*

</div>
</div>

<!--
Any signal is a sum of sine waves. That is what a Fourier transform is telling you. So this is
not a special case about sines. It is what a derivative does to every high-frequency component
in anything you feed it.

Look at the two tangent lines. Same amplitude A. Ten times the frequency omega. The derivative
has amplitude A times omega, so ten times the slope. That is the whole argument: differentiation
multiplies by frequency. The break-even point is omega equal to 1 radian per second. Above it,
the derivative amplifies. Below it, it attenuates.

So here is a question. Each of our six noise components is 0.2 km/h. The top one sits at 16
hertz. What does the derivative path make of it?

k times T d times A times omega. That is 563 newton-meters, out of a wiggle two tenths of a
km/h wide. The engine makes 150.
-->

---

## A near-pure derivative

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [07-derivative-and-noise.ipynb · cell 3. A near-pure derivative]
# Nd is the derivative filter coefficient: large Nd pushes
# the cutoff up, towards no filter at all. Nd = 100 puts it
# at 200 rad/s, above the noise band's 16 Hz top.
near_pure = rerun(noisy, "Nd" => 100.0)

t, u = signal(near_pure, COMMAND)
cruise = 20.0 .<= t .<= 30.0    # settled, the step long over
extrema(u[cruise])              # the damage, in N.m
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/07-derivative-and-noise.ipynb)

> **Look at both plots together**
>
> The speed trace still looks almost clean. The torque command is unusable. The failure is
> invisible on the output and obvious on the actuator.

</div>
<div>

![Commanded torque against time with a near-pure derivative: a violently chattering trace swinging across a wide range, while the speed trace below remains smooth.](/figures/07-chattering-command.svg)

*Commanded torque with the filter effectively switched off.*

</div>
</div>

<!--
Here is the range from `extrema`. The command swings across 1751 newton-meters. That is twelve
times the 150 newton-meters the engine can deliver, and forty times the 40 newton-meters the
car actually needs to hold this speed.

N d equal to 100 puts the cutoff at N d over T d, 200 radians per second. That is above the
noise band's 16 hertz top, so in effect there is no filter left. `Nd` is an ordinary
parameter, so `rerun` re-solves the compiled model rather than building a second one. And we
look only at the 20 to 30 second window. That is settled cruise, with the step long over, so
what is left in it is the noise and nothing else.

Now think about what this is physically. That command goes to an engine. Fueling swinging like
that, many times a second, forever. It will not break today. It will wear something out, or
overheat something, or simply feel terrible to sit in.

And here is the same lesson as section 08, arriving from a different direction. **Always plot
the actuator command.** The controlled variable looked fine in both cases.

Would a real cruise control ever run a pure derivative? No. That is why the block you get in
any real toolchain has a filter coefficient on it. And it is why most industrial loops are PI,
with no derivative at all.
-->

---

## Filter it

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

A first-order low-pass on the derivative path, with cutoff *N* in rad/s:

$$
\frac{s\,N}{s+N} \qquad\text{instead of}\qquad s
$$

```julia [07-derivative-and-noise.ipynb · cell 4. Filter it]
# `Nd` is an ordinary parameter, so the whole family is one
# compiled model re-solved four times, not four models.
NDS = [100.0, 20.0, 5.0, 2.0]   # cutoffs 200, 40, 10, 4 rad/s

nd_family = sweep(near_pure, "Nd", NDS)

for (nd, sol) in nd_family
    tt, uu = signal(sol, COMMAND)
    @show nd extrema(uu[20.0 .<= tt .<= 30.0])
end
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/07-derivative-and-noise.ipynb)

</div>
<div>

![Commanded torque at four derivative filter coefficients: the chatter shrinks steadily as the cutoff comes down until the command is smooth.](/figures/07-nd-family.svg)

*The same loop at four cutoffs. The chatter subsides — from 1751 N·m to 316, with the engine's 150 N·m limit still inside the band.*

</div>
</div>

<!--
Let us do this on your own `NoisyCruiseStep` from step 7. Set `controller.Nd` to 100 and
re-run. Then 20, then 5, then 2. `Nd` is an ordinary parameter, so each one is a re-solve, not
a recompile. Keep `controller.y` on the same axes, so you can see the band shrink.

What you have here is a derivative in series with a first-order low-pass filter. At low
frequency it is a derivative. At high frequency it flattens off instead of growing. Its cutoff
N is N d over T d, with T d equal to 0.5 seconds. So N d equal to 100, 20, 5 and 2 puts the
cutoff at 200, 40, 10 and 4 radians per second. That is the sweep from no filter to heavy.

This is what the `Nd` parameter is for. Every PID block in every toolchain has one. Most people
never touch it, because they never look at the actuator command. Now you know what it does and
why it is there.

And notice that the filter does not remove the noise. It attenuates it, so that after the
derivative amplifies what is left, the result is smaller. On this car, that is not the same as
small enough. The command falls from 1751 newton-meters to 316. And 316 is still twice what the
engine can deliver.
-->

---

## Choosing the cutoff

### Low enough to remove the noise.

### High enough to leave the signal.

On this car those two ranges nearly touch. The loop works at about 0.2 Hz; the speedometer's
noise starts at 0.5 Hz. **Half a decade** — and a first-order filter rolls off at 6 dB per
octave, so it cannot cut one without starting on the other.

*From **N<sub>d</sub>** = 20 down to 2 the filter is free: the perfect-sensor overshoot does not
move while the command range falls by a factor of three. Below 2 it starts charging — at
**N<sub>d</sub>** = 0.5 the overshoot quintuples **on a sensor with no noise on it at all**.*

> **No cutoff rescues this loop**
>
> The command range bottoms out around 300 N.m at an `Nd` where the response is still intact —
> twice the engine's limit. The honest answers are the ones that leave the filter alone:
> **less derivative** (T<sub>d</sub> multiplies the noise too), **a better sensor**, or **an
> estimator** that decides by model rather than by frequency. Anyone who gives you a single
> number for `Nd` has assumed your plant.

<!--
The easy case is the well-separated one. The signal you care about is slow and has most of the
power. The noise is fast and has very little. Then a first-order filter is all you need, and the
choice is easy. The cutoff is where the filter starts to attenuate, conventionally at minus 3
dB. Too high, and the noise gets through. Too low, and you filter away the signal, and the
derivative stops doing its job.

Do not leave here thinking this car was the easy case. It was not. We filtered it as hard as
the response would allow, and the command still swings twice the engine's limit. The notebook
measures both ends of the trade, and there is no value of `Nd` that wins. That is the result.
It is not a failure to tune.

So the fix is upstream of the filter. Use less derivative. Get a better measurement. Or
estimate. The last of those is a Kalman filter, and it is a different course.

One more thing. A filtered derivative, s N over s plus N, is algebraically identical to a
feedback loop with N forward and an integrator in the feedback path. Same behavior, fewer
operations, much harder to read. The block in your toolchain may well be implemented the second
way.
-->

---

## What this bought us

- The derivative's real cost: it amplifies by frequency, and noise is all frequency.
- A concrete reason the `Nd` parameter exists.
- The rule, arriving for the second time today: plot the actuator command.

### Next: where the gains came from. <Link to="tuning">→ 08, tuning</Link>

<!--
We have now seen the controller defeated by an actuator that saturates, and by a sensor that
lies. Before the plant itself changes character in section 10, we owe an answer to a question
nobody has asked yet. Where did k equal to 56 come from?

Before we move on, go back to `CruiseLoopStep`. It never had the noise, and it still has its
step 6b limits, 150 and 0. Leave `NoisyCruiseStep` as it is. We lift the limits only on
duplicates. Here that was `NoisyCruiseStep`, and in section 08 it will be `TuningCruiseStep`.
We never lift them on `CruiseLoopStep` itself.
-->
