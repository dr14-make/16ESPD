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
Welcome to the extra session, the last one of the electric and hybrid block. Tonight is theory
only: no build, no Dyad model, and four exercises to take home at the end.

*[ask]* First, a show of hands. How long does it take to fill a hydrogen car? Under five minutes?
Under ten? *[pause]* And a Nissan Leaf, 10 to 80 percent on a fast charger: a quarter of an hour?
Half an hour? An hour? *[pause]* Remember your guess; by the end we will have both numbers, measured.

The sentence on the slide is the whole session. Energy on board decides what the car is: how fast
the energy goes back in, and what it costs to get it there. A battery car refills through a plug, a
fuel-cell car through a nozzle. At the wheel both are electric; tonight is about everything before
the wheel.

*[show photos]* The two cars of tonight, cut open. Left, a Leaf: the orange battery fills the whole
floor. Right, a first Mirai: the stack under the front seats, the yellow hydrogen tanks under the
rear seat. Both photographs are from Wikimedia Commons: the Leaf by the Norwegian EV Association,
Norsk Elbilforening, the Mirai by the user Mariordo, at the São Paulo motor show.
-->

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
Where we left the car. *[show figure]* On the left, your Lecture 4 battery, the left circuit: E minus R0 times i, with E fixed at 350
volts and R0 at 0.1 ohm, and the state of charge counted from the current. Its faults: E never
moves, so full and empty look the same; the voltage sags only at the instant the current changes;
and nothing stops the state of charge at zero. At 330 amperes yours ended at minus 0.54. Section 02
fixes all three, with the circuit on its right: the Thevenin cell.

On the right, Lecture 5's series hybrid: only the motor drives the wheels, a source on the DC link
feeds it, a battery buffers it. In section 07 a fuel-cell stack replaces the engine-generator, and
that is the Toyota Mirai.

Lecture 5 promised the stepped gearbox for tonight; it moves to a later lecture, with the more
detailed motor model.

And your Lecture 4 energy bill said "tank to wheel only: the electricity is made somewhere".
Tonight we follow it back to the power plant.
-->

---
routeAlias: sections
skipInCut: true
---

## The sections

<div class="tight">

| # | Section | What it covers | 3 h | 90 min |
|---|---|---|---:|---:|
| <Link to="cells-and-chemistries">01</Link> | Cells and chemistries | LFP, NMC, sodium-ion; specific energy and cost today | 15 | 5 |
| <Link to="thevenin-cell">02</Link> | The Thevenin cell | OCV(SoC), R₀, one RC pair; the pulse response | 15 | 5 |
| <Link to="bms">03</Link> | The BMS | coulomb counting and its drift, the OCV reset, balancing, limits | 15 | 7 |
| <Link to="charging">04</Link> | Charging | CC-CV, measured DC curves, 400 V vs 800 V, modes, losses, ISO 15118, the network | 40 | 25 |
| — | Break | | 15 | — |
| <Link to="fuel-cells">05</Link> | Fuel cells | the polarization curve, the stack, balance of plant | 20 | 10 |
| <Link to="hydrogen">06</Link> | Hydrogen | 700 bar storage and fueling, the station chain, counts, price, AFIR Art. 6 | 35 | 20 |
| <Link to="fuel-cell-car">07</Link> | The fuel-cell car | a series hybrid with a different source; well-to-wheel against the BEV | 15 | 10 |
| <Link to="wrap-up">08</Link> | Wrap-up | plug or nozzle, the summary, the take-home exercises | 5 | 5 |

</div>

Not tonight: the stepped gearbox and the dq model of the motor, promised in Lecture 5, move to a
later lecture.

<!--
Here is the evening: eight sections, with a break after charging. The first column links to each
section; the last two columns are minutes, for the full three hours and for the 90-minute version
built from the same slides.

The first half is the plug. Section 01 is the cells on the road today. Section 02 gives the cell a
voltage that follows its charge. Section 03 is the battery management system, the BMS, which has
to know that charge without a fuel gauge. Section 04, the longest, is charging: why the last
fifth is slow, why some cars charge twice as fast as others, what is lost, and how many chargers
Czechia has.

After the break, the nozzle. Section 05 is the fuel cell and its one characteristic curve.
Section 06 is the hydrogen: how it gets into a tank in three minutes, what a station needs to do
that, how many stations there are, and what a kilogram costs. Section 07 puts the stack into
Lecture 5's series hybrid and follows the electricity from the power plant to the wheel for both
cars. Section 08 puts the plug and the nozzle side by side.

For browsing on your own afterwards, the line on the cover: the arrow keys and the space bar move,
O opens the overview, G jumps to a slide.
-->
