---
routeAlias: windup
layout: section
---

###### Notebook 06

# Integral windup

The integrator does not know the engine has run out.

`notebooks/lecture01/06-windup.ipynb`

<!--
Everything so far has been true of a linear model. This section is about the first place where
the real world stops being linear. And it is the failure that has actually destroyed hardware.

We have four build steps here. Two inside `GradeCar` and `CruiseController`, one new climb
harness, and one equation.
-->

---

## The plant has two halves

- The **actuator** — the thing that supplies the force. Our engine.
- The **process** — the thing being pushed. Our car.

Real actuators have backlash, rate limits and **saturation**.
A linear model has none of these: ask it for a million newton-meters and it will agree.

**Open in Dyad** `dyad/HandsOn/Engine.dyad` — the `limiter` after the lag

> **The hill we are about to drive up**
>
> 130 km/h on a sustained 10 % climb needs **2023 N** at the road.
>
> The engine can deliver **1935 N**.
>
> The car will lose, and head for about **118 km/h** — a 120 s climb gets it to **119.05**,
> still falling.

*↩ Hands-on step 07: [the slope, and the 2023 N sum](../handson-01/index.html#/slope)*

<!--
The numbers in the box are not chosen to make a point. They come out of the force balance
from hands-on step 05, with the parameters on the front slide. You can compute them yourself.
That is the whole point of having built the car first.

And notice how close it is. 2023 against 1935. Four percent short. This is not a cartoon
overload. It is the ordinary case of a fully loaded car on a long climb.

So the climb at 130 km/h on a 10 % grade asks for 2023 newtons, and the engine can give 1935.
The car heads for about 118 km/h. I say heads for, not settles at. The climb is 120 seconds
long, and the car is at 119.05 km/h and still falling when the road flattens.

What does the controller see when the engine is pinned at its limit? Exactly what it saw
before: a speed that is too low. It has no sensor for "the actuator has given up". Hold that
thought for two slides.

In the engine model, the ceiling is the `limiter`. Its `y_max` is `T_max`, and its `y_min` is
zero. That second one matters too. This engine cannot produce negative torque, so it cannot
brake. Downhill it has no answer at all.

When an actuator sits at its limit and cannot follow the command it was given, we call that
**saturation**.
-->

---
routeAlias: step-6a
---

## Step 6a: the ceiling becomes a parameter

![GradeCar's parameter panel with T_max, and the engine selected so its binding T_max = T_max shows.](/img/lecture-01/step06-tmax.png)

*Your `GradeCar` · add `parameter T_max::Torque = 150` · `engine`: `T_max = T_max`*

[page: step 6a](../lecture/lecture-01/#step-6a) · reference `dyad/HandsOn/GradeCar.dyad`

<!--
The engine has had a ceiling since hands-on step 02. It is the `limiter` inside it, at
150 N·m. Until now nobody outside the engine could touch it. Today we need to, so it moves up
one level, onto the car.

Open your `GradeCar` in the diagram view. With nothing selected, go to the parameter panel and
add `parameter T_max::Torque = 150`, with the description "Peak deliverable torque".

Now select `engine`. In its parameter panel, set `T_max` equal to `T_max`. The engine already
declares `T_max`, from hands-on step 02, so this is a binding, not a new parameter.

There is nothing to wire, and there are no new blocks.

Before we move on, run the PID checkpoint loop from section 05. It should compile and give the
same curve as before. 150 is the default, so nothing may move. If your curve moved, the binding
went to the wrong instance.

This is the hands-on move once more: add a parameter and pass it down. `T_max` is a fact about
the hardware. The next step gives the controller its own number, and the rest of the section
is about what happens when the two disagree.
-->

---
routeAlias: step-6b
---

## Step 6b: the controller gets a limit of its own

![CruiseController in progress: gain feeds the limiter, and the limiter feeds the output y.](/img/lecture-01/step06-limiter.png)

*Your `CruiseController` · `parameter y_max::Real = 1e300`, `parameter y_min::Real = -y_max` ·
`Limiter(y_max = y_max, y_min = y_min)` between `gain` and `y` · `CruiseLoopStep`: `controller` `y_max = 150`, `y_min = 0`*

```julia
using MyCar, Plots; plotly()
r = MyCar.CruiseLoopTransient()
plot(r; idxs = [r."controller.y", r."controller.gain.y"], xlims = (0, 20))
```

[page: step 6b](../lecture/lecture-01/#step-6b) · reference `dyad/Lecture1/CruiseController.dyad`

<!--
The engine refuses anything above 150. The controller has never known that. It can ask for a
thousand N·m, and the engine silently clips it. So we give the controller its own ceiling.
Then it can at least see when it is asking for more than it gets.

Go inside your `CruiseController`. First add two parameters. `parameter y_max::Real = 1e300`,
described as "Maximum output". And `parameter y_min::Real = -y_max`, described as "Minimum
output". These are the reference's defaults, so a controller with no limits set behaves
exactly as before.

Now drag in `BlockComponents.Nonlinear.Limiter` and name it `limiter`. Set its `y_max` to
`y_max` and its `y_min` to `y_min`.

Delete the wire from `gain.y` to `y`. Then wire `gain.y` into `limiter.u`, and `limiter.y`
into `y`.

Now go to `CruiseLoopStep`. Select `controller` and set `y_max` to 150 and `y_min` to zero.
The reference `CruiseLoop` uses `y_max` equals `T_max` and `y_min` equals zero. Zero, because
this engine cannot brake.

Re-run `CruiseLoopTransient` on `CruiseLoopStep`. The step from 90 to 110 km/h asks for more
than 150 N·m at the start. So you should see `controller.y` sit flat on 150 for the first
moments, instead of spiking above it. `controller.gain.y` is the command before the limiter.
Plot both, with the code on the slide. The gap between them is the saturation.

Watch the naming here. The instance must be called `limiter`, and the signal before it is
`gain.y`. Otherwise the notebook paths and the clamping equation in step 6d will not find
them.
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
using MyCar, Plots; plotly()
r = MyCar.CruiseClimbTransient()
top = plot(r; idxs = r."plant.v_kmh")
bottom = plot(r; idxs = [r."controller.y", r."controller.gain.y",
                         r."controller.integrator.y"])
plot(top, bottom; layout = (2, 1), link = :x)
```

[page: step 6c](../lecture/lecture-01/#step-6c) · reference `CruiseClimb` in `dyad/Lecture1/WindupClimb.dyad`

<!--
We have a 10 % hill that needs 2023 N at 130 km/h, and an engine that makes 1935. Let us drive
up it. Nothing in the controller changes. Only the road.

This is a new harness in `MyCar`, beside `CruiseLoopStep`. Duplicate `CruiseLoopStep` from
section 02, and name the copy `CruiseClimb`. That is the reference harness's name.
`CruiseLoopStep` itself stays as it is, a checkpoint to come back to. The four instances keep
their names: `demand`, `controller`, `plant` and `road`.

Replace `demand` with `BlockComponents.Sources.Constant`, with `k` equal to 130. Wire
`demand.y` into `controller.u_s`.

Replace `road` with a Pulse, from BlockComponents, Sources. Name it `road`. Set `amplitude` to
0.10, `offset` to zero, `start_time` to 30, `duty_cycle` to 1.0, and `period` to 120. Wire
`road.y` into `plant.grade`. The hill starts at 30 seconds, and the road flattens again at
150 seconds. Your `MyCar` cannot see the course library. This pulse is what the reference
uses, wrapped in its `GradeProfile`.

On `controller`, keep `k` at 56, `Ti` at 10 and `Td` at 0.5. Those are the defaults from
sections 03 to 05. Keep `y_max` at 150 and `y_min` at zero, as we set them in 6b. And set
`xd0` to minus 130. The default, minus 90, seeds the derivative filter for a cruise at 90 km/h.
This run cruises at 130, so the filter's settled input, wd times u_s minus u_m, is minus 130.
Leave it at minus 90 and the run opens with a derivative kick.

Now the initial conditions, in the code view. These are the same three lines `CruiseClimb`
uses. `initial plant.body.mass.s = 0`. Then `initial plant.body.mass.v = 36.111111111111114`,
which is 130 km/h in meters per second. Then `initial plant.engine.lag.x = 50.9693`, which is
the holding torque at 130 km/h on the flat.

Click Run Analysis, choose TransientAnalysis, name it `CruiseClimbTransient`, and set `stop`
to 400. Run it.

Plot it with the code on the slide. `plant.v_kmh` on top. Below it, three signals.
`controller.y` is the command after the limiter. `controller.gain.y` is the command before it.
And `controller.integrator.y` is the integrator's state.

Here is what you should see. The speed sags from 130 after t equals 30 seconds. It heads for
about 118, and is at 119.05 at the crest. `controller.y` lies flat on 150 through the climb.
`controller.gain.y` keeps climbing, to about 6000 newton-meters at the crest. That is forty
times what the engine can give. The integrator is what drives it there. On this axis its trace
hugs zero, so hover over it. It reaches about 97 at the crest, and 56 times 97 is over 5400
newton-meters. And after t equals 150 seconds comes the overshoot, to almost 180 km/h. The
notebook's run without anti-windup peaks 49.47 km/h over the setpoint and takes 66.7 seconds
to recover.

This is your controller with a limiter and no anti-windup. It is the "none" row of the
three-way table we will see shortly. If your overshoot is a few km/h rather than tens, your
integrator is not wired from `error`. Check that before we go on.
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
Look at the speed trace first. It sags away from the setpoint at t equals 30 seconds. The car
is losing. Now the delivered torque. It lies flat on the limit line. The engine is doing
everything it can. Now the commanded torque. It carries on upward, past the limit, off into
nonsense. And the integrator is what is driving it there.

The integrator's rule is: the error is not zero, so keep accumulating. It is obeying that rule
perfectly. Nothing in the loop tells it that the accumulation has stopped buying anything.

Look at the commanded torque at the top of the climb and compare it with 150 N·m. It is about
6000 N·m, forty times over.

Think of holding a drone down on the ground while it is trying to fly to 50 meters. The
propellers max out at 1000 rpm. The integrator winds the command up to 2000. And the moment
you let go...

In the model, three parameters set the hill: `gradient`, `start_time` and `duration`. A
gradient of 0.10 is a 10 % climb, about 5.7 degrees. The hill starts at 30 seconds and lasts
120, so the road flattens again at 150 seconds. The setpoint, `v_set`, is 130 km/h. The road
flattens because the duration is finite, and the flattening is where the damage shows.

We plot the integrator state separately, because it is the thing actually going wrong, and it
is invisible in the speed trace.

The controller limits here are one million and minus one million. The command never reaches
them, so the clamp never acts. That gives us no anti-windup at all, on purpose, so the failure
is visible. The engine still stops at 150 N·m.
-->

---

## Why the crash is already scheduled

When the road flattens at t = 150 s, the car accelerates. The error changes sign. The
integrator begins to unwind.

But it is unwinding *from far above the limit*. While the command falls from about 6000 N·m
to 150, the engine delivers the same full torque it was delivering before.

**Nothing the car does can be seen at the output until the command comes back inside the
limit.**

> **The dangerous property**
>
> The delay between "the error changed sign" and "the actuator responded" is not set by the
> plant, or by the gains. It is set by how far the integrator was allowed to wander while nobody
> was looking.

<!--
The drone numbers make this cleaner. The integrator asks for 2000 rpm. The motors do 1000.
Let go. The drone shoots up past 50 meters. The error goes negative. The integrator starts
coming down. 1900, and still 1000 at the motors. 1500, still 1000. 1100, still 1000. Only at
1000 does anything at all begin to happen. And by then the drone is out of sight.

And that is the actual harm. Winding up is not itself the problem. Commanding about
6000 N·m from a 150 N·m engine hurts nothing. The problem is the time it takes to unwind.
During that time the controller is effectively disconnected.

So let me name the two halves. **Windup** is an integrator accumulating past the point where
the actuator can act on it. **Unwinding** is coming back down. The harm is in the unwinding.
Until the command falls back inside the limit, nothing the car does reaches the engine. During
unwinding, the loop is open, whether you designed it that way or not.

Now, before we run the next cell: how far past 130 km/h do you think we go? Give me two
guesses, and I will write them on the board.
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
Look at the peak. The car goes 49.47 km/h over the setpoint, and it takes 66.7 seconds to come
back. Compare that with the guesses on the board.

Nobody commanded this. The driver asked for 130, and the car chose to do something else for
several seconds. Any control failure that surprises the operator is a safety problem, whatever
the numbers say.

We measure the excursion as the peak minus 130, in km/h. We do not use the `overshoot` helper
here. That helper divides by the step size, and this run starts at the setpoint, so there is
no step. The time of the peak tells us when it happens. The dotted vertical lines mark where
the climb starts and ends.

What would you change to stop it? Hold on to your answers. The usual first one is "limit the
output". On its own, that is not enough, and you will see why in a moment.
-->

---

## Clamping: two conditions

![Block diagram of the clamping anti-windup logic: the controller output is compared before and after the saturation block, the sign of the error is compared with the sign of the output, and when both tests pass an AND gate switches the integrator input to zero.](/diagrams/06-clamping.svg)

*Both true → stop integrating. Either one false → the integrator is restored and starts coming down immediately.*

<!--
Follow the diagram with me, in this order. The output. The saturation block. The two
comparisons. The AND. And the switch back into the integrator.

The first check compares the controller's output before and after the saturation block. Equal
means we are inside the limit, and everything is fine. Not equal means we are saturating.

The second check asks: do the error and the output have the same sign? Same sign means the
integrator is still pushing in the direction that is already saturated. It is trying to make
things worse.

Both true, and only both, and we switch the integrator's input to zero. It freezes. It does not
reset, and it does not decay. It holds, ready to move the instant either condition stops being
true.

A common mistake is to think clamping means "limit the integrator to some maximum value". It
does not. It stops the accumulation conditionally. A fixed cap would still wind up to the cap,
and would still have to unwind from it.

This is conditional integration, the other name for clamping. It is not the only method. Back-calculation feeds the saturation error
back into the integrator instead. We compare both next.
-->

---
routeAlias: step-6d
---

## Step 6d: two conditions, one equation

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
using MyCar, Plots; plotly()
r = MyCar.CruiseClimbTransient()
top = plot(r; idxs = r."plant.v_kmh")
bottom = plot(r; idxs = [r."controller.y", r."controller.gain.y",
                         r."controller.integrator.y"])
plot(top, bottom; layout = (2, 1), link = :x)
```

[page: step 6d](../lecture/lecture-01/#step-6d) · reference `ClampingCruiseClimb` in `dyad/Lecture1/WindupClimb.dyad`

<!--
The diagram on the previous slide is two comparisons and a switch. As a diagram it would be
eight blocks. As an equation it is five lines. Dyad lets you mix the two, so we write it.

Go inside your `CruiseController`. In the diagram view, delete the wire from `error.y` to
`integrator.u`. The integrator now has an unconnected input. The equation we are about to write
is what drives it.

Switch to the code view. Under the existing declarations, add `variable control_error::Real`.

Now, in `relations`, add two equations. The first one: `control_error = error.y`.

The second one sets `integrator.u` with nested `ifelse`. Here it is in words. If `limiter.y` is
greater than or equal to `y_max`, then: if `control_error` is greater than or equal to zero,
zero; otherwise `control_error`. Else, if `limiter.y` is less than or equal to `y_min`, then:
if `control_error` is less than or equal to zero, zero; otherwise `control_error`. Otherwise,
just `control_error`. The zero is written 0.0.

Read it as the two conditions. At the upper limit, and the error still pushing up: zero. At
the lower limit, and the error still pushing down: zero. Otherwise the integrator gets the
error, as before. We nest `ifelse` because the equation has no boolean "and".

Back in the diagram, `integrator` has no wire into it, and that is correct. It is still wired
from `integrator.y` into `add_pid.u3`.

Now re-run `CruiseClimbTransient`, and plot it with the same code as in 6c. It is on the slide
again.

Here is what you should see. The same sag on the climb, to 119.05 km/h at the crest, exactly as
in 6c. Clamping adds no torque. `controller.integrator.y` goes flat once the limiter saturates,
instead of climbing. `controller.gain.y` still rises above 150 on the climb, to about 660. That
is mostly the proportional term, 56 times an error of about 11 km/h, and it drops the moment
the road flattens. And after t equals 150 seconds, the car goes 0.17 km/h over the setpoint
and is back within 3.5 seconds. Without clamping it was 49.47 km/h and 66.7 seconds.

The most common mistake is leaving the old wire in place. Then `integrator.u` is defined twice,
once by the connection and once by the equation, and Dyad reports one equation too many. The
second most common is testing `gain.y` instead of `limiter.y`. The output of the limiter is the
saturated signal, so `limiter.y` greater than or equal to `y_max` means exactly "at the
limit".
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
| Reads | trivially | needs a second look |
| Where | your `CruiseController`, step 6d | `LimPID`, via `Ni` |

*Both keep the integrator near the limit rather than far above
it, which is the only thing that matters.*

**Open in Dyad** `dyad/Lecture1/WindupClimb.dyad` — `CruiseClimb`, whose loop
`BackCalcCruiseLoop` closes `LimPID` around the same `GradeCar`

</div>
</div>

<!--
This is the method your toolbox most likely implements, so it is worth being able to read.
Clamping is easy to explain and easy to get right. Back-calculation gives a smoother handover,
and has one more number to choose.

Read the equation like this. The rate of change of the integrator state is k over T i times
the error, plus one over T t times u sat minus u. And u sat minus u is how much of the command
did not get through. It is zero whenever we are inside the limit, which is why the term
vanishes in normal operation.

Look at the tracking time constant, T t, in seconds. It sets how fast the integrator is dragged
back when saturated. Small means the integrator is dragged back hard the moment you saturate.
Large means it barely notices. Set it too small, and the integral path stops contributing at
all near the limit. `LimPID` exposes it through N i: T t equals N i times T i. The default N i
is 0.9.

What does back-calculation do that clamping does not? It unwinds while still saturated, rather
than merely refusing to wind further. So you would expect it to recover better. On this hill
it does not. Clamping overshoots 0.17 km/h and recovers in 3.5 seconds. Back-calculation
overshoots 1.11 km/h and takes 13.6 seconds. Back-calculation balances rather than freezes.
With T t equal to N i times T i, which is 9 seconds, it settles high and still has a surplus to
unwind. That is a library default left alone, not a verdict on the method. And it is why this
lecture demonstrates clamping, which has no parameter to leave wrong.

`LimPID` appears in this lecture only here, as the comparison. Put the reference `CruiseClimb`
next to your own `MyCar.CruiseClimb`. Same plant, same road, same gains. The only difference is
the controller block. Look at `Ni`, the back-calculation parameter. And look at `y_max`, which
defaults to `T_max`. That is the controller's own ceiling, and it is the subject of the last
slide in this section.
-->

---

## Three controllers, one hill

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
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

| Variant | Over setpoint | Recovery |
|---|---|---|
| none | +49.47 km/h | 66.7 s |
| clamping | +0.17 km/h | 3.5 s |
| back-calculation | +1.11 km/h | 13.6 s |

</div>
<div>

![Speed and integrator state for three controllers through the same climb: without anti-windup the integrator runs far above the limit and the speed overshoots, while clamping and back-calculation both hold the integrator near the limit and follow the setpoint back cleanly.](/figures/06-three-way-antiwindup.svg)

*Speed above, integrator state below. The difference between the runs is entirely in the lower plot.*

</div>
</div>

<!--
Look at the lower plot first, not the speed. The integrator traces are where the mechanism is
visible. One of them wanders far above the limit. The other two sit on it.

Now the speed plot. Same car, same hill, same gains. The only difference is whether the
integrator was allowed to accumulate something it could not spend.

"None" is the clamping controller with limits it never reaches, so no protection at all. It
overshoots 49.47 km/h. "Clamping" is conditional integration, a different controller and so a
different analysis. It overshoots 0.17. "Back-calculation" is the built-in method of `LimPID`,
at `Ni` equal to 0.9. It overshoots 1.11. The peak overshoot is the single number that
separates them.

And note what anti-windup did not fix. All three traces sag to the same 119 km/h on the climb.
No controller can make a 150 N·m engine deliver 2023 N of tractive force. Anti-windup does not
add performance. It stops you being punished for asking.

Which of the two methods would you ship? Either. Clamping is cheaper, and easier to explain to
the next engineer. Back-calculation is smoother, with a tuning parameter of its own. The real
answer is: whichever one your framework already implements correctly.
-->

---

## Two limits, and only one of them is real

<div class="grid grid-cols-2 gap-8">
<div>

- `T_max` is what the **engine enforces**. A fact about the hardware, true whether or not any
  software knows it.
- `y_max` is what the **controller believes**. A constant in a program — and what the
  saturation detector compares against.

| Engine | Controller believes | Lowest on climb | Peak after |
|---|---|---|---|
| 150 | 140 — margin | 102.03 | 130.15 |
| 150 | 150 — exactly at it | 119.04 | 130.17 |
| 150 | 200 — optimism | 119.09 | 130.55 |
| 150 | 300 — twice | 119.09 | 131.58 |
| 150 | none at all | 119.10 | **179.48** |

</div>
<div>

> **The rule is ordering, not margin**
>
> **The clamp must not sit above what the actuator enforces.** Above it, the damage is the size
> of the gap. Below it buys almost nothing and is *not free*: clamping at 140 against an engine
> that has 150 costs **17 km/h** of climbing authority to buy back **0.02 km/h** of overshoot.
>
> How far below is a trade against authority — made with both numbers in front of you, not by
> reflex.

</div>
</div>

<!--
The folklore here is "leave yourself a margin below the nameplate". We measured it, and on this
car it is a bad trade. Read the "peak after" column downwards. Below the ceiling and at it are
both safe. Above it, the damage grows with the gap.

`y_max` is the controller's output clamp, which you choose. It decides when the integrator
freezes. `T_max` is what the engine enforces. And when the engine is hot, aged, at altitude, or
on poor fuel, the real ceiling sits below the nameplate.

If you want to see it in your own model, go to `CruiseClimb`, set `controller.y_max` to 140 and
re-run. Then try 300. The lowest speed on the climb and the peak after it move the way the
first and fourth rows say.

Look at the last row. A controller with no output clamp at all reproduces the windup run to
within a fraction of a km/h. And that row is not hypothetical. It is what notebooks 03, 04 and
05 were running. Correct anti-windup logic that is never reached is the most expensive kind of
correct. It passes review, and it does nothing.

Why does the margin cost so much here? The proportional term has already driven the command
hundreds of N·m past both numbers. So 10 N·m of gap is worth almost nothing in overshoot. But
10 N·m of authority you refused to use is worth 17 km/h on a 10 % climb. On this car, the
prudent-sounding margin loses that trade, 17 km/h to 0.02.

If `y_max` sits above what the engine delivers, there is a band where the engine is saturated,
the error will not close, and the controller sees no saturation at all. That is windup, back
again. So the rule is ordering, not margin: `y_max` must not sit above `T_max`. How far below
is a trade against climbing authority.

Where does the margin reflex earn its keep? In systems where the gap can be large. A valve that
sticks, a rudder meeting current, an amplifier sagging under load. And where the loop gain is
low enough that the command lives inside the gap, rather than far above it.
-->

---

## What this bought us

- The first genuinely nonlinear failure in the lecture — and it came from the actuator, not
  from the controller's mathematics.
- Clamping: two conditions, one switch.
- A rule for the limit itself: not above the hardware's.

### Next: the derivative, and what a noisy sensor does to it. <Link to="derivative-and-noise">→ 07, derivative and noise</Link>

<!--
You now have the controller the rest of the lecture runs on. P, I, D, a limit, and clamping.
Section 07 puts a noisy sensor in front of it. After that only parameters change, until
section 10 swaps the car.
-->
