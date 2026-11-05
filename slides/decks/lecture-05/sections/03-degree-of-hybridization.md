---
routeAlias: degree-of-hybridization
layout: section
---

###### Section 03

# Degree of hybridization

How much of the power is electric, from a micro hybrid to a plug-in, and what it costs.

<span class="todo">TODO: notebook file (#115)</span>

<!--
Section 03, the degree of hybridization: how much of the car's power is electric. It runs from a
micro hybrid, which only stops the engine, to a plug-in, which drives for a while on the grid's
energy. Then what drives the cost. The sweep figure comes from the degree-of-hybridization
notebook of issue 115.
-->

---
routeAlias: doh
---

## How much of the power is electric

<div class="grid grid-cols-[1fr_1.3fr] gap-8 items-center">
<div>

$$
\mathrm{DOH} = \frac{P_{EM}}{P_{EM} + P_{ICE}}
$$

The larger it is, the smaller the engine can be, and the more of the time it runs near its best
efficiency.

**BSFC**, brake-specific fuel consumption: fuel mass per unit of shaft work.

$$
\mathrm{BSFC} = \frac{\dot m_f}{P}
\qquad
\eta_b = \frac{1}{\mathrm{BSFC}\cdot H_u}
$$

232 g/kWh with *H*<sub>u</sub> = 43.4 MJ/kg is η<sub>b</sub> = 35.7 %.

Our P2: DOH = 30 kW / (30 kW + 85.6 kW) ≈ **26 %**

</div>
<div>

<div class="placeholder">

**Figure: `03-doh-sweep.svg`**

WLTC fuel saving of the P2 hybrid against machine power, 8 to 40 kW, the 15 kW and 30 kW cases
marked.

Produced by the degree-of-hybridization notebook, #115

</div>

</div>
</div>

<!--
The degree of hybridization, DOH, is the share of the electric machine's power in the total: P EM
over P EM plus P ICE. Zero is a conventional car, one is a battery-electric car. That is the
original deck's definition, slide 11.

What it buys, in the deck's words: the larger it is, the greater the scope for a smaller engine, and
for having that engine run near its best efficiency for more of the time. A machine that can carry
the car at low power lets the engine stay off there, which is exactly the region where section 01
showed the engine is worst.

The efficiency of an engine is usually given as BSFC, brake-specific fuel consumption: the fuel mass
flow divided by the shaft power, in grams per kilowatt-hour. Lower is better. It is the inverse of
the brake efficiency times the fuel's lower heating value. Check it with Lecture 2's best point: 232
grams per kilowatt-hour is 0.232 kilograms per 3.6 megajoules; times 43.4 megajoules per kilogram,
the heating value Lecture 4 used, that is 2.80 joules of fuel per joule of work, and the inverse is
35.7 percent.

Our P2 has a 30 kilowatt machine, so its DOH is 30 over 30 plus the engine's peak power. Lecture 2's
map peaks at 85.6 kilowatts, at about 6000 rpm, the top of the best-BSFC line. So the DOH is about 26
percent, a full hybrid.

The figure on the right will be the sweep: the same P2 car with machines from 8 to 40 kilowatts, the
WLTC fuel saving against machine power. The ICCT review expects the saving to grow with power, and
says going from 15 to 20 or 30 kilowatts adds 5 to 10 percent on P2, P3 and P4, in its own words. Watch
whether ours flattens: past the point where the machine covers the regen and the low-power driving,
more power buys little.
-->

---
routeAlias: micro-to-plug-in
---

## From micro to plug-in

<div class="tight">

| Class | What the machine does | Machine, battery | WLTC saving |
|---|---|---|---|
| **Micro** | stops and restarts the engine | 12 V starter, ≈ 3 kW | 5.0 % vs no stop/start (Chalmers); 3.5 % average (ICCT) |
| **Mild, 48 V** | boost and regen; electric driving only if decoupled | 8–20 kW | ≈ 7 % (P0) to ≈ 16 % (P2, P3, P4+P0) vs stop/start, 15–16 kW |
| **Full** | drives alone, boosts, regens; the engine can stay off | ≈ 30 kW, ≈ 1.4 kWh, 270 V (2011 Sonata Hybrid) | today's result: <span class="todo">TODO (#113)</span> |
| **Plug-in** | a full hybrid with a pack charged from the grid | a larger pack | first charge-depleting, then charge-sustaining |

</div>

<div class="handson">Today's car is a full hybrid. The P-position comparison of section 07 runs it
at 15 kW too, the size the mild-hybrid studies compare at.</div>

<!--
The degree of hybridization in four classes, from small to large.

A micro hybrid only stops the engine at standstill and restarts it with a strengthened 12 volt
starter. In the Chalmers study the ICCT review reproduces, a 3 kilowatt 12 volt stop/start saves
5.0 percent on the WLTC against the same car without it. The ICCT's own average for micro hybrids is
3.5 percent on the WLTC.

A mild hybrid at 48 volts adds a machine of 8 to 20 kilowatts, the range the research note collects
from the studies. It boosts and recovers braking; whether it can drive the car alone depends on
whether it can be decoupled from the engine, which is section 04. With a comparable 15 to 16
kilowatt machine the ICCT review finds from about 7 percent for P0 to almost 16 percent for P2, P3
and P4 with P0, against a stop/start car.

A full hybrid has a machine and a battery large enough to drive the car alone at low power and keep
the engine off for long stretches. The anchor is the 2011 Hyundai Sonata Hybrid Oak Ridge
benchmarked: a 30 kilowatt machine behind an engine clutch, a 1.4 kilowatt-hour, 270 volt pack, and
a claimed electric drive up to 62 miles per hour. That is the size of today's car. Its saving on the
WLTC is what you measure in build 04.

A plug-in hybrid is a full hybrid with a much larger pack charged from the grid. It first drives
charge-depleting, mostly on grid energy, then charge-sustaining like a full hybrid. Today stays
charge-sustaining; section 06 says why that matters for honest numbers.

The green box: today's car is a full hybrid. In section 07 the same car also runs with a 15
kilowatt machine, because that is the size at which the published studies compare positions.
-->

---
routeAlias: cost
---

## What it costs

<div class="grid grid-cols-2 gap-8">
<div>

### Keep the rest of the car

- Keep the vehicle and the transmission as they are in the conventional car.
- At 48 V: integrate the machine into the existing engine, in place of the 12 V alternator.
- Above that: a new transmission housing for P2, a new axle for P4, high-voltage wiring and
  safety.

</div>
<div>

### The battery

- The high-voltage battery is the largest single addition.
- Average lithium-ion pack price, 2025: **108 $/kWh** (BNEF).
- A full hybrid's ≈ 1.4 kWh is small; a plug-in's pack is many times that, and so is its cost.

</div>
</div>

<div class="handson">The cheapest hybrid changes the least: P0 on the belt. The most effective
needs a clutch inside the driveline. Section 04 is that trade.</div>

<!--
What drives the cost, from the original deck's slide 12.

The first driver is the impact on the existing powertrain. The cheapest way is to keep the vehicle
and the transmission architecture of the conventional car, and at 48 volts to integrate the machine
into the existing engine, replacing the 12 volt alternator on the belt. Anything more needs a
redesign: a P2 needs room for a machine and a clutch in the transmission housing, a P4 a new rear
axle, and above 48 volts the whole high-voltage wiring and its protection.

The second driver is the high-voltage battery. Prices have fallen a long way: BloombergNEF's survey
puts the average lithium-ion pack at 108 dollars per kilowatt-hour in 2025, the number Lecture 4
showed. That is already below what the original deck forecast for 2030. A
full hybrid's pack of about 1.4 kilowatt-hours is small. A plug-in's is many times larger, and so
is its cost and its mass.

The green box sets up the next section. The cheapest hybrid changes the least: a P0 machine on the
belt. The most effective one needs a clutch inside the driveline. Section 04 shows why that is the
trade.
-->

---
routeAlias: power-battery
---

## A hybrid battery is a power battery

<div class="grid grid-cols-2 gap-8 items-start">
<div>

<div class="tight">

| | Power | Energy | Power / energy |
|---|---:|---:|---:|
| today's hybrid (2011 Sonata) | 30 kW | 1.4 kWh | **≈ 21 C** |
| Lecture 4's Leaf | 110 kW | 40 kWh | ≈ 2.75 C |

</div>

For each kWh it holds, the hybrid's pack gives about eight times the Leaf's power: its cells are
built for **power rather than energy**.

So its **internal resistance** matters: at 30 kW and 270 V, about 110 A flow through it. Our
*R*₀ ≈ 0.077 Ω is **an assumption, not derived**, and likely optimistic: the *I*²*R* loss in our
hybrid results may be understated. A 1.4 kWh pack of energy cells would have a far higher
resistance; real hybrid packs use high-power cells, built for low resistance per Ah.

</div>
<div>

**Batteries deck, summary table (guidelines only)**

<div class="tight">

| Chemistry | Wh/kg | W/kg |
|---|---:|---:|
| lead-acid | 30 | 250 |
| NiCd | 50 | 150 |
| NiMH | 65 | 200 |
| Li-ion | 150 | 300 |

</div>

Li-ion in that table: 300 W/kg from 150 Wh/kg, **2 C**. A hybrid asks ten times that.

</div>
</div>

<!--
The battery from the last slide, seen from the side that matters for a hybrid: power.

Divide the power the pack must give by the energy it holds. Today's car, after the 2011 Sonata: 30
kilowatts from 1.4 kilowatt-hours, about 21 per hour, a 21 C discharge. Lecture 4's Leaf: 110
kilowatts from 40 kilowatt-hours, about 2.75 C. The hybrid's pack has to give about eight times more
power for each kilowatt-hour it holds. So hybrid cells are built for power rather than energy.

And the pack's internal resistance matters. At 30 kilowatts and 270 volts about 110 amperes flow,
and every one of them goes through R zero. Say plainly what ours is: an assumption, not a derived
number. The model takes the Leaf pack's 0.1 ohm times 270 over 350 volts, about 0.077 ohm. But pack
resistance goes as the series count times the cell resistance over the parallel count, and scaling
by series count alone keeps the Leaf's strings of about 114 ampere-hours: that is a 31
kilowatt-hour pack, not a 1.4 kilowatt-hour one of about 5 ampere-hours. A 5 ampere-hour pack of
energy cells would have a far higher resistance; real hybrid packs use high-power cells built for low
resistance per ampere-hour. We have no source for their number, so ours is unsourced and likely
optimistic, and the resistive loss in our hybrid results may be understated.

The right side is from the batteries lecture, the summary table of slide 14; the deck calls its
figures guidelines only. Read the two columns as a ratio: a typical Li-ion cell there gives 300 watts
per kilogram from 150 watt-hours per kilogram, about 2 C. A hybrid asks about ten times that, which is
why a hybrid pack is not just a small electric-car pack.
-->

---

## Summary of section 03

- **DOH** = P<sub>EM</sub> / (P<sub>EM</sub> + P<sub>ICE</sub>): the larger, the more the engine
  can stay off or run near its best BSFC.
- Micro, mild 48 V, full, plug-in: from stopping the engine to driving on the grid's energy.
- Today's car is a **full hybrid**: ≈ 30 kW, ≈ 1.4 kWh. Cost: the integration and the battery.

### Next: where the machine sits. <Link to="p-positions">→ 04, P0 to P4</Link>

<!--
Section 03 in three lines. The degree of hybridization is the machine's share of the power; the
larger it is, the more the engine can stay off or run near its best fuel consumption. The classes
run from the micro hybrid, which only stops the engine, through the 48 volt mild hybrid and the full
hybrid, to the plug-in, which drives on the grid's energy. Today's car is a full hybrid, about 30
kilowatts and 1.4 kilowatt-hours, and its cost is the integration and the battery.

Next: where in the driveline the machine sits.
-->
