---
routeAlias: slip-wheel
layout: section
---

###### Step 09 · 15 min

# A wheel that can slip

Cut the rolling constraint: wheel and car may now move at different speeds.

[page: step 09](../handson/lecture-01/#slip-wheel) · reference `dyad/HandsOn/SlipWheel1D.dyad`

<!--
**Say:** Up to now, the ideal rolling wheel forced the wheel's spin times
its radius to equal the car's speed. That is the assumption we drop. The difference
between the two speeds is slip, and the curve from step 8 turns slip into force.

**What students do:** **Components** → right-click `MyCar` →
**Add Component** → `SlipWheel1D`, ⇄ (switch to code), Ctrl+A, paste from the page, Ctrl+S.
It uses `TireFrictionCurve`, so step 08 must be saved in the same library.

**Expected:** nothing in the **Problems** tab. Switched back to the diagram,
it shows three ports (`spline`, `flange`, `mu_scale`) and a `curve` block with no wires.
That is correct. Commit: `Step 09: slip wheel`.

**Timing:** 15 minutes. Paste, then read: the page walks through every relation. Nothing
runs in this step; step 10 drives it.
-->

---

## Slip, grip, force

```julia
kappa = (omega * radius - v) / max(abs(v), v_eps)
curve.kappa = kappa
mu = mu_scale * curve.mu
F_x = mu * F_z
flange.f = -F_x
0 = spline.tau + radius * flange.f
```

- `v_eps` keeps κ finite at standstill.
- `mu_scale` is the road: 1 dry, 0.2 slippery.
- Flow is positive *into* a component: a tire pushing the car forward reports
  `flange.f = -F_x`.

<!--
**The six lines in plain words:**

1. Slip = (tire surface speed − car speed) ÷ car speed. `omega` is how fast the wheel
   turns, `radius` is 0.31 m, `v` is the car's speed.
2. Hand the slip to the step-08 curve.
3. Read the grip back, scaled for the road (`mu_scale`).
4. Push = grip × load. `F_z` is the load on the driven axle, half the car's weight,
   6865 N.
5. The push on the car, with the sign rule below.
6. The same push acts back on the wheel as a braking twist (radius × force). That is what
   holds the wheel back.

**Point at:** line 1. Dividing by the car's speed makes slip relative. At
a standstill v = 0, so the model never divides by less than `v_eps` = 0.5 m/s (1.8 km/h).

**Ports:** `spline` is the shaft connection from the gear; `flange` is the
contact with the car body; `mu_scale` is an input number for the road.

**The sign rule, plainly:** Dyad counts a force at a connection as positive
when it pushes *into* the component. The tire pushes the car forward, so it writes
`flange.f = -F_x`.

**They get wrong:** the sign on `flange.f`. With the wrong sign
the tire pulls the car backward and the car accelerates in reverse. That is the first
thing to check if step 10 looks strange.

**Point at the screenshot on the page:** `curve` has no wires.
It is connected by the equations `curve.kappa = kappa` and
`mu = mu_scale * curve.mu`, not by `connect` (a drawn wire). Both are valid.
-->

---

## What you are building

![SlipWheel1D: the curve block sits between the spline and flange ports with no wires; it is connected through equations.](/img/step09-slip-wheel.png)

- **135** slip after 5 s, μ × 0.2
- **0.0076** slip after 5 s, dry

<!--
**Say:** Same torque, two roads. On the dry road, slip stays under 1
percent. On the slippery road it runs up to 135. A slip of 135 means the tire surface
speed, minus the car's speed, is 135 times the car's speed. So the tire surface moves 136
times as fast as the car. The reference test for the slip wheel checks both cases.

**Where the two numbers come from:** the reference library's test,
`TestSlipWheel1D`. Students do not run it; they see the same effect in step 10. It drives
the wheel with a steady 600 N·m (the engine's 150 N·m × gear 4) for 5 s. The wheel has
1 kg·m² of inertia (resistance to being spun up), the car is a bare 1400 kg mass, with
no air drag and no rolling resistance.

| road | slip after 5 s | car speed after 5 s |
| --- | --: | --: |
| slippery, `mu_scale` 0.2 | 135 | 3.43 m/s (12.4 km/h) |
| dry, `mu_scale` 1 | 0.0076 | 6.86 m/s (24.7 km/h) |

**If asked why dry is 0.0076:** 600 N·m ÷ 0.31 m = 1935 N, which is
μ = 0.28 of the 6865 N load. The step-08 curve reaches 0.28 at a slip of about 0.0076.

**If asked why the slippery car is slower:** past the peak, the tire only
gives sliding grip, 0.7 × 0.2 = 0.14 of the load. The rest of the engine's push goes into
spinning the wheel.
-->
