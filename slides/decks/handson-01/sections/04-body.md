---
routeAlias: body
layout: section
---

###### Step 04 · 21 min

# Body

1400 kg, and the two forces that hold it back on a flat road.

[page: step 04](../handson/lecture-01/#body) · reference `dyad/HandsOn/Body.dyad`

<!--
**Say:** This step, step 4, builds the right-hand side of the car's force
balance, minus the slope. The slope comes back in step 7.

**Timing:** 21 minutes: 6 for the three force slides, 15 building — mostly the drag parameters.
-->

---
routeAlias: four-forces
---

## Four forces on the car

![A car on an inclined road with the forces acting on it drawn as labeled arrows: tractive force up the slope at the driven wheel, aerodynamic drag and rolling resistance down the slope, and the weight resolved into a component along the slope and one into the road surface.](/diagrams/04-four-forces.svg)

<!--
**Say:** There are four arrows on this picture. Here is what each one
means.

**Point at:** each arrow in turn and give it one sentence:

- **Green — the push from the wheels.** Step 03's F = T·i/r. The only one
  we control.
- **Red — air drag.** The car shoving air out of the way. Small when slow,
  huge when fast.
- **Amber — rolling resistance.** The tires squash and spring back on every
  turn, and lose a little energy each time. Roughly the same at any speed.
- **Blue — the slope.** Part of the car's own weight pulls it back down the
  hill.

**Say:** Anything left over after those four is what speeds the car up.
The next slides take them one at a time, and then add them up.

**Tie back to the course deck:** the engine-energy slides call these
O<sub>V</sub> (air), O<sub>f</sub> (rolling), O<sub>s</sub> (slope), O<sub>z</sub>
(acceleration). O<sub>aux</sub>, electrical loads, we leave out — say so, because leaving
something out should always be a decision you announce.
-->

---

## Air drag, and why it grows with speed squared

<div class="grid grid-cols-2 gap-8">
<div>

Speed enters **twice**:

1. **How much air.** Each second the car's front (area *A*)
   moves *v* meters forward and pushes away the air in front of it. Twice as
   fast → twice as much air per second.
2. **How hard.** Each kilogram of that air is pushed to roughly the car's
   speed *v*. Twice as fast → each kilogram pushed twice as hard.

$$ F \;\sim\; \underbrace{\rho A v}_{\text{kg of air per second}}\cdot\underbrace{v}_{\text{speed given to it}} \;=\; \rho A v^2 $$

> **Why it matters for control**
>
> Because of the square, the car behaves differently at different speeds. A controller
> tuned at 90 km/h is tuned for 90 km/h.

</div>
<div>

Double the speed: twice the air, each kilogram pushed twice as hard, so the drag is **2 × 2 = 4 times** bigger. The measured
shape factor *C<sub>d</sub>* and the ½ account for air that flows around the
car instead of being carried along:

$$ F_{\text{drag}} = \tfrac12\,\rho\,C_dA\,v^2 = 0.378\cdot v^2 $$

*ρ = 1.2 kg/m³ air density. C<sub>d</sub>A = 0.63 m², the car's
frontal area times a shape factor. ½·1.2·0.63 = 0.378.*

| speed | m/s | drag |
| --- | --: | --: |
| 30 km/h | 8.3 | 26 N |
| 90 km/h | 25.0 | 236 N |
| 130 km/h | 36.1 | 493 N |

</div>
</div>

<!--
**Say:** Put your hand out of a car window at 30 kilometers per hour, then
at 120. You do not feel four times the push. You feel sixteen times the push. That is the
square.

**Derivation, step by step** (the intuition is enough for the room; this is
for a student who asks):

1. In one second the car sweeps a volume of air A·v (area × distance). Its mass is
   ρ·A·v.
2. The car pushes that air roughly up to its own speed, giving it momentum
   (ρ·A·v)·v = ρ·A·v² every second.
3. Force is momentum per second, so drag ∝ ρ·A·v². The real airflow is gentler than
   "hit and carried along"; the measured shape factor C<sub>d</sub> and the ½ correct for
   that: F = ½·ρ·C<sub>d</sub>·A·v².

**The numbers:** km/h ÷ 3.6 = m/s. 90 km/h = 25 m/s; 25² = 625;
625 × 0.378 = 236 N. 130 km/h = 36.1 m/s; 36.1² = 1304; × 0.378 = 493 N. 30 km/h = 8.33 m/s;
69.4 × 0.378 = 26 N.

**Ask the room:** at 90 km/h, which is bigger — drag or rolling resistance
(next slide, 165 N)? *(Drag, 236 against 165. At 30 km/h it flips: 26 against 165.)*
-->

---

## Rolling resistance, and the 500 N check

<div class="grid grid-cols-2 gap-8">
<div>

**Rolling resistance** is a fixed share of the weight
pressing on the tires:

$$ F_{\text{roll}} = f_r\,m\,g = 0.012 \times 1400 \times 9.81 = 165\ \text{N} $$

It does not depend on speed. In the model, `RollingResistance`
takes the weight m·g as a parameter, and f<sub>r</sub> and the road slope as
*signals* — so a hill can arrive in the middle of a run.

</div>
<div>

#### Step 04's check: push with 500 N

The car speeds up until drag + rolling = 500 N:

0.378·v² + 165 = 500<br>
0.378·v² = 335<br>
v² = 886 &nbsp;→&nbsp; v = 29.8 m/s

- **29.78** m/s — about 107 km/h

</div>
</div>

<!--
**Say:** The rolling resistance coefficient is 0.012. That means the tires
cost 1.2 percent of the car's weight as a backward force. A 1400-kilogram car weighs 1400
times 9.81, which is 13,734 newtons. And 1.2 percent of that is 165 newtons.

**Why the drag part wants "one point":** the library's drag block only knows
"force grows with speed squared". It needs one point to fix the size: at 30 m/s, the force
is ½·1.2·0.63·30² = 0.378 × 900 = 340.2 N. Any speed would do; 30 m/s is just a round number.
In step 04 students give the parameters names (ρ, C<sub>d</sub>A, m) instead of typing
340.2, so the next reader sees physics, not a magic number.

**The 500 N check, step by step:** at the final speed nothing is speeding up,
so the push equals the resistances: 500 = 0.378·v² + 165. Subtract 165: 335. Divide by
0.378: 886.2. Square root: 29.77 m/s. × 3.6 = 107 km/h.
-->

---

## Mass, drag, rolling resistance

![Body: mass, quadratic drag and rolling resistance on one flange, with two constants feeding the rolling resistance.](/img/step04-body.png)

<!--
**Point at:** the two `Constant` blocks on the left. Rolling
resistance takes its coefficient (0.012) and the road inclination (0 — flat) as
*inputs*, not parameters. Unconnected, the model is incomplete.

**Say:** Drag and rolling resistance push against the ground, not against
the car, so their supports connect to the ground block.
-->

---

## The one parameter that bites

```julia
parameter m::Dyad.Mass = 1400
parameter CdA::Area = 0.63
parameter rho::Density = 1.2
parameter v_nominal::Velocity = 30
…
drag = QuadraticSpeedDependentForce(ForceDirection = false,
    v_nominal = v_nominal, f_nominal = -0.5 * rho * CdA * v_nominal ^ 2)
rolling = RollingResistance(fWeight = m * g)
```

- Each value is a parameter of `Body`; the parts use the *names*.
- The block knows drag as **one point** on its curve — force
  `f_nominal` at speed `v_nominal` — and scales by
  (v / v<sub>nominal</sub>)². With `f_nominal` = ½ρC<sub>d</sub>A·v<sub>nominal</sub>²,
  v<sub>nominal</sub> cancels: any value gives the same drag; 30 m/s is just a reference.
- **Negative** makes the source a load rather than a push.
- `ForceDirection = false` makes it oppose motion both ways.

* **500 N** test push
* **29.78 m/s** where drag + rolling = 500 N

<!--
**Why a nominal point:** `QuadraticSpeedDependentForce` is a
generic quadratic load — fans, pumps, drag — meant to be filled in from a datasheet value
such as "this many newtons at that speed". Its equation is
f = −f<sub>nominal</sub>·v·|v| / v<sub>nominal</sub>². Substituting
f<sub>nominal</sub> = −½ρC<sub>d</sub>A·v<sub>nominal</sub>² gives ½ρC<sub>d</sub>A·v·|v|,
with v<sub>nominal</sub> gone. It only must not be zero, because the block divides by it.

**They get wrong:** a positive `f_nominal`. The car then
accelerates forever — drag pushes it. If a student's car in step 05 goes to absurd speeds,
this sign is the first thing to check.

**Ask the room:** why parameters instead of 340.2 and 13729? *(The
next reader sees ρ, C<sub>d</sub>A and m, not magic numbers — and `m` feeds the
mass and the rolling resistance, so changing the car's weight changes both or neither.)*
-->
