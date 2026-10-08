---
routeAlias: driveline
layout: section
---

###### Step 03 · 13 min

# Driveline

Shaft torque in, force on the car out: F = T · i / r.

[page: step 03](../handson/lecture-01/#driveline) · reference `dyad/HandsOn/Driveline.dyad`

<!--
**Say:** This step has two parts and four ports. This is where rotation
becomes straight-line motion.

**Timing:** 13 minutes: 3 for the formula, 10 building. No bench, no analysis — it is checked when the car
runs in step 05.
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
**Say:** Here are two steps, and everyone has felt both. First, a bicycle
in a low gear: you pedal fast, the wheel turns slowly, and climbing is easy. The gear
trades speed for force. Second, a wrench: the longer the handle, the less force you need
for the same twist. The wheel is a wrench the other way around: the twist at the axle
becomes a force at the rim, and a bigger wheel means less force.

**Derivation, step by step**

1. Gear: torque × i, speed ÷ i. An ideal gear loses no energy, so power in = power out:
   T·ω<sub>engine</sub> = T<sub>wheel</sub>·ω<sub>wheel</sub>. With
   ω<sub>engine</sub> = i·ω<sub>wheel</sub>, that gives T<sub>wheel</sub> = i·T.
2. Wheel: torque = force × radius, so the force at the road is
   F = T<sub>wheel</sub> / r.
3. Together: **F = T·i / r**.

**The numbers:** 150 × 4 = 600 N·m at the wheel; 600 / 0.31 = 1935 N.
100 × 4 / 0.31 = 1290 N; 1290 / 1400 = 0.921 m/s², which the step-03 reference test
checks.

**Engine speed, for the "246 km/h is wrong" slide later:** the wheel rolls
without sliding, so one turn moves the car 2πr. Wheel angular speed ω = v / r = 25 / 0.31 =
80.6 rad/s. Engine: × 4 = 322.6 rad/s. To rpm: × 60 / 2π = 3080 rpm.

**They get wrong:** "150 N·m is a weak engine". Do the multiplication out
loud: almost 2 kN at the road, about the weight of 200 kg.

**Ask the room:** the wheel "rolls without sliding" — which step will
break that? *(Step 08, on snow.)*
-->

---

## Gear, rolling wheel, four ports

![Driveline: spline into an ideal gear, then an ideal rolling wheel out to the flange, with both supports brought out.](/img/step03-driveline.png)

*parameters `i` = 4.0, `r` = 0.31 · `gear` IdealGear(ratio = i) → `wheel` IdealRollingWheel(radius = r) ·
gray circles are rotational ports, green squares translational*

<!--
**Point at:** the wheel block. Gray circle in, green square out — the port
shapes tell you the domain, and you can only wire like to like.

**Say:** A torque of 100 newton-meters, times a gear ratio of 4, divided
by a wheel radius of 0.31 meters, gives 1290 newtons. On a 1400-kilogram car that is
0.9217 meters per second squared, which is what the reference test checks.

**They get wrong:** forgetting the reaction paths. The gear housing and the
road both push back; `gear.support` and `wheel.support_r` go to
`support_r`, `wheel.support_t` to `support_t`. The car
grounds them in step 05.
-->
