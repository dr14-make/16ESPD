---
routeAlias: operating-point
layout: section
---

###### Section 05

# Moving the operating point

The best-BSFC line, the CVT that holds the engine on it, the machine that shifts the load, and
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

## The CVT holds the engine on the line

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

<span class="todo">TODO: guide link · reference `dyad/HandsOn05/…`</span>

</div>
<div class="stack">

*Requested power → best-BSFC line → engine speed command → divided by the CVT's input speed from
the wheels → CVT ratio command; the engine's torque from the power*

```julia
# TODO: snippet from the build guide (#112)
```

<div class="handson">✓ over the WLTC, the engine's operating points sit on the best-BSFC line of
Lecture 2's map, within <span class="todo">TODO band</span> · L/100 km, engine only, on the line:
<span class="todo">TODO</span></div>

</div>
</div>

<!--
Build 02: the operating line. The screenshot will show your P2 powertrain with the line between the
requested power and the CVT; it is captured with the build guide, issue 112.

The library gives you the best-BSFC line as a data table, from issue 200. You read the requested
power from the driver, look up the engine speed on the line, divide by the CVT's input speed as the
wheels set it, and command that ratio, clipped to the CVT's range. The engine's torque follows from
the power.

The checkpoint, from the plan: over the WLTC, the engine's operating points sit on the best-BSFC line
of Lecture 2's map, within a band the reference model fixes. That band, and the fuel figure of the
engine alone on the line, are TODO until the reference model of issue 112 runs.

Compare that fuel figure with Lecture 2's 5.22 and its 4.93 estimate. It is the first of the three
savings, alone.
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
