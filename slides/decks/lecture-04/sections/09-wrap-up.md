---
routeAlias: wrap-up
layout: section
---

###### Section 09

# Wrap-up

The chain link by link, what you measured, and what the model leaves out.

<!--
Section 09, the wrap-up: the chain link by link, what you measured on your own car, and what the
model leaves out.
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
| road | Lecture 2's road load | 1500 kg, 0.63 m², 0.012 | 104.9 Wh/km | given |

</div>

**Out of the cells: 134.3 Wh/km. At the terminals: 131.2. Braking back: 24 % of traction.**

<!--
The whole lecture on one table, one row per link of the chain. The columns: the model you built for
it, its key number, what it lost over the WLTC per kilometer, and the step that built it.

The battery: v equals E minus R0 i, with a coulomb-counted state of charge; 40 kilowatt-hours, 350
volts, 0.1 ohm; it lost 3.1 watt-hours per kilometer; step 03. The 12 volt network: a constant
power, 300 watts; 6.4; given in the library. The converter: v out equals d times v in, with current
and duty limits; 99.2 percent at the corner; 2.1; step 02. The machine: T equals K Phi i and E
equals K Phi omega, with its losses as parts; 320 newton meters, 110 kilowatts, 3283 rpm; 17.6; step
01. The reduction and the differential: ideal gears, ratio 8.193; no loss; step 04. The brakes:
series blending onto Lecture 3's, with the ceilings 80.5 kilowatts, 320 newton meters and a fade at
10 kilometers per hour; 0.1; step 05. And the road: Lecture 2's road load, 1500 kilograms, 0.63
square meters, 0.012; 104.9, which is 103.1 of drag and rolling resistance plus 1.8 of tire slip;
given.

The line under the table: out of the cells, 134.3 watt-hours per kilometer; at the terminals, 131.2;
and braking gave back 24 percent of the traction.

Read the loss column. After the road, the machine is the only large loss, and it is large because
the cycle drives at light load. Everything else costs a few watt-hours per kilometer.
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
The lecture in eight lines, one per section. 01: an electric car is a chain of reversible links, and
on the WLTC the braking energy is a quarter of the traction. 02: a DC machine, T equals K Phi I and
E equals K Phi omega; on a fixed supply a steep straight line, and a generator past V over K Phi.
03: a PMSM under field-oriented control is that machine from the outside, with i q for torque and i
d for the field. 04: the converter's voltage runs out at base speed, and above it field weakening
holds the power constant; light-load efficiency decides the bill. 05: switches and pulse-width
modulation make the converter, and averaged, v equals d times V. 06: v equals E minus R0 i, and the
state of charge counted from the current. 07: regen is limited by torque, charge power and speed,
and series blending gives the rest to friction. 08: 131.2 watt-hours per kilometer, 47.2 megajoules
per 100 kilometers, against the engine car's 168.8.

If you take one picture away, take the energy chain with the green arrows running back: every link
reversible, each costing a few percent each way, and a bill that adds them up.

The notebooks are in the repository, in `notebooks/lecture04`. Open them in Pluto and move the
controls: the auxiliary load and the fade speed in the energy bill, the pack voltage in the
efficiency map, the duty, the modulation index and the frequencies in the switching notebook.
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
| 05 | regen | hard stop 27.10 m (within 1 % of friction); gross machine 0.839 %, meaningful-share goal NOT met · WLTC 23.85 % back |
| 06 | the bill | 131.2 Wh/km · 47.2 MJ/100 km against 168.8 |

</div>

<div class="text-sm opacity-70 mt-4">

Commit each step on `handson-04`. Next lecture: the hybrid, built from your Lecture 2 engine,
this lecture's machine and battery, and a clutch. The extra pack: battery chemistry, the Thevenin
cell, charging, SoC estimation and the BMS, fuel cells and hydrogen, a dq model of the PMSM and a
stepped gearbox.

</div>

<!--
What you measured, build by build. Each number is a test expectation of the reference model, and
each is a number your own parts should have produced.

Build 01, the machine on a dyno: 320.0 newton meters at 3283 rpm for 332.2 amperes, 94.6 percent
efficient, and minus 304 newton meters at 3600 rpm, generating. Build 02, the converter and the
envelope: the duty reaches 1 at 3283 rpm, the field is down to 0.328 at 10 000 rpm, the air-gap
power holds at 110.75 kilowatts, and the converter is 99.2 percent efficient. Build 03, the battery:
a 10 volt sag at 100 amperes, the state of charge from 0.9 to 0.4625 in 30 minutes, and 17.0 of the
17.5 kilowatt-hours delivered. Build 04, the car on the WLTC: within 1.63 kilometers per hour of the
trace, 23 267 meters, the state of charge from 0.9 to 0.822. Build 05, regen: after the ABS
memory fix, 27.102036224 meters in 2.340 seconds after pedal, against 26.937898732 meters
friction-only: 0.61 percent longer, within the 1 percent regression tolerance. Keep withdrawal
ON: OFF is longer and reverses wheels, not a physical regen benchmark. Gross machine share
is only 0.839 percent: blanket front-active withdrawal suppresses regen almost throughout,
so the meaningful-share goal is NOT met. Low-grip ON is 87.594615426 meters in 7.665 seconds;
use stop 12 for both benches (HandsOn 87.604052512 m, Success).
WLTC remains 23.85 percent of traction back on the
WLTC. Build 06, the bill: 131.2 watt-hours per kilometer, and 47.2 megajoules per 100 kilometers
against 168.8.

If one of yours differs, the guide's Fell behind block for that step has the finished code to
compare with.

The small print: commit each step on `handson-04`. The next lecture is the hybrid, built from your
Lecture 2 engine, this lecture's machine and battery, and a clutch. And the extra pack holds what we
left out today: battery chemistry; the more detailed cell, charging, state-of-charge estimation and
the battery management system; fuel cells and hydrogen; a d-q model of the PMSM; and a stepped
gearbox.
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
- **ABS coordination is blanket withdrawal:** front-active reporting suppresses regen almost throughout the stop; it is not traction control for machine-only braking.
- **ORNL's map** belongs to the 80 kW first-generation motor: shape and level, not a fit.

</div>
</div>

<!--
What the model leaves out, from the plan's list of known limits. Each is a choice, and each changes
the bill by a little.

Left column. The machine is DC-equivalent: it has no saliency or reluctance torque, and no d and q
dynamics. Field weakening is free: a real PMSM pays copper loss for its i d current, and the model
does not. There is no heat: the motor, the inverter and the battery are all at a warm operating
temperature. And E is constant: the state of charge does not move the open-circuit voltage. A real
pack's voltage falls as it empties, and then the converter's corner moves down, as the 300 volt run
of build 02 showed.

Right column. Ideal gears: a real single-speed reducer loses 2 to 3 percent each way. On the 144
watt-hours per kilometer of traction and the 39 of braking at the shaft, that would add 4 to 5
watt-hours per kilometer to the bill. The WLTC is gentle: its blending result is mostly the fade,
which is why the hard stop carries the blending lesson. ABS coordination now withdraws regen
while either front command is below demand, including initial build, hold and reapply. This blanket
rule suppresses regen almost throughout the dry stop; the memory fix repairs hydraulic recovery,
not the motor-share shortfall. It is not traction control: machine-only light braking may lock a
wheel with no friction demand for the ABS to modulate. And Oak Ridge's map belongs to the
80 kilowatt first-generation motor, so the comparison with it is of shape and level, not a fit.
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

**Market and regulation**

- IEA, *Global EV Outlook 2026*; BloombergNEF, battery price survey, Dec 2025; EEA, new-car CO₂
  and electricity indicators, 2026; ACEA, Jan 2026; Toyota, TNGA engine, 2018
- EU Regulations 2019/631, 2023/851, 2025/1214 (car CO₂), 2024/1257 (Euro 7), 2023/1542
  (batteries), 2023/1804 (AFIR); proposal COM(2025) 995
- US: 89 FR 27842 (EPA 2024), 91 FR 7686 (EPA 2026), 91 FR 61988 (NHTSA 2026); Public Law 119-21

**Secondary**

- ADAC Autokatalog and EV Database: Leaf WLTP consumption, cell chemistry
- Our World in Data: the IEA's EV-share series

</div>
</div>

<!--
The sources behind the numbers in this lecture, for reference.

On the left, the course and the repository: the two source decks, on electric vehicles and electric
machines and on batteries and fuel cells, after Larminie and Lowry; the lecture plan, with the model
ladder, the settled decisions and the reality anchors; the research note with the Leaf numbers, the
Oak Ridge maps, the cell data and the regen studies, each with its verification status; and the
build guide with its checkpoint tests. Then the manufacturer and the laboratories: Nissan's ZE1
specifications and its 2017 press release; Burress at Oak Ridge National Laboratory, the 2013
benchmarking presentation with the Leaf's efficiency maps; Idaho National Laboratory's 2014 battery
tests of a 2013 Leaf pack; the baseline testing of the 2013 Leaf by Argonne and Idaho; and Bosch's
ESP hev.

On the right, papers and books: Larminie and Lowry's textbook; Boretti's analyses of the Leaf's
regenerative braking efficiency; Gao and Ehsani's paper, and Ehsani, Gao and Emadi's textbook, on
blending; and the 2024 paper by Gao and colleagues on Leaf cell resistance. Below them, the market and
regulation sources behind section 01 and the battery prices of section 06: the IEA's Global EV
Outlook 2026, BloombergNEF's 2025 battery price survey, the European Environment Agency's
indicators, ACEA, Toyota's engine page; the EU regulations on car CO2, Euro 7, batteries and charging
infrastructure, and the Commission's 2035 proposal; and the US Federal Register notices and the 2025
law behind the American rules. Last, the secondary sources: ADAC's car catalog and the EV Database,
for the Leaf's WLTP consumption and its cell chemistry, and Our World in Data's copy of the IEA's
yearly EV shares.

Some numbers are not verified from a primary source, and it is fair to say which. The yearly EV
shares in the market figure are Our World in Data's copy of the IEA's data. The Leaf ZE1's
WLTP consumption comes from ADAC and the EV Database. The low-speed regen fade speed is assumed at
10 kilometers per hour. Boretti's efficiencies were read from the abstracts. And Oak Ridge's map
points were read by eye from contour labels, to within about a percentage point.
-->
