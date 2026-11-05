---
routeAlias: why-hybridize
layout: section
---

###### Section 01

# Why hybridize

Where Lecture 2's engine spends the WLTC on its fuel map, and the three ways a hybrid saves fuel.

<span class="todo">TODO: notebook file (#115)</span>

<!--
Section 01, why hybridize. Before we add a single part, we look at where Lecture 2's engine spends
the WLTC on its own fuel map, and see that it spends most of it far from where it is efficient.
That gap is what a hybrid goes after, in three ways. The figure comes from the operating-points
notebook, still to be written under issue 115.
-->

---
routeAlias: wltc-on-the-bsfc-map
---

## Where Lecture 2's engine spends the WLTC

<div class="grid grid-cols-[1.4fr_1fr] gap-8 items-center">
<div>

<img src="/figures/05-operating-points-conventional.svg" class="w-full" style="max-height: 24rem" alt="Lecture 2's BSFC map with the conventional car's WLTC operating points as bubbles sized by the fuel burned there. Nearly all the fuel lies on one diagonal band from about 2300 rpm at 10 N·m to 3600 rpm at 110 N·m, set by the CVT's pedal schedule, at higher speed and lower torque than the best-BSFC line, in the 250 to 350 g/kWh region."/>

</div>
<div>

**At its best**: 35.7 % brake efficiency, **232 g/kWh**, at 3000 rpm and 99 N·m.

**Over the WLTC**: 30.2 % of the fuel's energy reaches the crank as work, a cycle BSFC of
**275 g/kWh**. Only a third of the fuel burns within 10 g/kWh of the best-BSFC line.

| Engine power | ≤ 1 kW | 1–10 kW | 10–40 kW | > 40 kW |
|---|---:|---:|---:|---:|
| share of time | 42.6 % | 28.7 % | 28.5 % | 0.2 % |
| share of fuel | 5.9 % | 26.2 % | 66.7 % | 1.2 % |

**At every stop**: idling, burning fuel for no work at all.

</div>
</div>

<!--
The figure is Lecture 2's fuel map, brake-specific fuel consumption over engine speed and torque,
with every point the conventional car visits on the WLTC on top, each bubble sized by the fuel
burned there. Nearly all of it lies on one diagonal band that the CVT's pedal schedule sets, from
about 2300 rpm at light load to 3600 rpm at 110 newton meters: faster and lighter-loaded than the
best-BSFC line, in the 250 to 350 gram region. Only a third of the fuel is burned within 10 grams
per kilowatt-hour of the line. That gap is what the operating line and the hybrid recover.

The right column has the numbers that figure will show. At its best point the engine turns 35.7
percent of the fuel's energy into shaft work: 232 grams of petrol per kilowatt-hour, at 3000 rpm and
99 newton meters. That is the star on Lecture 2's efficiency map, in the engine-and-cycles section of
that deck.

Over the whole WLTC, on the conventional reference run, it gets 30.2 percent: 275 grams per
kilowatt-hour of crank work over the cycle, against 232 at the star. The table splits the cycle by
engine power. Four tenths of the time the engine idles or barely pulls, and burns only 6 percent of
the fuel there. Two thirds of the fuel goes in at 10 to 40 kilowatts, on the band the CVT's pedal
schedule sets, faster and lighter-loaded than the best-BSFC line. Only a third of all the fuel is
burned within 10 grams per kilowatt-hour of that line. Light load is where the engine does worst:
a nearly closed throttle to pump against, and friction that is a large share of a small output.

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

Lecture 2's backward estimate: an ideal CVT on the minimum-fuel line, **4.93 L/100 km**, against
5.22 for the hands-on CVT.

</div>
<div>

### 2 · Stop, don't idle

Switch the engine off at standstill and restart it on demand.

Stop/start alone: on average **3.5 %** less CO₂ on the WLTC (ICCT 2022).

</div>
<div>

### 3 · Bring the braking back

Brake with the machine and store the energy instead of heating the discs.

On the WLTC the braking at the wheel is **25–26 %** of the positive traction energy.

</div>
</div>

<div class="handson">Each joule that goes through the battery pays the machine, the converter and
the battery twice, once in and once out. Saving 1 is worth it only where the engine's loss is larger
than that round trip; saving 3 always gains, since braking energy otherwise all turns to heat.</div>

<!--
A hybrid goes after that gap in three ways.

One: move the operating point. For a given power at the wheels the engine can run at many
combinations of speed and torque. A hybrid picks the one on the best-BSFC line, and if even that is
poor, at very low power, it switches the engine off and drives on the battery; when the battery
runs low, it runs the engine a bit harder than the road asks and stores the difference. Lecture 2
already showed how much the line alone is worth. Its backward estimate, in the drive-cycles section,
put an ideal CVT on the minimum-fuel line at 4.93 liters per 100 kilometers; the hands-on CVT,
which keeps the engine at 1800 rpm or more, ran 5.22 forward. The two are different methods, so read
the gap as a size, not a precise number.

Two: stop, don't idle. Switch the engine off whenever the car stands, and restart it when the
driver lifts the brake. That is a micro hybrid. The ICCT's 2022 review of mild hybrids gives stop and
start alone an average of 3.5 percent less CO2 on the WLTC, and 7 percent on the older NEDC, which
idles more.

Three: bring the braking back. Brake with the machine as a generator and store the energy. The
research note derives that on the WLTC, for the course car, the braking energy at the wheel is 25
to 26 percent of the positive traction energy. Lecture 4's electric car got 24 percent back.

The green box is the catch. Every joule that goes into the battery and out again pays the machine,
the converter and the battery twice. So moving the operating point only pays where the engine's
loss is larger than that round trip. That is why the energy manager in section 06 does not simply
charge whenever it can.
-->

---
routeAlias: model-ladder
---

## Today's ladder

<div class="tight">

| Level | Model | What it adds | Built in |
|---|---|---|---|
| H0 | H1 with K0 closed, the hybrid machine removed: no torque, no losses, no inertia | the conventional baseline on the same planar car, L/100 km on WLTC | reference |
| H1 | P2 powertrain | engine → K0 clutch → ≈ 30 kW machine → CVT → differential; ≈ 1.4 kWh battery | build 01 |
| H2 | H1 + operating line | the CVT ratio holds the engine on its best-BSFC line | build 02 |
| H3 | H2 + energy manager | modes inside an SoC window, with hysteresis; regen through Lecture 4's blending | build 03 |
| H4 | P0, P1, P3, P4 | the same parts on other flanges | lecturer demo |

</div>

<div class="handson">Saving 2 comes with H1: K0 open, engine off. Saving 1 with H2. Saving 3 with
H3. H4 shows that where the machine sits decides how much of each a hybrid can get.</div>

<!--
Here is the ladder we climb today, one rung per build.

H0 is the conventional baseline, in liters per 100 kilometers on the WLTC. It is the P2 car with the
clutch closed and the hybrid machine removed: no torque, no losses, no inertia, no auxiliaries: Lecture 2's engine and CVT on the same planar car,
driveline and mass as the hybrid, so the difference you measure is the hybrid's alone. You do not
build it; it is the reference run.

H1, build 01, is the P2 powertrain. Lecture 2's engine, then the K0 disconnect clutch, then Lecture
4's machine at about 30 kilowatts, then the CVT that the course already has, then the planar car's
differential to the front wheels. A battery of about 1.4 kilowatt-hours feeds the machine.

H2, build 02, commands the CVT ratio so that the engine sits on its best-BSFC line for the power it
is asked for.

H3, build 03, adds the energy manager: rule-based modes inside a window of state of charge, switched
with hysteresis so they do not chatter. Braking goes through Lecture 4's regen blending.

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
- Every joule through the battery pays the round trip; the energy manager decides when it is
  worth it.

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
