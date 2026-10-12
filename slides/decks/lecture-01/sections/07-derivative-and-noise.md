---
routeAlias: derivative-and-noise
layout: section
---

###### Notebook 07

# Derivative and noise

The derivative responds to how fast the noise changes, not to how large it is.

`notebooks/lecture01/07-derivative-and-noise.ipynb`

<!--
In section 05 the derivative removed the overshoot at no visible cost. Here is the cost: it
amplifies sensor noise.
-->

---

## Every sensor is noisy

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

Thermal, shot, flicker, coupling from everything else in the vehicle:
every sensor has noise, and a speedometer does too.

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

*The measured trace against the true speed. The noise looks harmless.*

</div>
</div>

<!--
Look at the measured trace. Asked whether it is good enough, you would say yes. The noise is a
fraction of a km/h.

`plant.v_kmh` is the true speed. `noise.y` is the measured speed, the same with noise added. The
controller runs with `Nd` equal to 10, a reasonable derivative filter for a first run.
-->

---
routeAlias: step-7
---

## Step 7: give the controller a real sensor

<div class="grid grid-cols-[1.7fr_1fr] gap-6 items-center">
<div>

![The loop with the noise block inserted between the plant's speed output and the controller's measurement input.](/img/lecture-01/step07-noise-loop.png)

</div>
<div class="step7-plots grid grid-rows-2 gap-2">
<div>

![Controller output with derivative setpoint weight 1: a spike at the setpoint step and continuous chatter after it.](/img/lecture-01/step07-noisy-plot.png)

</div>
<div>

![The same plot with derivative setpoint weight 0: the setpoint kick is gone and the chatter remains.](/img/lecture-01/step07-wd0-plot.png)

</div>
</div>
</div>

*Duplicate `CruiseLoopStep` → `NoisyCruiseStep` · new component `MeasurementNoise` (paste from
the page) → `noise` between `plant.v_kmh` and `controller.u_m` · limits lifted · run at
`wd = 1`, `xd0 = 0`, then back to `wd = 0`, `xd0 = -90` · later: vary `Nd`*

```julia
using MyCar, Plots; plotly()
r = MyCar.NoisyCruiseTransient()
plot(r; idxs = r."controller.y")
plot(r; idxs = [r."plant.v_kmh", r."noise.y"])
```

[page: step 7](../lecture/lecture-01/#step-7) · reference `NoisyCruiseLoop` in `dyad/Lecture1/NoisyCruiseLoop.dyad`

<style>
.step7-plots img { max-height: 9rem; }
</style>

<!--
Until now the controller saw the true speed, to fifteen digits. No car has that sensor. So we add
realistic noise and look at the command.

Duplicate `CruiseLoopStep` and name the copy `NoisyCruiseStep`, the reference bench's name.
`CruiseLoopStep` stays clean. In the copy, delete the wire from `plant.v_kmh` to `controller.u_m`.

Add a component `MeasurementNoise`. Toggle to code and paste the block from step 7 of the guide
page; `MyCar` cannot see the course library, so you paste the reference's code. Place it as
`noise` with `amplitude` 0.2. That is 0.2 km/h per sinusoid, six of them, from 0.5 to 16 hertz.

Wire `plant.v_kmh` into `noise.u`, and `noise.y` into `controller.u_m`. The controller now sees
`noise.y`; `plant.v_kmh` stays the truth.

The `controller` keeps k 56, `Ti` 10, `Td` 0.5 and `Nd` 10. Set `controller.wd` to 1 and
`controller.xd0` to 0, the seed that goes with w d equal to 1. Then lift every limit, as the
notebook does, so the chatter is not clipped: `controller.y_max` 1e6, `controller.y_min` minus
1e6, and `plant.T_max` 1e6. That is what the step 6a parameter is for.

Run Analysis, TransientAnalysis, name it `NoisyCruiseTransient`, stop 40. Run it and plot
`controller.y`, then `plant.v_kmh` with `noise.y`, with the code on the slide.

With w d equal to 1 you see a tall spike in `controller.y` at the setpoint step: the derivative of
the step. After it the command never stops chattering. With the limits lifted, the kick throws the
car to about 187 km/h within the first second. The engine cannot brake, so the car coasts down for
the rest of the run, to 108.9 km/h at 40 seconds.

Now set `controller.wd` back to 0 and `controller.xd0` back to minus 90, the section 05 defaults,
and re-run on the same axes. The kick is gone; the chatter is unchanged. The kick came from the
setpoint, the chatter from the sensor, and w d only removes the first. That is why every notebook
since 05 runs with w d equal to 0.

On the "Filtering the derivative" slide we come back to this model with `controller.Nd` at 100,
20, 5 and 2. In the notebook, the swing in the 20 to 30 second window falls from 1751
newton-meters at N d 100 to 316 at N d 2.
-->

---

## Why small noise gives a large derivative

$$
\frac{d}{dt}\bigl[A\sin(\omega t)\bigr] \;=\; A\,\omega\cos(\omega t)
$$

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

- Same amplitude *A*.
- Frequency ten times higher.
- **Slope ten times steeper.**

A derivative reports slope. A small wiggle that moves fast has a steep slope.

*Above ω = 1 rad/s the derivative **amplifies**. Sensor noise is mostly at high
frequencies.*

</div>
<div>

![Two sine waves of equal amplitude, one slow and one ten times faster, each with a tangent line drawn at its steepest point: the fast one's tangent is far steeper.](/figures/07-two-sines.svg)

*Equal amplitude, ten times the frequency, ten times the slope. The derivative measures the slope of the tangent, not the amplitude.*

</div>
</div>

<!--
Any signal is a sum of sine waves; that is what a Fourier transform tells you. So this holds for
every fast component you feed a derivative.

The two tangent lines: same amplitude A, ten times the frequency. The derivative has amplitude A
times omega, so ten times the slope. Differentiation multiplies each component by its frequency.
Above 1 radian per second it amplifies; below, it attenuates.

A question. Each of our six noise components is 0.2 km/h, and the top one sits at 16 hertz. What
does the derivative path make of it?

k times T d times A times omega: 563 newton-meters, from a wiggle of two tenths of a km/h. The
engine makes 150.
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

> **Compare the speed and the torque**
>
> The speed trace still looks almost clean. The torque command is unusable. The problem shows
> on the actuator, not on the output.

</div>
<div>

![Commanded torque against time with a near-pure derivative: a violently chattering trace swinging across a wide range, while the speed trace below remains smooth.](/figures/07-chattering-command.svg)

*Commanded torque with the filter effectively switched off.*

</div>
</div>

<!--
`extrema` gives the range: the command swings across 1751 newton-meters. That is twelve times what
the engine can deliver, and forty times the 40 newton-meters the car needs to hold this speed.

N d 100 puts the cutoff at N d over T d, 200 radians per second, above the noise band's 16 hertz.
In effect, no filter. `Nd` is an ordinary parameter, so `rerun` re-solves the compiled model
instead of building a new one. We look only at 20 to 30 seconds: settled cruise, so what is left
is the noise.

That command goes to an engine. The fueling swings like that many times a second, for as long as
the car drives. Nothing breaks at once, but it wears parts, overheats them, and makes the ride
rough.

Section 08 repeats the rule: **always plot the actuator command.** The speed looked fine in both
cases.

A real cruise control never runs a pure derivative. That is why every real PID block has a filter
coefficient, and why most industrial loops are PI, with no derivative at all.
-->

---

## Filtering the derivative

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

*The same loop at four cutoffs. The command range falls from 1751 N·m to 316, still wider than the engine's 150 N·m limit.*

```julia
using MyCar, Plots; plotly()
r = MyCar.NoisyCruiseTransient()
p = plot(r; idxs = r."controller.y", label = "Nd = 10")
# set controller.Nd = 100, run again, then:
r2 = MyCar.NoisyCruiseTransient()
plot!(p, r2; idxs = r2."controller.y", label = "Nd = 100")
```

</div>
</div>

<!--
Now on your own `NoisyCruiseStep`. Plot `controller.y` as it stands, at `Nd` 10, with the first
three lines on the slide. Set `controller.Nd` to 100 and re-run; the last two lines add that run
to the plot. Then 20, 5 and 2, each with its own label. Each is a re-solve, not a recompile. You
see the band shrink.

This is a derivative in series with a first-order low-pass. At low frequency it differentiates; at
high frequency it flattens off. Its cutoff N is N d over T d, with T d 0.5 seconds, so N d 100,
20, 5 and 2 put it at 200, 40, 10 and 4 radians per second: from almost no filtering to heavy
filtering.

Every PID block in every toolchain has this parameter. Most people never change it, because they
never look at the actuator command.

The filter attenuates the noise; it does not remove it. On this car that is not enough. The
command falls from 1751 newton-meters to 316, still twice what the engine delivers.
-->

---

## Choosing the cutoff

### Low enough to remove the noise.

### High enough to leave the signal.

On this car those two ranges nearly touch. The loop works at about 0.2 Hz; the speedometer's
noise starts at 0.5 Hz, only **2.5 times** higher. A first-order filter rolls off at 6 dB per
octave, that is, it halves the amplitude for each doubling of frequency. So it cannot cut one
without starting on the other.

*From **N<sub>d</sub>** = 20 down to 2 the filter costs nothing: the perfect-sensor overshoot does
not move while the command range falls by a factor of three. Below 2 it starts to cost: at
**N<sub>d</sub>** = 0.5 the overshoot is five times larger, **even with a perfect sensor**.*

> **No cutoff fixes this loop**
>
> The command range bottoms out around 300 N.m at an `Nd` where the response is still intact,
> twice the engine's limit. The fixes are outside the filter:
> **less derivative** (T<sub>d</sub> multiplies the noise too), **a better sensor**, or **an
> estimator** that decides by model rather than by frequency. A recommended value for `Nd`
> assumes a particular plant.

<!--
The easy case is well separated: the signal is slow and carries most of the power, the noise is
fast and weak. Then a first-order filter is all you need. Its cutoff, conventionally at minus 3
dB, is where it starts to attenuate. Too high, and noise gets through. Too low, and you filter
away the signal and the derivative stops working.

This car is not the easy case. We filtered as hard as the response allows, and the command still
swings twice the engine's limit. The notebook measures both ends of the trade, and no value of
`Nd` wins. That is a property of the loop, not a tuning mistake.

So the fix lies outside the filter: less derivative, a better measurement, or a speed estimated
with a model. That last one is a Kalman filter, and a different course.

A side note. A filtered derivative, s N over s plus N, is algebraically identical to a loop with N
forward and an integrator in the feedback path. It behaves the same, needs fewer operations, and
is much harder to read. Your toolchain's block may be built the second way.
-->

---

## Summary of section 07

- The derivative's cost: it amplifies each component in proportion to its frequency, and
  sensor noise is high-frequency.
- A concrete reason the `Nd` parameter exists.
- A rule you will hear again in section 08: plot the actuator command.

### Next: where the gains came from. <Link to="tuning">→ 08, tuning</Link>

<!--
The controller has now failed twice: an actuator that saturates, and a sensor that is noisy.
Before the plant changes in section 10, one question is open: where did k equal to 56 come from?

Go back to `CruiseLoopStep`. It never had the noise, and it keeps its step 6b limits, 150 and 0.
Leave `NoisyCruiseStep` as it is. We lift limits only on duplicates: `NoisyCruiseStep` here,
`TuningCruiseStep` in section 08. Never on `CruiseLoopStep` itself.
-->
