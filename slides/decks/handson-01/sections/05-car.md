---
routeAlias: car
layout: section
---

###### Step 05 · 27 min

# Car: full throttle to terminal speed

Your three components, assembled — and the 246 km/h you computed on paper.

[page: step 05](../handson/lecture-01/#car) · reference `dyad/HandsOn/Car.dyad`

<!--
**Say:** This is the milestone. Everything so far was parts. This is the
plant that every controller in the PID lecture will be wrapped around.

**Timing:** 27 minutes: 7 of theory (force balance, nine numbers, top speed, how long), then assembly 8, bench and analysis 5, run and plot 5, and the "246 is wrong" slide after the plot.
-->

---
routeAlias: force-balance
---

## Adding it all up: the force balance

Newton's second law: mass × acceleration = sum of all forces.

$$
\underbrace{m\,\frac{dv}{dt}}_{\text{speeding up}} \;=\;
  \underbrace{\frac{T\,i}{r}}_{\text{push}}
  \;-\; \underbrace{\tfrac{1}{2}\rho\,C_dA\,v^2}_{\text{air}}
  \;-\; \underbrace{f_r\,m\,g\cos\alpha}_{\text{tires}}
  \;-\; \underbrace{m\,g\sin\alpha}_{\text{slope}}
$$

<div class="grid grid-cols-2 gap-8">
<div>

Read it as a budget: the push comes in, the three resistances take their share, and
**what is left speeds the car up**. If nothing is left, the speed is
steady.

</div>
<div>

> **In Dyad you do not type this**
>
> You join the parts on one mechanical joint, and the rule from step 01 — forces add up to
> zero — writes this equation for you.

</div>
</div>

<!--
**Say:** This is the whole car in one line: everything we said in the last
four slides, added up. The left side is mass times acceleration. The right side is the
push, minus everything that holds the car back.

**Point at:** the T on the right. It is not the pedal request; it is what
step 02's engine actually delivers — late, slow, limited.

**Point at:** the v². Because of it, the car is not "linear": doubling the
push does not double the speed. That will matter in the next lecture's step test.

**Say:** Step 4 builds the right side on a flat road: mass, air and tires.
Step 7 adds the slope.

**Symbols, once more:** m = 1400 kg; v speed in m/s; T engine torque;
i = 4; r = 0.31 m; ρ = 1.2 kg/m³; C<sub>d</sub>A = 0.63 m²; f<sub>r</sub> = 0.012;
g = 9.81 m/s²; α road angle.
-->

---

## The car, in nine numbers

<div class="grid grid-cols-2 gap-8">
<div>

| What | | |
| --- | --: | --- |
| mass *m* | 1400 | kg |
| drag area *C<sub>d</sub>A* | 0.63 | m² |
| air density *ρ* | 1.2 | kg/m³ |
| rolling coefficient *f<sub>r</sub>* | 0.012 | — |
| wheel radius *r* | 0.31 | m |
| gear ratio *i* | 4.0 | — |
| max engine torque *T*<sub>max</sub> | 150 | N·m |
| engine lag *τ<sub>e</sub>* | 0.3 | s |
| engine delay *θ<sub>e</sub>* | 0.3 | s |

</div>
<div>

#### Where you type each one

- `Engine` — T<sub>max</sub>, τ<sub>e</sub>, θ<sub>e</sub> (step 02)
- `Driveline` — i, r (step 03)
- `Body` — m, C<sub>d</sub>A, ρ, f<sub>r</sub> (step 04)

> **Nothing is chosen to make a point**
>
> Every number in the hands-on and in the next lecture comes from these nine, by
> arithmetic you can check.

</div>
</div>

<!--
**Say:** This is the entire car: nine numbers. You have now met every one
of them: three in the engine, two in the gear and wheel, and four in the body.

**Ask the room:** which of these nine will make the car hardest to control?
*(Let two or three guesses land. The answer is the bottom two — the delay and the lag
from step 02.)*
-->

---
routeAlias: top-speed
---

## Top speed: when the push runs out

<div class="grid grid-cols-2 gap-8">
<div>

At top speed the car no longer speeds up: *dv/dt = 0*. The force
balance (flat road) becomes **push = air + tires**:

1. Most push: 150 × 4 / 0.31 = **1935 N**
2. Tires take: **165 N**. Left for the air: 1935 − 165 = 1770 N
3. Air: 0.378 · v² = 1770 → v² = 4683
4. v = √4683 = 68.4 m/s × 3.6 = **246 km/h**

</div>
<div>

#### The same idea, at cruise

To hold a speed, push = air + tires. Then turn the push back into engine
torque: T = F · r / i.

| hold | air | + tires | = push | torque |
| --- | --: | --: | --: | --: |
| 90 km/h | 236 | 165 | 401 N | **31.1 N·m** |
| 110 km/h | 353 | 165 | 518 N | **40.1 N·m** |

*The next lecture opens with these two: they are its first
experiment, and the answer its controller has to find on its own.*

</div>
</div>

<!--
**Do it on the board.** This is the most important calculation of the day,
so go slowly.

1. **Why dv/dt = 0:** "top speed" means the car has stopped getting faster.
   So the left side of the force balance is zero, and the forces must cancel.
2. **The push:** full torque through step 03's formula, 150 × 4 / 0.31 =
   1935 N.
3. **Subtract the tires:** 165 N, the same at every speed. 1935 − 165 =
   1770 N left for the air.
4. **Solve for v:** 0.378·v² = 1770, so v² = 1770 / 0.378 = 4683, and
   v = 68.4 m/s. Times 3.6 = 246 km/h.

**The cruise torques, step by step:** 90 km/h = 25 m/s; air 0.378 × 625 =
236 N; plus 165 = 401 N needed at the road. Torque = 401 × 0.31 / 4 = 31.1 N·m. 110 km/h =
30.56 m/s; 30.56² = 934; × 0.378 = 353 N; plus 165 = 518 N; × 0.31 / 4 = 40.1 N·m.

**Say:** Notice what we did. We set the "speeding up" part to zero and
solved. That gives the *steady state*, where the car ends up, without saying
anything about how it gets there. The next lecture's controller will find 31.1
newton-meters by itself, without being told.

**Ask the room, before the next slide:** 246 km/h from a 150 N·m engine. Does
anyone believe that? *(Let the doubt sit — the next slide answers it.)*
-->

---
routeAlias: time-constant
---

## How long does it take to get there?

<div class="grid grid-cols-2 gap-8">
<div>

Near any speed, the car behaves like step 02's lag: if it goes a little
faster, drag grows a little and pulls it back. How fast it pulls back sets its
**time constant**:

$$ \tau_{\text{car}} = \frac{m}{\text{extra drag per extra m/s}} = \frac{m}{2 \cdot 0.378 \cdot v} $$

**Extra drag per extra m/s** at 100 km/h (27.8 m/s): drag
is 0.378 × 27.8² = 292 N; 1 m/s faster it is 0.378 × 28.8² = 313 N — about
**21 N more**. In general the slope of v² is 2v, so it is
2 × 0.378 × v = 21 N per m/s.

Those 21 N per m/s pull a too-fast car back, like the lag closing its
gap: τ = 1400 / 21 = **67 s**.

That is 200 times slower than the engine's 0.3 s. The car itself is the
slow part.

</div>
<div>

#### Step 05, predicted

- **23.6 s** to 100 km/h
- **143 s** to 99 %
- **246.39** km/h at 300 s

> **So run for 300 s**
>
> Stop sooner and the car is still on its way up — and you will think 246 is wrong.

</div>
</div>

<!--
**Say:** It takes two and a half minutes of flat-out driving to get within
one percent of top speed. Drag is weak at low speed, so there is not much pulling the car
toward its final speed, and it gets there slowly.

**Derivation, step by step** (compare with the lag slide in step 02):

1. Suppose the car is near speed v and goes Δv faster. Drag grows from 0.378·v² to about
   0.378·v² + 2·0.378·v·Δv (the slope of v² is 2v).
2. That extra drag, 2·0.378·v·Δv, slows the car: m·dΔv/dt = −2·0.378·v·Δv.
3. That is exactly the lag equation from step 02, τ·dΔv/dt = −Δv, with
   τ = m / (2·0.378·v).
4. At 27.8 m/s: 2 × 0.378 × 27.8 = 21.0; 1400 / 21.0 = 66.7 s. At 90 km/h it is 74 s, at
   110 km/h 61 s — the car is quicker to settle at high speed, because drag is
   stronger there.

**Where 23.6 s, 143 s and 246.39 come from:** these are read off a simulation
of this same force balance (the reference model `HandsOn.CarFullThrottle`); there
is no neat hand formula because τ changes with speed. They are the numbers students compare
against.

**Flag forward:** in the next lecture a controller moves this car 20 km/h in
a few seconds. The engine is no stronger. Feedback changes how fast the car responds — keep
the 67 s in mind for that moment.
-->

---

## Assemble from your own library

![Car: torque command into engine, driveline and body, with a velocity sensor and a 3.6 gain producing speed in km/h.](/img/step05-car.png)

*Your `Engine`, `Driveline`, `Body` from + → MyCar · `VelocitySensor` → `Gain(k = 3.6)` → `v_kmh` · two grounds*

<!--
**Point at:** `rot_ground` and `trans_ground`. These
close the reaction paths left open in steps 02 and 03.

**Say:** The sensor gives meters per second, and the gain turns that into
kilometers per hour. There is one conversion, at the edge of the model, which is the same
rule the lecture model follows.
-->

---

## New bench, new analysis, run

```julia [CarFullThrottle — complete bench and analysis]
component CarFullThrottle
  "Full throttle: the engine's 150 N·m ceiling"
  cmd = BlockComponents.Sources.Constant(k = 150)
  car = Car()
relations
  connect(cmd.y, car.tau_cmd)
  initial car.body.mass.s = 0
  initial car.body.mass.v = 0
  initial car.engine.lag.x = 0
end

analysis CarFullThrottleTransient
  extends TransientAnalysis(stop = 300)
  model = CarFullThrottle()
end
```

<!--
**Same pattern as step 02:** New component `CarFullThrottle` →
draw → three `initial` lines in code → ▷ Run Analysis → TransientAnalysis, named
`CarFullThrottleTransient`, `stop = 300` → ▷ in Analyses.

**They get wrong:** leaving out `car.body.mass.s`. Position
appears in no force, so it feels optional, but without it the start is not unique and the
model will not initialize.

**Why 300 s:** the car's own time constant is about a minute. Shorter runs
stop on the way up and the student thinks the terminal speed is wrong.
-->

---

## 246 km/h — the car on paper

<div class="grid grid-cols-2 gap-8">
<div>

```julia [Julia REPL]
using MyCar, Plots
r = MyCar.CarFullThrottleTransient()
plot(r; idxs = r."car.v_kmh")
```

</div>
<div>

![car.v_kmh rising from zero and leveling off at about 246 km/h.](/img/step05-car-plot.png)

</div>
</div>

- **23.6 s** to 100 km/h
- **143 s** to 99 %
- **246.39** km/h at 300 s

<!--
**Say:** The course model that the PID lecture runs, called CarPlant, also
reads 246.39 kilometers per hour at 300 seconds. At 800 seconds the two agree to within
0.0001 kilometers per hour. You built the lecture's car.

**Point at:** the shape. Steep first, then flattening, because drag grows
with the square of speed. Tie back to the start of this step: the 246 is the number we
worked out on paper from the force balance, and 23.6 s to 100 km/h was predicted there
too.

**If a number is off:** drag sign (step 04), gear ratio or radius
(step 03), limiter ceiling (step 02) — in that order.
-->

---

## 246 km/h is wrong — and that is fine

<div class="grid grid-cols-[1fr_1.4fr] gap-8">
<div>

> **What our engine gets wrong**
>
> It gives 150 N·m at every engine speed. A real engine only gives its best in the middle
> of its rev range, and less at very low and very high revs.

- At 246 km/h the engine would spin at **8400 rpm** (step 03). A real one
  gives much less there, so the real top speed is lower.
- Between 90 and 130 km/h — where the next lecture drives — the two agree. There the
  model is good.
- Fixing the top end means a torque curve: lecture 2.

</div>
<div>

![Engine torque against crankshaft speed. A flat line at 150 newton-meters across the whole range is our model; a curve that rises, plateaus and falls away is the shape of a real engine. The band where the PID lecture operates is shaded, and the crankshaft speed implied by 246 km/h is marked well past the real curve's peak.](/diagrams/05-torque-curve.svg)

_Red: the usual **shape** of a petrol engine, drawn for
comparison — not measured. Blue: exactly what our engine block computes._

</div>
</div>

<!--
**Say:** Every model has a range where you can trust it. Ours is fine up
to about 130 kilometers per hour, and fiction above that. Your car just hit 246 kilometers
per hour, exactly as we predicted, and it is still fiction. Both are true. That is the
point of this slide.

**Point at the plot in this order:** the blue line (our engine: 150 N·m
whatever the revs — the limiter's ceiling is a constant); the red curve (a real engine:
same peak, but only in the middle); the shaded band (90–130 km/h, where the two agree); the
mark at 8400 rpm (our 246 km/h, where a real engine is down to about 95 N·m).

**The rpm numbers, step by step** (step 03's formula, engine rpm =
v / r × i × 60 / 2π): 90 km/h = 25 m/s → 25 / 0.31 × 4 × 9.55 = 3080 rpm. 130 km/h →
4450 rpm. 246 km/h = 68.4 m/s → 8430 rpm.

**They get wrong:** treating a simulation result as a measurement. A model
only knows what you told it.

**Ask the room:** what would you add to get a believable top speed?
*(Make the maximum torque depend on engine speed — a torque curve. That is where
lecture 2 starts.)*
-->
