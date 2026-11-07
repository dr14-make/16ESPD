---
routeAlias: series-and-parallel
layout: section
---

###### Section 02

# Series and parallel

Who drives the wheels: only the motor, the engine and the motor together, or one then the other
through a clutch. Other kinds of hybrid, briefly.

<!--
Section 02, series and parallel. The first question about any hybrid is who drives the wheels. In
a series hybrid only the electric motor does, and the engine only makes electricity. In a parallel
hybrid the engine and the motor both drive them. A series-parallel hybrid switches between the
two with a clutch. Then one slide on the other kinds of hybrid. No
build here, but the series hybrid is your homework.
-->

---
routeAlias: series-hybrid
---

## Series hybrid: only the motor drives

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-center">
<div>

![Block diagram of a series hybrid. The engine turns a generator, mechanical to electrical, which feeds a DC link; the battery is on the same link, and in a plug-in the grid charges it; the link feeds the motor, electrical to mechanical, which alone drives the wheels, and regen goes back to the battery. No shaft runs from the engine to the wheels.](/diagrams/02-series.svg)

<div class="caption">Orange: electric connections · black: shafts</div>

</div>
<div class="text-[0.95rem]">

**Drives the wheels:** one or more electric motors, only.

**Feeds the motor:** the engine-generator, the battery, or both when extra power is needed.

**Charges the battery:** the engine through the generator, regenerative braking, and the grid in
a plug-in.

**The price:** every joule from the engine is converted twice, and the motor must drive the car
alone, so it is full size.

**Used in** diesel-electric locomotives, and all-terrain vehicles with a separately controlled
motor in each wheel.

</div>
</div>

<!--
The first architecture, the series hybrid.

The vehicle is driven by one or more electric motors, and only by them. Point at the drawing: the
orange lines are electrical, the black ones are shafts, and there is no shaft from the engine to the
wheels. The engine only turns a generator. The orange dot, the DC link, is the electrical junction
that the generator, the battery and the motor all share.

The motor is fed from the engine and its generator, from the battery, or from both when extra power
is needed. The battery is charged by the engine through the generator, by regenerative braking when
the motor works as a generator and brakes the car, and in a plug-in also from the grid, the dashed
box.

So the engine is completely free of the road: it can run at its best point whatever the car does, or
stand still. The price is in the two labels above the generator and the motor: every joule from the
engine is converted twice, mechanical to electrical and back. And the motor must be big enough to
drive the car alone.

The take-away from the drawing is its bottom line: no shaft from the engine to the wheels, so every
joule from the engine is converted twice.

The original course deck names where that is used: diesel-electric locomotives, and special
all-terrain vehicles with a separately controlled motor in each wheel. Keep the series hybrid in
mind: it is your homework.
-->

---
routeAlias: parallel-hybrid
---

## Parallel hybrid: both drive the wheels

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-center">
<div>

![Block diagram of a parallel hybrid. The engine drives through the K0 clutch onto a shaft that the motor also drives, then through the transmission, whose ratio ties the engine speed to the wheels, to the wheels; the battery feeds the motor.](/diagrams/02-parallel.svg)

<div class="caption">Orange: electric connections · black: shafts · K0: the clutch that cuts off the
engine</div>

</div>
<div class="text-[0.95rem]">

**Drives the wheels:** the engine directly through the transmission; one or more motors through
the transmission or coupled directly to the wheels; or both at once.

**The energy path:** the engine's power reaches the road mechanically, never converted twice. The
motor helps; it need not carry the car, so it can be small.

**The price:** the engine's speed is tied to the wheels through the transmission.

**Used in** most passenger hybrids, and the car you build today.

</div>
</div>

<!--
The second architecture, the parallel hybrid.

The vehicle is driven either by the engine working directly through a transmission, by one or more
electric motors working through the transmission or coupled directly to the wheels, or by both at
once. In the drawing the motor sits on the same shaft as the engine, before the transmission; a
motor on the wheels is the other option, and we come back to it as P4.

Same colors as before: orange is electrical, black is shafts. Point at the black line from the
engine to the wheels: there is a mechanical path, so when the engine drives, its power reaches the
road without being converted twice. That is the take-away of this drawing. And the motor only helps,
so it can be much smaller than a series hybrid's.

The price is under the transmission: the engine's speed is tied to the wheels through its ratio. The
engine cannot simply sit at its best point.

This is what most passenger hybrids are, and what you build today. The drawing already shows the
clutch K0 between the engine and the motor: the clutch that can cut the engine off from the rest of
the driveline. Section 04 is about where exactly the motor sits, and why that clutch matters.
-->

---
routeAlias: series-parallel-clutch
---

## Series-parallel: a series hybrid with a clutch

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-center">
<div>

![The series hybrid's diagram with one addition: a clutch on the engine-generator shaft, closed at steady cruise, joins the engine's shaft to the motor's shaft above the wheels. With the clutch open it is a series hybrid; with it closed the engine drives the wheels directly.](/diagrams/02-series-parallel-clutch.svg)

<div class="caption">Orange: electric connections · black: shafts</div>

</div>
<div class="text-[0.95rem]">

**Low speed, clutch open:** a series hybrid. The engine turns the generator; the motor drives the
wheels.

**Steady cruise, clutch closed:** the engine drives the wheels directly. There, one mechanical path
beats converting every joule twice.

**Used in** Honda's current hybrids.

**Against the power split** of <Link to="power-split">section 05</Link>: a few fixed modes,
switched by a clutch, not a split that changes smoothly.

</div>
</div>

<!--
One layout sits between the two: the series-parallel hybrid with a clutch. Point at the drawing,
same colors, orange electrical and black shafts: it is the series diagram from two slides ago, with
one clutch added on the engine's shaft, after the generator, and a new black shaft from it to the
wheels.

At low speed the clutch is open and the car is a series hybrid: the engine turns the generator, the
motor alone drives the wheels, and the engine is free of the road, where that freedom pays most.

At steady cruise the clutch closes and the engine drives the wheels directly. There the engine's
speed tied to the wheels costs little, because the cruise point is steady, and the mechanical path
saves the double conversion. So it takes the series hybrid's strength where the series is good and
the parallel's where the parallel is good.

Honda's current hybrids use this layout. No numbers on it today: our research notes have none.

The last line is the contrast with the power-split hybrid of section 05, the Prius: there a
planetary gear, a set of gears turning around a central gear, splits the engine's power smoothly
between a mechanical and an electrical path. Here a clutch switches between a few fixed modes.
-->

---
routeAlias: series-or-parallel
---

## Series or parallel: what each costs

<div class="grid grid-cols-2 gap-8">
<div>

### Series

- The engine is free of the road: any speed, any torque, or off.
- Every joule from the engine is converted twice: generator, then motor.
- The motor must carry the whole car; the generator, the whole engine.
- Simple to control: the engine is a power source for the battery.

</div>
<div>

### Parallel

- One mechanical path: no double conversion when the engine drives.
- The engine's speed is tied to the wheels through the transmission.
- The machine can be small: it helps, it does not carry the car.
- A transmission with a free ratio, the CVT, gives back the speed freedom.

</div>
</div>

<div class="handson">Homework: a series hybrid, with prepared parts. The library gives an
engine-generator with its mount and a WLTC test model; you wire the series layout and write the
battery's thermostat: engine on when the charge (SoC) is low, off when it is high. Targets: the
battery ends within ±0.02 of its starting SoC; at most 5.60 L/100 km, with the fuel corrected for
the change in charge.</div>

[page: the homework](../lecture/lecture-05/homework)

<!--
What each architecture costs, the last two slides side by side.

The series hybrid's strength is that the engine is free of the road: any speed and torque, ideally
its single best point, or off. Its weakness is the double conversion: generator, converter, motor,
a few percent lost each time, as you measured on Lecture 4's chain. And it needs three full
machines: an engine, a generator that takes all its power, and a motor that drives the car alone.
It is simple to control: the engine is a power source that keeps the battery in a window, like a
thermostat keeps a room warm.

The parallel hybrid's strength is the single mechanical path, and a machine that can be small,
because it only helps. Its weakness is the engine's speed tied to the wheels. The last line is why
our car is a good place to learn this: the CVT has a free ratio, so it gives back most of the speed
freedom a series hybrid has. Section 05 uses exactly that.

The green box is the homework. The series hybrid is the same shape as the fuel-cell car of the extra
pack, so you get prepared parts: the library ships an engine-generator part with its mount and a
WLTC test model. You wire the series layout and write the thermostat that starts the engine when
the state of charge is low and stops it when it is high. State of charge, SoC, is how full the
battery is, from 0 to 1. To pass, the car ends the WLTC within 0.02 of the SoC it started with; we
call that charge-sustaining. And it burns at most 5.60 liters per 100 kilometers, after the fuel is
corrected for any change in the battery's charge: a few percent under the conventional car. The
homework page has the full list.
-->

---
routeAlias: other-hybrids
---

## Other kinds of hybrid, briefly

<div class="grid grid-cols-2 gap-8 text-[0.95rem]">
<div>

- **Fuel cells**: hydrogen into electricity, a battery beside it: a series hybrid with another
  source. The original deck counts metal-air batteries, such as zinc-air, as "fueled" too.
  *Extra pack.*
- **Supply lines**: trolleybuses and trams take their power from overhead lines, often with a
  battery for the gaps.

</div>
<div>

- **Flywheels and supercapacitors**: very high power per kilogram, they take and give energy
  quickly; but little energy per kilogram.
- **Solar**: record-setting cars in races across Australia; on a road car the panel area limits it
  to a little extra range.

</div>
</div>

<!--
The original deck closes its hybrid part with other kinds of hybrid. One slide, briefly.

Fuel-cell vehicles turn hydrogen into electricity, with a battery beside the stack to take regen
and the peaks. Seen from the wheels it is a series hybrid with a different source, which is why the
extra pack treats it right after your series homework. The deck puts metal-air batteries, such as
zinc-air, in the same fueled group.

Electric vehicles on supply lines: trolleybuses and trams, used for city transport, with the power
from overhead lines; many now carry a battery to cross the gaps.

Flywheels and supercapacitors: both have very high specific power, meaning power per kilogram; they
take in and give out energy very quickly. But their specific energy, the energy stored per
kilogram, is small. That makes them good for braking and
launching, poor as the only store.

Solar cars: the deck mentions the record runs in the solar races across Australia. On a road car the
area of the roof limits what the sun can give, so solar can at most add a little range. No numbers
on this slide: none of them come back today.
-->

---

## Summary of section 02

- **Series**: only the motor drives; the engine is free of the road, but its energy is converted
  twice. Your homework.
- **Parallel**: engine and machine both drive; one mechanical path, the engine's speed tied to the
  wheels, which the CVT loosens.
- **Series-parallel with a clutch**: a series hybrid at low speed, the engine on the wheels at
  steady cruise.
- Fuel cells are a series hybrid with another source: the extra pack.

### Next: how much of the power is electric. <Link to="degree-of-hybridization">→ 03, degree of hybridization</Link>

<!--
Section 02 in four lines. In a series hybrid only the motor drives, the engine is free of the
road, and its energy is converted twice; you build one as homework. In a parallel hybrid the engine
and the machine both drive, with one mechanical path, and the engine's speed tied to the wheels,
which our CVT loosens. The series-parallel hybrid with a clutch drives as a series hybrid at low
speed and closes a clutch to put the engine on the wheels at steady cruise. And the fuel-cell car
is a series hybrid with another source, in the extra pack.

Next: how much of the power is electric, the degree of hybridization.
-->
