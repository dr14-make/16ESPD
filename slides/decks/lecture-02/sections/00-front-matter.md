---
routeAlias: front-matter
layout: cover
---

# Engine Control Systems

<h1 class="!text-5xl !-mt-4 opacity-70">The engine and its control unit</h1>

Vehicle Systems &amp; Components — Lecture 2

An engine control unit is a stack of control loops wrapped around one nonlinear plant.

<div class="text-xs opacity-60 mt-12">

<kbd>→</kbd> <kbd>Space</kbd> next &nbsp;·&nbsp; <kbd>←</kbd> previous &nbsp;·&nbsp;
<kbd>O</kbd> overview &nbsp;·&nbsp; <kbd>G</kbd> go to slide &nbsp;·&nbsp;
presenter mode from the nav bar, bottom left

</div>

<!--
Welcome back. Last time the engine was one block. Today we open it.

The sentence on this slide is the whole lecture: an engine control unit is a stack of control loops
wrapped around one nonlinear plant. The plant is the engine. The loops are fuel, spark, idle and
lambda. Every section today adds a piece of one or the other.

This is the theory half. In the hands-on you build a mapped engine with a manifold pressure, put it
in the car, and read off fuel consumption and CO2. The last section shows what that engine is.

The handout, `handout.pdf`, is published next to the deck, one slide per page.
-->

---
routeAlias: from-lecture-1
---

## Where Lecture 1 left the engine

<div class="grid grid-cols-2 gap-8">
<div>

In Lecture 1 the engine was `Vehicle.IdealEngine`: a torque command, a **0.3 s transport delay**,
a **0.3 s first-order lag**, and a cap at **150 N·m**.

$$
T_e(s) \;=\; \frac{e^{-\theta s}}{\tau s + 1}\,T_{\text{cmd}}(s)
$$

That was enough to tune a cruise controller. It hides three questions:

- Where does the delay come from? *(fuel injection, combustion)*
- Where does the lag come from? *(the intake manifold filling)*
- Why would they change with speed and load? *(the engine is nonlinear)*

</div>
<div>

> **This lecture opens the block**
>
> The engine is the plant. Sensors measure it, the ECU computes from maps and loops, and
> actuators (injectors, ignition coils, throttle) act on it.
>
> The control loops sit on top: fuel metering, injection timing, spark advance, idle speed, and the
> lambda loop that keeps the catalyst working.

</div>
</div>

<!--
Recall the engine you used for cruise control. A command went in, nothing happened for 0.3 seconds,
then the torque rose with a 0.3 second time constant to whatever you asked for, up to 150 newton
meters.

The docstring of that block says the delay stands for injection-to-torque and the lag for manifold
filling. Today we see what those words mean. And the end of Lecture 1 promised one more thing: the
246 kilometers per hour top speed was too high, because a real engine's torque depends on speed.
The mapped engine in the hands-on fixes that.
-->

---

## The sections

| # | Section | What it covers |
|---|---|---|
| <Link to="vehicle-energy">01</Link> | Vehicle energy | where the engine's work goes: drag, rolling, slope, acceleration, auxiliaries |
| <Link to="engine-and-cycles">02</Link> | Engine and cycles | engine types, the Otto and Diesel cycles, the stoichiometric mixture |
| <Link to="engine-control-system">03</Link> | Engine control system | sensors, ECU, actuators; functions, subsystems, control strategies |
| <Link to="sensors">04</Link> | Sensors | classification, throttle position, temperature, air mass flow |
| <Link to="fuel-injection">05</Link> | Fuel injection | single-point, multipoint and direct injection; the injector; pulse width |
| <Link to="ignition">06</Link> | Ignition | timing and advance, spark plug, coil, dwell, distributor to coil-on-plug |
| <Link to="emissions-and-lambda">07</Link> | Emissions and lambda control | evaporative emissions, the λ loop, the oxygen sensor, the catalyst |
| <Link to="mapped-engine">08</Link> | The mapped engine | what you build in the hands-on |

<!--
Eight sections. The first two are the physics: where the energy goes and how the engine makes it.
Sections 03 to 07 are the control system, from the outside in: the whole system, then its sensors,
then the two main actuators, fuel and spark, then the emissions loop that closes around both.

Section 08 is the bridge to the hands-on.
-->
