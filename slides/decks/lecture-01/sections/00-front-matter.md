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
Welcome. This is the second of two sessions on one car. In the hands-on, you learned the
physics of each part of the car and you built it. Today I will not repeat that physics. Wherever
a slide relies on it, you will see a gray line that says "Hands-on step" and a number. It links
to the exact slide where you built that part.

Today you build cruise control for that car, one block at a time. The car does not change during
the lecture. Every new idea is a change to the **controller**. So what you learn about the car at
minute twenty still holds at minute one hundred and seventy.

Section 01 opens with a recap of what you built. If you skipped the hands-on, make your own
copy of the MyCar template on GitHub and follow that recap. The guide page links to it.

Every build step has one slide. It shows a Studio screenshot, a one-line recipe, and a link that
says "page: step" and a number. That link goes to the guide page, `lecture/lecture-01/` on the
course site, the same site as the hands-on page. I build every step live in Studio, exactly as
you do.

If you fall behind, follow the guide page. It has every step with its blocks, parameters, wires
and the plot you should see. Two checkpoints let anyone rejoin with a working model. The first
is P, at the end of section 03. The second is PID, at the end of section 05. The guide page has
both as code to paste. The course repository has them too, as `Lecture1.Step03` and
`Lecture1.Step05`.

Every demo slide names the notebook file and the cell heading, and it carries the code with a
copy button. A gray strip on a slide means there is a Dyad model worth having open at that
point.

The handout is `handout.pdf`, published next to the deck, with one slide per page.
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
This slide lists the whole lecture in ten short steps. Each one is a notebook you can re-run
yourself afterwards. They are committed with their outputs, so they read even without the
modeling tools installed.

You do not only watch these. From section 01 to section 10, you build the car's cruise
controller yourself, block by block. Every plot in the notebooks comes from a diagram you have
on your own screen. The one exception is 09, which is a demo.

Look at rows 03 and 05. Those are the two checkpoints, P and PID. If you fall behind, the guide
page gets you back on at either one.
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
First, what is the thing we control? A system is parts that interact and together
do something none of them does alone. The engine alone does not move. The body alone does not
accelerate. Together they are a car.

Look at the left column. Structure is the diagram. Behavior is what the simulation does with it.
Interconnection is the wires. The last line describes how we work: split the system into parts.
Nobody models a car in one equation. You modeled an engine, a driveline and a body, and connected
them. That is what the hands-on was.

Now the table, top to bottom, against your own `Car` diagram. Your `Car` has nothing in two of
the rows yet, and this lecture adds them. Control is the controller we build from section 02 on. Feedback is the wire
from `v_kmh` back into it. Do not skip the boundary row. The ports of a component are
exactly where the system ends and its environment begins. Whatever crosses a port is an input or
an output. Whatever does not is internal.
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
A control system is the part we add so that the plant ends up where we want it, not just where
it happens to go. Control theory is how we pick the input on purpose, instead of by trying
things. Trial and error does work. The first tuning method in section 08 is "guess and check".
But it does not tell you why it works, or when it will stop working.

Look at the right column. Every control problem has these three parts: a plant, a desired
output, and the question of the input. Today the plant is fixed. It is the car you built. The desired
output is a speed. Everything from section 02 on is a different answer to the third line.
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
Controllers are often sorted by what their reference does. Fixed setpoint: the driver sets 110,
and the job is to hold it against hills and wind. That is our whole lecture. Follow-up: the
reference moves, driven by something else, and you cannot know its future. Adaptive cruise
follows the car ahead, whatever that car does. Program: the reference moves, but on a timetable
written beforehand. The heating that warms the house at six.

The PID we build today does not care which of the three it is in. It only ever sees the error.
What changes is the job. Holding a setpoint is mostly about rejecting disturbances. Following a
moving reference is mostly about speed of response.

Open loop versus closed loop is the next distinction, and it gets a whole section, 02. The three
names for a step response, transient, steady state and dynamic, come in section 01, on the car's
own step test.
-->

---

## The feedback control loop

![The general control diagram: a reference enters a comparator, the error goes to a controller which produces a control input u, u enters the system alongside a disturbance d, the system state x evolves, a sensor measures it producing a noisy measurement y, and y is fed back to the comparator.](/diagrams/00-control-loop.svg)

<!--
We use this diagram for the next three hours. Everything we build today changes one box in it.

Here is each signal. r is the reference, what we want. Somebody has to decide it. That is
called **planning**, and for us it is just "the driver set 110". u is the control input, what we
deliberately do: steering, brake, throttle. d is the disturbances, what acts on the system
anyway and never asked us. x is the state, what the system is actually doing. And y is the
measurement, what we can **see** it doing. That is not the same thing, because every sensor adds
noise.

With feedback, the sensor noise enters the controller. So it changes the command, and the noise
moves the real car, not only the plotted measurement.

Of these five signals, we set only u directly. The others are chosen by somebody else or act on
the system from outside.

Each symbol has other names that you will meet in books. r, the reference,
is also called the setpoint or the command. Its units are whatever we are controlling, here km/h.
e is the error, r minus the measurement, in the same units as r. Zero means we are where we asked
to be. u, the control input, is also called the actuating signal or the plant input. It is what
the controller chooses. Here it is newton-meters of commanded engine torque. d, the disturbances,
are inputs we do not choose and cannot command: the hill, the wind, the luggage. x, the state, is
what the system is actually doing, and what it remembers. Here that is road speed, and how full
the inlet manifold is. y, the measurement, is also called the controlled variable or the plant
output. It is what the sensor reports, which is the state plus noise.
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
Control engineering covers the five tasks in this table, and each one belongs to a part of the
diagram you just saw.

Planning decides what we want, the reference. For a self-driving car, planning is a large subject: a
path to the destination that avoids obstacles, follows the rules of the road, and that the car
can physically drive. For us it is one number. The driver sets 110.

Control turns the reference into the input. Feedforward does it without looking at the result.
Feedback looks at the measurement and corrects. Today we build a feedback controller, PID.

State estimation sits between the sensor and the controller. The sensor gives us y, which
is noisy, and sometimes not even the quantity we need. Estimation turns it into our best guess of
the true state. A simple running average does that. So does a Kalman filter. In section 07 you
will meet the simplest one there is, a filter on the derivative.

Every other task needs a model. You can write a model from physics, from first
principles, the way you built the car in the hands-on. Or you can measure the real system and
fit a model to the data. That is called system identification, and the step test in section 01
is an example of it.

And analysis, simulation and test is how we check that the result works. Stability margins,
Bode and Nyquist plots, and simulation. Every run you do in Dyad today is this task.

As the last line on the slide says, the model is used everywhere: to
design the controller, to build the estimator, to make a plan the system can follow, and to
analyze the result. That is why the hands-on came first.

The table follows a short MathWorks video by Brian Douglas. The link is on the slide. It takes
about fifteen minutes.
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
There are many feedback algorithms. The left column sorts them into families. Linear controllers, like PID and full state feedback, assume the system behaves
roughly linearly. Nonlinear ones, like a simple on-off thermostat, sliding mode or gain
scheduling, do not. Robust controllers are designed to keep working when the model is wrong by a
known amount. Adaptive ones change themselves as the system changes. Optimal controllers, like
LQR, balance performance against effort by minimizing a cost. Predictive controllers run a model
of the system inside the controller and choose the input that makes the predicted future match
the reference. And intelligent controllers, like fuzzy logic or reinforcement learning, learn
from data.

Which one you pick depends on the system and on what you want it to do. Today we use PID, by far the
most common of them.

Before any of them, two questions. First, is the system controllable? Can our input actually move
the state we care about? For cruise control, torque moves the speed. Yes. Second, is it
observable? Can we work out every state we feed back from what we measure? We do not need a
sensor on every state. A speedometer alone also tells us acceleration, because acceleration is
the derivative of speed. So yes.

The last box is a warning that applies all afternoon. Feedforward changes how we operate a
system. Feedback changes its dynamics, that is, how it responds over time. So feedback can make
an unstable system stable, and it can also make a stable one unstable. We need feedback because
we never know the system and its environment exactly. We analyze a feedback loop before we trust
it.
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
This slide shows where each model lives. Students often get this split wrong in their own
packages.

The car goes in one place, and the experiment goes in another. If it is part of the car, it is in
`HandsOn`. If it exists because of what we are teaching today, a step source, a setpoint, a
controller, it is in `Lecture1`. Your `MyCar` has no folders, so everything sits side by side. The
`GradeCar` you build in section 01 sits next to your `Car`. The controller and the loop are new
components beside them. Keep the split in your head even so.

The harnesses exist because `GradeCar` has two inputs, torque and grade. Leave
them unconnected and the model is not solvable. It has more unknowns than equations. So every
demo today is the same plant, with something different plugged into those two inputs.

Where would a traffic-light sequence belong? And a tire pressure? The sequence is a scenario, so
it belongs in `Lecture1`. The pressure is the car, so it belongs in `HandsOn`.

You may also see a package called `Vehicle`. That is the course library for lectures 2 and 3. It
carries the same parts block for block, and today's notebooks no longer use it.

Some terms we use all day. A component is a Dyad block with ports, parameters and
equations. `Engine` is one. A harness is a component whose job is to make another one runnable,
by connecting sources to its inputs and setting initial conditions. An analysis is a named,
runnable experiment: a model plus a stop time plus the parameters you may vary.
`CruiseLoopTransient` is one. A structural parameter is one that changes the **equations**, so
each value is a separately compiled model. `theta_e`, the engine's delay, is one. An ordinary
parameter like `k` is not.
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
These are the same nine numbers you typed into your own `Engine`, `Driveline` and `Body`. Section
01's recap comes back to the ones control cares about. This lecture uses the right-hand
column. 31.1 and 40.1 newton-meters are the step test in section 01. And 1935 newtons is the
largest force the engine can deliver, which the hill in section 06 exceeds.

Of these nine, the two lags at the bottom matter most for how hard this car is to control, as
you saw in hands-on step 02. Section 01's step test shows them on a plot.

About the transport delay: 0.3 seconds is the whole powertrain torque-response path: the ECU,
fueling, combustion, and driveline compliance. Injection alone is faster than that. The model lumps
the whole path into this one number.

C d A, 0.63 square meters, is the drag coefficient times
the frontal area, kept as one number because only the product matters. The rolling coefficient,
0.012, is the tire losses as a fraction of the normal load. The gear ratio of 4.0 means the
engine turns four times per wheel turn. The manifold lag, tau e, 0.3 seconds, is a first-order
lag: how long the engine takes to build the torque it was asked for. The transport delay, theta
e, 0.3 seconds, is a pure delay, also called dead time: how long before the engine responds at all. And 1935 newtons
is T max times i over r, the maximum tractive force.
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
Two rules about units, so that a number on a plot has only one meaning.

A common cause of a misbehaving cruise controller is a gain tuned against meters per second, in
a loop that measures km/h. That is a silent factor
of 3.6. So we put the conversion in the model, where you can see it, once. It sits on the sensor
output, and everything inside the plant stays in meters per second, newtons and kilograms.

If I tell you my gain is 220, what is missing? The units. k is in newton-meters per km/h: this
many newton-meters for every km/h I am off.
-->
