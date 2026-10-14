---
routeAlias: proportional-integral
layout: section
---

###### Notebook 04

# Proportional-integral

The integrator finds the holding torque without a model of the car.

`notebooks/lecture01/04-proportional-integral.ipynb`

<!--
One switch changes from the last notebook: `with_I = true`, integral on. Same car, same gain, same
step. An integrator is a block that keeps a running total of the error. In your diagram the change
is three blocks.
-->

---

## Adding an integral term

$$
u \;=\; k\left(e \;+\; \frac{1}{T_i}\int_0^t e\,d\tau\right)
$$

<div class="grid grid-cols-2 gap-8">
<div>

- The integral keeps a running total of the error.
- So it keeps *changing* for as long as any error remains.
- And it stops changing only when the error is exactly zero. Then it holds
  whatever value it has reached.

**Open in Dyad** `dyad/Lecture1/CruiseLoop.dyad`

</div>
<div>

> **Why this removes the error**
>
> An integrator's output at rest is *unconstrained by the error*. The proportional path does not
> have this freedom.

</div>
</div>

<!--
The proportional term uses the present error. The integral term uses all past error.

If the error has been zero for a while, what is the integral path putting out? Not zero: whatever
it accumulated before. Many of you will want to say zero. The next two slides show why it is not.

That is what the box on the right says. At zero error the proportional part must be zero, but the
integral part can hold any value.

T i, the integral time, is in seconds. It is a **time**, not a gain, and it divides, so a smaller
T i integrates harder. k multiplies the whole bracket. The tau inside the integral is only the
variable of integration, not the car's time constant from section 01.

In the reference, `with_I` is an ordinary parameter. The integrator is always in the diagram, and
an on/off block, `i_switch`, sits between it and the sum. With `with_I` false it passes zero. On
the next slide you get the same effect by adding the block.
-->

---
routeAlias: build-integrator
---

## Build: the integral path

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
using Plots; plotly()
r = MyCar.CruiseLoopTransient()
top = plot(r; idxs = [r."plant.v_kmh", r."demand.y"])
bottom = plot(r; idxs = r."controller.integrator.y")
plot(top, bottom; layout = (2, 1), link = :x, xlims = (0, 40))
```

[page: step 4](../lecture/lecture-01/#step-4) · reference `dyad/Lecture1/CruiseController.dyad`

<!--
The bracket becomes a summing block in front of the gain, with three inputs, one per term. Today
you fill two. The third waits for section 05.

In `CruiseController`, add two parameters: `Ti`, of type `Time`, default 10 seconds, and `xi0`,
of type Real, default 0. `xi0` is the integrator's starting state, the value its running total
starts from.

Delete the wire from `error.y` to `gain.u`.

Drag in an Add3, a block that adds three inputs, from `BlockComponents.Math`. Name it `add_pid`,
and set k one, k two and k three to 1.
Wire `error.y` into `add_pid.u1`, and `add_pid.y` into `gain.u`.

Drag in an Integrator from `BlockComponents.Continuous`, name it `integrator`, set k to 1 over
`Ti` and x zero to `xi0`. Wire `error.y` into `integrator.u`, and `integrator.y` into
`add_pid.u3`.

Drag in a Constant from `BlockComponents.Sources`, name it `zero_d`, set k to 0, and wire it into
`add_pid.u2`. It holds the derivative's slot.

Save, and run `CruiseLoopTransient` again from the Analyses list. In the Julia REPL, paste the code
from the slide. It plots `plant.v_kmh` and `demand.y` on top, and `controller.integrator.y`, the
integrator's running total, in a panel below.

The speed reaches **110 km/h**; the 0.7 gap is gone. On the way it overshoots: it passes 110,
peaks at about 115.5, and comes back down to settle on 110. The integrator state levels off near
**0.716**: 40.1 newton-meters divided by k equals 56. Two slides on, we multiply it back.

Your engine still clips at 150 and the notebook does not, so your first seconds differ, and the
notebook's peak is higher, 118.8. The settled 110 and 0.716 are the same.

Two common mistakes. Feeding the integrator from `add_pid.y` instead of `error.y`, so it
integrates its own output. And k set to `Ti` instead of 1 over `Ti`, so a bigger T i integrates
**harder**.
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

![Two step responses on one axes: the proportional run overshoots and then settles below the setpoint, the proportional-integral run overshoots a little further and then settles on it.](/figures/04-p-vs-pi.svg)

*Same gain, same step. P settles short; PI reaches the setpoint.*

</div>
</div>

<!--
The curves separate late, in the slow part. There the error is nearly zero, so the proportional
path does little, while the integral path keeps working.

Both runs use k equals 56; the PI run has T i equals 10 seconds. The torque ceiling is lifted to
one times ten to the six, which stands in for no limit.

P settles at 109.3. PI settles at 110.0. Proportional does the transient, the fast first part of
the response. Integral does the last stretch.

Both runs pass 110 on the way up. P peaks at 117.8, PI at 118.8. Overshoot is the peak past the
setpoint as a percentage of the 20 km/h step: 39 percent for P, 44 percent for PI. PI also takes
longer to settle. Arriving quickly and arriving exactly are different requirements, and PID tuning
is mostly trading one for the other.
-->

---

## The integrator finds the holding torque

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
- **40.1** N·m found by the integrator

*↩ Hands-on step 05: [where 40.1 N·m comes from](../handson-01/index.html#/top-speed)*

**Open in Dyad** `dyad/Lecture1/CruiseLoop.dyad`

</div>
<div>

![The integral path's output rising and leveling off exactly on a dashed horizontal line marking the analytically computed cruise torque.](/figures/04-integrator-state.svg)

*The integrator's state settles on the dashed line: the cruise torque we computed from the force balance, which the controller was never told.*

</div>
</div>

<!--
The dashed line is the force balance you solved with a pencil in hands-on step 05: the torque at
which the drive exactly cancels drag and rolling resistance at 110.

The controller was never given the mass, the drag area or the gear ratio. It sees only the speed
error. By accumulating it, the integrator found the holding torque: the same answer as solving the
model backwards. 40.122 against 40.119 newton-meters. The run is 90 seconds long, because the last
hundredths take most of a minute.

That is how an integrator removes steady-state error. It can hold an output while the error is
zero, and it keeps changing until it holds exactly the right one.

Put 200 kg of luggage in the trunk, and the line moves up. The integrator finds the new value
without being told.

`integrator.y` is the state before the gain; the plot multiplies by k. Your own build shows the
same curve, unscaled: it levels off at 0.716, and 56 times 0.716 is 40.1.

If your integrator settles anywhere else, the units or the gear ratio disagree between your model
and the notebook. Find that before you go on.
-->

---

## The cost: overshoot

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

*Still an unlimited engine. A smaller **T<sub>i</sub>** integrates harder. Every one of these settles at 110; they differ on the way there. The loop reaches the setpoint sooner, then overshoots it.*

</div>
<div>

![Five step responses at decreasing integral time: each reaches the setpoint sooner and the fastest ones overshoot and oscillate before settling.](/figures/04-ti-family.svg)

*The **T<sub>i</sub>** sweep. As T<sub>i</sub> shrinks, the overshoot grows.*

</div>
</div>

<!--
Every T i settles at 110; the integrator guarantees it. The sweep shows how each gets there.

The proportional run at this gain already overshot by 39 percent. The integrator
adds to that, and a smaller T i adds more. At T i equals 40 seconds the peak is 118.1, 40 percent.
At 10 seconds, 118.8, 44 percent. At 2.5 seconds, 122, 60 percent. The swings also take longer to
die out.

By the time the car reaches 110, the integrator has accumulated error for the whole climb, so it
holds **more** torque than 110 needs. It can only shed that excess with error of the opposite
sign: time on the far side of the setpoint. That is the overshoot.

To react **before** we arrive, we need a term that responds to how fast the error is shrinking.
That is section 05.
-->

---

## Summary of section 04

- Zero steady-state error, with no model in the controller.
- The integral path settles on the torque the model inversion gives: the same number, found
  two ways.
- A new problem: overshoot, while the integrator gets rid of its excess.

### Next: a third path, to arrive without overshooting. <Link to="pid">→ 05, PID</Link>

<!--
Model inversion means solving the car's equations backwards, from the speed we want to the torque
it takes, as you did by hand. The integrator found the same 40.1 newton-meters without them.

One warning. An integrator that has accumulated more than the engine can deliver is a much worse
problem than overshoot. That is section 06.
-->
