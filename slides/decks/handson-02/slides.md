---
theme: default
title: Drive a Mapped Engine — Lecture 2 hands-on
canvasWidth: 1280
aspectRatio: 1280/760
routerMode: hash
transition: none
routeAlias: title
layout: cover
---

# Drive a mapped engine

<h1 class="!text-5xl !-mt-4 opacity-70">Lecture 2 hands-on</h1>

Vehicle Systems &amp; Components · about 90 minutes

<img src="/img/mapped-engine-overview.svg" class="!max-h-48 bg-white rounded p-2 mt-6" alt="The mapped engine: pedal to throttle, throttle and booster air into the intake manifold whose state is the pressure p_m, the cylinders drawing air out; maps read at engine speed and p_m give torque to the car and fuel to the fuel and CO₂ outputs.">

<div class="mt-6 text-xl">

Follow the guide: **[handson/lecture-02](../handson/lecture-02/)**

</div>

<!--
What to say, timings and where students stall: the tutor guide,
../handson/lecture-02/tutor.html
-->

---
routeAlias: setup
---

###### Step 00 · 8 min

## Set up

<div class="grid grid-cols-[1.4fr_1fr] gap-10 items-start">
<div>

**Goal:** a `handson-02` branch on your `MyCar`, and the course library beside it.

> **Checkpoint**
>
> **+** → `VehicleSystemsComponents › Vehicle › Engine` lists `AirPath`, `CylinderAirflow`,
> `MappedEngine` and `Throttle`.
>
> `using VehicleSystemsComponents` runs in the REPL without an error.

[Guide: step 00 →](../handson/lecture-02/#setup)

</div>
<div>

<img src="/img/step00-engine-library.png" class="!max-h-110" alt="The plus popup opened at VehicleSystemsComponents › Vehicle › Engine, listing AirPath, CylinderAirflow, MappedEngine and more.">

</div>
</div>

<!--
Tutor guide: ../handson/lecture-02/tutor.html#setup
-->

---
routeAlias: maps
---

###### Step 01 · 12 min

## Read the maps

<div class="grid grid-cols-[1fr_1.3fr] gap-8 items-start">
<div>

**Goal:** the 90 km/h cruise point on the torque map, and its fuel, before any model runs.

> **Checkpoint**
>
> 90 km/h = 3080 rpm, 31.1 N·m
>
> - *p<sub>m</sub>* ≈ **47.8 kPa**
> - fuel **0.850 g/s** = 4.11 L/h
> - **4.6 L/100 km**
>
> 50 · 90 · 130 km/h: **3.3 · 4.6 · 7.0 L/100 km**

[Guide: step 01 →](../handson/lecture-02/#maps)

</div>
<div>

![The torque map as a heat map over manifold pressure and engine speed, with the 90 km/h point marked at 3080 rpm and 47.8 kPa.](/img/step01-torque-map.png)

</div>
</div>

<!--
Tutor guide: ../handson/lecture-02/tutor.html#maps
-->

---
routeAlias: manifold
---

###### Step 02 · 15 min

## Manifold: a pressure that fills

<div class="grid grid-cols-[1fr_1fr] gap-8 items-start">
<div>

**Goal:** the manifold as one equation, on a bench between the throttle and the cylinders.

> **Checkpoint**
>
> | | closed | after the step | τ |
> | --- | --: | --: | --: |
> | 800 rpm | **33.0 kPa** | 37.3 kPa | **0.15 s** |
> | 3000 rpm | **13.5 kPa** | 99.9 kPa | **0.03 s** |

[Guide: step 02 →](../handson/lecture-02/#manifold)

</div>
<div>

![The AirPathStep bench: throttle_cmd into throttle, no_booster into the manifold, speed into cylinders; both flows into the manifold, and manifold.p_m fed back to throttle and cylinders.](/img/step02-airpath-bench.png)

</div>
</div>

<!--
Tutor guide: ../handson/lecture-02/tutor.html#manifold
-->

---
routeAlias: map-engine
---

###### Step 03 · 20 min

## Map engine on a dynamometer

<div class="grid grid-cols-[1fr_1fr_1fr] gap-6 items-start">
<div>

**Goal:** your own engine, pedal in, torque, fuel and CO₂ out; then fuel cut, pasted in.

> **Checkpoint**
>
> - run 1, 90 km/h: **31.1 → 41.4 N·m**, rise in **50 ms**
> - run 2, wide open, 3000 rpm: **148.4 N·m**, 3.75 g/s
> - released: fuel **0** within 30 ms, **−18.7 N·m**, back at **1000 rpm**

[Guide: step 03 →](../handson/lecture-02/#map-engine)

</div>
<div>

![The MapEngine diagram: air, speed, torque_map above fuel_map, torque, co2, with the speed and pressure wires fanning out to both maps.](/img/step03-map-engine.png)

<div class="text-sm text-center opacity-70">drawn: <code>MapEngine</code></div>

</div>
<div>

![MapEngine after the fuel-cut paste: cut_logic at the bottom left, its output into both maps.](/img/step03-map-engine-fuel-cut.png)

<div class="text-sm text-center opacity-70">after the paste, fuel cut</div>

</div>
</div>

<!--
Tutor guide: ../handson/lecture-02/tutor.html#map-engine
-->

---
routeAlias: mapped-car
---

###### Step 04 · 12 min

## The car with a mapped engine

<div class="grid grid-cols-[2fr_3fr] gap-8 items-start">
<div>

**Goal:** your hands-on 1 car with your own engine, a flywheel, a pedal and a given CVT, floored from rest.

> **Checkpoint**
>
> - clutch slips at **1300 rpm**, locks at **1.33 s**, 13.7 km/h
> - 0–100 km/h in **10.4 s**
> - peak **6390 rpm**, under the 6500 limiter; then 6000
> - top speed **205 km/h**, not 246

[Guide: step 04 →](../handson/lecture-02/#mapped-car)

</div>
<div>

![MappedCar: pedal into engine and driveline; engine, flywheel, CVT driveline, body, vsensor and to_kmh in one row; p_m and fuel_lph outputs along the top; the grounds below.](/img/step04-mapped-car.png)

</div>
</div>

<!--
Tutor guide: ../handson/lecture-02/tutor.html#mapped-car
-->

---
routeAlias: cruise
---

###### Step 05 · 12 min

## Cruise: fuel and CO₂

<div class="grid grid-cols-[3fr_1fr] gap-8 items-start">
<div>

**Goal:** hold 50, 90 and 130 km/h, and read the numbers on a car's sticker.

> **Checkpoint**
>
> | km/h | rpm | `p_m` kPa | L/h | L/100 km | g CO₂/km | fixed gear |
> | --: | --: | --: | --: | --: | --: | --: |
> | 50 | 1992 | 40.1 | 1.84 | **3.7** | **85** | 3.3 |
> | 90 | 2182 | 54.4 | 3.55 | **3.9** | **91** | 4.6 |
> | 130 | 3118 | 67.2 | 7.78 | **6.0** | **138** | 7.0 |

[Guide: step 05 →](../handson/lecture-02/#cruise)

</div>
<div>

![MappedCarCruise: a constant pedal into the car.](/img/step05-cruise-bench.png)

</div>
</div>

<!--
Tutor guide: ../handson/lecture-02/tutor.html#cruise
-->

---
routeAlias: coast-brake
---

###### Step 06 · 8 min

## Coast-down and a brake stop

<div class="grid grid-cols-[2fr_3fr] gap-8 items-start">
<div>

**Goal:** lift off at 90 km/h and watch the fuel stop; then brake to rest, and read the vacuum.

> **Checkpoint**
>
> - at 5 s: fuel **3.55 → 0 L/h**, *p<sub>m</sub>* **17.1 kPa**, **0.39 m/s²**
> - fuel back at **11 km/h**, 66 s, below 1000 rpm
> - braking 4000 N: at rest in **7.9 s**, *p<sub>m</sub>* ≤ 34 kPa
> - the engine idles at **775 rpm**: no stall

[Guide: step 06 →](../handson/lecture-02/#coast-brake)

</div>
<div>

![MappedCar with the F_brake input and the given RoadBrake between body and trans_ground.](/img/step06-mapped-car-brake.png)

</div>
</div>

<!--
Tutor guide: ../handson/lecture-02/tutor.html#coast-brake
-->

---
routeAlias: hand-in
---

###### 3 min

## Hand in: a pull request

**Goal:** a pull request from `handson-02` into the branch you started from, with your step 05
table in its description. Do *not* merge it.

> **Checkpoint**
>
> The pull request's **Commits** tab lists one commit per step.

[Guide: hand in →](../handson/lecture-02/#hand-in)

<!--
Tutor guide: ../handson/lecture-02/tutor.html#hand-in
-->

---
routeAlias: wltc
---

###### Step 07 · if time allows

## WLTC: the test cycle

**Goal:** the same engine with a gearbox and a driver, on the 30-minute trace a car's label is
measured on; compare your L/100 km and g CO₂/km with a real 1.5 L petrol car's.

[Guide: step 07 →](../handson/lecture-02/#wltc)

<!--
Tutor guide: ../handson/lecture-02/tutor.html#wltc
-->

---
routeAlias: wrap-up
---

## What you measured

| Step | What | Number | From |
| --- | --- | --- | --- |
| 01 | 90 km/h on the map | 47.8 kPa, 0.85 g/s | the tables, by hand |
| 02 | manifold at idle, overrun, wide open | 33.0 · 13.5 · 99.9 kPa | mass balance |
| 03 | full load at 3000 rpm | 148.4 N·m, 3.75 g/s | map, capped |
| 04 | top speed with a CVT | 205 km/h, not 246 | 79.5 kW at 6000 rpm |
| 05 | cruise 50 · 90 · 130 km/h | 3.7 · 3.9 · 6.0 L/100 km | 85 · 91 · 138 g CO₂/km |
| 06 | lift off at 90 km/h | 0 L/h down to 11 km/h | fuel cut, CVT |

Steps 01–03 were known before the model ran; from step 04 the car reads the same maps at the CVT's points. Where your run agreed, your model is right.

<!--
Tutor guide: ../handson/lecture-02/tutor.html#wrap-up
-->
