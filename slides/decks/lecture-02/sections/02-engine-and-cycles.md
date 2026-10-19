---
routeAlias: engine-and-cycles
layout: section
---

###### Section 02

# Engine and cycles

What an internal combustion engine is, the two cycles it runs on, and the mixture it burns.

<!--
The plant. We classify engines, look at the Otto and Diesel cycles as pressure-volume diagrams, and
end with the one number the rest of the lecture keeps coming back to: the stoichiometric air-fuel
ratio.
-->

---
routeAlias: ice
---

## Internal combustion engine

It is an engine which converts the chemical energy of fuel into mechanical energy by burning the
fuel inside the engine cylinder.

<div class="grid grid-cols-2 gap-8 mt-4">
<div>

- **Based on the fuel used**
  - Diesel engine
  - Petrol engine (or gasoline engine)
- **Based on the type of cycle**
  - Otto cycle engine
  - Diesel cycle engine
  - Dual cycle engine
- **Based on the number of strokes per cycle**
  - Two-stroke engine
  - Four-stroke engine

</div>
<div>

- **Based on the number of cylinders**
  - Single-cylinder engine
  - Multi-cylinder engine
  - Twin-cylinder engine, …
- **Based on the type of ignition**
  - Spark ignition engine (SI engine)
  - Compression ignition engine (CI engine)
- **Based on the cooling system used**
  - Air-cooled engine
  - Water-cooled engine

</div>
</div>

<!--
Internal combustion means just what it says: the fuel is burned inside the engine. In a car engine,
gasoline is burned inside the cylinder, and the energy it releases moves the car. There are other
kinds of internal combustion too, such as diesel engines and gas turbines.

Internal combustion is an efficient system that needs a relatively small engine to create motion,
and it is more fuel efficient than external combustion, like an old steam engine. It was not always
so. When the gasoline engine appeared in 1876 it was no more efficient than the steam engine, and a
lot of fuel was wasted. Rudolf Diesel set out to build a more efficient engine, and in 1892 the
diesel engine was born. It was more efficient, but it took many more years to make it cleaner and
quieter.

Today's engine, and the hands-on's, is a petrol, Otto-cycle, four-stroke, four-cylinder, spark
ignition, water-cooled engine. Every row of this slide picks one answer for it.
-->

---
routeAlias: otto-cycle
---

## Otto cycle

<div class="grid grid-cols-[2.6fr_1fr] gap-6 items-center">
<div>

<CardExport notebook="02-cycle-and-spark" name="otto-pv" height="24rem" />

</div>
<div>

![Animated four-stroke engine: intake, compression, power and exhaust strokes.](/pptx/slide20-four-stroke.gif)

</div>
</div>

<div class="text-sm">

0–1 intake at ambient pressure · 1–2 isentropic compression · 2–3 constant-volume heat addition
(combustion) · 3–4 isentropic expansion · 4–1 constant-volume heat rejection (exhaust valve opens) ·
1–0 exhaust at ambient pressure.
Compression ratio $\varepsilon = V_{\text{bdc}} / V_{\text{tdc}} = (V_{\text{swept}} + V_{\text{tdc}}) / V_{\text{tdc}}$.

</div>

<!--
Engines on the four-stroke Otto cycle have one power stroke for every four strokes, up, down, up,
down, and use a spark plug to ignite. Combustion is fast, so the volume hardly changes while it
happens: that is the "constant volume" heat addition from 2 to 3. They are used in cars, larger
boats, some motorcycles and many light aircraft. They are generally quieter, more efficient and
larger than two-strokes.

Most truck and car diesel engines use a cycle much like the four-stroke, but ignite by compression
heating instead of a spark. That is the Diesel cycle, two slides on. The fuel is injected directly
into the cylinder, so combustion happens at roughly constant pressure while the piston moves.

V tdc is the clearance volume, what is left when the piston is at the top.

The dotted line along the bottom is the gas exchange: the intake stroke from 0 to 1 draws fresh
charge in at ambient pressure, and the exhaust stroke from 1 back to 0 pushes the burned gas out.
In the ideal cycle both run at the same pressure, so together they do no net work; in a real
throttled engine the intake runs below ambient, and that pumping loop costs work.

The loop is the ideal air-standard Otto cycle from notebook 02, "The cycle and the spark": a
compression ratio of 10.5, intake at ambient, and the heat of a stoichiometric charge burned
completely. Its efficiency depends on the compression ratio alone, 61 percent here. With no heat
loss and an instant burn its peak pressure is far above a real engine's; the fired cycle of a
crank-angle cylinder model will stand beside it.
-->

---
routeAlias: two-and-four-stroke
---

## Two-stroke and four-stroke

<div class="grid grid-cols-[1fr_1.2fr] gap-8 items-center">
<div>

![Animated comparison of a two-stroke and a four-stroke engine, with the pressure-volume loop of each; the enclosed area is the mechanical work done per cycle.](/pptx/slide21-two-and-four-stroke.gif)

</div>
<div>

- **Two-stroke**: one power stroke per revolution. The end of the combustion stroke and the
  start of the compression stroke happen together; intake and exhaust (scavenging) take place
  at the same time, through ports in the cylinder wall.
- **Four-stroke**: one power stroke every two revolutions. Intake and exhaust have their own
  strokes, controlled by valves.
- In both, the **area inside the p–V loop** is the mechanical work done per cycle.

</div>
</div>

<!--
In a two-stroke engine, the end of the combustion stroke and the beginning of the compression
stroke happen at the same time, and intake and exhaust, the scavenging, also overlap. It makes a
power stroke every revolution, so it is light for its power, but some fresh mixture escapes with the
exhaust. That is why two-strokes left cars.

The four-stroke separates the jobs. Read the area of each loop: that is the work per cycle.

A good animation of the two-stroke: https://www.youtube.com/watch?v=Z6YC3I54so4
-->

---
routeAlias: diesel-cycle
---

## Diesel cycle

<div class="grid grid-cols-[1fr_1.4fr] gap-8 items-center">
<div>

<CardExport notebook="02-cycle-and-spark" name="diesel-pv" height="24rem" />

</div>
<div>

- Can operate with a **higher compression ratio**: only air is compressed, so there is no risk of
  the fuel auto-igniting.
- Fuel is sprayed into the cylinder at high pressure when compression is complete, and it ignites
  without a spark.

<div class="text-sm mt-4">

- **1–2** suction
- **2–3** adiabatic compression, both valves closed; much higher than in an Otto engine, so
  pressure and temperature rise
- **3–4** isobaric: fuel is added and burns from the high temperature at constant pressure, while
  the volume grows
- **4–5** adiabatic expansion: the piston moves from TDC to BDC and delivers power
- **5–2** isochoric heat rejection at constant volume
- **2–1** exhaust

</div>
</div>
</div>

<!--
The difference from Otto is in two places. First, the compression: only air is in the cylinder, so
it can be squeezed much harder without anything igniting early. Second, the heat addition: fuel is
sprayed in at the end of compression, at point 3, and burns as it enters, so the pressure stays
roughly constant from 3 to 4 while the piston already moves down.

Higher compression is why a diesel is more efficient, but the plot shows it is not the whole
story. Both ideal loops take the same heat per kilogram of air, that of a stoichiometric charge.
The diesel, at 18, compresses much harder than the Otto at 10.5, yet its ideal efficiency is lower,
55 against 61 percent, because it adds the heat while the piston is already moving down. A real
diesel wins because it runs lean, with far less heat per kilogram of air, so its constant-pressure
phase is short, and because it has no throttle to pump against.

A video of the cycle: https://youtu.be/DZt5xU44IfQ?t=88
-->

---
routeAlias: ice-principles
---

## ICE principles and efficiency

<div class="grid grid-cols-[1fr_1.45fr] gap-6 items-center">
<div>

- **Law of conservation of energy**: the total energy of an isolated system cannot change. Energy
  can be neither created nor destroyed, only changed from one form to another.
- The chemical energy of the fuel–air mixture is converted to kinetic energy in the explosion.
- These transformations lose a lot: the hands-on engine's best point is **35.7 % efficiency**
  (232 g/kWh), at 3000 rpm and 99 N·m.

</div>
<div>

<CardExport notebook="12-mapped-engine" name="efficiency-map" height="27rem" />

<div class="caption">Brake efficiency of the hands-on engine, from the EPA ALPHA maps of a 2014 Mazda 2.0 L, scaled to 1.5 L</div>

</div>
</div>

<!--
The map is the hands-on engine's, from the US EPA's measured Mazda data, in notebook 12. Brake
efficiency is the power at the shaft over the heat flow of the fuel burned. The star is the best
point: 35.7 percent, 232 grams of fuel per kilowatt-hour, at 3000 rpm and 99 newton-meters. That is
a good modern petrol engine at its best. Most of the rest leaves as heat in the exhaust and the
coolant.

Read the map from the lower left: at light load the efficiency falls fast, because the engine
pumps against a nearly closed throttle and its friction is a large share of a small output. A car
cruising in town sits down there. The black line is full load.
-->

---
routeAlias: stoichiometric
---

## The stoichiometric mixture

<div class="grid grid-cols-[1.5fr_1fr] gap-6 items-center">
<div>

- An "ideal" mixture in which both the fuel and the oxygen in the air are completely consumed:
  **14.6 kg of air per kg of fuel**. With a three-way catalyst it is used everywhere except near
  full load.
- To increase power, the mixture is made **rich**.
- When power is not needed, a **lean** mixture saves fuel.

$$
\lambda \;=\; \frac{\dot m_{\text{air}} / \dot m_{\text{fuel}}}{\text{AFR}_s},
\qquad \text{AFR}_s = 14.6
$$

$\lambda < 1$ rich &nbsp;·&nbsp; $\lambda = 1$ stoichiometric &nbsp;·&nbsp; $\lambda > 1$ lean

</div>
<div>

<CardExport notebook="illustrations" name="power-efficiency-vs-afr" height="22rem" />

<div class="caption">Power and brake efficiency at fixed air charge, 3000 rpm, each as % of its maximum; idealized, drawn from textbook trends</div>

</div>
</div>

<!--
The stoichiometric ratio is the one number to remember today: 14.6 kilograms of air for each
kilogram of petrol, a little more or less depending on the fuel blend; you will also see 14.7. The
ratio of the actual air-fuel ratio to this one is lambda. Lambda below one is rich, above one is
lean.

The plot on the right shows why there is no single best mixture. Maximum power is a little rich,
lambda 0.88 or 12.8 to 1, because all the oxygen gets used. Maximum efficiency is a little lean,
lambda 1.09 or 16 to 1, because all the fuel gets burned. Outside about 7 to 20, the mixture does
not burn at all: 7 to 1 is too rich, 20 to 1 too lean.

The plot is idealized, drawn from textbook trends. It holds the air of the hands-on engine's best
point, 3000 rpm and 77.5 kilopascals, and varies the fuel. At lambda one it gives that point's 35.7
percent; leaning to 1.09 would add about one percentage point. The shape is an assumed lambda
multiplier, the one Dyad task 2's mean-value engine will use; a lambda sweep of that engine replaces
this plot.

The source slide said stoichiometric is used for idle. In a modern petrol engine with a three-way
catalyst it is used nearly everywhere except full load, because the catalyst only works close to
lambda one. That is section 07. The hands-on engine runs at lambda one up to 85 percent of its
full-load manifold pressure, then richens to between 0.9 and 0.8; at 3000 rpm it uses 0.87, next to
the power peak in the plot.

A video on the mixture: https://www.youtube.com/watch?v=h5Ug-U-Rsts
-->

---

## Summary of section 02

- Today's engine: petrol, four-stroke, Otto cycle, spark ignition.
- Otto adds heat at constant volume, Diesel at constant pressure; Diesel compresses only air and so
  can use a higher compression ratio.
- Stoichiometric is 14.6 kg of air per kg of fuel, and $\lambda$ measures the mixture against it.
  Power wants rich, economy wants lean.

### Next: the system that decides how rich. <Link to="engine-control-system">→ 03, engine control system</Link>

<!--
Something has to choose the mixture, the spark and the idle speed, thousands of times a minute.
That is the engine control system.
-->
