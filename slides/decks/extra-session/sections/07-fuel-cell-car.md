---
routeAlias: fuel-cell-car
layout: section
---

###### Section 07

# The fuel-cell car

A series hybrid with a different source: Lecture 5's shape with a stack in place of the
engine-generator, and its efficiency from the power plant to the wheel against a battery car.

<!--
Section 07, the fuel-cell car. There is nothing new to model here: a fuel-cell car is Lecture 5's
series hybrid, with a fuel-cell stack where the engine-generator was. We look at the Mirai in that
shape, at how the source and the buffer battery are sized, and then at the question that decides
its future: how much electricity reaches the wheel, against a battery car.
-->

---
routeAlias: mirai-series-hybrid
---

## The Mirai is a series hybrid

<div class="grid grid-cols-[1.25fr_1fr] gap-8 items-center">
<div>

<div class="placeholder">

**Diagram** `/diagrams/07-mirai-series.svg`

Lecture 5's series-hybrid diagram (`lecture-05/public/diagrams/02-series.svg`) redrawn with the
engine-generator replaced: three H₂ tanks (5.6 kg) → stack (330 cells, 128 kW) → boost DC-DC
converter → DC link; buffer battery (Li-ion, 84 cells, 310.8 V, 1.24 kWh) on the same link;
inverter → motor (134 kW, 300 N·m) → rear wheels; regen arrow back to the battery. Orange
electrical, black shafts, as in Lecture 5. Values: `hydrogen.md` §4.

</div>

</div>
<div class="text-[0.95rem]">

| Lecture 5 | Mirai gen 2 |
|---|---|
| engine-generator | **stack, 128 kW** |
| battery | **1.24 kWh**, 310.8 V |
| motor | **134 kW**, 300 N·m, RWD |
| fuel | **5.6 kg H₂**, 0.79 kg/100 km |

The battery is a **power buffer**: it takes regen and covers transients; the stack does the
driving.

<div class="caption text-left">[TOYOTA-UK-MIRAI-2020], [TOYOTA-UK-MIRAI-SPECS-2024] verified ·
1.24 kWh: 310.8 V × 4.0 Ah, derived</div>

</div>
</div>

<!--
The diagram is Lecture 5's series hybrid, redrawn. Orange lines are electrical, black lines are
shafts, as in Lecture 5. Where Lecture 5 had the engine turning a generator, the Mirai has its three
hydrogen tanks feeding the fuel-cell stack. The stack's voltage falls with load, so a boost
converter lifts it onto the DC link. The battery sits on the same link. The inverter and the motor
drive the rear wheels, and regenerative braking goes back to the battery. Again, no shaft runs from
the source to the wheels.

The table maps the parts. The engine-generator becomes the 128 kilowatt stack. The battery is a
lithium-ion pack of 84 cells at 310.8 volts and 4.0 ampere-hours: 1.24 kilowatt-hours, my
multiplication. That is smaller than Lecture 5's P2 hybrid battery, 1.4 kilowatt-hours. The motor:
134 kilowatts, 300 newton meters, rear-wheel drive. The fuel: 5.6 kilograms of hydrogen, used at
0.79 kilograms per 100 kilometers on WLTP.

So the battery is a power buffer, not an energy store. It catches the braking energy and covers the
moments when the stack cannot follow the driver; the stack does the driving. The energy manager's
job is the one you wrote for the series-hybrid homework, with the stack's efficiency curve from
section 05 in place of the engine's fuel map: and that curve is best at light load.
-->

---
routeAlias: source-and-buffer
skipInCut: true
---

## Sizing the source and the buffer

<div class="tight">

| Car | Fuel cell | Battery | Motor | H₂ | Consumption |
|---|---|---|---|---|---|
| Toyota Mirai gen 2 | 128 kW | 1.24 kWh | 134 kW | 5.6 kg | 0.79 kg/100 km |
| Hyundai Nexo (2025) | 110 kW gross / **94 kW net** | **2.64 kWh**, 80 kW | 150 kW | 6.69 kg | 0.81 kg/100 km |
| Honda CR-V e:FCEV | 92.2 kW | **17.7 kWh**, plug-in | — | 4.3 kg | 29 mi electric (EPA) |
| Hyundai XCIENT truck | 180 kW | 72 kWh | 350 kW | ≈ 68 kg | 450 mi max |

</div>

**The degree of hybridization again** (Lecture 5): from a power buffer (Mirai) to a plug-in that
drives on its battery first (CR-V).

<div class="caption text-left">[TOYOTA-UK-MIRAI-SPECS-2024], [HYUNDAI-NEXO-2025], [HYUNDAI-XCIENT-2025]
verified · [HONDA-CRV-EFCEV-2024] secondary</div>

<!--
How big should the stack be, and how big the battery? Four vehicles, one per row. Columns: fuel-cell
power, battery, motor, hydrogen stored, consumption or range.

The Mirai: 128 kilowatt stack, 1.24 kilowatt-hour battery, 134 kilowatt motor, nearly all its
power from the stack. The new Nexo: 110 kilowatts gross, 94 net after the balance of plant, and a
bigger buffer, 2.64 kilowatt-hours that can give 80 kilowatts, for a 150 kilowatt motor; the
battery now carries a large share of the peak power. Honda's CR-V e:FCEV goes further: a 92 kilowatt
fuel cell and a 17.7 kilowatt-hour battery you plug in, good for 29 miles on electricity alone by
EPA rating, from Honda's release reproduced on an aggregator, so secondary. And a truck for
contrast: Hyundai's XCIENT, 180 kilowatt fuel cell, 72 kilowatt-hour battery, 350 kilowatt motor,
about 68 kilograms of hydrogen, up to 450 miles.

This is Lecture 5's degree of hybridization with a different source: the share of the peak power
that comes from the battery. At one end the Mirai uses its battery as a power buffer; at the other
the CR-V is a plug-in hybrid that drives on its battery first.
-->

---
routeAlias: power-to-wheel
---

## Power to wheel: BEV 69 %, FCEV 26 %

<div class="grid grid-cols-[1.3fr_1fr] gap-6 items-start">
<div>

<div class="placeholder">

**Figure** `/figures/07-efficiency-chain.svg`

Two horizontal step-down bars from 100 % renewable electricity. BEV: transmission 95 % → battery
charge/discharge 90 % → motor 85 % → drivetrain 95 % = **69 %**. FCEV: transmission 95 % →
electrolysis 70 % → compression/transport 80 % → fuel cell 60 % → motor 85 % → drivetrain 95 % =
**26 %**. Values printed on each step. Redrawn from Agora 2018 slide 7 (`hydrogen.md` §5,
[AGORA-SYNCOST-2018], read from figure ±0.5 %).

</div>

</div>
<div class="text-[0.9rem]">

**Per 100 km, bottom-up:**

Mirai: 0.79 kg × (55 electrolysis + 3.0 compression + 0.2 precool) kWh/kg = **46.0 kWh** of
electricity.

Leaf: **17.1 kWh** at the grid.

→ **≈ 2.7×** the electricity for the same distance.

Agora: "about two and a half times".

<div class="caption text-left">[DOE-PEM-TARGETS], [DOE-REC-9013-2009], [TOYOTA-UK-MIRAI-SPECS-2024]
verified · Leaf: `energy-prices-cz.md` · 46.0 and 2.7: derived</div>

</div>
</div>

<!--
The decisive comparison. The figure follows 100 units of renewable electricity to the wheel, step
by step, for a battery car and a fuel-cell car. It is redrawn from an Agora Energiewende study
slide; the values are printed on their figure, so they are exact to rounding.

The battery car, top bar. 95 percent survives the grid. 90 percent of that survives charging and
discharging the battery. The motor passes 85, the gears 95. What reaches the wheel: 69 percent.

The fuel-cell car, bottom bar. The same grid, 95 percent. Electrolysis turns 70 percent of the
electricity into hydrogen. Compressing and transporting it keeps 80 percent. The fuel cell turns 60
percent back into electricity. Then the same motor and gears. What reaches the wheel: 26 percent.
The two chains share the motor and the gears; the difference is that the fuel-cell car converts the
energy twice more, into hydrogen and back.

On the right, the same from the bottom up with our own primary numbers. A PEM electrolysis system
uses 55 kilowatt-hours per kilogram today, DOE's 2022 status; compression about 3.0, precooling 0.2.
Times the Mirai's 0.79 kilograms per 100 kilometers: 46.0 kilowatt-hours of electricity per 100
kilometers, before transport and station losses. The Leaf takes 17.1 from the grid. So the fuel-cell
car needs about 2.7 times the electricity for the same distance, my division, close to Agora's
"about two and a half times".
-->

---
routeAlias: hydrogen-colors
skipInCut: true
---

## Where the hydrogen comes from

<div class="grid grid-cols-2 gap-8">
<div>

**Emissions, kg CO₂-eq per kg H₂:**

| Route | kg CO₂-eq/kg |
|---|---:|
| natural gas, unabated (SMR) | **10–14** |
| coal gasification, unabated | **22–26** |
| grid electrolysis, world average grid (460 g/kWh) | **24** |
| electrolysis, Swedish grid | as low as **0.5** |

Global average, 2021: **12–13**.

</div>
<div>

**Production today:** natural gas **62 %**, coal about a fifth.

**Low-emissions hydrogen:** almost **1 Mt** in 2025; electrolysis capacity doubled to over
**4 GW**.

**The IEA's proposal:** define hydrogen by its measured emissions, not by "colors".

<div class="caption text-left">[IEA-H2-DEF-2023], [IEA-GHR-2026] verified</div>

</div>
</div>

<!--
Where does the hydrogen come from, and what does it emit? All from the IEA, verified.

The table: kilograms of CO2 equivalent per kilogram of hydrogen. From natural gas by steam methane
reforming, without carbon capture: 10 to 14, of which about 9 is the plant itself and the rest
methane and CO2 upstream. From coal: 22 to 26. From electrolysis on the world's average grid, 460
grams per kilowatt-hour: 24, as bad as coal. On Sweden's grid: as low as 0.5. The global average in
2021 was 12 to 13.

Production today is 62 percent natural gas and about a fifth coal. Low-emissions hydrogen reached
almost one million tonnes in 2025, and electrolyzer capacity doubled to over 4 gigawatts.

That is why the IEA proposes to define hydrogen by its measured emissions intensity, rather than by
the usual colors, grey, blue and green: hydrogen from electrolysis is only as clean as the
electricity behind it.
-->

---
routeAlias: where-hydrogen-fits
skipInCut: true
---

## Where hydrogen fits

<div class="grid grid-cols-2 gap-8">
<div>

**For hydrogen in cars:**

- a 3-minute fill and a 400-mile range
- no grid connection at the car

**Against:**

- about 2.5× the electricity of a BEV per km
- 50 public stations in Germany, 2 in Czechia, closures
- energy cost above petrol at reported prices

</div>
<div>

**Where it is growing:** trucks and buses use about **90 %** of road hydrogen; stock growth
comes from Chinese trucks.

**Even there:** Daimler's series truck slipped to the early 2030s; Czech operators order
battery-electric buses.

**AFIR's stations** must serve heavy-duty vehicles too.

<div class="caption text-left">[IEA-GHR-2026], [AFIR-2023-1804] verified · Daimler, Ostrava:
`hydrogen.md` §4, §7, secondary / search summary</div>

</div>
</div>

<!--
To close the section, the case on both sides, from the numbers of the last hour.

For hydrogen in cars: a fill takes about three minutes, the Mirai's range is up to 400 miles by
Toyota, and the car needs no grid connection where it parks. Against: two and a half times the
electricity of a battery car per kilometer; a thin and shrinking network, 50 public stations in
Germany and two in Czechia; and an energy cost above petrol at the price reported for Prague.

Where is it growing? In heavy vehicles. The IEA: trucks and buses use about 90 percent of the
hydrogen on the road, and the growth in the vehicle stock comes from trucks in China. Even there it
is not settled: Daimler pushed series production of its hydrogen truck to the early 2030s, reported
by trade press, and Ostrava's recent bus orders are battery-electric, a search summary. AFIR's
stations, for their part, must serve heavy vehicles too.
-->
