---
routeAlias: bms
layout: section
---

###### Section 03

# The BMS

Counting the charge and why the count drifts, resetting it from the open-circuit voltage, cell
imbalance and passive balancing, and the limits the battery management system enforces.

<div class="zoom-crop mt-6" style="width: 21rem; height: 15rem; --zoom: 2">
<img src="/photos/03-bms-board.jpg" alt="A small green circuit board on white: a microcontroller, a terminal block, a ribbon header and two power transistors with heat tabs on the right edge, the cell-module measuring and balancing unit of a Czech battery management system."/>
</div>

<div class="caption">BMS cell board, MGM compro (CZ), cropped · Drazny, CC BY-SA 4.0</div>

<!--
The Thevenin cell says what a cell does. The BMS, the battery management system, has to know it
while it can measure only voltage, current and temperature. Every limit a charger obeys comes from
the BMS. This section links the cell to the plug: how the BMS counts the charge, corrects the count,
and keeps 96 cells in step.

*[show photo]* A BMS cell board from the Czech maker MGM compro. The two transistors on the right
edge are its balancing switches, on a later slide. Photograph by Drazny, Wikimedia Commons.
-->

---
routeAlias: what-the-bms-does
skipInCut: true
---

## What the BMS does

<div class="grid grid-cols-[1.7fr_1fr] gap-6 items-start">
<div>

![Block diagram of a modular BMS. Modules 1, 2 to n, each 14 to 16 cells in series with an AFE that measures cell voltage and temperature and balances. The AFEs connect over an isolated daisy chain (dashed blue) to the pack controller: SoC, limits, safety, ASIL D, safe state within 800 ms. The modules' high-voltage path (orange) runs to the contactors (BDU), which the pack controller opens on overvoltage, undervoltage, overcurrent or overtemperature; from the contactors the path splits to the inverter and the charger. A side note gives two AFEs: TI BQ79616, up to 16 cells, ±1.5 mV, balancing 240 mA; NXP MC33771C, 14 cells, 0.8 mV, balancing 300 mA.](/diagrams/03-bms-architecture.svg)

<div class="caption">[TI-BQ79616], [NXP-MC33771C], [TI-SLVAE87] (daisy chain), [IFX-AN1104] (ASIL D, FTTI ≤ 800 ms,
safe state) · verified · layout per <code>bms.md</code> §5.</div>

</div>
<div class="text-[0.9rem]">

**Measures** every series cell's voltage (96 on the Leaf), the pack current, temperatures.

**Estimates** SoC; state of health, capacity and resistance against new; the power it can allow
now, in and out.

**Acts:** current limits to the inverter and the charger; heating or cooling.

**Required:** China's GB/T 38661 asks ≤ **10 mV** and ±**2 °C**.

<div class="zoom-crop" style="width: 16rem; height: 12rem; --zoom: 2">
<img src="/photos/03-bms-board.jpg" alt="A small green circuit board on white: a microcontroller, a terminal block, a ribbon header and two power transistors with heat tabs on the right edge, the cell-module measuring and balancing unit of a Czech battery management system."/>
</div>

<div class="caption">BMS cell board, MGM compro (CZ), cropped · Drazny, CC BY-SA 4.0 · [GBT-38661-2020] from a
translator's excerpt</div>

</div>
</div>

<!--
The BMS has three jobs. It measures the voltage of every series cell, 96 on the Leaf, the pack
current, and temperatures across the pack. It estimates what it cannot measure: the state of charge,
SoC; the state of health, SoH, meaning how much capacity and extra resistance the pack has against
new; and the power it can allow right now, in and out. And it acts. On a fault it opens the main
contactors, the high-voltage switches. It tells the inverter and the charger their current limits,
balances the cells, and asks for heat or cooling.

*[show figure]* How it is built. Each module of 14 to 16 cells has a monitoring chip that measures
and balances its cells. The chips pass data along an isolated chain to one pack controller, which
runs the estimates and drives the contactors.

The side note gives how well it measures. The chips claim 1.5 millivolts for Texas Instruments' part
and 0.8 for NXP's. China's national BMS standard, GB/T 38661, asks for at most 10 millivolts and 2
degrees. We have it only as a translated excerpt, but it is the one published requirement we found.

*[ask]* Why measure a cell voltage to a millivolt or two, when a cell spans more than a volt?
*[pause]* Two slides on, on an LFP cell, 10 millivolts is worth about 7 percent of charge.

And safety: the standard ISO 26262 grades hazards from ASIL A, the mildest, to D. In Infineon's
worked example, "prevent thermal runaway" is an ASIL D goal. On overvoltage, undervoltage,
overcurrent or overtemperature, the BMS must open the high-voltage circuit within 800 milliseconds.
It is a training example, not a real product, but it shows the scale: under a second.
-->

---
routeAlias: coulomb-counting
---

## Coulomb counting, and why it drifts

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-start">
<div>

<img src="/figures/03-soc-drift.svg" alt="SoC error in percent against time, 0 to 7 days, for a 33 Ah cell. A 50 mA current-sensor offset grows the error at 3.6 % per day; with OCV resets on days 2, 4 and 6, the dashed vertical lines, it saws between 0 and 7.3 %, crossing the dashed 5 % line of GB/T 38661 1.4 days after each reset. Never reset, dotted, it leaves the top of the plot on day 4 and would reach 25 % on day 7. Zero-mean 10 mA noise spreads the error by only ±0.0065 % after 7 days, a band too thin to see on the zero line."/>

<div class="caption">Formula plot · offset: derived (<code>bms.md</code> §2) · noise: σ = 0.0544 % at 24 h on 1.5 A·h
[MOVASSAGH-2021], scaled to 33 A·h, growing as √t · reset days: illustrative.</div>

</div>
<div>

$$
\mathrm{SoC}(t) = \mathrm{SoC}_0 - \frac{1}{Q_\text{nom}} \int_0^t i\, dt
$$

What the integral also integrates:

- a **sensor offset** *i*<sub>off</sub>: an error growing as *i*<sub>off</sub> *t* / *Q*<sub>nom</sub>
- a wrong **SoC₀**: carried forever
- a wrong **Q<sub>nom</sub>**: the pack ages, the count does not know

**Offset vs noise:** 50 mA offset on a 33 Ah cell → 1.2 Ah = **3.6 % per day**, one direction.
Zero-mean 10 mA noise on a 1.5 Ah cell: **0.054 %** after 24 h.

<div class="caption text-left">offset: derived (<code>bms.md</code> §2) · noise: [MOVASSAGH-2021]</div>

</div>
</div>

<!--
The first job: state of charge. Lecture 4's model counted it, and so does every BMS. But adding up
the current also adds up its errors. A sensor offset grows with time. A wrong start stays forever.
An aged pack makes the count read high.

*[ask]* A current sensor reads 50 milliamperes high on a 33 ampere-hour Leaf cell. The Chinese
standard allows 5 percent error. How long until you are 5 percent off? *[pause]* 50 milliamperes for
a day is 1.2 ampere-hours, 3.6 percent. So about 1.4 days: the straight line.

Noise averages out. An offset never does. The count needs a second measurement to reset it.
-->

---
routeAlias: ocv-reset
---

## Resetting the count from the OCV

<div class="grid grid-cols-[1.15fr_1fr] gap-6 items-start">
<div>

<img src="/figures/02-ocv-soc.svg" alt="Voltage per cell against state of charge, 0 to 100 percent. Solid: the NMC 811 cell (LG M50) OCV, derived from PyBaMM Chen2020: 2.500 V at 0 %, 3.296 at 10 %, 3.581 at 30 %, 3.751 at 50 %, 3.948 at 70 %, 4.097 at 90 % and 4.200 at 100 %. Dashed: the 2013 Leaf's loaded voltage per series element at C/3, INL: 4.17 V at 100 %, 3.88 at 47 %, 3.61 at 12 %, 3.08 at 3 % and 2.49 at 0 %. The 10 to 90 % window is shaded."/>

<div class="caption">NMC 811: [CHEN-2020] via PyBaMM, derived · Leaf: [INL-5045] Fig. 1, read by eye (±0.03 V),
loaded, not OCV.</div>

</div>
<div class="text-[0.9rem]">

**After a rest**, *v*₁ has decayed and the terminal voltage **is** the OCV: SoC = OCV⁻¹(*v*).

**Works where the curve is steep.** NMC 811, 30 → 70 % SoC: 3.581 → 3.948 V, about
**9 mV per % SoC**.

**Fails where it is flat.** A **10 mV** error reads as **1.7 %** SoC on NMC, **6.8 %** on LFP.

**Rest needed:** at least **1 h**, or until the voltage moves **< 5 mV/h**. The Leaf cell after
60 s is still **9 mV** short of its 1 h value.

**TI bench test:** coulomb counting alone **≈ 6 %** peak error; with OCV correction and an
impedance model **≈ 1 %**. GB/T 38661 allows **≤ 5 %**.

<div class="caption text-left">10 mV: derived from [NEJAD-2016] slopes · rest: [USABC-EV-R4],
[ORNL-LEAF-ECM] · [TI-SLUAAR3] · [GBT-38661-2020] translator's excerpt · Kalman filters:
[PLETT-2015]</div>

</div>
</div>

<!--
The second measurement is the cell's own voltage. *[show figure]* After the car has stood, the RC
pair has settled. The terminal voltage is then the open-circuit voltage, OCV, a known curve of the
charge. Read the voltage, look up the charge, reset the counter.

It works where the curve is steep: about 9 millivolts per percent on NMC between 30 and 70 percent.

*[ask]* LFP's curve is about four times flatter. What does a 10 millivolt error cost? *[pause]* 1.7
percent on NMC. 6.8 on LFP, more than the whole allowance from one reading.

The rest takes about an hour, so the reset happens while parked. In a Texas Instruments test,
counting alone peaked at 6 percent error. With voltage corrections, about 1.
-->

---
routeAlias: balancing
---

## Cells drift apart: passive balancing

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-center">
<div>

![Four cells in series between the pack's plus and minus terminals, each drawn as a bar filled to its state of charge: 80, 83, 78 and 80 percent from the top. Across each cell sits a bleed resistor in series with a switch. Three switches are open; on cell 2, the fullest at 83 percent, the switch is closed and an arrow shows its current leaving the cell through the resistor, which glows red and gives off heat. Below: charge stops when the fullest cell hits the CV limit; discharge stops when the emptiest hits cutoff.](/diagrams/03-passive-balancing.svg)

<div class="caption">SoC values illustrative</div>

</div>
<div>

**Same current, different cells.** Even fresh, 1100 LFP cells varied **0.28 %** in capacity; aging
widens it.

**The string is as good as its extreme cells:**
the fullest stops the charge, the emptiest stops the discharge.

**Passive balancing:** bleed the fullest cells through a resistor, near the top of charge.

- balancing current: **240 mA** (TI BQ79616), **300 mA** (NXP MC33771C)
- 1 % of a 33 Ah cell at 240 mA: **1.4 h**; **0.89 W** of heat per cell

**Active balancing** moves charge between cells instead; the chips above are passive.

<div class="caption text-left">[RUMPF-2017], [TI-BQ79616], [NXP-MC33771C] verified · hours, watts:
derived (<code>bms.md</code> §3)</div>

</div>
</div>

<!--
The third job. In series every cell carries the same current, but no two cells are equal. Even fresh
LFP cells varied 0.28 percent in capacity, and aging widens that.

*[show figure]* The fullest cell stops the charge. The emptiest stops the discharge. Passive
balancing drains the fullest cells through a resistor, near the top of the charge.

*[ask]* How long to drain 1 percent of a 33 ampere-hour cell at 240 milliamperes? *[pause]* 1.4
hours, and almost a watt of heat per cell. Balancing is slow; it happens on the charger.

*[ask]* Back to section 01's question: which chemistry for the city bus? *[pause]* LFP. It is
cheaper per kilowatt-hour, and the bus has room for the extra mass. The cost is the flat voltage
curve, which makes the BMS's job harder, as we have just seen.

What the BMS does with all this is enforce limits, and those limits are what a fast charger obeys.
-->

---
routeAlias: bms-limits
skipInCut: true
---

## The limits: voltage, current, temperature

<div class="tight">

| Limit | Value | Source |
|---|---|---|
| Cell voltage, Leaf AESC cell | **2.50–4.20 V** | [INL-5045] |
| Usable window, Leaf Gen 1 | 10–90 % SoC = **3.2–4.1 V** | [GAO-2024] |
| Charge temperature, NCR18650B | **0 to +45 °C**; below 10 °C at **0.25C** | [PAN-NCR18650B] |
| Charge current by temperature, LG M50LT | **0.3C** at 0–25 °C, **0.7C** at 25–45 °C | [LG-M50LT-2020] |
| LFP cell (A123 26650) | charge 0–60 °C, **< 250 mA** below 0 °C; discharge −30 to 60 °C | [LW-26650-2022] |
| Leaf pack, charging | pauses above **55 °C** | [INL-DCFC-2015] |
| Leaf pack power, 2013 | **103.3 kW** discharge (30 s), **80.5 kW** charge (10 s) | [INL-5045] |
| Reaction to OV, UV, OC, OT | open the HV circuit within **800 ms** (ASIL D goal) | [IFX-AN1104] |

</div>

<img src="/figures/03-runaway.svg" style="height: 16rem" alt="For four 21700 cells at 100 % SoC, a line from self-heating onset (circle) to start of thermal runaway (diamond), with ±1σ bars: NMC 85.5 to 198.0 °C, NCA-HE I 95.3 to 203.1, NCA-HP 95.5 to 202.6 (blue), LFP 124.4 to 256.3 (orange)."/>

<div class="caption">Accelerating rate calorimetry, Ohneseit et al. 2023, Table 10 [OHNESEIT-2023], verified ·
onset: self-heating &gt; 0.02 °C/min.</div>

<!--
The limits the BMS enforces. The table is for reference. Three rows matter most.

The cold rows. The Panasonic cell may be charged only between 0 and 45 degrees, and below 10 degrees
only at a quarter of its capacity per hour. The LG cell allows 0.3C up to 25 degrees, 0.7C above.
The A123 LFP cell allows under 250 milliamperes below zero. Every chemistry charges slowly in the
cold. Section 04 says why.

The Leaf pack pauses charging above 55 degrees. That is the extreme case of rapidgate, the slowdown
we meet in section 04.

And thermal runaway, a cell heating itself out of control: the reason for all the other limits.
*[show figure]* Ohneseit and colleagues heated fully charged 21700 cells in a calorimeter, a box
that measures heat. The NMC cell started heating itself at 85.5 degrees and ran away at 198. The LFP
cell started at 124 and ran away at 256. About 40 degrees later to start, nearly 60 later to run
away. That is one more reason LFP suits the bus.

The power row links back. Idaho measured 80.5 kilowatts of charge for 10 seconds on the 2013 pack,
the regen limit you used in Lecture 4.

So the BMS sets the voltage, the current and the temperature a charger may use. Section 04 is what
happens when a charger pushes right up against them.
-->
