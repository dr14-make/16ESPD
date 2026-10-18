---
routeAlias: coast-brake
layout: section
---

###### Step 06 · 8 min

# Coast-down and a brake stop

Lift off at 90 km/h: the fuel stops and the engine brakes the car. Then brake, and watch the vacuum.

[page: step 06](../handson/lecture-02/#coast-brake)

<!--
**Say:** Two things a driver does a hundred times a day, and both are invisible from the driver's
seat. Lifting off cuts the fuel completely. Braking happens with the manifold at its deepest
vacuum, which is exactly what the brake booster needs.

**Built or given:** students add a brake force to their `MappedCar` and build one bench.

**Timing:** 8 minutes: 4 for the coast-down, 4 for the brake. If short of time, do only the
coast-down.

**TODO (reference):** the student `HandsOn02.MappedCarCoast`, on the car with the student's
`MapEngine` and its pasted fuel cut, with its coast-down and brake-stop analyses. Add the reference
file to the line above.
-->

---

## Lift off at 90 km/h

<div class="grid grid-cols-2 gap-8">
<div>

**Bench `MappedCarCoast`:** copy `MappedCarCruise`, start at 25 m/s, and make the pedal a
`Step` from your 90 km/h value to 0 at 5 s (`offset` = the value, `height` = minus it). Run
**90 s**; plot `car.v_kmh`, `car.fuel_lph`, `car.p_m`.

At 3080 rpm the closed-throttle torque is **−19 N·m**: × 4 / 0.31 = **246 N** of engine braking,
on top of 401 N of drag and rolling.

</div>
<div>

> **Checkpoint**
>
> - at 5 s: fuel **4.11 → 0 L/h**
> - `p_m` drops to about **13.5 kPa**
> - deceleration **0.46 m/s²** (in neutral: 0.29)
> - fuel back on at **29 km/h** — 1000 rpm

</div>
</div>

<!--
**Say:** Lift your foot at 90. Two things happen at once. The throttle closes, so the manifold
empties: overrun, 13.5 kPa, as in step 02. And the ECU cuts the fuel: zero, not idle. The engine is
now an air pump driven by the wheels, and pumping against that vacuum brakes the car.

**Derivation:** closed-throttle torque at 3080 rpm, interpolated in `closed_throttle.csv`, is
−19.0 N·m; × 4 / 0.31 = 246 N. With 401 N of road load: 647 N / 1400 kg = 0.46 m/s². Neutral,
road load only: 401 / 1400 = 0.29 m/s².

**Why 29 km/h:** fuel resumes below 1000 rpm, `FuelCutLogic`'s assumed resume speed: 1000 / 34.2 =
29.2 km/h. It arms only above 1300 rpm, 38 km/h, so a pedal lift at 30 km/h never cuts.

**Ask the room:** coasting down a long hill in gear, or in neutral: which uses less fuel?
*(In gear: zero. In neutral the engine idles at 0.45 L/h.)*

**TODO (checkpoint):** `p_m` at the fuel-resume instant, from `HandsOn02.MappedCarCoastTransient`.

**TODO (screenshot):** `step06-coast-plot.png`.
-->

---

## Brake, and read the vacuum

<div class="grid grid-cols-2 gap-8">
<div>

In `MappedCar`:

1. New input `F_brake`.
2. `brake` = `TranslationalComponents › Sources › Force`, between `body.flange` and
   `trans_ground`; `F_brake` → `brake.f`.

In `MappedCarCoast`: `Step(height = 4000, start_time = 5)` → `car.F_brake`. Stop the run before
the speed falls below **25 km/h**.

</div>
<div>

> **Checkpoint**
>
> - the car slows much faster than in the coast-down — if it speeds up, swap the two flanges
> - `p_m` stays deep below the 101 kPa outside — the vacuum the **brake booster** draws on

<div class="text-sm mt-4">

The car has no clutch: below idle speed the engine would stall with the wheels, so stop the run at 25 km/h.

</div>
</div>
</div>

<!--
**Say:** A brake booster is a can of air with a diaphragm. Its vacuum side is connected to this
manifold. The deeper the vacuum while you brake, the more the booster helps your foot. You have
just plotted the vacuum it gets. In the brake lecture, the booster's own air flows back into the
manifold through the `mdot_bst` input we held at zero today.

**Where the numbers come from:** 4000 N is about 0.3 g on 1400 kg, a firm stop. 25 km/h is
855 rpm, just above idle; below that the one-gear car drags the engine toward standstill and `p_m` climbs to
ambient, an artifact of having no clutch.

**TODO (checkpoint):** `p_m` during the stop and the time to 25 km/h; the sign of the brake force
as wired (`Force` applies `f` at `flange_a` and `-f` at `flange_b`), from the reference. Then
replace "swap the flanges" with the one correct wiring.

**TODO (screenshot):** `step06-brake-plot.png`.
-->

---

## What you measured

| Step | What | Predicted | From |
| --- | --- | --- | --- |
| 01 | 90 km/h on the map | 47.8 kPa, 0.85 g/s | the tables, by hand |
| 02 | manifold at idle, overrun, wide open | 33.0 · 13.5 · 99.9 kPa | mass balance |
| 03 | full load at 3000 rpm | 148.4 N·m, 3.75 g/s | map, capped |
| 04 | top speed | ≈ 190 km/h, not 246 | rev limiter |
| 05 | cruise 50 · 90 · 130 km/h | 3.3 · 4.6 · 7.0 L/100 km | 77 · 105 · 162 g CO₂/km |
| 06 | lift off at 90 km/h | 0 L/h, 0.46 m/s² | fuel cut |

<!--
**Say:** Every number in this table was known before you ran the model. Where your run agreed,
the model is right.

**Point at:** step 05. Those are the numbers on a car's sticker, and you computed them from a
table measured on a test bench and a force balance you wrote in hands-on 1.
-->

---

## Hand in: a pull request

1. Source Control: nothing left to commit, nothing waiting to sync.
2. github.com → your `MyCar` → **Compare &amp; pull request**: compare `handson-02` against the branch you started from.
3. Title `Lecture 2 hands-on`. Description: the step 05 table with your numbers, and anything that
   did not match.
4. **Create pull request** — and do *not* merge it.

> **Checkpoint**
>
> The pull request's **Commits** tab shows one commit per step.

Page: [Hand in](../handson/lecture-02/#hand-in)

<!--
**Say:** Same as last time. The description carries the cruise table: three speeds, liters per
100 km and grams of CO2 per km.

**They get wrong:** a base of `main` while hands-on 1's pull request is still open: the pull
request then shows hands-on 1's commits too. The base is the branch `handson-02` was created from.
-->
