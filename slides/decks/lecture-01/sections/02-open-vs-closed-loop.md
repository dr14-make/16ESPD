---
routeAlias: open-vs-closed-loop
layout: section
---

###### Notebook 02

# Open loop versus closed loop

Feedforward is correct exactly as long as the world matches your model.

`notebooks/lecture01/02-open-vs-closed-loop.ipynb`

<!--
We have a model of the car that predicted its terminal speed correctly. So here is a fair
question, before we spend an hour on feedback. Why measure anything at all? Why not just compute
the right throttle and apply it?

This section is the motivation for everything that follows. It ends with the one diagram the rest
of the lecture never changes.
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

*The output is compared with the reference, and the difference — the error — is what the controller acts on.*

</div>
</div>

**Open in Dyad** `dyad/Lecture1/CruiseLoop.dyad`

<!--
Look at the left diagram. There is no wire coming back. That missing wire is the entire
difference, and everything else follows from it.

Feedforward needs a model, because the controller has to invert the plant. Given the speed you
want, it produces the torque that achieves it. Any error in that inversion becomes an error in the
output, permanently, and nothing corrects it.

And feedback is not obviously better. It is a hack we are forced into, because we cannot know the
plant and the world well enough. With perfect knowledge we would not want the extra wire at all.
It brings problems of its own, and those problems are what the rest of this lecture is about.

In the model, `CruiseLoop` is the right-hand picture, wired up. The setpoint goes into the
controller's `u_s`, and the plant's speed comes back into `u_m`. `CruiseController` has no
feedforward input at all. Later in this section you draw exactly this loop yourselves.

A few words, so we agree on them. Open loop, or feedforward, means u is computed from r alone. No
sensor, no error, no loop. Closed loop, or feedback, means u is computed from the error. The
output is fed back and compared. The comparator is the circle with plus and minus. It forms e
equals r minus y, and it is the only place the two signals meet. Model inversion means solving the
plant backwards. Given the output you want, which input produces it? That is all a feedforward
controller does.
-->

---

## Invert the model, and drive

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

> **It works**
>
> No sensor. No error signal. No controller worth the name — and the car sits on 90 km/h. On a
> flat, dry road, with the car we modeled, feedforward is exactly right.

</div>
</div>

<!--
This is not a trick. It is a legitimate control strategy. It is cheap, and it is fast. There is no
loop to be unstable, so it cannot oscillate. Feedforward is genuinely the right answer for a lot
of problems.

Look at the inversion in the code. That line is the controller. Everything the controller knows
about the car is in it: mass, drag area, rolling coefficient, wheel radius, gear ratio.

Let me read it with you. v is 90 divided by 3.6, which is 25 meters per second. We work in SI,
because the force balance is in SI. F is the total resisting force at that speed, in newtons: drag
plus rolling. tau_ff is F times r over i, which comes to 31.1 newton-meters at the engine.
Multiply by the wheel radius and divide by the gear ratio. That is the driveline equation run
backwards. And this single number is the controller. There is nothing else in it.

So what has to be true for this to keep working? Think of the assumptions hidden in that one
number. The road is flat, the car weighs what we modeled, and the air pushes back the way we
modeled. On the next slide we break exactly those assumptions.
-->

---

## Break it three ways

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

*Same torque, four worlds. Three of them settle somewhere the driver did not ask for.*

</div>
</div>

<!--
Here are the three wrong speeds. On a 1 percent grade, the car falls to 58.25 kilometers per hour.
With a 200 kilogram payload, it settles at 85.40. With 20 percent more drag area, it settles at
82.16.

Now the important part. Nothing in the controller went wrong. It computed 31.1 newton-meters, it
commanded 31.1, and it delivered 31.1. It is still correct. The world moved.

There is no error signal anywhere in this architecture, so nothing in the system is even capable
of noticing. The car is not failing to correct. It has no concept of correction.

A word on each world. A 1 percent grade means tan alpha is 0.01, about 0.57 degrees. That is a
gentle motorway rise, and it costs 137 newtons against the 401 newtons the engine is holding. The
200 kilogram payload takes the mass from 1400 to 1600 kilograms. That changes both the rolling
resistance and the slope term. The extra drag area is a roof box, or a headwind, because drag
depends on the relative airspeed. The dashed line is the 90 kilometers per hour target that nobody
is holding any more.

Which of the three would a driver notice first? The hill. And which would they never notice? The
payload. The car is just quietly slower than they asked, forever.
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

All three come back towards the target — without the controller being told which disturbance it
is facing, or that there is one.

</div>
<div>

![Two panels. Left: the same four worlds under proportional control, every run climbing back to within about two km/h of the 90 km/h target, with dotted lines marking where the open loop had settled. Right: the first twenty seconds magnified onto the last two km/h, showing the runs arriving within five seconds and the small error each one keeps.](/figures/02-closed-loop-recovered.svg)

*One controller, three different worlds, one outcome. That is the argument for feedback.*

</div>
</div>

<!--
This controller has no model. It does not know about the hill, or the luggage, or the wind. It
knows one number: how far off it is. And that is enough to handle three disturbances it was never
designed for.

Now look at the gap that remains between the curves and the target. It is still there, and it is
different for each disturbance. Hold that thought. Section 03 explains it.

So what did we give up to get this? Take a guess. Cost, complexity, a sensor: all of those are
partly right. The real answer is more interesting than any of them, and we come to it right after
the build.

Before we look at that cost, you draw this loop yourselves.
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
now, and it never changes again. Every step from here to section 08 happens inside the controller
box.

We build two new components. First, the controller shell.

In Components, right-click `MyCar`, choose Add Component, and name it `CruiseController`.

Now the ports, from the `Dyad` library. A `RealInput` named `u_s` on the left edge. That is the
setpoint, in kilometers per hour. A `RealInput` named `u_m` on the bottom edge. That is the
measured speed, also in kilometers per hour. And a `RealOutput` named `y` on the right edge. That
is the torque command, in newton-meters. Use exactly these names. Every notebook and the reference
use them.

Now drag in `BlockComponents.Math.Add` and name it `error`. Set k one to 1 and k two to minus 1.
This block is the comparator, the circle with plus and minus in every block diagram.

Wire `u_s` into `error.u1`, and `u_m` into `error.u2`. Leave `error.y` and `y` open for now.

Second, the loop. Add Component, and name it `CruiseLoopStep`.

Drag in four blocks and name them exactly. First, `demand`. That is
`BlockComponents.Sources.Step`, with offset 90, height 20, and start time 0. It is the setpoint,
going from 90 to 110 kilometers per hour at the start of the run. Second, `controller`, which is
your `CruiseController`. Third, `plant`, which is your `GradeCar`. Fourth, `road`. That is
`BlockComponents.Sources.Constant`, with k equal to 0. A flat road, for now.

Now the wires. `demand.y` into `controller.u_s`. `controller.y` into `plant.tau_cmd`. `road.y`
into `plant.grade`. And `plant.v_kmh` into `controller.u_m`. That last wire is the feedback.

Switch to code and add the starting state. We are cruising at 90 kilometers per hour, with the
engine already holding 31.078 newton-meters. So: initial `plant.body.mass.s` equals 0. Initial
`plant.body.mass.v` equals 25. Initial `plant.engine.lag.x` equals 31.078. Save.

Now Run Analysis. Choose TransientAnalysis of `CruiseLoopStep`, name it `CruiseLoopTransient`, and
set stop to 100. Do not run it yet.

Why is the step at time zero? A step later in the run would give the P controller of step 3 an
interval at zero error. In that interval it commands zero torque, and the car slows down.

Nothing runs yet. `controller.y` has no source until the gain goes in at step 3, so the problems
panel reports it. That is expected. Check your two diagrams against the screenshots: four blocks
and four wires in the loop, and two wires into `error`.

The names matter. `plant`, `controller` and `error` are the reference instance names, so your
signal paths and the notebooks' read the same. The reference wraps the loop one level deeper, so
there it is `loop.plant.v_kmh`. Your `CruiseLoopStep` is flat, so for you it is `plant.v_kmh`.

The common mistake here is k two set to plus 1 on `error`. Then the loop adds the measurement to
the setpoint, and it runs away the moment it can run. The parameter panel in the right-hand
screenshot is your check: k one is 1, k two is minus 1.
-->

---

## What feedback costs

### Feedforward changes how a system is *operated*.

### Feedback changes what the system *is*.

*The controller sets the rate of change as a function of the current state, and that
relationship is new dynamics — dynamics the car did not have before you wired it up.*

> **Which cuts both ways**
>
> You can take an unstable system and make it stable. You can also take a perfectly stable car
> and make it oscillate, or worse. A badly tuned loop is more dangerous than no loop at all —
> and it is why the rest of this lecture exists.

<!--
This is the sentence to take away from the section. Feedforward cannot destabilize anything,
because there is no loop. Feedback can, because there is.

That is why control engineering spends so much of its effort on analysis rather than on design.
Designing a controller that works on a good day is not hard. Proving that it cannot do harm on a
bad one is the job.

We will see the loop destabilize twice today. Once on purpose in section 08, to measure it. And
once by accident in section 09, from nothing more than a slow processor.

By dynamics I mean how a system evolves: its poles, its time constants, its stability. Feedforward
leaves them alone. Feedback rewrites them. And stability means whether a disturbance dies out or
grows. Feedback can create it, and feedback can destroy it.
-->

---

## What this bought us

- A working feedforward controller — and three ordinary situations that defeat it.
- The reason feedback exists: the world moves, and only an error signal notices.
- The warning: feedback changes the dynamics, so it can make things worse.

### Next: the simplest thing that uses an error signal. <Link to="proportional">→ 03, proportional</Link>

<!--
So we need feedback. Let us start with the least clever thing we could possibly do with an error
signal: multiply it by a number.
-->
