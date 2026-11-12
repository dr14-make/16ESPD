---
routeAlias: cells-and-chemistries
layout: section
---

###### Section 01

# Cells and chemistries

A battery's terms on the Leaf's pack, then deck 8's tour cut to what is on the road now: LFP, NMC
and sodium-ion, their specific energy, and what a kilowatt-hour costs today.

<img class="hero" src="/photos/01-bmw-i3-cells.jpg" alt="Rows of flat aluminum prismatic cells, each with two threaded terminal posts and a vent window, labeled SB LiMotive, sample cells for the BMW i3."/>

<div class="caption">BMW i3 prismatic cells, SB LiMotive · RudolfSimon, CC BY-SA 3.0</div>

<!--
Before we ask how fast energy goes back into a car, we need to know what it goes into. NMC, LFP and,
just arriving, sodium-ion: the choice sets what a kilogram stores, what a kilowatt-hour costs, and
the voltage the charger must stop at.

*[ask]* A question to carry through: which chemistry would you buy for a city bus, and why?
*[pause]* We answer it in section 03.

*[show photo]* Car cells: sample prismatic cans for the BMW i3. But first the words a spec sheet
uses, on the Leaf's pack.
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
| **State of charge** *SoC* | the share of *Q* still in the cells | % | counted (section 03) |
| **Specific energy** | energy per kilogram | Wh/kg | **132** pack (303 kg) |
| **Energy density** | energy per liter | Wh/L | **≈ 82** pack (485 L box) |
| **Specific power** | power per kilogram | W/kg | **≈ 360** at the motor's 110 kW |
| **Energy efficiency** | energy out ÷ energy in, round trip | % | **95–98** (2013 Leaf) |

</div>

<div class="caption text-left">40 kWh, 350 V, 110 kW: Nissan [N-JP-ZE1] · 303 kg, 1547 × 1188 × 264 mm: Nissan US
guide · 39 kWh usable, 96s2p: EV Database, secondary · 56.3 Ah: Gao et al. 2024 · round trip:
ANL 2013 · Wh/kg, Wh/L, W/kg: derived</div>

<div class="handson">New tonight: nominal voltage, and gross against usable. The rest is Lecture 4's.</div>

<!--
The vocabulary on one pack, so every number tonight has a place to land. Lecture 4 gave you
capacity, energy, state of charge and the efficiencies; two words are new.

Nominal voltage is the average over a full discharge: 3.65 volts per cell, 96 in series, 350 volts.
The pack actually swings from about 240 volts empty to 420 full.

Gross is what the cells hold; usable is what the car lets you take out, because the BMS keeps a
margin at the top and the bottom, where the cell ages fastest. On the Leaf, 40 against 39.

*[ask]* Two cars advertised at 77 kilowatt-hours, one gross, one usable. Which goes further?
*[pause]* The usable one: all its 77 come out.

Per kilogram: 132 watt-hours for the pack, and about 360 watts at the motor's 110 kilowatts peak.
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
| Leaf, DC charge peak | 46 kW | **1.2 C** |
| IONIQ 5 84 kWh, DC peak | 263 kW | **3.1 C** |

</div>

</div>
<div>

**Peak against continuous.** A peak lasts seconds, a continuous rating holds until the heat
settles:

- Leaf motor: **110 kW** peak, **85 kW** rated.
- 2013 Leaf pack (24 kWh): **103 kW** for 30 s discharging (**4.3 C**), **80 kW** for 10 s
  charging.

**Power depends on the state.** Measured at every 10 % of depth of discharge: an empty pack has a
higher resistance, so it gives less power; a full pack takes less.

<div class="caption text-left">Leaf: Nissan [N-JP-ZE1], INL 2014 [INL-5045] · IONIQ 5 and Leaf DC: Fastned, Hyundai
[charging.md] · WLTC: 17.1 kWh/100 km × 46.5 km/h · C-rates derived</div>

</div>
</div>

<!--
The one new unit tonight, and you will hear it at every charger: the C-rate, current over capacity,
or power over energy. One C empties the battery in an hour. It does not care about size, so a
datasheet gives its limits as C-rates.

*[show table]* The Leaf on the WLTC: a fifth of a C. Its motor peak 2.8 C, its DC charge 1.2 C. The
IONIQ 5 charges at 3.1 C.

*[ask]* Which of these worries the cell most? *[pause]* The charge. Pushed too hard, too cold, the
lithium plates on the graphite as metal instead of going in. A few seconds of discharge at 2.8 C is
easy by comparison. Section 04 comes back to this.

On the right: a peak lasts seconds, a continuous rating holds until the temperature settles. The
2013 Leaf pack gave 103 kilowatts for 30 seconds, so the motor, not the pack, sets the car's peak.
And power changes with the state: an empty, cold pack gives little, a full one takes little.
-->

---
routeAlias: power-costs-energy
---

## Specific energy against specific power: why one costs the other

<div class="diagram-wide">

<img src="/figures/01-rate-capability.svg" style="max-height: 23rem" alt="Left, terminal voltage against charge delivered for one NMC 21700 cell discharged to 2.5 V: 5.1 Ah at 0.2 C, 4.9 at 1 C, 4.7 at 2 C, 2.3 at 3 C; the faster curves sit lower and reach the cutoff sooner. Right, the same runs as specific energy against specific power: 272 Wh/kg at 54 W/kg, falling to 230 at about 490 W/kg at 2 C and 110 at about 720 W/kg at 3 C."/>

</div>

<div class="caption">Simulated: PyBaMM DFN model, Chen2020 parameters of the LG M50 cell, 25 °C, per 68.2 g (M50LT
datasheet). A model, not a measurement: take the shape.</div>

<div class="grid grid-cols-3 gap-6 text-sm mt-2">
<div>

**1 · Resistance.** *V* = OCV − *R i*: the curve drops and hits the cutoff sooner; *R i*² heats
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
Lecture 4 showed the deck's Ragone plot: more power, less energy. Here is why, on one cell of today.

*[show figure]* One NMC cell, simulated, emptied at four currents. At a fifth of a C it gives 5.1
ampere-hours; at 2 C, 4.7; at 3 C only 2.3. The faster curves sit lower and hit the cutoff sooner.

*[ask]* Where did the missing charge go at 3 C? *[pause]* Nowhere: it is still in the cell. The
cell could not deliver it in time.

Three reasons. Resistance: OCV minus R i shifts the curve down, and R i squared is heat. Transport,
which makes the cliff: at 3 C the electrolyte runs out of ions near one electrode, and the voltage
collapses with half the lithium still in the anode. On the right, the same runs per kilogram: flat,
then over the edge. Take the shape, not the 3 C number; the real cell is allowed 3 C.

And design: thin electrodes carry ions fast but more foil and separator per watt-hour. LG's energy
cell stores 267 watt-hours per kilogram at up to 3 C; A123's power cell 113, at 20 C.

*[ask]* Which for a hybrid's buffer battery, which for a battery car? *[pause]* Power cells for the
hybrid's small, hard-worked pack; energy cells for range, enough that the C-rate stays low.
-->

---
routeAlias: cell-to-pack
skipInCut: true
---

## From cell to pack: series adds volts, parallel adds amp-hours

<div class="diagram-wide">

<img src="/diagrams/01-cell-to-pack.svg" alt="Leaf pack schematic: 96 groups in series, each two cells in parallel. Two in parallel add amp-hours, 2 × 56 Ah = 113 Ah; 96 in series add volts, 96 × 3.65 V = 350 V; E = Ns · Np · V_cell · Q_cell ≈ 40 kWh."/>

</div>

<div class="tight">

| | Cells | Cell | Pack | Gross / usable | Cell / pack Wh/kg |
|---|---|---|---|---|---|
| **Leaf 40 kWh** | 192, **96s2p**, 24 modules | 56.3 Ah, 3.65 V, 914 g | 113 Ah, **350 V** | 40 / 39 kWh | **224 / 132**: cells are 58 % of the mass |
| **IONIQ 5 84 kWh** | 384, **192s2p**, 32 modules | ≈ 60 Ah, 3.63 V | 120.6 Ah, **697 V** | 84 / 80 kWh | pack mass: no primary |

</div>

<div class="caption text-left">Leaf cell: AESC product page (2019) · 96s2p, modules: secondary · IONIQ 5: Hyundai spec
sheet and emergency response guide (IONIQ 5 N, same pack) · usable: EV Database, secondary · cell
values for the IONIQ 5 and the mass share: derived [battery-terms.md]</div>

<!--
How cells become a pack. *[show diagram]* Cells in parallel share one voltage and add their
amp-hours; groups in series carry one current and add their volts. The Leaf pairs 56 amp-hour cells
into 113 amp-hour groups, then puts 96 groups in series: 350 volts. The energy is the product at the
bottom: 96 times 2 times 3.65 times 56.3, about 39.5 kilowatt-hours. Nissan sells it as 40.

*[ask]* The IONIQ 5 is an 800 volt car. Did Hyundai use bigger cells? *[pause]* No: its cells are
about the Leaf's size, 60 amp-hours, 3.63 volts. It puts 192 groups in series instead of 96, so the
voltage doubles to 697 volts nominal. For the same power the current halves, and with it the R i
squared loss in every cable. Section 04's 800 volt story starts here, in the series count.

The last column is what the box costs you. AESC gives the Leaf cell as 914 grams and 224 watt-hours
per kilogram; the pack is 132. The cells are only 58 percent of the mass; the rest is module frames,
busbars, cooling, case and electronics. That ratio is where much of the progress since 2018 went:
cell-to-pack designs drop the module frames altogether.

The usable figures come from a database, not the makers, so treat them as close, not exact.
-->

---
routeAlias: soc-dod-soh
skipInCut: true
---

## How full, how deep, how worn: SoC, DoD and SoH

<div class="grid grid-cols-[3fr_2fr] gap-6 items-start">
<div>

<img src="/figures/01-ageing.svg" alt="Two bar panels for NMC 18650 cells. Left, full cycles to 80 percent capacity at 25 °C: about 450 cycling 0–100 percent SoC, 1,650 at 20–80, 2,150 at 40–60. Right, capacity lost after 10 months of storage: at 25 °C about 2.5 percent at 50 percent SoC against 6.5 at 100; at 50 °C about 12 against 23."/>

<div class="caption">NMC 18650 cells, not car cells · read from figures: Preger et al., JES 2020, Fig. 2a; Keil et al.,
JES 2016, Fig. 2b</div>

</div>
<div>

$$
DoD = 1 - SoC
$$

$$
SoH = \frac{Q_\text{now}}{Q_\text{new}}
$$

- **Cycle ageing** grows with the window: shallow cycles last longer.
- **Calendar ageing** runs parked: faster when full and hot. LFP: ≈ 0.2 points a month at 25 °C.
- **Euro 7**, new cars: **≥ 80 %** of usable energy at 5 years or 100,000 km, **≥ 72 %** at 8
  years or 160,000 km (types from 29 Nov 2026).
- **Warranties:** 8 years or 160,000 km, to **70 %** (Hyundai) or 9 of 12 bars (Nissan).

<div class="caption text-left">EU 2024/1257 Annex II, Art. 10 · Hyundai EU, Nissan BE · LFP: Keil 2016</div>

</div>
</div>

<!--
Three words for the state of the battery. State of charge: how full. Depth of discharge, one minus
SoC: how far down you have gone. State of health: the capacity now over the capacity new; Euro 7
measures it in usable energy, but the idea is the same.

*[show figure]* The depth decides how long a cell lives. Sandia cycled one NMC cell over three SoC
windows at 25 degrees until it had lost a fifth of its capacity. Full to empty: about 450 full
cycles. Between 20 and 80 percent: 1,650. Between 40 and 60: 2,150. These are equivalent full
cycles, so a 40 to 60 cycle counts as a fifth of one; the shallow windows are not cheating. The ends,
nearly full and nearly empty, do the damage. That is why the car keeps a margin, and why the app
suggests charging to 80 percent.

On the right, ageing while parked, ten months in storage. At 25 degrees, kept half full, the cell lost
about 2.5 percent; kept full, 6.5. At 50 degrees, 12 against 23. Full and hot is the worst way to
park a battery. LFP ages far less sitting still: about 0.2 points a month.

These are small laboratory cells, 18650s, not car cells, so take the shape, not the numbers; section 04 has the fleet: 2.3
percent a year.

*[ask]* Euro 7 demands at least 72 percent at 8 years for new types from the end of this month.
Hyundai's warranty pays out below 70. Which is the stricter promise? *[pause]* The law, by two
points.
-->

---
routeAlias: what-is-on-the-road
skipInCut: true
---

## From deck 8 to the road

<div class="grid grid-cols-2 gap-8">
<div>

**Deck 8's tour:** lead acid, nickel-cadmium, nickel-metal hydride, lithium-ion. Lecture 4
recalled its Ragone plot.

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

<div class="caption text-left">IEA, Global EV Outlook 2026, pp. 92, 96 [IEA-GEVO-2026]</div>

</div>
</div>

<!--
Deck 8 tours the chemistries in historical order: lead acid, nickel-cadmium, nickel-metal hydride,
lithium-ion. Lead acid stores about 35 watt-hours per kilogram, nickel-cadmium about 52; today's
best lithium-ion cells reach 265, five times lead acid. Every new electric car carries lithium-ion,
in two families, and a third is arriving.

NMC has a layered nickel-manganese-cobalt oxide cathode: the most energy per kilogram, charged to
4.2 volts. LFP has an iron phosphate cathode: it stores less, costs less, is charged to only 3.6
volts, and its voltage hardly changes over most of its charge. Keep that in mind: in section 03 it
makes the BMS's job much harder. Sodium-ion swaps lithium for a far more common element; its best
cells store 175 watt-hours per kilogram against LFP's 205, aimed at LFP's market.

On the right, the market, from the IEA's 2026 outlook. In 2025 LFP was over 55 percent of the EV
batteries deployed worldwide, up from nearly 50 the year before. In the EU only just over a tenth:
Europe is still a nickel market. For lithium-ion as a whole, the IEA puts today's cells between
about 90 and 300 watt-hours per kilogram.

*[ask]* The world deployed 1.2 terawatt-hours of EV batteries in 2025. How many 40 kilowatt-hour
Leaf packs is that? *[pause]* Thirty million, in one year.

So LFP has taken half the world while storing less per kilogram. The next slide shows why.
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

<div class="caption text-left">Pack Wh/kg: IEA GEVO 2025 [IEA-GEVO-2025] · CV: datasheets
[LG-M50LT-2020], [LW-26650-2022]</div>

</div>
</div>

<!--
The one chart to take from this section. *[show figure]* Left, what the best cell of each chemistry
stores per kilogram; right, what a pack cost in 2025.

*[ask]* LFP stores less per kilogram than NMC. Why is it over half of the EV batteries the world
deploys? *[pause]* Price: 81 dollars per kilowatt-hour against 128, about two-thirds. For a cheap
car or a bus, a quarter more battery mass is a good trade for a third off the price. Sodium-ion
reaches 175 per kilogram, but our sources give no price for it yet.

The cell figures are best in class, not fleet averages.

The charge voltage on the right is the one for tonight: NMC up to 4.20 volts, LFP 3.6. Section 04
starts from that limit. And the Leaf's 132 per kilogram is half the best NMC cell: the rest is
casing, cooling and wiring.
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

- **Pack price, all segments:** **$108/kWh** in 2025, −8 % on 2024; BEV packs **$99/kWh**.
- **Cell vs pack, 2025:** **$74** of the 108 is the cell.
- **The last decade:** pack energy density **+60 %**, price **−75 %**.
- **Regions:** China **$84/kWh**; North America and Europe 44 % and 56 % higher.

<div class="caption text-left">[BNEF-2025] · decade: [IEA-GEVO-2026] p. 173</div>

</div>
</div>

<!--
Lecture 4 showed this price curve once; here it is split into the cells and the rest of the pack,
every year in 2025 dollars.

*[show figure]* In 2013 a pack cost 827 dollars per kilowatt-hour, 568 of it cells. In 2025, 108, of
which 74 is cells: an eighth of the 2013 price. 2022 is the one year it went up. The rest of the
pack stayed about a third of the price throughout: it got cheaper as fast as the cells did.
These are averages over everything BloombergNEF surveyed, cars, buses, two-wheelers and storage;
battery-electric car packs alone were 99 dollars.

*[ask]* At 99 dollars, what does a 40 kilowatt-hour pack like the Leaf's cost to make today?
*[pause]* About 4,000 dollars. At the 2013 average, over 30,000.

One trap with price headlines: BloombergNEF restates its history in each year's dollars, so last
year's 115 for 2024 is 118 here. Use one series; never mix press releases from different years.

Stationary storage packs averaged 70 dollars, 45 percent down in a year. That matters for charging:
a station with a battery can draw a steady current from a weak grid connection.

*[ask]* Put LFP instead of NMC into the Leaf's pack at 2025 prices. How much cheaper, and how much
heavier? *[pause]* 47 dollars times 40, about 1,900 dollars; and 303 kilograms become about 380.

On the right: over the decade, energy density up about 60 percent and price down about 75; a
European pack costs about 130, half again China's 84.

So a cell is cheap, getting cheaper, and stores up to 265 watt-hours per kilogram. What it does not
have is the fixed voltage Lecture 4 gave it. That is section 02.
-->
