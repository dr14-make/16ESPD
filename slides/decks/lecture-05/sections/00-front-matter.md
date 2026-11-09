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
Welcome to Lecture 5, on hybrids. A hybrid car has two power sources: a gasoline engine, and an
electric machine with a battery. The subtitle names the four things we put together today: the
engine from Lecture 2, a clutch, the electric machine from Lecture 4, and an energy manager. The
energy manager is the controller that decides which of them drives.

The sentence on the slide is the whole lecture in one line. The engine's operating point is the
speed and the torque it runs at, at one moment. A hybrid saves fuel by moving that point: it runs
the engine where it burns little fuel for each kilowatt-hour of work, or it switches the engine
off. And the clutch decides how far the hybrid can move it. An electric machine that can be cut
loose from the engine can drive the car alone, and it can brake the car without dragging the
engine along. That matters more than how strong the machine is.

Today you build one hybrid, called a P2. The P stands for position: where the machine sits in the
driveline. Section 04 explains the names. You build it on Lecture 4's planar car, the car model
with four wheels on a flat road. Then I move its machine to every other position and show you the
table that the theory predicts.

Today covers series and parallel hybrids, the degree of hybridization, the P0 to P4 positions and
the controller. The fuel cell is a series hybrid with a different source; you find it in the extra
pack, the optional slides after this lecture.

The small line at the bottom is for browsing the slides on your own: the arrow keys and the space
bar move, O opens the overview, and G jumps to a slide.
-->

---
routeAlias: from-lectures-2-and-4
---

## Where Lectures 2 and 4 left the car

<div class="grid grid-cols-2 gap-8">
<div>

### Lecture 2: the engine car

The engine model, built from measured maps, with a CVT drove the WLTC on **5.22 L/100 km**:
**168.8 MJ/100 km** of gasoline. Every stop idled the engine, and every brake burned what the engine
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
unit for gasoline and electricity · regen: the machine brakes as a generator and charges the
battery · K0: the clutch between the engine and the rest</div>

<!--
Let us recall the two cars we already have. First, four terms from the line at the bottom of the
slide. The WLTC is the standard test drive for fuel consumption. It takes about 30 minutes, in four
phases: Low, Medium, High and Extra High speed. A CVT is a continuously variable transmission, a
gearbox whose ratio changes smoothly instead of in steps. Megajoules per 100 kilometers is energy
per distance; it lets us compare a gasoline car and an electric car in one unit. And regen, short
for regenerative braking, means that the electric machine brakes the car as a generator and charges
the battery.

On the left you see Lecture 2's car: the engine model, built from the engine's measured maps, with
the CVT. On the WLTC it burned 5.22 liters of gasoline per 100 kilometers. That is 168.8 megajoules
per 100 kilometers, the number we started Lecture 4 with, and our current model still gives it. Two
things in that run are pure waste. The engine idles at every stop. And every time the car brakes,
the energy the engine put into the car's speed goes into the brake discs as heat.

On the right you see Lecture 4's battery-electric car on the planar car model. At the battery
terminals it used 131.2 watt-hours per kilometer, which is 47.2 megajoules per 100 kilometers, and
24 percent of the driving energy came back through regen. That is where Lecture 4 ended.

The green box says what we do today. We keep the engine from Lecture 2 and add a disconnect clutch.
We call it K0: the clutch that can cut the engine off from the rest of the car. We take the machine
from Lecture 4, but sized at about 30 kilowatts, and a battery of about 1.4 kilowatt-hours. Those
sizes come from a real car. The 2011 Hyundai Sonata Hybrid, which Oak Ridge National Laboratory
measured in detail, had a 30 kilowatt machine behind an engine clutch and a 1.4 kilowatt-hour, 270
volt battery pack. It all goes on Lecture 4's planar car and drives the same cycle. So at the end
of today we can put the conventional car, the hybrid and the electric car side by side.
-->

---

## The sections

| # | Section | What it covers | Build |
|---|---|---|---|
| <Link to="why-hybridize">01</Link> | Why hybridize | where Lecture 2's engine spends the WLTC, the three savings | |
| <Link to="series-and-parallel">02</Link> | Series and parallel | series, parallel, series-parallel with a clutch; other types; the series homework | |
| <Link to="degree-of-hybridization">03</Link> | Degree of hybridization | the electric share of the power, micro to plug-in, cost | |
| <Link to="p-positions">04</Link> | P0 to P4 | where the machine sits, and why the clutch decides | 01 wire the library's P2 powertrain into the car |
| <Link to="operating-point">05</Link> | Moving the operating point | the engine's most efficient speeds, the CVT, power split | 02 the operating line |
| <Link to="energy-management">06</Link> | Energy management | driving modes, the battery's charge window, an optimizer | 03 the energy manager |
| <Link to="results">07</Link> | Results | WLTC three ways, the five positions against published studies | 04 the comparison at equal charge |
| <Link to="wrap-up">08</Link> | Wrap-up | what you measured, what the model leaves out | |

<!--
Here is the plan for today: seven sections and a wrap-up. The first column links to each section,
and the last column names the build at its end.

Section 01 asks why we hybridize at all. We look at where Lecture 2's engine spends the WLTC on its
fuel map, and at the three ways a hybrid saves fuel. Section 02 is about the layouts: series,
parallel, and series-parallel with a clutch, plus one slide on other kinds of hybrid. The series
hybrid comes back as your homework. Section 03 is the degree of hybridization: the electric
machine's power divided by the total power of machine and engine. It runs from a micro hybrid,
which only stops the engine, up to a plug-in, and we look at what it costs.

Section 04 covers the five places a parallel hybrid's machine can sit, P0 to P4, and the argument
that the clutch matters more than the machine. There you wire the library's P2 powertrain into
the car, build 01. Section 05 moves the engine's operating point: the line of the engine's most
efficient speeds, the CVT that moves the engine toward that line, and the power-split hybrid that
does the same with a planetary gear. You build the operating line, build 02.

Section 06 is the energy manager. It covers the driving modes; a window for the battery's state of
charge, which is how full the battery is; switching with a gap between the on and off thresholds,
so the modes do not flicker; ending the test with the same charge we started with; and, in one
slide, an optimizer that we do not build. You wire the library's energy manager into the car,
build 03. Section 07 gives the results: the WLTC for three powertrains, and the table of the five
positions against the published studies. There you compare your three runs, H0, the line car and
the hybrid, at equal battery charge, build 04. Section 08 wraps up.

So there are four build steps, each right after the theory it puts into practice. Sections 01 to
03 are theory only.
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

### Yours, from starters

One starter per step in `dyad/HandsOn05/`:

- step 1: the library P2 powertrain on the planar car
- step 2: the engine's operating line
- step 3: the rule-based energy manager
- step 4: the charge-sustaining comparison

Starters: `Step1EngineWLTC`, `Step2OperatingLineWLTC`, `Step3HybridWLTC`

Reference answers: `P2WLTC`, `P2OperatingLineWLTC`, `P2HybridWLTC`.

</div>
</div>

<!--
This slide lists the models behind today, in three columns.

The left column is the notebooks. The operating-points notebook puts the points where Lecture 2's
engine runs onto its fuel map, once for the conventional car and once for the P2 hybrid. A fuel map
shows how much fuel the engine burns for each unit of work, at every speed and torque. The
P-positions notebook prints the table of section 07: the fuel, the recovered braking energy and the
time driven with the engine off, for each position, all at 30 kilowatts. The machine-size notebook
runs the P2 car with machines from 8 to 40 kilowatts and plots the fuel saving against the machine
size. The last line of the column computes, over the map, the engine's most efficient speed for
each power. In section 05 we call that the best-BSFC line. Every plot you see today comes from one
of these; the block diagrams are drawn by hand.

The middle column is what the course library gives you, so that you spend the build on the hybrid
and not on parts. You get the K0 clutch with its actuator, and the machine and battery at hybrid
size. You get the line of efficient speeds as a table of numbers, and the block that corrects the
fuel for the change in battery charge. You get the energy manager with its five rules, and the
engine's map read backwards, which turns the torque the manager wants into a pedal position. Then
there are test models for the other four positions, and the prepared parts for the series-hybrid
homework.

The right column is what you build: the library's P2 powertrain on the planar car, the operating
line, the energy manager, and the charge-sustaining comparison. Each step starts from a starter
model in the HandsOn05 folder, and the finished reference for each step sits next to it.
-->

---
routeAlias: how-the-build-works
---

## How the build works today

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-start">
<div>

- **Clone the course repository** at the tag `lecture-05-dyad-3.5`, on a branch `handson-05`;
  step 0 of the guide has the clicks.
- **Open the step's starter** in `HandsOn05`. It already holds the car, cycle, driver, fuel meter
  and everything that can only be written as code, plus its analysis.
- Each step lists the blocks to place, every wire, and the numbers to check before you go on.
  About 90 minutes in all.
- **Use the names given.** The starter's equations read the placed blocks by name.
- **Plot in the Julia REPL.** After ▷ **Run Analysis**, keep the result: `r1 = solution`.
- **Fell behind?** Every step names its finished reference; the next starter does not need yours.

</div>
<div>

> **Every number** on a checkpoint is checked by an automated test or measured on the reference
> model, as in Lectures 3 and 4.

The build guide holds every block, line and number:

[page: Lecture 5 build guide](../lecture/lecture-05/)

</div>
</div>

<!--
Before the first build, here is how the build works.

Today you work inside the course repository itself. Clone it at the tag lecture-05-dyad-3.5 and
make a branch handson-05; step 0 of the guide has the clicks.

Each step starts from a starter model in the HandsOn05 folder. The starter already holds the car,
the drive cycle, the driver, the fuel meter and everything that can only be written as code, and
it comes with its analysis. You place a block or two from the library and draw a few wires. The
whole build takes about ninety minutes.

Please use the names given. The starter's equations read the blocks you place by name, so if you
keep Studio's default name, the error shows up far away from its cause.

You plot in the Julia REPL. After each run, keep the result under its own name, r1, r2 and r3, so
that the comparison at the end can read all three.

If you fall behind, every step names its finished reference model, and the next step's starter
does not need your previous step.

The box on the right says that every number in a green checkpoint box has been checked against the
reference model. If your number differs, your model differs.
-->
