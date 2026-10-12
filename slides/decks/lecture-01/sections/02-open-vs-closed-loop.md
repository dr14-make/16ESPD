---
routeAlias: open-vs-closed-loop
layout: section
---

###### Notebook 02

# Open loop versus closed loop

Feedforward works only while the road and the car match the model.

`notebooks/lecture01/02-open-vs-closed-loop.ipynb`

<!--
Our model predicted the car's terminal speed correctly. So why measure anything at all? Why not
compute the right throttle and apply it?

This section answers that, and ends with the loop diagram we use for the rest of the lecture.
-->

---

## Two architectures

<div class="grid grid-cols-2 gap-8">
<div>

#### Open loop — feedforward

![Open-loop block diagram: reference into controller into plant, producing an output, with a disturbance entering the plant and no path back.](/diagrams/02-open-loop.svg)

*The reference is fed forward and never comes back. There is no error signal anywhere in this picture.*

</div>
<div>

#### Closed loop — feedback

![Closed-loop block diagram: reference into a summing junction that subtracts the measured output, then controller, then plant, with a disturbance entering the plant and the output fed back to the summing junction.](/diagrams/02-closed-loop.svg)

*The output is compared with the reference, and the controller acts on the difference, the error.*

</div>
</div>

**Open in Dyad** `dyad/Lecture1/CruiseLoop.dyad`

<!--
The left diagram has no wire coming back from the output. That is the whole difference.

Feedforward runs the plant model backwards: from the speed you want, it computes the torque. Any
error in that model stays in the output, and nothing corrects it.

Feedback is not automatically better. We use it because we never know the plant and its
surroundings well enough. Feedback brings problems of its own, and the rest of this lecture is
about them.

In the model, `CruiseLoop` is the right-hand picture: the setpoint goes into the controller's
`u_s`, and the plant's speed comes back into `u_m`. You draw this loop yourselves later in this
section.

Open loop computes u from r alone: no sensor, no error. Closed loop computes u from the error. The
comparator, the circle with plus and minus, forms e equals r minus y. It is the only place the two
signals meet. Model inversion means solving the plant backwards, from the output you want to the
input that gives it. That is all a feedforward controller does.
-->

---

## Feedforward: the torque from the model

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

```julia [02-open-vs-closed-loop.ipynb · cell Invert the model]
Scenarios = VehicleSystemsComponents.Lecture1

v = 90 / 3.6                                  # m/s
F = 0.5 * CAR.rho * CAR.CdA * v^2 +           # drag
    CAR.f_r * CAR.m * CAR.g                   # rolling
tau_ff = F * CAR.r / CAR.i                    # N.m at the engine

nominal = Scenarios.FeedforwardCruiseTransient(
    tau_ff = tau_ff, stop = 1200.0)
plot_speed(nominal; setpoint = 90)
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/02-open-vs-closed-loop.ipynb)

</div>
<div>

- **31.1** N·m computed
- **90.0** km/h achieved

> **Feedforward holds the speed**
>
> There is no sensor and no error signal, and the car holds 90 km/h. On a flat, dry road, with
> the car we modeled, feedforward is exactly right.

</div>
</div>

<!--
Feedforward is a valid strategy. It is cheap and fast, and with no loop it cannot oscillate.

The inversion line is the whole controller. Everything it knows about the car is in there: mass,
drag area, rolling coefficient, wheel radius, gear ratio.

v is 90 divided by 3.6, 25 meters per second; we work in SI because the force balance is in SI. F
is drag plus rolling at that speed. tau_ff is F times r over i, the driveline equation run
backwards: 31.1 newton-meters.

That number assumes a flat road, the mass we modeled and the drag we modeled. The next slide
changes each one.
-->

---

## Feedforward with a grade, a payload and more drag

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [02-open-vs-closed-loop.ipynb · cell Break it three ways]
WORLDS = [("flat road, nominal car", (grade = 0.0,  m = CAR.m,       CdA = CAR.CdA)),
          ("1% grade",               (grade = 0.01, m = CAR.m,       CdA = CAR.CdA)),
          ("200 kg payload",         (grade = 0.0,  m = CAR.m + 200, CdA = CAR.CdA)),
          ("20% more drag area",     (grade = 0.0,  m = CAR.m,       CdA = 1.2 * CAR.CdA))]

open_loop = [name => Scenarios.FeedforwardCruiseTransient(
                 tau_ff = tau_ff, grade = w.grade, m = w.m, CdA = w.CdA,
                 stop = 1200.0)
             for (name, w) in WORLDS]

plt = plot(; xlabel = "time [s]", ylabel = "speed [km/h]")
for (name, sol) in open_loop
    plot!(plt, signal(sol, "plant.v_kmh")...; lw = 2, label = name)
end
hline!(plt, [90]; ls = :dash, color = :black, label = "target")
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/02-open-vs-closed-loop.ipynb)

</div>
<div>

![Four open-loop runs against a 90 km/h target over twenty minutes: the nominal case sits on target, while the 1% grade, the 200 kg payload and the 20% larger drag area each settle at a visibly different wrong speed, the grade lowest.](/figures/02-open-loop-broken.svg)

*The same torque in four conditions. In three of them the car settles away from 90 km/h.*

</div>
</div>

<!--
On a 1 percent grade the car falls to 58.25 kilometers per hour. With a 200 kilogram payload it
settles at 85.40. With 20 percent more drag area, 82.16.

The controller did nothing wrong. It computed 31.1 newton-meters and delivered 31.1. The road and
the car changed, and with no error signal nothing can notice.

A 1 percent grade is about 0.57 degrees, a gentle motorway rise. It costs 137 newtons against the
401 the engine is holding. The payload raises both the rolling resistance and the slope term. The
extra drag area is a roof box, or a headwind.

A driver notices the hill. The payload they may never notice: the car just stays slower than they
asked.
-->

---

## Close the loop

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [02-open-vs-closed-loop.ipynb · cell Close the loop]
# the same four worlds, now with the loop closed
K = 25.0                   # N.m per km/h
UNLIMITED = 1.0e6          # N.m — both torque ceilings lifted

closed = [name => Scenarios.CruiseLoopTransient(
              model = Scenarios.CruiseLoopStep(; name = :CruiseLoopStep,
                                               with_I = false, with_D = false),
              k = K, v_lo = 90.0, v_hi = 90.0,
              grade = w.grade, m = w.m, CdA = w.CdA,
              T_max = UNLIMITED, y_max = UNLIMITED, stop = 60.0)
          for (name, w) in WORLDS]

for (name, sol) in closed
    plot!(plt, signal(sol, "loop.plant.v_kmh")...; lw = 2, label = name)
end
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/02-open-vs-closed-loop.ipynb)

All three come back toward the target, although the controller is not told which disturbance it
faces, or that there is one.

</div>
<div>

![Two panels. Left: the same four worlds under proportional control, every run climbing back to within about two km/h of the 90 km/h target, with dotted lines marking where the open loop had settled. Right: the first twenty seconds magnified onto the last two km/h, showing the runs arriving within five seconds and the small error each one keeps.](/figures/02-closed-loop-recovered.svg)

*One controller, without knowing the disturbance, brings all three cases back near the target.*

</div>
</div>

<!--
This controller has no model. It knows only how far off the speed is, and that is enough to handle
three disturbances it was never designed for.

A gap to the target remains, different for each disturbance. Section 03 explains it.

What did we give up for this? Cost, complexity and a sensor are all partly right. The main cost is
something else, and we come to it right after you draw this loop.
-->

---
routeAlias: build-loop
---

## Build: the loop, and an empty controller

<div class="grid grid-cols-[1.4fr_1fr] gap-6">
<div>

![CruiseLoopStep: the demand step into the controller, the controller into the plant (GradeCar), the road constant into the plant's grade input, and the plant's speed fed back to the controller.](/img/lecture-01/step02-loop.png)

</div>
<div>

![CruiseController in progress: ports u_s, u_m and y, and the error block only, with its parameter panel showing k1 = 1 and k2 = -1.](/img/lecture-01/step02-controller-shell.png)

</div>
</div>

*New `CruiseController`: ports `u_s`, `u_m`, `y` · `error` Add(k1 = 1, k2 = −1) from `u_s`, `u_m` ·
new `CruiseLoopStep`: `demand` Step(offset = 90, height = 20) → `controller` → `plant` (`GradeCar`) · `road` Constant(k = 0) · speed back to `u_m` ·
TransientAnalysis `CruiseLoopTransient`, `stop = 100`*

[page: step 2](../lecture/lecture-01/#step-2) · reference `dyad/Lecture1/CruiseLoop.dyad`

<!--
This is the right-hand diagram from the start of the section, as a Dyad model. You draw it once,
now. Every later step either changes the controller, adds a parameter to `GradeCar`, or copies
this loop into a new bench.

First, the controller shell. In Components, right-click `MyCar`, Add Component, name it
`CruiseController`.

Three ports from the `Dyad` library. A `RealInput` named `u_s` on the left edge: the setpoint, in
kilometers per hour. A `RealInput` named `u_m` on the bottom edge: the measured speed. A
`RealOutput` named `y` on the right edge: the torque command, in newton-meters. Use exactly these
names; the notebooks use them.

Drag in `BlockComponents.Math.Add`, name it `error`, set k one to 1 and k two to minus 1. That is
the comparator. Wire `u_s` into `error.u1` and `u_m` into `error.u2`. Leave `error.y` and `y`
open.

Second, the loop: Add Component, `CruiseLoopStep`. Four blocks, named exactly. `demand` is
`BlockComponents.Sources.Step`, offset 90, height 20, start time 0. `controller` is your
`CruiseController`. `plant` is your `GradeCar`. `road` is `BlockComponents.Sources.Constant`, k
equal to 0.

Wire `demand.y` into `controller.u_s`, `controller.y` into `plant.tau_cmd`, `road.y` into
`plant.grade`, and `plant.v_kmh` into `controller.u_m`. That last wire is the feedback.

In code, add the starting state, cruising at 90 with the engine holding 31.078 newton-meters.
Initial `plant.body.mass.s` equals 0. Initial `plant.body.mass.v` equals 25. Initial
`plant.engine.lag.x` equals 31.078. Save.

Run Analysis: TransientAnalysis of `CruiseLoopStep`, named `CruiseLoopTransient`, stop 100. Do not
run it yet: `controller.y` has no source until step 3, and the problems panel says so. That is
expected.

The step is at time zero because a later step would give the P controller of step 3 a stretch at
zero error, where it commands zero torque and the car slows down.

Check against the screenshots: four blocks and four wires in the loop, two wires into `error`. The
reference wraps the loop one level deeper, as `loop.plant.v_kmh`; yours is `plant.v_kmh`.

The common mistake is k two set to plus 1. Then the speed runs away as soon as there is torque.
Check the parameter panel: k one is 1, k two is minus 1.
-->

---

## What feedback costs

### Feedforward changes how a system is *operated*.

### Feedback changes the system's *dynamics*.

*The controller makes the rate of change depend on the current state. That adds dynamics the car
did not have before you wired the loop.*

> **Stabilizing or destabilizing**
>
> You can take an unstable system and make it stable. You can also take a stable car and make it
> oscillate or become unstable. A badly tuned loop can be more dangerous than no loop at all, and
> most of this lecture is about tuning it.

<!--
Feedforward cannot destabilize anything, because there is no loop. Feedback can.

That is why control engineering spends so much effort on analysis. A controller that works on a
good day is easy. Showing that it does no harm on a bad one is the hard part.

You will see the loop go unstable twice today: on purpose in section 08, to measure it, and by
accident in section 09, from nothing more than a slow processor.

Dynamics means how fast a system responds, whether it oscillates, whether it is stable. Stable
means a disturbance dies out instead of growing. Feedback can create stability, and it can remove
it.
-->

---

## Summary of section 02

- A working feedforward controller, and three ordinary situations where it misses the target.
- Why we need feedback: when the road or the car changes, only an error signal detects it.
- The warning: feedback changes the dynamics, so it can make things worse.

### Next: the simplest thing that uses an error signal. <Link to="proportional">→ 03, proportional</Link>

<!--
We need feedback. The simplest thing to do with an error signal is to multiply it by a number.
-->
