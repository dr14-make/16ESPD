---
routeAlias: the-car
layout: section
---

###### Notebook 01

# The car

You built it. Recall it, measure it as if you had not, and put it on a hill.

`notebooks/lecture01/01-the-car.ipynb`

[page: step 1a](../lecture/lecture-01/#step-1a) · reference `dyad/HandsOn/Car.dyad`, `dyad/Lecture1/CarStepTest.dyad`

<!--
**Say:** no controller in this section either. The force balance, the terminal speed and the
engine's lags were explained and built in the hands-on. We recall them in three slides, then
take the control engineer's view of the same car: one experiment, three numbers. And we end by
giving the car the one thing it needs before it can be controlled on a real road — a hill.

**Timing:** 22 minutes. Recap 8 (model map 3, four Studio moves 3, plant numbers 2), full
throttle 2, step test and build 1a 5, the three names 1, K/τ/θ 3, GradeBody reminder and
build 1b 3. Start the full-throttle solve in the notebook while the recap is still up.

**Students build from here.** Everyone needs their hands-on package (`MyCar`) open in Studio,
with `Car` and `GradeBody` in it. Anyone without it takes the reference `dyad/HandsOn/` from
the guide page and works on that — the instance names match.
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

*Engine → Driveline → Body → Car is the trunk. GradeBody and SlipCar are the two branches.*

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
**Say:** this is your morning on one slide. Four parts in a row — the trunk — and two
branches off it. Every row has the one equation that part adds and the number your bench
showed when you ran it. You predicted each of those on paper first, and your model hit it.

**Point at:** the `Car` diagram, top right. That is the plant for the whole lecture. Section 01
measures it; the end of section 01 swaps its `Body` for your `GradeBody`; section 10 swaps the
whole thing for `SlipCar`.

**Point at:** the two branch pictures. `GradeBody` is the hill — needed in section 02. The slip
wheel is the tire with a peak — needed in section 10, on ice.

**Ask the room:** which of these numbers would a controller have to fight? *(The 1366 N of a
10 % hill — that is most of the 1935 N the engine can push. Section 06 is that fight.)*

**Timing:** 3 minutes. Do not re-derive anything; the hands-on deck has every derivation, and
the link at the bottom goes straight to the summary table.
-->

---
routeAlias: studio-moves
---

## Four Studio moves, repeated all afternoon

<div class="grid grid-cols-2 gap-8">
<div>

#### 1 · Duplicate a component

Components → right-click → **Duplicate**, then rename. You did it for `WheeledDriveline` and
`GradeBody`; today `Car` → `GradeCar`.

#### 2 · Add a parameter, pass it down

**Add parameter** in the component panel, then the part refers to it by name:
`Engine(T_max = T_max)`. One number, one place.

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
**Say:** you already know every Studio move this afternoon needs. There are four of them, and
every build step today is one of the four, sometimes two.

**Point at, one at a time:**

1. **Duplicate.** Right-click the component under Components, Duplicate, rename. The copy
   keeps every wire. Today: `Car` becomes `GradeCar`.
2. **Parameter.** Add parameter, give it a name and a default, then type that name into the
   part's parameter. Today: `k`, `Ti`, `Td` on the controller; `T_max`, `m`, `theta_e` on the
   car, each when the story first needs it.
3. **Two kinds of wire.** Arrows carry numbers, one way; joints carry physics, both ways. You
   can only wire like to like — the port shape tells you which. The controller is all arrows.
4. **Run and plot.** A harness to feed the inputs, the initial state in code, a
   TransientAnalysis from the ▷ button, run it from Analyses, plot.

**Ask the room:** which of the four do you expect to use most? *(Wiring. The controller is
seven blocks and about a dozen wires.)*

**Timing:** 3 minutes. If someone in the room did not do the hands-on, pair them with someone
who did for the first build.
-->

---
routeAlias: plant-numbers
---

## The numbers the rest of the lecture leans on

<div class="grid grid-cols-2 gap-8">
<div>

| | | comes back in |
|---|---:|---|
| Padé transport delay θ<sub>e</sub> | **0.3 s** | 08 tuning, 09 sampling |
| torque lag τ<sub>e</sub> | **0.3 s** | 08 tuning |
| torque ceiling *T*<sub>max</sub> | **150 N·m** | 06 windup |
| holding torque at 90 km/h | **31.08 N·m** | every loop's starting state |
| time constant *τ* | **from the step test** | 08 tuning |

</div>
<div>

> **Late, slow and capped**
>
> The first three are the engine, and each one becomes a control problem today. The fourth is
> where every run starts: the car already cruising at 90 km/h. The last one you are about to
> measure.

</div>
</div>

<!--
**Say:** five numbers. Write them down; you will be asked for each one later.

**Point at, top to bottom:**

- **0.3 s delay.** The Padé block in your `Engine`. Nothing happens for 0.3 s after a command.
  It is what makes high gains oscillate in section 03, and what Ziegler-Nichols measures in 08.
- **0.3 s lag.** The first-order block after it. The torque arrives gradually.
- **150 N·m.** The limiter. Every controller today asks for more than that at some point; in
  section 06 it asks for more than that *for a long time*, and the integrator does not notice.
- **31.08 N·m.** The torque that holds 90 km/h: drag 236 N plus rolling 165 N is 401 N at the
  road, times 0.31, divided by 4. Every loop today starts at 90 km/h with the engine's lag
  already holding this, so no run begins with a transient of its own.
- **The time constant.** Not a number we type in — the car's own, read off a step test in the
  next five minutes.

**Timing:** 2 minutes.
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
> 300 seconds, and the last stretch barely moves. The car's own time constant is about
> **67 s**.

*↩ Hands-on step 05: [why it takes so long — the car's time constant](../handson-01/index.html#/time-constant)*

</div>
<div>

![Speed against time, full torque from rest, rising asymptotically to about 246 km/h over several hundred seconds.](/figures/01-speed-to-terminal.svg)

*Speed to terminal, full torque from rest — `HandsOn.Car`, the same curve as your hands-on step 05. The asymptote is the 246 km/h derived on paper.*

</div>
</div>

<!--
**Run it** before you start talking — it is the slowest solve in the notebook.

**Say:** everyone has seen this curve — it is their step 05, run on the reference `Car`. The point today is not the 246;
it is the time axis. Two and a half minutes to get within one percent, because drag is a
very weak restoring force at low speed.

**Say:** remember this time axis. In notebook 03 the closed loop will do a 20 km/h step in a
handful of seconds. Feedback did not make the engine stronger; it made the *dynamics*
different. That is the single most important sentence about feedback in this lecture.

**Check:** if the curve runs away instead of flattening, the sign on the drag force is wrong.

**In the model:** **why a harness exists**: a constant source feeding the plant's torque
input, and the initial conditions. Leave those inputs dangling and the model will not solve.
It is the reference version of the students' `CarFullThrottle` bench, on `HandsOn.Car`.

**Readout — every symbol on this slide**

- **300 s** — the run length. About twice the 143 s the car needs to reach 99 % of terminal
  speed.
- **67 s** — the car's own time constant near 100 km/h: m ÷ (dF/dv), mass divided by how hard
  drag pushes back per unit of speed.
- **Time constant** — the time to cover 63 % of the remaining distance to the final value.
  Three of them gets you to 95 %.
- **The dashed line** — the 246 km/h computed by hand in hands-on step 05. Two routes, one
  number.
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
**Say:** this procedure is four lines long and it is the foundation of notebook 08. Every
heuristic tuning rule in this lecture reads its numbers off this one experiment.

**Point at, on the torque plot:** first the flat piece where the command has stepped and
nothing has happened yet — that is *dead time*, the engine has not been told yet. Then the
curve — the manifold filling. Two different delays with two different causes, and they need
different treatment.

**Tie back:** hands-on step 02 argued the lags in on paper — without them the car is first
order, Ziegler-Nichols has nothing to oscillate and Cohen-Coon divides by a dead time of zero.
This plot is the first time they are visible as a control problem.

**Ask the room:** why step from 31 to 40 N·m rather than 0 to 150? *(Because we want the
response around the operating point we actually drive at. A huge step wanders across the
nonlinearity in v².)*

**In the model:** **`tau_lo` and `tau_hi` are parameters**, so the step test runs the
equation the students just wrote down. Then `HandsOn/Engine.dyad`: **delay → lag → limiter**,
in that order.

**Next slide:** the students build this same harness on their own `Car`.

**Readout — every symbol on this slide**

- **T_90 = 31.1 N·m, T_110 = 40.1 N·m** — the cruise torques for 90 and 110 km/h, derived
  from the force balance and handed to the model as parameters.
- **t_step = 50 s** — when the command steps.
- **Commanded torque** — `cmd.y`, what the controller asks for.
- **Delivered torque** — `plant.engine.limiter.y`, what comes out of the engine after the
  delay, the lag and the limit.
- **Dead time** — the flat gap at the start where the command has changed and nothing has
  happened. A pure delay.
- **Lag** — the curve after it. A first-order response, not a delay: it starts immediately and
  approaches gradually.
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

[page: step 1a](../lecture/lecture-01/#step-1a) · reference `dyad/Lecture1/CarStepTest.dyad`

<!--
**Build it live, on the projector, with the room.** Switch to Studio.

1. **New component.** Components → right-click `MyCar` → Add Component → `CarStepTest`.
2. **Drag in** `BlockComponents.Sources.Step`, name it `cmd`. Parameters: `offset = 31.078`,
   `height = 9.041`, `start_time = 50`. (31.078 holds 90 km/h, 40.119 holds 110; the height is
   their difference.)
3. **Drag in** your `Car` from `MyCar`, name it `plant`. The name matters: the notebook reads
   `plant.v_kmh` and `plant.engine.limiter.y`.
4. **Wire** `cmd.y` → `plant.tau_cmd`. That is the only wire; `Car` has no grade input.
5. **⇄ to code** and add the initial state, so the car starts cruising at 90 km/h in
   equilibrium:
   `initial plant.body.mass.s = 0` · `initial plant.body.mass.v = 25` ·
   `initial plant.engine.lag.x = 31.078`. Save.
6. **▷ Run Analysis** → TransientAnalysis, name it `CarStepTestTransient`, `stop = 500`. Run
   it from Analyses.
7. **Plot** `plant.v_kmh`, and on a second plot `cmd.y` against `plant.engine.limiter.y`.

**The plot must show, before moving on:** speed flat at 90 km/h until 50 s, then an S-shaped
climb that levels off at 110 km/h by the end of the run. Zoomed on the step, the delivered
torque does nothing for 0.3 s, then rises along the lag to 40.1 N·m.

**They get wrong:** leaving out `initial plant.engine.lag.x`. The lag then starts at zero
torque, the car spends the first minute slowing down, and the step lands on a car that is not
at 90.

**If the speed settles at 110 but the curve looks different from the notebook's:** compare the
`offset` and `height`. A run that ends anywhere other than 110 has the wrong torques.

**Timing:** 3 minutes building, 1 running. Walk the room while it solves.
-->

---

## Three names for one curve

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

The whole journey — their sum.

</div>
</div>

$$
y(t) \;=\; y_{\text{transient}}(t) \;+\; y_{\text{steady-state}}(t)
$$

> **Why the vocabulary matters today**
>
> Proportional control is about to fail in *steady state* while looking fine in the
> *transient*. Without these three words that failure is invisible.

<!--
**Point at the speed plot from the previous slide** and mark the two regions with your hand:
here it is moving, here it has stopped moving. Do it physically — this is the one piece of
vocabulary everyone thinks they already have and half the room does not.

**Ask the room:** where exactly does the transient end? *(It does not — it decays
asymptotically. We pick a threshold, usually 2 % or 5 %, and that choice is ours, not the
system's.)*

**Flag forward:** every requirement you will ever be given is phrased in these terms — rise
time and overshoot live in the transient, steady-state error lives in the other half.

**Terms, if anyone asks**

- **Transient response** — the temporary part, which decays. Rise time, overshoot and settling
  time are measured here.
- **Steady-state response** — what is left once the transient has died. Steady-state error is
  measured here.
- **Dynamic response** — the sum of the two. The whole journey from one settled state to the
  next.
- **Settling time** — when the response stays within a band, usually 2 % or 5 %, of its final
  value. The band is our choice, not the system's.
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
- **θ** = 1.88 s

> **θ is not the engine's delay**
>
> It is five times larger. Drag is quadratic, so the car's time constant changes across the
> step, and θ is the only parameter that can absorb that. The fit measures bend, not delay.

</div>
<div>

![The speed response to the torque step: flat at 90 km/h, then an S-shaped climb settling at 110.](/figures/01-step-response.svg)

*The step response the three numbers are read from. θ is the flat piece before it moves, τ the rise, K the settled change divided by the torque step.*

</div>
</div>

<!--
**Read out** all three values from the cell output, slowly, with units. Students will need
them again in section 08 and they should write them down now.

**Say:** this is the whole of system identification for a first-order plant plus dead time —
FOPTD. A step in, a curve out, three numbers off the curve. No free-body diagram, no
equations of motion. If somebody handed you this car as a sealed box you could still have got
here.

**Do not skip the amber box, and do not let it embarrass you.** A student who knows the
engine's delay is 0.3 s will see 1.88 s and conclude the fit is broken. It is not. FOPTD has
three parameters and our car is not FOPTD — it is a *quadratic* drag law, so its time
constant is different at every speed. The fit spends θ on the mismatch because θ is the only
parameter left.

**Say:** and this is what a practitioner would have. You do not get to know that your plant
is really quadratic; you get a curve and three numbers. Notebook 08 tunes from these three
exactly as they stand, and the controller works — which is the more interesting result.

**Point at:** the ratio θ/τ — about 0.030 here. That is the number every tuning rule in
notebook 08 keys on, and it puts this car at the easy end of the range.

**Honest framing, if asked:** quote the tangent gain and time constant at each end of the
step — 74.1 s at 90 km/h, 60.6 s at 110. They bracket the fit rather than pretending it is
exact.

**They get wrong:** reading τ as "time to reach the final value". It is the time to reach
63 % of it. The helper uses the two-landmark construction from the tuning document, not an
eyeball.

**Readout — every symbol on this slide**

- **K = 2.21 km/h per N·m** — steady-state gain: how far the output moves per unit of input,
  once settled.
- **τ = 63.0 s** — time constant: how long it takes to get there, dominated by the vehicle,
  not the engine.
- **θ = 1.878 s** — dead time as the fit reports it. *Not* the engine's 0.3 s delay — see the
  amber box.
- **FOPTD** — first order plus dead time, the three-parameter shape these numbers describe.
- **Tangent gain / time constant** — the local values computed from the force balance at each
  end of the step: 74.1 s at 90 km/h, 60.6 s at 110. They bracket the fit honestly.
- **Secant gain** — the total speed change divided by the total torque change, 20 ÷ 9.04. What
  K should land near.
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
**Say:** one slide on the plant before we use it. This is the body you built in hands-on step
07: the same mass, drag and rolling resistance, plus your first hand-written equation — the
part of the weight that pulls back along the slope.

**Point at:** the `grade` input on the left, and its two wires. One number drives both the
slope force and the rolling resistance's inclination, so they can never disagree.

**Say:** a cruise controller that only ever drives on a flat road is not worth building. The
whole argument of section 02 is a hill. So before we close any loop, the car gets this body.

**Timing:** 30 seconds.
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

[page: step 1b](../lecture/lecture-01/#step-1b) · reference `dyad/HandsOn/GradeCar.dyad`

> **The plant from here to section 09**
>
> Every loop in this lecture runs on this model. Section 10 swaps it for `SlipCar`.

</div>
</div>

<!--
**Build it live, on the projector, with the room.**

1. **Duplicate.** Components → right-click `Car` → Duplicate → rename to `GradeCar`. Open it.
2. **Swap the body.** Delete `body`, drag in your `GradeBody` from `MyCar`, rename it `body`,
   and redraw the two wires the old body had: `driveline.flange` → `body.flange` and
   `vsensor.flange` → `body.flange`. Keep the name `body` — the `initial plant.body.mass...`
   lines in every harness today depend on it. (Quicker, in code: change `body = Body()` to
   `body = GradeBody()`; the wires survive because the port has the same name.)
3. **New input.** Drag a `RealInput` from the `Dyad` library onto the outline, on the left
   under `tau_cmd`. Name it `grade`.
4. **Wire** `grade` → `body.grade`.
5. **Save.** The problems panel must be empty.
6. **Bench.** Right-click `CarFullThrottle` → Duplicate → `GradeCarFullThrottle`. Replace
   `car` with a `GradeCar` named `car`, add `road` — `BlockComponents.Sources.Constant`,
   `k = 0` — and wire `road.y` → `car.grade`. TransientAnalysis
   `GradeCarFullThrottleTransient`, `stop = 300`. Run, plot `car.v_kmh`.

**No parameters yet.** `T_max` arrives in section 06, `m` and `theta_e` in section 08, each
when the story first needs it. The reference `GradeCar` already carries all of them; ignore
that for now.

**The plot must show, before moving on:** **246.39 km/h** at 300 s — the same as `Car`. A
`GradeBody` on a flat road is a `Body`. Ask the room to set `road.k = 0.1` and run again: the
terminal speed drops and the engine sits on its 150 N·m ceiling the whole way. If time is
short, skip the bench run; the block showing two inputs on the left (`tau_cmd`, `grade`) and
`v_kmh` on the right is enough to go on.

**They get wrong:** renaming `body` while swapping it. Every harness from here on writes
`plant.body.mass.v`; a body called `gradebody` breaks all of them.

**Timing:** 2 minutes building, 1 for the bench run.
-->

---

## What this bought us

- The car you built, seen from outside: one step in, one curve out.
- Three numbers off one step test — *K*, *τ*, *θ* — which section 08 will turn into gains.
- The vocabulary: transient, steady state, dynamic response.
- `GradeCar`: your car on a road with a grade — the plant every loop today runs on.

### Next: we have a model of the car. Do we even need to measure it? <Link to="open-vs-closed-loop">→ 02, open loop versus closed loop</Link>

<!--
**Say:** we now know what the car does when left alone — from its physics, and now from a
measurement. That is the only honest starting point for control, and it is the step people
skip.

**Bridge:** and here is an uncomfortable thought before the break in pace — we have a model of
the car that is good enough to predict its terminal speed. If the model is that good, why
measure anything at all? Why not just compute the right throttle and apply it? *(That is
notebook 02, and the answer is a hill — which is why your car just got a `grade` input.)*

**Check the room before moving on:** every student has a `GradeCar` that compiles. Anyone
who does not takes the reference `HandsOn.GradeCar` from the guide page now; section 02 wires
it into the loop.
-->

