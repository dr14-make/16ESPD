---
routeAlias: front-matter
layout: cover
---

# Control Systems

<h1 class="!text-5xl !-mt-4 opacity-70">Introduction and PID</h1>

Vehicle Systems &amp; Components — Lecture 1

One car you built, one controller you build today, ten notebooks.

<div class="text-xs opacity-60 mt-12">

<kbd>→</kbd> <kbd>Space</kbd> next &nbsp;·&nbsp; <kbd>←</kbd> previous &nbsp;·&nbsp;
<kbd>O</kbd> overview &nbsp;·&nbsp; <kbd>G</kbd> go to slide &nbsp;·&nbsp;
presenter mode from the nav bar, bottom left

</div>

<!--
**Before the room fills.** Deck on the projector, Dyad Studio and the notebooks on the laptop.
Open **presenter mode** from the nav bar now (bottom left, it appears on hover): these notes, the
next slide and a timer in the same tab, no popup to block. In Studio, open the students'
hands-on package with `Car` and `GradeBody` in it — you build on it live, exactly as they do.

**Where this sits:** second of two sessions on one car. In the hands-on
(`slides/decks/handson-01/`) students learned each part's physics and built it. This deck does not
repeat that physics: wherever a slide relies on it, a gray *↩ Hands-on step NN* line links to
the exact slide. Section 01 opens with a recap of what they built; if a group skipped the
hands-on, they start from the reference `HandsOn.Car` and follow the recap.

**Say:** you built a car; today you build its cruise control, one block at a time, on that car.
The car never changes. Every new idea in this lecture is a change to the *controller*, never a
change of subject — so whatever you understand about the car at minute twenty is still true at
minute one hundred and seventy.

**Timing:** 184 minutes, students building along in Dyad Studio. Front matter 9 · 01 the car 22
· 02 open vs closed loop 15 · 03 P 15 · 04 PI 18 · 05 PID 18 · **break 10** · 06 windup 25 ·
07 derivative and noise 15 · 08 tuning 18 · 09 discretization 8 (demo only) · 10 wheel and
slip 11. Each section's first slide repeats its own budget in these notes.

**The build.** Every build step has one slide: a Studio screenshot, a one-line recipe, and a
`page: step NN` link to the guide page, `lecture/lecture-01/` on the course site — the same
site as the hands-on page. The notes on each build slide carry the full instructions: what to
drag in, which parameters, every wire, and what the plot must show before you move on. Switch
the projector to Studio, build it, run it, switch back.

**Catch-up.** Students who fall behind follow the guide page, which has every step with its
blocks, parameters, wires and expected plot. Two checkpoints let anyone rejoin with a working
model: **P** at the end of section 03 and **PID** at the end of section 05. The guide page has
both as code to paste; the reference is `CruiseLoop`, with `with_I = false, with_D = false` for
P, and with `with_I = true, with_D = true`, `Td = 0.5`, `wd = 0` for PID.

**Driving the deck.** **→** or **Space** next slide, **←** previous. **O** overview of
everything, **G** jump to a slide number, **F** fullscreen. Presenter mode, opened from the
nav bar (bottom left, on hover), is this window: these notes, the next slide and a timer.

**Three windows.** Deck on the projector, Dyad Studio for the build, Jupyter for the notebook
figures. Every demo slide names the notebook file and the cell heading and carries the code,
with a copy button, so you never hunt through a notebook with your back to the room. A gray
strip means there is a Dyad model worth having open for that beat.

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

**Say:** and you do not just watch these. From section 01 to section 10 you build the car's
cruise controller yourself, block by block, and every plot in the notebooks comes from a
diagram you have on your own screen. The one exception is 09, which is a demo.

**Point at:** rows 03 and 05. Those are the two checkpoints — P and PID. Fall behind and the
guide page gets you back on at either one.
-->

---

## What a system is

<div class="grid grid-cols-2 gap-8">
<div>

A set of interacting parts that forms one whole. Every system has:

- **structure** — parts, related directly or through each other
- **behavior** — processes that turn inputs into outputs: material, energy, data
- **interconnection** — the parts and processes are linked

Too big to understand at once? Split it into subsystems, and those into parts. You already did:
`Car` is `Engine`, `Driveline` and `Body`.

</div>
<div>

| Element | In your `Car` |
|---|---|
| Inputs and outputs | `tau_cmd` in, `v_kmh` out |
| Processor | engine, driveline, body |
| Control | the cruise controller, built today |
| Environment | the road grade, the air |
| Feedback | the speed sensor, back to the controller |
| Boundary and interface | the component's ports |

</div>
</div>

<!--
**Say:** before any control, what is the thing we control? A system is parts that interact and
together do something none of them does alone. The engine alone does not move; the body alone
does not accelerate. Together they are a car.

**Walk the left column** in one sentence each. Structure is the diagram; behavior is what the
simulation does with it; interconnection is the wires. The last line is the one that matters
for how we work: divide and conquer. Nobody models a car in one equation. You modeled an
engine, a driveline and a body, and connected them — that decomposition *is* the hands-on.

**Walk the table** top to bottom, pointing at their `Car` diagram if Studio is up. Two rows are
empty today and the lecture fills them: *control* is the controller we build from section 02
on, and *feedback* is the wire from `v_kmh` back into it. The *boundary* row is the one people
skip: the ports of a component are exactly where the system ends and its environment begins.
Whatever crosses a port is an input or an output; whatever does not is internal.

**Timing:** 2 minutes.
-->

---

## What a control system is

<div class="grid grid-cols-2 gap-8">
<div>

### Control system

A mechanism that changes the future behavior of a system, so that its output tends toward the
state we want.

### Control theory

The mathematics of choosing that input. Without it, the strategy is trial and error.

</div>
<div>

### The question, every time

- a **plant** — the system we are given: here, the car
- a **desired output** — here, 110 km/h
- **how do we change the input** to get it? Here, the torque command.

The rest of this lecture is answers to the third line. Whether the answer looks at the output
or not is <Link to="open-vs-closed-loop">section 02</Link>.

</div>
</div>

<!--
**Say:** a control system is the part we add so that the plant ends up where we want it, not
just where it happens to go. Control theory is how we pick the input on purpose instead of by
trying things. Trial and error does work — the first tuning method in section 08 is literally
"guess and check" — but it does not tell you why, and it does not tell you when it will stop
working.

**Point at the right column:** this is the shape of every control problem. Plant, desired
output, and the question of the input. Today the plant is fixed — the car they built — and the
desired output is a speed. Everything from section 02 on is a different answer to the third
line.

**Timing:** 1 minute.
-->

---

## Three kinds of control

| Kind | The reference | Example |
|---|---|---|
| **Fixed setpoint** | set once, held | cruise control at 110 km/h — **today** |
| **Follow-up** | moves, and nobody knows in advance how | adaptive cruise behind the car in front; automatic climate control |
| **Program** | moves along a schedule fixed in advance | central heating by time of day; a radar antenna's sweep |

The controller is the same in all three. Only where the reference comes from changes.

<!--
**Say:** controllers are often sorted by what their reference does. Fixed setpoint: the driver
sets 110 and the job is to hold it against hills and wind — that is our whole lecture.
Follow-up: the reference moves, driven by something else, and you cannot know its future —
adaptive cruise follows the car ahead, whatever it does. Program: the reference moves, but on a
timetable written beforehand — the heating that warms the house at six.

**Then say the last line.** The PID we build today does not care which of the three it is in;
it only ever sees the error. What changes is the job: holding a setpoint is mostly about
rejecting disturbances, following a moving reference is mostly about speed of response.

**Bridge:** open loop versus closed loop is the next distinction, and it gets a whole section —
02. The three names for a step response — transient, steady state, dynamic — come in section 01
on the car's own step test.

**Timing:** 1 minute.
-->

---

## One diagram, and all of control theory hangs off it

![The general control diagram: a reference enters a comparator, the error goes to a controller which produces a control input u, u enters the system alongside a disturbance d, the system state x evolves, a sensor measures it producing a noisy measurement y, and y is fed back to the comparator.](/diagrams/00-control-loop.svg)

<!--
**Say:** this one picture is the map for the whole subject, and for the next three hours.
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
  controller chooses. Here, newton-meters of commanded engine torque.
- **d** — the *disturbances*. Inputs we do not choose and cannot command: the hill, the wind,
  the luggage.
- **x** — the *state*. What the system is actually doing, and what it remembers. Here, road
  speed, and how full the inlet manifold is.
- **y** — the *measurement*, also called the controlled variable or plant output. What the
  sensor reports, which is the state plus noise.
-->

---

## Where the models live

<div class="grid grid-cols-2 gap-8">
<div>

#### HandsOn/ — the car, as you built it

*The plant. Today it gains a grade input and, later, a few parameters — never a new part.*

- `Engine`, `Driveline`, `Body`, `Car` — hands-on steps 02–05
- `GradeForce`, `GradeBody` — step 07, the hill
- `GradeCar` — `Car` on a road with a grade, **built today** in section 01
- `WheeledCar`, `SlipCar` — steps 06 and 10, back in section 10

</div>
<div>

#### Lecture1/ — what we do to it

*Controllers and scenario harnesses. A plant cannot run on its own: its inputs would be
unconnected, so every demo is a harness around `Car` or `GradeCar`.*

- `WideOpenThrottle`, `CarStepTest` → section 01
- `CruiseController` → **built today**, sections 02–06
- `CruiseLoop` → sections 02–06, 08

> **Each harness ships an analysis**
>
> `WideOpenThrottleTransient`, `CarStepTestTransient`, `CruiseLoopTransient` — the sources,
> the initial conditions and the run window live in the model, so a notebook cell is a run and
> a plot.

</div>
</div>

<!--
**This slide is the map for the whole lecture.** Leave it up while you say the rule, because
it is the thing students most often get wrong when they build their own:

**Say:** the car goes in one place and the experiment goes in another. If it is part of the
car, it is in *HandsOn*. If it exists because of what we are teaching today — a step source,
a setpoint, a controller — it is in *Lecture1*. Your own package follows the same split: the
`GradeCar` you build in section 01 sits next to your `Car`; the controller and the loop are
new components beside them.

**Say:** and notice why the harnesses exist at all. `GradeCar` has two inputs, torque and
grade. Leave them unconnected and the model is not solvable — it has more unknowns than
equations. So every single demo today is the same plant with something different plugged
into those two inputs.

**Ask the room:** where would a traffic-light sequence belong? A tire pressure? *(The
sequence is a scenario — Lecture1. The pressure is the car — HandsOn.)*

**On `Vehicle/`:** the course library for lectures 2 and 3. It carries the same parts block
for block, and today's notebooks no longer use it.

**Practical:** when a slide carries a gray "open in Dyad" strip, that is the reference model to
have on the second screen for that beat. The students' own diagram is the one on the projector
during a build.

**Terms, if anyone asks**

- **Component** — a Dyad block with ports, parameters and equations. `Engine` is one.
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
> The hill in notebook 06 defeats the engine because 2023 N &gt; 1935 N, and you can check
> that.

</div>
</div>

<!--
**Say:** the same nine numbers students typed into their own `Engine`, `Driveline` and
`Body`. Half a minute here — section 01's recap comes back to the ones control cares about.
The right-hand column is what the lecture leans on —
31.1 and 40.1 N·m are the step test in section 01, and 1935 N is the ceiling the hill in
section 06 breaks.

**Ask the room:** which of these nine matters most for how hard this car is to control?
*(They heard the answer in hands-on step 02: the two lags at the bottom. Section 01's step
test is where they show up on a plot.)*

**On the transport delay:** 0.3 s is the whole powertrain torque-response path — ECU,
fueling, combustion, driveline compliance — not injection alone. If someone objects that
injection is faster than that, they are right, and the model lumps more than injection into
this one number.

**Readout — every symbol on this slide**

- **m** = 1400 kg — vehicle mass.
- **C<sub>d</sub>A** = 0.63 m² — drag area: the drag coefficient times the frontal area, kept
  as one number because only the product matters.
- **ρ** = 1.2 kg/m³ — air density at sea level.
- **f_r** = 0.012 — rolling resistance coefficient, dimensionless. Tire losses as a fraction
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

*"Five newton-meters for every km/h I am off." That is a sentence an engineer can
sanity-check; **k = 220** in mixed units is not.*

</div>
<div>

### SI inside, km/h at the sensor

The plant's internals are SI throughout. Exactly one conversion exists in the whole model, and
it is a visible block on the sensor output:

`to_kmh` — `Gain(k = 3.6)`

*The block you put on `Car`'s sensor in hands-on step 05. No notebook ever multiplies a plotted
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

- **k** — the controller gain, N·m per km/h. "This many newton-meters for every km/h I am
  off."
- **km/h** — the unit of the setpoint, the measurement and therefore the error.
- **SI inside** — the plant computes in m/s, N, kg. One block, `to_kmh`, converts, and it
  sits on the sensor output.
-->
