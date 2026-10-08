---
routeAlias: front-matter
layout: cover
---

# Control Systems

<h1 class="!text-5xl !-mt-4 opacity-70">Introduction and PID</h1>

Vehicle Systems &amp; Components — Lecture 1

One car, three fidelity levels, ten notebooks.

<div class="text-xs opacity-60 mt-12">

<kbd>→</kbd> <kbd>Space</kbd> next &nbsp;·&nbsp; <kbd>←</kbd> previous &nbsp;·&nbsp;
<kbd>O</kbd> overview &nbsp;·&nbsp; <kbd>G</kbd> go to slide &nbsp;·&nbsp;
presenter mode from the nav bar, bottom left

</div>

<!--
**Before the room fills.** Deck on the projector, notebooks on the laptop screen. Open
**presenter mode** from the nav bar now (bottom left, it appears on hover): these notes, the
next slide and a timer in the same tab, no popup to block.

**Where this sits:** second of two sessions on one car. In the hands-on
(`slides/decks/handson-01/`) students learned each part's physics and built it. This deck does not
repeat that physics: wherever a slide relies on it, a grey *↩ Hands-on step NN* line links to
the exact slide. If a group skipped the hands-on, show its slides on the forces (step 04's
"Four forces on the car") and top speed (step 05, "Adding it all up" to "Top speed") first —
ten minutes.

**Say:** you built a car; today we control it six different ways. The car never changes.
Every new idea in this lecture is a change to the *controller*, never a change of subject —
so whatever you understand about the car at minute ten is still true at minute ninety.

**Timing:** 90 minutes. The spine is sections 01, 03, 04, 05, 06, 08 — about 60 minutes.
Everything else is bonus; drop from the back, not the middle. Each section's first slide
tells you, in these notes, whether it is safe to cut.

**Driving the deck.** **→** or **Space** next slide, **←** previous. **O** overview of
everything, **G** jump to a slide number, **F** fullscreen. Presenter mode, opened from the
nav bar (bottom left, on hover), is this window: these notes, the next slide and a timer.

**Two screens.** Deck on the projector, Jupyter on the laptop. Every demo slide names the
notebook file and the cell heading and carries the code, with a copy button, so you never
hunt through a notebook with your back to the room. A grey strip means there is a Dyad model
worth having open for that beat.

**Handout:** `handout.pdf`, published next to the deck — one slide per page, these notes
excluded.

**If a solve stalls in front of the room:** every notebook is committed with its outputs.
Scroll to the plot that is already there and keep talking. Do not debug live.
-->

---

## The ten notebooks

| # | Title | The point of it |
|---|---|---|
| <Link to="the-car">01</Link> | The car | the step test: read K, τ and θ off the car you built |
| <Link to="open-vs-closed-loop">02</Link> | Open vs closed loop | feedforward is right until the hill |
| <Link to="proportional">03</Link> | P | error shrinks with k but never reaches zero |
| <Link to="proportional-integral">04</Link> | PI | the integrator finds notebook 02's answer by itself |
| <Link to="pid">05</Link> | PID | three terms, three jobs: present, past, future |
| <Link to="windup">06</Link> | Windup | the hill the engine cannot climb |
| <Link to="derivative-and-noise">07</Link> | Derivative and noise | small noise, steep slope, ruined command |
| <Link to="tuning">08</Link> | Tuning | a gain set from one step test, without a model |
| <Link to="discretization">09</Link> | Discretization | the strobe light slows down |
| <Link to="wheel-and-slip">10</Link> | Wheel and slip | cruise control meets black ice |

<!--
**Say:** here is the whole lecture on one slide. Ten short steps. Each one is a notebook you
can re-run yourself afterwards — they are committed with their outputs, so they read even
without the modeling tools installed.

**Point at:** the column on the right. Rows 01, 03, 04, 05, 06, 08 are the ones we will
definitely do. The others are there if the room moves quickly.

**Cutting for time:** drop 10, then 07, then 09, then 02. Never cut from the middle of the
P → PI → PID → windup run; that sequence is one argument.
-->

---

## One diagram, and all of control theory hangs off it

![The general control diagram: a reference enters a comparator, the error goes to a controller which produces a control input u, u enters the system alongside a disturbance d, the system state x evolves, a sensor measures it producing a noisy measurement y, and y is fed back to the comparator.](/diagrams/00-control-loop.svg)

<!--
**Say:** this one picture is the map for the whole subject, and for the next ninety minutes.
Everything we build today is a change to one box in it.

**Walk it with your hand,** naming each signal:

- *r*, the reference — what we want. Somebody has to decide it; that is **planning**, and for
  us it is just "the driver set 110".
- *u*, the control input — what we deliberately do. Steering, brake, throttle.
- *d*, the disturbances — what acts on the system anyway, and never asked us.
- *x*, the state — what the system is actually doing.
- *y*, the measurement — what we can *see* it doing, which is not the same thing, because
  every sensor adds noise.

**Say:** and note the shape of the argument. Feedback means the sensor's noise gets fed into
the controller and therefore affects the true state. Noise in a feedback loop does not just
make the picture fuzzy — it moves the car.

**Ask the room:** which of these five do you have direct control over? *(Only u. Everything
else is either chosen by somebody else or done to you.)*

**Readout — every symbol on this slide**

- **r** — the *reference*, also called the setpoint or the command. What we want. Units of
  whatever we are controlling; here km/h.
- **e** — the *error*, r minus the measurement. Same units as r. Zero means we are where we
  asked to be.
- **u** — the *control input*, also called the actuating signal or plant input. What the
  controller chooses. Here, newton-metres of commanded engine torque.
- **d** — the *disturbances*. Inputs we do not choose and cannot command: the hill, the wind,
  the luggage.
- **x** — the *state*. What the system is actually doing, and what it remembers. Here, road
  speed, and how full the inlet manifold is.
- **y** — the *measurement*, also called the controlled variable or plant output. What the
  sensor reports, which is the state plus noise.
-->

---

## The car you built

<div class="grid grid-cols-2 gap-8">
<div>

| Step | Your `MyCar` | Course model |
|---|---|---|
| 02 | `Engine` | `Vehicle.IdealEngine` |
| 03 | `Driveline` | `Vehicle.Driveline` |
| 07 | `GradeBody` | `Vehicle.VehicleBody` |
| 05 | `Car` | `Vehicle.CarPlant` |
| 06 | `WheeledCar` | `Lecture1.WheeledCarPlant` |
| 10 | `SlipCar` | `Lecture1.SlipCarPlant` |

</div>
<div>

Same parts, same parameters. `CarPlant` adds a `grade` input, and names the 3.6 gain
`ToKmPerHour`. Both reach 246.39 km/h at 300 s.

> **What we know before any controller**
>
> The torque arrives late, slow and capped. Drag is quadratic. The tire has a peak.
> Every one of those comes back today as a control problem.

↩ [What we built in the hands-on](../handson-01/index.html#/what-we-build) ·
[hands-on page](../handson/lecture-01/index.html)

</div>
</div>

<!--
**Say:** you met this car in the hands-on — each part explained on paper car, and in Dyad,
built part by part. Today it is the plant, and it does not change.

**Point at:** the left column. Every row is a model they built, next to the course model the
notebooks run. They are the same components; the course versions live in `Vehicle/` so
lecture 2 can reuse them. The 1 kg·m² wheel and the slip wheel live in `Lecture1/` harnesses
that section 10 uses.

**Point at:** the callout, one phrase at a time, and name where each returns: the lags in the
step test and in tuning (sections 01 and 08), the square in the step test's θ (section 01),
the tire's peak on ice (section 10).

**Timing:** 2 minutes. If the room did not do the hands-on, spend 5 here and show
`dyad/Vehicle/CarPlant.dyad` open in Dyad — the force balance as a diagram — instead.

**Ask the room:** what did your car need that it did not have in step 05, before it could
climb a hill? *(A grade input — step 07. CarPlant has it, which is why every harness today
feeds it two signals.)*
-->

---

## Where the models live

#### Vehicle/ — the car

*Physical components. Lecture 2 uses these unchanged, which is the test for whether something
belongs here.*

- `IdealEngine.dyad` — delay, lag, torque limit
- `Driveline.dyad` — gear, wheel
- `VehicleBody.dyad` — mass, drag, rolling, grade
- `GradeForce.dyad` — the hill, as a force
- `Conversions.dyad` — ToKmPerHour — the one conversion
- `CarPlant.dyad` — all of the above, wired up
- `GradeProfile.dyad` — flat → climb → flat

#### Lecture1/ — what we do to it

*Controllers and scenario harnesses. A plant cannot run on its own: its inputs would be
unconnected, so every demo is a harness around `CarPlant`.*

- `WideOpenThrottle.dyad` → section 01
- `CarStepTest.dyad` → sections 01, 08
- `CruiseLoop.dyad` → sections 02–06, 08, 09

> **Each harness ships an analysis**
>
> `WideOpenThrottleTransient`, `CarStepTestTransient`, `CruiseLoopTransient` — the sources,
> the initial conditions and the run window live in the model, so a notebook cell is a run and
> a plot.

<!--
**This slide is the map for the whole lecture.** Leave it up while you say the rule, because
it is the thing students most often get wrong when they build their own:

**Say:** the car goes in one place and the experiment goes in another. If lecture 2 would use
it unchanged, it is a *Vehicle*. If it exists because of what we are teaching today — a step
source, a setpoint, a controller — it is a *Lecture1*. Moving a component between them later
breaks every reference to it, so the line gets drawn at the start.

**Say:** and notice why the harnesses exist at all. `CarPlant` has two inputs, torque and
grade. Leave them unconnected and the model is not solvable — it has more unknowns than
equations. So every single demo today is the same plant with something different plugged
into those two inputs.

**Ask the room:** where would a traffic-light sequence belong? A tyre pressure? *(The
sequence is a scenario — Lecture1. The pressure is the car — Vehicle.)*

**Practical:** when a slide carries a grey "open in Dyad" strip, that is the model to have on
the second screen for that beat. You do not need it open all the time — only where the
diagram says something the plot cannot.

**Terms, if anyone asks**

- **Component** — a Dyad block with ports, parameters and equations. `IdealEngine` is one.
- **Harness** — a component whose job is to make another one runnable, by connecting sources
  to its inputs and setting initial conditions.
- **Analysis** — a named, runnable experiment: a model plus a stop time plus the parameters
  you may vary. `CruiseLoopTransient` is one.
- **Structural parameter** — one that changes the *equations*, so each value is a separately
  compiled model. `with_I` is one; an ordinary parameter like `k` is not.
-->

---

## The car, once

<!-- theta_e is 0.3 s: at 0.04 s the Ziegler-Nichols
     demo in notebook 08 relay-limit-cycled against the torque limit instead of oscillating
     cleanly. The shipped models and CAR both carry 0.3 s; this table follows them. -->

<div class="grid grid-cols-2 gap-8">
<div>

| Parameter | | |
|---|---:|---|
| mass *m* | 1400 | kg |
| drag area *C<sub>d</sub>A* | 0.63 | m² |
| air density *ρ* | 1.2 | kg/m³ |
| rolling coefficient *f<sub>r</sub>* | 0.012 | — |
| wheel radius *r* | 0.31 | m |
| gear ratio *i* | 4.0 | — |
| torque limit *T*<sub>max</sub> | 150 | N·m |
| manifold lag *τ<sub>e</sub>* | 0.3 | s |
| transport delay *θ<sub>e</sub>* | 0.3 | s |

*Nine numbers. Everything else in this lecture is arithmetic on them.*

</div>
<div>

#### What follows from them

- **1935** N max tractive
- **246** km/h terminal
- **31.1** N·m to hold 90
- **40.1** N·m to hold 110

> **Every one of these was derived on paper**
>
> In [hands-on step 05](../handson-01/index.html#/top-speed), and checked by every student's model.
> The hill in notebook 06 defeats the engine because 2024 N &gt; 1935 N, and you can check
> that.

</div>
</div>

<!--
**Say:** the same nine numbers students typed into their own `Engine`, `Driveline` and
`Body`. Leave this slide up a moment: the right-hand column is what the lecture leans on —
31.1 and 40.1 N·m are the step test in section 01, and 1935 N is the ceiling the hill in
section 06 breaks.

**Ask the room:** which of these nine matters most for how hard this car is to control?
*(They heard the answer in hands-on step 02: the two lags at the bottom. Section 01's step
test is where they show up on a plot.)*

**On the transport delay:** 0.3 s is the whole powertrain torque-response path — ECU,
fuelling, combustion, driveline compliance — not injection alone. If someone objects that
injection is faster than that, they are right, and the model lumps more than injection into
this one number.

**Readout — every symbol on this slide**

- **m** = 1400 kg — vehicle mass.
- **C<sub>d</sub>A** = 0.63 m² — drag area: the drag coefficient times the frontal area, kept
  as one number because only the product matters.
- **ρ** = 1.2 kg/m³ — air density at sea level.
- **f_r** = 0.012 — rolling resistance coefficient, dimensionless. Tyre losses as a fraction
  of the normal load.
- **r** = 0.31 m — wheel rolling radius.
- **i** = 4.0 — total gear ratio, dimensionless. Engine turns four times per wheel turn.
- **T<sub>max</sub>** = 150 N·m — the engine's torque ceiling.
- **τ<sub>e</sub>** = 0.3 s — the manifold-filling lag: a first-order lag, how long the
  engine takes to build the torque it was asked for.
- **θ<sub>e</sub>** = 0.3 s — the powertrain transport delay: a pure dead time, how long
  before anything at all happens.
- **1935 N** — maximum tractive force, T<sub>max</sub>·i/r. **246 km/h** — terminal speed.
  **31 and 40 N·m** — torque to hold 90 and 110 km/h.
-->

---

## Two conventions, for the whole lecture

<div class="grid grid-cols-2 gap-8">
<div>

### The loop runs in km/h

Setpoint, measurement and error are all km/h. So every gain you see today has the same units
and means the same thing:

**k** is in **N·m per km/h**.

*"Five newton-metres for every km/h I am off." That is a sentence an engineer can
sanity-check; **k = 220** in mixed units is not.*

</div>
<div>

### SI inside, km/h at the sensor

The plant's internals are SI throughout. Exactly one conversion exists in the whole model, and
it is a visible block on the sensor output:

`Vehicle.ToKmPerHour`

*The `Gain(k = 3.6)` of hands-on step 05, under a name. No notebook ever multiplies a plotted
signal by 3.6: if a speed axis says km/h it is because the model emitted km/h.*

</div>
</div>

<!--
**Say:** two housekeeping rules, and then we start. Both exist so that a number on a plot
means one thing only.

**Why it matters:** the most common way a student's cruise controller "mysteriously"
misbehaves is a gain tuned against m/s driving a loop that measures km/h — a silent factor
of 3.6. Put the conversion in the model where you can see it, once.

**Ask the room:** if I tell you my gain is 220, what is missing? *(Units. Wait for it —
someone will say it.)*

**Readout — every symbol on this slide**

- **k** — the controller gain, N·m per km/h. "This many newton-metres for every km/h I am
  off."
- **km/h** — the unit of the setpoint, the measurement and therefore the error.
- **SI inside** — the plant computes in m/s, N, kg. One block, `ToKmPerHour`, converts, and it
  sits on the sensor output.
-->
