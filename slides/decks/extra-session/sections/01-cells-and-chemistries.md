---
routeAlias: cells-and-chemistries
layout: section
---

###### Section 01

# Cells and chemistries

A battery's terms on the Leaf's pack, then the chemistries on the road now: LFP (lithium iron
phosphate), NMC (lithium nickel manganese cobalt oxide) and sodium-ion, their specific energy, and
what a kilowatt-hour costs today.

<img class="hero" src="/photos/01-bmw-i3-cells.jpg" alt="Rows of flat aluminum prismatic cells, each with two threaded terminal posts and a vent window, labeled SB LiMotive, sample cells for the BMW i3."/>

<div class="caption">BMW i3 prismatic cells, SB LiMotive · RudolfSimon, CC BY-SA 3.0</div>

<!--
Before we ask how fast energy goes back into a car, we need to know what it goes into. NMC, LFP and
the new sodium-ion: the choice sets what a kilogram stores, what a kilowatt-hour costs, and the
voltage where the charger must stop.

*[ask]* A question for later: which chemistry would you buy for a city bus, and why? *[pause]* We
answer it in section 03, on the balancing slide.

*[show photo]* Sample cells for the BMW i3, in flat metal cases. First, the words a data sheet uses,
on the Leaf's pack.
-->

---
routeAlias: battery-terms
---

## A battery's terms, on the Leaf's pack

<div>

| Term | What it means | Unit | Leaf 40 kWh |
|---|---|---|---|
| **Capacity** *Q* | the charge it delivers from full to empty | A·h | **113 A·h** (2 × 56.3) |
| **Nominal voltage** | the average voltage over a full discharge | V | **350 V** (96 × 3.65 V) |
| **Energy**, gross | *Q* × nominal voltage: what the cells hold | kWh | **40 kWh** |
| **Energy**, usable | what the car lets you take out | kWh | **39 kWh** |
| **State of charge** *SoC* | the share of *Q* still in the cells | % | counted (section 03, the BMS) |
| **Specific energy** | energy per kilogram | Wh/kg | **132** pack (303 kg) |
| **Energy density** | energy per liter | Wh/L | **≈ 82** pack (485 L box) |
| **Specific power** | power per kilogram | W/kg | **≈ 360** at the motor's 110 kW |
| **Energy efficiency** | energy out ÷ energy in, round trip | % | **95–98** (2013 Leaf) |

</div>

<div class="caption text-left">40 kWh, 350 V, 110 kW: Nissan [N-JP-ZE1] · 303 kg, 1547 × 1188 × 264 mm: Nissan US
guide · 39 kWh usable, 96s2p (96 groups in series, 2 cells in parallel): EV Database
(ev-database.org), secondary · 56.3 Ah: Gao et al. 2024 · round trip: Argonne National Laboratory
(ANL) 2013 · Wh/kg, Wh/L, W/kg: derived</div>

<div class="caption text-left">Units: A·h ampere-hour · kWh kilowatt-hour · Wh/kg watt-hours per kilogram · Wh/L
watt-hours per liter · W/kg watts per kilogram</div>

<div class="handson">New tonight: nominal voltage, and gross against usable. The rest is from <a href="https://dr14-make.github.io/16ESPD/lecture-04/#/charge-and-energy" target="_blank">Lecture 4, <i>The Battery-Electric Car</i></a>.</div>

<!--
The basic terms, on one pack. Lecture 4 gave you capacity, energy, state of charge and the
efficiencies. Two terms are new.

Nominal voltage is the average over a full discharge: 3.65 volts per cell, times 96 in series, gives
350 volts. The real pack swings from about 240 volts empty to 420 full.

Gross energy is what the cells hold. Usable energy is what the car lets you take out. The battery
management system, the BMS, keeps a margin at the top and the bottom, where the cell ages fastest.
On the Leaf, 40 against 39.

*[ask]* Two cars advertised at 77 kilowatt-hours, one gross, one usable. Which goes further?
*[pause]* The usable one: all 77 come out.
-->

---
routeAlias: c-rate
---

## C-rate: current per capacity, and power per energy

<div class="grid grid-cols-2 gap-8">
<div>

$$
\text{C-rate} = \frac{I}{Q} \approx \frac{P}{E}
\qquad 1\,\text{C} \;\Rightarrow\; \text{full to empty in 1 h}
$$

- Size-free: a cell and its pack share the C-rate.
- Each limit on a datasheet is a C-rate: charge, discharge, pulse.

<div class="tight">

| | Power | C-rate |
|---|---|---|
| Leaf, WLTC average | ≈ 8 kW | **0.2 C** |
| Leaf, motor peak | 110 kW | **2.8 C** |
| Leaf, DC (direct current) fast-charge peak | 46 kW | **1.2 C** |
| IONIQ 5 84 kWh, DC peak | 263 kW | **3.1 C** |

</div>

</div>
<div>

**Peak against continuous.** A peak rating holds for seconds; a continuous rating holds once the
temperature has settled.

- Leaf motor: **110 kW** peak, **85 kW** continuous.
- Even the older, smaller 2013 Leaf pack (24 kWh) gave **103 kW** for 30 s (**4.3 C**), close to
  the motor's peak; the 40 kWh pack has more cells in reserve.
- So the **motor, not the pack, sets the car's peak power.**

**Power depends on charge and temperature.** INL measured the available power against depth of
discharge, every 10 %:

- An **empty** or **cold** pack has a higher internal resistance, so it gives less power.
- A **full** pack accepts less charge power.
- Cold: the LG M50LT cell may charge at **0.3 C** below 25 °C, **0.7 C** above.

<div class="caption text-left">Leaf: Nissan [N-JP-ZE1], Idaho National Laboratory (INL) 2014 [INL-5045] · IONIQ 5 and
Leaf DC: [HYU-EU-CT], [EVDB-LEAF40] (Fastned data) · WLTC (Worldwide harmonised Light vehicles Test
Cycle): 17.1 kWh/100 km × 46.5 km/h · cold: [LG-M50LT-2020] · C-rates derived</div>

</div>
</div>

<!--
The one new unit tonight, heard at every charger: the C-rate. It is current over capacity, or power
over energy. One C empties the battery in an hour. It does not depend on size, so data sheets give
limits as C-rates.

*[show table]* On the WLTC test cycle the Leaf uses a fifth of a C. Motor peak: 2.8 C. Fast charge:
1.2 C. The IONIQ 5 charges at 3.1 C.

*[ask]* Which of these is hardest on the cell? *[pause]* The charge. Charge too hard or too cold,
and the lithium coats the graphite as metal instead of going in. Seconds of discharge at 2.8 C are
easy by comparison. Section 04 comes back to this, on "Cold and fast".

On the right: a peak lasts seconds; a continuous rating holds once the temperature settles. Even
the smaller 2013 pack gave 103 kilowatts for 30 seconds, close to the motor's 110. So the motor, not
the pack, sets the car's peak. An empty or cold pack has more resistance and gives less; a full one
takes less.
-->

---
routeAlias: power-costs-energy
---

## Specific energy against specific power: why one costs the other

<div class="diagram-wide">

<img src="/figures/01-rate-capability.svg" style="max-height: 23rem" alt="Left, terminal voltage against charge delivered for one NMC 21700 cell discharged to 2.5 V: 5.1 Ah at 0.2 C, 4.9 at 1 C, 4.7 at 2 C, 2.3 at 3 C; the faster curves sit lower and reach the cutoff sooner. Right, the same runs as specific energy against specific power: 272 Wh/kg at 54 W/kg, falling to 230 at about 490 W/kg at 2 C and 110 at about 720 W/kg at 3 C."/>

</div>

<div class="caption">Simulated: PyBaMM Doyle–Fuller–Newman (DFN) model, Chen2020 parameters of the LG M50 cell, 25 °C, per 68.2 g (M50LT
datasheet). A model, not a measurement: take the shape.</div>

<div class="grid grid-cols-3 gap-6 text-sm mt-2">
<div>

**1 · Resistance.** *V* = OCV − *R i*, OCV the open-circuit voltage: the curve drops and hits the cutoff sooner; *R i*² heats
the cell.

</div>
<div>

**2 · Transport.** At 3 C the electrolyte runs out of ions near one electrode: the voltage
collapses with half the lithium still in the anode.

</div>
<div>

**3 · Design.** Thin electrodes are fast but carry more foil per Wh:

<div class="tight">

| Cell | Wh/kg | W/kg |
|---|---|---|
| LG M50LT, energy | **267** | ≈ 780 (3 C) |
| A123 26650, power | **113** | ≈ 2,300 (20 C) |

</div>
</div>
</div>

<div class="caption text-left">Datasheets [LG-M50LT-2020], [LW-26650-2022]: rated Wh and mass; W/kg = max continuous
current × nominal V, derived</div>

<!--
Lecture 4's Ragone plot, energy per kilogram against power per kilogram, showed that more power means less energy. Here is why.

*[show figure]* One NMC cell, simulated, emptied at four currents. At a fifth of a C it gives 5.1
ampere-hours. At 2 C, 4.7; at 3 C, only 2.3. The faster curves sit lower and reach the cutoff
sooner.

*[ask]* Where did the missing charge go at 3 C? *[pause]* Nowhere. It is still in the cell, but
could not come out in time.

Three reasons. First, resistance: the voltage is the OCV, the voltage at rest, minus R i. The curve
shifts down, and R i squared is heat. Second, transport: the sharp drop. At 3 C the electrolyte runs
out of ions near one electrode, and the voltage collapses with half the lithium still in the anode.
On the right, the same runs per kilogram. Trust the shape, not the 3 C number; the real cell is
allowed 3 C.

Third, design. Thin electrodes move ions fast, but need more foil and separator per watt-hour. LG's
energy cell stores 267 watt-hours per kilogram at up to 3 C. A123's power cell, 113, at 20 C.

*[ask]* Which for a hybrid's buffer battery, which for a battery car? *[pause]* Power cells for the
hybrid's small, hard-working pack. Energy cells for range: a big pack keeps the C-rate low.
-->

---
routeAlias: cell-to-pack
skipInCut: true
---

## From cell to pack: series adds volts, parallel adds amp-hours

<div class="diagram-wide">

<img src="/diagrams/01-cell-to-pack.svg" alt="Leaf pack schematic: 96 groups in series, each two cells in parallel. Two in parallel add amp-hours, 2 × 56 Ah = 113 Ah; 96 in series add volts, 96 × 3.65 V = 350 V; E = Ns · Np · V_cell · Q_cell ≈ 40 kWh."/>

</div>

<div class="text-sm mb-1">

**96s2p** = 96 groups in series, 2 cells in parallel in each group · **Ah** ampere-hour · **kWh**
kilowatt-hour · **Wh/kg** watt-hours per kilogram

</div>

<div class="tight">

| | Cells | Cell | Pack | Gross / usable | Cell / pack Wh/kg |
|---|---|---|---|---|---|
| **Leaf 40 kWh** | 192, **96s2p**, 24 modules | 56.3 Ah, 3.65 V, 914 g | 113 Ah, **350 V** | 40 / 39 kWh | **224 / 132**: cells are 58 % of the mass |
| **IONIQ 5 84 kWh** | 384, **192s2p**, 32 modules | ≈ 60 Ah, 3.63 V | 120.6 Ah, **697 V** | 84 / 80 kWh | pack mass: no primary |

</div>

<div class="caption text-left">Leaf cell: Automotive Energy Supply Corporation (AESC, the cell maker) product page
(2019) [AESC-EV-2019] · 96s2p, modules: secondary · IONIQ 5: Hyundai spec sheet and emergency
response guide (IONIQ 5 N, same pack) · usable: EV Database (ev-database.org), secondary · cell
values for the IONIQ 5 and the mass share: derived</div>

<!--
How cells become a pack. *[show diagram]* Cells in parallel share one voltage and add their
amp-hours. Groups in series carry one current and add their volts. The Leaf pairs 56 amp-hour cells
into 113 amp-hour groups, then puts 96 groups in series: 350 volts. The energy is the product at the
bottom: 96 times 2 times 3.65 times 56.3, about 39.5 kilowatt-hours. Nissan sells it as 40.

*[ask]* The IONIQ 5 is an 800 volt car. Did Hyundai use bigger cells? *[pause]* No: about the Leaf's
size, 60 amp-hours and 3.63 volts. It puts 192 groups in series instead of 96, so the voltage
doubles to 697 volts nominal. For the same power the current halves, which cuts the R i squared loss
in every cable. Section 04's slide "Why 800 V charges faster" starts here.

The last column is what the box costs in mass. AESC, the Automotive Energy Supply Corporation that makes the cell, gives the Leaf cell as 914 grams and
224 watt-hours per kilogram. The pack has 132. The cells are only 58 percent of the mass. The rest
is module frames, the metal bars that join the cells, cooling, case and electronics. Much of the
progress since 2018 went into that ratio. Cell-to-pack designs drop the module frames.

The usable figures come from a database, not the makers, so treat them as close.
-->

---
routeAlias: soc-dod-soh
skipInCut: true
---

## How full, how deep, how worn: SoC, DoD and SoH

<div class="grid grid-cols-[3fr_2fr] gap-6 items-start">
<div>

<img src="/figures/01-ageing.svg" alt="Two bar panels for NMC 18650 cells. Left, full cycles to 80 percent capacity at 25 °C: about 450 cycling 0–100 percent SoC, 1,650 at 20–80, 2,150 at 40–60. Right, capacity lost after 10 months of storage: at 25 °C about 2.5 percent at 50 percent SoC against 6.5 at 100; at 50 °C about 12 against 23."/>

<div class="caption">NMC 18650 cells, not car cells · read from figures: Preger et al., <i>J. Electrochem. Soc.</i>
(JES) 2020, Fig. 2a; Keil et al., JES 2016, Fig. 2b</div>

<div class="text-sm mt-2 tight">

**Equivalent full cycles** (EFC) = total charge moved ÷ capacity. A 40→60 % cycle moves 20 % of
capacity: **0.2 EFC**.

| Window | EFC to 80 % | Actual cycles |
|---|---:|---:|
| 0–100 % | 450 | 450 ÷ 1.0 = **450** |
| 20–80 % | 1,650 | 1,650 ÷ 0.6 ≈ **2,750** |
| 40–60 % | 2,150 | 2,150 ÷ 0.2 ≈ **10,750** |

</div>

</div>
<div>

$$
DoD = 1 - SoC
$$

$$
SoH = \frac{Q_\text{now}}{Q_\text{new}}
$$

- **Cycle aging** grows with the window: shallow cycles deliver about **5×** more lifetime
  energy (2,150 vs 450 EFC).
- **Calendar aging** runs parked: faster when full and hot. LFP: ≈ 0.2 points a month at 25 °C.
- **Euro 7**, new cars: **≥ 80 %** of usable energy at 5 years or 100,000 km, **≥ 72 %** at 8
  years or 160,000 km (types from 29 Nov 2026).
- **Warranties:** 8 years or 160,000 km, to **70 %** (Hyundai) or 9 of 12 bars (Nissan).

<div class="caption text-left">Euro 7: Regulation (EU) 2024/1257 Annex II, Art. 10 · Hyundai EU, Nissan BE · LFP: Keil
2016</div>

</div>
</div>

<!--
Three words for the battery's state. State of charge, SoC: how full it is. Depth of discharge, DoD,
is one minus SoC: how far down you have gone. State of health, SoH, is capacity now over capacity
new. Euro 7 measures it in usable energy, but the idea is the same.

*[show figure]* The depth decides how long a cell lives. Sandia National Laboratories cycled one NMC
cell over three SoC ranges at 25 degrees, until it had lost a fifth of its capacity. Full to empty:
about 450 full cycles. Between 20 and 80 percent: 1,650. Between 40 and 60: 2,150. These are
equivalent full cycles: the total charge moved, divided by the capacity. One 40 to 60 cycle moves a
fifth of the capacity, so it counts as 0.2. The 2,150 are therefore about 10,750 real shallow
cycles, five times as many, not a fifth. Between 20 and 80, 1,650 divided by 0.6, about 2,750 real
cycles. The comparison is fair because all three count the same thing: the total charge the cell
delivered before it lost a fifth of its capacity. Shallow cycling gets about five times more
lifetime energy out of the cell. The ends, nearly full and nearly empty, do the damage. That is why the car keeps a margin, and why the
app suggests charging to 80 percent.

On the right, aging while parked, over ten months. At 25 degrees, kept half full, the cell lost
about 2.5 percent; kept full, 6.5. At 50 degrees, 12 against 23. Full and hot is the worst way to
park a battery. LFP ages far less parked: about 0.2 points a month.

These are small laboratory cells, 18650s, not car cells. Trust the shape, not the numbers. Section
04's slide "Does fast charging wear the battery?" has the fleet: 2.3 percent a year.

*[ask]* Euro 7 requires at least 72 percent at 8 years, for new car types from the end of this
month. Hyundai's warranty pays out below 70. Which promise is stricter? *[pause]* The law, by two
points.
-->

---
routeAlias: what-is-on-the-road
skipInCut: true
---

## From the course deck to the road

<div class="grid grid-cols-2 gap-8">
<div>

**The course deck's tour** (deck 8, *Batteries and Fuel Cells*, after Larminie and Lowry, *Electric
Vehicle Technology Explained*): lead acid, nickel-cadmium, nickel-metal hydride, lithium-ion.
<a href="https://dr14-make.github.io/16ESPD/lecture-04/#/battery-table" target="_blank">Lecture 4</a>
showed its Ragone plot and chemistry table, early 2000s values.

**On the road in 2025:** lithium-ion only, in two families.

- **NMC**: a layered nickel-manganese-cobalt oxide cathode; most energy per kilogram.
- **LFP**: an iron-phosphate cathode; cheaper, lower voltage, a flat voltage curve.
- **Sodium-ion**: sodium in place of lithium; the newest cells.

</div>
<div>

**LFP's share of EV batteries deployed:** over **55 %** worldwide in 2025, up from nearly 50 % in
2024.

**In the EU:** more than **10 %** of EV battery demand.

**EV batteries deployed in 2025:** **1.2 TWh**.

<div class="caption text-left">International Energy Agency (IEA), Global EV Outlook 2026, pp. 92, 96 [IEA-GEVO-2026] ·
EV: electric vehicle</div>

</div>
</div>

<!--
The course deck, Batteries and Fuel Cells, covers the chemistries in historical order: lead acid, nickel-cadmium, nickel-metal hydride,
lithium-ion. Lead acid stores about 35 watt-hours per kilogram, nickel-cadmium about 52. Today's
best lithium-ion cells reach 265, more than seven times lead acid. Every new electric car carries lithium-ion,
in two families, and a third is arriving.

NMC has a layered nickel-manganese-cobalt oxide cathode. It stores the most energy per kilogram and
is charged to 4.2 volts. LFP has an iron phosphate cathode. It stores less, costs less, and is
charged to only 3.6 volts. Its voltage hardly changes over most of its charge. In section 03, on
"Resetting the count from the OCV", that makes the BMS's job much harder. Sodium-ion swaps lithium for sodium, a far more common element. Its
best cells store 175 watt-hours per kilogram against LFP's 205, and it aims at LFP's market.

On the right, the market, from the International Energy Agency's 2026 outlook. In 2025 LFP was over
55 percent of the EV batteries put into use worldwide, up from nearly 50 the year before. In the EU,
just over a tenth: Europe still prefers nickel. Across all lithium-ion, today's cells range from
about 90 to 300 watt-hours per kilogram.

*[ask]* In 2025 the world put 1.2 terawatt-hours of EV batteries into use. How many 40 kilowatt-hour
Leaf packs is that? *[pause]* Thirty million, in one year.

LFP took half the world while storing less per kilogram. The next slide shows why.
-->

---
routeAlias: chemistry-table
---

## LFP, NMC and sodium-ion side by side

<div class="grid grid-cols-[2fr_1fr] gap-8 items-start">
<div>

<img src="/figures/01-chemistry.svg" alt="Two bar panels. Left, best-in-class cell specific energy: NMC up to 265 Wh/kg, LFP up to 205, sodium-ion up to 175. Right, 2025 average pack price, all segments: NMC 128 $/kWh, LFP 81; sodium-ion has no price in the source."/>

<div class="caption">Cell: IEA Global EV Outlook 2026 p. 101 [IEA-GEVO-2026], "up to" values, the IEA does not say
"cell" for LFP and NMC explicitly · pack: BloombergNEF survey, Dec 2025 [BNEF-2025] · no sodium-ion
pack price published there.</div>

</div>
<div>

**Pack specific energy:** LFP about **one-fifth lower** than NMC.

**Charge voltage (CV), example cell:** NMC **4.20 V** (LG M50LT, NMC 811), LFP **3.6 V** (A123
26650); sodium-ion: no figure in our sources.

**For scale:** the 2018 Leaf's 40 kWh pack weighs 303 kg, about **132 Wh/kg** at pack level.

<div class="caption text-left">Pack Wh/kg: IEA Global EV Outlook 2025 [IEA-GEVO-2025] · CV: datasheets
[LG-M50LT-2020], [LW-26650-2022] · NMC: lithium nickel manganese cobalt oxide · LFP: lithium iron
phosphate</div>

</div>
</div>

<!--
The one chart to keep from this section. *[show figure]* On the left, what the best cell of each
chemistry stores per kilogram. On the right, what a pack cost in 2025.

*[ask]* LFP stores less per kilogram than NMC. Why is it over half of the EV batteries in use?
*[pause]* Price: 81 dollars per kilowatt-hour against 128, about two-thirds. For a cheap car or a
bus, a quarter more battery mass is a good trade for a third off the price. Sodium-ion reaches 175
per kilogram, but our sources give no price for it yet.

The charge voltage on the right matters tonight: NMC up to 4.20 volts, LFP 3.6. Section 04's "CC-CV
at the cell" starts from that limit. The Leaf's 132 per kilogram is half the best NMC cell. The rest is casing, cooling
and wiring.
-->

---
routeAlias: cost-today
skipInCut: true
---

## What a kilowatt-hour costs, and what it weighs

<div class="grid grid-cols-[1.2fr_1fr] gap-8 items-start">
<div>

<img src="/figures/01-pack-price.svg" alt="Stacked bars of the volume-weighted average lithium-ion pack price, all segments, in real 2025 dollars per kWh, split into cell and rest of pack: 827 (568 cell + 259) in 2013, 475 (318 + 157) in 2015, 273 (192 + 81) in 2017, 194 (136 + 58) in 2019, 159 (122 + 37) in 2021, 170 (136 + 34) in 2022, 148 (114 + 34) in 2023, 118 (78 + 40) in 2024 and 108 (74 + 34) in 2025."/>

<div class="caption">BloombergNEF battery price survey, December 2025, real 2025 $: the bar labels of its cell and
pack split chart.</div>

</div>
<div>

- **Pack price, all segments:** **$108/kWh** in 2025, −8 % on 2024; battery-electric car (BEV)
  packs **$99/kWh**.
- **Cell vs pack, 2025:** **$74** of the 108 is the cell.
- **The last decade:** pack energy density **+60 %**, price **−75 %**.
- **Regions:** China **$84/kWh**; North America and Europe 44 % and 56 % higher.

**LFP in place of NMC, Leaf 40 kWh pack:**

- Price: ($128 − $81)/kWh = **$47/kWh**; × 40 kWh ≈ **$1,900** cheaper
- Mass: 132 Wh/kg × (1 − 0.2) ≈ 106 Wh/kg; 40,000 Wh ÷ 106 Wh/kg ≈ **380 kg**, against 303 kg

<div class="caption text-left">[BNEF-2025] · decade: [IEA-GEVO-2026] p. 173 · NMC $128, LFP $81 and "LFP packs
one-fifth lower in Wh/kg": slide <Link to="chemistry-table">LFP, NMC and sodium-ion side by side</Link>,
[BNEF-2025], [IEA-GEVO-2025]</div>

</div>
</div>

<!--
Lecture 4's slide "What a kilowatt-hour costs" showed this price curve once. Here it is split into cells and the rest of the pack, every
year in 2025 dollars.

*[show figure]* In 2013 a pack cost 827 dollars per kilowatt-hour, 568 of it cells. In 2025, 108, 74
of it cells: an eighth of the 2013 price. 2022 is the only year it went up. The rest of the pack
stayed about a third of the price, so it got cheaper as fast as the cells. These are averages over
everything BloombergNEF surveyed: cars, buses, two-wheelers and storage. Battery-electric car packs
alone were 99 dollars.

*[ask]* At 99 dollars, what does a 40 kilowatt-hour pack like the Leaf's cost to make today?
*[pause]* About 4,000 dollars. At the 2013 average, over 30,000.

Careful with price headlines. BloombergNEF restates its history in each year's dollars. Last year it
gave 115 for 2024; here it is 118. Use one series. Never mix press releases from different years.

Stationary storage packs averaged 70 dollars, down 45 percent in a year. That matters for charging:
a station with a battery can draw a steady current from a weak grid connection.

*[ask]* Put LFP instead of NMC into the Leaf's 40 kilowatt-hour pack at 2025 prices. How much
cheaper, and how much heavier? *[pause]* The chemistry slide gave NMC packs at 128 dollars per
kilowatt-hour and LFP at 81: 47 dollars less, times 40, about 1,900 dollars. LFP packs store about
a fifth less per kilogram: 132 becomes about 106 watt-hours per kilogram, so 40,000 watt-hours need
about 380 kilograms instead of 303.

On the right: over the decade, energy density rose about 60 percent and price fell about 75. A
European pack costs about 130, one and a half times China's 84.

So a cell is cheap, getting cheaper, and stores up to 265 watt-hours per kilogram. What it does not
have is the fixed voltage Lecture 4 gave it. That is section 02, the Thevenin cell.
-->
