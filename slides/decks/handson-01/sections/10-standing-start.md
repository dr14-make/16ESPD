---
routeAlias: standing-start
layout: section
---

###### Step 10 · 23 min

# Standing start on a slippery road

Floor it on ice: the wheel spins, the car barely moves.

[page: step 10](../handson/lecture-01/#standing-start) · reference `dyad/HandsOn/SlipCar.dyad`

<!--
**Say:** Everything in this car is a part you already have. The new thing
is the wiring. The tire is now the contact with the road, so there is no translational
ground block. The wheel's flange drives the body directly.

**Timing:** 23 minutes — 3 for the "two limits" slide, then 20: 13 parts and 15 wires. The page lists the wires as
a numbered table; tell the room to tick them off. Create the car, then its parameters, then
the parts, then the wires, then a separate bench.
-->

---
routeAlias: two-limits
---

## Two limits: the engine's and the tire's

<div class="grid grid-cols-2 gap-8">
<div>

The driven wheels carry half the car: F<sub>z</sub> = 1400 × 9.81 / 2 =
6865 N. The most the tire can push is μ<sub>peak</sub> × F<sub>z</sub>:

| limit | N at the road |
| --- | --: |
| engine, flat out (step 03) | 1935 |
| tire, dry: 1.0 × 6865 | 6865 |
| tire, snow: 0.2 × 6865 | 1373 |
| tire, ice: 0.05 × 6865 | 343 |

**Dry:** the engine runs out first; the tire stays left of its
peak. **Snow:** the tire runs out first; the engine keeps pushing and drives
the wheel **past the peak**.

</div>
<div>

#### Step 10, predicted — full power from a stop

- **21** km/h after 5 s, dry — wheel and car together
- **10** km/h car, snow
- **1500** km/h tire surface, snow

> **Why it runs away**
>
> More slip → less grip → less holding the wheel back → it spins faster → more slip.

</div>
</div>

<!--
**Say:** The push to the road has to get through two things in a row: the
engine and the tire. Whichever has the lower limit decides. You can tell which one it is
from this table, before simulating anything.

**Derivation, step by step**

1. **Load on the driven wheels:** the car weighs 1400 × 9.81 = 13 734 N. Our
   model drives one axle and puts half the weight on it: 6865 N. (Real cars are not
   exactly 50/50 — it is a modeling choice.)
2. **Tire limit:** peak μ × load. Dry 1.0 × 6865 = 6865 N. Snow
   0.2 × 6865 = 1373 N. Ice 0.05 × 6865 = 343 N.
3. **Compare with 1935 N**, the engine at full torque. Dry: the tire could
   take 3.5 × more, so the engine is the limit. Snow: 1373 &lt; 1935, so the tire is the
   limit and the extra torque spins the wheel.
4. **On the curve:** 1935 / 6865 = 0.28. The red dashed line on the last
   slide is at μ = 0.28 — under the whole dry curve, over the whole snow curve. On the dry
   road it needs only κ ≈ 0.0075 — step 09's check reads 0.0076 under the same 1935 N.

**Why it runs away:** once past the peak, extra slip lowers the grip. Less
grip means less force holding the wheel back, so the engine spins it faster, which is more
slip. A loop that feeds itself — nobody built it; it is what the tire does.

**On the 1500 km/h:** the model has no rev limiter, so nothing stops the
wheel. That number is the model telling the truth about what we left out, not a bug. Say it
now so nobody tries to "fix" it when it appears on their plot.

**Flag forward:** the next lecture ends here. A cruise control on ice sees
the speed drop and asks for more torque — and does exactly what this table predicts. That is
why real cruise control switches off when traction control steps in.
-->

---

## Two speeds out

![SlipCar: engine, gear, wheel inertia and slip wheel drive the grade body, with sensors for vehicle speed and wheel surface speed.](/img/step10-standing-start.png)

*`v_kmh` from the body · `wheel_kmh` from the wheel shaft,
× r × 3.6 · tire `radius = r`, `F_z = m * g / 2` · bench: `cmd` 150, `road` 0, `friction` 0.2*

<!--
**Point at:** `r` is used twice — the tire's radius and the
km/h gain — and `m` sets both the body's mass and the axle load. One parameter
each, so they cannot disagree. Typed twice, a change to one is a silent bug in the other.

**Say:** The wheel's surface speed is its spin times its radius. Put that
on the same axis as the car's speed, and wheelspin is simply the gap between the two
lines.

**They get wrong:** missing `initial car.wheel_inertia.w = 0`.
With slip, wheel speed is no longer tied to car speed, so it needs its own start.
-->

---
routeAlias: wheelspin
---

## 1500 km/h at the tire, 10 km/h on the road

<div class="grid grid-cols-2 gap-8">
<div>

```julia [Julia REPL]
using MyCar, Plots
r = MyCar.SlipCarStandingStartTransient()
plot(r; idxs = [r."car.v_kmh", r."car.wheel_kmh"])

dry = MyCar.SlipCarStandingStartTransient(
    model = MyCar.SlipCarStandingStart(
        name = :SlipCarStandingStart, friction__k = 1.0))
plot(dry; idxs = [dry."car.v_kmh", dry."car.wheel_kmh"])
```

</div>
<div>

![Wheel surface speed climbs to 1500 km/h in 5 s while the body barely reaches 10 km/h.](/img/step10-standing-start-plot.png)

</div>
</div>

- **10.1** km/h car, ice, 5 s
- **1501** km/h wheel, ice, 5 s
- **21.1 / 21.2** km/h car / wheel, dry

<!--
**Say:** Past the peak of the curve, more slip gives less grip. The wheel
speeds up, grip falls, and it speeds up more. The model has no rev limit, so the engine
keeps pouring 150 newton-meters into a wheel with nothing to push against. The 1500
kilometers per hour is the model telling you the truth about an assumption. It is not a
bug.

**Then the dry run:** `friction__k = 1.0` overrides the
constant without editing the model. Twice the speed of the icy car, and the two lines stay
together.

**Close:** this is the "two limits" table from the start of this step
come true: on snow the tire saturates before the engine. The PID lecture ends with this car
under cruise control on an ice patch. The controller sees speed falling, commands more
torque, and does exactly what you just watched. That is the argument for traction
control — and for the cascade control of lecture 2.
-->

---

## Every number you predicted, and hit

| Step | You build | Your run should show | Worked out in |
| --- | --- | --- | --- |
| 02 | Engine | 0 until 0.8 s · 97 N·m at 1.0 s · 150 N·m from 1.22 s | <Link to="engine">step 02</Link> |
| 03 | Driveline | 100 N·m → 1290 N → 0.92 m/s² on 1400 kg | <Link to="driveline">step 03</Link> |
| 04 | Body | 500 N push settles at 29.78 m/s | <Link to="body">step 04</Link> |
| 05 | Car | **246.39 km/h** at 300 s · 100 km/h at 23.6 s | <Link to="car">step 05</Link> |
| 06 | Wheel inertia | 23.8 s to 100 km/h · terminal speed unchanged | <Link to="wheel-inertia">step 06</Link> |
| 07 | Grade | 1366 N on a 10 % climb | <Link to="grade">step 07</Link> |
| 08 | Tire curve | μ = 1.0 at κ = 0.04, 0.7 beyond 0.12 | <Link to="tire-curve">step 08</Link> |
| 09–10 | Slip wheel, car | snow: car 10 km/h, wheel 1500 km/h · dry: 21 km/h together | <Link to="standing-start">step 10</Link> |

<!--
**Say:** This is the session on one slide. Every number in the middle
column was worked out on paper at the start of its step. Where a run agreed, the model was
right. Where it did not, something in the model was wrong, not the arithmetic.

**Where each number comes from**, so you can answer "why that number?":

- **02** — 0.5 s request + 0.3 s delay = 0.8 s; 200·(1 − e<sup>−0.2/0.3</sup>) = 97; 0.8 + 0.3·ln 4 = 1.22 s. Step 02.
- **03** — 100 × 4 / 0.31 = 1290 N; ÷ 1400 kg = 0.92 m/s². Step 03.
- **04** — 500 = 0.378·v² + 165 → v = 29.78 m/s. Step 04.
- **05** — 1935 − 165 = 1770 = 0.378·v² → 68.4 m/s = 246 km/h. The times (23.6 s, 143 s) are read off the reference simulation. Step 05.
- **06** — wheel adds J/r² = 10 kg, 0.7 % → 23.6 × 1.007 = 23.8 s. Step 06.
- **07** — 1400 × 9.81 × sin(arctan 0.1) = 1366 N. Step 07.
- **08** — the curve's own parameters. Step 08.
- **09–10** — snow limit 1373 N &lt; engine 1935 N, so the wheel must spin; the 10 and 1500 km/h are read off the reference simulation. Step 10.

**Point at:** step 05, the milestone. Two independent routes — the equation
on paper, and the model you built — and one number.
-->

---

## What you built, and what comes next

<div class="grid grid-cols-2 gap-8">
<div>

- A car, from an empty library: engine → gear and wheel → body → speedometer.
- Every block stands for one term of the physics, explained before you placed it.
- Every number it produced, you predicted first.
- And a tire with a peak — the reason the car crawls on snow.

</div>
<div>

> **Next: Lecture 1 — Introduction and PID**
>
> [The lecture](../lecture-01/index.html) takes this car and builds the cruise
> control from the first slide — P, PI, PID, the 10 % hill the engine cannot climb, tuning
> from a step test, and what that cruise control does on ice.

</div>
</div>

<!--
**Say:** Go back to the first question of the day: how does cruise control
hold 90 kilometers per hour? You now have the car it has to drive, and you know how that
car answers: late, slowly, pushed back by air that grows with the square of speed, and on
snow, not at all. Next lecture, we close the loop.

**Say:** Keep your MyCar library. The lecture's slides link back to the
slides here whenever they use a piece of this physics.
-->

---

## Hand in: a pull request

1. Source Control: nothing left to commit, nothing waiting to sync.
2. github.com → your `MyCar` → **Compare &amp; pull request**
   (or Pull requests → New: base `main`, compare `handson-01`).
3. Title `Lecture 1 hands-on`. Description: steps finished, the checkpoint
   numbers you got, anything that did not match.
4. **Create pull request** — and do *not* merge it.

> **Checkpoint**
>
> The pull request's **Commits** tab shows one commit per step.

Page: [Hand in](../handson/lecture-01/#hand-in)

<!--
**Say:** Your last step is to hand in. Open a pull request from your
branch into main, describe what you did and what numbers you got, and leave it open. It
gets reviewed there. If you get a comment, fix the model, commit and sync again on the
same branch, and the fix shows up in the same pull request.

**They get wrong:** merging their own pull request. If it happened, it is
not lost — the commits are on `main` — but the pull request is gone, so the
review has nothing to comment on. Note who it was and sort it out with them after the
session.
-->
