---
routeAlias: wrap-up
layout: section
---

###### Section 08

# Wrap-up

The session in seven lines, the take-home exercises, and the sources.

<!--
Section 08, the wrap-up: the session in seven lines, the exercises to take home, and the sources.
-->

---
routeAlias: session-summary
---

## Summary of the session

- **01** LFP is over half of EV batteries: cheaper ($81 vs $128/kWh), lighter on energy (205 vs
  265 Wh/kg cell).
- **02** the Thevenin cell: OCV(SoC), *R*₀ at once, *R*₁*C*₁ slowly — and SoC can no longer pass
  zero unnoticed.
- **03** the BMS counts charge, resets the count from the OCV after a rest, and balances the
  string to its weakest cells.
- **04** CC-CV because the limit is on the terminal voltage; heat and the curve's shape, not the
  peak, set the charge time; 800 V halves the current.
- **05** a fuel cell's efficiency is its voltage: best at light load.
- **06** 700 bar in 3 minutes needs −40 °C gas and ~3 kWh/kg of compression; stations are closing.
- **07** the fuel-cell car is Lecture 5's series hybrid; **69 % vs 26 %** from power plant to wheel.

<!--
The session in seven lines, one per section.

01: LFP is now over half of the EV batteries deployed; it is cheaper, 81 against 128 dollars per
kilowatt-hour for NMC, and stores less, 205 against 265 watt-hours per kilogram at best cell level.
02: the Thevenin cell, with an open-circuit voltage that follows the charge, R0 acting at once and
an RC pair acting slowly; its voltage collapses near empty, so the state of charge can no longer run
through zero unnoticed. 03: the battery management system counts the charge, resets the count from
the open-circuit voltage after a rest, and balances the cells, because the string is only as good as
its extreme cells.

04: charging switches from constant current to constant voltage because the limit is on the
terminal voltage; heat and the shape of the curve, not the peak power, set the charging time; and
800 volts halves the current. 05: a fuel cell's efficiency is its voltage, so it is best at light
load. 06: filling 700 bar in three minutes needs gas precooled to minus 40 and about 3
kilowatt-hours per kilogram of compression, and in Germany the public stations fell from over 80 to
50 in two years. 07: the fuel-cell car is Lecture 5's series hybrid with a stack for a
source, and from the power plant to the wheel it delivers 26 percent against the battery car's 69.
-->

---
routeAlias: take-home
---

## Take-home exercises

1. **The end of CC.** Redo the "why CV" slide for an 800 V pack (192s2p of ZE1-class cells: twice the Leaf pack's *R* ≈ 0.1 Ω, so **0.2 Ω**) at 200 kW:
   the current, the *I R* drop per cell, and the OCV where CC must end.
2. **The drift.** For Lecture 4's 114.3 Ah pack, how many hours of driving until a current-sensor
   offset of **50 mA** gives 5 % SoC error? How often must the BMS reset?
3. **The Mirai's hydrogen.** From 12.41 g/h per A and the polarization curve at 0.7 V: the stack
   current and hydrogen flow at 30 kW, and the cell area that makes 0.7 V sit at 1 A/cm².
4. **Your own bill.** Cost per 100 km of the Leaf, the Mirai and your family's car at today's
   prices — home tariff, public DC, ORLEN's hydrogen, petrol — with each price's source and date.

<div class="handson">TODO(lecturer): confirm the extra-pack exercises and their answers; none are in
the plan or the research notes yet.</div>

<!--
Four exercises to take home, each built on a slide from today.

One: redo the CV slide for an 800 volt pack at 200 kilowatts. Find the current, the voltage drop per
cell across the resistance, and the open-circuit voltage at which constant current must end. Take
the pack as two Leaf packs in series: the course's 96s2p pack of ZE1-class cells is about 0.1 ohm,
from the teaching-materials note, so 0.2 ohm.

Two: the coulomb-counting drift. With Lecture 4's 114.3 ampere-hour pack and a 50 milliampere sensor offset, the one
the BMS slide used on a single cell,
how long until the counted state of charge is 5 percent off, and so how often the BMS must reset it
from the open-circuit voltage.

Three: the Mirai's hydrogen. From Faraday's 12.41 grams per hour per ampere and a cell voltage of 0.7
volts, find the stack current and the hydrogen flow at 30 kilowatts, and
the cell area that would put 0.7 volts at 1 ampere per square centimeter.

Four: your own bill. Look up today's prices and their dates, and compute the cost per 100 kilometers
of the Leaf at home and on public DC, the Mirai at ORLEN's current hydrogen price, and your family's
car.

The green box is for the lecturer: these drafts need confirming, with worked answers.
-->

---
routeAlias: sources
---

## Sources

<div class="grid grid-cols-2 gap-8 text-sm">
<div>

**Course and repository**

- Source deck *8. Batteries and Fuel Cells* (course materials), after Larminie and Lowry
- `docs/extra-session-plan.md`; research notes in `docs/research_notes/Electric and hybrid
  vehicles/`: `teaching_materials.md`, `charging.md`, `hydrogen.md`, `pem-polarization.md`,
  `energy-prices-cz.md`, `bms.md`

**Laboratories and agencies**

- INL: 2013 Leaf battery tests (2014); DC fast-charging study (2015); USABC/INL EV test manual
  Rev. 4 (2025); ORNL Leaf cell HPPC data (equiv-circ-model)
- ANL: 2017 Mirai assessment (2018); J2601 fill time; NLR (ex-NREL) station data (2023)
- US DOE: compression record 9013 (2009), station cost 21002 (2020), PEM electrolysis targets
- CARB AB 126 report (2025); IEA GEVO 2025, 2026; GHR 2026; hydrogen definitions (2023)
- ADAC charging losses (2026); EAFO Czechia and EU27 (Sep 2026)

</div>
<div>

**Papers, standards, regulation, makers**

- Plett, *Battery Management Systems* Vol. I (2015); Nejad et al., *J. Power Sources* (2016);
  Movassagh et al. (2021); Rumpf et al. (2017); Ohneseit et al., *Batteries* (2023)
- TI, NXP, Infineon BMS notes and product pages; GB/T 38661-2020 (translator's excerpt)
- Pukrushpan thesis (2003) and JDSMC (2004); Gao et al., *eTransportation* (2024); Das and
  Shrotriya, *Energies* (2024); Chen et al., *JES* (2020)
- IEC 61851, 62752, 62196-2; ISO 15118-20; SAE J2601, J3400, J3271
- EU 2023/1804 (AFIR), Delegated Regulation 2025/656
- Toyota, Hyundai, Porsche, Nissan, Renault, Panasonic, LG, A123 datasheets and releases
- BloombergNEF battery price survey (Dec 2025); Agora (2018); Geotab (2026); Fastned curves

**Secondary (labeled on the slides)**

- EV Database; CleanTechnica; LBST via Motor1; H2 MOBILITY via ecomento; Argus/SNE; Czech trade
  press (fDrive, Systemy logistiky, Aktuálně.cz, ČT24)

</div>
</div>

<!--
The sources behind today's numbers, for reference. Every number on a slide carries its source tag
from the research notes, and the notes give the full citation, the date and whether it was verified
from the primary, read off a figure, or only reported by a secondary source. Secondary numbers are
labeled where they appear.
-->
