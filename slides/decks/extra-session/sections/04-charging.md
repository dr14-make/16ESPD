---
routeAlias: charging
layout: section
---

###### Section 04

# Charging

CC-CV at the cell, measured DC curves of the Leaf, a 400 V and an 800 V car, modes and connectors,
AC and DC losses, ISO 15118 and V2G, and the network in Czechia and the EU.

<!--
Section 04, charging, the longest section today. We start at one cell: constant current, then
constant voltage, and why the second phase exists. Then real cars: the Leaf on CHAdeMO with its
overheating problem, and a 400 volt and an 800 volt car. Then the modes and the connectors, where the
energy is lost on AC and on DC, the communication standard ISO 15118 with vehicle-to-grid, how fast
charging ages a battery, and finally how many chargers Czechia and the EU have.
-->

---
routeAlias: cc-cv
---

## CC-CV at the cell

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-start">
<div>

<img src="/figures/04-cc-cv.svg" alt="Three panels against time in minutes. Current: constant 16.55 A, 0.5C of 33.1 Ah, until 103 minutes, then decaying to the C/50 cutoff of 0.66 A at 120 minutes. Voltage: the terminal voltage rises from 3.32 V to 4.20 V at 103 minutes and holds there; the OCV, dashed, runs below it, 4.15 V at the switch to CV and 4.198 V at the end. SoC: from 10 % rising linearly to 95.6 % at the switch and 99.8 % at the end."/>

<div class="caption">Formula plot · the section 02 Leaf cell (R₀ 1.60 mΩ, R₁ 1.34 mΩ, τ₁ 25.7 s, 33.1 A·h;
[ORNL-LEAF-ECM] fit, derived) with the NMC 811 OCV curve · assumed: 0.5C from rest at 10 %,
CV 4.20 V, stop at C/50.</div>

</div>
<div class="text-[0.9rem]">

<div class="tight">

| Cell | CC | CV | End at |
|---|---|---|---|
| Panasonic NCR18650B, 3.25 Ah | ≤ 0.5C | **4.20 V** | 65 mA ≈ **C/50** |
| LG INR21700M50LT, 4.8 Ah, NMC 811 | 0.3C | **4.20 V** | 50 mA ≈ **C/96** |
| A123 ANR26650M1B, 2.5 Ah, LFP | 1.2C rec., 4C max | **3.6 V** | < 50 mA ≈ **C/50** |

</div>

1. **CC:** constant current until the terminal voltage reaches the limit.
2. **CV:** hold the voltage; the current decays.
3. **Stop** at the end current.

<div class="caption text-left">Datasheets [PAN-NCR18650B], [LG-M50LT-2020] (mirror copies),
[LW-26650-2022]; C-rates computed (`charging.md` §1)</div>

</div>
</div>

<!--
Every lithium-ion cell charges the same way: CC-CV, constant current then constant voltage. The
figure is a formula plot of the Thevenin cell from section 02 charging from 10 percent. Top panel:
the current. Middle: the terminal voltage, with the open-circuit voltage dashed. Bottom: the state
of charge. Across all three: time.

Step one, CC: the charger pushes a constant current, and the terminal voltage climbs. Step two,
CV: when the terminal voltage reaches the limit, the charger holds it there, and the current decays
by itself. Step three: when the current has fallen to the end value, the charge stops.

The table gives the numbers from three datasheets. The Panasonic NCR18650B, a 3.25 ampere-hour
cell: at most half its capacity per hour, 0.5C, up to 4.20 volts, ending at 65 milliamperes. That is
about C over 50, my arithmetic. The LG M50LT, an NMC 811 cell of 4.8 ampere-hours: 0.3C, 4.20 volts,
ending at 50 milliamperes, about C over 96. The A123 LFP cell: 1.2C recommended and up to 4C, to
3.6 volts, ending below 50 milliamperes, again about C over 50. Two of the three sheets are
third-party mirror copies, so they are verified but not from the maker's site.

Note the end current: all three stop between C over 50 and C over 100, not at the C over 20 that is
often quoted. And note LFP's lower voltage, 3.6 against 4.2.
-->

---
routeAlias: why-cv
---

## Why the CV phase exists

<div class="grid grid-cols-2 gap-8">
<div>

The limit applies to the **terminal** voltage:

$$
v = \mathrm{OCV} + R\, i \;\le\; v_\text{max}
$$

At the end of CC, *R i* reaches the limit while the OCV is still below it: the cell is **not
full**. Holding *v* lets *i* fall, so the OCV can rise to the limit.

**The anode's side:** a high current at high SoC drives the graphite below **0 V vs Li/Li⁺** —
**lithium plating**.

</div>
<div>

**The course Leaf at 50 kW** (96s2p, *R* ≈ 0.1 Ω):

- 4.2 V × 96 = **403 V** ceiling
- 50 kW at ≈ 350 V: *I* ≈ **143 A**
- *I R* ≈ **14 V** pack, **0.15 V** per cell
- CC ends at OCV ≈ 389 V, **≈ 4.05 V per cell**
- at C/20, 3.3 A: *I R* = 0.33 V pack — the cell is at its OCV

<div class="caption text-left">Computed in `charging.md` §1 · plating: [DAS-2024]</div>

</div>
</div>

<!--
Why not just push constant current until the cell is full? Because the limit is on the terminal
voltage, and the terminal voltage while charging is the open-circuit voltage plus R times i. The
current pushes the terminal voltage up by R i. So the terminal voltage hits the limit while the
open-circuit voltage, the one that tells you the charge, is still below it: the cell is not full.
If the charger now holds the voltage, the current falls, R i shrinks, and the open-circuit voltage
can climb up to the limit without the terminal voltage ever passing it.

There is a second reason inside the cell. Pushing a large current into a nearly full cell drives
the graphite anode's potential down; below 0 volts against lithium, lithium metal plates onto the
anode instead of slipping into it. That is lithium plating; Das and Shrotriya's 2024 review
describes it. Plated lithium is lost capacity, and in the extreme it grows dendrites that can pierce
the separator.

The right column puts numbers on our course Leaf. 96 cells in series at 4.2 volts gives a 403 volt
ceiling. At 50 kilowatts and about 350 volts the current is about 143 amperes. Times 0.1 ohm, that
is 14 volts across the pack's resistance, 0.15 volts per cell. So constant current must stop when
the open-circuit voltage is about 389 volts, 4.05 volts per cell, well short of full. At a current
of C over 20, 3.3 amperes, the drop is only a third of a volt across the whole pack: the cell is
effectively at its open-circuit voltage. All of this is arithmetic in the charging note, and it
assumes the Leaf's cell has the same 4.2 volt ceiling as the cells on the last slide; there is no
AESC datasheet in our notes.
-->

---
routeAlias: cold-and-plating
skipInCut: true
---

## Cold and fast: why the charger slows down

<div class="grid grid-cols-2 gap-8">
<div>

**Plating is likely** at **> 1C** or near **0 °C**: diffusion in the graphite slows, and the anode
potential falls below 0 V vs Li/Li⁺.

**Normal intercalation** sits at **65–200 mV** vs Li/Li⁺.

**Causes:** high CC-CV rates, low temperature, overcharging around 4.5 V.

**The worst case:** dendrites through the separator, an internal short, thermal runaway.

<div class="caption text-left">[DAS-2024], verified</div>

</div>
<div>

**What the datasheets do about it:**

- NCR18650B: below 10 °C, **0.25C**
- M50LT: **0.3C** at 0–25 °C, **0.7C** at 25–45 °C
- A123 LFP: below 0 °C, **< 250 mA**

**What the car does:** preconditions the pack on the way to a fast charger.

<div class="caption text-left">[PAN-NCR18650B], [LG-M50LT-2020], [LW-26650-2022]; preconditioning:
[ADAC-LADEVERLUST-2026]</div>

</div>
</div>

<!--
This slide says why the charge limits of section 03 depend on temperature. From Das and
Shrotriya's review: lithium plating typically appears above a charge rate of 1C or near 0 degrees.
In the cold, lithium diffuses more slowly inside the graphite, ions pile up at its surface, and the
local anode potential falls below 0 volts against lithium. In normal operation it sits 65 to 200
millivolts above. The review's list of causes: high charging rates, low temperature, and
overcharging to around 4.5 volts. The worst case is dendrites through the separator, an internal
short, and thermal runaway.

On the right, what the datasheets do about it, the numbers from section 03 again: a quarter C below
10 degrees for the Panasonic cell, 0.3C below 25 degrees for the LG cell, under 250 milliamperes
below zero for the A123 LFP cell. And what the car does: it heats the pack on the way to a fast
charger, preconditioning. ADAC found that this saves time at the charger, but not energy; the next
slides come back to it.
-->

---
routeAlias: leaf-chademo
---

## The Leaf on CHAdeMO, and rapidgate

<div class="grid grid-cols-[1.3fr_1fr] gap-8 items-start">
<div>

<img src="/figures/04-leaf-chademo.svg" alt="Charging power in kW against state of charge for the Nissan Leaf 40 kWh on CHAdeMO, Fastned data: 42.2 kW at 17 %, 43.1 at 20 %, 44.8 at 50 %, a peak of 45.63 at 57 and 60 %, then 32.75 at 70 %, 26.03 at 80 % and 20.17 at 90 %."/>

<div class="caption">Fastned, one charge, pack about 30 °C: the 10 % points, first point and peak of its per-1 %
data, joined by straight lines.</div>

</div>
<div class="text-[0.9rem]">

**One charge, warm enough:** **46 kW** peak, **10–80 % in 43 min**, 40 kW average.

**Rapidgate:** the air-cooled pack **throttled above 32 °C**. At a 41 °C pack, 70 % took 54 min
(old software) → just under 40 min (new).

**Why:** no active cooling. Per charge, the pack warmed **6.5 °C** on 50 kW DC vs **2.9 °C** on AC;
the next charge starts warmer.

**The fix:** the 3rd-generation Leaf has a **liquid-cooled** pack, CCS in Europe, up to 150 kW.

<div class="caption text-left">[EVDB-LEAF40] and [CT-RAPIDGATE-2019], secondary · [INL-DCFC-2015],
[NISSAN-LEAF3-2025], verified</div>

</div>
</div>

<!--
Our reference car, the 40 kilowatt-hour Leaf, on a CHAdeMO fast charger. The figure is Fastned's
own measured curve, redrawn from the numbers in their web page. Across: state of charge in percent.
Up: charging power in kilowatts. Fastned's data run from 17 to 92 percent, one value per percent,
and they say it is one charge on a pack at about 30 degrees.

The curve is flat at 43 to 46 kilowatts up to 60 percent; the peak is 45.6. Then it steps down: 33
kilowatts at 70 percent, 26 at 80, 20 at 90. That step-down is the constant-voltage logic of the
last two slides, at pack level. EV Database, an aggregator, so reported and secondary, gives 46
kilowatts peak and 10 to 80 percent in 43 minutes, 40 kilowatts on average.

Now rapidgate. CleanTechnica, reporting Bjørn Nyland's test, so again secondary: the 40
kilowatt-hour Leaf throttled DC charging whenever its pack was above 32 degrees. With the pack at 41
degrees, the old software needed 54 minutes to add 70 percent from near empty; a software update
cut that to just under 40.

Why does the Leaf overheat when other cars do not? Its pack has no active cooling. Idaho measured it
on the 2012 Leaf, with the same air-cooled concept: on average the pack warmed 6.5 degrees per 50
kilowatt DC charge, against 2.9 on AC. With no cooling, the heat of one charge is still there at the
next one, so on a long trip the second and third fast charge start hot and get throttled.

Nissan's fix is the third-generation Leaf of 2025: a liquid-cooled pack with thermal conditioning,
CCS in Europe instead of CHAdeMO, and up to 150 kilowatts.
-->

---
routeAlias: three-curves
---

## A 400 V and an 800 V car

<div class="grid grid-cols-[1.3fr_1fr] gap-6 items-start">
<div>

<img src="/figures/04-dc-curves.svg" alt="Charging power in kW against state of charge, Fastned data at about 30 °C. Hyundai IONIQ 5 84 kWh, 800 V: 203 kW at 10 %, 238 at 20 %, a peak of 263.6 at 51 %, 201 at 60 %, 81 at 80 % and 67 at 82 %. Tesla Model Y LR 2025+, 400 V: 231 at 8 %, 182 at 20 %, 105 at 50 %, 48 at 80 % and 34 at 90 %. VW ID.3 Pro S 77 kWh, 400 V: 175 at 10 %, a peak of 179 at 18 %, 101 at 50 %, 69 at 80 % and 46 at 89 %. Nissan Leaf 40 kWh: 42 to 46 kW up to 60 %, 26 at 80 % and 20 at 90 %."/>

<div class="caption">[FASTNED-CURVES]: each series' 10 % points, first and last point and peak, joined by straight
lines.</div>

</div>
<div class="text-[0.85rem]">

<div class="tight">

| kW at SoC | 20 % | 50 % | 80 % |
|---|---:|---:|---:|
| ID.3 Pro S, 400 V | 175 | 101 | 69 |
| Model Y LR, 400 V | 182 | 105 | 48 |
| IONIQ 5 84 kWh, 800 V | 238 | 263 | 81 |
| Leaf 40 kWh | 43 | 45 | 26 |

</div>

**10–80 %:**

- IONIQ 5: **18 min**, 196 kW average, 263 kW peak
- Taycan 2024: **18 min** (37 min before), 320 kW peak
- Model Y LR: **27 min**, 124 kW average, 250 kW peak
- ID.3 Pro S: **28 min**, 120 kW average, 175 kW peak

<div class="caption text-left">Curves: [FASTNED-CURVES], verified · times: [HYU-EU-CT],
[POR-TAYCAN-2024] verified; [EVDB-IONIQ5], [EVDB-MY-2025], [EVDB-ID3-2024] secondary</div>

</div>
</div>

<!--
Three modern cars on the same axes, again Fastned's own data at about 30 degrees, with the Leaf
for scale. Across: state of charge. Up: charging power in kilowatts.

The table reads three points off each curve. At 20 percent the two 400 volt cars are fastest
early: the ID.3 at 175 kilowatts, the Model Y at 182. By 50 percent both have fallen to about 100.
By 80 percent, 69 and 48. The 800 volt IONIQ 5 does the opposite: 238 at 20 percent, rising to its
peak of 263 at about 50 percent, and only then falling, to 81 at 80 percent. The Leaf stays near
45 throughout and drops to 26.

So the shape, not the peak, decides the time. The list below the table gives the time from 10 to 80
percent. IONIQ 5: 18 minutes, from Hyundai's own page, verified; the 196 kilowatt average is from EV
Database, secondary. The 2024 Porsche Taycan, also 800 volts: 18 minutes, down from 37 for the first
generation, from Porsche's newsroom. Model Y: 27 minutes at 124 kilowatts average, with a 250
kilowatt peak. ID.3: 28 minutes at 120 average. The last two are reported by EV Database,
secondary. The Model Y has nearly the IONIQ's peak, but half its average.

One caveat on the figure: Fastned's Model Y page states 250 kilowatts, but its own data peak at 231
at 8 percent; the real peak is below 8 percent, outside the data.
-->

---
routeAlias: why-800v
---

## Why 800 V charges faster

<div class="grid grid-cols-2 gap-8">
<div>

$$
P = U\, I, \qquad P_\text{loss} = I^2 R
$$

The current is capped by the **cable and contacts**, not the charger's electronics.

| At 500 A | Power |
|---|---:|
| 400 V | **200 kW** |
| 800 V | **400 kW** |

Same power at twice the voltage: half the current, **a quarter of the I²R loss** in cable, contacts
and pack.

<div class="caption text-left">Computed (`charging.md` §6)</div>

</div>
<div>

**Cable limits:** liquid-cooled CCS2 cable **500 A** permanent, 700 A boost, 1000 V; uncooled about
200–250 A.

**In-vehicle DC loss at 23 °C:** IONIQ 6 (800 V) **1 %**; Model Y, ID.3 **3 %**.

**But on a slow charger:** IONIQ 5 84 kWh on 50 kW DC — **76 min** for 10–80 %.

**800 V car at a 400 V charger:** E-GMP boosts 400 → 800 V with the motor and inverter.

<div class="caption text-left">[PHX-HPC] search summary · [ADAC-LADEVERLUST-2026], [HYU-EU-CT],
[HMG-EGMP-2022] verified</div>

</div>
</div>

<!--
Why does 800 volts win? Charging power is voltage times current. The current is limited by the
cable and the connector contacts heating up, by I squared R, not by the charger's power
electronics. So at a given current limit, twice the voltage is twice the power. The table, my
arithmetic from the charging note: at a 500 ampere cable limit, a 400 volt car gets 200
kilowatts, an 800 volt car 400. Or, turned around: for the same power, twice the voltage means half
the current, and a quarter of the I squared R loss, in the cable, the contacts and the pack itself.

The right column grounds it. The 500 ampere figure is a liquid-cooled CCS2 cable from Phoenix
Contact: 500 amperes permanent, 700 in boost, 1000 volts. We have that only as a search summary,
so it is reported, not checked. Without liquid cooling, cables manage about 200 to 250 amperes,
also a search summary.

ADAC measured the loss inside the car on DC at 23 degrees: 1 percent for the 800 volt IONIQ 6, 3
percent for the 400 volt Model Y and ID.3.

But 800 volts helps only where the charger can deliver. Hyundai's own page: the IONIQ 5 84 takes 76
minutes from 10 to 80 percent on a 50 kilowatt charger, against 18 on a 350 kilowatt one. And an
800 volt car at an older 400 volt charger needs a boost converter. Hyundai's E-GMP platform uses
the drive motor and its inverter to step 400 up to 800 volts.
-->

---
routeAlias: modes-and-connectors
---

## Modes, connectors and the on-board charger

<div class="grid grid-cols-[1.25fr_1fr] gap-6">
<div>

<div class="tight">

| Mode | What | Limits |
|---|---|---|
| 1 | AC, plain socket, no communication | ≤ 16 A; restricted in many countries (search summary) |
| 2 | AC, socket + in-cable box (IC-CPD) | **≤ 32 A**, ≤ 250 V 1-ph / ≤ 480 V 3-ph |
| 3 | AC, wallbox or post, control pilot | Type 2 coupler **≤ 63 A 3-ph**, ≤ 480 V |
| 4 | DC, off-board charger, bypasses the OBC | CCS2 in the EU |

</div>

<div class="caption text-left">[IEC-62752-2016], [IEC-62196-2-2022] scopes, verified (preview)</div>

</div>
<div>

**AC goes through the car's on-board charger** (230 V phase):

| Supply | Power |
|---|---:|
| 1 × 16 A | 3.7 kW |
| 1 × 32 A | 7.4 kW |
| 3 × 16 A | **11 kW** |
| 3 × 32 A | 22 kW |

The ID.3, Model Y, IONIQ 5: **11 kW**. The old Leaf: **3.6 or 6.6 kW**, one phase — also on a 22 kW
post.

</div>
</div>

<!--
The charging modes from IEC 61851. Mode 1: AC from a plain socket with no communication; usually
quoted as up to 16 amperes and restricted in many countries, but that comes from a search summary,
because the standard's clause itself was not readable. Mode 2: AC from a socket through a control
and protection box in the cable; the IEC 62752 scope limits it to 32 amperes, 250 volts single-phase
or 480 three-phase. Mode 3: AC from a dedicated wallbox or post, which talks to the car over the
control pilot wire; the Type 2 coupler standard caps it at 63 amperes three-phase at 480 volts.
Mode 4: DC from a charger outside the car, which bypasses the car's own charger. In the EU the DC
connector is CCS2, Type 2 with two DC pins added below.

On AC, the car's own on-board charger, the OBC, turns AC into DC, and its rating sets the power. The
table is my arithmetic at 230 volts per phase: 16 amperes on one phase is 3.7 kilowatts, 32 amperes
7.4, three phases at 16 amperes 11, three at 32 amperes 22. The three modern cars have 11 kilowatt
chargers. The 40 kilowatt-hour Leaf has a single-phase 3.6 or 6.6 kilowatt charger, so even on a 22
kilowatt public post it charges at 3.6 or 6.6.
-->

---
routeAlias: connectors-elsewhere
skipInCut: true
---

## Connectors beyond CCS2

<div class="tight">

| Connector | Where | Rating |
|---|---|---|
| **CHAdeMO** (2017 spec) | Japan; old Leaf in Europe | 100 kW continuous, 150–200 kW peak, 400 A × 500 V |
| **ChaoJi / CHAdeMO 3.0** | Japan, China, with GB/T | up to 600 A, 1–1.5 kV, 500–900 kW |
| **GB/T 20234.3-2023** | China | ≤ 1,500 V DC, ≤ 800 A (search summary) |
| **NACS / SAE J3400** | North America | DC or 1-ph AC on the same two pins; V/A not on SAE's page |
| **MCS / SAE J3271** | trucks | 1,250 V × 3,000 A = **3.75 MW** |

</div>

**In Europe CHAdeMO is fading:** the 3rd-generation Leaf takes CCS in Europe, NACS in North America.

<div class="caption text-left">[CHADEMO-HP], [SAE-J3400], [SAE-J3271], [CHARIN-MCS],
[NISSAN-LEAF3-2025] verified; MW computed (`charging.md` §3)</div>

<!--
The connectors outside the EU's CCS2, for reference. CHAdeMO, the Japanese standard the old Leaf
uses: the 2017 high-power spec runs 100 kilowatts continuous and 150 to 200 peak, at 400 amperes and
500 volts. Its successor, ChaoJi or CHAdeMO 3.0, developed with China: up to 600 amperes, 1 to 1.5
kilovolts, 500 to 900 kilowatts. China's own GB/T DC coupler of 2023: up to 1500 volts and 800
amperes, but that is a search summary. NACS, Tesla's connector, standardized as SAE J3400 for North
America: one hand-sized coupler that carries DC or single-phase AC on the same two pins; SAE's page
gives no rating. And MCS, the megawatt charging system for trucks: CharIN recommends 1250 volts and
3000 amperes, which multiplies to 3.75 megawatts.

In Europe CHAdeMO is on its way out: even Nissan's new Leaf takes CCS in Europe and NACS in North
America, and keeps CHAdeMO only in Japan.
-->

---
routeAlias: charging-losses
---

## AC and DC: where the energy is lost

<div class="grid grid-cols-2 gap-8">
<div>

**AC, grid to battery:**

<div class="tight">

| | 2.3 kW socket | 11 kW wallbox |
|---|---:|---:|
| Mercedes CLA 350 | 24.2 % | 6.9 % |
| Renault R5 | 13.7 % | 5.1 % |
| Tesla Model Y | 12.7 % | 6.1 % |
| Volvo EX30 | 14.2 % | 7.0 % |
| VW ID.7 | 15.3 % | 6.9 % |

</div>

Lowest for every car at 11 or 22 kW: the car's fixed loads run for hours on a slow charge.

</div>
<div>

**DC, inside the car:**

<div class="tight">

| | 23 °C | 0 °C, precond. | 0 °C, not |
|---|---:|---:|---:|
| IONIQ 6 (800 V) | 1 % | 1 % | 6 % |
| Mégane E-Tech | 4 % | 6 % | 8 % |
| Model Y | 3 % | 4 % | 10 % |
| ID.3 | 3 % | 5 % | 7 % |

</div>

**DC total: 5–15 %**, the charger itself about 3 %. Heating the pack at the charger: **+2–8 %**.

</div>
</div>

<div class="caption">ADAC, Aug 2026 [ADAC-LADEVERLUST-2026], verified (`charging.md` §4)</div>

<!--
ADAC's 2026 measurements, in two tables. Left: AC losses from the grid into the battery, for five
current cars, at a 2.3 kilowatt household socket and at an 11 kilowatt wallbox. At the socket the
losses run from 12.7 percent for the Model Y to 24.2 percent for the Mercedes CLA. At the wallbox
they fall to 5.1 to 7.0 percent. ADAC found the lowest losses for every car at 11 or 22 kilowatts.
The reason the data suggest, though ADAC does not say it in so many words: the car's control units,
pumps and BMS draw a fixed power for as long as the charge lasts, and on a slow socket that is many
hours.

Right: DC losses inside the car only, at 23 degrees, at 0 degrees with the pack preconditioned, and
at 0 degrees without. Warm: 1 percent for the 800 volt IONIQ 6, 3 to 4 for the others. Cold and not
preconditioned: 6 to 10 percent. Adding the charger's own conversion, about 3 percent on average,
ADAC puts total DC losses at 5 to 15 percent. Heating the battery at the charger cost another 2 to 8
percent.

For the course: Argonne measured the 2013 Leaf's on-board charger at 86 to 87 percent, the high end
of these AC losses; today's cars reach 93 to 95 percent at 11 kilowatts.
-->

---
routeAlias: iso-15118-v2g
skipInCut: true
---

## ISO 15118, Plug & Charge and V2G

<div class="grid grid-cols-2 gap-8">
<div>

**The car talks to the charger** over the control pilot: HomePlug Green PHY powerline, 2–30 MHz
(search summary). Most CCS chargers in service still speak DIN SPEC 70121.

**ISO 15118-20 (2022)** adds the messages for **bidirectional** power transfer.

**AFIR, as amended by Reg. 2025/656:**

- new or renovated public AC and DC points from **8 Jan 2026**: ISO 15118 parts 1–5
- from **1 Jan 2027**: **ISO 15118-20** at every one
- Plug & Charge stays optional for operators

</div>
<div>

**V2G on the road: Renault 5, France (Oct 2024)**

- bidirectional **on-board charger**: AC V2G, the car's OBC is the inverter
- PowerBox wallbox 7–22 kW
- "On average, the cost of charging is cut by half"

**The new Leaf** is V2G-compatible in Europe.

<div class="caption text-left">[ISO-15118-20], [EU-2025-656], [TMH-2024], [RENAULT-V2G-2023],
[NISSAN-LEAF3-2025] verified</div>

</div>
</div>

<!--
A modern charger and car talk to each other. The signal rides on the control pilot wire as
powerline communication, HomePlug Green PHY in the 2 to 30 megahertz band; that detail is a search
summary. Most CCS chargers in service still speak the older DIN SPEC 70121, a DC-only protocol on
the same physical layer.

ISO 15118-20, published in 2022, defines the messages and the sequence for bidirectional power
transfer: the car can also feed the grid. The EU made it mandatory through an amendment of AFIR, the
alternative fuels infrastructure regulation: Delegated Regulation 2025/656. From 8 January 2026,
every newly installed or renovated public AC or DC point must support ISO 15118 parts 1 to 5. From 1
January 2027, every one must support part 20. Plug and Charge, where the car authenticates itself
and you need no card or app, stays optional for the operator. Existing chargers are exempt.

On the right, vehicle-to-grid in practice: Renault and Mobilize launched it in France in October
2024 with the Renault 5. The car's own on-board charger is bidirectional, so this is AC V2G: the
car's charger is the inverter, the wallbox is simple. The wallbox runs 7 to 22 kilowatts. Renault
says the cost of charging is cut by half on average; that is their claim. Nissan's new Leaf is
V2G-compatible in Europe too.
-->

---
routeAlias: degradation
skipInCut: true
---

## Does fast charging wear the battery?

<div class="grid grid-cols-2 gap-8">
<div>

**Fleet data, 22,700 EVs, 21 models (2026):**

- average degradation **2.3 %/yr**
- mostly > 100 kW DC: up to **3.0 %/yr**
- mostly AC: about **1.5 %/yr**
- hot regions: **+0.4 %/yr**
- worse only above 80 % of the time at very high or very low SoC

<div class="caption text-left">[GEOTAB-2026], verified</div>

</div>
<div>

**Controlled test, four 2012 Leafs, Phoenix, 50,000 mi:**

- 50 kW DC only: ≈ **27 %** capacity lost
- 3.3 kW AC only: ≈ **24 %**
- charged twice a day, in heat; DC packs under 46 °C for 95 % of the time

"the difference is small relative to the total capacity loss"

<div class="caption text-left">[INL-DCFC-2015], read from figure ±2 % and verified</div>

</div>
</div>

<!--
Does fast charging wear the battery out? Two sources.

On the left, Geotab's fleet data from January 2026: more than 22,700 electric cars of 21 models. The
average loss of capacity is 2.3 percent per year. Cars that mostly fast-charge above 100 kilowatts
lose up to 3.0 percent per year; cars charged mostly on AC about 1.5. Hot regions add about 0.4
percent per year. And the state of charge matters only at the extremes: degradation speeds up only
when a car spends more than 80 percent of its time very full or very empty.

On the right, Idaho's controlled experiment: four 2012 Leafs in Phoenix, two charged only on 50
kilowatt DC, two only on 3.3 kilowatt AC, twice a day, in a hot climate. At 50,000 miles, read off
their figure to about 2 percent: the DC cars had lost about 27 percent of their capacity, the AC cars
about 24. Idaho's conclusion, quoted: the difference is small relative to the total loss. Their DC
packs spent 95 percent of the time below 46 degrees, which links back to rapidgate: heat, not the
plug, is what ages the pack.
-->

---
routeAlias: network
---

## The network: Czechia, the EU, and AFIR

<div class="grid grid-cols-[1.2fr_1fr] gap-6 items-start">
<div>

<img src="/figures/04-network.svg" alt="Stacked bars of public charging points by AFIR power class, AC in blues and DC in oranges, for 2024, 2025 and September 2026. Czechia: 6,359, 7,574 and 7,669 points, most of them AC 7.4 to 22 kW (4,369, 4,971 and 4,801); DC share 29.8, 33.1 and 36.1 %; share of 150 kW and above 9.1, 12.8 and 15.0 %. EU27, in thousands: 882,012, 1,061,890 and 1,176,554 points; DC share 15.7, 18.3 and 19.2 %; share of 150 kW and above 9.3, 11.2 and 12.0 %."/>

<div class="caption">European Alternative Fuels Observatory [EAFO-CZ], [EAFO-EU27]: counts verified, shares
computed; Sep 2026 is the latest update.</div>

</div>
<div class="text-[0.9rem]">

<div class="tight">

| End 2025 | Czechia | EU27 |
|---|---:|---:|
| Public points | **7,574** | **1,061,890** |
| DC | 2,510 (33.1 %) | 194,756 (18.3 %) |
| ≥ 150 kW | 967 (12.8 %) | 118,718 (11.2 %) |

</div>

Sep 2026, Czechia: 7,669 points, DC 36.1 %, ≥ 150 kW 15.0 %.

**AFIR Art. 3:** per registered BEV, **1.3 kW** of public power; on the TEN-T core network a pool
every **60 km**, ≥ **400 kW** with one ≥ 150 kW point by end 2025, **600 kW** by end 2027.

<div class="caption text-left">[EAFO-CZ], [EAFO-EU27] counts verified, shares computed ·
[EU-AFIR] verified</div>

</div>
</div>

<!--
How many public chargers are there? The figure stacks the public charging points by power class,
as the EU's Alternative Fuels Observatory counts them, for 2024, 2025 and September 2026: Czechia on
the left, the EU 27 on the right. From the bottom: slow AC, the ordinary 7.4 to 22 kilowatt AC posts
that are the bulk, fast AC, then the DC classes up to 350 kilowatts and above.

The table gives end 2025. Czechia: 7,574 public points; 2,510 of them DC, 33.1 percent; 967 of at
least 150 kilowatts, 12.8 percent. The EU 27: just over a million points; 18.3 percent DC; 11.2
percent at 150 kilowatts or more. The counts are the Observatory's; the shares are my arithmetic. So
Czechia has a larger DC share than the EU average. In absolute numbers it ranks 14th in the EU and
21st per capita, reported by fDrive from the transport research center CDV, secondary. By September 2026 Czechia had
barely grown, to 7,669 points, but the DC share rose to 36 percent.

At the bottom, the EU rule. AFIR, Article 3: for every battery-electric car registered, the country
must provide 1.3 kilowatts of public charging power. And along the core trans-European road network
there must be a charging pool every 60 kilometers in each direction: at least 400 kilowatts with one
point of 150 kilowatts by the end of 2025, and 600 kilowatts with two such points by the end of 2027.

That is the end of charging. Break: 15 minutes.
-->
