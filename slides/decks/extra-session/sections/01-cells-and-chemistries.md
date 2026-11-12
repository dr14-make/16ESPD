---
routeAlias: cells-and-chemistries
layout: section
---

###### Section 01

# Cells and chemistries

Deck 8's tour cut to what is on the road now: LFP, NMC and sodium-ion, their specific energy, and
what a kilowatt-hour costs today.

<img class="hero" src="/photos/01-bmw-i3-cells.jpg" alt="Rows of flat aluminum prismatic cells, each with two threaded terminal posts and a vent window, labeled SB LiMotive, sample cells for the BMW i3."/>

<div class="caption">BMW i3 prismatic cells, SB LiMotive · RudolfSimon, CC BY-SA 3.0</div>

<!--
Before we ask how fast energy goes back into a car, we need to know what it goes into. Three
chemistries are in cars sold today: NMC, LFP and, just arriving, sodium-ion. The choice sets three
numbers you will meet again tonight: what a kilogram of cells stores, what a kilowatt-hour costs,
and the voltage the charger must stop at. That last one is where section 04 starts.

*[ask]* A question to carry through the section: if you were buying batteries for a city bus,
which chemistry would you pick, and why? *[pause]* We will have the answer by the end of section
03.

*[show photo]* What a car cell looks like: flat aluminum cans with two terminal posts and a vent,
sample cells made by SB LiMotive for the BMW i3. Photograph by the user RudolfSimon, Wikimedia
Commons.
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
and finally lithium-ion. Lecture 4 showed its Ragone plot. Read off the deck, a lead-acid traction
battery stores about 35 watt-hours per kilogram at low power, nickel-cadmium about 52. Today's best
lithium-ion cells, next slide, reach 265: five times lead acid or more. That is why the tour now
ends at lithium-ion. Every new electric car carries it, in two families, and a third is arriving.

NMC has a layered oxide cathode of nickel, manganese and cobalt. It stores the most energy per
kilogram, and it is charged to 4.2 volts. LFP has a lithium iron phosphate cathode. It stores less,
costs less, is charged to only 3.6 volts, and its voltage hardly changes over most of its charge.
Keep that last property in mind: in section 03 it makes the BMS's job much harder. Sodium-ion
swaps lithium for sodium, a far more common element, and its first cells are only now in cars. Its
best cells already store 175 watt-hours per kilogram against LFP's 205, so it is aimed squarely at
LFP's market: cheap cars and storage, where the price per kilowatt-hour matters more than the
mass.

On the right, the market, from the International Energy Agency's 2026 outlook. In 2025, LFP was
over 55 percent of the EV batteries deployed worldwide, up from nearly 50 percent the year before.
The IEA counts by the battery capacity of the new electric cars registered. In the EU, though, LFP
was only just over a tenth of demand, so Europe is still a nickel market; in the US its share almost
halved in 2025.

The range to keep in mind for lithium-ion as a whole: the IEA puts today's cells between about 90
and 300 watt-hours per kilogram, and LFP conventionally 20 to 30 percent below the high-nickel
cells. The best of each are on the next slide.

*[ask]* The world deployed 1.2 terawatt-hours of EV batteries in 2025. How many 40 kilowatt-hour
Leaf packs is that? *[pause]* 1.2 billion kilowatt-hours over 40: thirty million packs, in one year.

So LFP has taken half the world while storing less per kilogram. The next slide puts the three
chemistries side by side and shows why.
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
stores per kilogram; right, what a pack cost on average in 2025.

*[ask]* Look at the two panels and tell me: LFP stores less per kilogram than NMC. Why is it
now over half of the EV batteries the world deploys? *[pause]*

The answer is the second pair of numbers. The best LFP cells store 205 watt-hours per kilogram
against NMC's 265, and the IEA says an LFP pack is about one-fifth lighter on energy than an NMC
pack. But an LFP pack cost 81 dollars per kilowatt-hour on average in 2025, against 128 for NMC:
about two-thirds of the price. For a cheap car or a bus, a quarter more battery mass is a good trade for
a third off its price. That is why, in 2025, LFP was over 55 percent of the EV batteries deployed
worldwide.

Sodium-ion reaches up to 175 per kilogram at cell level. The empty place in the price panel says
that our sources give no price for it, and no pack figure or charge voltage either: the chemistry is
that new.

Read the cell figures as best in class, not fleet averages: a car built today with LFP may carry
cells well below 205.

The charge voltage on the right is the one for tonight. An NMC cell is charged up to 4.20 volts, an LFP cell up to 3.6.
Section 04 starts from exactly that limit.

The last line on the right gives the scale of a real pack. The 2018 Leaf's 40 kilowatt-hour pack weighs
303 kilograms, about 132 watt-hours per kilogram: half the best NMC cell. The other half goes to the
casing, the cooling, the wiring and the electronics, and to 2018 cells rather than 2026 ones.
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
Lecture 4 showed this price curve once; here it is split between the cells and the rest of the
pack. Across, the years 2013 to 2025. Up, the average pack price in dollars per kilowatt-hour, every
year in 2025 dollars, so the bars compare directly. Each bar is split in two: the cells, and the
rest of the pack, meaning the casing, the cooling, the wiring and the electronics.

*[show figure]* In 2013 a pack cost 827 dollars per kilowatt-hour, 568 of it cells. In 2025 it cost
108, of which 74 is cells. That is an eighth of the 2013 price. The fall was not smooth: 2022 is the
one year the bar went up. And notice the split: the rest of the pack is about a third of the price
in both 2013 and 2025. The rest of the pack got cheaper as fast as the cells did.

These are averages over everything BloombergNEF surveyed: cars, buses, two-wheelers and stationary
storage. Battery-electric car packs alone were the cheapest transport segment, at 99 dollars.

*[ask]* At 99 dollars per kilowatt-hour, what does a 40 kilowatt-hour pack like the Leaf's cost to
make today? *[pause]* About 4,000 dollars. At the 2013 average it would have cost over 30,000.

One trap when you read old price headlines: BloombergNEF restates its whole history in each year's
dollars. Last year's survey announced 115 dollars for 2024; in this chart, in 2025 dollars, 2024 is
118. Same survey, different dollar. Use one series, as the chart does, and never mix press releases
from different years.

And the cheapest batteries of all are not in cars: stationary storage packs averaged 70 dollars per
kilowatt-hour in 2025, 45 percent down in a year. That matters for charging too: a fast-charging
station with a battery can draw a steady current from a weak grid connection.

*[ask]* Put the two chemistries into the Leaf's 40 kilowatt-hour pack at 2025 average prices. How
much cheaper is LFP, and how much heavier? *[pause]* 47 dollars a kilowatt-hour less, times 40:
about 1,900 dollars. And with a pack one-fifth lighter on energy, 303 kilograms become about 380:
some 75 kilograms more. For a city car, many buyers would take the money.

Two more facts on the right. The IEA puts the last decade in one sentence: average pack energy
density up about 60 percent, price down about 75. And place matters: a pack made in China cost 84
dollars per kilowatt-hour; North America and Europe paid 44 and 56 percent more, which puts a
European pack at about 130.

So a cell is cheap, getting cheaper, and stores 200 to 265 watt-hours per kilogram at its best.
What it does not have is the fixed voltage Lecture 4 gave it. That is section 02.
-->
