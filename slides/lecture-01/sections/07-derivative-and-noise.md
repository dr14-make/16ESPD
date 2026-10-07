---
routeAlias: derivative-and-noise
layout: section
---

###### Notebook 07

# Derivative and noise

The derivative does not care how big the noise is, only how fast.

`notebooks/lecture01/07-derivative-and-noise.ipynb`

<!--
**Say:** in section 05 the derivative was free. It cost nothing and it removed the overshoot.
Here is the bill.

**Timing:** 10 minutes. The two-sines slide is the one that has to land; everything else is
evidence.

**Cut order:** first to go. Everything here is upside; the lecture stands without it.
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

# Nd = 10 is the LimPID default, and what every
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
**Point at** the measured trace and say: if I showed you this and asked whether it was good
enough, you would say yes. A fraction of a km/h. Down in the noise, as the phrase goes.

**Note for you, not for them:** this noise is a deterministic sum of sines, not a random
process. The notebooks are committed with their outputs as the lecture's fallback, and a plot
that changes on every run is worse than useless. Mention it only if someone asks why it looks
periodic — then it is a good answer about reproducible simulation.

**Readout — every symbol on this slide**

- **plant.v_kmh** — the true speed. **noise.y** — the measured speed, with noise added.
- **N<sub>d</sub> = 10** — a sane derivative filter coefficient for this first run.
- **Deterministic noise** — a sum of sines, not a random process, so the committed plots
  reproduce exactly. Say so only if asked why it looks periodic.
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
**Draw the tangents with your finger** on the projected plot. This is a visual argument and it
works far better as a gesture than as an equation.

**Say:** any signal is a sum of sine waves — that is what a Fourier transform is telling you.
So this is not a special case about sines; it is what a derivative does to every
high-frequency component in anything you feed it.

**Ask the room:** each of our six noise components is 0.2 km/h. The top one sits at 16 Hz.
What does the derivative path make of it? *(k·T<sub>d</sub>·A·ω = 563 N.m, out of a wiggle two
tenths of a km/h wide. The engine makes 150.)*

**Readout — every symbol on this slide**

- **A** — the amplitude of the noise. Unchanged between the two sines.
- **ω** — the angular frequency, radians per second. Ten times higher in the second.
- **A·ω** — the amplitude of the derivative. This is the whole argument: differentiation
  multiplies by frequency.
- **ω = 1 rad/s** — the break-even point. Above it the derivative amplifies; below it,
  attenuates.
- **The yellow tangents** — the slope at the steepest point of each sine, which is what the
  derivative reports.
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
**Read out** the range from `extrema`: the command swings across 1760 N·m, twelve times the
150 N·m the engine can deliver and forty times the 40 N·m the car actually needs to hold this
speed.

**Say:** and now think about what this is physically. That command goes to an engine.
Fuelling swinging like that, many times a second, forever. It will not break today — it will
wear something out, or overheat something, or simply feel terrible to sit in.

**Say:** and here is the same lesson as section 08 arriving from a different direction —
*always plot the actuator command*. The controlled variable looked fine in both cases.

**Ask the room:** would a real cruise control ever run a pure derivative? *(No. Which is why
the block you get in any real toolchain has a filter coefficient on it, and why most
industrial loops are PI with no derivative at all.)*

**Readout — every symbol on this slide**

- **N<sub>d</sub> = 100** — cutoff at N<sub>d</sub>/T<sub>d</sub> = 200 rad/s, above the noise
  band's 16 Hz top: no filter left, in effect.
- **rerun** — `Nd` is an ordinary parameter, so this re-solves the compiled model rather than
  building a second one.
- **extrema(...)** — the minimum and maximum of the commanded torque, i.e. the full swing.
- **COMMAND** — `loop.controller.y`, what the controller asks of the engine.
- **the 20–30 s window** — settled cruise, with the step long over, so what is left in it is
  the noise and nothing else.
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

*The same loop at four cutoffs. The chatter subsides — from 1760 N·m to 315, with the engine's 150 N·m limit still inside the band.*

</div>
</div>

<!--
**Say:** this is what the `Nd` parameter is for. Every PID block in every toolchain has one,
and most people never touch it because they never look at the actuator command. Now you know
what it does and why it is there.

**Say:** and notice the filter does not remove the noise. It attenuates it, so that after the
derivative amplifies what is left, the result is smaller. On this car that is not the same as
small enough: the command falls from 1760 N·m to 315, and 315 is still twice what the engine
can deliver.

**Readout — every symbol on this slide**

- **sN/(s + N)** — a derivative in series with a first-order low-pass. At low frequency it is
  a derivative; at high frequency it flattens off instead of growing.
- **N** — the cutoff frequency in rad/s; <code>N<sub>d</sub></code> in the code.
- **s** — the Laplace variable; multiplying by s is differentiating.
- **N<sub>d</sub> = 100, 20, 5, 2** — the sweep, from no filter to heavy: cutoffs at 200, 40,
  10 and 4 rad/s.
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
**Say:** the easy case is the well-separated one — the signal you care about is slow and has
most of the power, the noise is fast and has very little. Then a first-order filter is all
you need and the choice is easy.

**Do not let them leave thinking this car was that case.** It was not. We filtered it as hard
as the response would allow and the command still swings twice the engine's limit. The
notebook measures both ends of the trade and there is no value of `Nd` that wins — that is
the result, not a failure to tune.

**Say:** so the fix is upstream of the filter. Use less derivative, get a better measurement,
or estimate. The last of those is a Kalman filter, and it is a different course.

**Optional aside, only if time and appetite:** a filtered derivative *sN/(s+N)* is
algebraically identical to a feedback loop with *N* forward and an integrator in the feedback
path. Same behavior, fewer operations, much harder to read. Worth mentioning that the block in
your toolchain may well be implemented the second way.

**Terms, if anyone asks**

- **Cutoff frequency** — where the filter starts attenuating, conventionally at −3 dB.
- **Low-pass** — passes slow things, blocks fast ones.
- **The trade-off** — too high and the noise gets through; too low and you filter away the
  signal, and the derivative stops doing its job.
- **When the bands are close** — as they are here, half a decade apart — no choice of cutoff
  helps, and the answer is less derivative, a better sensor or a state estimator.
-->

---

## What this bought us

- The derivative's real cost: it amplifies by frequency, and noise is all frequency.
- A concrete reason the `Nd` parameter exists.
- The rule, arriving for the second time today: plot the actuator command.

### Next: the tire has a limit too, and it is not in the engine. <Link to="wheel-and-slip">→ 10, wheel and slip</Link>

<!--
**Say:** we have now seen the controller defeated by an actuator that saturates and by a sensor
that lies. The last section is defeated by neither — it is defeated by the plant itself
changing character.
-->
