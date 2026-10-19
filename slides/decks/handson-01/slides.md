---
theme: default
title: Build the Car in Dyad — Lecture 1 hands-on
canvasWidth: 1280
aspectRatio: 1280/760
routerMode: hash
transition: none
routeAlias: title
layout: cover
---

# Build the car in Dyad

<h1 class="!text-5xl !-mt-4 opacity-70">Lecture 1 hands-on</h1>

Vehicle Systems &amp; Components · about 225 minutes

<img src="/img/car-chain.svg" class="!max-h-44 bg-white rounded p-2 mt-6" alt="The car as a chain of four parts: the pedal command goes into the engine, the engine's shaft into the gear and wheel, the wheel pushes the body along the road, and a speedometer reads the body's speed in km/h. Each part is labeled with the hands-on step that builds it.">

<div class="mt-6 text-xl">

Follow the guide: **[handson/lecture-01](../handson/lecture-01/)**

</div>

<!--
What to say, timings and where students stall: the tutor guide,
../handson/lecture-01/tutor.html
-->

---
routeAlias: ui
---

###### Part 1 · 15 min

## What you are looking at

<div class="grid grid-cols-[1fr_1.6fr] gap-8 items-start">
<div>

**Goal:** find the four controls you use all day, and see that a diagram and its code are one model.

1. **Components** — right-click → Add Component
2. **Analyses** — ▷ runs one
3. ▷ **Run Analysis**
4. ⇄ **Toggle Between Code and Diagram View**

[Guide: what you are looking at →](../handson/lecture-01/#ui)

</div>
<div>

![Dyad Studio with four numbered arrows: the Components and Analyses panels in the Dyad sidebar, and the Run Analysis and Toggle Between Code and Diagram View buttons in the editor title bar.](/img/dyad-studio-map.png)

</div>
</div>

<!--
Tutor guide: ../handson/lecture-01/tutor.html#ui
-->

---
routeAlias: library
---

###### Part 1 · 15 min

## Create your library

<div class="grid grid-cols-[1.4fr_1fr] gap-10 items-start">
<div>

**Goal:** an empty `MyCar` library, with the three standard libraries the car is built from, and Plots.

> **Checkpoint**
>
> The terminal finished without errors, and `MyCar` is in the **Components** panel.
>
> `Project.toml` lists `BlockComponents`, `RotationalComponents`, `TranslationalComponents`
> and `Plots` under `[deps]`.

[Guide: create your library →](../handson/lecture-01/#library)

</div>
<div>

<img src="/img/dyad-studio-add-component.png" class="!max-h-100" alt="The diagram toolbar's plus button opened: a search box above a tree of libraries, with the student's own library at the bottom.">

</div>
</div>

<!--
Tutor guide: ../handson/lecture-01/tutor.html#library
-->

---
routeAlias: github
---

###### Part 1 · 5 min

## Put your library on GitHub

<div class="max-w-220">

**Goal:** `MyCar` in your own GitHub repository, and a branch `handson-01` that today's work goes on.

> **Checkpoint**
>
> Your repository opens on github.com, and the status bar shows `handson-01`.

After **every** checkpoint from step 01 on: message `Step 02: engine` → **Commit** → **Sync Changes**.

[Guide: put your library on GitHub →](../handson/lecture-01/#github)

</div>

<!--
Tutor guide: ../handson/lecture-01/tutor.html#github
-->

---
routeAlias: tour
---

###### Step 01 · 13 min

## Tour: one model, two views

<div class="max-w-240">

**Goal:** two blocks and one wire, and the same model as code.

![Tour in Dyad Studio: delay and lag wired in the diagram with the delay parameter panel open, and the same component in the code view.](/img/step01-engine-two-views.png)

> **Checkpoint** · the code view shows the two blocks and one `connect(delay.y, lag.u)`

[Guide: step 01 →](../handson/lecture-01/#tour)

</div>

<!--
Tutor guide: ../handson/lecture-01/tutor.html#tour
-->

---
routeAlias: engine
---

###### Step 02 · 27 min

## Engine

<div class="grid grid-cols-[1fr_1fr] gap-8 items-start">
<div>

**Goal:** torque command in, shaft torque out — late, slow, never more than 150 N·m; then a bench that steps it.

> **Checkpoint**
>
> 200 N·m asked for at 0.5 s; `engine.limiter.y`:
>
> - **0** until 0.8 s
> - **97.5 N·m** at 1.0 s
> - **150 N·m** from 1.22 s

[Guide: step 02 →](../handson/lecture-01/#engine)

</div>
<div>

![The finished Engine diagram: tau_cmd, delay, lag, limiter and torque in a row, spline port on the right, support port at the bottom.](/img/step02-engine-finished.png)

</div>
</div>

<!--
Tutor guide: ../handson/lecture-01/tutor.html#engine
-->

---
routeAlias: driveline
---

###### Step 03 · 13 min

## Driveline

<div class="grid grid-cols-[1fr_1.4fr] gap-8 items-start">
<div>

**Goal:** shaft torque in, a force on the car out: a 4:1 gear and a 0.31 m wheel.

> **Checkpoint**
>
> *F* = *T* · *i* / *r*
>
> 100 N·m → **1290 N** → **0.92 m/s²** on 1400 kg
>
> Flat out: 150 N·m → **1935 N**

[Guide: step 03 →](../handson/lecture-01/#driveline)

</div>
<div>

![Driveline: spline into an ideal gear, then an ideal rolling wheel out to the flange, with both supports brought out.](/img/step03-driveline.png)

</div>
</div>

<!--
Tutor guide: ../handson/lecture-01/tutor.html#driveline
-->

---
routeAlias: body
---

###### Step 04 · 21 min

## Body

<div class="grid grid-cols-[1fr_1.4fr] gap-8 items-start">
<div>

**Goal:** 1400 kg, and the two forces that hold it back on a flat road.

> **Checkpoint**
>
> Drag 0.378 · *v*², rolling 165 N
>
> Pushed with 500 N: **0.357 m/s²** at the start, settles at **29.78 m/s**

[Guide: step 04 →](../handson/lecture-01/#body)

</div>
<div>

![Body: mass, quadratic drag and rolling resistance on one flange, with two constants feeding the rolling resistance.](/img/step04-body.png)

</div>
</div>

<!--
Tutor guide: ../handson/lecture-01/tutor.html#body
-->

---
routeAlias: car
---

###### Step 05 · 27 min

## Car: full throttle to terminal speed

<div class="grid grid-cols-[1fr_1.4fr] gap-8 items-start">
<div>

**Goal:** your three components as one car, flat out from rest, run for 300 s.

> **Checkpoint**
>
> - **23.6 s** to 100 km/h
> - **143 s** to 99 %
> - **246.39 km/h** at 300 s

[Guide: step 05 →](../handson/lecture-01/#car)

</div>
<div>

![Car: torque command into engine, driveline and body, with a velocity sensor and a 3.6 gain producing speed in km/h.](/img/step05-car.png)

</div>
</div>

<!--
Tutor guide: ../handson/lecture-01/tutor.html#car
-->

---
routeAlias: wheel-inertia
---

###### Step 06 · 12 min

## A wheel with inertia

<div class="grid grid-cols-[1fr_1.4fr] gap-8 items-start">
<div>

**Goal:** a 1 kg·m² wheel between the gear and the road, and how little it changes.

> **Checkpoint**
>
> *J* / *r*² ≈ **10 kg** on 1400 kg
>
> - **23.8 s** to 100 km/h, not 23.6
> - **246.39 km/h**, unchanged

[Guide: step 06 →](../handson/lecture-01/#wheel-inertia)

</div>
<div>

![WheeledDriveline: an inertia block between the gear and the rolling wheel.](/img/step06-wheeled-driveline.png)

</div>
</div>

<!--
Tutor guide: ../handson/lecture-01/tutor.html#wheel-inertia
-->

---
routeAlias: grade
---

###### Step 07 · 13 min

## A road with a gradient

<div class="grid grid-cols-[1fr_1.4fr] gap-8 items-start">
<div>

**Goal:** your first equation, gravity along the slope, and a body with a `grade` input.

> **Checkpoint**
>
> 10 % climb: *m g* sin(arctan 0.10) = **1366 N**
>
> At 130 km/h: 1366 + 493 + 164 = **2023 N** > 1935 N

[Guide: step 07 →](../handson/lecture-01/#grade)

</div>
<div>

![GradeBody: the grade input feeds both the rolling resistance inclination and the grade force.](/img/step07-grade-body.png)

</div>
</div>

<!--
Tutor guide: ../handson/lecture-01/tutor.html#grade
-->

---
routeAlias: tire-curve
---

###### Step 08 · 20 min

## Tire friction against slip

<div class="grid grid-cols-[1fr_1.4fr] gap-8 items-start">
<div>

**Goal:** a component made of equations: slip κ in, grip μ out.

> **Checkpoint**
>
> - peak **μ = 1.0** at κ = 0.04
> - **0.85** at 0.08
> - **0.7** beyond 0.12
> - mirrored for braking

[Guide: step 08 →](../handson/lecture-01/#tire-curve)

</div>
<div>

![TireFrictionCurve: the diagram holds only the kappa input and mu output; the curve itself is equations in the code view.](/img/step08-tire-curve.png)

</div>
</div>

<!--
Tutor guide: ../handson/lecture-01/tutor.html#tire-curve
-->

---
routeAlias: slip-wheel
---

###### Step 09 · 15 min

## A wheel that can slip

<div class="grid grid-cols-[1fr_1.4fr] gap-8 items-start">
<div>

**Goal:** a tire instead of a rolling constraint: wheel and car may now move at different speeds.

> **Checkpoint**
>
> Nothing in **Problems**; `curve` has no wires.
>
> Reference test, 5 s full torque:
> snow slip **135**, dry **0.0076**

[Guide: step 09 →](../handson/lecture-01/#slip-wheel)

</div>
<div>

![SlipWheel1D: the curve block sits between the spline and flange ports with no wires; it is connected through equations.](/img/step09-slip-wheel.png)

</div>
</div>

<!--
Tutor guide: ../handson/lecture-01/tutor.html#slip-wheel
-->

---
routeAlias: standing-start
---

###### Step 10 · 23 min

## Standing start on a slippery road

<div class="grid grid-cols-[1fr_1.3fr_0.6fr] gap-6 items-start">
<div>

**Goal:** a car around the slipping wheel, floored from rest on snow.

> **Checkpoint**
>
> After 5 s:
>
> - snow: car **10.12 km/h**, wheel **1501 km/h**
> - dry: **21.08 / 21.24 km/h**

[Guide: step 10 →](../handson/lecture-01/#standing-start)

</div>
<div>

![SlipCar: engine, gear, wheel inertia and slip wheel drive the grade body, with sensors for vehicle speed and wheel surface speed.](/img/step10-standing-start.png)

<div class="text-sm text-center opacity-70"><code>SlipCar</code></div>

</div>
<div>

![The SlipCarStandingStart bench: road, friction and cmd constants into the car's three inputs.](/img/step10-standing-start-bench.png)

<div class="text-sm text-center opacity-70">the bench</div>

</div>
</div>

<!--
Tutor guide: ../handson/lecture-01/tutor.html#standing-start
-->

---
routeAlias: hand-in
---

###### 5 min

## Hand in: a pull request

**Goal:** a pull request from `handson-01` into `main`, with the steps you finished and the
checkpoint numbers you got in its description. Do *not* merge it.

> **Checkpoint**
>
> The pull request's **Commits** tab lists one commit per step.

[Guide: hand in →](../handson/lecture-01/#hand-in)

<!--
Tutor guide: ../handson/lecture-01/tutor.html#hand-in
-->

---
routeAlias: wrap-up
---

## What you measured

| Step | What | Predicted | From |
| --- | --- | --- | --- |
| 02 | engine, 200 N·m asked | 0 until 0.8 s · 97 N·m at 1.0 s · 150 from 1.22 s | delay, lag, ceiling |
| 03 | driveline, 100 N·m | 1290 N · 0.92 m/s² | *F* = *T i* / *r* |
| 04 | body, 500 N push | 29.78 m/s | push = drag + rolling |
| 05 | car, flat out | **246 km/h** · 23.6 s to 100 | force balance |
| 06 | wheel inertia | 23.8 s to 100 · top speed unchanged | *J* / *r*² ≈ 10 kg |
| 07 | 10 % climb | 1366 N | *m g* sin α |
| 08 | tire curve | μ 1.0 at κ 0.04 · 0.7 beyond 0.12 | four parameters |
| 10 | standing start | snow: car 10, wheel 1500 km/h · dry: 21 together | tire limit 1373 < 1935 N |

Next: [Lecture 1](../lecture-01/index.html) puts this car under cruise control.

<!--
Tutor guide: ../handson/lecture-01/tutor.html#wrap-up
-->
