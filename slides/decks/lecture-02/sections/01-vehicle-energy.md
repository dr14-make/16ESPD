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
| $O_{\text{aux}}$ | all other electrical equipment | $O_{\text{aux}} = O_{\text{climat}} + O_{\text{batmngm}} + O_{\text{light}} + O_{\text{audio}}$ |

</div>
</div>
<div>

![A car with its forces drawn as arrows: weight, reaction forces, driving force, friction and air resistance.](/pptx/slide16-vehicle-forces.jpeg)

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

The auxiliaries: climate, battery management, lights, audio. On a modern car they are several
hundred watts, more with the air conditioning on.

Notebook 01, "Where the energy goes", will drive these terms over a WLTC cycle and show which one
dominates in town and on the motorway.
-->

---
routeAlias: rolling-resistance
---

## Rolling resistance coefficient

<div class="grid grid-cols-[1.15fr_1fr] gap-4 items-center">
<div>

![Coefficient of rolling resistance of a car tire against speed from 0 to 140 km/h, one curve per tire pressure from 1 to 4 bar; lower pressure gives a higher coefficient, and every curve rises with speed.](/pptx/slide17-rolling-resistance-vs-speed.png)

</div>
<div>

![Table of rolling resistance coefficients, from 0.001 for railroad steel wheels on rails, through 0.01 to 0.015 for ordinary car tires on concrete or new asphalt, to 0.2 to 0.4 for a car tire on loose sand.](/pptx/slide17-rolling-resistance-table.png)

</div>
</div>

<div class="caption">Source: engineeringtoolbox.com</div>

<!--
The coefficient f k from the previous slide. Left: it rises with speed, and it rises a lot when the
tire is underinflated. At 1 bar it is twice what it is at 3.

Right: by surface. An ordinary car tire on asphalt or concrete is 0.01 to 0.015. In Lecture 1 the
car had 0.012, right in that band. Gravel doubles it, loose sand multiplies it by more than ten.

Notebook 01 will sweep the road surface using this table.
-->

---
routeAlias: drag-and-rolling
class: big-figure
---

## Drag against rolling resistance

<div class="grid grid-cols-[1.6fr_1fr] gap-6 items-center">
<div>

![Drag force and rolling resistance force against velocity from 0 to 35 m/s. Drag rises as the square of speed to about 750 N at 35 m/s; rolling resistance is nearly flat, about 30 to 60 N. The two cross near 7 to 8 m/s.](/pptx/slide18-drag-and-rolling-force.png)

</div>
<div>

$$
O_V = \tfrac{1}{2}\,\rho\, c_x\, S_x\,(v - v_{\text{wind}})^2
$$

$$
O_F = m\, g\, f_k
$$

Below about **8 m/s** (29 km/h) rolling resistance is the larger force. Above it, drag takes over,
and at motorway speed it is more than ten times larger.

</div>
</div>

<!--
The two forces on one axis, on a flat road, so cos alpha is one.

Rolling resistance is almost flat; it creeps up because f k rises with speed. Drag starts at zero
and grows with the square. They cross between 7 and 8 meters per second, below 30 kilometers per
hour. So in town both matter; on the motorway drag is nearly everything. That is why a car's fuel
consumption climbs so steeply above 100 kilometers per hour.

The source slide writes the rolling term as m times f k, without g. It needs g to be a force, as on
the previous slide.

Notebook 01 will regenerate this plot from the Lecture 1 car's parameters.
-->

---

## Summary of section 01

- The engine's work goes into drag, rolling resistance, slope and acceleration, divided by the
  driveline efficiency, plus the electrical auxiliaries.
- Rolling resistance depends on the surface and the tire pressure, and rises with speed.
- Drag grows with the square of speed and dominates above about 30 km/h.

### Next: how the engine turns fuel into that work. <Link to="engine-and-cycles">→ 02, engine and cycles</Link>

<!--
That is the demand side. Now the supply: the engine.
-->
