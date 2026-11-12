---
routeAlias: front-matter
layout: cover
---

# Energy on Board

<h1 class="!text-5xl !-mt-4 opacity-70">Batteries in depth, charging and hydrogen</h1>

Vehicle Systems &amp; Components — Extra session

Energy on board decides what the car is: how fast it goes back in, and what it costs to get it
there.

<div class="text-xs opacity-60 mt-12">

<kbd>→</kbd> <kbd>Space</kbd> next &nbsp;·&nbsp; <kbd>←</kbd> previous &nbsp;·&nbsp;
<kbd>O</kbd> overview &nbsp;·&nbsp; <kbd>G</kbd> go to slide &nbsp;·&nbsp;
presenter mode from the nav bar, bottom left

</div>

<!--
Welcome to the extra session, the last one of the electric and hybrid block. Today is theory only:
there is no build and no Dyad model, only slides, and the take-home exercises at the end.

The sentence on the slide is the whole session. Energy on board decides what the car is: how fast
the energy goes back in, and what it costs to get it there. Lecture 4 treated the battery as a fixed
voltage behind a resistor. Today the cell gets a voltage that moves with its charge, and a
relaxation. Then we put the two ways to refill an electric car side by side: a plug, limited by the
constant-voltage phase, by heat and by the grid; and a hydrogen nozzle, fast at the car, but long
and lossy before it.

The material follows the course's deck 8, batteries and fuel cells, after Larminie and Lowry, cut to
what is on the road today. Charging and hydrogen refueling are new; they are not in deck 8.

The small line at the bottom is for browsing the slides on your own: the arrow keys and the space
bar move, O opens the overview, and G jumps to a slide.
-->

---
routeAlias: from-lectures-4-and-5
---

## Where Lectures 4 and 5 left the car

<div class="grid grid-cols-2 gap-8">
<div>

### Lecture 4: the battery

*v* = *E* − *R*₀ *i*, with *E* = **350 V** and *R*₀ = **0.1 Ω**, and SoC counted from the
current.

*E* never moves, the voltage sags only at once, and nothing stops SoC at zero.

</div>
<div>

### Lecture 5: the series hybrid

Only the motor drives the wheels; a source on the DC link feeds it, and a battery buffers it.

The fuel-cell car is that shape with a stack in place of the engine-generator.

</div>
</div>

<div class="handson">Today: a cell whose voltage follows its charge, the BMS that watches it, the
two ways to refill a car — a plug and a nozzle — and what each costs.</div>

<!--
Let us recall where we are. On the left, Lecture 4's battery: the terminal voltage v equals E minus
R0 times i. E is the open-circuit voltage, 350 volts for our pack; R0 is the internal resistance,
0.1 ohm; i is the current, positive when the battery delivers. The state of charge, SoC, was
counted by integrating the current.

Three things in that model are wrong, and the second line says them. E never moves, so a full and
an empty battery have the same voltage. The voltage sags only at the instant the current changes,
never slowly afterwards. And nothing stops the state of charge at zero: in Lecture 4 it went
negative at 330 amperes. Section 02 fixes all three.

On the right, Lecture 5's series hybrid: only the electric motor drives the wheels. A source on the
DC link, the electrical junction, feeds it, and a battery buffers the difference. In Lecture 5 the
source was the engine-generator. In section 07 we put a fuel-cell stack there and get the Toyota
Mirai.

The green box is today's route: the cell, the battery management system that watches it, charging
by plug, refueling by nozzle, and what each costs per 100 kilometers.
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
| <Link to="wrap-up">08</Link> | Wrap-up | summary and the take-home exercises | 5 | 5 |

</div>

<!--
Here is the plan: eight sections, with a break after charging. The first column links to each
section. The last two columns are minutes: the full three-hour session, and the 90-minute version
built from the same slides. The 90-minute version takes its time from the battery sections, which
recall Lecture 4, and protects charging and hydrogen, the topics this session exists for.

Section 01 tours the chemistries on the road now: LFP, NMC and sodium-ion, with their specific
energy and cost. Section 02 is the Thevenin cell: an open-circuit voltage that follows the state of
charge, R0, and one resistor-capacitor pair, and what a current pulse does to it. Section 03 is the
battery management system: counting the charge, why the count drifts, how the open-circuit voltage
resets it, balancing the cells, and the limits it enforces.

Section 04, the longest, is charging: constant current then constant voltage at the cell, measured
curves of real cars, why 800 volts charges faster, the charging modes and connectors, the losses,
the communication standard ISO 15118, and the charging network in Czechia and the EU.

After the break, section 05 is the fuel cell: the polarization curve, the stack and the balance of
plant. Section 06 is hydrogen on board and at the station: 700 bar storage and fueling, the chain of
machines in a station, how many stations there are and how many closed, the price, and the EU's
rule for stations. Section 07 puts the stack into Lecture 5's series hybrid and compares the
efficiency from the power plant to the wheel against the battery car. Section 08 wraps up and gives
the take-home exercises.
-->
