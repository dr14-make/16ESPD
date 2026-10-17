---
routeAlias: body
layout: section
---

###### Step 04 · 21 min

# Body

1400 kg, and the two forces that hold it back on a flat road.

[page: step 04](../handson/lecture-01/#body) · reference `dyad/HandsOn/Body.dyad`

<!--
**Say:** In this step you build the car's body: its 1400 kilograms, and the two forces that
hold it back on a flat road. Those are air drag and rolling resistance. Hills come back in
step 7.

**Tutor:** `Body` is one new *component*. A component is Dyad's word for a model: a block
with parts and wires inside, which can then be used as a single part in a bigger model.
In step 05 the engine, the driveline and this body become one car.

**Timing:** 21 minutes: about 6 for the three theory slides (four forces, air drag,
rolling resistance), 15 for building. The drag block's settings take the longest.

**What students should have at the end:** `Body` saves without errors. That is the only
check they make in this step. The "500 N" result on the rolling-resistance slide comes from
a ready-made test in the course library (`TestBody`), not from a run they do. Their body
first moves for real in step 05.
-->

---
routeAlias: four-forces
---

## Four forces on the car

![A car on an inclined road with the forces acting on it drawn as labeled arrows: tractive force up the slope at the driven wheel, aerodynamic drag and rolling resistance down the slope, and the weight resolved into a component along the slope and one into the road surface.](/diagrams/04-four-forces.svg)

<!--
**Say:** The picture shows four forces.

**Point at:** each arrow in turn and give it one sentence:

- **Green — the push from the wheels** (labeled "tractive"). This is step 03's result,
  F = T·i/r: engine torque T (its twisting force, in newton-meters), times the gear ratio
  i = 4, divided by the wheel radius r = 0.31 m. The only force we control.
- **Red — air drag.** The car pushing air out of the way. Small at low
  speed, large at high speed.
- **Amber — rolling resistance.** The tires squash and spring back on every
  turn, and lose a little energy each time. Roughly the same at any speed.
- **Blue — the slope.** Part of the car's own weight pulls it back down the
  hill. Zero on a flat road; step 07 adds it.

**Say:** The push minus the three resistances is what speeds the car up.
The next slides take the forces one at a time, and then add them up.

**Tie back to the course lectures:** the course's own slides on driving resistances use
these letters, and the picture shows them too: O<sub>V</sub> (air), O<sub>f</sub> (rolling),
O<sub>s</sub> (slope), O<sub>z</sub> (the force that goes into speeding up). The course also
lists O<sub>aux</sub>, power for electrical equipment. We leave it out. Say so: whenever you
leave something out of a model, state it.

**If asked why the slope looks so steep:** it is drawn steeper than a real road so the
arrows are readable. The picture says so in its small print.
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
> tuned at 90 km/h is tuned for 90 km/h only.

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
at 120. Four times the speed gives sixteen times the push, because drag grows with the
square of speed.

**Symbols, read aloud:** ρ is "rho", the density of air: 1.2 kilograms per cubic meter.
C<sub>d</sub>A is the "drag area": the car's front area times a shape factor that says how
smoothly air flows around it. For this car it is 0.63 square meters. v is speed in meters
per second. F is force in newtons (N).

**The control box, in plain words:** a controller is the program that works the pedal.
Settings that work well at 90 km/h will not work as well at 130 km/h, because the car
answers the pedal differently there.

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
8.33² = 69.4; × 0.378 = 26 N.

**Ask the room:** at 90 km/h, which is bigger — drag or rolling resistance
(next slide, 165 N)? *(Drag, 236 against 165. At 30 km/h it flips: 26 against 165.)*
-->

---

## Rolling resistance, and the 500 N check

<div class="grid grid-cols-2 gap-8">
<div>

**Rolling resistance** is a fixed share of the weight
pressing on the tires:

$$ F_{\text{roll}} = f_r\,m\,g = 0.012 \times 1400 \times 9.81 = 164.8\ \text{N} $$

It does not depend on speed. In the model, `RollingResistance`
takes the weight m·g as a parameter, and f<sub>r</sub> and the road slope as
*signals* — so a hill can arrive in the middle of a run.

</div>
<div>

#### The reference test: push with 500 N

The car speeds up until drag + rolling = 500 N:

0.378·v² + 164.8 = 500<br>
0.378·v² = 335.2<br>
v² = 886.8 &nbsp;→&nbsp; v = 29.78 m/s

- **29.78** m/s — about 107 km/h

</div>
</div>

<!--
**Say:** The rolling resistance coefficient is 0.012. That means the tires
cost 1.2 percent of the car's weight as a backward force. A 1400-kilogram car weighs 1400
times 9.81, about 13,730 newtons. And 1.2 percent of that is about 165 newtons.

**Symbols:** f<sub>r</sub> is the rolling resistance coefficient (0.012, no unit). m is the
mass, 1400 kg. g is gravity, 9.81 m/s². The model uses g = 9.80665, the standard value; that
gives 164.75 N instead of 164.8 N. The difference does not show in any result.

**Parameter or signal — the one Dyad idea on this slide:** a *parameter* is a number fixed
before the run starts, like the car's weight. A *signal* is a value that arrives through a
wire and may change during the run. The road slope is a signal so that a hill can appear
halfway through a drive (step 07).

**The 500 N check, step by step:** imagine a constant 500 N push on the body alone. It speeds
up until it stops getting faster. At that point the push equals the resistances:
500 = 0.378·v² + 164.8. Subtract 164.8: 335.2. Divide by 0.378: 886.8. Square root: 29.78 m/s.
Times 3.6 = 107 km/h. At the very start the speed is zero, so there is no drag yet. The
acceleration is then 500 / 1400 = 0.357 m/s².

**Who runs this check:** the course library's test `TestBody` does, with exactly these
results (0.357 m/s² at the start, 29.78 m/s at the end). Students do not build a test for it.
-->

---

## Mass, drag, rolling resistance

![Body: mass, quadratic drag and rolling resistance on one flange, with two constants feeding the rolling resistance.](/img/step04-body.png)

<!--
**Tutor — what is in the picture:**

- `mass` — the car's 1400 kg.
- `drag` — air drag.
- `rolling` — rolling resistance.
- `flange` — the body's connection point. A *flange* is Dyad's word for a point where
  a straight-line push enters a part. The driveline will push the car here in step 05.
- `ground` — a fixed point that never moves. It stands for the road and the still air.
- `cr_const` and `incl_const` — two `Constant` blocks. A `Constant` block just outputs one
  fixed number on a wire: 0.012 (the rolling coefficient) and 0 (a flat road).

**Point at:** the two `Constant` blocks on the left. Rolling resistance takes its
coefficient and the road slope as *inputs* (wires), not as typed-in numbers. If either
input is left unwired, the model is incomplete and will not run.

**The wires students draw:**

1. `flange`, `drag.flange` and `rolling.flange` → `mass.flange_a`.
2. `drag.support` and `rolling.support` → `ground.flange`.
3. `cr_const.y` → `rolling.cr`, and `incl_const.y` → `rolling.inclination`.

**Say:** Drag and rolling resistance push against the road and the air, not against the car
itself. So the other end of each force (its *support*) connects to the ground block.

**Where to click:** in the **Components** panel, right-click `MyCar` → **Add Component** →
name it `Body`. Add each part with the **+** button in the diagram toolbar; the student page
lists the library path for every part. Add parameters with **Add parameter** in the
component panel, or switch to code (⇄ button) and paste the block from the student page.

**If stuck:** the student page has the full model under "Stuck? The full model".
-->

---

## Body parameters, and the sign of `f_nominal`

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
**Tutor:** the "…" in the code hides two more parameters, `f_r = 0.012` and
`g = 9.80665`. The full list is in the student page's parameters table.

**Say:** We type each number once, as a named parameter. The parts then use the names.

**Why the drag block needs one point:** `QuadraticSpeedDependentForce` is a general
library block for any force that grows with speed squared: fans, pumps, drag. It is
filled in from one data point, such as "this many newtons at that speed". Here the point is
30 m/s, where drag is ½·1.2·0.63·30² = 0.378 × 900 = 340.2 N. Any speed would give the same
drag curve; 30 m/s is just a round number. It must not be zero, because the block divides
by it.

**For a student who wants the math:** the block computes
f = −f<sub>nominal</sub>·v·|v| / v<sub>nominal</sub>². Put in
f<sub>nominal</sub> = −½ρC<sub>d</sub>A·v<sub>nominal</sub>², and v<sub>nominal</sub> cancels,
leaving ½ρC<sub>d</sub>A·v·|v|.

**The two settings, in plain words:**

- `f_nominal` is **negative**, so the block holds the car back instead of pushing it.
- `ForceDirection = false` makes drag act against the motion in both directions,
  forward or backward.

**They get wrong:** a positive `f_nominal`. Drag then pushes the car
forward and it accelerates without limit. If a student's car in step 05 goes to absurd speeds,
this sign is the first thing to check.

**Ask the room:** why parameters instead of 340.2 and 13729? *(13729 is m·g = 1400 × 9.80665.
With names, the next reader sees ρ, C<sub>d</sub>A and m, not unexplained numbers. And `m` feeds
the mass and the rolling resistance, so changing the car's weight changes both at once.)*
-->
