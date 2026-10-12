---
routeAlias: proportional-integral
layout: section
---

###### Notebook 04

# Proportional-integral

The integrator works out the answer you would otherwise have to compute by hand.

`notebooks/lecture01/04-proportional-integral.ipynb`

<!--
One boolean changes between the last notebook and this one. `with_I = true`. Same car, same
gain, same step. In your diagram it is three blocks.
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
Proportional is the present. Integral is the past. That is not a slogan. It is literally what
the two expressions compute.

If the error has been zero for a while, what is the integral path putting out? Whatever it
accumulated before. Not zero. Many of you will want to say zero, and the next two slides show
why it is not.

The integral keeps a running total of the error, in km/h times seconds. T i is the integral
time, in seconds. It is a **time**, not a gain, and it divides. So a smaller T i integrates
harder. This catches people out every single year. The gain k multiplies the whole bracket, so
it scales every path together. And the tau inside the integral is just the variable of
integration. It is not the plant's time constant. Unfortunate collision of names.

In the reference model, `with_I` is an ordinary parameter of `CruiseController`. The
integrator is always in the diagram, and an on/off block called `i_switch` sits between it and
the sum. With `with_I` false, the switch passes zero and the integrator holds still. So P and PI
are one model with one switch flipped. On the next slide you get the same effect by hand: you
add the block.
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

![plant.v_kmh reaching 110 km/h, with controller.integrator.y on a second axis.](/img/lecture-01/step04-pi-plot.png)

</div>
</div>

*Parameters `Ti` = 10, `xi0` = 0 · `add_pid` Add3 between `error` and `gain` · `integrator` Integrator(k = 1/Ti, x0 = xi0) on `u3` ·
`zero_d` Constant(k = 0) holds the derivative slot on `u2`*

```julia
using MyCar, Plots; plotly()
r = MyCar.CruiseLoopTransient()
top = plot(r; idxs = [r."plant.v_kmh", r."demand.y"])
bottom = plot(r; idxs = r."controller.integrator.y")
plot(top, bottom; layout = (2, 1), link = :x, xlims = (0, 40))
```

[page: step 4](../lecture/lecture-01/#step-4) · reference `dyad/Lecture1/CruiseController.dyad`

<!--
The formula has a bracket: the error, plus the integral over T i, all times k. So the diagram
gets a summing block in front of the gain, with three inputs, one for each term the finished
controller will have. Today two of them: the error, and its integral. The third slot waits for
section 05.

Let's build it together. Open `CruiseController`.

First, add two parameters. `Ti`, of type `Time`, default 10 seconds. And `xi0`, default 0.
That is the integrator's starting state.

Now delete the wire from `error.y` to `gain.u`.

Drag in an Add3 block from `BlockComponents.Math` and name it `add_pid`. Set k one, k two and k
three all to 1. Wire `error.y` into `add_pid.u1`, and `add_pid.y` into `gain.u`.

Next, drag in an Integrator from `BlockComponents.Continuous` and name it `integrator`. Set k to
1 over `Ti`, and x zero to `xi0`. Wire `error.y` into `integrator.u`, and `integrator.y` into
`add_pid.u3`.

Then drag in a Constant from `BlockComponents.Sources`, name it `zero_d`, and set k to 0. Wire
`zero_d.y` into `add_pid.u2`. It holds the derivative's slot, so `add_pid` has all three
inputs.

Save. Go back to `CruiseLoopStep` and run `CruiseLoopTransient` again. The analysis picks up
the changed controller.

Plot `plant.v_kmh` and `demand.y`, with `controller.integrator.y` in a panel below. The code is
on the slide.

You should see the speed reach **110 km/h**. The 0.7 km/h gap from step 3 is gone. And you
should see the integrator state rise and level off near **0.716**. That is 40.1 newton-meters
divided by k equals 56. On the punchline slide we multiply it back.

Your engine still clips at 150 newton-meters, and the notebook figures do not. So the first
seconds of your climb, and any overshoot, can differ from the notebook's. The settled 110 and
0.716 are the same.

Two mistakes are common. The first is feeding the integrator from `add_pid.y` instead of
`error.y`. Then it integrates its own output as well as the error. The second is setting k to
`Ti` instead of 1 over `Ti`. Then a bigger T i integrates **harder**, the opposite of the
convention.
-->

---

## PI against P

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [04-proportional-integral.ipynb · cell 1. Adding memory]
SPEED = "loop.plant.v_kmh"
GAIN, T_I, UNLIMITED = 56.0, 10.0, 1.0e6

p_only = Scenarios.CruiseLoopTransient(
    model = Scenarios.CruiseLoopStep(; name = :CruiseLoopStep,
                                     with_I = false, with_D = false),
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
Look at the place where the two curves separate. Not at the step, but afterwards, in the slow
part. The proportional path has already given up there, because its error is nearly zero. The
integral path is still working, because its input is still not zero.

Both runs use the same gain, k equals 56 newton-meters per km/h. The PI run has T i equals 10
seconds. Each run lasts 60 seconds, and the torque ceiling is lifted to one times ten to the
six, which stands in for no limit at all. The signal we plot is the plant's km/h output, inside
the loop, inside the harness.

The two terms do different jobs at different times. Proportional does the transient. Integral
does the last stretch. Watch for that division of labor again in the next section, where we
plot it directly.

Which one reached the setpoint faster, to within, say, 1 km/h? Usually P. Arriving eventually
and arriving exactly are different requirements, and PID tuning is mostly about trading one
for the other.
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

![The integral path's output rising and leveling off exactly on a dashed horizontal line marking the analytically computed cruise torque.](/figures/04-integrator-state.svg)

*The integrator's state settles on the dashed line — the cruise torque we computed from the force balance, which the controller was never told.*

</div>
</div>

<!--
This is the slide. Let's take it slowly.

Look at the dashed line first. Where did it come from? We solved the force balance at 110 km/h
with a pencil, back in hands-on step 05, and got 40 newton-meters.

Now look at the curve arriving at it. Nobody gave the controller the mass. Or the drag area.
Or the gear ratio. It has never seen the model. It has seen one number, how far off it was,
and by accumulating that it has **inverted the plant**.

The numbers agree. The integrator times k settles at 40.122 newton-meters at the end of the
run. The force balance gives 40.119. That is the same number to within 0.003 newton-meters.
The dashed line is drawn on so you can see the coincidence, not just take my word for it. The
run is 90 seconds long, longer than the step needs, because the last hundredths of a
newton-meter take most of a minute.

That is what "an integrator removes steady-state error" actually means. It is not a magic
property of the formula. The integrator can hold an output that the error no longer
justifies, and it will keep hunting until it holds exactly the right one.

What happens to that line if I put 200 kg of luggage in the trunk? It moves up, and the
integrator finds the new value without being told. That is the argument for feedback in one
sentence.

The integrator is inside `CruiseController`. It is the block you just placed. Its output,
`integrator.y`, is its state before the gain. The plot multiplies by k to get newton-meters.
The second axis from your own build shows the same curve, unscaled.

If your integrator settles anywhere other than the hand-computed torque, then the units or the
gear ratio disagree between your model and the notebook. That mismatch is worth finding, so
stop and find it.
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
Look at the first curve that crosses the setpoint and comes back. That crossing is new. The
proportional controller never did it, at any gain.

We sweep T i through 40, 20, 10, 5 and 2.5 seconds, from lazy to aggressive. Every one of
these settles at 110. The integrator guarantees that. The sweep is about the journey, not the
destination.

Here is the explanation to remember. By the time the car reaches 110, the integrator has been
accumulating error for the whole climb. So it is already holding **more** torque than 110 km/h
needs. The only way to get rid of that excess is to generate error with the opposite sign. That
means spending time on the far side of the setpoint. The overshoot is not a flaw in the tuning.
It is how an integrator unwinds.

Overshoot is the peak excursion past the setpoint, as a percentage of the step. A 20 km/h step
that overshoots to 112 is 10 percent. The notebook prints the overshoot for each T i. Watch it
grow as T i shrinks.

So what could we add that reacts **before** we arrive, rather than after? Something that
watches how fast we are closing. That is section 05.
-->

---

## What this bought us

- Zero steady-state error, for free, with no model in the controller.
- A demonstration that the integral path *is* the model inversion — the same number, found
  two ways.
- A new failure mode: overshoot, caused by unwinding.

### Next: a third path, to arrive without overshooting. <Link to="pid">→ 05, PID</Link>

<!--
One warning before we move on. An integrator that has accumulated more than the actuator can
deliver is a much worse problem than overshoot. That is section 06, and it is the one that
breaks real vehicles.
-->
