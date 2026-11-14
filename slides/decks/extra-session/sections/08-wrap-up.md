---
routeAlias: wrap-up
layout: section
---

###### Section 08

# Wrap-up

Plug or nozzle, the session in seven lines, the take-home exercises, and the sources.

<!--
The wrap-up: the plug and the nozzle side by side, the session in seven lines, and the exercises to
take home.
-->

---
routeAlias: plug-or-nozzle
---

## Plug or nozzle: the answer

<div class="tight">

| | Plug: Leaf 40 kWh / IONIQ 5 | Nozzle: Mirai |
|---|---|---|
| Refill | 10–80 % in **43 min** / **18 min** | full in **≈ 3.2 min** (US average) |
| Energy cost, Czechia, per 100 km | **60–120 CZK** at home, 222–289 on DC | **394 CZK** (H₂ price Jan 2024) |
| Electricity per 100 km | **17.1 kWh** at the wall | **≈ 46 kWh** |
| Power plant to wheel | **69 %** | **26 %** |
| Where to refill in Czechia | **7,669** public charging points | **2** ORLEN public stations |

</div>

<div class="caption text-left">All from this session's slides: sections 04, 06 and 07.</div>

<div class="handson">Energy on board decides what the car is.</div>

<!--
Back to the sentence on the first slide, and to your guesses. How fast does the energy go back in,
and what does it cost to get it there? Here they are side by side.

The nozzle wins on time: about three minutes against 18 to 43. A tank has no CV phase, and no
rapidgate, the Leaf's heat slowdown. The plug wins everything else. At home it costs a third as much
per 100 kilometers, or less. It uses a third of the electricity. There are seven and a half thousand
places to plug in, against two nozzles. A Mirai is a larger car, but no row is close.

So for a car the battery has won. The fuel-cell car's one advantage, the three-minute fill, is the
gap that 800 volt charging keeps closing. Where fill time matters more than electricity, in trucks
and buses that run all day, the question is still open.

*[ask]* Which column would you buy? *[pause]*
-->

---
routeAlias: session-summary
---

## Summary of the session

- **01** the terms: C-rate, series and parallel, gross vs usable, SoH; LFP is over half of EV
  batteries: cheaper ($81 vs $128/kWh), stores less (205 vs 265 Wh/kg best cell).
- **02** the Thevenin cell: OCV(SoC), *R*₀ at once, *R*₁*C*₁ slowly — and SoC can no longer pass
  zero unnoticed.
- **03** the BMS counts charge, resets the count from the OCV after a rest, and bleeds the
  fullest cells so the string fills together.
- **04** CC-CV because the limit is on the terminal voltage; heat and the curve's shape, not the
  peak, set the charge time; 800 V halves the current.
- **05** a fuel cell's efficiency is its voltage: best at light load.
- **06** 700 bar in 3 minutes needs −40 °C gas and ~3 kWh/kg of compression; stations are closing.
- **07** the fuel-cell car is Lecture 5's series hybrid; **69 % vs 26 %** from power plant to wheel.

<div class="grid grid-cols-4 gap-x-6 gap-y-1 mt-3 items-end">
<div>
<img src="/figures/01-chemistry.svg" style="height: 7.5rem" alt="Bars of best cell specific energy and 2025 pack price for NMC, LFP and sodium-ion."/>
<div class="caption">01</div>
</div>
<div>
<img src="/diagrams/02-thevenin.svg" style="height: 7.5rem" alt="The Thevenin cell: OCV(SoC), R0 and one RC pair."/>
<div class="caption">02</div>
</div>
<div>
<img src="/figures/03-soc-drift.svg" style="height: 7.5rem" alt="SoC error from a current-sensor offset: a taxi that never rests crosses 5 %, a parked car is reset from the OCV."/>
<div class="caption">03</div>
</div>
<div>
<img src="/figures/04-dc-curves.svg" style="height: 7.5rem" alt="Charging power against state of charge for three modern cars and the Leaf."/>
<div class="caption">04</div>
</div>
<div>
<img src="/figures/05-polarization.svg" style="height: 7.5rem" alt="The fuel cell polarization curve with the Mirai stack points."/>
<div class="caption">05</div>
</div>
<div>
<img src="/diagrams/06-fill-700bar.svg" style="height: 7.5rem" alt="Sketch of a 700 bar fill: pressure ramp and tank gas temperature under their limits."/>
<div class="caption">06</div>
</div>
<div>
<img src="/figures/07-efficiency-chain.svg" style="height: 7.5rem" alt="Power plant to wheel: 69 percent for the battery car, 26 for the fuel-cell car."/>
<div class="caption">07</div>
</div>
</div>

<!--
The session in seven lines. I will only pick out the thread.

The first four lines are the plug. The terms and the chemistry set the price and the voltage limit.
The Thevenin cell gives the voltage its meaning. The BMS reads it, resets its count, and bleeds
charge from the fullest cells. The charger obeys the BMS, so the last fifth is slow and heat sets
the time. The last three lines are the nozzle: efficient at light load, filled in three minutes with
gas chilled to minus 40, and 26 percent from power plant to wheel, against the battery car's 69.

Energy on board decides what the car is: how fast it goes back in, and what it costs to get it
there. That is the sentence we started with.
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
   current and hydrogen flow at 30 kW; read the current density at 0.7 V off the curve and work
   out the cell area it implies.
4. **Your own bill, and when it pays back.** Cost per 100 km of the Leaf, the Mirai and your family's car at today's
   prices — home tariff, public DC, ORLEN's hydrogen, petrol — with each price's source and date.
   Then the break-even: an electric car in place of your family's next one, with its price gap,
   your yearly kilometers, your share of home vs DC charging, and servicing. After how many years
   does it pay back, if ever? Which input moves the answer most?

<div class="handson">Every number you need is on tonight's slides; for exercise 4 you find your
own.</div>

**Check your answer** in the course library: 1 with <code>CCCV800V</code>, 2 with
<code>SoCDriftDays</code>, 4 with <code>notebooks/extra-session/01-ev-payback.pluto.jl</code>.

<!--
Four exercises to take home, each built on a slide from tonight. One, the CV slide again for an 800
volt pack at 200 kilowatts. Two, the coulomb-counting drift on your Lecture 4 pack. Three, the
Mirai's hydrogen flow at 30 kilowatts, and how big its cells must be. Four, your own bill: today's
prices, with their sources and dates, for the Leaf, the Mirai and your family's car. Then the real
question at home: would an electric car pay for itself, and after how many years? Try it with your
own kilometers. Someone who drives little and charges on DC may never break even. Someone who drives
a lot and charges at home may break even in a few years. While you are at it, check whether ORLEN
has published a newer hydrogen price than ours.
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

<div class="text-xs mt-3 opacity-80">

**Photos, all from Wikimedia Commons:** Nissan Leaf cutaway · Norsk Elbilforening, CC BY 2.0 ·
BMW i3 cells · RudolfSimon, CC BY-SA 3.0 · Leaf pack · Gereon Meyer, CC BY-SA 4.0 · BMS board ·
Drazny, CC BY-SA 4.0 · Type 2, CCS2, CHAdeMO · D-Kuru/Wikimedia Commons, CC BY-SA 4.0 · NACS ·
RickyCourtney, CC BY-SA 4.0 · MCS · SRago91, CC BY-SA 4.0 · IONITY · Андрей Романенко, CC BY-SA 4.0
· ČEZ charger · Yopic, CC0 · Mirai cutaway, stack, tank · Mariordo, CC BY-SA 4.0 · Magdeburg ·
Michał Beim, CC BY-SA 4.0 · Offenbach nozzles · L. Willms, CC BY-SA 3.0 · Frankfurt · Zgonnik,
public domain · Mirai gen 2, Herten bus · Icke68746, CC0 · XCIENT · JoachimKohler-HB, CC BY-SA 4.0

</div>

<!--
The sources behind tonight's numbers, for reference. Every number on a slide has a source tag. The
research notes give the full citation and how firm it is. All photographs are from Wikimedia
Commons, credited at the bottom.
-->
