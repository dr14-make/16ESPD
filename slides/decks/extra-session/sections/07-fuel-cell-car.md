---
routeAlias: fuel-cell-car
layout: section
---

###### Section 07

# The fuel-cell car

A series hybrid with a different source: Lecture 5's shape with a stack in place of the
engine-generator, and its efficiency from the power plant to the wheel against a battery car.

<img class="hero" src="/photos/07-mirai-gen2.jpg" alt="A blue second-generation Toyota Mirai sedan parked on paving stones, seen from the front left."/>

<div class="caption">Mirai (gen 2) · Icke68746, CC0</div>

<!--
You have already met this car. A fuel-cell car is Lecture 5's series hybrid, with a stack where the
engine-generator was. So there is nothing new to model, only a new source to drop in. Then the
question your Lecture 4 bill left open, when it said "tank to wheel only": how much electricity, from
the power plant, reaches the wheel of each car? That decides whether the nozzle's three minutes are
worth it.

*[show photo]* The car: a second-generation Mirai, a CC0 photograph by the user Icke68746 on
Wikimedia Commons.
-->

---
routeAlias: mirai-series-hybrid
---

## The Mirai is a series hybrid

<div class="grid grid-cols-[1.25fr_1fr] gap-8 items-center">
<div>

![Lecture 5's series-hybrid diagram with the engine-generator replaced. Three H2 tanks holding 5.6 kilograms feed the fuel-cell stack, 330 cells and 128 kilowatts; the stack feeds a boost DC-DC converter, which feeds the DC link. The battery, lithium-ion, 84 cells, 310.8 volts, 1.24 kilowatt-hours, sits on the same link, and a dashed regen arrow returns energy to it. The link feeds the inverter, then the motor, 134 kilowatts and 300 newton meters, whose shaft alone drives the rear wheels. No shaft runs from the source to the wheels; the battery is a power buffer and the stack does the driving.](/diagrams/07-mirai-series.svg)

<div class="caption">Orange: electric connections · black: shafts · blue: hydrogen</div>

</div>
<div class="text-[0.95rem]">

<div class="tight">

| Lecture 5 | Mirai gen 2 |
|---|---|
| engine-generator | **stack, 128 kW** |
| battery | **1.24 kWh**, 310.8 V |
| motor | **134 kW**, 300 N·m, RWD |
| fuel | **5.6 kg H₂**, 0.79 kg/100 km |

</div>

The battery is a **power buffer**: it takes regen and covers transients; the stack does the
driving.

<div class="caption text-left">[TOYOTA-UK-MIRAI-2020], [TOYOTA-UK-MIRAI-SPECS-2024] verified ·
1.24 kWh: 310.8 V × 4.0 Ah, derived</div>

<img class="photo mt-2" src="/photos/07-mirai-cutaway.jpg" style="height: 10rem" alt="A first-generation Toyota Mirai cut open along its side at a motor show: power control unit over the motor at the front, the fuel-cell stack under the front seats, the yellow hydrogen tanks under the rear seat."/>

<div class="caption">The same blocks in a car: Mirai (gen 1) cutaway, São Paulo 2016 · Mariordo, CC BY-SA 4.0</div>

</div>
</div>

<!--
*[show figure]* Lecture 5's series hybrid, redrawn. Orange lines are electrical, black lines are
shafts, as in Lecture 5. Where you had the engine turning a generator, the Mirai has three hydrogen
tanks feeding the stack. The stack's voltage falls with load, so a boost converter lifts it onto the
DC link. The battery sits on the same link. The inverter and the motor drive the rear wheels, and
regen goes back to the battery. No shaft runs from the source to the wheels. *[show photo]* Below the table, the same blocks in a
real car, the first Mirai cut open: the stack under the front seats, the tanks under the rear.

The table maps the parts. Engine-generator: the 128 kilowatt stack. Battery: 84 cells at 310.8 volts
and 4 ampere-hours, so 1.24 kilowatt-hours, smaller than the 1.4 in your Lecture 5 P2 hybrid and the
first Mirai's 1.6. Motor:
134 kilowatts, rear drive. Fuel: 5.6 kilograms of hydrogen at 0.79 per 100 kilometers.

*[ask]* With a 1.24 kilowatt-hour battery, what is the battery for? *[pause]* It is a power buffer,
not an energy store. It catches the braking energy and covers the moments when the stack cannot
follow the driver's foot; the stack does the driving.

And the energy manager's job is the one you wrote for the series hybrid, with section 05's efficiency
curve in place of the engine's fuel map. Only now the source is most efficient at light load, not
near full power.
-->

---
routeAlias: source-and-buffer
skipInCut: true
---

## Sizing the source and the buffer

<div class="grid grid-cols-[1.5fr_1fr] gap-8 items-start">
<div>

<img src="/figures/07-fcev-hybridization.svg" alt="Fuel-cell power in kW against buffer-battery energy in kWh on a log scale: Toyota Mirai gen 2, 128 kW, 1.24 kWh, 5.6 kg H₂; Hyundai Nexo 2025, 94 kW, 2.64 kWh, 6.69 kg; Honda CR-V e:FCEV, 92.2 kW, 17.7 kWh, 4.3 kg (a plug-in); Hyundai XCIENT truck, 180 kW, 72 kWh, 68 kg."/>

<div class="caption">[TOYOTA-UK-MIRAI-SPECS-2024] (1.24 kWh derived), [HYUNDAI-NEXO-2025] (net), [HYUNDAI-XCIENT-2025]
verified · [HONDA-CRV-EFCEV-2024] secondary · fuel-cell kW not on one basis (stack, net system,
estimated).</div>

</div>
<div class="text-[0.9rem]">

**The degree of hybridization again** (Lecture 5): from a power buffer (Mirai) to a plug-in that
drives on its battery first (CR-V).

**Motors:** Mirai **134 kW**, Nexo **150 kW**, XCIENT **350 kW**.

**Nexo:** 110 kW gross, its 2.64 kWh battery gives **80 kW**; **0.81 kg/100 km** (Mirai 0.79).

**CR-V:** **29 mi** on electricity (EPA). **XCIENT:** 450 mi max.

</div>
</div>

<!--
How big should the stack be, and how big the battery? *[show figure]* Four vehicles: fuel-cell
power up, battery energy across, on a log scale.

The Mirai: 128 kilowatt stack, 1.24 kilowatt-hour battery, 134 kilowatt motor. Nearly all the power
comes from the stack. The new Nexo: 110 kilowatts gross, 94 net after the balance of plant takes its
share, and a bigger buffer, 2.64 kilowatt-hours that can give 80 kilowatts, for a 150 kilowatt motor.
The battery now carries a large share of the peak power, and the stack can be smaller.

Honda's CR-V e:FCEV goes further: a 92 kilowatt fuel cell and a 17.7 kilowatt-hour battery you plug
in, good for 29 miles on electricity alone by the US rating. It is a plug-in hybrid with a fuel cell
as its range extender.

And a truck for contrast: Hyundai's XCIENT, a 180 kilowatt fuel cell, 72 kilowatt-hours of battery,
a 350 kilowatt motor, about 68 kilograms of hydrogen, up to 450 miles.

*[ask]* In Lecture 5 you put hybrids on a line from micro to plug-in by the degree of
hybridization. Place these four on it. *[pause]* The Mirai is near the full-hybrid end: battery as a
buffer. The Nexo moves along. The CR-V is a plug-in, which drives on its battery first.

Honda also claims the CR-V's fuel-cell system costs two-thirds less than its predecessor's, and
lasts twice as long; the Nexo's total system output rose from 135 to 190 kilowatts. The systems are
improving fast. What they cannot change is the chain behind the nozzle, which is the next slide.

The CR-V is also an admission. If most trips are short, the cheapest energy is the plug. The nozzle
is kept for the long ones.
-->

---
routeAlias: power-to-wheel
---

## Power to wheel: BEV 69 %, FCEV 26 %

<div class="grid grid-cols-[1.3fr_1fr] gap-6 items-start">
<div>

<img src="/figures/07-efficiency-chain.svg" alt="Horizontal bars of the energy left from 100 % renewable electricity. BEV: transmission ×95 % leaves 95, battery charge and discharge ×90 % leaves 85.5, electric motor ×85 % leaves 72.7, mechanical drivetrain ×95 % leaves 69 %. FCEV: transmission ×95 % leaves 95, electrolysis ×70 % leaves 66.5, compression and transport ×80 % leaves 53.2, fuel cell ×60 % leaves 31.9, electric motor ×85 % leaves 27.1, mechanical drivetrain ×95 % leaves 26 %."/>

<div class="caption">Agora Verkehrswende and Agora Energiewende 2018, slide 7, after acatech 2017: step
efficiencies and totals as printed (±0.5 %); the values between multiplied out, derived.</div>

</div>
<div class="text-[0.9rem]">

**Per 100 km, bottom-up:**

Mirai: 0.79 kg × (55 electrolysis + 3.0 compression + 0.2 precool) kWh/kg = **46.0 kWh** of
electricity.

Leaf: **17.1 kWh** at the grid.

→ **≈ 2.7×** the electricity for the same distance.

Agora's totals, 69 / 26: also **≈ 2.7×**; its text rounds to "about two and a half times".

<div class="caption text-left">[DOE-PEM-TARGETS], [DOE-REC-9013-2009], [TOYOTA-UK-MIRAI-SPECS-2024]
verified · Leaf: <code>energy-prices-cz.md</code> · 46.0 and 2.7: derived</div>

</div>
</div>

<!--
The decisive comparison. *[show figure]* The figure follows 100 units of renewable electricity to the
wheel, step by step, for a battery car and a fuel-cell car. It is redrawn from an Agora Energiewende
slide; the totals and the step efficiencies are printed on their slide, and the values in between are
multiplied out.

The battery car, top. 95 percent survives the grid, 90 percent of that survives charging and
discharging the battery, the motor passes 85, the gears 95. At the wheel: 69 percent. The fuel-cell
car, bottom. Same grid. Electrolysis turns 70 percent of the electricity into hydrogen; compressing
and transporting it keeps 80; the fuel cell turns 60 back into electricity; then the same motor and
gears. At the wheel: 26. The difference is two extra conversions, into hydrogen and back.

*[ask]* So for the same distance, how many times the electricity does the fuel-cell car need?
*[pause]* 69 over 26: about 2.7.

On the right, the same from the bottom up, with our own numbers. A PEM electrolyzer today uses 55
kilowatt-hours per kilogram; compression about 3.0, precooling 0.2. Times the Mirai's 0.79 kilograms
per 100 kilometers: 46 kilowatt-hours of electricity per 100 kilometers, before any transport or
station losses. The Leaf takes 17.1 from the wall. Ratio: again about 2.7.

Agora's own text rounds it to "about two and a half times". The two routes differ inside: DOE's
electrolyzer is 61 percent efficient, Agora assumes 70; the bottom-up count leaves out the grid and
transport. They land on the same answer anyway: the nozzle needs about 2.7 times the electricity. Agora's
slide has a third bar, a combustion car on synthetic fuel made from electricity: 13 percent, about
five times the battery car's electricity.
-->

---
routeAlias: hydrogen-colors
skipInCut: true
---

## Where the hydrogen comes from

<div class="grid grid-cols-[1.5fr_1fr] gap-8 items-start">
<div>

<img src="/figures/07-h2-emissions.svg" alt="Horizontal bars of kg CO₂-eq per kg H₂: natural gas (SMR) without CCS 10–14 (range bar), coal gasification without CCS 22–26 (range bar), electrolysis on the world-average grid 24, electrolysis on the Swedish grid 0.5."/>

<div class="caption">IEA 2023, "Towards hydrogen definitions" [IEA-H2-DEF-2023], verified · world grid at 460 g
CO₂-eq/kWh.</div>

**Global average, 2021:** **12–13** kg CO₂-eq per kg H₂.

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
And where does the hydrogen come from today? Not from the renewable electricity of the last slide.
All of this is from the IEA.

*[show figure]* Kilograms of CO2 equivalent per kilogram of hydrogen. From natural gas without carbon
capture: 10 to 14, of which about 9 is the plant itself and the rest methane and CO2 upstream. From
coal: 22 to 26. From electrolysis on the world's average grid, 460 grams per kilowatt-hour: 24, as
bad as coal. On Sweden's grid: as low as 0.5. The world average in 2021 was 12 to 13.

*[ask]* Grey hydrogen at about 12 kilograms of CO2 per kilogram: what does a Mirai emit per 100
kilometers on it? *[pause]* 0.79 times 12: about 9.5 kilograms of CO2 per 100 kilometers, before
the station's compressor.

Production today is 62 percent natural gas and about a fifth coal. Low-emissions hydrogen reached
almost a million tonnes in 2025, and electrolyzer capacity doubled to over 4 gigawatts.

*[ask]* And on Europe's grid? The EEA puts EU electricity at 183 grams of CO2 per kilowatt-hour in
2024. A PEM electrolyzer at 55 kilowatt-hours per kilogram? *[pause]* About 10 kilograms of CO2 per
kilogram of hydrogen: no better than making it from natural gas.

That is why the IEA proposes defining hydrogen by its measured emissions rather than by color, grey,
blue or green: hydrogen from electrolysis is only as clean as the electricity behind it, and it needs
2.7 times as much of that electricity as a battery car.
-->

---
routeAlias: where-hydrogen-fits
---

## Where hydrogen fits

<div class="grid grid-cols-[1fr_1fr] gap-8 items-start">
<div class="text-[0.95rem]">

**For hydrogen in cars:** a 3-minute fill and about 640 km of range (Toyota: up to 400 mi); no grid
connection at the car.

**Against:** about 2.7× the electricity of a BEV per km; 50 public stations in Germany, 2 in Czechia,
closures; energy cost above petrol at the last reported price.

**Where it is growing:** trucks and buses use about **90 %** of road hydrogen; stock growth comes
from Chinese trucks.

**Even there:** Daimler's series truck slipped to the early 2030s; Ostrava's recent bus orders are
battery-electric (reported). **AFIR's stations** must serve heavy-duty vehicles too.

<div class="caption text-left">[IEA-GHR-2026], [AFIR-2023-1804] verified · Daimler, Ostrava:
<code>hydrogen.md</code> §4, §7, secondary / search summary</div>

</div>
<div>

<img class="photo" src="/photos/07-xcient-truck.jpg" style="height: 12rem" alt="A white Hyundai XCIENT Fuel Cell truck in Coop livery, green hydrogen on its box body, on a wet city street in Switzerland."/>

<div class="caption">Hyundai XCIENT Fuel Cell · JoachimKohler-HB, CC BY-SA 4.0</div>

<img class="photo mt-2" src="/photos/07-h2-bus.jpg" style="height: 10rem" alt="A fuel-cell city bus refueling under the canopy of a hydrogen station at dusk, storage tanks behind it."/>

<div class="caption">Fuel-cell bus refueling, Herten, 2026 · Icke68746, CC0</div>

</div>
</div>

<!--
So where does hydrogen fit? The case on both sides, from the numbers of the last hour.

For hydrogen in cars: a fill of about three minutes, a range of up to 400 miles by Toyota's figure,
about 640 kilometers, and no grid connection where the car parks. Against: 2.7 times the electricity
of a battery car per kilometer; a thin and shrinking network, 50 public stations in Germany and two
in Czechia; and an energy cost above petrol at the last reported Prague price.

*[ask]* Where would the three-minute fill matter more than the electricity?
*[pause]* In heavy vehicles that run all day: *[show photos]* a Hyundai XCIENT fuel-cell truck on
Coop's deliveries in Switzerland, photographed by JoachimKohler-HB, and a fuel-cell bus refueling
in Herten, by Icke68746, both on Wikimedia Commons. And that is where hydrogen is growing: trucks and buses
use about 90 percent of the hydrogen on the road, and the growth comes from trucks in China. Even
there it is not settled. Daimler pushed series production of its hydrogen truck to the early 2030s,
and Ostrava's recent bus orders are battery-electric, as reported in the press. AFIR's stations, for
their part, must serve heavy vehicles too.

So we have every number we need to answer the question from the first slide. Next slide.
-->
