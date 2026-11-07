---
routeAlias: front-matter
layout: cover
---

# Hybrids

<h1 class="!text-5xl !-mt-4 opacity-70">Engine, clutch, machine, energy manager</h1>

Vehicle Systems &amp; Components — Lecture 5

A hybrid saves fuel by moving the engine's operating point (the speed and torque it runs at), and
the clutch decides how far it can move it.

<div class="text-xs opacity-60 mt-12">

<kbd>→</kbd> <kbd>Space</kbd> next &nbsp;·&nbsp; <kbd>←</kbd> previous &nbsp;·&nbsp;
<kbd>O</kbd> overview &nbsp;·&nbsp; <kbd>G</kbd> go to slide &nbsp;·&nbsp;
presenter mode from the nav bar, bottom left

</div>

<!--
Welcome to Lecture 5, hybrids. A hybrid car has two power sources: a petrol engine and an
electric machine with a battery. The subtitle names the four things we put together today: Lecture
2's engine, a clutch, Lecture 4's electric machine, and an energy manager, the controller that
decides which of them drives.

The sentence on the slide is the whole lecture. The engine's operating point is the speed and the
torque it runs at, at one moment. A hybrid saves fuel by moving that point: it runs the engine
where it burns little fuel for each kilowatt-hour of work, or it switches the engine off. And the
clutch decides how far it can move it. An electric machine that can be cut loose from the engine
can drive the car alone, and it can brake the car without dragging the engine along. That matters
more than how strong the machine is.

You build one hybrid today, called a P2. The P is for position: where the machine sits in the
driveline. Section 04 explains the names. You build it on Lecture 4's planar car, the car model
with four wheels on a flat road. Then I move its machine to every other position and show the table
the theory predicts.

The material follows the course's deck on electric vehicles and electric machines, its slides on
series and parallel hybrids, the degree of hybridization, the P0 to P4 positions and the
controller. The fuel cell, which is a series hybrid with a different source, is in the extra pack,
the optional slides after this lecture.

The small line at the bottom is for browsing the deck yourself: arrows and space move, O opens the
overview, G jumps to a slide.
-->

---
routeAlias: from-lectures-2-and-4
---

## Where Lectures 2 and 4 left the car

<div class="grid grid-cols-2 gap-8">
<div>

### Lecture 2: the engine car

The engine model, built from measured maps, with a CVT drove the WLTC on **5.22 L/100 km**:
**168.8 MJ/100 km** of petrol. Every stop idled the engine, and every brake burned what the engine
had made.

</div>
<div>

### Lecture 4: the battery-electric car

The Leaf-sized planar car drove the same cycle on **131.2 Wh/km** at the battery terminals:
**47.2 MJ/100 km**, with about a quarter of the driving energy coming back through regen.

</div>
</div>

<div class="handson">Today: Lecture 2's engine, a disconnect clutch, Lecture 4's machine shrunk to
about 30 kW and a battery of about 1.4 kWh, on Lecture 4's planar car and the same WLTC. So three
powertrains meet on one car and one cycle.</div>

<div class="caption text-left">WLTC: the standard 30-minute test drive, in four phases from Low to
Extra High speed · CVT: a gearbox whose ratio changes smoothly · MJ/100 km: energy per 100 km, one
unit for petrol and electricity · regen: the machine brakes as a generator and charges the battery
· K0: the clutch between the engine and the rest</div>

<!--
Let us recall the two cars we already have. First, four words from the line at the bottom of the
slide. The WLTC is the standard test drive for fuel consumption: about 30 minutes, in four phases,
Low, Medium, High and Extra High speed. A CVT is a continuously variable transmission: a gearbox
whose ratio changes smoothly instead of in steps. Megajoules per 100 kilometers is energy per
distance; it lets us compare a petrol car and an electric car in one unit. And regen, regenerative
braking, means the electric machine brakes the car as a generator and charges the battery.

On the left, Lecture 2's car: the engine model built from the engine's measured maps, with the CVT.
On the WLTC it burned 5.22 liters of petrol per 100 kilometers, which is 168.8 megajoules per 100
kilometers. That is the number from Lecture 4's opening slide, and it is still what the current
model gives. Two things in that run are pure waste: the engine idles at every stop, and every time
the car brakes, the energy the engine put into its speed goes into the brake discs as heat.

On the right, Lecture 4's battery-electric car on the planar car model. At the battery terminals it
used 131.2 watt-hours per kilometer, 47.2 megajoules per 100 kilometers, and 24 percent of the
driving energy came back through regen. Those are the numbers from Lecture 4's wrap-up.

The green box says what we do today. We keep the engine from Lecture 2 and add a disconnect clutch.
We call it K0: the clutch that can cut the engine off from the rest of the car. We take the machine
from Lecture 4 but sized at about 30 kilowatts, and a battery of about 1.4 kilowatt-hours. Those sizes come from a real car: the 2011 Hyundai Sonata Hybrid that Oak Ridge
National Laboratory benchmarked had a 30 kilowatt machine behind an engine clutch and a 1.4
kilowatt-hour, 270 volt pack. It all goes on Lecture 4's planar car and drives the same cycle, so at
the end of the day we can put the conventional car, the hybrid and the electric car side by side.
-->

---

## The sections

| # | Section | What it covers | You build |
|---|---|---|---|
| <Link to="why-hybridize">01</Link> | Why hybridize | where Lecture 2's engine spends the WLTC, the three savings | |
| <Link to="series-and-parallel">02</Link> | Series and parallel | series, parallel, series-parallel with a clutch; other types; the series homework | |
| <Link to="degree-of-hybridization">03</Link> | Degree of hybridization | the electric share of the power, micro to plug-in, cost | |
| <Link to="p-positions">04</Link> | P0 to P4 | where the machine sits, and why the clutch decides | 01 the P2 powertrain |
| <Link to="operating-point">05</Link> | Moving the operating point | the engine's most efficient speeds, the CVT, power split | 02 the operating line |
| <Link to="energy-management">06</Link> | Energy management | driving modes, a battery charge window, ending with the charge we started with, an optimizer | 03 the energy manager |
| <Link to="results">07</Link> | Results | WLTC three ways, the five positions against published studies | 04 the WLTC, charge-sustaining |
| <Link to="wrap-up">08</Link> | Wrap-up | what you measured, what the model leaves out | |

<!--
Here is the plan for today: seven sections and a wrap-up. The first column links to each section,
the last says what you build at its end.

Section 01 asks why we hybridize at all: where Lecture 2's engine spends the WLTC on its fuel map,
and the three ways a hybrid saves fuel. Section 02 is the layouts: series, parallel, and
series-parallel with a clutch, and a slide on the other kinds of hybrid; the series hybrid comes
back as your homework. Section 03 is the degree of hybridization: the electric machine's power
divided by the total power of machine and engine. It runs from a micro hybrid that only stops the
engine to a plug-in, and we look at what it costs. Section 04 is the five positions a parallel
hybrid's machine can take, P0 to P4, and the argument that the clutch matters more than the
machine. There you build the P2 powertrain, build 01. Section 05 moves the engine's operating
point: the line of the engine's most efficient speeds, the CVT that moves the engine toward it, and
the power-split hybrid that does it with a planetary gear. You build the operating line, build 02.
Section 06 is the energy manager: driving modes; a window for the battery's state of charge, which
is how full it is; switching with a gap between the on and off thresholds so the modes do not
flicker; ending the test with the same charge we started with; and, in one slide, an optimizer we
do not build. You build the energy manager, build 03. Section 07 is the result: the WLTC for three
powertrains, and the table of the five positions against the published studies. You build the
charge-sustaining WLTC, the run that ends with the battery as full as it started, build 04.
Section 08 wraps up.

Four build steps, each after the theory it puts into practice. Sections 01 to 03 are theory only.
-->

---
layout: center
---

## The models behind this lecture

<div class="grid grid-cols-3 gap-8 text-left text-[0.85rem]">
<div>

### Notebooks

`notebooks/lecture05/`

- `01-operating-points.pluto.jl`: Lecture 2's engine on its fuel map, conventional against P2
  on WLTC
- `02-p-positions.pluto.jl`: P0 to P4 at 30 kW, fuel, recovered energy and electric driving per
  position
- `03-machine-size.pluto.jl`: degree of hybridization, the P2 machine 8–40 kW against fuel
  saving

`scripts/bsfc_line.jl`: the engine's most efficient speed for each power, over the map

</div>
<div>

### Library parts

`VehicleSystemsComponents.Vehicle`

- `DisconnectClutch`: the K0 clutch with its actuator
- `Electric.HybridDrive`: the 30 kW machine and 1.4 kWh battery
- `assets/data/engine/bsfc_line.csv`: the most efficient speed for each power, as a table
- `SoCCorrectedFuel`: fuel corrected for the change in battery charge
- `EnergyManager`: the five rules; `TorqueToPedal`: torque in, pedal out
- the P0, P1, P3 and P4 test models
- the prepared parts for the series-hybrid homework

</div>
<div>

### Yours, built along

Your `MyCar`, branch `handson-05`:

- step 01: the P2 powertrain on the planar car
- step 02: the engine's operating line
- step 03: the rule-based energy manager
- step 04: the charge-sustaining WLTC

Components: `P2Powertrain`, `P2WLTC`, `P2OperatingLineWLTC`, `P2HybridWLTC`

Reference answers: `dyad/HandsOn05/`.

</div>
</div>

<!--
This slide lists the models behind today, in three columns.

The left column is the notebooks. The operating-points notebook puts Lecture 2's engine points on
its fuel map, once for the conventional car and once for the P2 hybrid. A fuel map shows how much
fuel the engine burns for each unit of work, at every speed and torque. The P-position notebook
prints the table of section 07: fuel, recovered braking energy and engine-off driving for each
position, all at 30 kilowatts. The degree-of-hybridization notebook runs the P2 car with machines
from 8 to 40 kilowatts and plots the fuel saving against machine size. And a script draws, over
the map, the engine's most efficient speed for each power; we call that the best-BSFC line in
section 05. Every plot in this deck comes from one of these; the block diagrams are drawn by hand.

The middle column is what the course library gives you, so you spend the build on the hybrid and
not on parts: the K0 clutch with its actuator, the machine and battery at hybrid size, the
efficient-speed line as a data table, the block that corrects fuel for the change in battery
charge, the energy manager with its five rules, and the engine's map read backwards, which turns a
torque the manager wants into a pedal position. Then test models for the other four positions, and
the prepared parts for the series homework.

The right column is what you build in your own `MyCar`, on a new branch, `handson-05`: the P2
powertrain, the operating line, the energy manager, and the charge-sustaining WLTC, as the
components `P2Powertrain`, `P2WLTC`, `P2OperatingLineWLTC` and `P2HybridWLTC`. The reference
answers are in `dyad/HandsOn05`.
-->

---
routeAlias: how-the-build-works
---

## How the build works today

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-start">
<div>

- Work in your `MyCar`, on a new branch **`handson-05`**, from your finished `handson-04`.
- Each step lists the parts with their library path, instance name and values, every wire and
  line of code, and the numbers to check before you go on.
- **Use the names given.** The energy manager and the fuel calculation read signal paths by name.
- **Plot in the Julia REPL.** Click ▷ **Run Analysis** once for each new analysis before you paste
  the snippet that calls it.
- **Fell behind?** Every step ends with the finished code of that step, to paste.

</div>
<div>

> **Every number** on a checkpoint is checked by an automated test or measured on the reference
> model, as in Lectures 3 and 4.

The build guide holds every block, line and number:

[page: Lecture 5 build guide](../lecture/lecture-05/)

Commit after each step: `Step 01: P2 powertrain`, `Step 02: operating line`, …

</div>
</div>

<!--
Before the first build, here is how the build works. It works as in Lectures 3 and 4.

You work in your `MyCar` on a new branch, `handson-05`, started from your finished Lecture 4 branch,
because the machine and the battery you built there come back today. The build guide has one
section per step, with the parts, their names and values, every wire and line of code, and the
numbers to check.

Use the names given. Today the energy manager reads the battery's state of charge and the
engine's speed by name, and the fuel calculation reads the fuel flow and the battery power. Keep
Studio's default names and the error shows up far from its cause.

You plot in the Julia REPL, and you click Run Analysis once on each new analysis before you paste
the snippet that calls it, so the REPL has loaded your library.

If you fall behind, every step ends with its finished code.

The quote box: every number in a green box is either checked by an automated test or measured on
the reference model. If yours differs, your model differs.

Commit after each step, Step 01: P2 powertrain, and so on.
-->
