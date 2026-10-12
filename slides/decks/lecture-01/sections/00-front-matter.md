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
(Run sheet: docs/lecture-01-run-sheet.md.)

Welcome. This is the second of two sessions on one car. In the hands-on, you learned the
physics of each part of the car and you built it. Today I will not repeat that physics. Wherever
a slide relies on it, you will see a gray line that says "Hands-on step" and a number. It links
to the exact slide where you built that part.

You built a car. Today you build its cruise control, one block at a time, on that same car. The
car never changes. Every new idea in this lecture is a change to the **controller**, never a
change of subject. So whatever you understand about the car at minute twenty is still true at
minute one hundred and seventy.

Section 01 opens with a recap of what you built. If you skipped the hands-on, start from the
reference `HandsOn.Car` and follow that recap.

Every build step has one slide. It shows a Studio screenshot, a one-line recipe, and a link that
says "page: step" and a number. That link goes to the guide page, `lecture/lecture-01/` on the
course site, the same site as the hands-on page. I build every step live in Studio, exactly as
you do.

If you fall behind, follow the guide page. It has every step with its blocks, parameters, wires
and the plot you should see. Two checkpoints let anyone rejoin with a working model. The first
is P, at the end of section 03. The second is PID, at the end of section 05. The guide page has
both as code to paste. The reference model is `CruiseLoop`. For P, set `with_I` to false and
`with_D` to false. For PID, set `with_I` to true and `with_D` to true, `Td` to 0.5, and `wd` to
0.

Every demo slide names the notebook file and the cell heading, and it carries the code with a
copy button. A gray strip on a slide means there is a Dyad model worth having open at that
point.

The handout is `handout.pdf`, published next to the deck, with one slide per page.
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
Here is the whole lecture on one slide. Ten short steps. Each one is a notebook you can re-run
yourself afterwards. They are committed with their outputs, so they read even without the
modeling tools installed.

And you do not just watch these. From section 01 to section 10, you build the car's cruise
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
Before any control: what is the thing we control? A system is parts that interact and together
do something none of them does alone. The engine alone does not move. The body alone does not
accelerate. Together they are a car.

Look at the left column. Structure is the diagram. Behavior is what the simulation does with it.
Interconnection is the wires. The last line is the one that matters for how we work: divide and
conquer. Nobody models a car in one equation. You modeled an engine, a driveline and a body, and
connected them. That decomposition **is** the hands-on.

Now the table, top to bottom, against your own `Car` diagram. Two rows are empty today, and this
lecture fills them. Control is the controller we build from section 02 on. Feedback is the wire
from `v_kmh` back into it. The boundary row is the one people skip. The ports of a component are
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
things. Trial and error does work. The first tuning method in section 08 is literally "guess and
check". But it does not tell you why, and it does not tell you when it will stop working.

Look at the right column. This is the shape of every control problem: a plant, a desired output,
and the question of the input. Today the plant is fixed. It is the car you built. The desired
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
One boolean changes between the last notebook and this one. `with_I = true`. Same car, same
gain, same step. In your diagram it is three blocks.
=====
Proportional is the present. Integral is the past. That is not a slogan. It is literally what
the two expressions compute.

If the error has been zero for a while, what is the integral path putting out? Whatever it
accumulated before. Not zero. Many of you will want to say zero, and the next two slides show
why it is not.

The integral keeps a running total of the error, in km/h times seconds. T i is the integral
time, in seconds. It is a **time**, not a gain, and it divides. So a smaller T i integrates
harder. This catches people out every single year. The gain k multiplies the whole bracket, so
it scales every path together. And the tau inside the integral is just the variable of
integration. It is not the plant's time constant. Unfortunate collision of names.

In the reference model, `with_I` is a structural parameter of `CruiseController`. The
integrator is either compiled into the equations or it is not there at all, and a block called
`zero_i` holds its slot when it is out. So P and PI are two different models, not one model
with a gain at zero. On the next slide you get the same effect by hand: you add the block.
=====
The formula has a bracket: the error, plus the integral over T i, all times k. So the diagram
gets a summing block in front of the gain, with three inputs, one for each term the finished
controller will have. Today two of them: the error, and its integral. The third slot waits for
section 05.

Let's build it together. Open `CruiseController`.

First, add two parameters. `Ti`, of type `Time`, default 10 seconds. And `xi0`, default 0.
That is the integrator's starting state.

Now delete the wire from `error.y` to `gain.u`.

Drag in an Add3 block from `BlockComponents.Math` and name it `add_pid`. Set k one, k two and k
three all to 1. Wire `error.y` into `add_pid.u1`, and `add_pid.y` into `gain.u`.

Next, drag in an Integrator from `BlockComponents.Continuous` and name it `integrator`. Set k to
1 over `Ti`, and x zero to `xi0`. Wire `error.y` into `integrator.u`, and `integrator.y` into
`add_pid.u3`.

Then drag in a Constant from `BlockComponents.Sources`, name it `zero_d`, and set k to 0. Wire
`zero_d.y` into `add_pid.u2`. It holds the derivative's slot, so `add_pid` has all three
inputs.

Save. Go back to `CruiseLoopStep` and run `CruiseLoopTransient` again. The analysis picks up
the changed controller.

Plot `plant.v_kmh` and `demand.y`. On a second axis, plot `controller.integrator.y`.

You should see the speed reach **110 km/h**. The 0.7 km/h gap from step 3 is gone. And you
should see the integrator state rise and level off near **0.716**. That is 40.1 newton-meters
divided by k equals 56. On the punchline slide we multiply it back.

Your engine still clips at 150 newton-meters, and the notebook figures do not. So the first
seconds of your climb, and any overshoot, can differ from the notebook's. The settled 110 and
0.716 are the same.

Two mistakes are common. The first is feeding the integrator from `add_pid.y` instead of
`error.y`. Then it integrates its own output as well as the error. The second is setting k to
`Ti` instead of 1 over `Ti`. Then a bigger T i integrates **harder**, the opposite of the
convention.
=====
Look at the place where the two curves separate. Not at the step, but afterwards, in the slow
part. The proportional path has already given up there, because its error is nearly zero. The
integral path is still working, because its input is still not zero.

Both runs use the same gain, k equals 56 newton-meters per km/h. The PI run has T i equals 10
seconds. Each run lasts 60 seconds, and the torque ceiling is lifted to one times ten to the
six, which stands in for no limit at all. The signal we plot is the plant's km/h output, inside
the loop, inside the harness.

The two terms do different jobs at different times. Proportional does the transient. Integral
does the last stretch. Watch for that division of labor again in the next section, where we
plot it directly.

Which one reached the setpoint faster, to within, say, 1 km/h? Usually P. Arriving eventually
and arriving exactly are different requirements, and PID tuning is mostly about trading one
for the other.
=====
This is the slide. Let's take it slowly.

Look at the dashed line first. Where did it come from? We solved the force balance at 110 km/h
with a pencil, back in hands-on step 05, and got 40 newton-meters.

Now look at the curve arriving at it. Nobody gave the controller the mass. Or the drag area.
Or the gear ratio. It has never seen the model. It has seen one number, how far off it was,
and by accumulating that it has **inverted the plant**.

The numbers agree. The integrator times k settles at 40.122 newton-meters at the end of the
run. The force balance gives 40.119. That is the same number to within 0.003 newton-meters.
The dashed line is drawn on so you can see the coincidence, not just take my word for it. The
run is 90 seconds long, longer than the step needs, because the last hundredths of a
newton-meter take most of a minute.

That is what "an integrator removes steady-state error" actually means. It is not a magic
property of the formula. The integrator can hold an output that the error no longer
justifies, and it will keep hunting until it holds exactly the right one.

What happens to that line if I put 200 kg of luggage in the trunk? It moves up, and the
integrator finds the new value without being told. That is the argument for feedback in one
sentence.

The integrator is inside `CruiseController`. It is the block you just placed. Its output,
`integrator.y`, is its state before the gain. The plot multiplies by k to get newton-meters.
The second axis from your own build shows the same curve, unscaled.

If your integrator settles anywhere other than the hand-computed torque, then the units or the
gear ratio disagree between your model and the notebook. That mismatch is worth finding, so
stop and find it.
=====
Look at the first curve that crosses the setpoint and comes back. That crossing is new. The
proportional controller never did it, at any gain.

We sweep T i through 40, 20, 10, 5 and 2.5 seconds, from lazy to aggressive. Every one of
these settles at 110. The integrator guarantees that. The sweep is about the journey, not the
destination.

Here is the explanation to remember. By the time the car reaches 110, the integrator has been
accumulating error for the whole climb. So it is already holding **more** torque than 110 km/h
needs. The only way to get rid of that excess is to generate error with the opposite sign. That
means spending time on the far side of the setpoint. The overshoot is not a flaw in the tuning.
It is how an integrator unwinds.

Overshoot is the peak excursion past the setpoint, as a percentage of the step. A 20 km/h step
that overshoots to 112 is 10 percent. The notebook prints the overshoot for each T i. Watch it
grow as T i shrinks.

So what could we add that reacts **before** we arrive, rather than after? Something that
watches how fast we are closing. That is section 05.
=====
One warning before we move on. An integrator that has accumulated more than the actuator can
deliver is a much worse problem than overshoot. That is section 06, and it is the one that
breaks real vehicles.
-->

---

## One diagram, and all of control theory hangs off it

![The general control diagram: a reference enters a comparator, the error goes to a controller which produces a control input u, u enters the system alongside a disturbance d, the system state x evolves, a sensor measures it producing a noisy measurement y, and y is fed back to the comparator.](/diagrams/00-control-loop.svg)

<!--
This one picture is the map for the whole subject, and for the next three hours. Everything we
build today is a change to one box in it.

Let me name each signal. r is the reference, what we want. Somebody has to decide it. That is
called **planning**, and for us it is just "the driver set 110". u is the control input, what we
deliberately do: steering, brake, throttle. d is the disturbances, what acts on the system
anyway and never asked us. x is the state, what the system is actually doing. And y is the
measurement, what we can **see** it doing. That is not the same thing, because every sensor adds
noise.

Now note the shape of the argument. Feedback means the sensor's noise gets fed into the
controller, and therefore it affects the true state. Noise in a feedback loop does not just make
the picture fuzzy. It moves the car.

Which of these five can you control directly? Only u. Everything else is either chosen by
somebody else or done to you.

Let me give each symbol its other names, because you will meet them in books. r, the reference,
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
This slide is the map for the whole lecture. And it is the rule people most often get wrong when
they build their own.

The car goes in one place, and the experiment goes in another. If it is part of the car, it is in
`HandsOn`. If it exists because of what we are teaching today, a step source, a setpoint, a
controller, it is in `Lecture1`. Your own package follows the same split. The `GradeCar` you build
in section 01 sits next to your `Car`. The controller and the loop are new components beside
them.

And notice why the harnesses exist at all. `GradeCar` has two inputs, torque and grade. Leave
them unconnected and the model is not solvable. It has more unknowns than equations. So every
single demo today is the same plant, with something different plugged into those two inputs.

Where would a traffic-light sequence belong? And a tire pressure? The sequence is a scenario, so
it belongs in `Lecture1`. The pressure is the car, so it belongs in `HandsOn`.

You may also see a package called `Vehicle`. That is the course library for lectures 2 and 3. It
carries the same parts block for block, and today's notebooks no longer use it.

A few words you will hear all day. A component is a Dyad block with ports, parameters and
equations. `Engine` is one. A harness is a component whose job is to make another one runnable,
by connecting sources to its inputs and setting initial conditions. An analysis is a named,
runnable experiment: a model plus a stop time plus the parameters you may vary.
`CruiseLoopTransient` is one. A structural parameter is one that changes the **equations**, so
each value is a separately compiled model. `with_I` is one. An ordinary parameter like `k` is
not.
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
These are the same nine numbers you typed into your own `Engine`, `Driveline` and `Body`. Section
01's recap comes back to the ones control cares about. The right-hand column is what this lecture
leans on. 31.1 and 40.1 newton-meters are the step test in section 01. And 1935 newtons is the
ceiling that the hill in section 06 breaks.

Which of these nine matters most for how hard this car is to control? You heard the answer in
hands-on step 02: the two lags at the bottom. Section 01's step test is where they show up on a
plot.

A word on the transport delay. 0.3 seconds is the whole powertrain torque-response path: the ECU,
fueling, combustion, and driveline compliance. It is not injection alone. If you think injection
is faster than that, you are right. The model lumps more than injection into this one number.

A few of these deserve a sentence each. C d A, 0.63 square meters, is the drag coefficient times
the frontal area, kept as one number because only the product matters. The rolling coefficient,
0.012, is the tire losses as a fraction of the normal load. The gear ratio of 4.0 means the
engine turns four times per wheel turn. The manifold lag, tau e, 0.3 seconds, is a first-order
lag: how long the engine takes to build the torque it was asked for. The transport delay, theta
e, 0.3 seconds, is a pure dead time: how long before anything at all happens. And 1935 newtons
is T max times i over r, the maximum tractive force.
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
Two housekeeping rules, and then we start. Both exist so that a number on a plot means one thing
only.

Here is why it matters. The most common way a cruise controller "mysteriously" misbehaves is a
gain tuned against meters per second, driving a loop that measures km/h. That is a silent factor
of 3.6. So we put the conversion in the model, where you can see it, once. It sits on the sensor
output, and everything inside the plant stays in meters per second, newtons and kilograms.

If I tell you my gain is 220, what is missing? The units. k is in newton-meters per km/h: this
many newton-meters for every km/h I am off.
-->
