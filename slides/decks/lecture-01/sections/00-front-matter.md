---
routeAlias: front-matter
layout: cover
---

# Control Systems

<h1 class="!text-5xl !-mt-4 opacity-70">Introduction and PID</h1>

Vehicle Systems &amp; Components — Lecture 1

Cruise control for the car you built, in ten notebooks.

<div class="text-xs opacity-60 mt-12">

<kbd>→</kbd> <kbd>Space</kbd> next &nbsp;·&nbsp; <kbd>←</kbd> previous &nbsp;·&nbsp;
<kbd>O</kbd> overview &nbsp;·&nbsp; <kbd>G</kbd> go to slide &nbsp;·&nbsp;
presenter mode from the nav bar, bottom left

</div>

<!--
Welcome. This is the second of two sessions on one car. In the hands-on you built it and learned its
physics. I will not repeat that physics today. Where a slide relies on it, a gray "Hands-on step"
line links to the slide where you built that part.

Today you build cruise control for that car, one block at a time. The car does not change. Every new
idea is a change to the **controller**.

If you skipped the hands-on, make your own copy of the MyCar template on GitHub. The guide page
links to it.

Every build step has one slide: a Studio screenshot, a one-line recipe, and a "page: step" link to
the guide page on the course site. I build every step live, as you do.

If you fall behind, follow the guide page. It has every block, parameter, wire and expected plot.
Two checkpoints let you rejoin with a working model: P at the end of section 03, and PID at the end
of section 05. The guide page has both as code to paste. The course repository has them as
`Lecture1.Step03` and `Lecture1.Step05`.

Demo slides name the notebook and the cell, with the code and a copy button. A gray strip means a
Dyad model worth having open.

The handout, `handout.pdf`, is published next to the deck, one slide per page.
-->

---

## The ten notebooks

| # | Title | What it shows |
|---|---|---|
| <Link to="the-car">01</Link> | The car | the step test: read K, τ and θ off the car you built |
| <Link to="open-vs-closed-loop">02</Link> | Open vs closed loop | feedforward holds the speed until the hill |
| <Link to="proportional">03</Link> | P | error shrinks with k but never reaches zero |
| <Link to="proportional-integral">04</Link> | PI | the integrator finds notebook 02's answer by itself |
| <Link to="pid">05</Link> | PID | P, I and D act on the present, past and future error |
| <Link to="windup">06</Link> | Windup | a hill steeper than the engine can climb |
| <Link to="derivative-and-noise">07</Link> | Derivative and noise | the derivative amplifies sensor noise |
| <Link to="tuning">08</Link> | Tuning | a gain set from one step test, without a model |
| <Link to="discretization">09</Link> | Discretization | the controller samples less and less often |
| <Link to="wheel-and-slip">10</Link> | Wheel and slip | cruise control on black ice |

<!--
These are the ten notebooks, one per section. Each is committed with its outputs, so you can read it
without the modeling tools installed.

You do not only watch. From section 01 to section 10 you build the cruise controller yourself, and
every plot comes from a diagram on your own screen. The exception is 09, a demo.

Rows 03 and 05 are the two checkpoints, P and PID.
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

<img src="/diagrams/00-car-chain.svg" class="mx-auto h-52" alt="The car as a chain of parts: the pedal command goes into the engine, the engine's shaft into the gear and wheel, the wheel pushes the body along the road, and a speedometer reads the body's speed in km/h.">

<!--
First, what do we control? A system is parts that interact and together do something none of them
does alone. The engine alone does not move. The body alone does not accelerate. Together they are a
car.

The last line of the left column is how we work: split the system into parts. You modeled an engine,
a driveline and a body, and connected them. That was the hands-on.

Now the table, against your own `Car` diagram. Two rows are still empty, and this lecture fills
them. Control is the controller we build from section 02 on. Feedback is the wire from `v_kmh` back
into it. Note the boundary row. A component's ports are where the system ends and its environment
begins. Whatever crosses a port is an input or an output. Everything else is internal.
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
A control system is the part we add so that the plant ends up where we want it. Control theory picks
the input on purpose instead of by trying things. Trial and error works: the first tuning method in
section 08 is "guess and check". It just does not tell you why it works, or when it will stop.

Every control problem has the three parts on the right. Today the plant is the car you built, and
the desired output is a speed. Everything from section 02 on is a different answer to the third
line.
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
Controllers are often sorted by what the reference does. Fixed setpoint: the driver sets 110, and
the job is to hold it against hills and wind. That is today. Follow-up: the reference moves and you
cannot know its future, like adaptive cruise following the car ahead. Program: the reference moves
on a timetable written beforehand, like heating that comes on at six.

The PID only ever sees the error, so it works in all three. What changes is the job. Holding a
setpoint is mostly rejecting disturbances. Following a moving reference is mostly speed of response.

Open versus closed loop gets its own section, 02. Transient, steady state and dynamic come in
section 01, on the car's step test.
-->

---

## The feedback control loop

![The general control diagram: a reference enters a comparator, the error goes to a controller which produces a control input u, u enters the system alongside a disturbance d, the system state x evolves, a sensor measures it producing a noisy measurement y, and y is fed back to the comparator.](/diagrams/00-control-loop.svg)

<!--
We use this diagram for the next three hours. Everything we build changes one box in it.

r is the reference, what we want. Deciding it is **planning**. For us that is the driver
setting 110. u is the control input, what we deliberately do: here, commanded engine torque in
newton-meters. d is the disturbances: the hill, the wind, the luggage. We do not choose them. x is
the state, what the system is actually doing and remembers: road speed, and how full the inlet
manifold is. y is the measurement, what we can **see**. It is the state plus sensor noise. e is the
error, r minus the measurement, in km/h. Zero means we are where we asked to be.

Of these, we set only u.

With feedback, sensor noise enters the controller. It changes the command, so the noise moves the
real car, not only the plotted line.

Books use other names. The reference is also the setpoint or the command. The control input is the
actuating signal or the plant input. The measurement is the controlled variable or the plant output.
-->

---

## Five tasks of control engineering

| Task | Where it sits on the diagram | Today |
|---|---|---|
| **Planning** | produces the reference r | the driver sets 110 km/h |
| **Control** — feedforward or feedback | turns r, and maybe y, into u | PID, built block by block |
| **State estimation** | turns the noisy y into an estimate of x | a derivative filter, in 07 |
| **Modeling** | first principles, or fitted to data: *system identification* | the hands-on car; the step test in 01 |
| **Analysis, simulation, test** | does the loop meet its requirements? | every run in Dyad |

Models feed all the others: the controller, the estimator, the plan and the analysis.

<div class="text-xs opacity-60 mt-6">

Reference: Brian Douglas, *Everything You Need to Know About Control Theory*, MathWorks Control
Systems in Practice — <a href="https://youtu.be/lBC1nEq0_nk" target="_blank">youtu.be/lBC1nEq0_nk</a>

</div>

<!--
Control engineering is these five tasks, each tied to a part of the diagram you just saw.

Planning decides the reference. For a self-driving car that is a big subject: a path that avoids
obstacles, follows the rules of the road, and that the car can drive. For us it is one number, 110.

Control turns the reference into the input. Feedforward does it without looking at the result.
Feedback looks at the measurement and corrects. Today we build a feedback controller, PID.

State estimation turns the noisy y into a best guess of the true state. A running average does that.
So does a Kalman filter. Section 07 has the simplest one there is, a filter on the derivative.

Every other task needs a model. You can write one from physics, as you did for the car in the
hands-on. Or you can measure the real system and fit a model to the data. That is system
identification, and the step test in section 01 is an example.

Analysis, simulation and test checks that the result works: stability margins, Bode and Nyquist
plots, simulation. Every Dyad run today is this task.

The model is used everywhere, which is why the hands-on came first.

The table follows a short MathWorks video by Brian Douglas, linked on the slide. It takes about
fifteen minutes.
-->

---

## Feedback controllers, controllability and observability

<div class="grid grid-cols-2 gap-8">
<div>

| Family | Examples |
|---|---|
| Linear | **PID** — today; full state feedback |
| Nonlinear | on-off, sliding mode, gain scheduling |
| Robust | μ-synthesis, active disturbance rejection |
| Adaptive | extremum seeking, model reference adaptive |
| Optimal | LQR |
| Predictive | model predictive control |
| Intelligent | fuzzy logic, reinforcement learning |

</div>
<div>

### Is it controllable?

Can the input actually move the state we care about? Torque moves the car's speed: yes.

### Is it observable?

Can we work out every state we feed back from what we measure? A speedometer alone also gives
acceleration, as its derivative: yes.

### Feedback can stabilize or destabilize

Feedforward changes how a system is operated. Feedback changes its dynamics, so it can make a
system more stable, or unstable.

</div>
</div>

<!--
The left column sorts feedback controllers into families. Linear ones, like PID, assume the system
behaves roughly linearly. Nonlinear ones, like an on-off thermostat, do not. Robust ones keep
working when the model is wrong by a known amount. Adaptive ones change as the system changes.
Optimal ones, like LQR, trade performance against effort by minimizing a cost. Predictive ones run a
model inside the controller and choose the input whose predicted future matches the reference.
Intelligent ones, like fuzzy logic or reinforcement learning, learn from data.

Today we use PID, by far the most common.

Before any of them, two questions. Is the system controllable: can our input move the state we care
about? Torque moves the speed, so yes. Is it observable: can we work out every state we feed back
from what we measure? A speedometer also gives acceleration, as its derivative, so yes.

The last box applies all afternoon. Feedforward changes how we operate a system. Feedback changes
its dynamics, how it responds over time. So feedback can make an unstable system stable, and a
stable one unstable. We need it because we never know the system exactly, so we analyze a loop
before we trust it.
-->

---

## Where the models live

<div class="grid grid-cols-2 gap-8">
<div>

#### HandsOn/ — the car, as you built it

*The plant. Today it gains a grade input and, later, a few parameters, but never a new part.*

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
The car goes in one place and the experiment in another. Part of the car: `HandsOn`. There because
of what we teach today, like a step source, a setpoint or a controller: `Lecture1`. Your `MyCar` has
no folders, so everything sits side by side, but keep the split in your head. Your `GradeCar` from
section 01 sits next to your `Car`, and the controller and the loop are new components beside them.

The harnesses exist because `GradeCar` has two inputs, torque and grade. Unconnected, the model has
more unknowns than equations and will not solve. So every demo today is the same plant with
something different plugged into those two inputs.

A quick check. A traffic-light sequence is a scenario, so `Lecture1`. A tire pressure is the car, so
`HandsOn`.

You may see a package called `Vehicle`. It is the course library for lectures 2 and 3. Today's
notebooks do not use it.

Four terms for today. A component is a Dyad block with ports, parameters and equations, like
`Engine`. A harness makes another component runnable: sources on its inputs, and initial conditions.
An analysis is a named, runnable experiment: a model, a stop time, and the parameters you may vary,
like `CruiseLoopTransient`. A structural parameter changes the **equations**, so each value is a
separately compiled model. `theta_e`, the engine's delay, is one. An ordinary parameter like `k` is
not.
-->

---

## The car's parameters

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

*Every car quantity in this lecture is calculated from these nine numbers.*

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
> The hill in notebook 06 is too steep for the engine because 2023 N &gt; 1935 N.

</div>
</div>

<!--
These are the nine numbers you typed into your own `Engine`, `Driveline` and `Body`. Three come back
as control problems: the 150 newton-meter ceiling in section 06, the 0.3 second delay and lag in
section 08's tuning, and the delay again in section 09's sampling.

The right-hand column follows from them. 31.1 newton-meters holds 90 km/h, and every loop today
starts there, already cruising. 31.1 and 40.1 are the step test in section 01. 1935 newtons, T max
times i over r, is the most the engine can push. The hill in section 06 needs more.

The two lags at the bottom matter most for how hard this car is to control, as you saw in hands-on
step 02. The transport delay, theta e, is a pure delay: how long before the engine responds at all.
It lumps the whole torque path into one number: the ECU, fueling, combustion and driveline
compliance. The manifold lag, tau e, is first order: how long the engine takes to build the torque
it was asked for. Section 01's step test shows both on a plot.

C d A is the drag coefficient times the frontal area, kept as one number because only the product
matters.
-->

---

## Units in this lecture

<div class="grid grid-cols-2 gap-8">
<div>

### The loop runs in km/h

Setpoint, measurement and error are all km/h. So every gain you see today has the same units
and means the same thing:

**k** is in **N·m per km/h**.

*"Five newton-meters for every km/h of error" can be checked against the car; **k = 220** in
mixed units cannot.*

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
Two rules about units, so a number on a plot has one meaning.

A common cruise-control bug is a gain tuned in meters per second, in a loop that measures km/h: a
silent factor of 3.6. So the conversion sits in the model, once, on the sensor output. Inside the
plant everything stays in meters per second, newtons and kilograms.

If I tell you my gain is 220, what is missing? The units. k is in newton-meters per km/h:
newton-meters of torque for every km/h of error.
-->
