---
routeAlias: windup
layout: section
---

###### Notebook 06

# Integral windup

The integrator keeps accumulating after the engine reaches its torque limit.

`notebooks/lecture01/06-windup.ipynb`

<!--
So far the model was linear: ask for twice the torque and you get twice the torque, at any size.
This section adds the first thing that breaks that rule, the engine's torque limit. The failure we
are about to see has destroyed real hardware.

Four build steps. One in `GradeCar`, your car model. One in `CruiseController`, the controller you
built in section 05. Then a new test model that drives the car up a hill, and one equation.
-->

---

## Actuator and process

<div class="grid grid-cols-[1.2fr_1fr] gap-8">
<div>

- The **actuator** — the thing that supplies the force. Our engine.
- The **process** — the thing being pushed. Our car.

Real actuators have backlash, rate limits and **saturation**.
A linear model has none of these: ask it for a million newton-meters and it delivers them.

**Open in Dyad** `dyad/HandsOn/Engine.dyad` — the `limiter` after the lag

</div>
<div>

> **The hill we are about to drive up**
>
> 130 km/h on a sustained 10 % climb needs **2023 N** at the road.
>
> The engine can deliver **1935 N**.
>
> The car slows down toward about **118 km/h**; a 120 s climb gets it to **119.05**,
> still falling.

*↩ Hands-on step 07: [the slope, and the 2023 N sum](../handson-01/index.html#/slope)*

![A car on a road tilted by angle alpha: its weight splits into m g sine alpha along the road, pulling it back downhill, and m g cosine alpha into the road.](/diagrams/07-slope.svg)

</div>
</div>

<!--
The actuator is the part that does the pushing, here the engine. The process is what gets pushed,
here the car.

The numbers in the box come from the force balance of hands-on step 07, the slope step. You can
compute them yourself.

The climb at 130 km/h on a 10 % grade asks for 2023 newtons: 1366 to lift the car up the slope,
493 of air drag and 164 of rolling resistance. The engine gives 1935, 88 newtons or four percent
short. That is an ordinary case: a loaded car on a long climb. The car heads for about 118 km/h
but never gets there. The climb lasts 120 seconds, and at the crest the car is at 119.05 km/h and
still falling.

At the limit, the controller sees only a speed that is too low. Nothing tells it the engine is
maxed out. We come back to this in two slides.

In the engine, the ceiling is the `limiter`, a block that passes its input through but cuts it off
at an upper and a lower bound. Its upper bound, `y_max`, is `T_max`, 150 newton-meters. Its lower
bound, `y_min`, is zero. The zero matters
too. This engine cannot make negative torque, so it cannot brake. Downhill it cannot slow the car.

Real actuators misbehave in several ways. Backlash is play in the gears. A rate limit means the
actuator cannot change faster than some speed. Today we look at the third: when an actuator sits
at its limit and cannot follow its command, we call that **saturation**.
-->

---
routeAlias: step-6a
---

## Step 6a: the torque limit becomes a parameter

![GradeCar's parameter panel with T_max, and the engine selected so its binding T_max = T_max shows.](/img/lecture-01/step06-tmax.png)

*Your `GradeCar` · add `parameter T_max::Torque = 150` · `engine`: `T_max = T_max`*

[page: step 6a](../lecture/lecture-01/#step-6a) · reference `dyad/Lecture1/Step06a/GradeCar.dyad`

<!--
The engine has had a 150 N·m ceiling since hands-on step 02: the `limiter` inside it. Today we
need to set it from outside, so it moves up one level, onto the car.

A parameter is a named number on a model that you can change from outside without opening it.

Open your `GradeCar`. Click an empty spot of the canvas and choose Add parameter: name `T_max`,
type `Torque`, value 150, description "Peak deliverable torque". Then click `engine` and set its
`T_max` to `T_max`. The engine already has that parameter, so we only link the engine's setting to
the car's new one. No blocks, no wires.

Run `CruiseLoopTransient`, the section 05 loop, again. 150 is the default, so the curve must not
change: the same peak of 113.98 km/h, settling at 110. If it moved, you linked the wrong block.

`T_max` is a fact about the hardware. Next, the controller gets its own number, and the rest of
the section is about what happens when the two disagree.
-->

---
routeAlias: step-6b
---

## Step 6b: the controller gets a limit of its own

![CruiseController in progress: gain feeds the limiter, and the limiter feeds the output y.](/img/lecture-01/step06-limiter.png)

*Your `CruiseController` · `parameter y_max::Real = 1e300`, `parameter y_min::Real = -y_max` ·
`Limiter(y_max = y_max, y_min = y_min)` between `gain` and `y` · `CruiseLoopStep`: `controller` `y_max = 150`, `y_min = 0`*

```julia
using Plots; plotly()
r = MyCar.CruiseLoopTransient()
plot(r; idxs = [r."controller.y", r."controller.gain.y"], xlims = (0, 20))
```

[page: step 6b](../lecture/lecture-01/#step-6b) · reference `dyad/Lecture1/CruiseController.dyad`

<!--
The engine refuses anything above 150. The controller does not know that: it can ask for a
thousand N·m and the engine silently clips it. So we give the controller its own ceiling, and it
can see when it asks for more than it gets.

Inside your `CruiseController`, add two parameters: `parameter y_max::Real = 1e300`, "Maximum
output", and `parameter y_min::Real = -y_max`, "Minimum output". 1e300 is a one followed by three
hundred zeros, so by default there is no limit and the controller behaves exactly as before.

Drag in `BlockComponents.Nonlinear.Limiter`, name it `limiter`, and set its `y_max` to `y_max` and
its `y_min` to `y_min`. Delete the wire from `gain.y` to `y`. Wire `gain.y` into `limiter.u`, and
`limiter.y` into `y`.

In `CruiseLoopStep`, select `controller` and set `y_max` to 150 and `y_min` to zero. Zero, because
this engine cannot brake. The reference `CruiseLoop` uses `y_max` equal to `T_max`, and zero.

Re-run `CruiseLoopTransient`. Plot `controller.y`, the command after the limiter, together with
`controller.gain.y`, the command before it, using the code on the slide. The step from 90 to 110
km/h asks for more than 150 N·m at the start, so `controller.y` sits flat on 150 for the first
moments instead of rising above it. It stays between 0 and 150 throughout, and the speed still
reaches 110. The gap between the two curves is the saturation.

Use the names `limiter` and `gain.y` exactly. The notebooks and the clamping equation in step 6d
look for them.
-->

---
routeAlias: step-6c
---

## Step 6c: drive up the hill

<div class="grid grid-cols-2 gap-8">
<div>

![The climb harness: a constant 130 km/h demand, the controller and the GradeCar plant, with a pulse driving the road input.](/img/lecture-01/step06-climb.png)

</div>
<div>

![Speed, controller output and integrator state through the climb and after it: the integrator keeps climbing while the engine is saturated, and the speed overshoots after the crest.](/img/lecture-01/step06-windup-plot.png)

</div>
</div>

*Duplicate `CruiseLoopStep` → `CruiseClimb` · `demand` → `Constant(k = 130)` ·
`road` → `Pulse(amplitude = 0.10, offset = 0, start_time = 30, duty_cycle = 1.0, period = 120)` ·
`controller.xd0 = -130` · start at 130 km/h*

```julia
using Plots; plotly()
r = MyCar.CruiseClimbTransient()
top = plot(r; idxs = r."plant.v_kmh")
bottom = plot(r; idxs = [r."controller.y", r."controller.gain.y",
                         r."controller.integrator.y"])
plot(top, bottom; layout = (2, 1), link = :x)
```

[page: step 6c](../lecture/lecture-01/#step-6c) · reference `CruiseClimb` in `dyad/Lecture1/WindupClimb.dyad`

<!--
Now we drive up the hill. Only the road changes; the controller does not.

Right-click `CruiseLoopStep`, choose Duplicate, and name the copy `CruiseClimb`, the name the
course's reference model uses. `CruiseLoopStep` stays as it is, a safe point to come back to. Keep
the block names: `demand`, `controller`, `plant` and `road`.

Replace `demand` with `BlockComponents.Sources.Constant`, a block that outputs one fixed number:
`k` equal to 130, wired into `controller.u_s`, the setpoint input. The setpoint is the speed we ask
for.

Replace `road` with a Pulse from BlockComponents, Sources, named `road`: `amplitude` 0.10,
`offset` zero, `start_time` 30, `duty_cycle` 1.0, `period` 120. Wire `road.y` into `plant.grade`.
The pulse outputs 0.10, a 10 % grade, from 30 seconds for 120 seconds, so the hill starts at 30
and ends at 150. The reference wraps the same pulse in its `GradeProfile`, which your `MyCar`
library cannot see.

On `controller`, keep `k` 56, `Ti` 10, `Td` 0.5, `y_max` 150 and `y_min` zero. Set `xd0` to
minus 130. `xd0` is the starting value of the derivative's filter, and it must match the speed the
run starts at. The default, minus 90, matches a 90 km/h cruise. This run cruises at 130. Leave
minus 90 and the run opens with a derivative kick: a huge, brief spike in the command at the first
instant.

Toggle to the code view and change the three `initial` lines, the starting state, to the
reference's values. `initial plant.body.mass.s = 0`. `initial plant.body.mass.v =
36.111111111111114`, which is 130 km/h in meters per second. `initial plant.engine.lag.x =
50.9693`, the torque that holds 130 km/h on the flat. So the car starts already cruising.

Run Analysis, TransientAnalysis, that is a simulation over time, name it `CruiseClimbTransient`,
`stop` 400 seconds. Run it and plot with the code on the slide: `plant.v_kmh` on top; below it
`controller.y` after the limiter, `controller.gain.y` before it, and `controller.integrator.y`,
the integrator's output, which grows for as long as the car is too slow.

What you should see. The speed sags from 130 after 30 seconds, toward about 118, and is at 119.05
at the crest. `controller.y` lies flat on 150 through the climb. `controller.gain.y` keeps
climbing, to about 6000 newton-meters at the crest, forty times the engine's 150. The integrator
drives it there. Its trace looks flat on this axis, so hover the mouse over it to read it: it
peaks at about 97 just after the crest, and 56 times 97 is over 5400 newton-meters. After 150
seconds comes the overshoot, the speed shooting past what we asked for, to almost 180 km/h. The
notebook's run peaks 49.47 km/h over the setpoint and takes 66.7 seconds to get back within half a
km/h of 130.

This is the "none" row, no protection at all, of the table we see shortly. If your overshoot is a few km/h rather than
tens, your integrator is not wired from `error`. Fix that before we go on.
-->

---

## The climb, with an ordinary PID controller

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [06-windup.ipynb · cell The climb, no anti-windup]
Scenarios = VehicleSystemsComponents.Lecture1

SPEED     = "loop.plant.v_kmh"
COMMAND   = "loop.controller.gain.y"        # before the limiter
DELIVERED = "loop.plant.engine.limiter.y"   # on the crankshaft
INTEGRAL  = "loop.controller.integrator.y"

# Clamping acts only when the command reaches a limit; limits it never
# reaches give the controller with no anti-windup at all.
no_aw = Scenarios.ClampingCruiseClimbTransient(
    k = 56.0, Ti = 10.0, Td = 0.5, y_max = 1.0e6, y_min = -1.0e6,
    v_set = 130.0, gradient = 0.10,
    start_time = 30.0, duration = 120.0, stop = 400.0)

plot_speed(no_aw; sig = SPEED, setpoint = 130)
plot_torque(no_aw; commanded = COMMAND, delivered = DELIVERED)
signal(no_aw, INTEGRAL)                 # the integrator, separately
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/06-windup.ipynb)

**Open in Dyad** `dyad/Lecture1/WindupClimb.dyad`

</div>
<div>

![Stacked traces through a sustained climb: speed falling below the setpoint, delivered torque pinned flat on the limit line, commanded torque and the integrator state climbing far above it.](/figures/06-climb-windup.svg)

*Delivered torque is flat on the limit. Commanded torque and the integrator keep climbing anyway.*

</div>
</div>

<!--
Speed first: it sags away from the setpoint at 30 seconds. Delivered torque lies flat on the
limit: the engine gives all it can. Commanded torque keeps rising far past the limit, to 5945 N·m
at the crest, forty times the 150 limit. The integrator drives it there: its share alone is 5334
N·m at the crest.

The integrator's rule is: while there is an error, keep accumulating. Nothing tells it that a
bigger command no longer gives more torque.

Picture holding a drone on the ground while it tries to fly to 50 meters. The propellers max out
at 1000 rpm. The integrator winds the command up to 2000. The next slide is what happens when you
let go.

In the model, `gradient`, `start_time` and `duration` set the hill. A `gradient` of 0.10 is a 10 %
climb, about 5.7 degrees. It starts at 30 seconds and lasts 120, so the road flattens at 150. The
setpoint, `v_set`, is 130 km/h. The overshoot comes after the road flattens.

We plot the integrator separately because the problem is there, and the speed trace hides it.

Anti-windup is any logic that stops the integrator running away like this. The controller limits
here are one million and minus one million. The command never reaches them, so there is no
anti-windup at all, on purpose. The engine still stops at 150 N·m.
-->

---

## Why the overshoot follows

When the road flattens at t = 150 s, the car accelerates. The error changes sign. The
integrator starts to decrease, or *unwind*.

But it is unwinding *from far above the limit*. While the command falls from about 6000 N·m
to 150, the engine delivers the same full torque it was delivering before.

**Nothing the car does can be seen at the output until the command comes back inside the
limit.**

> **What sets the delay**
>
> The delay between "the error changed sign" and "the actuator responded" is not set by the
> plant, or by the gains. It is set by how far the integrator rose above the limit during
> saturation.

<!--
With the drone: the integrator asks for 2000 rpm, the motors do 1000. Let go. The drone shoots
past 50 meters, and the error goes negative. The integrator comes down: 1900, still 1000 at the
motors. 1500, still 1000. 1100, still 1000. Only at 1000 does anything change. By then the drone
is far above 50 meters.

Winding up does no harm by itself. Commanding 6000 N·m from a 150 N·m engine hurts nothing. The
harm is the time it takes to unwind.

Two terms. **Windup** is an integrator accumulating past what the actuator can act on.
**Unwinding** is coming back down. Until the command falls back inside the limit, nothing reaches
the engine. Whatever the speed does, the engine gets the same full torque: the controller has
stopped steering.

Before the next cell: how far past 130 km/h do we go? Give me two guesses, and I will write them
on the board. The answer is on the next slide.
-->

---

## The overshoot

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [06-windup.ipynb · cell The overshoot]
t, v = signal(no_aw, SPEED)

plt = plot_speed(no_aw; sig = SPEED, setpoint = 130)
vline!(plt, [30.0, 150.0]; ls = :dot, color = :gray,
       label = "climb starts / ends")

# The car starts AT the setpoint, so there is no step to normalize
# against: `overshoot` would divide by zero. Measure the excess.
peak = maximum(v)
@show peak peak - 130 t[argmax(v)]      # km/h, km/h over, s
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/06-windup.ipynb)

> **In a real car**
>
> This is a cruise control that, at the top of a long climb, accelerates hard for several
> seconds while the driver is doing nothing at all.

</div>
<div>

![Speed through and after the climb: a sag during the climb, then a large overshoot above the setpoint once the road flattens, before settling back.](/figures/06-overshoot.svg)

*The road flattens at t = 150 s, and the car keeps accelerating well past the setpoint before the integrator has unwound.*

</div>
</div>

<!--
The car peaks at 179.47 km/h, 21.6 seconds after the crest: 49.47 km/h over the setpoint. It takes
66.7 seconds to come back within half a km/h of 130. Compare that with
the guesses on the board.

Nobody commanded this. The driver asked for 130 and the car did something else. A control failure
that surprises the operator is a safety problem, whatever the numbers say.

The excursion is the peak minus 130. We do not use the `overshoot` helper here: it divides by the
step size, and this run has no step. The dotted lines mark the start and end of the climb.

What would you change to stop it? The usual first answer is "limit the output". On its own that is
not enough: our controller already has a limit in step 6b, and the integrator still winds up behind
it. The answer is to stop the integrator itself from accumulating while the engine is at its
limit. That is the next slide.
-->

---

## Clamping: two conditions

![Block diagram of the clamping anti-windup logic: the controller output is compared before and after the saturation block, the sign of the error is compared with the sign of the output, and when both tests pass an AND gate switches the integrator input to zero.](/diagrams/06-clamping.svg)

*Both true → stop integrating. Either one false → the integrator is restored and starts coming down immediately.*

<!--
The first fix is called clamping: freeze the integrator while the engine is at its limit.

Follow the diagram: the output, the saturation block, the two comparisons, the AND block, which
says yes only when both its inputs say yes, and the switch back into the integrator.

The first check compares the output before and after saturation. Equal means inside the limit. Not
equal means saturating.

The second check: do the error and the output have the same sign? Then the integrator is pushing
further into the saturated direction, and integrating only winds it up more.

Only when both are true does the integrator's input switch to zero. It freezes. It does not reset
or decay. It holds, and moves again the moment either condition stops.

Clamping does not mean capping the integrator at some value. A fixed cap still winds up to the cap
and still has to unwind. Clamping stops the accumulation conditionally, which is why it is also
called conditional integration.

The other common method is back-calculation. It takes the part of the command the engine could
not deliver and feeds it back to pull the integrator down. We compare both shortly.
-->

---
routeAlias: step-6d
---

## Step 6d: clamping as an equation

<div class="grid grid-cols-2 gap-8">
<div>

![CruiseController code view: the integrator input given by a nested ifelse equation that freezes it while the output is saturated and the error pushes further into the limit.](/img/lecture-01/step06-clamping-code.png)

</div>
<div>

![The same three signals as the windup run, on the same axes, with clamping: the integrator holds flat while saturated and the speed returns to the setpoint after the crest with almost no overshoot.](/img/lecture-01/step06-clamping-plot.png)

</div>
</div>

*Your `CruiseController` · delete `error.y → integrator.u` · in code:
`integrator.u = ifelse(...)` on `limiter.y` and `error.y` · re-run `CruiseClimb`*

```julia
using Plots; plotly()
r = MyCar.CruiseClimbTransient()
top = plot(r; idxs = r."plant.v_kmh")
bottom = plot(r; idxs = [r."controller.y", r."controller.gain.y",
                         r."controller.integrator.y"])
plot(top, bottom; layout = (2, 1), link = :x)
```

[page: step 6d](../lecture/lecture-01/#step-6d) · reference `ClampingCruiseClimb` in `dyad/Lecture1/WindupClimb.dyad`

<!--
As a diagram, two comparisons and a switch are eight blocks. As an equation, five lines. A Dyad
model can mix blocks and equations, so we write the equation.

Open your `CruiseController` and toggle to the code view. Delete the line `connect(error.y,
integrator.u)`, the wire from the error to the integrator. The equation drives that input now.

Above `relations`, add `variable control_error::Real`, a named value that holds the error. Inside
`relations`, add `control_error = error.y`.

The second equation sets `integrator.u` with nested `ifelse`. `ifelse` takes a condition, a value
for true and a value for false. In words: if `limiter.y` is greater
than or equal to `y_max`, then zero if `control_error` is greater than or equal to zero, otherwise
`control_error`. Else, if `limiter.y` is less than or equal to `y_min`, then zero if
`control_error` is less than or equal to zero, otherwise `control_error`. Otherwise just
`control_error`. Write the zero as 0.0.

Read it as the two conditions. At the upper limit with the error still pushing up: zero. At the
lower limit with the error pushing down: zero. Otherwise the error, as before. We nest `ifelse`
because the equation has no boolean "and".

Back in the diagram, `integrator` has no input wire. That is correct. Its output still goes into
`add_pid.u3`, the block that adds the three terms.

Save, re-run `CruiseClimbTransient` and plot it with the same code as in 6c.

What you should see. The same sag, to 119.05 km/h at the crest: clamping adds no torque.
`controller.integrator.y` goes flat once the limiter saturates. `controller.gain.y` still rises to
about 660 N·m on the climb. That is mostly the proportional term, the part of the command that is
k times the error: 56 times about 11 km/h. It drops when the road flattens. After 150 seconds the
car goes about 0.2 km/h over the setpoint; the notebook's run says 0.17, back within half a km/h in
3.5 seconds. Without clamping it was 49.47 km/h and 66.7 seconds. At 400 seconds the speed is back
at 130.

The most common mistake is leaving the old wire. Then `integrator.u` is defined twice, and Dyad
reports one equation too many. The second is testing `gain.y` instead of `limiter.y`. Only
`limiter.y` is the saturated signal, so `limiter.y` at `y_max` means exactly "at the limit".
-->

---

## The other way: back-calculation

<div class="grid grid-cols-2 gap-8">
<div>

Instead of switching the integrator off, feed the part of the command
that did not get through back into it:

$$
\dot{I} \;=\; \frac{k}{T_i}\,e \;+\; \frac{1}{T_t}\bigl(u_{sat} - u\bigr)
     \qquad T_t = N_i\,T_i
$$

- Inside the limit $u_{sat} = u$, the second term is zero, and it is an ordinary integrator.
- In saturation the term is negative and pulls the integrator back down towards the value
  that would just reach the limit.

</div>
<div>

| | Clamping | Back-calculation |
|---|---|---|
| Action | on / off | continuous |
| Tuning | none | $N_i$ — how fast it unwinds |
| Easy to read | yes | less so |
| Where | your `CruiseController`, step 6d | `LimPID`, via `Ni` |

*Both keep the integrator below the limit instead of far above
it, and that is what prevents the overshoot.*

**Open in Dyad** `dyad/Lecture1/WindupClimb.dyad` — `CruiseClimb`, whose loop
`BackCalcCruiseLoop` closes `LimPID` around the same `GradeCar`

</div>
</div>

<!--
Your toolbox probably implements this method, so learn to read it. Clamping is easy to explain and
to get right. Back-calculation hands over more smoothly, and has one more number to choose.

The equation: the integrator's rate of change is k over T i times the error, plus one over T t
times u sat minus u. u is the command before the limit, u sat the command after it. So u sat minus
u is the part of the command that did not get through. Inside the limit it is zero, so the term
vanishes.

T t, the tracking time, in seconds, sets how hard the integrator is pulled back when saturated.
Small pulls it back hard, and too small stops the integral part contributing near the limit. Large
pulls it back slowly. `LimPID`, the ready-made limited PID block in Dyad's standard library, sets
it through N i: T t equals N i times T i. The default N i is 0.9, so with T i 10, T t is 9
seconds.

Back-calculation unwinds while still saturated, instead of only refusing to wind further. So you
would expect it to recover better. On this hill it does not. Clamping: 0.17 km/h over, 3.5
seconds. Back-calculation: 1.11 km/h over, 13.6 seconds. It holds the integrator where the two
terms balance. With T t at 9 seconds that is near 90 N·m, almost twice the roughly 50 N·m the flat
road needs, so there is still a surplus to unwind. That
comes from the untuned library default, not the method. It is why this lecture uses clamping,
which has no parameter to set.

`LimPID` appears only here, as the comparison. Put the reference `CruiseClimb` next to your
`MyCar.CruiseClimb`. Same plant, road and gains; only the controller block differs. Look at `Ni`,
and at `y_max`, which defaults to `T_max`. That ceiling is the subject of the last slide in this
section.
-->

---
class: big-figure
---

## Three anti-windup variants on the same hill

![Speed and integrator state for three controllers through the same climb: without anti-windup the integrator runs far above the limit and the speed overshoots, while clamping and back-calculation both keep the integrator below the limit and follow the setpoint back cleanly.](/figures/06-three-way-antiwindup.svg)

<!--
Lower plot first. The integrator traces show the cause: one rises far above the limit, to 5431
N·m. The other two stay below the 150 limit, peaking at 62 N·m for clamping and 123 for
back-calculation.

Then the speed. Same car, hill and gains. The only difference is whether the integrator could
accumulate beyond what the engine delivers.

What anti-windup did not fix: all three sag to the same 119 km/h on the climb. No controller makes
a 150 N·m engine deliver 2023 N. Anti-windup adds no performance. It prevents the overshoot after
saturation.
-->

---

## Three anti-windup variants: the numbers

<div class="grid grid-cols-[1.6fr_1fr] gap-8">
<div>

```julia [06-windup.ipynb · cell Three-way comparison]
# Three schemes, two controllers: clamping with unreachable limits is no
# anti-windup at all; back-calculation is the library's LimPID.
CLIMB = (k = 56.0, Ti = 10.0, Td = 0.5, v_set = 130.0, gradient = 0.10,
         start_time = 30.0, duration = 120.0, stop = 400.0)

runs = ["none"             => Scenarios.ClampingCruiseClimbTransient(; y_max = 1.0e6, y_min = -1.0e6, CLIMB...),
        "back-calculation" => Scenarios.CruiseClimbTransient(; Ni = 0.9, CLIMB...),
        "clamping"         => Scenarios.ClampingCruiseClimbTransient(; CLIMB...)]

# peak over setpoint, not `overshoot`: no step to normalize against
[name => maximum(signal(s, SPEED)[2]) - 130 for (name, s) in runs]
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/06-windup.ipynb)

</div>
<div>

| Variant | Over setpoint | Recovery |
|---|---|---|
| none | +49.47 km/h | 66.7 s |
| clamping | +0.17 km/h | 3.5 s |
| back-calculation | +1.11 km/h | 13.6 s |

</div>
</div>

<!--
"None" is the clamping controller with limits it never reaches: 49.47 km/h over, 66.7 seconds to
recover. "Clamping", also called conditional integration: 0.17 km/h and 3.5 seconds.
"Back-calculation" is `LimPID` at `Ni` 0.9: 1.11 km/h and 13.6 seconds. Recovery means back within
half a km/h of 130 after the crest. The peak overshoot is the number that separates them.

Which would you ship? Either. Clamping is cheaper and easier to explain. Back-calculation is
smoother, with its own tuning parameter. In practice, use whichever your framework already
implements correctly.
-->

---

## The controller limit and the engine limit

<div class="grid grid-cols-2 gap-8">
<div>

- `T_max` is what the **engine enforces**. A fact about the hardware, true whether or not any
  software knows it.
- `y_max` is what the **controller believes**. A constant in a program, and what the
  saturation detector compares against.

| Engine | Controller believes | Lowest on climb | Peak after |
|---|---|---|---|
| 150 | 140, below | 102.03 | 130.15 |
| 150 | 150, equal | 119.04 | 130.17 |
| 150 | 200, above | 119.09 | 130.55 |
| 150 | 300, twice | 119.09 | 131.58 |
| 150 | none at all | 119.10 | **179.48** |

</div>
<div>

> **The clamp must not be above the engine limit**
>
> **The clamp must not sit above what the actuator enforces.** Above it, the overshoot grows with
> the gap. Below it reduces overshoot very little and *costs* climbing torque: clamping at 140
> against an engine that has 150 costs **17 km/h** on the climb to save **0.02 km/h** of
> overshoot.
>
> How far below is a trade-off against climbing torque. Decide it with both numbers in front of
> you.

</div>
</div>

<!--
A common rule of thumb says: leave a margin below the nameplate limit, the limit printed in the
engine's specification. We measured it, and on this car it is a bad trade. Read the "peak after"
column down: 130.15 with the clamp at 140, 130.17 at 150, 130.55 at 200, 131.58 at 300, and 179.48
with no clamp. Below the ceiling and at it are both safe. Above it, the damage grows with the gap.

`y_max` is the controller's clamp, which you choose; it decides when the integrator freezes.
`T_max` is what the engine enforces. When the engine is hot, aged, at altitude or on poor fuel,
the real ceiling sits below the nameplate.

To see it yourself, set `controller.y_max` in `CruiseClimb` to 140 and re-run, then try 300. The
lowest speed on the climb and the peak after it move as the first and fourth rows say: at 140 the
car drops to 102.03 km/h on the climb, at 300 only to 119.09.

The last row: a controller with no output clamp reproduces the windup run to within a fraction of
a km/h. That is what notebooks 03, 04 and 05 were running. Correct anti-windup logic whose limit
is never reached passes review and does nothing.

Why does the margin cost so much? The proportional term already drives the command hundreds of N·m
past both numbers, so 10 N·m of gap barely changes the overshoot. But 10 N·m of torque the
controller refuses to use costs 17 km/h on a 10 % climb. 17 km/h against 0.02: the margin loses.

If `y_max` sits above what the engine delivers, the engine saturates while the controller sees
nothing. That is windup again. So `y_max` must not sit above `T_max`. How far below is a trade
against climbing torque.

A margin pays off where the gap can be large: a sticking valve, a rudder against a current, an
amplifier sagging under load. It also needs gains low enough to keep the command inside the gap.
-->

---

## Summary of section 06

- The first nonlinear failure in the lecture, caused by the actuator's limit, not by the
  control law.
- Clamping: two conditions that switch off the integrator.
- A rule for the controller limit: not above the hardware limit.

### Next: the derivative, and what a noisy sensor does to it. <Link to="derivative-and-noise">→ 07, derivative and noise</Link>

<!--
You now have the controller the rest of the lecture runs on: proportional, integral and derivative
terms, a limit, and clamping.
Section 07 puts a noisy sensor in front of it. After that only parameters change, until section 10
swaps the car.
-->
