---
routeAlias: standing-start
layout: section
---

###### Step 10 · 23 min

# Standing start on a slippery road

Floor it on ice: the wheel spins, the car barely moves.

[page: step 10](../handson/lecture-01/#standing-start) · reference `dyad/HandsOn/SlipCar.dyad`

<!--
**Say:** Every part in this car is one you already have. Only the wiring
is new. The new wheel is the contact with the road: its `flange` (road contact) connects
straight to the body. This is a new car, `SlipCar`, not an edit of `Car`.

**Timing:** 23 minutes: 3 for the "two limits" slide, then 20 to build: 10 parts, 5 ports
and 15 wires. The page lists the wires as a numbered table; tell the room to tick them off.
Order: create the car, then its five parameters, then the parts, then the wires, then a
separate *bench* (a small test model that feeds fixed inputs into the car).

**Words in this step:** *wheelspin* = the wheel turning much faster than the
car moves. *Standing start* = full throttle from a stop.
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
**Say:** The push to the road passes through two things in a row: the
engine and the tire. The lower of the two limits decides. You can tell which one it is
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
4. **On the curve:** 1935 / 6865 = 0.28. The red dashed line on step 08's
   "Slip, and how grip depends on it" slide is at μ = 0.28: under the whole dry curve,
   over the whole snow curve. On the dry road it needs only κ ≈ 0.0075; step 09's check
   reads 0.0076 under the same 1935 N.

**Snow or ice?** The bench students build uses `friction` 0.2, the
"snow" row of the table. Later slides call the same run "ice". It is the same run: say
"slippery road" if a student asks.

**The three predictions on the right:**

- 21 km/h dry: the tire barely slips, so this car behaves like the step 05 car, which also
  read 21.2 km/h at 5 s.
- 10 km/h and 1500 km/h on snow: read off the reference simulation, not worked out on
  paper. The table only says the wheel *must* spin.

**Why it runs away:** once past the peak, extra slip lowers the grip. Less
grip means less force holding the wheel back, so the engine spins it faster, which is more
slip. Each change makes the next one bigger. This comes from the tire curve, not from
anything we built.

**On the 1500 km/h:** a rev limiter is the part of a real engine that cuts
power at a maximum engine speed. The model has none, so nothing stops the wheel. For
scale: 1500 km/h at the tire is the engine turning at about 51 000 rpm (through gear 4 and
the 0.31 m radius). That number follows from what we left out; it is not a bug. Say it now
so nobody tries to "fix" it when it appears on their plot.

**Flag forward:** the next lecture ends here. A cruise control on ice sees
the speed drop and asks for more torque, with the result this table predicts. That is
why real cruise control switches off when traction control (a system that cuts power when a
driven wheel spins) steps in.
-->

---

## Two speeds out

![SlipCar: engine, gear, wheel inertia and slip wheel drive the grade body, with sensors for vehicle speed and wheel surface speed.](/img/step10-standing-start.png)

*`v_kmh` from the body · `wheel_kmh` from the wheel shaft,
× r × 3.6 · tire `radius = r`, `F_z = m * g / 2` · bench: `cmd` 150, `road` 0, `friction` 0.2*

<!--
**Point at:** `r` is used twice (the tire's radius and the
km/h gain), and `m` sets both the body's mass and the axle load. One parameter
each, so they cannot disagree. If the value were typed twice, changing one copy would
leave the other wrong without any error.

**Say:** The wheel's surface speed is its spin times its radius. Put that
on the same axis as the car's speed, and wheelspin is the gap between the two
lines.

**The caption, decoded:**

- `v_kmh`: car speed, from a speed sensor on the body, × 3.6 to get km/h.
- `wheel_kmh`: tire surface speed, from a turn-rate sensor on the wheel shaft,
  × r × 3.6 (r = 0.31 m).
- The five parameters, typed once on the car: `i = 4.0` (gear), `J_w = 1.0` (wheel
  inertia), `r = 0.31`, `m = 1400`, `g = 9.80665`.
- The bench `SlipCarStandingStart` holds the car and three constant blocks: `cmd` 150
  (full throttle, N·m), `road` 0 (flat), `friction` 0.2 (slippery; 1.0 is dry).

**Then:** in the bench's code, at the end of `relations`, five `initial`
lines set the starting values (position, speed, engine, wheel angle, wheel speed all
zero). The page has them under "Starting state". Save; nothing in **Problems**.

**They get wrong:** missing `initial car.wheel_inertia.w = 0`.
With slip, wheel speed is no longer tied to car speed, so it needs its own start.
If `Problems` lists `SlipCar`, compare the wires with the page's numbered table.
-->

---
routeAlias: wheelspin
---

## 1500 km/h at the tire, 10 km/h on the road

<div class="grid grid-cols-2 gap-8">
<div>

```julia [Julia REPL]
using Plots
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
keeps applying 150 newton-meters to a wheel with little grip to resist it. The 1500
kilometers per hour follows from that missing limit. It is not a bug.

**How to run it:** with `SlipCarStandingStart` open, press ▷
(**Run Analysis**, editor title bar) → **TransientAnalysis**. Name it
`SlipCarStandingStartTransient`, set `stop` to 5. Run it with ▷ in the **Analyses**
panel, then type the first three lines on the slide into the Julia REPL.

**Expected on screen** (the reference test checks these, within 0.1 km/h for the car and
0.5 km/h for the wheel):

- Slippery (friction 0.2): after 1 s, car 1.94 km/h and wheel surface already 159.8 km/h.
  After 5 s, car **10.12 km/h**, wheel **1501 km/h**. Blue line is the car, orange the wheel.
- Dry (friction 1.0): after 5 s, car 21.08 km/h, wheel 21.24 km/h. The lines lie on top of
  each other.

**Then the dry run:** `friction__k = 1.0` means "the `k` of the
block named `friction`". It changes the constant for this run without editing the model.
Students can instead set `friction`'s `k` to 1.0 in the bench, save and run again. Twice
the speed of the slippery car, and the two lines stay together.

**If a result differs:**

- Car goes backward: the sign on `flange.f` in `SlipWheel1D` (step 09).
- Both lines together on the slippery run: the bench's `friction` is still 1.0. Set it
  back to 0.2.
- Error that `SlipCarStandingStartTransient` is not defined: rename the word after
  `analysis` in the analysis code.

Commit: `Step 10: standing start`.

**Close:** this matches the "two limits" table from the start of this step:
on snow the tire reaches its limit before the engine does. The PID lecture ends with this car
under cruise control on an ice patch. The controller sees speed falling, commands more
torque, and produces what you just watched. That is the argument for traction
control, and for the cascade control of lecture 2 (one controller inside another; lecture 2
explains it, you do not need to).
-->

---

## Predicted values, step by step

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
**Say:** This slide collects the session's results. Every number in the
middle column was worked out on paper at the start of its step. Where a run agreed, the model was
right. Where it did not, something in the model was wrong, not the arithmetic.

**Where each number comes from**, so you can answer "why that number?":

- **02** — the bench asks for 200 N·m at 0.5 s; the engine waits 0.3 s, so nothing until 0.8 s. Then the torque rises gradually (time constant 0.3 s): 200·(1 − e<sup>−0.2/0.3</sup>) = 97 at 1.0 s. It reaches the 150 N·m ceiling at 0.8 + 0.3·ln 4 = 1.22 s. Step 02.
- **03** — torque × gear 4 ÷ wheel radius 0.31 m: 100 × 4 / 0.31 = 1290 N; ÷ 1400 kg = 0.92 m/s². Step 03.
- **04** — top speed is where the push equals air drag (0.378·v²) plus rolling resistance (165 N): 500 = 0.378·v² + 165 → v = 29.78 m/s. Step 04.
- **05** — the same balance with the engine's 1935 N: 1935 − 165 = 1770 = 0.378·v² → 68.4 m/s = 246 km/h. The time to 100 km/h (23.6 s) is read off the reference simulation, as is 143 s, when the car reaches 99 % of its top speed. Step 05.
- **06** — the spinning wheel acts like J/r² = 1 / 0.31² ≈ 10 kg of extra mass, 0.7 % of the car → 23.6 × 1.007 = 23.8 s. Step 06.
- **07** — 1400 × 9.81 × sin(arctan 0.1) = 1366 N. Step 07.
- **08** — the curve's own parameters. Step 08.
- **09–10** — snow limit 1373 N &lt; engine 1935 N, so the wheel must spin; the 10 and 1500 km/h are read off the reference simulation. Step 10.

**Point at:** step 05, the milestone. Two independent methods, the equation
on paper and the model you built, give the same number.
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
car responds: with a delay, slowly, against air drag that grows with the square of speed,
and on snow, barely at all. In the next lecture we add the controller that measures the
speed and sets the pedal.

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

**Plain words:** a *pull request* is a request on GitHub to merge one
branch into another; reviewers comment on it. The *branch* `handson-01` is the separate
line of work students created at the start of the session; `main` is the original.
**Sync Changes** (in **Source Control**) uploads local commits to GitHub.

**On github.com:** a yellow bar says `handson-01` had recent pushes, with
the **Compare &amp; pull request** button. No bar: **Pull requests** → **New pull request**,
base `main`, compare `handson-01`.

**Checkpoint:** the **Commits** tab lists one commit per step, named
`Step 07: grade`, `Step 08: tire curve` and so on. A missing commit means that step was
not committed or not synced: commit, **Sync Changes**, and it appears in the same pull
request.

**They get wrong:** merging their own pull request. If it happened, it is
not lost — the commits are on `main` — but the pull request is gone, so the
review has nothing to comment on. Note who it was and sort it out with them after the
session.
-->
