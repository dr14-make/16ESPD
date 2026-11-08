---
routeAlias: operating-point
layout: section
---

###### Section 05

# Moving the operating point

The best-BSFC line, the CVT that moves the engine toward it, the machine that shifts the load, and
the power-split hybrid that does it with a planetary gear.

`scripts/bsfc_line.jl` · `notebooks/lecture05/01-operating-points.pluto.jl`

<!--
Section 05: moving the operating point, which is the engine's speed and torque. This is the first
of the three savings from section 01, and it explains most of a hybrid's gain while the engine
runs. For each power the engine can give, there is a best speed. The CVT can put the engine there.
The machine can shift the engine's load up or down. And the power-split hybrid, the Prius, does all
of that with one planetary gear. At the end you build the operating line, build 02. The figures
are computed from Lecture 2's engine map, and the operating-points notebook.
-->

---
routeAlias: best-bsfc-line
---

## One power, many operating points

<div class="grid grid-cols-[1fr_2fr] gap-6 items-center">
<div>

$$
P = T\,\omega
$$

<div class="caption text-left"><i>P</i>: power, W · <i>T</i>: torque, N·m · ω: engine speed,
rad/s</div>

A power the car asks for is a curve on the engine map: low speed and high torque, or high speed
and low torque.

Along each curve the BSFC, grams of fuel per kWh, changes. The **best-BSFC line** joins, for every
power, the point where it is lowest.

Best point of Lecture 2's map: **232 g/kWh** at 3000 rpm, 99 N·m.

</div>
<div>

<img src="/figures/05-bsfc-line.svg" class="w-full" style="max-height: 26rem" alt="Lecture 2's BSFC map, brake torque against engine speed from 1000 to 6000 rpm, with BSFC contours from 235 to 500 g/kWh, the full-load curve, and dashed lines of constant power at 20, 40, 60 and 80 kW. The best-BSFC line runs from low speed and torque up through the minimum of 232 g/kWh at 3000 rpm, then follows the full-load curve to peak power."/>

<div class="caption">Thin black rings: equal BSFC, g/kWh · gray dashed: equal power · blue: the best-BSFC
line, the cheapest way to make each power</div>

</div>
</div>

<!--
The power at the engine's shaft is torque times speed. P is the power in watts, T is the torque in
newton meters, and omega is the engine's speed in radians per second. So a given power, say the
power the car needs to cruise through town, is a curve on the map, a hyperbola. The engine can give
that power at low speed and high torque, or at high speed and low torque, or anywhere in between.

Along each of those curves the BSFC changes. At high speed and low torque, the throttle is nearly
closed and friction is large, so BSFC is high. At low speed and high torque the engine does better,
up to the full-load line. The best-BSFC line joins, for every power, the speed and torque where
BSFC is lowest. It starts near idle, runs up through the region of the best point, and ends at peak
power.

The figure shows the line over Lecture 2's map, the same map as in section 01. Across is the engine
speed in rpm, and up is the torque in newton meters. The thick black curve is full load. The thin
black rings are lines of equal BSFC, in grams per kilowatt-hour. The dashed gray curves are lines of
equal power, 20, 40, 60 and 80 kilowatts; those are the curves I just described. The blue line is
the best-BSFC line. Take one dashed curve and slide along it: the point where it touches the lowest
ring lies on the blue line. We compute the line from the engine maps. It passes through the map's
overall minimum, the best point you already know: 232 grams per kilowatt-hour at 3000 rpm and 99
newton meters.

Note that the line is not the best point. The car asks for a power, and the line says how to give
that power best. To run always at the best point, you need a battery to absorb the difference, and
that comes two slides from now.
-->

---
routeAlias: cvt-on-the-line
---

## The CVT moves the engine toward the line

<div class="grid grid-cols-[1fr_1fr] gap-8 items-start">
<div>

For the power the driver asks for:

$$
\omega_e^{*} = \omega_{\text{line}}(P_{req})
\qquad
i_{CVT} = \frac{\omega_e^{*}}{\omega_{\text{in,wheels}}}
$$

<div class="caption text-left">ω<sub>e</sub><sup>*</sup>: the engine speed we want ·
ω<sub>line</sub>(<i>P</i><sub>req</sub>): the line's speed for the power the driver asks for ·
<i>i</i><sub>CVT</sub>: the CVT's ratio · ω<sub>in,wheels</sub>: the CVT's output speed, set by the
wheels</div>

The engine's throttle sets the torque, the CVT's ratio the speed: the operating point is where the
two meet.

Inside the ratio range only. At launch and at top speed the ratio limits, and the engine leaves the
line.

</div>
<div>

**Lecture 2, the same body and engine**

<div class="tight">

| Driveline | L/100 km |
|---|---:|
| ideal CVT, minimum-fuel line (backward) | 4.93 |
| hands-on CVT, ≥ 1800 rpm (forward) | 5.22 |

</div>

The line alone, without a battery: **≈ 0.3 L/100 km** on this car, as an order of magnitude.

Even steady cruise is off the line: at 90 km/h Lecture 2's CVT schedule runs the engine at 10.0 kW,
2182 rpm, **264 g/kWh**; the line gives 10 kW at 1420 rpm, **242 g/kWh**: about **8 % less fuel**.

</div>
</div>

<div class="handson">A CVT gives one free choice: engine speed. Without a battery the engine's
power must still equal the road's.</div>

<!--
How does the car put the engine on the line? With the CVT. Its ratio is the free choice that lets
us pick the engine's speed for a given wheel speed.

Read the two formulas from left to right. Take the power the driver asks for, P req. The best-BSFC
line gives the engine speed for that power; we call the speed we want omega e star. The CVT's ratio,
i CVT, is that speed divided by the speed of the CVT's output, which the wheels set. So the energy
manager commands the ratio, and the engine's torque follows from the power. The throttle sets the
torque, the ratio sets the speed, and the operating point is where the two meet.

This works only inside the CVT's ratio range. At launch the wheels barely turn, and the ratio
needed is huge; at top speed it runs out the other way. There the engine leaves the line, and the
checkpoint of build 02 accepts that.

The table recalls Lecture 2's drive-cycles section, with the same body and engine. An ideal CVT on
the minimum-fuel line, estimated backward from the speed trace to the engine, gave 4.93 liters per
100 kilometers. The hands-on CVT, which held the engine at 1800 rpm or more, was simulated forward
with a driver model that works the pedal, and it gave 5.22. The two methods differ, so read the
gap, about three tenths of a liter, as an order of magnitude.

The last lines in the right column are one point you can check by hand. At a steady 90 kilometers
per hour, the car needs about 10 kilowatts. Lecture 2's CVT schedule gives them at 2182 rpm, where
the engine burns 264 grams per kilowatt-hour. The best-BSFC line gives the same 10 kilowatts at 1420
rpm and 242 grams. Same power, about 8 percent less fuel, just by choosing the speed. So even steady
cruise is off the line.

The green box is the limit of this trick. A CVT gives one free choice: the engine's speed. The power
still has to equal what the road asks for, so at low power the engine still runs on a poor part of
the line. To do better, you have to change the power too, and that needs a battery.
-->

---
routeAlias: load-point-shifting
---

## With a machine: shift the load

<div class="grid grid-cols-[1fr_1.3fr] gap-8 items-center">
<div>

$$
P_{ICE} = P_{req} + P_{gen}
$$

<div class="caption text-left">All in kW · <i>P</i><sub>ICE</sub>: engine power ·
<i>P</i><sub>req</sub>: power the road asks for · <i>P</i><sub>gen</sub>: power the machine
generates into the battery, below zero when it boosts</div>

- **Raise the load**: the engine gives more than the road asks, the machine stores the rest.
  Low power moves up the line, to better BSFC.
- **Engine off**: below some power the machine drives alone.
- **Lower the load**: the machine boosts, the engine stays on the line at its upper end.

</div>
<div>

<img src="/figures/05-operating-points.svg" class="w-full" style="max-height: 24rem" alt="Lecture 2's BSFC map with the WLTC operating points of the conventional car in red and the P2 hybrid in green, as bubbles sized by the fuel burned there on one scale. The conventional car's fuel lies on a diagonal band from about 2300 rpm at 10 N·m to 3600 rpm at 110 N·m, in the 250 to 350 g/kWh region. The hybrid's fuel gathers along the best-BSFC line between 1500 and 3000 rpm, its largest bubble at the map's 232 g/kWh minimum, and the low-load region below 40 N·m is nearly empty."/>

<div class="caption">Red: conventional · green: P2 hybrid · bubble size: fuel burned there. The
hybrid's fuel moves onto the blue line and leaves the low-torque corner.</div>

</div>
</div>

<!--
Now we add the machine and the battery. The engine's power no longer has to equal the road's. The
formula says it: the engine's power, P ICE, is the power the road asks for, P req, plus the power
the machine generates into the battery, P gen, all in kilowatts. When the machine boosts, P gen is
below zero. That is our second free choice.

There are three ways to use it. Raise the load: at low power, where even the line is poor, run the
engine harder than the road asks, and let the machine store the difference in the battery. The
operating point moves up the line, to a better BSFC. Engine off: below some power, drive on the
machine alone and spend the stored energy. Lower the load: when the driver asks for more than the
line's upper end, let the machine boost, so that the engine stays on its line instead of going to
full load.

Together, these gather the engine's points where it is efficient, and empty the poor region at low
load. The figure, from the operating-points notebook, shows exactly that. It is the same fuel map:
speed across, torque up, thin black rings of equal BSFC, and the blue best-BSFC line. Now there are
two sets of bubbles, and a bigger bubble means more fuel burned there. Red is the conventional car:
its WLTC fuel sits on its diagonal band, in the region of 250 to 350 grams. Green is the P2 hybrid:
its fuel gathers along the blue line, most of it near the map's best point, and the low-torque
corner is nearly empty. That is the take-away: the hybrid burns its fuel where the engine is
efficient.

Remember the catch from section 01. Each joule stored now to run the engine better later pays the
round trip through the battery, in and out. So raising the load pays only where the engine's gain
is larger than that loss.
-->

---
routeAlias: power-split
---

## The power-split hybrid: an electric CVT

<div class="grid grid-cols-[1.35fr_1fr] gap-6 items-center">
<div class="diagram-wide">

![A power-split hybrid. The engine drives the carrier of a planetary gear. The sun gear drives MG1, which sets the engine's speed. The ring gear drives the final drive and the wheels, with MG2 on the same shaft. MG1 and MG2 are joined electrically through their inverters and the battery.](/diagrams/05-power-split.svg)

</div>
<div class="text-[0.95rem]">

$$
(1 + k)\,\omega_c = \omega_s + k\,\omega_r
\qquad
k = \frac{z_r}{z_s}
$$

<div class="caption text-left">ω: speed of the carrier (c), sun (s) and ring (r) · <i>z</i>: number
of teeth · MG: motor-generator</div>

Engine on the carrier, **MG1** on the sun, **MG2** and the wheels on the ring.

MG1's speed sets the engine's speed at any wheel speed: a CVT without a belt. Part of the engine's
power goes to the ring mechanically, part through MG1 and MG2 electrically.

The Toyota Prius's hybrid system.

</div>
</div>

<!--
There is a hybrid that does all of this with no CVT at all: the power-split hybrid, best known from
the Toyota Prius. This is a picture only; we do not build it.

Its heart is one planetary gear. There is a sun gear in the middle, small planet gears around it
held by a carrier, and a ring gear around them all, with its teeth on the inside. In the drawing,
the thick black lines are shafts and the thin orange lines are electrical; the carrier's arms are
drawn in orange too. The engine drives the carrier. The sun gear drives the first motor-generator,
MG1. The ring gear drives the final drive and the wheels, and the second motor-generator, MG2, sits
on the same shaft. The two machines are joined electrically through their inverters, the
electronics that drive them, and through the battery.

The equation is the planetary gear's speed rule. Omega is a speed: c for the carrier, s for the
sun, r for the ring. In words: one plus k, times the carrier speed, equals the sun speed plus k
times the ring speed. And k is the number of teeth on the ring, z r, divided by the number on the
sun, z s. Two of the three speeds are free, and the third follows. The ring is tied to the wheels.
So by setting MG1's speed, the energy manager sets the engine's speed at any wheel speed. It is an
electric CVT, with no belt.

The power splits. The planetary gear divides the engine's torque in fixed proportions between the
sun and the ring. The ring's share goes to the wheels mechanically. The sun's share turns MG1 as a
generator, and that electricity drives MG2, back onto the ring, or charges the battery. So at every
moment it is partly a parallel and partly a series hybrid.

That is why it is called power split, and why it can hold the engine on its best-BSFC line without
a transmission. The price is that some of the power is always converted twice.
-->

---
routeAlias: build-operating-line
---

## Build 02: the operating line

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-start">
<div>

![P2OperatingLineWLTC in Studio: driver, operating-line table and P2 powertrain on top, the planar car, differential and road load below, the fuel meter on the right.](/img/lecture-05/step02-operating-line-diagram.png)

**Given:** the best-BSFC line as a data table (`OperatingLine`)

[page: step 2](../lecture/lecture-05/#step-2) · reference `dyad/HandsOn05/P2OperatingLineWLTC.dyad`

</div>
<div class="stack">

*Pedal → requested power → best-BSFC line → engine speed command, floored at 1000 rpm → the CVT
sets the ratio that holds it*

```txt
line.P = powertrain.engine_pedal * P_peak   # P_peak = 85 kW, a calibration
N_target = max(line.N, N_locked)            # 1000 rpm
powertrain.N_ref = N_target
```

<div class="handson">✓ same car, driver and K0 as H0 · WLTC: <b>5.44</b> L/100 km against H0's
<b>5.72</b>, <b>−4.9 %</b> · only 17 % of the fuel within ±150 rpm of the line</div>

<img src="/img/lecture-05/step02-operating-points.png" style="max-height: 13rem" alt="The operating-line WLTC run: engine torque against engine speed, the WLTC points as black dots and the best-BSFC line in orange. The points form a cloud around and below the line, densest on a band below it, not on the line itself." />

<div class="caption">Black: the engine's WLTC points · orange: the best-BSFC line. The pedal's power
request is never checked against the engine, so most points fall on a band below the line.</div>

</div>
</div>

<!--
Build 02: the operating line. On the left you see the operating-line test model in Studio. The
line's table sits between the driver and the powertrain.

The library gives you the best-BSFC line as a data table, called OperatingLine. The powertrain gets
a switch that swaps the CVT that follows the pedal for one that holds an engine speed we command.
Now read the three code lines. First: the driver's pedal becomes a power request, the pedal position
times 85 kilowatts, a value we chose. Second: the line turns that power into a speed, and we never
go below 1000 revolutions per minute, so the engine never drops below idle while K0 is locked.
Third: the CVT holds that speed. Everything else is the same as H0: the same car, driver, brakes and
K0.

The checkpoint: over the WLTC the car burns 5.44 liters per 100 kilometers, against H0's 5.72. That
is 4.9 percent less, with no electric machine at all, just from moving the engine to lower speed
and higher load.

But be honest about why. Nothing checks the request against the engine. Pedal times 85 kilowatts is
not what the engine actually delivers, so the engine does not sit on the line. The plot under the
checkpoint shows this. The black dots are the engine's points over the WLTC, and the orange curve is
the best-BSFC line. The dots are densest on a band below the line, not on it. Only 17 percent of the fuel
burns within 150 revolutions per minute of the line. The saving comes from running slower in
general. Holding the engine on the line needs a controller that commands the engine's power
directly: that is the energy manager of section 06.
-->

---

## Summary of section 05

- For each power there is a best speed: the **best-BSFC line**.
- The **CVT** puts the engine on it by commanding the ratio; inside its range only.
- The **machine** shifts the load: raise it and store, switch the engine off, or boost.
- A **power split** does both with one planetary gear: motor-generator MG1 sets the engine's
  speed.

### Next: who decides. <Link to="energy-management">→ 06, energy management</Link>

<!--
Section 05 in four lines. For each power the engine gives, there is a best speed; joined up, those
speeds form the best-BSFC line. The CVT puts the engine on that line by commanding the ratio, inside
its ratio range. The machine shifts the load: it raises the load and stores the surplus, it lets
the engine stop, or it boosts. And the power-split hybrid does both with one planetary gear, with
MG1 setting the engine's speed.

Next: somebody has to decide which of these to do at every moment. That is the energy manager.
-->
