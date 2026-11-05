---
routeAlias: series-and-parallel
layout: section
---

###### Section 02

# Series and parallel

Who drives the wheels: only the motor, or the engine and the motor together. Other kinds of
hybrid, briefly.

<!--
Section 02, series and parallel. The first question about any hybrid is who drives the wheels. In
a series hybrid only the electric motor does, and the engine only makes electricity. In a parallel
hybrid the engine and the motor both drive them. Then one slide on the other kinds of hybrid. No
build here, but the series hybrid is your homework.
-->

---
routeAlias: series-hybrid
---

## Series hybrid: only the motor drives

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-center">
<div>

![Block diagram of a series hybrid. The engine turns a generator, mechanical to electrical, which feeds a DC link; the battery is on the same link, and in a plug-in the grid charges it; the link feeds the motor, electrical to mechanical, which alone drives the wheels, and regen goes back to the battery. No shaft runs from the engine to the wheels.](/diagrams/02-series.svg)

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
orange lines are electrical, the black ones shafts, and there is no shaft from the engine to the
wheels. The engine only turns a generator.

The motor is fed from the engine and its generator, from the battery, or from both when extra power
is needed. The battery is charged by the engine through the generator, by regenerative braking when
the motor runs backwards as a generator, and in a plug-in also from the grid, the dashed box.

So the engine is completely free of the road: it can run at its best point whatever the car does, or
stand still. The price is in the two labels above the generator and the motor: every joule from the
engine is converted twice, mechanical to electrical and back. And the motor must be big enough to
drive the car alone.

The original deck names where that is used: diesel-electric locomotives, and special all-terrain
vehicles with a separately controlled motor in each wheel. Keep the series hybrid in mind: it is your
homework.
-->

---
routeAlias: parallel-hybrid
---

## Parallel hybrid: both drive the wheels

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-center">
<div>

![Block diagram of a parallel hybrid. The engine drives through the K0 clutch onto a shaft that the motor also drives, then through the transmission, whose ratio ties the engine speed to the wheels, to the wheels; the battery feeds the motor.](/diagrams/02-parallel.svg)

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
once. In the drawing the motor sits on the same shaft as the engine, before the transmission; a motor
on the wheels is the other option, and we come back to it as P4.

Point at the black line from the engine to the wheels: there is a mechanical path, so when the engine
drives, its power reaches the road without being converted twice. And the motor only helps, so it can
be much smaller than a series hybrid's.

The price is under the transmission: the engine's speed is tied to the wheels through its ratio. The
engine cannot simply sit at its best point.

This is what most passenger hybrids are, and what you build today. The drawing already shows the
clutch K0 between the engine and the motor; section 04 is about where exactly the motor sits, and
why that clutch matters.
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

<div class="handson">Homework: a series hybrid on prepared ground. The library gives an
engine-generator with its mount and a WLTC bench; you wire the series layout and write the SoC
thermostat. <span class="todo">TODO: targets and page (#116)</span></div>

<!--
What each architecture costs, the last two slides side by side.

The series hybrid's strength is that the engine is free of the road: any speed and torque, ideally
its single best point, or off. Its weakness is the double conversion: generator, converter, motor,
a few percent lost each time, as you measured on Lecture 4's chain. And it needs three full
machines: an engine, a generator that takes all its power, and a motor that drives the car alone.
It is simple to control: the engine is a power source that keeps the battery in a window, a
thermostat.

The parallel hybrid's strength is the single mechanical path, and a machine that can be small,
because it only helps. Its weakness is the engine's speed tied to the wheels. The last line is why
our car is a good place to learn this: the CVT has a free ratio, so it gives back most of the speed
freedom a series hybrid has. Section 05 uses exactly that.

The green box is the homework. The series hybrid is the same shape as the fuel-cell car of the extra
pack, so you get it on prepared ground: the library ships an engine-generator part with its mount
and a WLTC bench. You wire the series layout and write the thermostat that starts the engine when
the state of charge is low and stops it when it is high. The targets and the homework page come
with issue 116.
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

- **Flywheels and supercapacitors**: very high specific power, they take and give energy quickly;
  poor specific energy.
- **Solar**: record-setting cars in races across Australia; on a road car the panel area limits it
  to a range extender.

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

Flywheels and supercapacitors: both have very high specific power, they take in and give out
energy very quickly, but they store little per kilogram. That makes them good for braking and
launching, poor as the only store.

Solar cars: the deck mentions the record runs in the solar races across Australia. On a road car
the area of the roof limits what the sun can give, so solar is at most a range extender. No numbers
on this slide: none of them come back today.
-->

---

## Summary of section 02

- **Series**: only the motor drives; the engine is free of the road, but its energy is converted
  twice. Your homework.
- **Parallel**: engine and machine both drive; one mechanical path, the engine's speed tied to the
  wheels, which the CVT loosens.
- Fuel cells are a series hybrid with another source: the extra pack.

### Next: how much of the power is electric. <Link to="degree-of-hybridization">→ 03, degree of hybridization</Link>

<!--
Section 02 in three lines. In a series hybrid only the motor drives, the engine is free of the
road, and its energy is converted twice; you build one as homework. In a parallel hybrid the engine
and the machine both drive, with one mechanical path, and the engine's speed tied to the wheels,
which our CVT loosens. And the fuel-cell car is a series hybrid with another source, in the extra
pack.

Next: how much of the power is electric, the degree of hybridization.
-->
