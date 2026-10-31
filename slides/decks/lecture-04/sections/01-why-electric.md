---
routeAlias: why-electric
layout: section
---

###### Section 01

# Why electric

The case for the electric car, the energy it needs, and the chain that delivers it both ways.

<!--
Section 01, why electric. Before we build anything, three things: the case for the electric car, the
energy the car needs to drive a cycle, and the chain of links that delivers that energy to the
wheels and, when the car brakes, takes it back.
-->

---
routeAlias: why-evs
---

## Why electric vehicles

<div class="grid grid-cols-2 gap-8">
<div>

**The problem** (EEA, EU)

- Transport causes nearly a quarter of Europe's greenhouse-gas emissions, and has cut them less
  since 1990 than other sectors.
- EU fleet CO₂ limits for new cars: 130 g/km under Regulation 443/2009, 95 g/km from 2020.

**What the electric drive changes**

- The chain from battery to wheel loses a few percent per link; an engine turns about 30 % of
  its fuel into work at its best.
- Nothing burns on board: no local exhaust.
- **Braking energy comes back.** The motor turns generator and charges the battery.
- Few moving parts, no gearbox, no oil change.

</div>
<div>

**What it costs**

- The battery: mass, cost, and energy per kilogram far below a fuel tank's.
- Charging time, and range in the cold.
- The CO₂ moves to the power station: it is only as clean as the grid.

> **Today's question**
>
> Where does an electric car's energy go on the WLTC, and how much of it comes back?
> Section 08 answers it in kWh/100 km, link by link.

</div>
</div>

<!--
On the left, the problem, and what the electric drive changes. Transport causes nearly a quarter
of Europe's greenhouse-gas emissions, and since 1990 it has cut them less than the other sectors
have: that is the European Environment Agency's transport indicator. And in the European Union,
Regulation 443 of 2009 set the average CO2 emissions of new cars at 130 grams per kilometer, with a
target of 95 grams per kilometer from 2020.

What does the electric drive change? First, efficiency. The chain from the battery to the wheel
loses a few percent per link, while an engine turns about 30 percent of its fuel into work at its
very best operating point. Second, nothing burns on board, so there is no local exhaust. Third,
braking energy comes back: when the car brakes, the motor turns generator and charges the battery.
And fourth, the mechanics are simple: few moving parts, no gearbox, no oil change.

On the right, what it costs. The battery: its mass, its cost, and an energy per kilogram far below
that of a fuel tank. Charging takes time, and the range drops in the cold. And the CO2 does not
disappear, it moves to the power station: an electric car is only as clean as the grid that charges
it.

The box at the bottom right is today's question: where does an electric car's energy go on the WLTC,
and how much of it comes back? Section 08 answers it in kilowatt-hours per 100 kilometers, link by
link. Instead of taking an efficiency from a brochure, we measure it on the model we build.
-->

---
routeAlias: energy-model
---

## The energy the car needs: Lecture 2's road load

<div class="grid grid-cols-[1.1fr_1fr] gap-8">
<div>

The deck's energy model, term by term, at the wheel:

$$
F = \underbrace{\tfrac12 \rho\, C_d A\, v^2}_{O_v,\ \text{drag}}
  + \underbrace{f_r\, m g}_{O_f,\ \text{rolling}}
  + \underbrace{m\, a}_{O_z,\ \text{acceleration}}
  + \underbrace{m g \sin\alpha}_{O_s,\ \text{slope}}
$$

plus $O_{aux}$, the auxiliaries, drawn from the battery.

It is Lecture 2's `RoadLoad`, now a part of its own: the same law drives the engine car and the
planar car.

</div>
<div class="tight">

| Course car | Value |
|---|---|
| mass *m* | 1500 kg |
| *C*<sub>d</sub>*A* | 0.63 m² |
| rolling *f*<sub>r</sub> | 0.012 |
| auxiliaries | 300 W |
| cycle | WLTC class 3b, 23.27 km |

<div class="handson">On WLTC at 1500 kg: <b>139 Wh/km</b> of traction at the wheel, and braking
energy worth <b>25–26 %</b> of it (derived, plan)</div>

</div>
</div>

<!--
How much energy does the car need? That is Lecture 2's road load, which the deck calls its energy
model. Let us read the formula term by term. F is the force the wheels must push with, in newtons,
and it has four parts. The first is aerodynamic drag, O v in the deck's notation: one half times the
air density rho, in kilograms per cubic meter, times the drag coefficient C d times the frontal area
A, in square meters, times the speed v squared, in meters per second. The second is rolling
resistance, O f: the rolling coefficient f r, which has no unit, times the mass m in kilograms,
times g, 9.81 meters per second squared. The third is the force that accelerates the car, O z: mass
times acceleration a. The fourth is the slope, O s: m g times the sine of the road's angle alpha.
These four are forces at the wheel. The deck adds a fifth term, O aux, the auxiliaries: everything
electrical that is not propulsion. That one is not a force at the wheel but a power drawn from the
battery.

This is exactly the road load of Lecture 2's notebook 01. What is new is that the course library has
taken it out into a part of its own, `RoadLoad`, with no mass in it, so that the planar car can use
the same law through an adapter. The engine car and the electric car meet the same road.

The table gives the course car's numbers: 1500 kilograms; a C d A of 0.63 square meters; a rolling
coefficient of 0.012; 300 watts for the auxiliaries, which is a car on a test cycle with the climate
control off; and the WLTC class 3b cycle, 23.27 kilometers long.

The green box is the size of the prize. Run this road load backwards over the WLTC with a 1500
kilogram car and add up the positive power at the wheel: 139 watt-hours per kilometer of traction.
Add up the negative power, the braking phases, and you get energy worth 25 to 26 percent of that.
That is the upper limit of what regenerative braking could recover on this cycle, if every bit of
the braking energy came back. Both numbers are derived in the course's research note, from the cycle
file and this road load. The same calculation shows that less than 4 percent of the braking energy
lies below 15 kilometers per hour, so a regen system that fades out at walking pace gives away very
little.
-->

---
routeAlias: energy-chain
class: big-figure
---

## The chain, both ways

<div class="diagram-wide">

![Block chain from left to right: grid and charger (dashed), battery (V = E − R0 i, step 03, 3.1 Wh/km), converter (v_out = d v_in, step 02, 2.1 Wh/km), machine (T = KΦi, E = KΦω, step 01, 17.6 Wh/km), reduction and differential (8.193, ideal, step 04), wheels and road (104.9 Wh/km). Black arrows to the right for driving, green arrows back to the battery for braking; the 12 V network hangs off the battery at 300 W, 6.4 Wh/km.](/diagrams/01-energy-chain.svg)

</div>

Every link is reversible. Each step today builds one, from the motor outwards; step 06 puts a
meter on each and reads the bill.

<!--
This picture is the lecture. Read it first from left to right, along the black arrows: that is
driving, with the energy flowing to the road. The grid fills the battery through a charger, which
costs 10 to 15 percent. The charger box is dashed: dashed means given in the course library, or
outside the model. The battery, V equals E minus R0 i, is built in step 03. It feeds the converter,
v out equals d times v in, built in step 02. The converter feeds the machine, T equals K Phi i and E
equals K Phi omega, built in step 01. The machine turns the reduction and the differential, ratio
8.193, ideal in the model, so they cost nothing; that is step 04. And the wheels push against the
road: drag, rolling resistance and tire slip. The 12 volt network hangs off the battery at 300
watts.

Now read the green arrows from right to left: that is braking. The wheels drive the machine, the
machine generates, the converter's current reverses, and the pack charges. Only below walking pace
do the friction brakes take over.

The orange numbers are the losses per kilometer on the WLTC, measured on the finished car in build
step 06. The road takes 104.9 watt-hours per kilometer: 103.1 in drag and rolling resistance and 1.8
in tire slip. The machine loses 17.6. The 12 volt network takes 6.4, the battery's resistance 3.1,
the converter 2.1, and the friction brakes, below walking pace, 0.1. All together, 134.3 watt-hours
per kilometer leave the cells, the number at the bottom of the picture.

The green step numbers are the build order. We start with the machine, the heart of the chain and
the link the theory explains, then the converter that feeds it, the battery behind it, the car
around it, regen, and finally the bill. That is the sentence under the picture: every link is
reversible, each step builds one, and step 06 puts a meter on each and reads the bill.
-->

---
routeAlias: bev-layout
---

## The battery-electric car

<div class="grid grid-cols-2 gap-8">
<div>

**Three parts** (deck): a battery to store the energy, a motor, and a controller between them
that sets the motor's power.

The battery is charged

- from the grid, through the plug;
- by **regenerative braking**.

**The controller's quadrants**

- forward and reverse driving: a **two-quadrant** controller;
- plus braking in both directions, energy back into the battery: **four quadrants**.

</div>
<div class="tight">

**The car you build: Leaf ZE1 numbers**

| | Value | Source |
|---|---|---|
| peak torque, power | 320 N·m, 110 kW | Nissan |
| base speed | 3283 rpm | Nissan |
| top motor speed | ≈ 10 100 rpm | derived |
| reduction | 8.193 | Nissan |
| pack | 40 kWh, 350 V, 96s2p | Nissan |
| pack resistance | 0.10–0.14 Ω | INL |
| mass | 1500 kg | course car |

</div>
</div>

<!--
The deck's battery-electric car has three parts: a battery that stores the energy, a motor, and a
controller between them that sets the motor's power. The battery is charged in two ways: from the
grid, through the plug, and by regenerative braking.

The controller is what we call the converter today. It sets the voltage the motor sees and the
current it draws. The deck sorts controllers by quadrants, the four quadrants of torque against
speed. A two-quadrant controller drives forward and in reverse. A four-quadrant controller can also
brake in both directions, with the current reversed so that the energy goes back into the battery.
Regenerative braking needs four quadrants.

The table on the right is the car you build today, with each number's source. Peak torque 320 newton
meters and peak power 110 kilowatts, both from Nissan's specification. Base speed 3283 rpm, also
Nissan's, and you can check that the numbers agree: 110 000 watts divided by 320 newton meters is
343.8 radians per second, which is 3283 rpm. So the motor gives 320 newton meters up to 3283 rpm,
where it meets its 110 kilowatts. The top motor speed, about 10 100 rpm, is derived: Nissan does not
state it, but the car's top speed of 144 kilometers per hour, through the 8.193 reduction and a
wheel radius of 0.31 meters, gives about 10 100 rpm. The reduction ratio, 8.193, is Nissan's. The
pack is 40 kilowatt-hours at 350 volts nominal, made of 96 pairs of cells in series, 96s2p. The pack
resistance, 0.10 to 0.14 ohm, comes from Idaho National Laboratory's pulse tests on a 2013 Leaf
pack; it rises by about half near empty, and our model uses 0.1 ohm. And the mass is the course
car's 1500 kilograms.

The hybrid layouts, series and parallel, are next lecture, on the same car.
-->

---

## Summary of section 01

- An electric car is a chain of reversible links: battery, converter, machine, gear, wheel.
- It needs the same road load as the engine car: on WLTC, **139 Wh/km** of traction at the
  wheel, and braking energy worth **a quarter** of it.
- The controller must work in four quadrants to brake into the battery.
- The car you build has the Leaf ZE1's motor, gear and pack on the course car's body.

### Next: the first link, the machine. <Link to="dc-machine">→ 02, the DC machine</Link>

<!--
To sum up section 01. An electric car is a chain of reversible links: battery, converter, machine,
gear, wheel. It needs the same road load as the engine car: on the WLTC, 139 watt-hours per
kilometer of traction at the wheel, and braking energy worth about a quarter of that, which regen
can bring back. To brake into the battery, the controller must work in four quadrants. And the car
you build has the Leaf ZE1's motor, gear and pack on the course car's body.

Next we open the chain at its first link, the machine, the link the deck spends the most slides on.
-->
