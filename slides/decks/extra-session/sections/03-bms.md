---
routeAlias: bms
layout: section
---

###### Section 03

# The BMS

Counting the charge and why the count drifts, resetting it from the open-circuit voltage, cell
imbalance and passive balancing, and the limits the battery management system enforces.

<!--
Section 03, the battery management system, the BMS. It is the electronics that watch every cell.
Four topics: counting the charge and why that count drifts; resetting the count from the
open-circuit voltage; cells that drift apart, and passive balancing; and the limits on temperature,
current and voltage that the BMS enforces.
-->

---
routeAlias: what-the-bms-does
skipInCut: true
---

## What the BMS does

<div class="grid grid-cols-2 gap-8">
<div>

**Measures**

- every series cell's voltage (96 on the Leaf)
- the pack current
- temperatures across the pack

**Estimates**

- state of charge, SoC
- state of health: capacity and resistance against new
- the power it can allow now, in and out

</div>
<div>

**Acts**

- opens the main contactors on a fault
- tells the inverter and the charger the current limits
- balances the cells
- asks for heating or cooling

**How it is built:** a monitoring chip per module (14–16 cells) measures and balances, and talks
over an isolated daisy chain to a pack controller.

**How well:** cell voltage to **±1.5 mV** (TI BQ79616) or **0.8 mV** (NXP MC33771C); China's
GB/T 38661 asks ≤ **10 mV** and ±**2 °C**.

**How safe:** "prevent thermal run-away" is an **ASIL D** goal, react within **800 ms**.

<div class="caption text-left">[TI-BQ79616], [NXP-MC33771C], [TI-SLVAE87], [IFX-AN1104] verified ·
[GBT-38661-2020] from a translator's excerpt</div>

</div>
</div>

<!--
The BMS in three verbs. It measures: the voltage of every series cell, 96 on the Leaf; the pack
current; and temperatures at several points in the pack. It estimates what it cannot measure: the
state of charge; the state of health, meaning how much capacity and how much extra resistance the
pack has against new; and the power it can allow right now, discharging and charging. And it acts:
it opens the main contactors if something is wrong, it tells the inverter and the charger how much
current they may draw or push, it balances the cells, and it asks the thermal system for heat or
cooling.

The bottom right says how it is built. Each module of 14 to 16 cells has a monitoring chip that
measures the cell voltages and temperatures and does the balancing; the chips talk over an isolated
daisy chain to one pack controller, which estimates the state of charge and drives the contactors.
That layout is described in TI's and Infineon's application notes.

How well does it measure? The monitoring chips claim plus or minus 1.5 millivolts for TI's
BQ79616 and 0.8 millivolts maximum error for NXP's MC33771C, from their product pages. China's
national BMS standard, GB/T 38661, asks for at most 10 millivolts on a cell voltage and plus or
minus 2 degrees; we have that standard only through a commercial translator's English excerpt, not
the official Chinese text, so treat it as reported.

And how safe? ISO 26262 rates hazards by automotive safety integrity level, ASIL, from A to D.
Infineon's application note makes "prevent thermal runaway from overvoltage, undervoltage,
overcurrent or overtemperature" an ASIL D safety goal: the BMS must detect the fault and open the
high-voltage circuit within a fault-tolerant time of 800 milliseconds. Infineon calls the note a
training example, not a blueprint; the ISO text itself was not read.
-->

---
routeAlias: coulomb-counting
---

## Coulomb counting, and why it drifts

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-start">
<div>

<div class="placeholder">

**Figure** `/figures/03-soc-drift.svg`

Formula plot, notebook: SoC error against time over 7 days for a 33 Ah Leaf cell. Line 1: a 50 mA
current-sensor offset, error growing straight at 3.6 %/day (derived, `bms.md` §2). Band 2: zero-mean
10 mA noise, error spread growing as √t — 0.054 % after 24 h on a 1.5 Ah cell [MOVASSAGH-2021],
scaled to 33 Ah. A dashed horizontal line at GB/T 38661's 5 %; dashed vertical lines where an OCV
reset (next slide) pulls the offset line back to zero.

</div>

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

<div class="caption text-left">offset: derived (`bms.md` §2) · noise: [MOVASSAGH-2021]</div>

</div>
</div>

<!--
Lecture 4's state of charge was the integral of the current: start at SoC0, subtract the charge
that has left, divided by the nominal charge Q nom. That is coulomb counting, and every BMS does it.

The trouble is that the integral integrates its own errors too. A small constant offset in the
current sensor becomes an error that grows linearly in time: the offset times the time, over Q nom.
A wrong starting value is carried forever. And a wrong Q nom scales every step: the pack loses
capacity as it ages, and a counter that still divides by the new capacity reads too high.

The figure, a formula plot to be drawn, shows the error of the count over a week, for one Leaf
cell of 33 ampere-hours. Across: days. Up: state-of-charge error in percent.

The straight line is an offset. A current sensor that reads 50 milliamperes too high, all the time,
adds 0.05 amperes times 24 hours, 1.2 ampere-hours a day, which is 3.6 percent of the cell, every
day, always in the same direction. That is arithmetic in the BMS note. In a little over a day it
uses up the 5 percent that China's standard allows; that standard is the dashed horizontal line.

The thin band is noise. Movassagh and colleagues worked out that zero-mean noise of 10 milliamperes
on a 1.5 ampere-hour cell spreads the error by only 0.054 percent after 24 hours, because noise
averages out; it grows with the square root of time. An offset does not average out. So the enemy is
the bias, and that is why the count needs a reset, the next slide; the vertical dashed lines are
where it happens.
-->

---
routeAlias: ocv-reset
---

## Resetting the count from the OCV

<div class="grid grid-cols-2 gap-8">
<div>

**After a rest**, *v*₁ has decayed and the terminal voltage **is** the OCV (section 02).

**Invert the curve:** SoC = OCV⁻¹(*v*).

**Works where the curve is steep.** NMC 811, 30 → 70 % SoC: 3.581 → 3.948 V, about
**9 mV per % SoC**.

**Fails where it is flat.** A **10 mV** error reads as **1.7 %** SoC on NMC, **6.8 %** on LFP.

</div>
<div>

**Rest needed:** at least **1 h**, or until the voltage moves **< 5 mV/h**. The Leaf cell after
60 s is still **9 mV** short of its 1 h value.

**With and without the reset** (TI bench test): coulomb counting alone **≈ 6 %** peak error; with
OCV correction and an impedance model **≈ 1 %**. GB/T 38661 allows **≤ 5 %**.

**Beyond the reset:** model-based estimators, such as Kalman filters, run the Thevenin cell beside
the count and correct it continuously.

<div class="caption text-left">NMC table: [CHEN-2020] derived · 10 mV: derived from [NEJAD-2016]
slopes · rest: [USABC-EV-R4], [ORNL-LEAF-ECM] · [TI-SLUAAR3] · [GBT-38661-2020] translator's
excerpt · method: [PLETT-2015]</div>

</div>
</div>

<!--
The drift needs a second, independent measurement, and the cell has one: its voltage. After the
car has stood for a while, the RC pair of section 02 has relaxed, v1 is zero, and the terminal
voltage equals the open-circuit voltage. Read it, invert the curve of section 02, and you have the
state of charge, with no memory of the past errors. The BMS resets its counter to that.

It works where the curve is steep. For the NMC cell, from 30 to 70 percent the voltage rises from
3.581 to 3.948 volts: about 9 millivolts per percent of charge. That is my arithmetic on the derived
table.

It fails where the curve is flat. Take the 10 millivolts China's standard allows as the voltage
error, and the slopes from Nejad's review on section 02: on the NMC cell, 10 millivolts reads as 1.7
percent of charge; on the LFP cell, as 6.8 percent. That is the note's arithmetic with an average
slope; on LFP's plateau itself the local slope is smaller and the error larger. So an LFP car's BMS
learns little from its voltage in the middle of the range.

How long is a rest? The USABC test manual counts an open-circuit reading as settled after at least
an hour, or when the voltage changes by less than 5 millivolts per hour. Oak Ridge's Leaf log shows
why: after one discharge step the cell voltage was still 9 millivolts short of its one-hour value
after a minute. For LFP, Nejad notes the hysteresis makes the rest longer still.

Does it help? Texas Instruments compared methods on a bench, for portable batteries, but the
mechanism is the same: counting alone peaked at about 6 percent error, their method with OCV
corrections and an impedance model at about 1 percent. And the 5 percent in China's GB/T 38661, the
only published requirement we found, again from a translator's excerpt.

Beyond the simple reset, model-based estimators such as Kalman filters run the Thevenin cell in
parallel with the count and correct it continuously from the voltage error, without waiting for a
rest. Plett's textbook is the reference for the method; I have no source that says which algorithm
a given production car uses.
-->

---
routeAlias: balancing
---

## Cells drift apart: passive balancing

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-center">
<div>

<div class="placeholder">

**Diagram** `/diagrams/03-passive-balancing.svg`

Four series cells drawn as bars filled to different SoC (e.g. 78, 80, 80, 83 %), each with a
bleed resistor and a switch across it; the highest cell's switch closed, its current drawn as an
arrow into the resistor as heat. Below: "charge stops when the fullest cell hits the CV limit;
discharge stops when the emptiest hits cutoff". Hand-drawn; SoC values illustrative (no source gives
an aged-pack spread; `bms.md` gap 5).

</div>

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
derived (`bms.md` §3)</div>

</div>
</div>

<!--
The diagram shows four cells in series, each drawn as a bar filled to its own state of charge. In
series, every cell carries the same current, but the cells are not identical. Rumpf and colleagues
measured 1100 fresh LFP cells: their capacities varied by 0.28 percent. With aging the spread grows,
and cells self-discharge at slightly different rates; for those we have no measured numbers. So over
months their states of charge spread apart. The numbers in the diagram are illustrative.

The pack is only as good as its extreme cells. When charging, the fullest cell reaches the voltage
limit first and the charge must stop, even though the others could take more. When discharging, the
emptiest cell reaches the cutoff first. Infineon's note says it in one line: the two most
unbalanced cells define how much of the pack can be used.

Passive balancing is the simple fix. Across each cell sits a resistor and a switch. Near the top of
the charge, the BMS closes the switch on the fullest cells and bleeds them down as heat, until all
the cells reach full together. The monitoring chips build the switches in: TI's BQ79616 balances at
240 milliamperes, NXP's MC33771C at 300, both from the makers' product pages. A third, Analog
Devices' LTC6813, is quoted at up to 200 milliamperes, but only in a search summary, unconfirmed.

How slow is that? Bleeding 1 percent of a 33 ampere-hour cell at 240 milliamperes takes 0.33 over
0.24, 1.4 hours, and dissipates about 0.9 watts per cell as heat in the chip, which is why the chips
pause balancing when they get hot. That is the note's arithmetic.

Active balancing moves charge from the fullest cells to the emptiest through a small converter
instead of burning it. A simulation review favors it, but the production chips above are all
passive.
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
| Thermal runaway, 21700 at 100 % SoC: onset / start | NMC **85.5 / 198.0 °C**; LFP **124.4 / 256.3 °C** | [OHNESEIT-2023] |
| Reaction to OV, UV, OC, OT | open the HV circuit within **800 ms** (ASIL D goal) | [IFX-AN1104] |

</div>

<!--
The limits the BMS enforces, with their sources. Read the table row by row.

Voltage. The Leaf's cell is rated from 2.50 to 4.20 volts, from Idaho's test report. The usable
window Gao and colleagues recommend for the first-generation Leaf is 10 to 90 percent, which is 3.2
to 4.1 volts.

Temperature and current together. The Panasonic NCR18650B datasheet allows charging only between
0 and 45 degrees, and below 10 degrees only at a quarter of the capacity per hour, 0.25C. The LG
M50LT datasheet says the same as a band: 0.3C between 0 and 25 degrees, 0.7C between 25 and 45.
The A123 LFP cell allows charging below zero only below 250 milliamperes, about a tenth of its
capacity per hour, charges up to 60 degrees and discharges from minus 30 to 60. Section 04 explains
why cold charging is limited: lithium plating.

Heat. Nissan's service literature, quoted by Idaho, pauses a charge when the pack is above 55
degrees.

Power. Idaho measured what the 2013 Leaf pack could deliver: 103.3 kilowatts for 30 seconds
discharging at 80 percent depth of discharge, and 80.5 kilowatts for 10 seconds charging at 20
percent. That 80.5 is the regen ceiling Lecture 4 used.

Why the limits matter: thermal runaway. Ohneseit and colleagues heated 21700 cells at full charge
in a calorimeter. The NMC cell started heating itself at 85.5 degrees and ran away at 198. The LFP
cell started at 124.4 and ran away at 256.3: LFP gives far more margin. And the last row: when the
BMS sees overvoltage, undervoltage, overcurrent or overtemperature, Infineon's example safety goal
says it must open the high-voltage circuit within 800 milliseconds.
-->
