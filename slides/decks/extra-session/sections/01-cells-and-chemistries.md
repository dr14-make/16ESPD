---
routeAlias: cells-and-chemistries
layout: section
---

###### Section 01

# Cells and chemistries

Deck 8's tour cut to what is on the road now: LFP, NMC and sodium-ion, their specific energy, and
what a kilowatt-hour costs today.

<!--
Section 01, cells and chemistries. Deck 8 walks through every battery chemistry from lead acid
onwards. We cut it to the three that matter in a car bought today: lithium iron phosphate, LFP;
nickel manganese cobalt, NMC; and sodium-ion, which is just arriving. For each: what one kilogram
stores, what one kilowatt-hour costs, and the voltage it is charged to.
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
Deck 8 tours the chemistries in historical order: lead acid, nickel-cadmium, nickel-metal hydride
and finally lithium-ion. Lecture 4 showed its Ragone plot for lead acid and nickel-cadmium. Today
every new electric car carries lithium-ion, in two families, and a third is arriving.

NMC has a cathode of layered nickel, manganese and cobalt oxide; it stores the most energy per
kilogram. LFP has a cathode of lithium iron phosphate; it is cheaper, runs at a lower voltage, and
its voltage curve is nearly flat, which matters for the battery management system in section 03.
Sodium-ion replaces lithium with sodium, a far more common element.

On the right, the market, from the IEA's Global EV Outlook 2026. In 2025 LFP made up over 55 percent
of the EV batteries deployed worldwide, up from nearly 50 percent in 2024. The IEA counts this by
the battery capacity of new electric cars registered. In the EU it is still more than 10 percent of
demand: European cars mostly carry NMC. The total deployed in 2025 was 1.2 terawatt-hours.
-->

---
routeAlias: chemistry-table
---

## LFP, NMC and sodium-ion side by side

<div class="tight">

| | NMC | LFP | Sodium-ion |
|---|---|---|---|
| Best cell specific energy (2026) | up to **265 Wh/kg** | up to **205 Wh/kg** | up to **175 Wh/kg** |
| Pack specific energy | — | about **one-fifth lower** than NMC | TODO: no source in the notes |
| Average pack price, 2025 | **$128/kWh** | **$81/kWh** | TODO: no source in the notes |
| Charge voltage (CV), example cell | **4.20 V** (LG M50LT, NMC 811) | **3.6 V** (A123 26650) | TODO: no source in the notes |

</div>

<div class="caption text-left">Cells: IEA GEVO 2026 p. 101 [IEA-GEVO-2026] · pack Wh/kg: IEA GEVO
2025 [IEA-GEVO-2025] · prices: BloombergNEF, Dec 2025 [BNEF-2025] · CV: datasheets [LG-M50LT-2020],
[LW-26650-2022]</div>

**For scale:** the 2018 Leaf's 40 kWh pack weighs 303 kg, about **132 Wh/kg** at pack level.

<!--
The one table to take from this section. Three columns, one per chemistry; four rows.

First row: the best cell specific energy, in watt-hours per kilogram of cell, from the IEA's 2026
outlook. The latest NMC cells reach up to 265, LFP up to 205, sodium-ion up to 175. These are best
in class, not fleet averages, and the IEA's sentence reads as cell level, though it does not say
"cell" for NMC and LFP explicitly.

Second row: at pack level the IEA gives only a ratio: an LFP pack stores about one-fifth less per
kilogram than an NMC pack. No source in our notes gives an absolute pack value per chemistry, or a
sodium-ion pack figure.

Third row: average pack prices across all uses in BloombergNEF's December 2025 survey: LFP 81
dollars per kilowatt-hour, NMC 128. No sodium-ion price in our notes.

Fourth row: the voltage a cell is charged to, read from two datasheets: 4.20 volts for the LG M50LT,
an NMC 811 cell, and 3.6 volts for the A123 LFP cell. Section 04 comes back to these.

The line at the bottom gives scale: Nissan's dismantling guide puts the 2018 Leaf's 40
kilowatt-hour pack at 303 kilograms, so about 132 watt-hours per kilogram for the whole pack, half
of the best NMC cell. That is my division, 40 over 303.
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
Lecture 4 showed this price curve once; here it is with the split between cell and pack. Across
are the years 2013 to 2025. Up is the average pack price in dollars per kilowatt-hour, in real 2025
dollars, so every year is on one basis. Each bar is split in two: the cell, and the rest of the
pack, meaning the casing, the cooling, the wiring and the electronics.

In 2013 a pack cost 827 dollars per kilowatt-hour, 568 of it the cell. In 2025 it cost 108, of
which 74 is the cell. That is BloombergNEF's survey average across cars, buses, two-wheelers and
stationary storage. Battery-electric car packs alone were the cheapest segment at 99 dollars per
kilowatt-hour.

The IEA puts the decade in one sentence: average pack energy density up about 60 percent, price
down about 75 percent. And the price depends on where the pack is made: 84 dollars in China, 44
and 56 percent more in North America and Europe.
-->
