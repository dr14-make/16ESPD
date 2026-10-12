---
routeAlias: the-car
layout: section
---

###### Notebook 01

# The car

A recap of the car you built, a step test that measures it, and a road with a grade.

`notebooks/lecture01/01-the-car.ipynb`

[page: step 1a](../lecture/lecture-01/#step-1a) · reference `dyad/HandsOn/Car.dyad`, `dyad/Lecture1/CarStepTest.dyad`

<!--
There is no controller in this section either. The force balance, the terminal speed and the
engine's lags were explained and built in the hands-on. We recall them in three slides. Then we
measure the same car the way a control engineer would: one step test gives three numbers. At the
end we give the car a grade input, so that it can drive up a hill.

From here on, you build along with me. You need your hands-on package, `MyCar`, open in Studio,
with `Car` and `GradeBody` in it. If you do not have it, make your own copy of the MyCar template
on GitHub. The guide page links to it. It is the finished hands-on car, and the instance names
match.
-->

---
routeAlias: recap-models
---

## What you built

<div class="grid grid-cols-[1.25fr_1fr] gap-6">
<div class="text-sm">

| Model | Key equation | Its step response |
|---|---|---|
| `Engine` | delay θ<sub>e</sub> → lag τ<sub>e</sub> → cap *T*<sub>max</sub> | 200 N·m at 0.5 s: nothing until 0.8 s, capped at 150 from 1.22 s |
| `Driveline` | *F* = *T*·*i* / *r* | 100 N·m → 1290 N → 0.92 m/s² on 1400 kg |
| `Body` | *m* d*v*/d*t* = *F* − ½ρ*C<sub>d</sub>A v*² − *f<sub>r</sub>mg* | 500 N push → 29.78 m/s, about 107 km/h |
| `Car` | the three, joined; `to_kmh` = 3.6 | flat out: 100 km/h at 23.6 s, **246.39** km/h at 300 s |
| ↳ `GradeBody` | + *m g* sin(arctan grade) | 10 % grade: **1366 N** back |
| ↳ `SlipCar` | *F<sub>x</sub>* = μ(κ)·*F<sub>z</sub>* | snow: car 10 km/h, wheel 1500 km/h after 5 s |

*Car joins Engine, Driveline and Body. GradeBody and SlipCar extend it.*

</div>
<div>

![Car: torque command into engine, driveline and body, with a velocity sensor and a 3.6 gain producing speed in km/h.](/img/handson-01/step05-car.png)

<div class="grid grid-cols-2 gap-3">

![GradeBody: the grade input feeds both the rolling resistance inclination and the grade force.](/img/handson-01/step07-grade-body.png)

![SlipWheel1D: the curve block sits between the spline and flange ports with no wires.](/img/handson-01/step09-slip-wheel.png)

</div>
</div>
</div>

↩ Hands-on: [step 10 and its summary table](../handson-01/index.html#/standing-start) · [hands-on page](../handson/lecture-01/index.html)

<!--
This slide summarizes the hands-on: four models in a row, and two extensions. Every row has the
equation that part adds, and the number your bench showed when you ran it. You predicted each of
those on paper first, and your model matched it.

Look at the `Car` diagram, top right. That is the plant for the whole lecture. Section 01
measures it. The end of section 01 swaps its `Body` for your `GradeBody`. Section 10 swaps the
whole thing for `SlipCar`.

Now look at the two branch pictures. `GradeBody` is the hill, and we need it in section 02. The
slip wheel is the tire model whose grip has a peak, and we need it in section 10, on ice.

The number a controller has to work against is the 1366 newtons of a 10 percent hill. That is
most of the 1935 newtons the engine can push. Section 06 is about this case.

Every derivation is in the hands-on deck, and the link at the bottom goes straight to the
summary table.
-->

---
routeAlias: studio-moves
---

## The four Studio moves you need today

<div class="grid grid-cols-2 gap-8">
<div>

#### 1 · Duplicate a component

Components → right-click → **Duplicate**, then rename. You did it for `WheeledDriveline` and
`GradeBody`; today `Car` → `GradeCar`.

#### 2 · Add a parameter, pass it down

**Add parameter** in the component panel, then the part refers to it by name:
`Engine(T_max = T_max)`. The number is set in one place.

</div>
<div>

#### 3 · Two kinds of wire

**Causal** — `RealInput` → `RealOutput`, an arrow: a number one block computes and the next
reads. The whole controller is these.
**Acausal** — `Flange`, `Spline`: a joint, no direction. The car is these.

#### 4 · Run and plot

New harness → `initial` lines in code → ▷ Run Analysis → **TransientAnalysis** → ▷ in
Analyses → plot the signals.

</div>
</div>

> **Every build step today is one of these four**
>
> The controller is causal wiring from end to end. Only the plant has joints, and you built it
> this morning.

<!--
You already know every Studio move this afternoon needs. There are four of them, and every
build step today is one of the four, sometimes two.

One. Duplicate. Right-click the component under Components, choose Duplicate, and rename it.
The copy keeps every wire. Today, `Car` becomes `GradeCar`.

Two. Parameter. Add parameter, give it a name and a default, then type that name into the
part's parameter. Today that is `k`, `Ti` and `Td` on the controller, and `T_max`, `m` and
`theta_e` on the car, each one in the section that first needs it.

Three. Two kinds of wire. Arrows carry numbers, one way. Joints carry physics, both ways. You
can only wire like to like, and the port shape tells you which. The controller is all arrows.

Four. Run and plot. A harness to feed the inputs, the initial state in code, a
TransientAnalysis from the Run button, run it from Analyses, and plot.

You will use wiring most. The controller is seven blocks and about a dozen wires.
-->

---

## Full throttle from rest

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [01-the-car.ipynb · cell 4. Open loop to terminal speed]
Scenarios = VehicleSystemsComponents.Lecture1

wot = Scenarios.WideOpenThrottleTransient()

plt = plot_speed(wot; sig = "plant.v_kmh", label = "speed",
                 title = "Full torque from rest, flat road")
hline!(plt, [v_terminal * 3.6]; ls = :dash, color = :grey,
       label = "terminal speed, analytic")
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/01-the-car.ipynb)

**Open in Dyad** `dyad/Lecture1/WideOpenThrottle.dyad`

> **Watch the time axis**
>
> 300 seconds, and the last stretch barely moves. The car's own time constant near 100 km/h
> is about **67 s**.

*↩ Hands-on step 05: [why it takes so long — the car's time constant](../handson-01/index.html#/time-constant)*

</div>
<div>

![Speed against time, full torque from rest, rising asymptotically to about 246 km/h over several hundred seconds.](/figures/01-speed-to-terminal.svg)

*Speed to terminal, full torque from rest — `HandsOn.Car`, the same curve as your hands-on step 05. The asymptote is the 246 km/h derived on paper.*

</div>
</div>

<!--
You have all seen this curve. It is your step 05, run on the reference `Car`. Today, look at the
time axis rather than the 246. It takes two and a half minutes to get within one percent,
because drag is a very weak restoring force at low speed.

Remember this time axis. In notebook 03 the closed loop will do a 20 km/h step in a few seconds.
Feedback does not make the engine stronger. It changes the **dynamics**: how fast and in what
way the car responds.

If your curve runs away instead of flattening, the sign on the drag force is wrong.

The harness is a constant source feeding the plant's torque input, plus the initial conditions.
Leave those inputs unconnected and the model will not solve. This is the
reference version of your own `CarFullThrottle` bench, on `HandsOn.Car`.

The run is 300 seconds long. That is about twice the 143 seconds the car needs to reach 99
percent of terminal speed. The car's own time constant near 100 km/h is 67 seconds. That is
the mass divided by how hard drag pushes back per unit of speed. A time constant is the time to
cover 63 percent of the remaining distance to the final value. Three of them get you to 95
percent. And the dashed line is the 246 km/h you computed by hand in hands-on step 05. The
simulation and the hand calculation agree.
-->

---

## The step test

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [01-the-car.ipynb · cell 5. The step test, and the zoom below it]
# the two cruise torques derived on paper, handed to the model
step_test = Scenarios.CarStepTestTransient(
    tau_lo = T_90, tau_hi = T_110, v0 = 90 / 3.6, t_step = t_step)

plot_torque(step_test;
    commanded = "cmd.y",
    delivered = "plant.engine.limiter.y",
    limit = nothing,
    xlims = (t_step - 0.5, t_step + 3.0))
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/01-the-car.ipynb)

**Open in Dyad** `dyad/Lecture1/CarStepTest.dyad`

*↩ Hands-on step 02: [why the engine is late and slow](../handson-01/index.html#/pedal)*

1. Wait until the process is at rest.
2. Put the controller in manual.
3. Change the control variable rapidly, and as large as noise allows.
4. Record the response and scale it by the size of the step.

</div>
<div>

![Commanded and delivered torque on one axes: the delivered trace starts late by the transport delay and then lags behind the command.](/figures/01-torque-step.svg)

*Commanded against delivered torque. The gap at the start is the transport delay; the curve after it is the manifold lag.*

</div>
</div>

<!--
Notebook 08 builds on this four-line procedure. Every heuristic tuning rule in this lecture reads its numbers off this one experiment.

Look at the torque plot. First there is a flat piece, where the command has stepped and nothing
has happened yet. That is **dead time**: the time before the engine responds at all. Then comes the curve.
That is the manifold filling. Two different delays, with two different causes, and they need
different treatment.

In hands-on step 02 we justified these lags on paper. Without them the car is first order,
Ziegler-Nichols has nothing to oscillate, and Cohen-Coon divides by a dead time of zero. This
plot is the first time they show up as a control problem.

We step from 31 to 40 newton-meters, and not from 0 to 150, because we want the response around
the operating point we actually drive at. Drag grows with v squared, so over a large step the
car's behavior changes too much.

In the model, `tau_lo` and `tau_hi` are parameters. So the step test runs the equation you just
wrote down. T 90 is 31.1 newton-meters and T 110 is 40.1 newton-meters. Those are the cruise
torques for 90 and 110 km/h, from the force balance. The command steps at `t_step`, 50 seconds.
And inside `HandsOn/Engine.dyad` the order is delay, then lag, then limiter.

On the plot, the commanded torque is `cmd.y`, what the controller asks for. The delivered torque
is `plant.engine.limiter.y`, what comes out of the engine after the delay, the lag and the limit.
The flat gap at the start is a pure delay. The curve after it is a lag. A lag is not a delay: it
starts immediately and approaches gradually.

Next, you build this same harness on your own `Car`.
-->

---
routeAlias: build-step-test
---

## Build: the step test, on your `Car`

<div class="grid grid-cols-2 gap-6">
<div>

![CarStepTest: a torque step source feeding the plant, an instance of Car.](/img/lecture-01/step01-step-test.png)

</div>
<div>

![plant.v_kmh rising from 90 to 110 km/h after the torque step at 50 s.](/img/lecture-01/step01-step-test-plot.png)

</div>
</div>

*New component `CarStepTest` · `cmd` Step(offset = 31.078, height = 9.041, start_time = 50) → `plant` (your `Car`) ·
three `initial` lines · TransientAnalysis `stop = 500`*

```julia
using MyCar, Plots; plotly()
r = MyCar.CarStepTestTransient()
plot(r; idxs = r."plant.v_kmh")
```

```julia
plot(r; idxs = r."plant.engine.limiter.y", xlims = (49.5, 52))
```

Paste it into the Julia REPL (**Dyad: Open Julia REPL**). `plotly()` makes the plot interactive: drag to zoom, double-click to reset.

[page: step 1a](../lecture/lecture-01/#step-1a) · reference `dyad/Lecture1/CarStepTest.dyad`

<!--
Let's build it together.

First, a new component. Under Components, right-click `MyCar`, choose Add Component, and call it
`CarStepTest`.

Now drag in `BlockComponents.Sources.Step` and name it `cmd`. Set `offset` to 31.078, `height`
to 9.041, and `start_time` to 50. 31.078 holds 90 km/h, and 40.119 holds 110. The height is
their difference.

Next, drag in your `Car` from `MyCar` and name it `plant`. The name matters. The notebook reads
`plant.v_kmh` and `plant.engine.limiter.y`.

Wire `cmd.y` into `plant.tau_cmd`. That is the only wire. `Car` has no grade input.

Now switch to code and add the initial state, so the car starts cruising at 90 km/h in
equilibrium. Three lines. `initial plant.body.mass.s = 0`. `initial plant.body.mass.v = 25`.
And `initial plant.engine.lag.x = 31.078`. Save.

Now Run Analysis, choose TransientAnalysis, name it `CarStepTestTransient`, and set `stop` to
500. Run it from Analyses.

Now plot `plant.v_kmh` in the Julia REPL. Open it with Dyad: Open Julia REPL, in the title bar of
the Actions panel. The code is on the slide. `plotly()` makes the plot interactive: drag a box to
zoom, and double-click to zoom back out. Every snippet today starts with that same line, so it
also works in a fresh REPL.

You should see the speed flat at 90 km/h until 50 seconds, then an S-shaped climb that levels
off at 110 km/h by the end of the run.

Now the second snippet. It plots the delivered torque, `plant.engine.limiter.y`, over the two
and a half seconds around the step. The command steps at 50 seconds. The delivered torque stays
at 31.1 for about 0.3 seconds. That is the transport delay. The small dip just before it rises
comes from the Padé approximation of that delay, not from your model. Then it rises along the
lag, and is at 40.1 newton-meters by 52 seconds.

The usual mistake is leaving out `initial plant.engine.lag.x`. The lag then starts at zero
torque, the car spends the first minute slowing down, and the step lands on a car that is not at
90.

If your speed settles at 110 but the curve looks different from the notebook's, compare your
`offset` and `height`. A run that ends anywhere other than 110 has the wrong torques.
-->

---

## Transient, steady state and dynamic response

<div class="grid grid-cols-3 gap-6">
<div>

### Transient

The temporary part. The system's reaction to an abrupt change, which dies
out.

</div>
<div>

### Steady state

What is left after long enough that every startup effect has gone. The
settled relationship between input and output.

</div>
<div>

### Dynamic response

The whole response: the sum of the two.

</div>
</div>

$$
y(t) \;=\; y_{\text{transient}}(t) \;+\; y_{\text{steady-state}}(t)
$$

> **Why the vocabulary matters today**
>
> Proportional control is about to fail in *steady state* while looking fine in the
> *transient*. These terms say where the failure is.

<!--
Look back at the speed plot from the step test. At first, the speed is moving. Later, it has
stopped moving.

The transient never ends exactly. It decays asymptotically. We pick a threshold, usually 2
percent or 5 percent. When the
response stays inside that band of its final value, that is the settling time.

Control requirements are usually written in these terms. Rise time, overshoot and settling time
describe the transient. Steady-state error describes the steady state.
-->

---

## Reading K, τ and θ off the curve

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

```julia [01-the-car.ipynb · cell 7. Reading K, tau and theta off the curve]
K, tau, theta = fopdt_fit(step_test;
    output = "plant.v_kmh", A = T_110 - T_90, t0 = t_step)

# and, for comparison, the tangent gain and time constant at
# each end of the step, straight from the force balance
local_gain(v) = 3.6 / (2 * c_drag * v * CAR.r / CAR.i)
local_tau(v)  = CAR.m / (2 * c_drag * v)
```

[open notebook](https://github.com/dr14-make/16ESPD/blob/main/notebooks/lecture01/01-the-car.ipynb)

- **K** = 2.21 km/h per N·m
- **τ** = 63.0 s
- **θ** = 1.82 s

> **θ is not the engine's delay**
>
> It is about six times larger. Drag is quadratic, so the car's time constant changes across the
> step, and θ is the only parameter that can absorb that. Here θ measures the curvature of the
> response more than the delay.

</div>
<div>

![The speed response to the torque step: flat at 90 km/h, then an S-shaped climb settling at 110.](/figures/01-step-response.svg)

*The step response the three numbers are read from. θ is the flat piece before it moves, τ the rise, K the settled change divided by the torque step.*

</div>
</div>

<!--
Here are the three values. K is 2.21 km/h per newton-meter. That is the steady-state gain: how
far the output moves per unit of input, once settled. Tau is 63.0 seconds. That is the time
constant: how long it takes to get there, and it is dominated by the vehicle, not the engine.
Theta is 1.816 seconds, the dead time as the fit reports it. Write all three down. You will need
them again in section 08.

This is system identification for a first-order plant plus dead time, F O P T D. One step in
gives one curve, and we read three numbers off it. It needs no free-body diagram and no equations
of motion. If somebody handed you this car as a sealed box, you could still get these numbers.

Now the amber box. You know the engine's delay is 0.3 seconds. You see 1.82 seconds here, but the fit is
correct. FOPTD has three parameters, and our car is not
FOPTD. It has a **quadratic** drag law, so its time constant is different at every speed. The
fit spends theta on the mismatch, because theta is the only parameter left.

In practice this is all you have. You do not know that your plant is quadratic. You have a curve
and three numbers. Notebook 08 tunes from these three as they stand, and the controller works.

Look at the ratio theta over tau. It is about 0.029 here. Every tuning rule in notebook 08 uses
this ratio, and a value this small means a car that is easy to control.

For comparison, take the tangent time constant at each end of the step, straight from the force
balance. It is 74.1 seconds at 90 km/h and 60.6 seconds at 110. The fitted 63.0 lies between
them. And the secant gain, the total speed change divided by the total torque
change, is 20 divided by 9.04. That is what K should land near.

One common mistake is reading tau as the time to reach the final value. It is the time to reach
63 percent of it. The helper uses the two-landmark construction from the tuning document, not a
reading by eye.
-->

---
routeAlias: gradebody-reminder
---

## Reminder: your `GradeBody`

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

![GradeBody: the grade input feeds both the rolling resistance inclination and the grade force.](/img/handson-01/step07-grade-body.png)

</div>
<div>

`Body`, plus one input and one equation:

$$ F_{\text{slope}} = m\,g\,\sin(\arctan \text{grade}) $$

- `grade` is tan α: 0.10 is a 10 % sign.
- One signal tilts the rolling resistance *and* drives the slope force.
- 10 %: **1366 N** back, against **1935 N** the engine can push.

*↩ Hands-on step 07: [the slope](../handson-01/index.html#/slope)*

</div>
</div>

<!--
This is the body you built in hands-on step 07. The
same mass, drag and rolling resistance, plus your first hand-written equation: the part of the
weight that pulls back along the slope.

Look at the `grade` input on the left, and its two wires. One number drives both the slope force
and the rolling resistance's inclination, so they can never disagree.

Section 02 uses a hill to show why we need feedback. So before we close any loop, the car gets
this body.
-->

---
routeAlias: build-gradecar
---

## Build: `GradeCar`

<div class="grid grid-cols-[1.4fr_1fr] gap-8">
<div>

![GradeCar: the Car diagram with GradeBody in place of Body, and a grade input on the left under tau_cmd wired to body.grade.](/img/lecture-01/step01-gradecar.png)

</div>
<div>

*Duplicate `Car` → `GradeCar` · `body`: `Body` → your `GradeBody` · new `RealInput` `grade`
on the left, under `tau_cmd` → `body.grade` · bench `GradeCarFullThrottle`*

```julia
using MyCar, Plots; plotly()
r = MyCar.GradeCarFullThrottleTransient()
plot(r; idxs = r."car.v_kmh")
```

[page: step 1b](../lecture/lecture-01/#step-1b) · reference `dyad/Lecture1/Step01/GradeCar.dyad`

> **The plant from here to section 09**
>
> Every loop in this lecture runs on this model. Section 10 swaps it for `SlipCar`.

</div>
</div>

<!--
Let's build it together.

First, duplicate. Under Components, right-click `Car`, choose Duplicate, and rename it to
`GradeCar`. Open it.

Now swap the body. Delete `body`, drag in your `GradeBody` from `MyCar`, and rename it `body`.
Redraw the two wires the old body had: `driveline.flange` to `body.flange`, and
`vsensor.flange` to `body.flange`. Keep the name `body`. The `initial plant.body.mass` lines in
every harness today depend on it. There is a quicker way, in code. Change `body = Body()` to
`body = GradeBody()`. The wires survive, because the port has the same name.

Next, a new input. Drag a `RealInput` from the `Dyad` library onto the outline, on the left,
under `tau_cmd`. Name it `grade`. Wire `grade` into `body.grade`.

Save. The problems panel must be empty.

Now the bench. Right-click `CarFullThrottle`, choose Duplicate, and call it
`GradeCarFullThrottle`. Replace `car` with a `GradeCar` named `car`. Add `road`, a
`BlockComponents.Sources.Constant` with `k` equal to 0, and wire `road.y` into `car.grade`.
Add a TransientAnalysis called `GradeCarFullThrottleTransient`, with `stop` at 300. Run it and
plot `car.v_kmh`, with the code on the slide.

No parameters yet. `T_max` arrives in section 06, and `m` and `theta_e` in section 08, each in the
section that first needs it. The reference `GradeCar` already carries all of them. Ignore that for
now.

You should see 246.39 km/h at 300 seconds, the same as `Car`. A `GradeBody` on a flat road is a
`Body`. Now set `road.k` to 0.1 and run it again. The terminal speed drops, and the engine sits
on its 150 newton-meter ceiling the whole way. Even without the bench run, the block should show
two inputs on the left, `tau_cmd` and `grade`, and `v_kmh` on the right.

The usual mistake is renaming `body` while swapping it. Every harness from here on writes
`plant.body.mass.v`. A body called `gradebody` breaks all of them.
-->

---

## Summary of section 01

- The car you built, seen from outside: one step in, one curve out.
- Three numbers from one step test, *K*, *τ* and *θ*, which section 08 turns into gains.
- The vocabulary: transient, steady state, dynamic response.
- `GradeCar`: your car on a road with a grade, the plant for every loop today.

### Next: we have a model of the car. Do we even need to measure it? <Link to="open-vs-closed-loop">→ 02, open loop versus closed loop</Link>

<!--
We now know what the car does without a controller, from its physics and from a measurement.
Control design starts from this, and people often skip it.

We have a model of the car that is good enough to predict
its terminal speed. If the model is that good, why measure anything at all? Why not just compute
the right throttle and apply it? Notebook 02 answers this with a hill. That is why your
car just got a `grade` input.

Before we move on, make sure your `GradeCar` compiles. If it does not, paste the `GradeCar`
from the guide page's step 1b now. Section 02 wires it into the loop.
-->

