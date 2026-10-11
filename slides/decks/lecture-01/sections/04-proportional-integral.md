---
routeAlias: proportional-integral
layout: section
---

###### Notebook 04

# Proportional-integral

The integrator works out the answer you would otherwise have to compute by hand.

`notebooks/lecture01/04-proportional-integral.ipynb`

<!--
**Say:** one boolean changes between the last notebook and this one. `with_I = true`. Same
car, same gain, same step. In your diagram it is three blocks.

**Timing:** 18 minutes. Adding a memory 2, build step 4 and its run 6, PI against P 2, the
punchline 5, what it costs 2, bridge 1. The punchline — the integrator's own state settling on
the number we computed with a pencil — is the best slide in the lecture. Do not rush to it and
do not rush past it.
-->

---

## Adding a memory

$$
u \;=\; k\left(e \;+\; \frac{1}{T_i}\int_0^t e\,d\tau\right)
$$

<div class="grid grid-cols-2 gap-8">
<div>

- The integral keeps a running total of the error.
- So it keeps *changing* for as long as any error remains.
- And it stops changing only when the error is exactly zero — at which point it holds
  whatever value it has reached.

**Open in Dyad** `dyad/Lecture1/CruiseLoop.dyad`

</div>
<div>

> **Read that last point again**
>
> An integrator's output at rest is *unconstrained by the error*. That is precisely the freedom
> the proportional path did not have, and it is the whole fix.

</div>
</div>

<!--
**Say:** proportional is the present. Integral is the past. That is not a slogan — it is
literally what the two expressions compute.

**Ask the room:** if the error has been zero for a while, what is the integral path putting
out? *(Whatever it accumulated before. Not zero. The room will often answer "zero" — that
confusion is exactly what the next two slides destroy.)*

**On T<sub>i</sub>:** it is a *time*, not a gain, and it divides — so smaller T<sub>i</sub>
is more aggressive integration. Say it now; it catches people out every single year.

**In the model:** **`with_I` is a `structural` parameter** of the reference
`CruiseController`. The integrator is either compiled into the equations or it is not there at
all — `zero_i` holds its slot when it is out. P and PI are two different models, not one model
with a gain at zero. The students get the same effect by hand on the next slide: they add the
block.

**Readout — every symbol on this slide**

- **∫e dτ** — the accumulated error: the running total of how far off we have been, and for
  how long. Units here are km/h·s.
- **T<sub>i</sub>** — the *integral time*, in seconds. It *divides*, so a smaller
  T<sub>i</sub> integrates harder. This catches people out every year.
- **k** — the same proportional gain, which multiplies the whole bracket, so it scales all
  three paths together.
- **τ** — here just the dummy variable of integration, not the plant time constant.
  Unfortunate collision; say so if anyone frowns.
- **with_I** — the boolean that compiles the integrator in or out.
-->

---
routeAlias: build-integrator
---

## Build: a memory

<div class="grid grid-cols-2 gap-6">
<div>

![CruiseController in progress: add_pid (Add3) between error and gain, the integrator on its third input, and the Constant(0) placeholder on its second.](/img/lecture-01/step04-integrator.png)

</div>
<div>

![loop.plant.v_kmh reaching 110 km/h, with loop.controller.integrator.y on a second axis.](/img/lecture-01/step04-pi-plot.png)

</div>
</div>

*Parameters `Ti` = 10, `xi0` = 0 · `add_pid` Add3 between `error` and `gain` · `integrator` Integrator(k = 1/Ti, x0 = xi0) on `u3` ·
`zero_d` Constant(k = 0) holds the derivative slot on `u2`*

[page: step 4](../lecture/lecture-01/#step-4) · reference `dyad/Lecture1/CruiseController.dyad`

<!--
**Say:** the formula has a bracket: the error, plus the integral over T<sub>i</sub>, all times
*k*. So the diagram gets a summing block in front of the gain, with three inputs — one for each
term the finished controller will have. Today two of them: the error, and its integral. The
third slot waits for section 05.

**Build it live, on the projector, with the room.** In `CruiseController`:

1. **Add parameters** `Ti`, default `10` (seconds, type `Time`), and `xi0`, default `0` — the
   integrator's starting state.
2. **Delete** the wire `error.y` → `gain.u`.
3. **Drag in** `BlockComponents.Math.Add3`, name it `add_pid`. Parameters `k1 = 1`, `k2 = 1`,
   `k3 = 1`. Wire `error.y` → `add_pid.u1`, `add_pid.y` → `gain.u`.
4. **Drag in** `BlockComponents.Continuous.Integrator`, name it `integrator`. Parameter
   `k = 1 / Ti`, `x0 = xi0`. Wire `error.y` → `integrator.u`,
   `integrator.y` → `add_pid.u3`.
5. **Drag in** `BlockComponents.Sources.Constant`, name it `zero_d`, `k = 0`. Wire
   `zero_d.y` → `add_pid.u2`. It holds the derivative's slot so `add_pid` has all three inputs.
6. Save. Back in `CruiseLoopStep`, run `CruiseLoopTransient` again — the analysis picks up the
   changed controller.
7. **Plot** `plant.v_kmh` and `demand.y`; on a second axis, `controller.integrator.y`.

**The plot must show, before moving on:** the speed reaching **110 km/h** — the 0.7 km/h gap
from step 3 is gone — and the integrator state rising and leveling off near **0.716**: that is
40.1 N·m divided by *k* = 56. The punchline slide in two minutes multiplies it back.

**On the engine ceiling, again:** the students' engine still clips at 150 N·m and the notebook
figures do not, so the first seconds of their climb, and any overshoot, can differ from the
notebook's. The settled 110 and 0.716 are the same.

**They get wrong:** feeding the integrator from `add_pid.y` instead of `error.y` — it then
integrates its own output as well as the error. And `k = Ti` instead of `k = 1 / Ti`: then a
bigger T<sub>i</sub> integrates *harder*, the opposite of the convention.

**Timing:** 4 minutes building, 2 running and reading the plot.
-->

---

## PI against P

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [04-proportional-integral.ipynb · cell 1. Adding memory]
SPEED = "loop.plant.v_kmh"
GAIN, T_I, UNLIMITED = 56.0, 10.0, 1.0e6

p_only = Scenarios.CruiseLoopTransient(
    k = GAIN, T_max = UNLIMITED, y_max = UNLIMITED, stop = 60.0)

pi_loop = Scenarios.CruiseLoopTransient(
    model = Scenarios.CruiseLoopStep(; name = :CruiseLoopStep,
                                     with_I = true, with_D = false),
    k = GAIN, Ti = T_I, T_max = UNLIMITED, y_max = UNLIMITED, stop = 60.0)
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/04-proportional-integral.ipynb)

</div>
<div>

![Two step responses on one axes: the proportional run settles below the setpoint, the proportional-integral run climbs the last stretch and reaches it.](/figures/04-p-vs-pi.svg)

*Same gain, same step. P settles short; PI keeps going and arrives.*

</div>
</div>

<!--
**Point at:** the place where the two curves separate — not at the step, but afterwards, in
the slow part. The proportional path has already given up there, because its error is nearly
zero. The integral path is still working, because its input is still non-zero.

**Say:** the two terms do different jobs at different times. Proportional does the transient,
integral does the last stretch. Watch for that division of labor again in the next section,
where we plot it directly.

**Ask the room:** which one reached the setpoint faster to within, say, 1 km/h? *(Usually P.
Arriving eventually and arriving exactly are different requirements, and PID tuning is mostly
about trading one for the other.)*

**Readout — every symbol on this slide**

- **k = 56** N·m per km/h, the same for both runs.
- **T<sub>i</sub> = 10 s** — the integral time for the PI run.
- **stop = 60 s** — run length.
- **UNLIMITED = 1e6** — the lifted torque ceiling, standing in for "no limit".
- **SPEED = "loop.plant.v_kmh"** — the signal path: inside the harness, inside the loop, the
  plant's km/h output.
-->

---

## The punchline

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [04-proportional-integral.ipynb · cell 2. What is the integrator holding?]
INTEGRAL = "loop.controller.integrator.y"   # state, before the gain

t, integral = signal(settling, INTEGRAL)
torque = GAIN .* integral                   # k * I, in N.m

plot(t, torque; lw = 3, xlabel = "time [s]", ylabel = "torque [N.m]")
hline!([cruise_torque(110.0)]; ls = :dash, lw = 2, color = :black,
       label = "torque to hold 110 km/h, from the force balance")
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/04-proportional-integral.ipynb)

- **40.1** N·m computed
- **40.1** N·m discovered

*↩ Hands-on step 05: [where 40.1 N·m comes from](../handson-01/index.html#/top-speed)*

**Open in Dyad** `dyad/Lecture1/CruiseLoop.dyad`

</div>
<div>

![The integral path's output rising and levelling off exactly on a dashed horizontal line marking the analytically computed cruise torque.](/figures/04-integrator-state.svg)

*The integrator's state settles on the dashed line — the cruise torque we computed from the force balance, which the controller was never told.*

</div>
</div>

<!--
**This is the slide.** Slow down.

**Point at:** the dashed line first. Say where it came from: we solved the force balance at
110 km/h with a pencil, back in hands-on step 05, and got 40 newton-metres.

**Then point at:** the curve arriving at it. Say: nobody gave the controller the mass. Or the
drag area. Or the gear ratio. It has never seen the model. It has seen one number — how far
off it was — and by accumulating that it has *inverted the plant*.

**Say:** that is what "an integrator removes steady-state error" actually means. It is not a
magic property of the formula. It is that the integrator can hold an output that the error
no longer justifies, and it will keep hunting until it holds exactly the right one.

**Ask the room:** what happens to that line if I put 200 kg of luggage in the boot? *(It
moves up, and the integrator finds the new value without being told. That is the argument
for feedback in one sentence.)*

**Check:** if the integrator settles anywhere other than the hand-computed torque, the units
or the gear ratio disagree between notebook and model — that mismatch is worth more than the
slide, so stop and find it.

**In the model:** The integrator is **inside `CruiseController`** — the block the students
just placed — and `integrator.y` is its state *before* the gain. The plot multiplies by `k` to
get newton-metres. Their own second axis from the build shows the same curve, unscaled.

**Readout — every symbol on this slide**

- **integrator.y** — the integrator's own state, *before* the gain k is applied. Multiply by
  k to get newton-metres.
- **k·I = 40.119 N·m** — where it settles.
- **T_cruise(110) = 40.119 N·m** — the same number, computed from the force balance with a
  pencil in hands-on step 05.
- **The dashed line** — that hand-computed value, drawn on so the coincidence is visible
  rather than asserted.
- **stop = 90 s** — a longer window than the step needs, because the last hundredths of a
  newton-metre take most of a minute.
-->

---

## What it costs

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [04-proportional-integral.ipynb · cell 4. The cost]
TIS = [40.0, 20.0, 10.0, 5.0, 2.5]

ti_family = sweep(pi_loop, "Ti", TIS)

plot_sweep(ti_family; sig = SPEED, setpoint = 110, name = "Ti",
           xlims = (0, 20))
[overshoot(s, 110; sig = SPEED) for (_, s) in ti_family]
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/04-proportional-integral.ipynb)

*Still an unlimited engine. Shrinking **T<sub>i</sub>** integrates harder. Every one of these settles at 110 — the question is what it does on the way. The loop arrives sooner, then past.*

</div>
<div>

![Four step responses at decreasing integral time: each reaches the setpoint sooner and the fastest ones overshoot and oscillate before settling.](/figures/04-ti-family.svg)

*The **T<sub>i</sub>** family. Overshoot appears, and then grows.*

</div>
</div>

<!--
**Point at:** the first curve that crosses the setpoint and comes back. That crossing is new —
the proportional controller never did it, at any gain.

**Say, and this is the explanation people remember:** by the time the car reaches 110, the
integrator has been accumulating error for the whole climb, so it is already holding *more*
torque than 110 km/h needs. The only way to get rid of that excess is to generate error with
the opposite sign — which means spending time on the far side of the setpoint. The overshoot
is not a flaw in the tuning. It is how an integrator unwinds.

**Read out** the overshoot percentages from the cell output.

**Ask the room:** so what could we add that reacts *before* we arrive, rather than after?
*(Something that watches how fast we are closing. Straight into 05.)*

**Readout — every symbol on this slide**

- **T<sub>i</sub> = 40, 20, 10, 5, 2.5 s** — the sweep, from lazy to aggressive.
- **Overshoot** — the peak excursion past the setpoint, as a percentage of the commanded step.
  A 20 km/h step overshooting to 112 is 10 %.
- **Every one of these settles at 110** — the integrator guarantees that. The sweep is about
  the journey, not the destination.
-->

---

## What this bought us

- Zero steady-state error, for free, with no model in the controller.
- A demonstration that the integral path *is* the model inversion — the same number, found
  two ways.
- A new failure mode: overshoot, caused by unwinding.

### Next: a third path, to arrive without overshooting. <Link to="pid">→ 05, PID</Link>

<!--
**Flag forward, briefly:** an integrator that has accumulated more than the actuator can
deliver is a much worse problem than overshoot. That is section 06, and it is the one that
breaks real vehicles.
-->
