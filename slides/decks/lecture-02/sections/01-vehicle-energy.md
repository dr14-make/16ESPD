---
routeAlias: vehicle-energy
layout: section
---

###### Section 01

# Vehicle energy

Before the engine: what it has to supply. Drag, rolling, slope, acceleration and the auxiliaries.

<!--
Every gram of fuel the engine burns ends up in one of five places. This section names them. You met
three of them in the hands-on as forces in the body: drag, rolling resistance and the grade. Here we
add acceleration and the electrical consumers, and look at them as energy.
-->

---
routeAlias: energy-used
---

## Energy used by a vehicle

<div class="grid grid-cols-[1.5fr_1fr] gap-6">
<div>

The energy consumption models are developed from the first principles of mechanics and the
vehicle parameters.

$$
O_{\text{total}} \;=\; \frac{O_F + O_V + O_S + O_Z}{\eta} \;+\; O_{\text{aux}}
$$

<div class="text-sm">

| Term | Resistance | |
|---|---|---|
| $O_V$ | drag | $O_V = \tfrac{1}{2}\,\rho\, c_x\, S_x\,(v - v_{\text{wind}})^2$ |
| $O_F$ | friction (rolling) | $O_F = m\, g\, f_k \cos\alpha$ |
| $O_Z$ | acceleration | $O_Z = m\, a\, v$ |
| $O_S$ | overcoming a slope | $O_S = m\, g\, v \sin\alpha$ |
| $O_{\text{aux}}$ | all other electrical equipment | $O_{\text{aux}} = O_{\text{AC}} + O_{\text{battery}} + O_{\text{light}} + O_{\text{audio}}$ |

</div>
</div>
<div>

![A car moving right with its forces as arrows: weight m·g down from the center of gravity, reaction forces N₁ and N₂ up at the wheels, rolling resistance O_F backward at both contact patches, the driving force F_t forward at the driven front wheel, and air resistance O_V backward on the front.](/diagrams/01-vehicle-forces.svg)

> **Units**
>
> $O_V$ and $O_F$ are forces. $O_Z$ and $O_S$ already carry the factor $v$, so they are powers.
> Multiply the first two by $v$ before adding.

</div>
</div>

<!--
The four mechanical terms share one efficiency, eta, from the fuel to
the wheel. The auxiliaries do not go through the driveline, so they are added after the division.

Drag grows with the square of the speed relative to the air, so a headwind counts. c x is the drag
coefficient, S x the frontal area; in Lecture 1 you had them as C d and A. Rolling resistance is
the weight times the coefficient f k, times cos alpha on a slope. Slope and acceleration are the two
terms that can be negative: downhill and braking give energy back, if the car can store it.

One thing to watch: as written, the drag and rolling terms are forces, and the acceleration and
slope terms are powers, because they carry the speed v. To add them, multiply the first two by v.
That gives power at the wheels; integrate over a drive cycle and you have energy.

The auxiliaries: air conditioning (AC), battery management, lights, audio. On a modern car they are several
hundred watts, more with the air conditioning on.

The force sketch is redrawn from the source deck's clip art with the table's symbols on the arrows:
the rolling term O F at the contact patches, drag O V on the front.

Notebook 01, "Where the energy goes", will drive these terms over a WLTC cycle and show which one
dominates in town and on the motorway.
-->

---
routeAlias: rolling-resistance
---

## Rolling resistance coefficient

<div class="grid grid-cols-[1.15fr_1fr] gap-4 items-center">
<div>

<CardExport notebook="illustrations" name="rolling-vs-speed" height="25rem" />

</div>
<div>

<CardExport notebook="01-energy" name="rolling-table" height="27rem" />

</div>
</div>

<div class="caption">Left: the engineeringtoolbox.com fit for car tires, f = 0.005 + (0.01 + 0.0095 (v/100)²) / p, p in bar, v in km/h</div>

<!--
The coefficient f k from the previous slide. Left: it rises with speed, and it rises a lot when the
tire is underinflated. At 1 bar it is twice what it is at 3.

Right: by surface. An ordinary car tire on asphalt or concrete is 0.01 to 0.015. In Lecture 1 the
car had 0.012, right in that band. Gravel doubles it, loose sand multiplies it by more than ten.

The table is notebook 01's, read from its coefficient file, with the row that holds Lecture 1's
0.012 highlighted. The curves on the left are drawn from the empirical fit behind the engineeringtoolbox.com
chart the source deck carried, not from measurements: an idealized characteristic, valid from
about 10 to 140 kilometers per hour. Once the drive-cycle model lands, the notebook sweeps the road surface over it.
-->

---
routeAlias: drag-and-rolling
class: big-figure
---

## Drag against rolling resistance

<div class="grid grid-cols-[1.6fr_1fr] gap-6 items-center">
<div>

<CardExport notebook="01-energy" name="drag-and-rolling" height="27rem" />

</div>
<div>

$$
O_V = \tfrac{1}{2}\,\rho\, c_x\, S_x\,(v - v_{\text{wind}})^2
$$

$$
O_F = m\, g\, f_k
$$

For Lecture 1's car, below **20.9 m/s** (75 km/h) rolling resistance is the larger force. Above
it, drag takes over; at 130 km/h it is **3.0×** the rolling resistance.

</div>
</div>

<!--
The two forces on one axis, on a flat road, so cos alpha is one.

This is Lecture 1's car: 1400 kilograms, f k of 0.012, C d A of 0.63 square meters, air at 1.2
kilograms per cubic meter. Rolling resistance is 165 newtons and flat, because the model takes f k
as a constant; on a real tire it creeps up with speed, as the previous slide showed. Drag starts at
zero and grows with the square. They cross at 20.9 meters per second, 75 kilometers per hour. At
130 drag is three times the rolling resistance. So in town both matter; on the motorway drag
dominates. That is why a car's fuel consumption climbs so steeply above 100 kilometers per hour.

The source slide's plot crossed near 8 meters per second, for a vehicle it does not name.

The source slide writes the rolling term as m times f k, without g. It needs g to be a force, as on
the previous slide.

The plot is notebook 01's, computed from the parameters of Vehicle Body. Once the drive-cycle
model lands it reads the road-load meter instead.
-->

---

## Summary of section 01

- The engine's work goes into drag, rolling resistance, slope and acceleration, divided by the
  driveline efficiency, plus the electrical auxiliaries.
- Rolling resistance depends on the surface and the tire pressure, and rises with speed.
- Drag grows with the square of speed: for Lecture 1's car it overtakes rolling resistance at
  75 km/h and is three times it at 130 km/h.

### Next: how the engine turns fuel into that work. <Link to="engine-and-cycles">→ 02, engine and cycles</Link>

<!--
That is the demand side. Now the supply: the engine.
-->
