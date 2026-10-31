---
routeAlias: wrap-up
layout: section
---

###### Section 09

# Wrap-up

The chain link by link, what you measured, and what the model leaves out.

<!--
Budget: 4 minutes: the chain 1, the summary 1, what you measured 1, the limits 1. The sources
slide is for the handout; skip it in the room.
-->

---
routeAlias: chain-table
---

## The chain, link by link

<div class="tight">

| Link | Model | Key number | WLTC loss | Step |
|---|---|---|---:|---|
| battery | *v* = *E* − *R*₀ *i*, coulomb-counted SoC | 40 kWh, 350 V, 0.1 Ω | 3.1 Wh/km | 03 |
| 12 V network | constant power | 300 W | 6.4 Wh/km | given |
| converter | *v*<sub>out</sub> = *d* · *v*<sub>in</sub>, current and duty limits | 99.2 % at the corner | 2.1 Wh/km | 02 |
| machine | *T* = *K*Φ *i*, *E* = *K*Φ ω, losses as parts | 320 N·m, 110 kW, 3283 rpm | 17.6 Wh/km | 01 |
| reduction, differential | ideal gears | 8.193 | 0 | 04 |
| brakes | series blending onto Lecture 3's | 80.5 kW, 320 N·m, 10 km/h | 0.1 Wh/km | 05 |
| road | Lecture 2's road load | 1500 kg, 0.63 m², 0.012 | 105.0 Wh/km | given |

</div>

**Out of the cells: 134.3 Wh/km. At the terminals: 131.2. Braking back: 24 % of traction.**

<!--
The lecture on one table: each link of the chain, the model you built for it, its key number, what
it lost over the WLTC, and the step that built it. The road's 105.0 is drag and rolling, 103.2,
plus tire slip, 1.8.

Read the loss column: after the road, the machine is the only large one, and it is large because
the cycle drives at light load. Everything else is a few Wh per km. That is why the electric car
needs a bit over a quarter of the engine car's energy.
-->

---

## Summary of the lecture

- **01** an electric car is a chain of reversible links; braking energy is a quarter of the
  traction on WLTC.
- **02** a DC machine: *T* = *K*Φ*I*, *E* = *K*Φω; on a fixed supply a steep line, a generator
  past *V*/*K*Φ.
- **03** a PMSM under field-oriented control is that machine from the outside: *i*<sub>q</sub>
  for torque, *i*<sub>d</sub> for the field.
- **04** the converter's voltage runs out at base speed; above it, field weakening at constant
  power. Light-load efficiency decides the bill.
- **05** switches and PWM make the converter; averaged, *v* = *d* · *V*.
- **06** *v* = *E* − *R*₀*i*, SoC counted from the current.
- **07** regen is limited by torque, charge power and speed; series blending gives the rest to
  friction.
- **08** **131.2 Wh/km**, **47.2 MJ/100 km** against the engine car's 168.8.

### Next: what you measured on your own car. <Link to="what-you-measured">→</Link>

<!--
If you take one picture away, take the energy chain with the green arrows running back: every
link reversible, each costing a few percent each way, and the bill that adds them up.

The notebooks are in the repository, `notebooks/lecture04/`. Open them in Pluto and move the
controls: the auxiliary load and the fade speed in the energy bill, the duty and frequencies in
the switching notebook.
-->

---
routeAlias: what-you-measured
---

## What you measured

<div class="tight">

| Build | What | Number |
|---|---|---|
| 01 | the machine on a dyno | 320.0 N·m at 3283 rpm, 332.2 A · 94.6 % · −304 N·m at 3600 rpm, generating |
| 02 | the converter, the envelope | duty 1 at 3283 rpm · field 0.328 at 10 000 rpm · 110.75 kW · 99.2 % |
| 03 | the battery | 10 V sag at 100 A · SoC 0.9 → 0.4625 in 30 min · 17.0 of 17.5 kWh delivered |
| 04 | the car on WLTC | within 1.63 km/h · 23 267 m · SoC 0.9 → 0.822 |
| 05 | regen | hard stop 36.2 m, machine 49 % · WLTC 23.85 % back |
| 06 | the bill | 131.2 Wh/km · 47.2 MJ/100 km against 168.8 |

</div>

<div class="text-sm opacity-70 mt-4">

Commit each step on `handson-04`. Next lecture: the hybrid, built from your Lecture 2 engine,
this lecture's machine and battery, and a clutch. The extra pack: the Thevenin cell, the BMS, fuel
cells and a dq model of the PMSM.

</div>

<!--
One minute. Each row is a test expectation of the reference model, and each is a number your own
parts should have produced. If one differs, the guide's Fell behind block for that step has the
finished code.

Lecture 5 reuses everything here: this machine, converter and battery, with Lecture 2's engine and
a clutch on the CVT, a P2 hybrid with an energy manager, and the P0 to P4 positions compared on
the WLTC.
-->

---
routeAlias: known-limits
---

## What the model leaves out

<div class="grid grid-cols-2 gap-8 text-[0.95rem]">
<div>

- **The machine is DC-equivalent:** no saliency or reluctance torque, no d and q dynamics.
- **Field weakening is free:** a PMSM's *i*<sub>d</sub> copper loss is not modeled.
- **No heat:** motor, inverter and battery at warm operating temperature.
- **E is constant:** SoC does not move the open-circuit voltage.

</div>
<div>

- **Ideal gears:** a real reducer's 2–3 % each way would add **4–5 Wh/km**.
- **WLTC is gentle:** its blending result is mostly fade; the hard stop carries that lesson.
- **The machine is outside the ABS loop:** nothing withdraws regen when the ABS acts.
- **ORNL's map** belongs to the 80 kW first-generation motor: shape and level, not a fit.

</div>
</div>

<!--
The plan's known limits, one line each. Each is a choice, and each would change the bill by a
little.

The reducer: a real single-speed reducer loses 2 to 3 percent each way. On the 144 Wh per km of
traction and 39 Wh per km of braking at the shaft, that adds 4 to 5 Wh per km to the bill.

The constant E: a real pack's voltage falls with SoC, and collapses near empty, so the converter's
corner moves down as the pack empties, as the 300 volt run of step 02 showed. The extra pack's
Thevenin cell reads E from SoC.

The ABS: on the dry hard stop the machine's torque holds the front wheels past the ABS's reapply
threshold, so the front friction brakes stay off. On a low-µ road the machine alone would lock them.
-->

---
routeAlias: sources
---

## Sources

<div class="grid grid-cols-2 gap-8 text-sm">
<div>

**Course and repository**

- Source decks: *7. Electric vehicles and Electric Machines* and *8. Batteries and Fuel Cells*
  (course materials), after Larminie and Lowry
- `docs/lecture-04-plan.md`: the model ladder, settled decisions and reality anchors
- `docs/research_notes/Electric and hybrid vehicles/teaching_materials.md`: Leaf numbers, ORNL
  maps, cell data, regen studies, with verification status
- The build guide, `slides/site/lecture/lecture-04/`, and the checkpoint tests in `test/`

**Manufacturer and laboratories**

- Nissan Japan, Leaf ZE1 main specifications (2017); Nissan Global newsroom (2017)
- T. Burress (ORNL), *Benchmarking State-of-the-Art Technologies*, DOE VTO AMR APE006, 2013
- INL, *BEV Battery Testing Results, 2013 Nissan Leaf*, INL/MIS-14-31587 (2014)
- Argonne/INL, *2013 Nissan Leaf Baseline Testing Results*
- Bosch Mobility, ESP hev

</div>
<div>

**Papers and books**

- J. Larminie, J. Lowry, *Electric Vehicle Technology Explained*, Wiley
- A. Boretti, *Comparison of Regenerative Braking Efficiencies of MY2012 and MY2013 Nissan Leaf*,
  Int. J. Eng. Technol. Innov. 6(3), 2016; SAE 2013-01-2872
- Y. Gao, M. Ehsani, SAE 2001-01-2478; M. Ehsani, Y. Gao, A. Emadi, *Modern Electric, Hybrid
  Electric, and Fuel Cell Vehicles*, CRC
- W. Gao et al., *eTransportation* 20 (2024) 100313: Leaf cell resistance

**Secondary**

- ADAC Autokatalog and EV Database: Leaf WLTP consumption, cell chemistry

</div>
</div>

<!--
Where each number came from. The speaker notes on each slide name the source of the facts on it.

Not verified from a primary source: the Leaf ZE1's WLTP consumption, which comes from ADAC and EV
Database; the low-speed regen fade speed, assumed at 10 km/h; Boretti's efficiencies, read from
the abstracts. ORNL's map points were read by eye from contour labels, plus or minus a percentage
point. The pairing of a PMSM with an induction machine in dual-motor cars is from manufacturer
descriptions, not a primary source in the research note.
-->
