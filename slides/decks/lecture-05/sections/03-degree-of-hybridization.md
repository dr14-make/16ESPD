---
routeAlias: degree-of-hybridization
layout: section
---

###### Section 03

# Degree of hybridization

How much of the power is electric, from a micro hybrid to a plug-in, and what it costs.

`notebooks/lecture05/03-machine-size.pluto.jl`

<!--
Section 03, the degree of hybridization: how much of the car's power is electric. It runs from a
micro hybrid, which only stops the engine, to a plug-in, which drives for a while on the grid's
energy. Then what drives the cost. The sweep figure comes from the machine-size notebook.
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

<div class="caption text-left">DOH: degree of hybridization · P<sub>EM</sub>: the electric
machine's peak power · P<sub>ICE</sub>: the engine's peak power, both in kW · 0 = no machine, 1 =
battery-electric</div>

The larger it is, the smaller the engine can be, and the more of the time it runs near its best
efficiency.

**BSFC**, brake-specific fuel consumption: grams of fuel per kWh of shaft work.

$$
\mathrm{BSFC} = \frac{\dot m_f}{P}
\qquad
\eta_b = \frac{1}{\mathrm{BSFC}\cdot H_u}
$$

<div class="caption text-left">ṁ<sub>f</sub>: fuel flow, g/h · <i>P</i>: shaft power, kW ·
<i>H</i><sub>u</sub>: energy in the fuel, MJ/kg · η<sub>b</sub>: brake efficiency, the share of the
fuel's energy that becomes shaft work · in these units, η<sub>b</sub> = 3600 / (BSFC ·
<i>H</i><sub>u</sub>)</div>

232 g/kWh with *H*<sub>u</sub> = 43.4 MJ/kg is η<sub>b</sub> = 35.7 %.

Our P2: DOH = 30 kW / (30 kW + 85.6 kW) ≈ **26 %**

</div>
<div>

<img src="/figures/03-doh-sweep.svg" class="w-full" style="max-height: 24rem" alt="WLTC fuel saving of the P2 hybrid against the conventional car, SoC-corrected, for machines of 8, 15, 22, 30 and 40 kW: 22.2, 25.3, 27.6, 28.5 and 28.4 percent. The saving rises by 3.1 and 2.3 points from 8 to 22 kW, then by 0.9 to 30 kW, and 40 kW saves no more than 30 kW; 15 kW is marked at 25.3 percent, DOH 15 percent, and 30 kW at 28.5 percent, DOH 26 percent. The 8 kW point is hollow: that run falls 2.3 km/h behind the trace and does not end charge-sustaining."/>

<div class="caption">Machine power across, WLTC fuel saving against the conventional car up. Past
about 22 kW, a bigger machine saves almost nothing more.</div>

</div>
</div>

<!--
The degree of hybridization, DOH, is the share of the electric machine's power in the total. On
top, the electric machine's peak power, P EM. Below, the electric machine's power plus the
engine's peak power, P ICE, where ICE stands for internal combustion engine. Both in kilowatts.
Zero is a conventional car with no machine; one is a battery-electric car with no engine. That is
the original course deck's definition, on its slide 11.

What it buys, in the deck's words: the larger it is, the greater the scope for a smaller engine, and
for having that engine run near its best efficiency for more of the time. A machine that can carry
the car at low power lets the engine stay off there, which is exactly the region where section 01
showed the engine is worst.

The efficiency of an engine is usually given as BSFC, brake-specific fuel consumption, the term
from section 01: how many grams of fuel the engine burns for each kilowatt-hour of work at its
shaft. The first formula says it: the fuel flow, m dot f, in grams per hour, divided by the shaft
power P, in kilowatts. Lower is better.

The second formula turns it into an efficiency. Eta b, the brake efficiency, is the share of the
fuel's energy that comes out as work at the shaft. It is one over BSFC times H u, the heating
value: the energy in one kilogram of fuel, in megajoules per kilogram. The units must match: with
BSFC in grams per kilowatt-hour and H u in megajoules per kilogram, the efficiency is 3600 divided
by BSFC times H u, because a kilowatt-hour is 3.6 megajoules. Check it with Lecture 2's
best point: 232 grams per kilowatt-hour is 0.232 kilograms per 3.6 megajoules; times 43.4
megajoules per kilogram, the heating value Lecture 4 used, that is 2.80 joules of fuel per joule of
work, and the inverse is 35.7 percent.

Our P2 has a 30 kilowatt machine, so its DOH is 30 over 30 plus the engine's peak power. Lecture 2's
map peaks at 85.6 kilowatts, at about 6000 rpm, the top of the best-BSFC line. So the DOH is about
26 percent, a full hybrid.

The figure on the right runs the same P2 car and energy manager with five machine sizes, from 8 to
40 kilowatts. Across is the machine's rated power, in kilowatts. Up is the WLTC fuel saving against
the conventional car, in percent, with the fuel corrected for any change in the battery's charge.
Each green dot is one run. A filled dot is a run that ends with the battery at its starting
charge; the hollow dot is a run that does not, so we flag it.

The ICCT review expects the saving to grow with power, and says going from 15 to 20 or 30
kilowatts adds 5 to 10 percent on P2, P3 and P4, in its own words. Ours grows from 25.3 percent at
15 kilowatts to 28.5 at 30, about 3 percentage points, most of it by 22 kilowatts, and then it is
flat: 40 kilowatts saves 28.4, no more than 30. That is the one thing to take from the plot: past
the point where the machine covers the regen and the low-power driving, more power buys nothing.
The 8 kilowatt point is hollow: with the manager left as it is, that machine falls behind the speed
the test asks for, and does not end with the battery at its starting charge.
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
| **Full** | drives alone, boosts, regens; the engine can stay off | ≈ 30 kW, ≈ 1.4 kWh, 270 V (2011 Sonata Hybrid) | today's P2: 28.5 % vs no stop/start |
| **Plug-in** | a full hybrid with a pack charged from the grid | a larger pack | first drains the pack, then holds its charge |

</div>

<div class="handson">Today's car is a full hybrid. Section 07 compares the positions at its 30 kW;
at 15 kW, the size the mild-hybrid studies compare at, only P2 ran: 25.3 %, in this sweep.</div>

<!--
The degree of hybridization in four classes, from small to large.

A micro hybrid only stops the engine at standstill and restarts it with a stronger 12 volt
starter. Chalmers University of Technology in Sweden ran a study that the ICCT review reproduces.
In it, a 3 kilowatt 12 volt stop/start saves 5.0 percent on the WLTC against the same car without
it. The ICCT's own average for micro hybrids is
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
WLTC is what you measure in build 04: 28.5 percent against the same car without the hybrid, which
idles at every stop, so the stop/start saving is inside that number.

A plug-in hybrid is a full hybrid with a much larger pack charged from the grid. It first drains
the pack, mostly on grid energy; we call that charge-depleting. Then it holds the pack's charge
level like a full hybrid; we call that charge-sustaining. Today stays
charge-sustaining; section 06 says why that matters for honest numbers.

The green box: today's car is a full hybrid. Section 07 compares the five positions at its 30
kilowatts. The published studies compare them at 15; of ours only P2 ran at that size, in this
sweep, and saves 25.3 percent.
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
- Average lithium-ion pack price, 2025: **108 $/kWh** (BloombergNEF).
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

C rate: power ÷ stored energy. At 1 C the full pack would last one hour. For each kWh it holds,
the hybrid's pack gives about eight times the Leaf's power: its cells are built for **power rather
than energy**.

So its **internal resistance** *R*₀ matters: at 30 kW about 130 A flow through it, and *I*²*R*,
current squared times resistance, is lost as heat. Measured on new 2011 Sonata packs (INL, 10 s
pulse): ***R*₀ ≈ 0.33 Ω**, the value our model uses.

<div class="tight">

| 30 kW at the terminals, *R*₀ = 0.33 Ω | current | *I*²*R* | efficiency |
|---|---:|---:|---:|
| discharge | 133 A | **5.8 kW** | 83.8 % |
| charge | 99 A | 3.2 kW | 89.2 % |
| round trip, charge then discharge | | | **≈ 75 %** |

</div>

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

Divide the power the pack must give by the energy it holds. The result is called the C rate. At 1
C, the full pack would last one hour; at 2 C, half an hour. Today's car, after the 2011 Sonata: 30
kilowatts from 1.4 kilowatt-hours, about 21 per hour, a 21 C discharge. Lecture 4's Leaf: 110
kilowatts from 40 kilowatt-hours, about 2.75 C. The hybrid's pack has to give about eight times more
power for each kilowatt-hour it holds. So hybrid cells are built for power rather than energy.

And the pack's internal resistance matters. Think of it as a resistor inside the battery, R zero.
Every ampere that flows goes through it and heats it: the heat is the current squared times the
resistance, I squared R, the column in the lower table. At 30 kilowatts out of the terminals about
133 amperes flow. Idaho National Laboratory, INL, measured new 2011 Sonata Hybrid packs, the same
72-cell, 5.3 ampere-hour, 270 volt pack: 0.32 to 0.38 ohm at the end of a 10 second pulse in the
middle of the charge window, on two cars at two labs. Our model uses 0.33 ohm, and with it
reproduces INL's own pulse power.

Now read the lower table. Discharging at 30 kilowatts, the terminal voltage drops to 226 volts: 5.8
kilowatts become heat, so the battery's efficiency, the share of power that gets through, is 83.8
percent. Charging at 30 kilowatts takes 99 amperes, 3.2 kilowatts of heat, 89.2 percent. A joule
that goes in and comes back out at that power keeps about 75 percent of itself. That is the round
trip section 01 said every stored joule pays.

A 10 second value also contains slower effects inside the cells, which our simple battery model
leaves out, so it somewhat overstates the loss on short pulses; we also try 0.2 ohm to see how much
that matters. And note what it does to the machine: at 0.33 ohm the pack's voltage drops to about
220 volts when the machine takes its full input, about 33 kilowatts once its own losses are
counted. So the model designs the 30 kilowatt machine for 220 volts, not for the 270 volts the pack
shows with no current flowing. The course's research note on the hybrid pack's resistance has the
sources.

The right side is from the batteries lecture, the summary table of slide 14; the deck calls its
figures guidelines only. The first number column is energy per kilogram, in watt-hours per kilogram;
the second is power per kilogram, in watts per kilogram. The rows are lead-acid, nickel-cadmium,
nickel-metal-hydride and lithium-ion. Read the two columns as a ratio: a typical Li-ion cell there
gives 300 watts per kilogram from 150 watt-hours per kilogram, about 2 C. A hybrid asks about ten
times that, which is why a hybrid pack is not just a small electric-car pack.
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
