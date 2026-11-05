---
routeAlias: operating-point
layout: section
---

###### Section 05

# Moving the operating point

The best-BSFC line, the CVT that moves the engine toward it, the machine that shifts the load, and
the power-split hybrid that does it with a planetary gear.

`scripts/bsfc_line.jl` · <span class="todo">TODO: notebook file (#115)</span>

<!--
Section 05, moving the operating point. This is the first of the three savings from section 01, and
the one that explains most of a hybrid's gain when the engine runs. For each power the engine can
give, there is a best speed; the CVT can put it there; the machine can shift the engine's load up or
down; and the power-split hybrid, the Prius, does all of it with one planetary gear. You build the
operating line at the end, build 02. The figures come from the best-BSFC line script of issue 200
and the operating-points notebook of issue 115.
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

A power the car asks for is a hyperbola on the engine map: low speed and high torque, or high
speed and low torque.

Along each hyperbola the BSFC changes. The **best-BSFC line** joins, for every power, the point
where it is lowest.

Best point of Lecture 2's map: **232 g/kWh** at 3000 rpm, 99 N·m.

</div>
<div>

<img src="/figures/05-bsfc-line.svg" class="w-full" style="max-height: 26rem" alt="Lecture 2's BSFC map, brake torque against engine speed from 1000 to 6000 rpm, with BSFC contours from 235 to 500 g/kWh, the full-load curve, and dashed lines of constant power at 20, 40, 60 and 80 kW. The best-BSFC line runs from low speed and torque up through the minimum of 232 g/kWh at 3000 rpm, then follows the full-load curve to peak power."/>

</div>
</div>

<!--
The power at the engine's shaft is torque times speed. So a given power, say the power the car needs
to cruise through town, is a hyperbola on the map: the engine can give it at low speed
and high torque, or at high speed and low torque, and at everything in between.

Along each of those hyperbolas the BSFC changes. At high speed and low torque the throttle is nearly
closed and friction is large, so BSFC is high. At low speed and high torque the engine is better, up
to the full-load line. The best-BSFC line joins, for every power, the speed and torque where BSFC is
lowest. It starts near idle, runs up through the region of the best point, and ends at peak power.

The figure will show it over Lecture 2's map. Issue 200 computes the line from the course's own
engine maps and draws it; its acceptance check is that the line's minimum is the map's global
minimum, the best point you already know: 232 grams per kilowatt-hour at 3000 rpm and 99 newton
meters.

Note that the line is not the best point. The car asks for a power; the line says how to give that
power best. To run always at the best point you need a battery to absorb the difference, and that is
two slides on.
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

<div class="handson">A CVT has one degree of freedom: engine speed. Without a battery the engine's
power must still equal the road's.</div>

<!--
How does the car put the engine on the line? With the CVT, the free degree of freedom that settled
decision S2 of the plan chose it for.

Take the power the driver asks for. The best-BSFC line gives the engine speed for that power, omega
e star. The CVT's ratio is that speed divided by the speed of its output, which the wheels set. So
the energy manager commands the ratio, and the engine's torque follows from the power: the throttle
sets the torque, the ratio sets the speed, and the operating point is where the two meet.

It works only inside the CVT's ratio range. At launch the wheels barely turn and the ratio needed is
huge; at top speed it runs out the other way. There the engine leaves the line, and the checkpoint
of build 02 accepts that.

The table recalls Lecture 2's drive-cycles section. The same body and engine: an ideal CVT on the
minimum-fuel line, estimated backward from the trace, 4.93 liters per 100 kilometers. The hands-on
CVT, which held the engine at 1800 rpm or more and ran forward with a PID driver, 5.22. The two
methods differ, so read the gap, about three tenths of a liter, as an order of magnitude.

The last line under it is one point you can check by hand. At a steady 90 kilometers per hour the
car needs about 10 kilowatts. Lecture 2's CVT schedule gives them at 2182 rpm, where the engine burns
264 grams per kilowatt-hour; the best-BSFC line gives the same 10 kilowatts at 1420 rpm and 242 grams.
Same power, about 8 percent less fuel, just by choosing the speed. Even steady cruise is off the line.

The green box is the limit of this trick. A CVT gives one degree of freedom, the engine's speed. The
power still has to equal what the road asks, so at low power the engine still runs on a poor part of
the line. To do better you need to change the power too, and that needs a battery.
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

- **Raise the load**: the engine gives more than the road asks, the machine stores the rest.
  Low power moves up the line, to better BSFC.
- **Engine off**: below some power the machine drives alone.
- **Lower the load**: the machine boosts, the engine stays on the line at its upper end.

</div>
<div>

<div class="placeholder">

**Figure: `05-operating-points.svg`**

Lecture 2's BSFC map with the WLTC operating points of the conventional car and of the P2 hybrid,
side by side or overlaid; the hybrid's points gathered along the line, with fewer at low load.

Produced by the operating-points notebook, #115

</div>

</div>
</div>

<!--
Now add the machine and the battery. The engine's power no longer has to equal the road's: it is
the requested power plus whatever the machine generates. That is the second degree of freedom.

Three ways to use it. Raise the load: at low power, where even the line is poor, run the engine
harder than the road asks and let the machine store the difference in the battery. The operating
point moves up the line, to a better BSFC. Engine off: below some power, drive on the machine alone
and spend the stored energy. Lower the load: when the driver asks for more than the line's upper
end, let the machine boost, so the engine stays on its line instead of going to full load.

Together they gather the engine's points where it is efficient and empty the poor region at low
load. The figure, from the operating-points notebook of issue 115, will show exactly that: the
conventional car's WLTC points spread over the lower map, the hybrid's gathered along the line.

Remember the catch of section 01: each joule stored to run the engine better later pays the round
trip through the battery twice. Raising the load pays only where the engine's gain is larger than
that.
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

Engine on the carrier, **MG1** on the sun, **MG2** and the wheels on the ring.

MG1's speed sets the engine's speed at any wheel speed: a CVT without a belt. Part of the engine's
power goes to the ring mechanically, part through MG1 and MG2 electrically.

The Toyota Prius's hybrid system.

</div>
</div>

<!--
There is a hybrid that does all of this with no CVT at all: the power-split hybrid, best known as
the Toyota Prius. A picture only; we do not build it.

The heart is one planetary gear. The engine drives the carrier. The sun gear drives the first
machine, MG1. The ring gear drives the final drive and the wheels, and the second machine, MG2, sits
on the same shaft. The two machines are joined electrically through their inverters and the
battery.

The equation is the planetary gear's speed relation, the Willis equation: one plus k times the
carrier speed equals the sun speed plus k times the ring speed, where k is the ring's tooth count
over the sun's. Two of the three speeds are free, the third follows. The ring is tied to the
wheels. So by setting MG1's speed, the energy manager sets the engine's speed at any wheel speed:
an electric CVT, with no belt.

The power splits. The planetary gear divides the engine's torque in fixed proportions between the
sun and the ring. The ring's share goes to the wheels mechanically. The sun's share turns MG1 as a
generator, and its electricity drives MG2, back onto the ring, or charges the battery. So it is
partly a parallel and partly a series hybrid, at every moment.

That is why it is called power split, and why it can hold the engine on its best-BSFC line without
a transmission. The price is that some of the power is always converted twice.
-->

---
routeAlias: build-operating-line
---

## Build 02: the operating line

<div class="grid grid-cols-[1.1fr_1fr] gap-8 items-start">
<div>

<div class="placeholder">

**Screenshot: `step02-operating-line.png`**

The P2 powertrain with the operating-line table between the requested power and the CVT's ratio
command.

Captured with the build guide, #112

</div>

**Given:** the best-BSFC line as a data table (#200)

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

<div class="handson">✓ same car, driver and K0 as H0 · WLTC: <b>5.39</b> L/100 km against H0's
<b>5.71</b>, <b>−5.5 %</b> · only 15 % of the fuel within ±150 rpm of the line</div>

</div>
</div>

<!--
Build 02: the operating line. The screenshot will show your P2 powertrain with the line between the
requested power and the CVT; it is captured with the build guide, issue 112.

The library gives you the best-BSFC line as a data table. The powertrain gets a switch,
speed_commanded, that swaps the pedal-scheduled CVT for one that holds a commanded engine speed.
The driver's pedal becomes a power request, pedal times 85 kilowatts; the line turns that power
into a speed, floored at 1000 revolutions per minute so the locked engine never drops below idle;
the CVT holds that speed. Everything else is H0: the same car, driver, brakes and K0.

The checkpoint: over the WLTC the car burns 5.39 liters per 100 kilometers, against H0's 5.71.
That is 5.5 percent, with no electric machine at all, from moving the engine to lower speed and
higher load.

But be honest about why. The request is open loop: pedal times 85 kilowatts is not what the engine
actually delivers, so the engine does not sit on the line. Only 15 percent of the fuel burns within
150 revolutions per minute of it. The saving comes from running slower in general. Holding the
engine on the line needs a controller that commands engine power directly: the energy manager of
section 06.
-->

---

## Summary of section 05

- For each power there is a best speed: the **best-BSFC line**.
- The **CVT** puts the engine on it by commanding the ratio; inside its range only.
- The **machine** shifts the load: raise it and store, switch the engine off, or boost.
- A **power split** does both with one planetary gear: MG1 sets the engine's speed.

### Next: who decides. <Link to="energy-management">→ 06, energy management</Link>

<!--
Section 05 in four lines. For each power the engine gives, there is a best speed; joined up, that is
the best-BSFC line. The CVT puts the engine on it by commanding the ratio, inside its ratio range.
The machine shifts the load: it raises it and stores the surplus, lets the engine stop, or boosts. And
the power-split hybrid does both with one planetary gear, MG1 setting the engine's speed.

Next: somebody has to decide which of these to do at every moment. That is the energy manager.
-->
