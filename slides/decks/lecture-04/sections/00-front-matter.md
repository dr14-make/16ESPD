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
Welcome to Lecture 4, the battery-electric car. The subtitle names what we build today: the machine,
the converter that feeds it, the battery behind them, and regenerative braking.

The sentence at the bottom of the slide is the whole lecture: an electric car is an energy chain you
can close in both directions. In Lecture 2 the energy went one way: fuel into heat and motion, and
every stop burned in the brakes. Today every link of the chain, the battery, the converter, the
motor, the gear and the wheel, is reversible, and each one costs a few percent each way.

We build the chain from the motor outwards, one link per step, put it into the planar car from
Lecture 3, and drive the WLTC. The result at the end is an energy bill: kilowatt-hours per 100
kilometers at the battery, how much of the braking energy came back, and the same cycle in
megajoules per 100 kilometers, so that we can set it beside Lecture 2's engine car.

The material follows the course's deck on electric vehicles and electric machines, and the battery
slides of the deck on batteries and fuel cells. Both follow Larminie and Lowry's textbook, Electric
Vehicle Technology Explained. The hybrids from that deck are next lecture; the tour of battery
chemistries and the fuel cells are in the extra pack.

The small line at the bottom is for when you browse the deck yourself: the arrow keys and the space
bar move between slides, O opens the overview, and G jumps to a slide.
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

<div class="handson">Today: the same body, road load and cycle, with Leaf ZE1 numbers for the motor,
the gear and the battery, at 1500 kg, 100 kg more than Lecture 2's car. So the bill compares fairly
with Lecture 2's engine.</div>

<!--
Let us recall the two cars we already have.

On the left, Lecture 2's car, the one with the mapped engine. On the WLTC its reference run burned
5.22 liters of petrol per 100 kilometers. Petrol has a density of 0.745 kilograms per liter and a
lower heating value of 43.4 megajoules per kilogram, so 5.22 liters is 5.22 times 0.745 times 43.4,
which is 168.8 megajoules per 100 kilometers. All of that chemical energy went one way, into heat
and motion, and every time the car stopped, its kinetic energy was burned in the brakes. Its road
load was the course car's: drag, rolling resistance, slope and acceleration. That is the deck's
energy model, and we meet it again in two slides.

On the right, Lecture 3's planar car: four wheels on a plane, four brakes, ABS and ESP. It is the
car you braked from 80 kilometers per hour and steered through the sine-with-dwell. It has four spin
flanges, one per wheel. Today a machine drives two of them, the front pair, through a differential,
and the same four brakes take whatever braking the machine cannot.

The green box says what stays the same and what changes. The body, the road load and the drive cycle
stay the course car's, so the comparison with Lecture 2's engine at the end of the day is fair. The
powertrain changes: the motor, the reduction gear and the battery take their numbers from the Nissan
Leaf ZE1, the 40 kilowatt-hour model from 2017. The mass is 1500 kilograms, the planar car's default
and the Leaf's curb mass, 100 kilograms more than Lecture 2's car.
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
Here is the plan for today: nine sections. The first column links to each section, the second names
it, the third says what it covers, and the last says what you build at the end of it.

Section 01 makes the case for the electric car, recalls the energy model, and draws the chain in
both directions, with the Leaf-class car we build. Section 02 is the DC machine: from the force on a
wire to T equals K Phi I and E equals K Phi omega, with its losses, its efficiency and its control.
You build the machine, build 01, and test it on a dyno. Section 03 looks at the machines in real
electric cars: brushless machines, the permanent-magnet synchronous machine under field-oriented
control, the induction machine and the switched-reluctance machine, and it explains why build 01's
machine stands in for them. Section 04 is the envelope: base speed, field weakening, the efficiency
map, and where the WLTC drives on it. You build the converter, build 02. Section 05 is power
electronics: choppers, the H-bridge, pulse-width modulation and its harmonics, the three-phase
bridge, the 12 volt DC-DC converter and the charger. There is no build there, only a demonstration
on switching models. Section 06 is the battery, kept simple: V equals E minus I R, ampere-hours and
watt-hours, specific energy and power. You build the battery, build 03. Section 07 puts everything
into the car and makes the motor brake: the drivetrain, the motor as a brake, three ceilings on
regeneration, and how it is blended with the friction brakes. You build the car, build 04, and
regen, build 05. Section 08 is the energy bill: the WLTC link by link, the braking energy recovered,
and megajoules against the engine. You build the bill, build 06. Section 09 wraps up.

So there are six build steps, each right after the theory section it puts into practice. Sections 03
and 05 are theory only.
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
This slide lists the models behind everything you will see today, in three columns.

The left column is the four Pluto notebooks in `notebooks/lecture04`. The first, the efficiency map,
sweeps the machine of builds 01 and 02 over torque and speed, draws its efficiency map, sets it next
to the map Oak Ridge National Laboratory measured on the Leaf, and puts the WLTC operating points on
top. The second, switching, runs a buck chopper and an H-bridge with pulse-width modulation, and
computes the spectrum of the output. The third, the energy bill, drives the WLTC with a meter on
every link. The fourth runs the machine, the battery and the hard stop on their benches. Every plot
in this deck comes out of one of these four notebooks; the circuit drawings and block diagrams are
drawn by hand.

The middle column is what the course library carries, in `VehicleSystemsComponents.Vehicle`. Under
`Electric`: the DC machine, the field EMF, the converter, the battery and the auxiliary load; the
torque split and the regen blend; and the buck chopper and the H-bridge, which are switching models
that run beside the car, never inside it. Under `Planar`: the road load for the planar car and three
benches, the WLTC bench, the hard stop, and the WLTC with regen.

The right column is what you build today in your own `MyCar`, on the branch `handson-04`, in this
order: the machine and its dyno; the field EMF, the converter and the converter's dyno; the battery
and its discharge bench; the electric drive and the WLTC bench; the regen blend, the hard stop and
the regen WLTC bench; and the energy bill. Your parts have twins in the course library under the
same names, and the reference answers are in `dyad/HandsOn04`.
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
Before the first build, here is how the build works today. It works as in Lecture 3.

You work in your `MyCar` on a new branch, `handson-04`. The build guide, linked on the right, has
one section per step. Each step lists the parts with their library path, their instance name and
their values, every wire and every line of code, and the numbers to check before you go on.

Use the names given. That matters more than usual today, because later steps read signal paths by
name. Step 04 reads `converter.field` and `machine.k`, and step 06 reads `battery.E`. If you keep
Studio's default names, the error shows up far away from its cause.

You plot in the Julia REPL. The snippets do not load `MyCar` themselves: the REPL reloads it when
you run an analysis from Studio. So each time you add a new analysis, click Run Analysis on it once
before you paste the snippet that calls it. If a snippet fails with an UndefVarError for an
analysis, that is almost always the reason.

If you fall behind, every step ends with the finished code of that step, ready to paste.

The quote box says where the checkpoint numbers come from. Every number in a green box is a test
expectation or a measured run of the reference model, as in Lecture 3. So if your number differs,
your model differs.

And commit after each step, with the messages Step 01: machine, Step 02: converter, and so on.
-->
