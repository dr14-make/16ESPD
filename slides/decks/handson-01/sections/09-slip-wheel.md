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

**Timing:** 15 minutes. Paste, then read: the page walks through every relation. Nothing runs in this step — step 10 drives it.
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
**Point at:** line 1. Divide by the car's speed, so slip is relative —
except at a standstill, where v = 0, hence the floor.

**They get wrong:** the sign on `flange.f`. With the wrong sign
the tire pulls the car backward and the car accelerates in reverse. That is the first
thing to check if step 10 looks strange.

**Point at the screenshot on the page:** `curve` has no wires.
It is connected by the equations `curve.kappa = kappa` and
`curve.mu`, not by `connect`. Both are legal.
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
-->
