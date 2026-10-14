---
routeAlias: driveline
layout: section
---

###### Step 03 · 13 min

# Driveline

Shaft torque in, force on the car out: F = T · i / r.

[page: step 03](../handson/lecture-01/#driveline) · reference `dyad/HandsOn/Driveline.dyad`

<!--
**Say:** This step has two parts and four ports. It turns the engine's turning into the
car's straight-line motion.

**Words for this step:**

- **Gear ratio** *i* = 4 — the engine turns 4 times for each turn of the wheel.
- **Rolling radius** *r* = 0.31 m — from the wheel's center to the road.
- **Rotational / translational** — turning motion / straight-line motion.
- **Ideal** gear and **ideal** rolling wheel — no friction losses, and the wheel never
  slides on the road.

**Timing:** 13 minutes: 3 for the formula, 10 building. No bench, no analysis — it is
checked when the car runs in step 05. The students' check today: the component saves with
nothing in the Problems tab, and it has the four ports.

**Tutor — order of work:** the student page lists "add the two parameters" as its first
step, but the component does not exist yet. Tell students to create `Driveline` first
(right-click MyCar → Add Component), then add the parameters.
-->

---
routeAlias: twist-to-push
---

## From a twist to a push: F = T · i / r

<div class="grid grid-cols-2 gap-8">
<div>

#### Step 1 — the gear multiplies the twist

The engine turns *i* = 4 times for every turn of the wheel. Like
a low bicycle gear: easier to turn, so the wheel gets **4 × the torque**
(and turns 4 × slower).

$$ T_{\text{wheel}} = i \cdot T $$

#### Step 2 — the wheel turns the twist into a push

Torque is force times lever arm. At the road the lever arm is the wheel
radius *r*, so T<sub>wheel</sub> = F · r:

$$ F = \frac{T_{\text{wheel}}}{r} = \frac{T\,i}{r} $$

</div>
<div>

#### With i = 4.0 and r = 0.31 m

| engine | × 4 | ÷ 0.31 m |
| --: | --: | --: |
| 100 N·m | 400 N·m | **1290 N** |
| 150 N·m | 600 N·m | **1935 N** |

1290 N on 1400 kg, nothing else acting: a = F/m =
**0.92 m/s²** — step 03's check.

#### Speeds go the other way

Wheel speed = v / r; engine speed = i × that. At 90 km/h: 25 m/s ÷ 0.31
× 4 = 323 rad/s = **3080 rpm**.

</div>
</div>

<!--
**Say:** There are two steps, and you have felt both. First, a bicycle
in a low gear: you pedal fast, the wheel turns slowly, and climbing is easy. The gear
trades speed for force. Second, a wrench: the longer the handle, the less force you need
for the same twist. The wheel is a wrench the other way around: the twist at the axle
becomes a force at the rim, and a bigger wheel means less force.

**Units:** N = newton, a force; 1 kN = 1000 N. N·m = newton-meter, a twist. rad/s =
turning speed in radians per second; one turn = 2π ≈ 6.28 rad. rpm = turns per minute.
ω ("omega") = turning speed.

**Derivation, step by step**

1. Gear: torque × i, speed ÷ i. An ideal gear loses no energy, so power in = power out:
   T·ω<sub>engine</sub> = T<sub>wheel</sub>·ω<sub>wheel</sub>. With
   ω<sub>engine</sub> = i·ω<sub>wheel</sub>, that gives T<sub>wheel</sub> = i·T.
2. Wheel: torque = force × radius, so the force at the road is
   F = T<sub>wheel</sub> / r.
3. Together: **F = T·i / r**.

**The numbers:** 150 × 4 = 600 N·m at the wheel; 600 / 0.31 = 1935 N.
100 × 4 / 0.31 = 1290 N; 1290 / 1400 = 0.92 m/s². 1400 kg is the car's mass (step 04).

**About "step 03's check":** students cannot see the 0.92 themselves today, because this
step has no bench. It is the result of the reference test `TestDriveline` in
`dyad/HandsOn/Driveline.dyad`: 100 N·m into a driveline pushing a 1400 kg mass. That test
expects 0.9217 m/s², and 9.2 m/s after 10 s.

**Engine speed** (step 05 uses it to explain why 246 km/h is unrealistic): 90 km/h ÷ 3.6
= 25 m/s. The wheel rolls without sliding, so one turn moves the car 2πr. Wheel speed
ω = v / r = 25 / 0.31 = 80.6 rad/s. Engine: × 4 = 322.6 rad/s. To rpm: × 60 / 2π =
3080 rpm.

**They get wrong:** "150 N·m is a weak engine". Do the multiplication out
loud: almost 2 kN at the road, about the weight of 200 kg.

**Ask the room:** the wheel "rolls without sliding" — which step will
break that? *(Steps 08–10: step 08 builds a tire that can slip, and in step 10 the wheel
spins on snow while the car crawls at about 10 km/h.)*
-->

---

## Gear, rolling wheel, four ports

![Driveline: spline into an ideal gear, then an ideal rolling wheel out to the flange, with both supports brought out.](/img/step03-driveline.png)

*parameters `i` = 4.0, `r` = 0.31 · `gear` IdealGear(ratio = i) → `wheel` IdealRollingWheel(radius = r) ·
gray circles are rotational ports, green squares translational*

<!--
**Point at:** the wheel block. Gray circle in, green square out: the port
shape tells you whether it is rotational (a turning shaft, Dyad calls it a spline) or
translational (straight-line, Dyad calls it a flange). You can only wire like to like.

**The four ports:** `spline` (left, from the engine), `flange` (right, to the car
body), `support_r` (the gearbox housing's mount), `support_t` (the road).

**Where to click:** click an empty spot of the canvas → **Add parameter** for `i` = 4.0
(type Real) and `r` = 0.31 (type Length). Then click `gear` and set `ratio` to `i`; click
`wheel` and set `radius` to `r` — the names, not the numbers.

**Say:** A torque of 100 newton-meters, times a gear ratio of 4, divided
by a wheel radius of 0.31 meters, gives 1290 newtons. On a 1400-kilogram car that is
0.92 meters per second squared, which is what the reference test checks.

**They get wrong:** forgetting the reaction paths. The gear housing and the
road both push back; `gear.support` and `wheel.support_r` go to
`support_r`, `wheel.support_t` to `support_t`. The car
grounds them in step 05.
-->
