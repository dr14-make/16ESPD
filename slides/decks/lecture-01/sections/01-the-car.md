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
No controller in this section either. We recall the hands-on car in a few slides, then measure it
the way a control engineer would: one step test, three numbers. At the end the car gets a grade
input, so it can climb a hill.

From here on you build along with me. Open your `MyCar` in Studio, with `Car` and `GradeBody` in it.
If you do not have it, copy the MyCar template linked from the guide page. It is the finished
hands-on car, with the same instance names.
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
This is the hands-on in one table. Each row is the equation a part adds and the number your bench
showed. You predicted each one on paper first, and your model matched.

The `Car` diagram, top right, is the plant for the whole lecture. At the end of this section its
`Body` becomes your `GradeBody`: the hill we need from section 02. In section 10 the whole car
becomes `SlipCar`, with a tire whose grip has a peak, on ice.

The number to remember is 1366 newtons, the pull of a 10 percent hill. That is most of the 1935
newtons the engine can push. Section 06 is about this case.

The derivations are in the hands-on deck. The link at the bottom goes to its summary table.
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

<img src="/diagrams/01-signal-wire.svg" class="h-20" alt="Two blocks joined by an arrow: the first block's number is read by the second.">

**Acausal** — `Flange`, `Spline`: a joint, no direction. The car is these.

<img src="/diagrams/01-mechanical-joint.svg" class="h-20" alt="Two blocks joined by a plain line with no arrowhead: they move together and push on each other equally.">

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
Every build step today is one of four Studio moves, sometimes two. You know all of them.

One. Duplicate: right-click the component, Duplicate, rename. The copy keeps every wire. Today `Car`
becomes `GradeCar`.

Two. Parameter: add it with a name and a default, then type that name into the part's parameter.
Today that is `k`, `Ti` and `Td` on the controller, and `T_max`, `m` and `theta_e` on the car.

Three. Two kinds of wire. Arrows carry numbers, one way. Joints carry physics, both ways. The port
shape tells you which, and you can only wire like to like. The controller is all arrows.

Four. Run and plot: a harness for the inputs, the initial state in code, a TransientAnalysis from
the Run button, run it from Analyses, plot.

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
This is your step 05, on the reference `Car`. Today, look at the time axis, not the 246. The car
needs 143 seconds to reach 99 percent of terminal speed, because at low speed drag pushes back very
weakly.

Remember that time axis. In notebook 03 the closed loop does a 20 km/h step in a few seconds.
Feedback does not make the engine stronger. It changes the **dynamics**: how fast the car responds,
and in what way.

The car's time constant near 100 km/h is 67 seconds: the mass divided by how hard drag pushes back
per unit of speed. One time constant covers 63 percent of the remaining distance. Three cover 95
percent. The dashed line is the 246 km/h you computed by hand in hands-on step 05, and the
simulation agrees.

This harness is the reference version of your `CarFullThrottle` bench: a constant source on the
torque input, plus the initial conditions. If your curve runs away instead of flattening, the sign
on the drag force is wrong.
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
Notebook 08 builds on this four-line procedure. Every tuning rule in this lecture reads its numbers
off this one experiment.

We step from 31 to 40 newton-meters, the cruise torques for 90 and 110 km/h, and not from 0 to 150.
We want the response around the speed we actually drive at. Drag grows with v squared, so over a
large step the car's behavior changes too much.

Look at the torque plot. The commanded torque is `cmd.y`. The delivered torque is
`plant.engine.limiter.y`, after the engine's delay, lag and limit. First a flat gap, where the
command has stepped and nothing has happened yet. That is **dead time**, a pure delay. Then a curve:
the manifold filling. That is a lag. A lag starts at once and approaches gradually. Two delays with
two causes, and they need different treatment.

In hands-on step 02 we justified these lags on paper. Without them the car is first order,
Ziegler-Nichols has nothing to oscillate, and Cohen-Coon divides by a dead time of zero. This plot
is where they first become a control problem.

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
Let's build it.

Under Components, right-click `MyCar`, choose Add Component, and call it `CarStepTest`.

Drag in `BlockComponents.Sources.Step` and name it `cmd`. Set `offset` to 31.078, `height` to 9.041,
and `start_time` to 50. 31.078 holds 90 km/h, 40.119 holds 110, and the height is the difference.

Drag in your `Car` and name it `plant`. The name matters: the notebook reads `plant.v_kmh` and
`plant.engine.limiter.y`.

Wire `cmd.y` into `plant.tau_cmd`. That is the only wire.

Switch to code and add the initial state, so the car starts cruising at 90 km/h. `initial
plant.body.mass.s = 0`. `initial plant.body.mass.v = 25`. `initial plant.engine.lag.x = 31.078`.
Save.

Run Analysis, choose TransientAnalysis, name it `CarStepTestTransient`, and set `stop` to 500. Run
it from Analyses.

Plot in the Julia REPL. Open it with Dyad: Open Julia REPL, in the Actions panel's title bar. The
code is on the slide. `plotly()` makes the plot interactive: drag a box to zoom, double-click to
zoom back out.

You should see 90 km/h until 50 seconds, then an S-shaped climb that levels off at 110 by the end.

The second snippet zooms in on the delivered torque around the step. It stays at 31.1 for about 0.3
seconds: the transport delay. The small dip before it rises comes from the Padé approximation, not
from your model. Then it climbs along the lag and reaches 40.1 by 52 seconds.

The usual mistake is leaving out `initial plant.engine.lag.x`. The lag then starts at zero torque,
the car slows for the first minute, and the step lands on a car that is not at 90. If the run ends
anywhere but 110, check `offset` and `height`.
-->

---

## Transient, steady state and dynamic response

<div class="grid grid-cols-[1fr_1.5fr] gap-8">
<div>

### Transient

The temporary part. The system's reaction to an abrupt change, which dies out.

### Steady state

What is left after long enough that every startup effect has gone. The settled relationship
between input and output.

### Dynamic response

The whole response: the sum of the two.

$$
y(t) \;=\; y_{\text{transient}}(t) \;+\; y_{\text{steady-state}}(t)
$$

</div>
<div>

![The step-test speed with its parts shaded: steady state at 90 km/h before the step, the transient climb, and steady state at 110 km/h once the speed stays inside a 2 percent band.](/figures/01-response-parts.svg)

> **Why the vocabulary matters today**
>
> Proportional control is about to fail in *steady state* while looking fine in the
> *transient*. These terms say where the failure is.

</div>
</div>

<!--
This is the step test again, with its parts marked. Before the step, and long after it, the speed
does not move: steady state. In between it climbs: the transient.

The transient never ends exactly. It decays toward the final value. So we pick a band, usually 2 or
5 percent. Once the response stays inside it, that is the settling time. Here the car stays inside
2 percent 240 seconds after the step.

Requirements are written in these terms. Rise time, overshoot and settling time describe the
transient. Steady-state error describes the steady state.
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

![The step test with the fit drawn on it: the 50 and 63.2 percent levels of the 20 km/h change, the times t2 and t3 where the speed crosses them, tau from t1 to t3, the total change B, and a zoom on the step showing theta from t0 to t1.](/figures/01-step-readings.svg)

*Read t₂ and t₃ where the speed crosses 50 % and 63.2 % of B. Then t₁ = (t₂ − ln 2 · t₃) / (1 − ln 2), θ = t₁ − t₀, τ = t₃ − t₁, and K = B / A with A = 9.04 N·m the torque step.*

</div>
</div>

<!--
K is 2.21 km/h per newton-meter: how far the speed moves per unit of torque, once settled. Tau is
63.0 seconds: how long it takes to get there, set by the vehicle, not the engine. Theta is 1.816
seconds, the dead time as the fit reports it. Write all three down. Section 08 uses them.

This is system identification for a first-order plant plus dead time, F O P T D. One step in, one
curve out, three numbers. No equations of motion. If somebody handed you this car as a sealed box,
you could still get them.

The amber box. The engine's delay is 0.3 seconds, and the fit says 1.82. The fit is still right. Our
car is not FOPTD: its drag is **quadratic**, so its time constant changes with speed. Theta is the
only parameter left to absorb that mismatch.

In practice this is all you have: a curve and three numbers. Notebook 08 tunes from them as they
stand, and the controller works.

Theta over tau is about 0.029. Every tuning rule in notebook 08 uses this ratio, and a value this
small means a car that is easy to control.

As a check, the force balance gives a tangent time constant of 74.1 seconds at 90 km/h and 60.6 at
110. The fitted 63.0 lies between them. K should land near 20 divided by 9.04, the total speed
change over the total torque change.

The plot shows how the fit gets them. Read the two times where the speed crosses half and 63
percent of the change. The first-order curve through both points starts rising at t1. Theta runs
from the step to t1, tau from t1 to the 63 percent point. In the zoom, the real speed is already
moving long before t1. That is why theta is not the engine's delay.

A common mistake is reading tau as the time to reach the final value. It is the time to reach 63
percent of it.
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
This is your `GradeBody` from hands-on step 07: the same body, plus your first hand-written
equation, the part of the weight that pulls back along the slope.

One `grade` input drives both the slope force and the rolling resistance's inclination, so they
cannot disagree.

Section 02 needs a hill to show why we need feedback. So before we close any loop, the car gets this
body.
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
Let's build it.

Right-click `Car`, choose Duplicate, and rename it `GradeCar`. Open it.

Swap the body. Delete `body`, drag in your `GradeBody`, and name it `body`. Redraw its two wires:
`driveline.flange` to `body.flange`, and `vsensor.flange` to `body.flange`. Faster, in code: change
`body = Body()` to `body = GradeBody()`. The wires survive, because the port has the same name.

Add a `RealInput` from the `Dyad` library on the left edge, under `tau_cmd`. Name it `grade` and
wire it into `body.grade`. Save. The problems panel must be empty.

Now the bench. Duplicate `CarFullThrottle` as `GradeCarFullThrottle`. Replace `car` with a
`GradeCar` named `car`. Add `road`, a `BlockComponents.Sources.Constant` with `k` equal to 0, and
wire `road.y` into `car.grade`. Add a TransientAnalysis `GradeCarFullThrottleTransient` with `stop`
at 300, run it, and plot `car.v_kmh` with the code on the slide.

You should see 246.39 km/h at 300 seconds, the same as `Car`: on a flat road a `GradeBody` is a
`Body`. Set `road.k` to 0.1 and run again. The terminal speed drops, and the engine sits on its 150
newton-meter ceiling the whole way.

No parameters yet. `T_max` comes in section 06, `m` and `theta_e` in section 08. The reference
`GradeCar` already has them. Ignore that for now.

The usual mistake is renaming `body` during the swap. Every harness from here on writes
`plant.body.mass.v`, so a body called `gradebody` breaks all of them.
-->

---

## Summary of section 01

- The car you built, seen from outside: one step in, one curve out.
- Three numbers from one step test, *K*, *τ* and *θ*, which section 08 turns into gains.
- The vocabulary: transient, steady state, dynamic response.
- `GradeCar`: your car on a road with a grade, the plant for every loop today.

### Next: we have a model of the car. Do we even need to measure it? <Link to="open-vs-closed-loop">→ 02, open loop versus closed loop</Link>

<!--
We now know what the car does without a controller, from its physics and from a measurement. Control
design starts here, and people often skip it.

Our model predicts the terminal speed. So why not just compute the right throttle and apply it?
Notebook 02 answers that with a hill. That is why your car just got a `grade` input.

Make sure your `GradeCar` compiles. If it does not, paste the one from the guide page's step 1b now.
Section 02 wires it into the loop.
-->

