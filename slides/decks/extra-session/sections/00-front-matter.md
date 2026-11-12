---
routeAlias: front-matter
layout: cover
---

# Energy on Board

<h1 class="!text-5xl !-mt-4 opacity-70">Batteries in depth, charging and hydrogen</h1>

Vehicle Systems &amp; Components — Extra session

Energy on board decides what the car is: how fast it goes back in, and what it costs to get it
there.

<div class="grid grid-cols-2 gap-6 mt-4 w-[52rem]">
<div>

<img class="photo" src="/photos/00-leaf-cutaway.jpg" style="height: 11rem" alt="A 2013 Nissan Leaf cut open along its side at a show: seats and dashboard above, the flat orange battery pack filling the floor under the cabin."/>

<div class="caption">A plug: 2013 Nissan Leaf, cutaway · Norsk Elbilforening, CC BY 2.0</div>

</div>
<div>

<img class="photo" src="/photos/07-mirai-cutaway.jpg" style="height: 11rem" alt="A first-generation Toyota Mirai cut open along its side at a motor show: power control unit over the motor at the front, the fuel-cell stack under the front seats, the yellow hydrogen tanks under the rear seat."/>

<div class="caption">A nozzle: Mirai (gen 1) cutaway, São Paulo 2016 · Mariordo, CC BY-SA 4.0</div>

</div>
</div>

<div class="text-xs opacity-60 mt-6">

<kbd>→</kbd> <kbd>Space</kbd> next &nbsp;·&nbsp; <kbd>←</kbd> previous &nbsp;·&nbsp;
<kbd>O</kbd> overview &nbsp;·&nbsp; <kbd>G</kbd> go to slide &nbsp;·&nbsp;
presenter mode from the nav bar, bottom left

</div>

<!--
Welcome to the extra session, the last one of the electric and hybrid block. Tonight is theory only,
with four exercises to take home.

*[ask]* A show of hands. How long does it take to fill a hydrogen car? Under five minutes? Under
ten? *[pause]* And a Nissan Leaf, 10 to 80 percent on a fast charger: a quarter of an hour? Half an
hour? *[pause]* Remember your guess. By the end we will have both numbers, measured.

The line on the slide is tonight's topic: how fast energy goes back into the car, and what that
costs. A battery car refills through a plug. A fuel-cell car refills through a nozzle.

*[show photos]* The two cars, cut open. The Leaf's battery fills the floor. The Mirai has its
fuel-cell stack under the front seats and its hydrogen tanks under the rear seat. -->

---
routeAlias: from-lectures-4-and-5
---

## Where Lectures 4 and 5 left the car

<div class="grid grid-cols-[1.7fr_1fr] gap-8 items-end">
<div>

![Two circuits side by side. Left, Lecture 4: inside a dashed box labeled battery, a fixed source E in series with a resistor R, feeding a load at the terminals; current i, terminal voltage v; v = E − R i, E and R fixed. Right, this session: the Thevenin cell, a source OCV(SoC), the resistor R0 and a parallel pair R1 and C1 with voltage v1, to the terminals; v = OCV(SoC) − R0 i − v1.](/diagrams/02-before-after.svg)

<div class="caption">Left: deck 8, after Larminie and Lowry, redrawn · right: the section 02 Thevenin cell.</div>

</div>
<div>

![Block diagram of a series hybrid. The engine turns a generator, mechanical to electrical, which feeds a DC link; the battery is on the same link, and in a plug-in the grid charges it; the link feeds the motor, electrical to mechanical, which alone drives the wheels, and regen goes back to the battery. No shaft runs from the engine to the wheels.](/diagrams/00-l5-series.svg)

<div class="caption">Lecture 5's series hybrid</div>

</div>
</div>

<div class="grid grid-cols-[1.7fr_1fr] gap-8 text-[0.95rem]">
<div>

**Lecture 4:** *E* = **350 V**, *R*₀ = **0.1 Ω**, SoC counted from the current. *E* never moves,
the voltage sags only at once, and nothing stops SoC at zero.

</div>
<div>

**Lecture 5:** only the motor drives the wheels. The fuel-cell car puts a stack in place of the
engine-generator.

</div>
</div>

<div class="handson">Today: a cell whose voltage follows its charge, the BMS that watches it, the
two ways to refill a car — a plug and a nozzle — and what each costs.</div>

<!--
Where we left the car. *[show figure]* Your Lecture 4 battery: E minus R0 times i, with E fixed at
350 volts. E never moves, so full and empty give the same voltage. Nothing stops the state of charge
at zero. At 330 amperes, yours ended at minus 0.54. Section 02 fixes this with the second circuit,
the Thevenin cell.

On the right is Lecture 5's series hybrid. In section 07 a fuel-cell stack replaces the engine and
generator: that is the Toyota Mirai. The stepped gearbox Lecture 5 promised moves to a later
lecture.

Your Lecture 4 energy bill said "tank to wheel only: the electricity is made somewhere". Tonight we
follow it back to the power plant.
-->

---
routeAlias: sections
skipInCut: true
---

## The sections

<div class="tight">

| # | Section | What it covers | 3 h | 90 min |
|---|---|---|---:|---:|
| <Link to="cells-and-chemistries">01</Link> | Cells and chemistries | the battery terms: C-rate, cell to pack, SoC, DoD, SoH; LFP, NMC, sodium-ion; cost | 22 | 10 |
| <Link to="thevenin-cell">02</Link> | The Thevenin cell | OCV(SoC), R₀, one RC pair; the pulse response | 12 | 4 |
| <Link to="bms">03</Link> | The BMS | coulomb counting and its drift, the OCV reset, balancing, limits | 12 | 5 |
| <Link to="charging">04</Link> | Charging | CC-CV, measured DC curves, 400 V vs 800 V, modes, losses, ISO 15118, the network | 40 | 25 |
| — | Break | | 15 | — |
| <Link to="fuel-cells">05</Link> | Fuel cells | the polarization curve, the stack, balance of plant | 19 | 9 |
| <Link to="hydrogen">06</Link> | Hydrogen | 700 bar storage and fueling, the station chain, counts, price, AFIR Art. 6 | 35 | 20 |
| <Link to="fuel-cell-car">07</Link> | The fuel-cell car | a series hybrid with a different source; well-to-wheel against the BEV | 15 | 9 |
| <Link to="wrap-up">08</Link> | Wrap-up | plug or nozzle, the summary, the take-home exercises | 5 | 5 |

</div>

Not tonight: the stepped gearbox and the dq model of the motor, promised in Lecture 5, move to a
later lecture.

<!--
Eight sections tonight, with a break after charging. The last two columns are minutes: the full
three hours, and the 90-minute version.

The first half is the plug. Section 01 gives the battery's terms and the cells on the road today.
Section 02 gives the cell a voltage that follows its charge. Section 03 is the battery management
system, which must know that charge without a fuel gauge. Section 04, the longest, is charging: why
the last fifth is slow, why some cars charge twice as fast as others, what is lost, and how many
chargers Czechia has. After the break comes the nozzle: the fuel cell, hydrogen from tank to station
and its price, and the fuel-cell car as Lecture 5's series hybrid, traced back to the power plant.
Section 08 puts the plug and the nozzle side by side.

To browse on your own: the arrow keys and the space bar move, O opens the overview, G jumps to a
slide.
-->
