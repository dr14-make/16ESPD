---
routeAlias: charging
layout: section
---

###### Section 04

# Charging

CC-CV at the cell, measured DC curves of the Leaf, a 400 V and an 800 V car, modes and connectors,
AC and DC losses, and the network in Czechia and the EU.

<img class="hero" src="/photos/04-ionity.jpg" alt="A row of white IONITY high-power charging posts along a parking strip at a German motorway service area under a cloudy sky."/>

<div class="caption">IONITY, A4 Germany, 2025 · Андрей Романенко, CC BY-SA 4.0</div>

<!--
Now the first half of the sentence: how fast does the energy go back in? A 40 kilowatt-hour Leaf
needs 43 minutes from 10 to 80 percent on a fast charger. An IONIQ 5 needs 18. After the break we
meet a car that refills in about three minutes. What sets the charging time? Three things, in
this order. The cell's voltage limit, which forces the constant-voltage phase. Heat. And the cable
and the grid behind it. Then what is lost on the way, and how many chargers there are.

In the short version we skip the standards and battery wear. Both are in the handout.

*[show photo]* A motorway charging site in Germany: a row of IONITY chargers at Raststätte
Altenburger Land Nord on the A4. Photograph by Andrei Romanenko, Wikimedia Commons.
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
[LW-26650-2022]; C-rates computed (<code>charging.md</code> §1)</div>

</div>
</div>

<!--
Every lithium-ion cell charges the same way, called CC-CV: constant current, then constant
voltage.

*[show figure]* A formula plot of the Thevenin cell from section 02, charging from 10 percent. Top,
the current. Middle, the voltage at the cell's terminals, with the open-circuit voltage, OCV, dashed
below it. Bottom, the state of charge. Time in minutes runs across all three.

Step one, CC. The charger pushes a constant current, here half a C, and the terminal voltage climbs.
Step two, CV. At 4.20 volts the charger holds the voltage there, and the current falls by itself.
Look at the dashed line. At the switch the OCV is still below 4.2, and the cell is at 96 percent.
Step three: when the current has fallen to the end value, charging stops, at 99.8.

The table shows three real datasheets. Two nickel-based cells stop at 4.20 volts. One LFP cell
stops at 3.6 volts, the last row of section 01's table. Now look at the end current. All three stop
between C over 50 and C over 100. The often-quoted C over 20 is higher. The CV phase is
long, and its current is small.
-->

---
routeAlias: why-cv
---

## Why the CV phase exists

<div class="grid grid-cols-[1fr_1fr] gap-8 items-start">
<div>

The limit applies to the **terminal** voltage:

$$
v = \mathrm{OCV} + R\, i \;\le\; v_\text{max}
$$

At the end of CC, *R i* reaches the limit while the OCV is still below it: the cell is **not
full**. Holding *v* lets *i* fall, so the OCV can rise to the limit.

**The anode's side:** a high current at high SoC drives the graphite below **0 V vs Li/Li⁺** —
**lithium plating**.

<div class="caption text-left">Plating: [DAS-2024]</div>

</div>
<div>

<img src="/figures/04-cv-budget.svg" alt="Two stacked bars of pack terminal voltage on an axis that starts at 370 V, under a dashed red ceiling of 96 × 4.20 V = 403 V. End of CC at 50 kW, 143 A: OCV 389.0 V (4.05 V per cell) plus 14 V of I·R reaches the ceiling. At C/20, 3.3 A: OCV 402.7 V (4.19 V per cell) plus only 0.33 V of I·R."/>

<div class="caption">Computed for the course Leaf pack: 96s2p, R_pack ≈ 0.1 Ω, 50 kW at ≈ 350 V [<code>charging.md</code>
§1] · 4.2 V ceiling assumed for the AESC cell (no datasheet found) · axis starts at 370 V.</div>

</div>
</div>

<!--
Why not push constant current until the cell is full? Because the limit applies to the terminal
voltage. While charging, the terminal voltage is the OCV plus R times i. The current itself pushes
the terminal voltage up. It hits the limit while the OCV, which tells how full the cell is, is still
below it. Holding the voltage lets the current fall, so R i shrinks. The OCV can then
climb the rest of the way, and the terminal voltage never passes the limit.

There is a second reason, inside the cell. A large current into a nearly full cell pushes the
graphite anode's potential down. Below 0 volts against lithium, lithium metal coats the anode
instead of moving into it. This is plating. Plated lithium is lost capacity. At worst it grows
metal needles, dendrites, that can pierce the separator.

*[ask]* Now your Lecture 4 pack: 0.1 ohm, charging at 50 kilowatts at about 350 volts. How many
volts are lost across R? *[pause]* 50 kilowatts over 350 volts is about 143 amperes. Times 0.1 ohm,
14 volts. Per cell, 0.15.

*[show figure]* The two bars show it. 96 cells at 4.2 volts make a 403 volt limit, the dashed red
line. With 14 volts across R, constant current must stop when the OCV is about 389 volts, 4.05
volts per cell. That is the left bar, well short of full. At C over 20, 3.3 amperes, the right bar,
the drop is a third of a volt for the whole pack. The cell is almost at its OCV.

*[3 h: give the room five minutes on take-home exercise 1, the same sum for an 800 volt pack at
200 kilowatts, and take one answer. It comes out at 250 amperes, 0.26 volts per cell, and CC ending
near 3.94 volts per cell.]*
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
The datasheet limits of section 03 all slow the charge in the cold. Here is why.

A 2024 review by Das and Shrotriya says plating usually appears above 1C or near 0 degrees.
Normally the anode sits 65 to 200 millivolts above lithium, and lithium moves into the graphite
layers, called intercalation. In the cold, lithium moves more slowly inside the
graphite. It piles up at the surface, and the anode potential there falls below zero. The same
happens at high current, and when a cell is overcharged to about 4.5 volts. At worst, a dendrite
grows through the separator and shorts the cell inside, which then overheats out of control:
thermal runaway.

*[ask]* Look back at the CV slide. Plating needs a low anode potential, and a high current near
full charge pushes it down. Which part of the charge is most at risk? *[pause]* The end of CC, nearly
full, with the current still high. That is one more reason for the CV phase,
and for chargers slowing down above 80 percent.

In the cold, the safety margin against plating shrinks. That is why the datasheets on the right
cut the current hard: a quarter C below 10 degrees for the Panasonic cell, 0.3C below 25 for the
LG cell, under 250 milliamperes below zero for the LFP cell.

*[ask]* What can a car do about it, on its way to a fast charger in January? *[pause]* Heat the
pack before it arrives. This is preconditioning: the car warms its battery while driving, so it
can take full current at the charger.

ADAC, the German automobile club, measured the cost. Preconditioning saves time at the charger,
but not energy. The numbers are two slides on. On DC, a cold pack that was not
preconditioned lost up to 10 percent inside the car. Heating the pack at the charger cost 2 to 8
percent more.

Your Lecture 4 winter bill showed the cold costing energy on the road. Here it also
costs time at the plug. On a winter trip you pay both.

The chemistry sets two limits on charging speed: the voltage limit and the temperature. The next
car shows the temperature limit at work.
-->

---
routeAlias: leaf-chademo
---

## The Leaf on CHAdeMO, and rapidgate

<div class="grid grid-cols-[1.3fr_1fr] gap-8 items-start">
<div>

<img src="/figures/04-leaf-chademo.svg" alt="Charging power in kW against state of charge. Measured, the Nissan Leaf 40 kWh on CHAdeMO, Fastned data: 42.2 kW at 17 %, 43.1 at 20 %, 44.8 at 50 %, a peak of 45.63 at 57 and 60 %, then 32.75 at 70 %, 26.03 at 80 % and 20.17 at 90 %. Above it, the course Leaf pack model charged at 143 A: from 47 kW at 10 % rising to about 58 kW; with R0 and the RC pair, constant voltage starts at 68 % and the power falls to 33 kW at 80 % and 21 at 90 %; with R0 alone, dashed, it starts at 82 %."/>

<div class="caption">Fastned, one charge, pack about 30 °C: the 10 % points, first point and peak of its per-1 %
data, joined by straight lines · model: <code>CCCVLeafCharge</code>, the course Leaf pack at
143 A to 96 × 4.20 V; its plateau sits higher because it assumes 143 A.</div>

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

<div class="flex items-center gap-4 mt-3">
<img class="light-box" src="/photos/04-chademo.png" style="height: 10rem; margin: 0" alt="Front face of a round CHAdeMO plug: two large DC pins with white guards side by side and two signal-pin groups above and below, on a transparent background."/>
<div class="caption text-left">The Leaf's DC plug: CHAdeMO · D-Kuru/Wikimedia Commons, CC BY-SA 4.0</div>
</div>

</div>
</div>

<!--
Our reference car, the 40 kilowatt-hour Leaf, on CHAdeMO, the Japanese fast-charging plug: the round
one at the bottom right, photographed by D-Kuru, Wikimedia Commons.

*[show figure]* Fastned, a charging company, measured this curve: one charge, pack at about 30
degrees. State of charge across, charging power up. Flat at 43 to 46 kilowatts up to 60 percent,
then it steps down: 33 kilowatts at 70, 26 at 80, 20 at 90. This is the CV phase again, on the whole
pack, and it starts early. 10 to 80 percent: 43 minutes, 40 kilowatts on average.

The blue line is our Leaf pack model at 143 amperes. With R0 alone, the dashed line, CV would start
at 82 percent. The slow sag of the RC pair brings it to 68. The real car starts at 60, because its
BMS also slows the charge for heat and plating. The measured curve is the one to remember.

That is a good day. Now rapidgate, the nickname for the Leaf slowing its fast charge when hot. In a
test reported by CleanTechnica, the Leaf cut DC power whenever its pack was above 32 degrees. At 41
degrees, adding 70 percent took 54 minutes on the old software, just under 40 after an update. A hot
pack still cost a quarter of an hour.

*[ask]* Why does the Leaf overheat when the IONIQ does not? *[pause]* Its pack has no active
cooling. Idaho National Laboratory measured the 2012 Leaf, the same air-cooled design: each 50
kilowatt DC charge warmed the pack 6.5 degrees on average, against 2.9 on AC. The heat of one charge
is still there at the next. On a long trip, the second and third fast charges start hot and are
slowed, just when you need them.

Heat is the second limit, and a liquid-cooled pack removes most of it.
-->

---
routeAlias: three-curves
---

## A 400 V and an 800 V car

<div class="grid grid-cols-[1.6fr_1fr] gap-6 items-start">
<div>

<img src="/figures/04-dc-curves.svg" alt="Charging power in kW against state of charge, Fastned data at about 30 °C. Hyundai IONIQ 5 84 kWh, 800 V: 203 kW at 10 %, 238 at 20 %, a peak of 263.6 at 51 %, 201 at 60 %, 81 at 80 % and 67 at 82 %. Tesla Model Y LR 2025+, 400 V: 231 at 8 %, 182 at 20 %, 105 at 50 %, 48 at 80 % and 34 at 90 %. VW ID.3 Pro S 77 kWh, 400 V: 175 at 10 %, a peak of 179 at 18 %, 101 at 50 %, 69 at 80 % and 46 at 89 %. Nissan Leaf 40 kWh: 42 to 46 kW up to 60 %, 26 at 80 % and 20 at 90 %."/>

<div class="caption">[FASTNED-CURVES]: each series' 10 % points, first and last point and peak, joined by straight
lines.</div>

</div>
<div class="text-[0.85rem]">

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
Three modern cars on the same axes, again Fastned's data at about 30 degrees, with the Leaf for
scale. Two 400 volt cars, the ID.3 and the Model Y; one 800 volt car, the IONIQ 5.

*[ask]* The Model Y's quoted peak is 250 kilowatts, the IONIQ 5's 263: nearly the same. Which one
charges 10 to 80 percent faster, and by how much? *[pause]*

*[show figure]* Look at the shapes. The two 400 volt cars are fastest early, around 180 kilowatts at
20 percent. By half charge they have fallen to about 100. The IONIQ 5 does the opposite: it climbs
to its peak at about half charge, and only then falls. The IONIQ needs 18 minutes, the Model Y 27.
The Model Y has nearly the IONIQ's peak, but only two-thirds of its average power: 124 kilowatts
against 196. The 2024 Porsche Taycan, also 800 volts, matches the IONIQ's 18 minutes.

The peak in the brochure tells you little. The time depends on the shape of the curve and where it
starts to fall. That comes from the CV phase and the heat, and the BMS controls both.

Two warnings about the data. The 10 to 80 times for the Model Y and the ID.3 come from EV Database,
a secondary source. The Model Y time is for the rear-drive version; Fastned does not say which one
it measured. And Fastned's Model Y data start at 8 percent, already below its quoted peak.
-->

---
routeAlias: why-800v
---

## Why 800 V charges faster

<div class="grid grid-cols-[1.8fr_1fr] gap-6 items-start">
<div>

<img src="/figures/04-voltage-class.svg" alt="Three bar panels, 400 V in blue, 800 V in green. Current for 200 kW: 500 A against 250 A. Cable I²R for 200 kW, relative to 400 V: ×1 against ×0.25. Power at a 500 A cable: 200 kW against 400 kW."/>

<div class="caption">Computed: P = U·I, I²R ∝ I² [<code>charging.md</code> §6] · 500 A: liquid-cooled CCS2 HPC cable,
permanent rating [PHX-HPC] (search summary).</div>

</div>
<div class="text-[0.9rem]">

$$
P = U\, I, \qquad P_\text{loss} = I^2 R
$$

The current is capped by the **cable and contacts**, not the charger's electronics.

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
Why does 800 volts charge faster? Charging power is voltage times current. The current is limited by
heat in the cable and the plug contacts, I squared R, not by the charger's electronics.
*[show figure]* So at the same current limit, twice the voltage gives twice the power. That is the
right-hand panel: at 500 amperes, a 400 volt car gets 200 kilowatts, an 800 volt car 400. The same
power at twice the voltage needs half the current, and a quarter of the I squared R loss in the
cable, the contacts and the pack. Your Lecture 4 pack drew 143 amperes at 50 kilowatts. At 200
kilowatts it would draw over 500.

The right column gives real numbers. A liquid-cooled CCS2 cable is rated about 500 amperes, 700 for
short bursts. Without liquid cooling, about 200 to 250. These are makers' figures we could not
check. ADAC, the German automobile club, measured the loss inside the car on DC at 23 degrees: 1
percent for the 800 volt IONIQ 6, 3 percent for the 400 volt Model Y and ID.3.

*[ask]* So should everyone buy an 800 volt car? *[pause]* Only if the chargers can deliver it.
Hyundai's own page says the IONIQ 5 needs 76 minutes from 10 to 80 percent on a 50 kilowatt charger,
against 18 on a 350 kilowatt one. At an older 400 volt charger the car must step the voltage up
itself, using its drive motor and inverter.
-->

---
routeAlias: modes-and-connectors
---

## Modes, connectors and the on-board charger

<div class="diagram-wide">

![Four pictograms in a row, each a source on the left and a car (dashed outline) on the right holding an on-board charger (OBC) and a battery. Mode 1, AC from a household socket through a plain cable to the OBC and on to the battery; ≤ 16 A, no communication, restricted in many countries. Mode 2, the same with an in-cable box (IC-CPD); ≤ 32 A, ≤ 250 V single-phase or ≤ 480 V three-phase. Mode 3, AC from a wallbox with a dashed pilot line beside the cable; Type 2 ≤ 63 A three-phase, 3 × 16 A = 11 kW, 3 × 32 A = 22 kW. Mode 4, DC from an off-board charger (AC to DC inside it) with a pilot line; the thick DC line goes straight to the battery and the OBC is grayed out, bypassed; CCS2, CHAdeMO, GB/T, NACS.](/diagrams/04-charging-modes.svg)

</div>

<div class="caption">Mode 2 [IEC-62752-2016] and the Type 2 coupler [IEC-62196-2-2022] verified (preview) · Mode 1's 16 A
and Mode 3's 22 kW ceiling commonly cited (search summary) · kW computed at 230 V.</div>

<div class="grid grid-cols-[auto_auto_1fr] gap-8 items-center mt-3">
<div>

<img class="light-box" src="/photos/04-type-2.png" style="height: 8rem" alt="Front face of a Type 2 plug: a rounded housing with one flat side, five large pins in a ring and two small signal pins at the top, on a transparent background."/>

<div class="caption">Type 2 · D-Kuru/Wikimedia Commons, CC BY-SA 4.0</div>

</div>
<div>

<img class="light-box" src="/photos/04-ccs2.png" style="height: 8rem" alt="Front face of a CCS2 (Combo 2) plug: the Type 2 signal pins in an upper opening and two large DC pins in a separate opening below, on a transparent background."/>

<div class="caption">CCS2 · D-Kuru/Wikimedia Commons, CC BY-SA 4.0</div>

</div>
<div>

**AC goes through the car's on-board charger:** 3 × 16 A = **11 kW**, 3 × 32 A = 22 kW.

The ID.3, Model Y, IONIQ 5: **11 kW**. The old Leaf: **3.6 or 6.6 kW**, one phase — also on a 22 kW
post.

</div>
</div>

<!--
What you plug in. *[show figure]* The charging modes of the standard IEC 61851, one picture each.
Mode 1: a plain socket with no communication, restricted in many countries. Mode 2: a household
socket with a protection box in the cable, up to 32 amperes. Mode 3: a wallbox or public post that
talks to the car over the control pilot, a signal wire. The Type 2 plug takes up to 63 amperes,
three-phase. Mode 4: DC from a charger outside the car, through CCS2 in the EU. *[show photos]*
Below, the two plug faces: Type 2 for AC, and CCS2, which adds two large DC pins under it.

On AC, the car's own on-board charger turns AC into DC, and its rating sets the power. One phase at
16 amperes and 230 volts is 3.7 kilowatts. Three phases give 11, and three at 32 amperes give 22.
The ID.3, the Model Y and the IONIQ 5 have 11 kilowatt chargers. The 40 kilowatt-hour Leaf has a
single-phase 3.6 or 6.6.

*[ask]* You plug that Leaf into a 22 kilowatt public post. What do you get? *[pause]* 3.6 or 6.6
kilowatts. The post offers 22; the car takes what its charger can. On DC, the charger outside the
car bypasses the car's own charger. That is the point of DC: the grayed-out on-board charger in Mode
4.

One warning: a household socket is not built to carry its full current for hours. That is why the
Mode 2 box exists. And why Denmark, for example, limits a socket charge that can run over two hours
to 8 amperes.
-->

---
routeAlias: connectors-elsewhere
skipInCut: true
---

## Connectors beyond CCS2

<div class="grid grid-cols-3 gap-6 items-end">
<div>

<img class="light-box" src="/photos/04-chademo.png" style="height: 10rem" alt="Front face of a round CHAdeMO plug: two large DC pins with white guards side by side and two signal-pin groups above and below, on a transparent background."/>

<div class="caption">CHAdeMO · D-Kuru/Wikimedia Commons, CC BY-SA 4.0</div>

</div>
<div>

<img class="light-box" src="/photos/04-nacs.png" style="height: 10rem" alt="Drawing of the NACS (SAE J3400) plug face: two large yellow-ringed pins labeled DC+/L1 and DC−/L2, and below them PP, a green ground pin G, and CP."/>

<div class="caption">NACS (SAE J3400) · RickyCourtney, CC BY-SA 4.0</div>

</div>
<div>

<img class="photo" src="/photos/04-mcs.jpg" style="height: 10rem" alt="A Megawatt Charging System inlet and plug on a white table: triangular black housings with two large DC contacts and smaller signal contacts."/>

<div class="caption">MCS, Stäubli · SRago91, CC BY-SA 4.0</div>

</div>
</div>

<div class="tight mt-2">

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
[NISSAN-LEAF3-2025] verified; MW computed (<code>charging.md</code> §3)</div>

<!--
The connectors other than the EU's CCS2, for reference. *[show photos]* Three plug faces: CHAdeMO,
NACS, and MCS for trucks. The photographs are by D-Kuru, RickyCourtney and SRago91, on Wikimedia
Commons.

CHAdeMO is the Japanese standard on the old Leaf. Its 2017 high-power version gives 100 kilowatts
continuously and 150 to 200 at peak, at 400 amperes and 500 volts. Its successor, ChaoJi, was
developed with China: up to 600 amperes at 1 to 1.5 kilovolts, 500 to 900 kilowatts. China's own
GB/T plug of 2023 is reported at up to 1500 volts and 800 amperes. NACS is Tesla's connector, now
the standard SAE J3400. It is one hand-sized plug that carries DC or single-phase AC on the same two
pins.

MCS, the Megawatt Charging System, is for trucks. 1250 volts times 3000 amperes is 3.75 megawatts,
about eighty times the old Leaf's 46 kilowatts. *[ask]* Who needs megawatts at a plug? *[pause]* A
battery truck. It must refill a very large pack during the driver's break, not overnight. Remember
this in section 07, when we ask where hydrogen trucks still make sense. This is what they compete
with. The first certified chargers are reported at about 1 to 1.2 megawatts. SAE's MCS document
covers the plug, the communication, cooled cables and automatic connection, so a truck need not wait
for a driver to plug it in.

With adapters, ChaoJi also works with GB/T and CHAdeMO, so the two Asian systems may merge. NACS
also has an SAE standard for an adapter to CCS.

There is one more way to refill a battery car, with no cable at all: swap the battery. The trade
press reports that NIO ran 4,090 battery-swap stations in China in September 2026. A swap takes
minutes, like a nozzle. But the station needs a stock of charged packs, and it only works for the
maker's own cars.

In Europe, CHAdeMO is disappearing. Nissan's new Leaf uses CCS in Europe and NACS in North America,
and keeps CHAdeMO only in Japan. Drivers of the old Leaf will find fewer and fewer CHAdeMO posts.
-->

---
routeAlias: charging-losses
---

## AC and DC: where the energy is lost

<img src="/figures/04-charging-losses.svg" style="max-height: 28rem" alt="Two panels of charging loss in percent. Left, AC grid to battery, one dumbbell per car from the 11 kW wallbox (green) through 4.1 kW (gray) to the 2.3 kW household socket (red): Mercedes CLA 350 EQ 6.9 / 12.8 / 24.2, VW ID.7 6.9 / 10.6 / 15.3, Volvo EX30 7.0 / 9.1 / 14.2, Renault R5 E-Tech 5.1 / 8.0 / 13.7, Tesla Model Y 6.1 / 9.4 / 12.7. Right, DC losses inside the car, three bars per car for 23 °C preconditioned, 0 °C preconditioned and 0 °C not preconditioned: VW ID.3 3 / 5 / 7, Tesla Model Y 3 / 4 / 10, Renault Mégane E-Tech 4 / 6 / 8, Hyundai Ioniq 6 (800 V) 1 / 1 / 6."/>

<div class="caption">ADAC 2026 [ADAC-LADEVERLUST-2026], verified · DC: inside the car only; with the charger's own ≈ 3 %
the DC total is 5–15 %, and heating the pack at the charger adds 2–8 %.</div>

**Slow AC loses most:** the car's fixed loads run for hours on a slow charge, so every car's loss is
lowest at 11 or 22 kW.

<!--
Energy lost between grid and battery, as ADAC measured it in 2026.

*[show figure]* On the left, AC, for five current cars, one line each, red for the socket, green for
the wallbox. At a 2.3 kilowatt household socket losses range from 12.7 percent for the Model Y to
24.2 for the Mercedes. At an 11 kilowatt wallbox they fall to 5 to 7 percent. *[ask]* Why would
charging slowly waste more? *[pause]* The car's control units, pumps and BMS draw a fixed power for
as long as the charge lasts. On a socket, that is many hours.

On the right, DC: the losses inside the car only, at 23 degrees and at 0 degrees. "Precond." means
the car heated the pack on its way to the charger. Warm: 1 percent for the 800 volt IONIQ 6, 3 to 4
for the others. Cold and not preconditioned: 6 to 10 percent. The charger itself loses about 3
percent. ADAC puts the total DC loss at 5 to 15 percent. Heating the pack at the charger costs
another 2 to 8 percent.

Your Lecture 4 energy bill assumed 13 percent between the wall and the battery. That fits this
range. Argonne, a US national lab, measured the old Leaf's on-board charger at 86 to 87 percent
efficiency. Today's cars reach 93 to 95 at 11 kilowatts.
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
A modern charger and car talk to each other. The data is sent as a high-frequency signal on the
control pilot wire. Most CCS chargers in use still speak an older, DC-only protocol, DIN SPEC 70121.

ISO 15118 sets the rules for this. Part 20, published in 2022, adds the messages for power in both
directions, so the car can also feed the grid. The EU made it compulsory by amending AFIR, its law
on charging and fueling stations. Every public AC or DC point installed or renovated from 8 January
2026 must support ISO 15118 parts 1 to 5. From 1 January 2027, also part 20. With Plug and Charge,
the car identifies itself; you need no card or app. It stays optional for the operator. But an
operator who offers it must use ISO 15118, so that every car can use every charger. Existing
chargers are exempt, and cards and apps may stay until the market has moved over.

On the right, V2G, vehicle-to-grid, on the road. Renault and Mobilize launched it in France in
October 2024 with the Renault 5. The car's on-board charger works in both directions and acts as the
inverter. This is AC V2G, and the wallbox stays simple, 7 to 22 kilowatts. Renault claims this
halves the cost of charging on average. Nissan's new Leaf can also do V2G in Europe. France came
first, then Great Britain. Germany was still waiting for its rules when Renault launched.

*[ask]* Most cars stand parked most of the day with a full battery. Who would want to use that
battery, and for what? *[pause]* The grid operator, to cover the evening peak and store midday
solar. The car is then more than a load. Here a plug can do something a nozzle never can: the energy
can go back out.
-->

---
routeAlias: degradation
skipInCut: true
---

## Does fast charging wear the battery?

<img src="/figures/04-degradation.svg" style="max-height: 25rem" alt="Two bar panels. Left, 22,700 EVs (Geotab 2026), capacity lost per year: about 1.5 % mostly on AC or low power, 2.3 % fleet average, up to 3.0 % for heavy DC above 100 kW. Right, four 2012 Leafs in Phoenix (INL), capacity lost at 50,000 miles: about 24 ± 2 % on Level 2 (3.3 kW) and about 27 ± 2 % on 50 kW DC."/>

<div class="caption">[GEOTAB-2026] verified · [INL-DCFC-2015] Fig. 14, read from figure (±2 %); DC cars charged twice
daily in a hot climate.</div>

<div class="grid grid-cols-2 gap-8 text-[0.9rem] mt-2">
<div>

**Fleet:** hot regions **+0.4 %/yr**; worse only above 80 % of the time at very high or very low SoC.

</div>
<div>

**INL:** DC packs under 46 °C for 95 % of the time. "the difference is small relative to the total
capacity loss"

</div>
</div>

<!--
Does fast charging wear out the battery? Two sources: one large but rough, one small but careful.

*[show figure]* On the left, fleet data from Geotab, January 2026: more than 22,700 electric cars of
21 models. Average capacity loss: 2.3 percent per year. Cars that mostly fast-charge above 100
kilowatts lose up to 3.0 percent a year. Cars charged mostly on AC lose about 1.5. Hot regions add
0.4. The battery wears faster only when a car spends more than 80 percent of its time very full or
very empty.

*[ask]* Over eight years, what does 3 percent a year against 1.5 mean for a car's range? *[pause]*
Roughly a quarter of the capacity against an eighth. Real, but not the end of the car. A trade
report on the same data gives similar numbers: after eight years, about 12 percent lost on AC and up
to 22 on DC.

On the right, a controlled test by Idaho National Laboratory: four 2012 Leafs in Phoenix. Two
charged only on 50 kilowatt DC, two only on 3.3 kilowatt AC, twice a day, in a very hot climate. At
50,000 miles the DC cars had lost about 27 percent of their capacity, the AC cars about 24. Values
read off their figure, to about 2 percent. In range at a steady 45 miles an hour, one AC car dropped
from 106 to 81 miles, one DC car from 104 to 69. The lab's own conclusion: the difference is small
compared with the total loss. And these cars were charged twice a day, twice as often as Nissan
recommends, in desert heat: a very hard test.

Their DC packs spent 95 percent of the time below 46 degrees. This links back to rapidgate. Heat
ages the pack more than the plug does. A car that keeps its pack cool can charge fast.
-->

---
routeAlias: network
---

## The network: Czechia, the EU, and AFIR

<div class="grid grid-cols-[1.7fr_1fr] gap-6 items-start">
<div>

<img src="/figures/04-network.svg" alt="Stacked bars of public charging points by AFIR power class, AC in blues and DC in oranges, for 2024, 2025 and September 2026. Czechia: 6,359, 7,574 and 7,669 points, most of them AC 7.4 to 22 kW (4,369, 4,971 and 4,801); DC share 29.8, 33.1 and 36.1 %; share of 150 kW and above 9.1, 12.8 and 15.0 %. EU27, in thousands: 882,012, 1,061,890 and 1,176,554 points; DC share 15.7, 18.3 and 19.2 %; share of 150 kW and above 9.3, 11.2 and 12.0 %."/>

<div class="caption">European Alternative Fuels Observatory [EAFO-CZ], [EAFO-EU27]: counts verified, shares
computed; Sep 2026 is the latest update.</div>

</div>
<div class="text-[0.9rem]">

<img class="photo" src="/photos/04-cez-praha.jpg" style="height: 15rem" alt="An orange-and-green ČEZ DC charger with its cables at a reserved parking bay on Evropská street in Prague 6, under a blue P sign."/>

<div class="caption">ČEZ charger, Praha 6, 2025 · Yopic, CC0</div>

**Czechia, end 2025:** **7,574** public points, **33.1 %** DC; Sep 2026: **7,669**, DC 36.1 %.

**AFIR Art. 3:** per registered BEV, **1.3 kW** of public power; on the TEN-T core network a pool
every **60 km**, ≥ **400 kW** with one ≥ 150 kW point by end 2025, **600 kW** by end 2027.

<div class="caption text-left">[EAFO-CZ], [EAFO-EU27] counts verified, shares computed ·
[EU-AFIR] verified</div>

</div>
</div>

<!--
How many public chargers are there? *[show figure]* Public charging points by power class, counted
by the EU's Alternative Fuels Observatory, for 2024, 2025 and September 2026. Czechia is on the
left, the EU 27 on the right. AC at the bottom: the ordinary 7 to 22 kilowatt posts, most of the
total. DC above.

*[show photo]* A ČEZ fast charger on Evropská in Prague 6, photographed by the user Yopic. At the
end of 2025 Czechia had 7,574 public points. A third of them were DC, and one in eight gave 150
kilowatts or more. The EU average is lower: 18 percent DC. Czechia has few chargers, but many fast
ones. By September 2026 the total had barely grown, to 7,669 points, but the mix changed. The AC
count fell by about 170, while DC rose by 260, to 36 percent of all points. Fast posts are replacing
slow ones.

Worldwide there were over 7 million public charging points at the end of 2025, about 11 electric
cars for each one, says the International Energy Agency.

The EU law on charging, AFIR, sets targets in Article 3. For every registered battery-electric car,
1.3 kilowatts of public charging power. Along the main trans-European roads, a charging site every
60 kilometers in each direction: at least 400 kilowatts by the end of 2025, 600 by the end of 2027.

The plug, in short: 18 to 43 minutes from 10 to 80 percent, set by the CV phase and by heat. 5 to 15
percent lost on DC. About 7,700 public points in Czechia. Keep two numbers for after the break: 18
minutes, and 17.1 kilowatt-hours per 100 kilometers, what the Leaf takes from the wall.

After the break, the nozzle: a car that fills in about three minutes. Break: 15 minutes. *[90 min:
no break; go straight on to section 05.]*
-->
