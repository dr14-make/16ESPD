---
theme: default
title: Stop Without Locking — Lecture 3 hands-on
canvasWidth: 1280
aspectRatio: 1280/760
routerMode: hash
transition: none
routeAlias: title
layout: cover
---

# Stop without locking

<h1 class="!text-5xl !-mt-4 opacity-70">Lecture 3 hands-on</h1>

Vehicle Systems &amp; Components · about 90 minutes

<div class="mt-8 text-xl">

Brake your car hard on one wheel, watch it lock, write an ABS of your own, then take away its
knowledge of the car's speed.

Follow the guide: **[handson/lecture-03](../handson/lecture-03/)**

</div>

<!--
Runs after the 90-minute theory session on the lecture-03 deck. Every checkpoint is a number
from that deck or one the students compute in step 01; the theory slide each step puts into
practice is named in its notes.

Budget: 8 + 7 + 15 + 22 + 25 + 10 + 3 = 90 min. If the room is behind at 45 min, skip step 03 A
(go straight to the look-ahead) and run step 05 from the reference models.

Reference solutions: dyad/HandsOn03/ in the course repository. Checkpoint tests:
test/abs_handson_plausibility.jl, testsets "Hands-on 03 …".
-->

---
routeAlias: setup
---

###### Step 00 · 8 min

## Set up

<div class="grid grid-cols-[1.3fr_1fr] gap-10 items-start">
<div>

**Goal:** a `handson-03` branch on your `MyCar`, with the Lecture 3 course library.

**Given:** the course library, pinned to a tag. **Built:** nothing.

```julia
# in MyCar, on a new branch handson-03 from main
using Pkg
Pkg.add(url = "https://github.com/dr14-make/16ESPD",
        rev = "TODO-TAG")   # ← decision D7: tag not cut yet
```

Then <kbd>F1</kbd> → `Dyad: Compile`.

[Guide: step 00 →](../handson/lecture-03/#setup)

</div>
<div>

> **Checkpoint**
>
> `using VehicleSystemsComponents` runs without an error.
>
> **+** → `VehicleSystemsComponents › Vehicle › Wheel` lists `BrakedWheel`, `BrakeActuator`,
> `TireFrictionCurve`; `Vehicle` lists `ABSPressureIntegrator`.

**Stuck?** No hands-on 2 branch: start from `main` — this session needs only hands-on 1's `Body`.

</div>
</div>

<!--
The tag replaces hands-on 2's branch pin (feat/lecture02-theory-deck), which has no Wheel module.
If the tag carries MultibodyComponents (planar car merged first), ask students to run this step
before the session: the first compile then takes about a minute longer.

TODO before the session: replace TODO-TAG with the rehearsed tag, and add the screenshot
step00-wheel-library.png.
-->

---
routeAlias: limits
---

###### Step 01 · 7 min

## The tire's limit, by hand

<div class="grid grid-cols-[1fr_1fr] gap-10 items-start">
<div>

**Goal:** the three numbers every later run is judged by, before anything runs.

**Given:** 1400 kg on one lumped wheel, *r* = 0.31 m, 90 km/h = 25 m/s; your
`TireFrictionCurve`: peak *μ*<sub>A</sub> = 1.0 at 4 % slip, sliding *μ*<sub>S</sub> = 0.7 from 12 %.

*F*<sub>z</sub> = *m g* · *T*<sub>peak</sub> = *μ*<sub>A</sub> *F*<sub>z</sub> *r* ·
*d* = *v*² / (2 *μ g*)

[Guide: step 01 →](../handson/lecture-03/#limits)

</div>
<div>

> **Checkpoint**
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
Theory: tire-is-not-a-block, braking-distance, abs-model (the plant numbers).

Students who reach for the REPL: 25^2 / (2 * 1.0 * 9.80665) and so on. The peak distance is the
floor no ABS beats; the sliding distance is roughly what a locked wheel gives.
-->

---
routeAlias: locked
---

###### Step 02 · 15 min

## Lock the wheel

<div class="grid grid-cols-[1fr_1.15fr] gap-8 items-start">
<div>

**Goal:** your `Body` on the library wheel; a 6000 N·m step at 0.5 s locks it.

**Given:** `Vehicle.Wheel.BrakedWheel`. **Yours:** `Body` (hands-on 1). **Built:** bench
`LockedStop`, drawn — 6 blocks, 5 wires:

<div class="text-sm">

```txt
demand = Step(height = 6000, start_time = 0.5)  → wheel.tau_cmd
road   = Constant(k = 1)                         → wheel.mu_scale
wheel.support → fixed.spline         (RotationalComponents Fixed)
wheel.flange  → body.flange, speed.flange      (VelocitySensor)
initial wheel.brake.tau_actual = 0
initial wheel.inertia.phi = 0
initial wheel.inertia.w = 25 / 0.31
initial body.mass.s = 0
initial body.mass.v = 25
```

</div>

[Guide: step 02 →](../handson/lecture-03/#locked)

</div>
<div>

![Two panels against time. Top: car speed falls in a straight line from 90 km/h at 0.5 s to zero at about 4 s, while the wheel's surface speed drops to zero within 0.17 s. Bottom: wheel slip goes from 0 to -1 at about 0.67 s and stays there until the car stops. Title: locked stop, 43.7 m from 90 km/h.](/img/step02-locked-stop.svg)

> **Checkpoint** · `wheel.kappa` = **−1** by 0.67 s · at rest at **4.0 s** ·
> `Vehicle.braking_distance(sol)` = **43.7 m**, just short of 45.5 m

</div>
</div>

<!--
Theory: braking-distance, one-stop.

Where they stall: the five initial lines. Forgotten, the wheel starts at 0 rad/s and the plot is a
wheel spinning up, not a stop. The guide gives the lines to paste.

Analysis: LockedStopTransient, stop 6 s, Tsit5 (never FBDF). In the REPL:
  sol = MyCar.LockedStopTransient()
  VehicleSystemsComponents.Vehicle.braking_distance(sol)

Why 43.7 and not 45.5: the wheel is not locked for the first 0.17 s, and drag and rolling
resistance help. The reference equals Vehicle.LockedBrakeTransient to 1e-6 at μ 1.0, 0.5, 0.3.
-->

---
routeAlias: slip-abs
---

###### Step 03 · 22 min

## An ABS of your own

<div class="grid grid-cols-[1fr_1.15fr] gap-8 items-start">
<div>

**Goal:** dump pressure when the slip passes the peak; then when it *will* pass it 30 ms from now.

**Given:** `Vehicle.ABSPressureIntegrator` (clips to [0, demand]). **Built:** `SlipABS` in code;
bench `ABSStop` = `LockedStop` + `abs` between `demand` and `wheel`, two wires in:
`wheel.kappa`, `speed.v`.

<div class="text-sm">

```txt
# A: inputs kappa, v, demand; output tau_cmd
pressure = VehicleSystemsComponents.Vehicle.ABSPressureIntegrator(T_track = 0.01)
...
connect(demand, pressure.demand)
pressure.requested_rate = ifelse(kappa_pred < -lambda_target, -k_dec, k_inc)
pressure.active = ifelse(v > v_min, 1.0, 0.0)
connect(pressure.tau_cmd, tau_cmd)
# C: look-ahead T_p = 0.03, filter T_f = 0.003
der(kappa_f) = (kappa - kappa_f) / T_f
kappa_dot = (kappa - kappa_f) / T_f
kappa_pred = kappa + T_p * kappa_dot
```

</div>

[Guide: step 03 →](../handson/lecture-03/#slip-abs)

</div>
<div>

![Two panels against time for the two ABS runs. Top, brake torque: without look-ahead it saws between about 600 and 4700 N·m roughly every 0.38 s; with the 30 ms look-ahead it holds near 4300 to 4400 N·m, just above the dotted 4256 N·m tire peak, until 3 s, then goes to 6000. Bottom, slip: without look-ahead each cycle dives past the -0.12 sliding line to -0.2 and deeper; with it the slip sits on the -0.04 peak line until the ABS switches off near 3 s.](/img/step03-abs-torque-slip.svg)

> **Checkpoint** · A, `T_p = 0`: **53.8 m**, *longer* than locked; 26 % of the time sliding,
> 2.6 Hz · C, `T_p = 0.03`: **34.4 m**, 21 % shorter; slip at **−0.04**, 31 Hz

</div>
</div>

<!--
Theory: modulator (build and dump are the two signs of the rate), abs-cycle, abs-model
(look-ahead), one-stop, on-the-curve.

A first (kappa_pred = kappa, i.e. T_p = 0), run, read the distance; then add the three look-ahead
lines and run again. Run A loses to the locked wheel: not a mistake. The slip law reacts to the
slip now, but the brake follows 30 ms later; by then the wheel is past 12 % and the dump comes
too late, every cycle. That is the findings document's result and the reason for the
look-ahead.

C is the library's ABSIdealController equation for equation: ABSStopTransient equals
Vehicle.IdealBrakeTransient to 1e-6. The torque sits a little above 4256 N·m, not below: the
brake also decelerates the wheel's inertia. The ABS switches off below 1.5 m/s (3.0 s) and the
wheel locks just before standstill, as a real ABS does. abs.tau_cmd ≤ demand throughout.

Stuck in the code view: the full SlipABS source is in the guide's "Stuck?" block. Rehearse
whether Studio keeps the pressure placement and the nested ifelse.
-->

---
routeAlias: wheel-only
---

###### Step 04 · 25 min

## Only the wheel speed

<div class="grid grid-cols-[1fr_1.1fr] gap-8 items-start">
<div>

**Goal:** an ABS fed only from a wheel-speed sensor, with the cycle a real ECU runs: dump, hold,
build slowly from where the hold left the pressure.

**Built:** `RefSpeedEstimator` and `PhaseABS` (a copy of `SlipABS`) in code; bench
`ABSStopWheelOnly` = `ABSStop` with `abs` = `PhaseABS`, a `wspeed` sensor on `wheel.spline`
→ `est`, and `est` → `abs` for `kappa`, `a_w`, `v`.

<svg viewBox="0 0 520 250" class="w-full" role="img" aria-label="State diagram of the three phases. Build, slowly at 8000 N·m/s, goes to dump when the wheel decelerates faster than 12 m/s² or the estimated slip passes 0.2. Dump, at 40000 N·m/s, goes to hold when the wheel accelerates faster than 3 m/s², or back to build once neither dump condition holds. Hold, rate zero, goes to build when the wheel acceleration falls below 3 m/s². Before the first dump the demand passes straight through.">
  <defs>
    <marker id="arr" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M0 0 L10 5 L0 10 z" fill="currentColor"/>
    </marker>
  </defs>
  <g text-anchor="middle" fill="currentColor" style="font-size:15px">
    <text x="18" y="22" text-anchor="start" opacity="0.7" style="font-size:13px">start: demand passes through</text>
    <line x1="78" y1="30" x2="78" y2="58" stroke="currentColor" marker-end="url(#arr)"/>
    <rect x="18" y="60" width="120" height="54" rx="10" fill="#2e8b57" fill-opacity="0.25" stroke="#2e8b57" stroke-width="2"/>
    <text x="78" y="84" font-weight="bold">BUILD</text>
    <text x="78" y="103" style="font-size:13px">+k_inc, slow</text>
    <rect x="382" y="60" width="120" height="54" rx="10" fill="#b22222" fill-opacity="0.25" stroke="#b22222" stroke-width="2"/>
    <text x="442" y="84" font-weight="bold">DUMP</text>
    <text x="442" y="103" style="font-size:13px">−k_dec</text>
    <rect x="200" y="182" width="120" height="54" rx="10" fill="#daa520" fill-opacity="0.25" stroke="#daa520" stroke-width="2"/>
    <text x="260" y="206" font-weight="bold">HOLD</text>
    <text x="260" y="225" style="font-size:13px">rate 0</text>
    <line x1="140" y1="74" x2="380" y2="74" stroke="currentColor" marker-end="url(#arr)"/>
    <text x="260" y="66" style="font-size:13px">a_w &lt; −a_minus  or  kappa &lt; −lambda_1</text>
    <line x1="380" y1="102" x2="140" y2="102" stroke="currentColor" stroke-dasharray="5 4" marker-end="url(#arr)"/>
    <text x="260" y="120" opacity="0.8" style="font-size:13px">no dump condition (dry road)</text>
    <line x1="430" y1="116" x2="322" y2="196" stroke="currentColor" marker-end="url(#arr)"/>
    <text x="432" y="168" style="font-size:13px">a_w &gt; +a_plus</text>
    <line x1="198" y1="196" x2="90" y2="116" stroke="currentColor" marker-end="url(#arr)"/>
    <text x="88" y="168" style="font-size:13px">a_w &lt; +a_plus</text>
  </g>
</svg>

</div>
<div>

<div class="text-sm">

```txt
# RefSpeedEstimator: add output a_w; T_f = 0.005
initial v_f = v0
der(v_f) = (v_w - v_f) / T_f
a_w = (v_w - v_f) / T_f

# PhaseABS: inputs kappa, a_w, v, demand; output tau_cmd
# a_minus 12, a_plus 3, lambda_1 0.2,
# k_dec 40000, k_inc 8000, v_min 1.5, T_latch 0.001
phase = ifelse(a_w > a_plus, 0,
               ifelse(a_w < -a_minus or kappa < -lambda_1, -1, 1))
initial cycled = 0
der(cycled) = ifelse(phase < -0.5, (1 - cycled) / T_latch, 0)
pressure.requested_rate = ifelse(phase < -0.5, -k_dec,
                                 ifelse(phase < 0.5, 0, k_inc))
pressure.active = ifelse(v > v_min and cycled > 0.5, 1.0, 0.0)
```

</div>

HOLD is the pressure memory: after a dump the pressure stays just under the level that was too
much, and the next build starts there, not from zero.

[Guide: step 04 →](../handson/lecture-03/#wheel-only)

</div>
</div>

<!--
Theory: wheel-speed-sensors ("the ABS measures only this"), reference-speed, the modulator and
state-machine slides (the inlet and outlet valve: both open is build, both shut is hold, outlet
open is dump), abs-distance.

Why this controller and not step 03's on an estimated slip: fed from the estimator, the step 03
law stops in 46.9 m, longer than locked, at any a_ref. After each dump it rebuilt from almost
nothing at a fixed rate, so the slip crept up unseen until the wheel dived. Two changes fix it.
The dump is triggered by the wheel's own deceleration, which needs no estimate of the car's
speed: a rolling wheel cannot decelerate faster than the car, about 9.8 m/s² on a dry road, so
12 m/s² means the tire has gone past its peak. And the hold keeps the pressure where the dump
left it, so the slow build starts close to the right level.

The estimated slip only catches a wheel that is already locked (a_w = 0 there). cycled is a
latch: until the first dump the integrator is inactive and passes the demand through, which is
the fast first build; after it, builds are slow.

Students who are behind: give them PhaseABS from the guide's "Stuck?" block and let them write
only the estimator lines.
-->

---
routeAlias: wheel-only-cycle
---

###### Step 04 · checkpoint

## Dump, hold, build

<div class="grid grid-cols-[1.3fr_1fr] gap-8 items-start">
<div>

![Two panels from 0.9 to 1.45 s of the wheel-speed-only stop at road mu 0.5. Top, brake torque: the command climbs slowly in the green build phases from about 1800 to 2500 N·m, drops in the short red dump phases, and stays flat in the amber hold phases; the torque at the wheel follows it smoothly between 2000 and 2300 N·m. Bottom, speed: the car falls steadily from 82 to 72 km/h, the wheel runs about 3 km/h below it with small dips, and the estimate rides the wheel. Title: your three-phase ABS, wheel speed only, mu 0.5, 69.8 m.](/img/step04-phase-cycle.svg)

</div>
<div>

> **Checkpoint** · μ 1: **35.5 m**, shorter than locked (43.7 m) and than the library's
> clocked ECU (38.7 m), 1 m from the true-slip 34.4 m · μ 0.5: **69.8 m** against 85.1 locked
>
> On μ 0.5 the cycle runs build → dump → hold, about 5 dumps a second; `abs.pressure.p` is flat
> in every hold · on a dry road the dump ends before the wheel turns round: dump and build only,
> 10 a second

Plot `abs.phase`, `abs.tau_cmd` and `wheel.brake.tau_actual` together.

</div>
</div>

<!--
The hold shows on wet and snow, where a dump lets the wheel spin back up past +3 m/s². On a dry
road it is so short that the wheel only stops decelerating, so the cycle is dump and slow build.
Both are the pressure memory: the build starts from the held level.

On a dry road a_ref = 8 is below the car's deceleration, so est.v_ref runs above the car; from
about 1.9 s the estimated slip passes 0.2 although the true slip is 4 %, and the slip trigger
dumps. That costs about 2 m (a_ref = 10 gives 33.6 m). On wet and snow a_ref = 8 is above the
car's deceleration and the estimate rides the wheel, below the car. Step 05 picks this up.

A hydraulic version, with the inlet and outlet valves of a real modulator in place of the rate
integrator, is a stretch goal for whoever finishes early; the library plan for it is
docs/brake-system-implementation-plan.md, step 3.
-->

---
routeAlias: surfaces
---

###### Step 05 · 10 min

## Across road surfaces

<div class="grid grid-cols-[1fr_1.25fr] gap-8 items-start">
<div>

**Goal:** one table from the REPL; then the `a_ref` trap on snow, and what `a_ref` does to yours.

<div class="text-sm">

```julia
using VehicleSystemsComponents: Vehicle
stop(μ; a = Inf) = 0.5 + 1.5 * 25 / min(0.7μ * 9.81, a) + 1
for μ in (1.0, 0.5, 0.3)
    d(run) = round(Vehicle.braking_distance(run); digits = 1)
    println(μ, "  ",
        d(MyCar.LockedStopTransient(road_mu = μ, stop = stop(μ))), "  ",
        d(MyCar.ABSStopTransient(road_mu = μ, stop = stop(μ))), "  ",
        d(MyCar.ABSStopWheelOnlyTransient(road_mu = μ, stop = stop(μ; a = 8))))
end
```

</div>

Then μ 0.3 with `a_ref = 0.8 μ g ≈ 2.4`, and the same `a_ref` on a dry road.

[Guide: step 05 →](../handson/lecture-03/#surfaces)

</div>
<div>

![Grouped bars of braking distance from 90 km/h at road mu 1.0, 0.5 and 0.3. Locked: 43.7, 85.1, 136.8 m. ABS on true slip: 34.4, 63.4, 102.2 m. ABS on wheel speed only, yours: 35.5, 69.8, 119.6 m. ABS on wheel speed only, the library's clocked ECU: 38.7, 83.2, 141.3 m, the last longer than locked.](/img/step05-surfaces.svg)

> **Checkpoint** · both ABS columns of yours beat locked everywhere · on snow the library ECU
> loses to the locked wheel, **141.3 vs 136.8 m**; with `a_ref = 2.4` it stops in **128.4 m** ·
> yours, with `a_ref = 2.4`: **124.1 m** on snow, *longer* than at 8, and **105.4 m** on a dry
> road

</div>
</div>

<!--
Theory: abs-surfaces, reference-speed (the trap).

The first two columns are the deck's and must come out of the students' models exactly. The
library column comes from Vehicle.ABSBrakeTransient(road_mu = μ, stop = …), run from the REPL.

The trap is the clocked ECU's: a_ref = 8 m/s² is almost three times what μ 0.3 allows (2.9),
so its estimate falls too fast, it under-reads the slip and lets the wheel slide. The students'
PhaseABS does not fall into it (119.6 m, under the locked 136.8): it dumps on the wheel's own
deceleration, which needs no estimate of the car's speed.

Their a_ref = 2.4 rerun shows the other side of the same knob: an a_ref below the car's real
deceleration (about 0.9 μ g with ABS) lets the estimate run above the car, the estimated slip
passes lambda_1 although the tire is at its peak, and the controller dumps on slip that is not
there: 124.1 m on snow, 105.4 m on a dry road. One sentence on why: an ABS can only be as good as
its guess of the car's speed, so a wheel-speed-only ECU leans on the wheel's deceleration and
uses the guess only to catch a locked wheel.
-->

---
routeAlias: hand-in
---

###### 3 min

## Hand in: a pull request

**Goal:** a pull request from `handson-03` into the branch you started from, with your step 05
table in its description and one sentence on why the library's wheel-speed-only ABS loses its
gain on snow and yours does not.
Do *not* merge it.

> **Checkpoint**
>
> The pull request's **Commits** tab lists one commit per step.

[Guide: hand in →](../handson/lecture-03/#hand-in)

<!--
The sentence to look for: the controller does not know the car's speed, it assumes the car slows
at a_ref; when the road does not match that guess the estimate runs away from the truth and the
slip it acts on is wrong. The library ECU acts on that slip; theirs mostly on the wheel's
deceleration, which is why it keeps its gain on snow.
-->

---
routeAlias: tcs
---

###### Step 06 · bonus, extra points

## Traction control

**Goal:** hands-on 1's `SlipCar` on snow (`mu_scale = 0.2`), full torque from rest: without TCS
the wheel spins up as in Lecture 1; with a brake-based TCS it holds near the peak and the car is
faster after 10 s.

**Given:** `Vehicle.Wheel.BrakeActuator`, `Vehicle.ABSPressureIntegrator`. **Built:**
`TCSSlipCar` (your `SlipCar` with a brake between `wheel_inertia` and `wheel`, its support on
`rot_ground`, a `tau_tcs` input); `TCS`, step 03's law turned round: pressure builds while
`kappa_pred > lambda_target`, falls otherwise, clipped to [0, `tau_tcs_max`].

> **Hand in** with your pull request
>
> - wheel slip and car speed over 10 s, with and without TCS; by hand, the traction limit is
>   0.2 × 6865 N = **1373 N** at the peak against **961 N** spinning, about **8.5 against 5.7 m/s**
>   after 10 s
> - one paragraph: why a production TCS cuts engine torque when both driven wheels spin, what
>   `SlipCar`'s 0.3 s engine delay would do to that loop, and why the brake works on one wheel
>   only through an open differential

[Guide: step 06 →](../handson/lecture-03/#tcs)

<!--
Theory: what-tcs-does, tcs-actuators, tcs-and-lecture-1.

The reference solution is kept off main, on branch feat/handson03-tcs-bonus (not built yet), as
the hands-on 2 WLTC bonus was. Students get the task, the parts and the advice, not the diagram.
The 8.5 and 5.7 m/s are hand estimates: net of resistance, about 0.85 against 0.57 m/s².
-->

---
routeAlias: wrap-up
---

## What you measured

| Step | What | Number | From |
| --- | --- | --- | --- |
| 01 | the tire's limit | 4256 N·m · 31.9 to 45.5 m | by hand |
| 02 | the locked wheel | 43.7 m, at rest at 4.0 s | your `Body`, the library wheel |
| 03 | ABS on the present slip | 53.8 m, longer than locked | 30 ms too late each cycle |
| 03 | ABS with a 30 ms look-ahead | 34.4 m, 21 % shorter | the lag led |
| 04 | ABS on the wheel speed only | 35.5 m yours · 38.7 m library | dump, hold, build slowly |
| 05 | on snow, μ 0.3 | 136.8 · 102.2 · 119.6 · 141.3 m | locked · true slip · yours · library |

The controller that knows the slip wins on every road. Without the car's speed, an ABS trusts
the wheel's own deceleration and remembers the pressure; where it trusts a poor guess of the
speed instead, it can stop longer than a locked wheel.

<!--
The deck's four claims, each tested on the students' own parts: a locked wheel stops on the
sliding friction (02); ABS holds the tire near its peak and stops shorter (03 C); the controller
must lead the 30 ms lag (03 A against C); without the car's speed it must estimate it, which
costs little on a dry road and about half the gain on snow (04, 05).
-->
