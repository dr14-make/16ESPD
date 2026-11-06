---
routeAlias: front-matter
layout: cover
---

# Hybrids

<h1 class="!text-5xl !-mt-4 opacity-70">Engine, clutch, machine, energy manager</h1>

Vehicle Systems &amp; Components — Lecture 5

A hybrid saves fuel by moving the engine's operating point, and the clutch decides how far it can
move it.

<div class="text-xs opacity-60 mt-12">

<kbd>→</kbd> <kbd>Space</kbd> next &nbsp;·&nbsp; <kbd>←</kbd> previous &nbsp;·&nbsp;
<kbd>O</kbd> overview &nbsp;·&nbsp; <kbd>G</kbd> go to slide &nbsp;·&nbsp;
presenter mode from the nav bar, bottom left

</div>

<!--
Welcome to Lecture 5, hybrids. The subtitle names the four things we put together today: Lecture
2's engine, a clutch, Lecture 4's machine, and an energy manager that decides which of them drives.

The sentence on the slide is the whole lecture. A hybrid saves fuel by moving the engine's
operating point: running it where it burns little fuel per kilowatt-hour, or switching it off. And
the clutch decides how far it can move it: a machine that can be cut loose from the engine can
drive the car alone and brake it without dragging the engine along, and that matters more than how
strong the machine is.

You build one hybrid today, a P2, on Lecture 4's planar car. Then I move its machine to every other
position and show the table the theory predicts.

The material follows the course's deck on electric vehicles and electric machines, its slides on
series and parallel hybrids, the degree of hybridization, the P0 to P4 positions and the
controller. The fuel cell, which is a series hybrid with a different source, is in the extra pack.

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

The mapped engine and the CVT drove the WLTC on **5.22 L/100 km**: **168.8 MJ/100 km** of
petrol. Every stop idled the engine, and every brake burned what the engine had made.

</div>
<div>

### Lecture 4: the battery-electric car

The Leaf-class planar car drove the same cycle on **131.2 Wh/km** at the battery terminals:
**47.2 MJ/100 km**, with about a quarter of the traction energy coming back through regen.

</div>
</div>

<div class="handson">Today: Lecture 2's engine, a disconnect clutch, Lecture 4's machine shrunk to
about 30 kW and a battery of about 1.4 kWh, on Lecture 4's planar car and the same WLTC. So three
powertrains meet on one car and one cycle.</div>

<!--
Let us recall the two cars we already have.

On the left, Lecture 2's car: the mapped engine with the CVT. On the WLTC it burned 5.22 liters of
petrol per 100 kilometers, which is 168.8 megajoules per 100 kilometers. That is the number from
Lecture 4's opening slide, and the research note's headline table reproduces it on current main.
Two things in that run are pure waste: the engine idles at every stop, and every time the car
brakes, the energy the engine put into its speed goes into the brake discs as heat.

On the right, Lecture 4's battery-electric car on the planar platform. At the battery terminals it
used 131.2 watt-hours per kilometer, 47.2 megajoules per 100 kilometers, and 24 percent of the
traction energy came back through regen. Those are the numbers from Lecture 4's wrap-up.

The green box says what we do today. We keep the engine from Lecture 2, add a disconnect clutch,
called K0, take the machine from Lecture 4 but sized at about 30 kilowatts, and a battery of about
1.4 kilowatt-hours. Those sizes are the plan's: the 2011 Hyundai Sonata Hybrid that Oak Ridge
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
| <Link to="degree-of-hybridization">03</Link> | Degree of hybridization | P<sub>EM</sub> / (P<sub>EM</sub> + P<sub>ICE</sub>), micro to plug-in, cost | |
| <Link to="p-positions">04</Link> | P0 to P4 | where the machine sits, and why the clutch decides | 01 the P2 powertrain |
| <Link to="operating-point">05</Link> | Moving the operating point | the best-BSFC line, the CVT, power split | 02 the operating line |
| <Link to="energy-management">06</Link> | Energy management | modes, SoC window, hysteresis, charge sustaining, ECMS | 03 the energy manager |
| <Link to="results">07</Link> | Results | WLTC three ways, the P-position table against the studies | 04 the WLTC, charge-sustaining |
| <Link to="wrap-up">08</Link> | Wrap-up | what you measured, what the model leaves out | |

<!--
Here is the plan for today: seven sections and a wrap-up. The first column links to each section,
the last says what you build at its end.

Section 01 asks why we hybridize at all: where Lecture 2's engine spends the WLTC on its fuel map,
and the three ways a hybrid saves fuel. Section 02 is the architectures: series, parallel, and
series-parallel with a clutch, and a slide on the other kinds of hybrid; the series hybrid comes back as your homework.
Section 03 is the degree of hybridization: how much of the power is electric, from a micro hybrid
that only stops the engine to a plug-in, and what it costs. Section 04 is the five positions a
parallel hybrid's machine can take, P0 to P4, and the argument that the clutch matters more than
the machine. There you build the P2 powertrain, build 01. Section 05 moves the engine's operating
point: the best-BSFC line, the CVT that moves the engine toward it, and the power-split hybrid that does
it with a planetary gear. You build the operating line, build 02. Section 06 is the energy manager:
modes, a state-of-charge window with hysteresis, charge sustaining, and the optimizer we do not
build in one slide. You build the energy manager, build 03. Section 07 is the result: the WLTC for
three powertrains, and the table of the five positions against the published studies. You build
the charge-sustaining WLTC, build 04. Section 08 wraps up.

Four build steps, each after the theory it puts into practice. Sections 01 to 03 are theory only.
-->

---
layout: center
---

## The models behind this lecture

<div class="grid grid-cols-3 gap-8 text-left text-[0.85rem]">
<div>

### Notebooks

`notebooks/lecture05/` <span class="todo">TODO: file names</span>

- `01-operating-points.pluto.jl`: Lecture 2's engine on its BSFC map, conventional against P2
  on WLTC
- `03-machine-size.pluto.jl`: degree of hybridization, the P2 machine 8–40 kW against fuel
  saving
- P-position table: fuel, recovered energy and modes per position (#114)

`scripts/bsfc_line.jl`: the best-BSFC line over the map

</div>
<div>

### Library parts

`VehicleSystemsComponents.Vehicle`

- `DisconnectClutch`: the K0 clutch with its actuator
- `Electric.HybridDrive`: the 30 kW machine and 1.4 kWh battery
- `assets/data/engine/bsfc_line.csv`: the best-BSFC operating line
- `SoCCorrectedFuel`: the SoC-corrected fuel calculation
- the P0, P1, P3 and P4 benches (#114)
- the series-hybrid homework ground (#116)

</div>
<div>

### Yours, built along

Your `MyCar`, branch `handson-05`:

- step 01: the P2 powertrain on the planar car
- step 02: the engine's operating line
- step 03: the rule-based energy manager
- step 04: the charge-sustaining WLTC

<span class="todo">TODO: component names (#111–#113)</span>

Reference answers: `dyad/HandsOn05/`.

</div>
</div>

<!--
This slide lists the models behind today, in three columns. Several of them are still being built;
the yellow TODO marks say what is missing and the issue numbers say where it comes from.

The left column is the notebooks. The operating-points notebook puts Lecture 2's engine points on
its fuel map, once for the conventional car and once for the P2 hybrid. The degree-of-hybridization
notebook sweeps the P2 machine from 8 to 40 kilowatts and plots the fuel saving against it. The
P-position notebook prints the table of section 07: fuel, recovered energy and available modes for
each position. And a script draws the best-BSFC line over the map. Every plot in this deck comes
from one of these; the block diagrams are drawn by hand.

The middle column is what the course library gives you, so you spend the build on the hybrid and
not on parts: the K0 clutch with its actuator, the machine and battery at hybrid size, the best-BSFC
line as a data table, the block that corrects fuel for the change in battery charge, the benches
for the other four positions, and the ground for the series homework.

The right column is what you build in your own `MyCar`, on a new branch, `handson-05`: the P2
powertrain, the operating line, the energy manager, and the charge-sustaining WLTC. The reference
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

> **Every number** on a checkpoint is a test expectation or a measured run of the reference model,
> as in Lectures 3 and 4.

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

The quote box: every number in a green box is a test expectation or a measured run of the reference
model. If yours differs, your model differs.

Commit after each step, Step 01: P2 powertrain, and so on.
-->
