---
routeAlias: why-hybridize
layout: section
---

###### Section 01

# Why hybridize

Where Lecture 2's engine spends the WLTC on its fuel map, and the three ways a hybrid saves fuel.

`notebooks/lecture05/01-operating-points.pluto.jl`

<!--
Section 01, why hybridize. Before we add a single part, we look at where Lecture 2's engine spends
the WLTC on its own fuel map, the chart of how much fuel it burns at each speed and torque, and see
that it spends most of the test far from where it is efficient.
That gap is what a hybrid goes after, in three ways. The figure comes from the operating-points
notebook.
-->

---
routeAlias: wltc-on-the-bsfc-map
---

## Where Lecture 2's engine spends the WLTC

<div class="grid grid-cols-[1.4fr_1fr] gap-8 items-center">
<div>

<img src="/figures/05-operating-points-conventional.svg" class="w-full" style="max-height: 24rem" alt="Lecture 2's BSFC map with the conventional car's WLTC operating points as bubbles sized by the fuel burned there. Nearly all the fuel lies on one diagonal band from about 2300 rpm at 10 N·m to 3600 rpm at 110 N·m, set by the CVT's pedal schedule, at higher speed and lower torque than the best-BSFC line, in the 250 to 350 g/kWh region."/>

<div class="caption">Engine speed across, torque up · thin black rings: BSFC · blue: the best-BSFC
line · red bubbles: where the fuel burns, bigger = more. Most of the fuel burns below and right of
the blue line.</div>

</div>
<div>

**BSFC**, brake-specific fuel consumption: grams of fuel per kWh of work at the shaft. Lower is
better. The **best-BSFC line**: for each power, the speed and torque with the lowest BSFC.

**At its best**: 35.7 % brake efficiency (fuel energy that becomes shaft work), **232 g/kWh**, at
3000 rpm and 99 N·m.

**Over the WLTC**: 30.2 % of the fuel's energy reaches the shaft as work, an average BSFC of
**275 g/kWh**. Only a third of the fuel burns within 10 g/kWh of the best-BSFC line.

| Engine power | ≤ 1 kW | 1–10 kW | 10–40 kW | > 40 kW |
|---|---:|---:|---:|---:|
| share of time | 42.6 % | 28.7 % | 28.5 % | 0.2 % |
| share of fuel | 5.9 % | 26.2 % | 66.7 % | 1.2 % |

**At every stop**: idling, burning fuel for no work at all.

</div>
</div>

<!--
First, one term. BSFC means brake-specific fuel consumption: how many grams of fuel the engine
burns for each kilowatt-hour of work it gives at its shaft. Lower is better. Brake means measured
at the shaft, the crankshaft.

Now the figure, Lecture 2's fuel map. Across is engine speed, in revolutions per minute. Up is the
engine's torque, in newton meters. The thick black curve at the top is full load, the most torque
the engine can give. The thin black rings are lines of equal BSFC, labeled in grams per
kilowatt-hour;
the smallest ring, near 3000 rpm, is the best point. The dashed gray curves are lines of equal
power, 20 to 80 kilowatts. The blue line is the best-BSFC line: for each power, the speed and torque
where the engine burns the least fuel. On top, the red bubbles are every point the conventional
car visits on the WLTC; the bigger the bubble, the more fuel burned there.

The one thing to see: nearly all the fuel lies on one diagonal band, from about 2300 rpm at light
load to 3600 rpm at 110 newton meters. The CVT's pedal schedule, the rule that picks its ratio from
the pedal, puts it there. That band runs faster and with less torque than the blue line, in the 250
to 350 gram region. Only a third of the fuel is burned within 10 grams per kilowatt-hour of the
line. That gap is what the hybrid recovers.

The right column has the numbers behind that figure. At its best point the engine turns 35.7 percent
of the fuel's energy into shaft work: that is its brake efficiency, 232 grams of gasoline per
kilowatt-hour, at 3000 rpm and 99 newton meters. That is the star on Lecture 2's efficiency map.

Over the whole WLTC, on the conventional reference run, it gets 30.2 percent: on average 275 grams
per kilowatt-hour of shaft work over the cycle, against 232 at the star. The table splits the cycle
by engine power. Read the column for 1 kilowatt or less: four tenths of the time the engine idles or
barely pulls, and it burns only 6 percent of the fuel there. Read the column for 10 to 40 kilowatts:
two thirds of the fuel goes in there, on the band the CVT's pedal schedule sets. So, again: only a
third of all the fuel is burned within 10 grams per kilowatt-hour of the line. Light load is where
the engine does worst: the throttle is nearly closed, so the engine works hard to suck air past it,
and friction is a large share of a small output.

And the engine idles at every stop. The WLTC's Low phase is full of stops, and every second of idle
burns fuel with nothing to show for it.

So the room for improvement is the distance between the points and the star. A hybrid closes it.
-->

---
routeAlias: three-savings
---

## Three ways a hybrid saves fuel

<div class="grid grid-cols-3 gap-6">
<div>

### 1 · Move the point

Run the engine on its best-BSFC line for the power it gives, or not at all; let the battery
cover the gap.

Lecture 2's estimate: an ideal CVT that always holds the engine on that line, **4.93 L/100 km**,
against 5.22 for the hands-on CVT.

</div>
<div>

### 2 · Stop, don't idle

Switch the engine off at standstill and restart it on demand.

Stop/start alone: on average **3.5 %** less CO₂ on the WLTC (ICCT 2022).

</div>
<div>

### 3 · Bring the braking back

Brake with the machine and store the energy instead of heating the discs.

On the WLTC the braking energy at the wheels is **25–26 %** of the energy spent driving them.

</div>
</div>

<div class="handson">Each joule that goes through the battery loses a little in the machine, the
converter and the battery twice, once in and once out: the round trip. Saving 1 is worth it only
where the engine's loss is larger than that round trip; saving 3 always gains, since braking energy
otherwise all turns to heat.</div>

<!--
A hybrid goes after that gap in three ways.

One: move the operating point. For a given power at the wheels the engine can run at many
combinations of speed and torque. A hybrid picks the one on the best-BSFC line, and if even that is
poor, at very low power, it switches the engine off and drives on the battery; when the battery
runs low, it runs the engine a bit harder than the road asks and stores the difference. Lecture 2
already showed how much the line alone is worth. In its drive-cycles section it estimated an ideal
CVT that always holds the engine on that line: 4.93 liters per 100 kilometers. That estimate worked
backward from the speed trace to the engine. The hands-on CVT, which keeps the engine at 1800 rpm or
more, was simulated forward, with a driver, and ran 5.22. The two are different methods, so read
the gap as a size, not a precise number.

Two: stop, don't idle. Switch the engine off whenever the car stands, and restart it when the
driver lifts the brake. That is a micro hybrid. The ICCT, the International Council on Clean
Transportation, published a review of mild hybrids in 2022. It gives stop and start alone an
average of 3.5 percent less CO2 on the WLTC, and 7 percent on the older European test cycle, the
NEDC, which idles more.

Three: bring the braking back. Brake with the machine as a generator and store the energy. For the
course car on the WLTC, our research note works out that the energy taken out by braking at the
wheels is 25 to 26 percent of the energy spent driving them. Lecture 4's electric car got 24
percent back.

The green box is the catch. Every joule that goes into the battery and out again loses a little in
the machine, the converter and the battery, twice: once going in, once coming out. We call that the
round trip. So moving the operating point only pays where the engine's loss is larger than that
round trip. That is why the energy manager in section 06 does not simply
charge whenever it can.
-->

---
routeAlias: model-ladder
---

## Today's ladder

<div class="tight">

| Level | Model | What it adds | Built in |
|---|---|---|---|
| H0 | H1 with the hybrid machine removed: no torque, no losses, no inertia; K0 opens at stops, slips to start the car, and closes once it moves | the conventional car to compare against, on the same planar car, L/100 km on WLTC | reference |
| H1 | P2 powertrain | engine → K0 clutch → ≈ 30 kW machine → CVT → differential; ≈ 1.4 kWh battery | build 01 |
| H2 | H1 + operating line | the CVT ratio aims the engine at its best-BSFC line | build 02 |
| H3 | H2 + energy manager | driving modes that keep the battery's charge (SoC) in a window, without flickering on and off; regen as in Lecture 4 | build 03 |
| H4 | P0, P1, P3, P4 | the same parts at other places in the driveline | lecturer demo |

</div>

<div class="handson">Saving 2 comes with H1: K0 open, engine off. Saving 1 with H2. Saving 3 with
H3. H4 shows that where the machine sits decides how much of each a hybrid can get.</div>

<!--
Here is the ladder we climb today, one rung per build.

H0 is the conventional car we compare against, in liters per 100 kilometers on the WLTC. It is the
P2 car with the hybrid machine removed: no torque, no losses, no inertia, no auxiliaries. K0 works
like the clutch of a manual car, but on its own: it is open while the car stands, slips as the
engine revs up to start the car, and is closed while the car moves. So it is Lecture 2's engine and
CVT on the same planar car, driveline and mass as the hybrid, and the difference you measure is the
hybrid's alone. You do not build it; it is the reference run.

H1, build 01, is the P2 powertrain. Lecture 2's engine, then the K0 disconnect clutch, then Lecture
4's machine at about 30 kilowatts, then the CVT that the course already has, then the planar car's
differential to the front wheels. A battery of about 1.4 kilowatt-hours feeds the machine.

H2, build 02, commands the CVT ratio toward the engine's best-BSFC speed for the power it is asked
for. With no battery the engine still follows the driver's demand, so it only gets near the line:
build 02 measures how near.

H3, build 03, adds the energy manager: driving modes chosen by simple rules. State of charge, SoC
for short, is how full the battery is, from 0 for empty to 1 for full. The rules keep it inside a
window. They switch with hysteresis: a gap between the switch-on and switch-off thresholds, so the
modes do not flicker on and off. Braking is shared as in Lecture 4: the machine brakes first, the
friction brakes add the rest.

H4 is my part: the same parts moved to the other four positions, P0, P1, P3 and P4, and one table.

The green box ties the ladder to the three savings. Stopping the engine comes with H1, because the
clutch lets the engine stop while the car moves. Moving the operating point comes with H2. Bringing
braking back, under control, comes with H3. And H4 shows that the position of the machine decides
how much of each a hybrid can get at all.
-->

---

## Summary of section 01

- Lecture 2's engine: **232 g/kWh** at its best, **30.2 %** over the WLTC, two thirds of its fuel
  off the best-BSFC line, and idling at every stop.
- A hybrid saves fuel three ways: **move the operating point**, **stop instead of idling**,
  **bring the braking back**.
- Every joule through the battery loses a little on the way in and out; the energy manager
  decides when that is worth it.

### Next: how the engine and the machine are connected. <Link to="series-and-parallel">→ 02, series and parallel</Link>

<!--
Section 01 in three lines. Lecture 2's engine is 232 grams per kilowatt-hour at its best and 30.2
percent efficient over the WLTC, with two thirds of its fuel burned off the best-BSFC line, and it
idles at every stop. A hybrid
saves fuel three ways: by moving the operating point, by stopping instead of idling, and by bringing
the braking back. And every joule that goes through the battery pays the round trip, so something
has to decide when that is worth it; that is the energy manager of section 06.

Next: how the engine and the machine can be connected, series or parallel.
-->
