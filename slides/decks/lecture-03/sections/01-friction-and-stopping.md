---
routeAlias: friction-and-stopping
layout: section
---

###### Section 01

# Friction and stopping

What the road can give back: the friction coefficient, how a tire differs from a sliding block,
and the shortest stop physics allows.

<!--
Budget: 14 minutes for the section, 7 slides: friction 2, tire curve 2, braking distance 2,
build 01 by hand 5, cornering 2, summary 1.

Every brake, however strong, ends at the same place: the contact patch, about the size of a hand
per wheel. Whatever the brakes do, the car decelerates only as hard as friction there allows. So
we start with friction.
-->

---
routeAlias: friction
---

## Friction: static, kinetic, and how much

<div class="grid grid-cols-[1fr_1.15fr] gap-8">
<div>

Friction resists the **relative motion** of two surfaces in contact:

$$
F_f \;=\; \mu\,F_N
$$

$F_f$ friction force [N], $F_N$ normal force [N], $\mu$ the coefficient of friction [–].

- **Static** $\mu_s$: no relative motion; $\mu_s F_N$ is the most it holds before sliding.
- **Kinetic** $\mu_k$: the surfaces slide.
- For one pair of surfaces $\mu_k \le \mu_s$: **once it slides, it holds less.**

The tire rows are typical, not exact: they vary with the tire, its temperature, the speed, the
water depth and the road. The repository's tire uses **1.0 at the peak**, **0.7 sliding**, scaled
by a road factor: 1.0 dry, about 0.5 wet, 0.2 snow, 0.05 ice.

</div>
<div>

| Surfaces | μ static | μ kinetic |
|---|---:|---:|
| Steel on steel | 0.74 | 0.57 |
| Glass on glass | 0.94 | 0.40 |
| Metal on metal, lubricated | 0.15 | 0.06 |
| Ice on ice | 0.10 | 0.03 |
| PTFE (Teflon) on PTFE | 0.04 | 0.04 |
| **Tire on dry concrete** | **1.00** | **0.80** |
| **Tire on wet road** | **0.60** | **0.40** |
| **Tire on snow** | **0.30** | **0.20** |

</div>
</div>

<!--
Budget: 2 minutes. Coulomb's model is school physics; say it once and move to the table.

Push a block. As long as it does not move, friction matches your push exactly. At some force, mu s
times the normal force, the block breaks loose. Then the friction drops to mu k times the normal
force, and stays there, roughly, while it slides. The source deck drew this as a block with four
forces and a friction-against-push curve, `public/pptx/slide03-friction-forces.jpg` and
`slide03-static-kinetic.jpg`; draw the curve on the board if the room needs it.

Why friction works the way it does is still an open research question. The two classic
explanations from the source deck: microscopic roughness interlocking, and molecular adhesion
between the surfaces. For rubber on a road both matter, plus a third: rubber deforming over the
road's texture and losing energy, called hysteresis friction. That is why a tire's grip depends on
temperature and on the road's texture, not only on the materials.

The table is the source deck's. The first five rows match the usual university physics textbook
table, Serway's, which lists rubber on concrete as 1.0 static and 0.8 kinetic; the wet and snow
rows are typical values from the same family of tables, not one measured tire.

Two things to notice. Teflon is the only pair whose static and kinetic values match. And for a
tire the gap between them is 20 to 33 percent. That gap is the prize ABS goes after.

The model's tire, `TireFrictionCurve`, has a peak of 1.0 and a sliding value of 0.7, so its
sliding-to-peak ratio is 0.7. Measured tires are milder: NHTSA's tests on paved surfaces give 0.76
to 0.89, cited in `docs/abs-frequency-research.md`. Keep that in mind when the model's ABS shows
a large gain: the model's tire is harsher than a real one.
-->

---
routeAlias: tire-is-not-a-block
---

## A tire is not a block: friction against slip

<div class="grid grid-cols-[1fr_1.3fr] gap-8">
<div>

A rolling tire is not purely static. The tread deforms in the contact patch and slips a little,
so its force depends on **slip** $\kappa$:

- **Rolling**, $\kappa = 0$: no longitudinal force.
- **Adhesion peak**, a few percent of slip: the most force, $\mu_A$. This is the "static" end.
- **Locked wheel**, $\kappa = -1$: the tread slides, $\mu_S$. This is the "kinetic" end.

**Braking well means holding the tire near its peak.**

<div class="handson">→ Build 01: the brake torque that holds the tire at this peak, by hand</div>

</div>
<div>

![Two panels. Left: friction coefficient against slip ratio, rising steeply to a marked peak of 1.0 at 0.04 and falling to a sliding plateau of 0.7, the region past the peak shaded. Right: the same curve on a logarithmic slip axis, with the operating points of the snow and dry-road standing starts marked.](/figures/10-mu-slip-curve.svg)

<div class="caption">The model's curve from Lecture 1; braking is its mirror image at negative slip</div>

</div>
</div>

<!--
The source deck explained the brake's job with static against kinetic friction: a rolling tire
uses static friction, a locked one kinetic. That picture is a good first step and is what drivers
are taught. The more accurate version is this curve, and the one the models use.

Its left end, zero slip, is free rolling. As you brake harder, slip grows and so does the force,
steeply, up to the adhesion peak at about 4 percent in the model; real dry-road tires peak
somewhere between about 5 and 20 percent depending on tire and surface. Past the peak the force
falls toward the sliding value, which a locked wheel sits at.

So "static" and "kinetic" are the two ends of one curve. The source deck's three options become:
brake just short of the peak, which only a very good driver can do; pump the brake, which cycles
the tire through the curve; or let a controller hold the tire there. The third is ABS.
-->

---
routeAlias: braking-distance
---

## Braking distance

<div class="grid grid-cols-[1fr_1fr] gap-8">
<div>

At constant deceleration $a = \mu g$, from speed $v$ to rest:

$$
d \;=\; \frac{v^2}{2\,g\,\mu}
$$

$d$ braking distance [m], $v$ initial speed [m/s], $g = 9.81$ m/s², $\mu$ the tire–road friction
coefficient.

From **90 km/h = 25 m/s**:

| μ | | d |
|---:|---|---:|
| 1.0 | dry, at the peak | 31.9 m |
| 0.8 | dry, sliding | 39.8 m |
| 0.6 | wet, at the peak | 53.1 m |
| 0.4 | wet, sliding | 79.7 m |
| 0.3 | snow, at the peak | 106.2 m |
| 0.2 | snow, sliding | 159.3 m |

<div class="handson">→ Build 01, next: the peak and sliding bounds for your ABS car, by hand</div>

</div>
<div>

> **Speed squared**
>
> Twice the speed is **four times** the distance. 130 km/h on a dry road needs 66.5 m.

> **Reaction distance comes first**
>
> At 1 s of reaction time, the car covers another **25 m** at 90 km/h before the brakes
> start. Stopping distance = reaction distance + braking distance.

> **The prize**
>
> Holding the peak instead of sliding saves 20–33 % of the braking distance on these numbers.

</div>
</div>

<!--
The energy argument: the kinetic energy one half m v squared is removed by the friction force mu
m g over the distance d. The mass cancels. That is why a heavy truck and a light car with the same
tires need, in theory, the same distance; in practice a truck's brakes and tires are worse.

The table is this formula at 25 meters per second with the source deck's friction table. Each
pair, peak and sliding, is what ABS can win on that surface, in the ideal case. Real cars do not
hold the peak exactly: NHTSA's measurements on nine cars found ABS stops 10 to 13 percent shorter
than a locked-wheel stop on dry pavement and 11 to 23 percent on wet, cited in
`docs/abs-frequency-research.md`.

130 kilometers per hour is 36.1 meters per second; squared, over 2 times 9.81, is 66.5 meters at
mu 1.

The source slide wrote the formula as d equals V squared over 2 g mu with "Vmax" and "r" in the
legend. Those two belong to the next slide, the cornering limit.
-->

---
routeAlias: build-limits
---

## Build 01: the tire's limit, by hand

<div class="grid grid-cols-[1fr_1fr] gap-10 items-start">
<div>

The car you brake today: **1400 kg** on one lumped wheel, *r* = **0.31 m**, from **90 km/h** =
25 m/s. Its tire: peak *μ*<sub>A</sub> = **1.0** at 4 % slip, sliding *μ*<sub>S</sub> = **0.7**
from 12 %.

$$
F_z = m g \qquad T_{peak} = \mu_A F_z\, r \qquad d = \frac{v^2}{2\,\mu\, g}
$$

*On paper or in the REPL: F<sub>z</sub>, T<sub>peak</sub>, and d at the peak and sliding, on dry
road and on snow (road factor 0.3)*

**Given:** no parts to place: the car and its tire, above

[page: step 01](../lecture/lecture-03/#step-01)

</div>
<div>

> **Expected**
>
> - *F*<sub>z</sub> = **13 729 N**, *T*<sub>peak</sub> = **4256 N·m**
> - the driver's 6000 N·m is 1.4 × that: the wheel **must** lock
>
> | road | at the peak | sliding |
> | --- | --: | --: |
> | dry, *μ* 1.0 | **31.9 m** | **45.5 m** |
> | snow, *μ* 0.3 | **106.2 m** | **151.7 m** |

</div>
</div>

<!--
Before anything runs, the three numbers every later run is judged by. Five minutes, on paper or in
the Julia REPL.

The car is the one in the ABS model: 1400 kilograms, all of it on one lumped wheel of radius 0.31
meters, braking from 90 kilometers per hour, 25 meters per second. The tire is the same
`TireFrictionCurve` you built in hands-on 1: peak 1.0 at 4 percent slip, 0.7 once it slides.

First the normal force: m times g, 1400 times 9.81, about 13,700 newtons. The tire can carry at
most mu A times that, and the brake torque that asks for exactly that force is the force times the
radius: 4256 newton-meters. Remember it. The driver today asks for 6000, 1.4 times as much, so
without ABS the wheel must lock.

Then the two distances from the formula on the last slide. At the peak, mu 1.0: 31.9 meters. That
is the floor no ABS beats. Sliding, mu 0.7: 45.5 meters, roughly what a locked wheel gives. On
snow, a road factor of 0.3 scales both: 106 and 152 meters.

In the REPL: 25 squared over 2 times 1.0 times 9.81, and so on. Wait until most of the room has
4256 before moving on; it comes back on every ABS slide.

The guide uses g = 9.80665, the library's value; 9.81 on paper is close enough.
-->

---
routeAlias: cornering-limit
---

## The cornering limit

<div class="grid grid-cols-[1fr_1fr] gap-8 items-center">
<div>

In a curve of radius $r$, friction has to supply the centripetal force $m v^2 / r$. It can give
at most $\mu m g$, so

$$
v_{\max} \;=\; \sqrt{\mu\, g\, r}
$$

On a 50 m radius: **80 km/h** dry, **62 km/h** wet, **44 km/h** on snow.

**One budget for two jobs.** A tire's grip is shared between braking and cornering, roughly a
circle of radius $\mu F_z$. Brake hard in a bend and less is left for turning; a **locked** wheel
has nothing left for turning, so the car **cannot be steered**.

</div>
<div>

![A car entering a curve: its velocity is tangent to the curve and the frictional force points toward the curve's center.](/pptx/slide04-car-on-curve.jpg)

</div>
</div>

<!--
The second half of the source deck's slide: maximum velocity in a curve of radius r. Same mu,
same g, now the force points sideways, toward the center of the curve.

The numbers: square root of mu times 9.81 times 50, in kilometers per hour.

The important sentence is the last one. Longitudinal and lateral force come out of the same
contact patch. The usual picture is the friction circle, or more accurately an ellipse: the vector
sum of the two cannot exceed about mu times the normal load. A sliding tire's force points along
its sliding direction, which for a locked wheel is the direction of travel. It gives no
sideways force where the driver needs it. That, more than the shorter stop, is why ABS exists:
the driver can still steer around the obstacle while braking fully.

That also sets up ESP: it uses the same budget, braking one wheel on purpose to turn the car.
-->

---

## Summary of section 01

- Friction force is $\mu F_N$; sliding friction is lower than the peak a surface can hold.
- A tire's force depends on slip: it peaks at a few percent and falls toward the sliding value
  of a locked wheel.
- Braking distance is $v^2 / 2 g \mu$: four times the distance at twice the speed. Holding the
  peak instead of sliding would save 20–33 % of it.
- A locked wheel gives no lateral force: the car cannot be steered.

### Next: how the brake turns a foot into torque. <Link to="brakes">→ 02, how the brakes work</Link>

<!--
That is what the road allows. Now the system that asks for it: the brakes.
-->
