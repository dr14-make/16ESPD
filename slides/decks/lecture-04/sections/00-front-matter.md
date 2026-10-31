---
routeAlias: front-matter
layout: cover
---

# The Battery-Electric Car

<h1 class="!text-5xl !-mt-4 opacity-70">Machine, converter, battery, regen</h1>

Vehicle Systems &amp; Components — Lecture 4

An electric car is an energy chain you can close in both directions.

<div class="text-xs opacity-60 mt-12">

<kbd>→</kbd> <kbd>Space</kbd> next &nbsp;·&nbsp; <kbd>←</kbd> previous &nbsp;·&nbsp;
<kbd>O</kbd> overview &nbsp;·&nbsp; <kbd>G</kbd> go to slide &nbsp;·&nbsp;
presenter mode from the nav bar, bottom left

</div>

<!--
The lecture is one 3-hour block of theory and a live build on the students' own car, section by
section, as in Lectures 1 and 3. Six build steps, each right after the theory section it puts into
practice.

The sentence on the slide is the whole lecture. Lecture 2 ended with fuel going one way, into
heat and motion. Here every link, battery, converter, motor, gear, wheel, is reversible, and each
one costs a few percent each way. You build the chain from the motor outwards, put it into the
planar car from Lecture 3, and drive the WLTC. The headline is the energy bill: kilowatt-hours
per 100 km at the battery, how much braking energy came back, and the same cycle in megajoules
for Lecture 2's engine.

The source is the course's old deck 7, electric vehicles and electric machines, and the battery
slides of deck 8. Both follow Larminie and Lowry, Electric Vehicle Technology Explained. The
hybrids of deck 7 move to Lecture 5; the battery chemistry tour and the fuel cells to the extra
pack.

The handout, `handout.pdf`, is published next to the deck, one slide per page.
-->

---
routeAlias: from-lectures-2-and-3
---

## Where Lectures 2 and 3 left the car

<div class="grid grid-cols-2 gap-8">
<div>

### Lecture 2: fuel, one way

The mapped engine drove the WLTC on **5.22 L/100 km** of petrol. At 0.745 kg/L and 43.4 MJ/kg
that is **168.8 MJ/100 km**: chemical energy into heat and motion, and every stop burned in the
brakes.

The road load was the course car's: drag, rolling resistance, slope and acceleration, the deck's
energy model.

</div>
<div>

### Lecture 3: the planar car

Four wheels on a plane, four brakes, ABS and ESP: the car you braked from 80 km/h and steered
through the sine-with-dwell.

Four `spin_*` flanges, one per wheel. Today a machine drives two of them through a differential,
and the same brakes take what the machine cannot.

</div>
</div>

<div class="handson">Today: the same car, the same road load, the same cycle, with Leaf ZE1 numbers for
the motor, the gear and the battery. So the bill compares fairly with Lecture 2's engine.</div>

<!--
Recall the two cars. Lecture 2's engine car is the comparison at the end of today: its reference
run burns 5.22 liters per 100 km on the WLTC, which is 168.8 megajoules per 100 km. Lecture 3's
planar car is today's platform: it has four wheel flanges, so every architecture in this lecture
and the next one is a choice of which flanges a machine drives.

The body, the road load and the cycle stay the course car's. The motor, the reduction ratio and
the pack come from the Nissan Leaf ZE1, the 40 kWh model from 2017. The mass is 1500 kg, the
planar car's default and the Leaf's curb mass, 100 kg more than Lecture 2's car.

Source of the engine number: notebook 03 of this lecture quotes Lecture 2's hands-on reference
run, petrol at 0.745 kg per liter and a lower heating value of 43.4 MJ per kg.
-->

---

## The sections

| # | Section | What it covers | You build |
|---|---|---|---|
| <Link to="why-electric">01</Link> | Why electric | the case, the energy model, the chain both ways, the Leaf-class car | |
| <Link to="dc-machine">02</Link> | The DC machine | F = BIL to T = KΦI and E = KΦω, losses, efficiency, control | 01 the machine, on a dyno |
| <Link to="machines">03</Link> | Machines in real EVs | brushless, PMSM under field-oriented control, induction, SRM | |
| <Link to="envelope">04</Link> | The envelope | base speed, field weakening, the efficiency map, WLTC on it | 02 the converter |
| <Link to="power-electronics">05</Link> | Power electronics | choppers, H-bridge, PWM and harmonics, three-phase bridge, DC-DC, charger | demo only |
| <Link to="batteries">06</Link> | Batteries, simply | V = E − IR, A·h and W·h, specific energy and power | 03 the battery |
| <Link to="car-and-regen">07</Link> | The car and regen | the drivetrain, the motor as a brake, three ceilings, blending | 04 the car · 05 regen |
| <Link to="energy-bill">08</Link> | The energy bill | WLTC link by link, braking recovered, MJ against the engine | 06 the bill |
| <Link to="wrap-up">09</Link> | Wrap-up | the chain, what you measured, what the model leaves out | |

<!--
Nine sections in three hours. Six of them end in a build step: the machine, the converter, the
battery, the car, regen and the bill. Sections 03 and 05 are theory and a demo: the machines in
real cars, and the switching power electronics, which run on a microsecond time scale and stay
out of the car.

Suggested split: about 100 minutes of theory and demo, 80 of building, with a break after section
04 and a short one after section 06. Builds 01 and 02 are the longest because they paste whole
components; 03 and 06 are short; 04 and 05 are mostly runs on prepared benches.
-->

---
layout: center
---

## The models behind this lecture

<div class="grid grid-cols-3 gap-8 text-left text-[0.85rem]">
<div>

### Notebooks

`notebooks/lecture04/`

- `01-efficiency-map`: the step 1–2 machine swept over torque and speed, next to ORNL's Leaf map,
  WLTC on top
- `02-switching`: buck chopper, H-bridge, PWM and its spectrum
- `03-energy-bill`: WLTC, a meter on every link
- `04-machine-battery-regen`: the machine, the pack and the hard stop on their benches

</div>
<div>

### Library parts

`VehicleSystemsComponents.Vehicle`

- `Electric.DCMachine`, `FieldEMF`, `Converter`, `Battery`, `AuxLoad`
- `Electric.TorqueSplit`, `RegenBlend`
- `Electric.BuckChopper`, `HBridge`: switching, beside the car
- `Planar.PlanarRoadLoad`, `PlanarBEVWLTC`, `PlanarBEVHardStop`, `PlanarBEVRegenWLTC`

</div>
<div>

### Yours, built along

Your `MyCar`, branch `handson-04`:

- `DCMachine`, `DCMachineDyno`
- `FieldEMF`, `Converter`, `ConverterDyno`
- `Battery`, `BatteryDischarge`
- `ElectricDrive`, `BEVWLTC`
- `RegenBlend`, `BEVHardStop`, `BEVRegenWLTC`
- `BEVEnergyBill`

Reference answers: `dyad/HandsOn04/`.

</div>
</div>

<!--
Every plot in this deck marked as a figure is an output of one of the four notebooks; the
speaker notes say which. The diagrams are drawn by hand.

The second column is what the course library carries. The students' parts have library twins
under the same names in `Vehicle.Electric`, and the tests check that each hands-on reference
matches its twin. The switching models are separate: they run for a few milliseconds and never go
into the car.

The third column is what you build today, in this order. The names matter: later steps read
signal paths such as `battery.SoC` and `converter.field`. The reference answers are in
`dyad/HandsOn04/`, under the same names; under plus they show as VehicleSystemsComponents,
HandsOn04.
-->

---
routeAlias: how-the-build-works
---

## How the build works today

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-start">
<div>

- Work in your `MyCar`, on a new branch **`handson-04`**.
- Each step lists the parts with their library path, instance name and values, every wire and
  line of code, and the numbers to check before you go on.
- **Use the names given.** Later steps read signal paths such as `battery.SoC`.
- **Plot in the Julia REPL.** Click ▷ **Run Analysis** once for each new analysis before you paste
  the snippet that calls it: that loads `MyCar` into the REPL.
- **Fell behind?** Every step ends with the finished code of that step, to paste.

</div>
<div>

> **Every number** on a checkpoint is a test expectation or a measured run of the reference model,
> as in Lecture 3.

The build guide holds every block, line and number:

[page: Lecture 4 build guide](../lecture/lecture-04/)

Commit after each step: `Step 01: machine`, `Step 02: converter`, …

</div>
</div>

<!--
Two minutes. The build works as in Lecture 3: one slide per step, with the recipe, the code
snippet that plots the result, and the checkpoint numbers in a green box. The guide page has the
full steps, with the Dyad code to paste.

Two things go wrong most often. First, a snippet that fails with an UndefVarError for an analysis:
the student has not clicked Run Analysis once since adding it, so `MyCar` in the REPL is stale.
Second, renamed parts: step 04 reads `converter.field` and `machine.k`, step 06 reads
`battery.E`, and a student who kept Studio's default names gets errors far from the cause.

The checkpoint tests are `test/machine_plausibility.jl`, `test/converter_plausibility.jl`,
`test/battery_plausibility.jl`, `test/bev_plausibility.jl` and `test/regen_plausibility.jl`.
-->
