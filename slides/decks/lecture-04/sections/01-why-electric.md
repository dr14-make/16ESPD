---
routeAlias: why-electric
layout: section
---

###### Section 01

# Why electric

The case for the electric car, the energy it needs, and the chain that delivers it both ways.

<!--
Budget: about 12 minutes for the section, no build. It condenses deck 7's slides 3 to 8: why EVs,
the energy model, regen, the benefits and the battery-electric layout. The history slide is
left out; the hybrid layouts are Lecture 5.
-->

---
routeAlias: why-evs
---

## Why electric vehicles

<div class="grid grid-cols-2 gap-8">
<div>

**The problem** (deck)

- Transport is about a fifth of greenhouse-gas emissions, and its share has grown.
- EU fleet CO₂ limits for new cars have tightened since Regulation 443/2009.

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
Deck 7, slides 3 and 7, condensed. The deck put transport at 19.7 percent of greenhouse-gas
emissions, with passenger cars about 12 percentage points of it, and cited the EU's CO₂
regulation for new cars, 443/2009. Those numbers are the deck's and dated; the slide keeps the
argument, not the figures.

The deck claimed 85 to 95 percent efficiency for the electric drive. Today we measure it instead:
the machine and converter together reach 93.8 percent at the corner point in build 02, and the
WLTC bill in section 08 shows what the whole chain delivers on a real cycle.

The deck's benefit list also had "domestically generated electricity" and "reduces peak load on
the grid": both depend on the grid and on when the car charges, so they stay in the notes.

The history slide, deck 7 slide 4, is left out: electric cars came before petrol ones and lost
to them on range around 1910–1920. The battery is still the reason, which is section 06.
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
Deck 7 slide 5 lists five resistances: O v aerodynamic, O f rolling, O z acceleration, O s slope,
and O aux, everything electrical that is not propulsion. The first four are a force at the
wheel; the last is a power from the battery.

This is Lecture 2's notebook 01, unchanged. The course library extracted it into a mass-free
`RoadLoad` part so the planar car can use it through an adapter: the same numbers, so the engine
and the electric car meet the same road.

The green box is the size of the prize. On the WLTC a 1500 kg course car needs 139 Wh per km of
positive traction energy at the wheel, and the braking phases would give back energy worth 25 to
26 percent of that, if every bit could be recovered. Both are derived in the research note from
the cycle and the road load. Below 15 km/h sits under 4 percent of it, so a regen fade at walking
pace costs little.

The 300 W auxiliaries are a car on a test cycle with the climate control off: lights, pumps,
electronics.
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
The picture is the lecture. Read it left to right for driving: the grid fills the battery through
a charger, the battery feeds the converter, the converter the machine, the machine turns the
reduction and the differential, and the wheels push against the road. Read the green arrows right
to left for braking: the wheels drive the machine, which turns generator, the converter's current
reverses and the battery charges.

The orange numbers are the losses per kilometer on the WLTC, measured in build step 06 on the
finished car: the road takes 103.1 Wh/km in drag and rolling and 1.8 in tire slip, the machine
17.6, the auxiliaries 6.4, the battery's resistance 3.1, the converter 2.1. Out of the cells,
134.3. The reduction and the differential are ideal gears in this model; a real one would cost
2 to 3 percent each way, which is in the known limits.

The step numbers are the build order: the machine first, because it is the heart of the chain and
the one the theory explains; then the converter that feeds it, the battery behind it, the car
around it, regen, and the bill.
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
Deck 7 slide 8. The battery, the motor and a controller between them. The controller is today's
converter: it sets the voltage the motor sees and the current it draws. Two quadrants means it can
drive forwards and backwards; four quadrants means it can also brake in both directions, with the
current reversed, and that is what regenerative braking needs.

The table is the car you build, from the plan's reality anchors. 320 newton meters from standstill
to 3283 rpm, where it meets 110 kW: 110 000 divided by 320 is 343.8 radians per second, 3283 rpm,
so the two Nissan numbers agree. The top speed of 144 km/h through the 8.193 reduction and a
0.31 meter wheel gives about 10 100 rpm. The pack: 40 kWh at 350 volts, 96 cell pairs in series.
Its resistance comes from INL's pulse tests on a 2013 Leaf pack: 0.11 to 0.145 ohm at mid
charge, about 50 percent more near empty; the model uses 0.1.

Series and parallel hybrids, deck 7 slides 9 to 18, are Lecture 5, on the same car.
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
One minute. The chain is the thread of the day; the next section opens it at the machine, the
link the deck spends most slides on.
-->
