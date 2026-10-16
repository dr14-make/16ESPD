---
routeAlias: mapped-car
layout: section
---

###### Step 04 · 12 min

# The car with a mapped engine

Your hands-on 1 car, a new engine, a pedal instead of a torque command — and a real top speed.

[page: step 04](../handson/lecture-02/#mapped-car)

<!--
**Say:** The milestone. Same body, same driveline, same single gear of 4.0. Only the engine
changes, and with it the input: the driver now presses a pedal from 0 to 1, not a torque.

**Built or given:** students build `MappedCar` by duplicating their `Car` and swapping the engine
for the library `MappedEngine`, the one with fuel cut. Their own `MapEngine` stays on its bench;
the car needs the fuel cut for step 06.

**Timing:** 12 minutes: 2 of theory, 6 to duplicate and rewire, 4 for the full-pedal run.

**TODO (reference):** `HandsOn02.MappedCar`, `HandsOn02.MappedCarWOT`,
`HandsOn02.MappedCarWOTTransient`, built on task 4's `Vehicle.Engine.MappedEngineCar`. Add
`reference dyad/HandsOn02/MappedCar.dyad` to the line above.
-->

---
routeAlias: top-speed-again
---

## Top speed, with a torque curve

<div class="grid grid-cols-2 gap-8">
<div>

Same force balance as hands-on 1, but the push now depends on engine speed:

$$ \frac{T_{\text{full}}(N)\cdot 4}{0.31} \;=\; 0.378\,v^2 + 165 $$

- At 190 km/h the engine turns **6500 rpm**; the full-load curve has fallen to about **96 N·m**.
- Drag alone would stop the car at **192 km/h**.
- But **6500 rpm** is the rev limiter: fuel cut until 6300 rpm.

</div>
<div>

> **Predict**
>
> Lecture 1's car: **246 km/h**, at 8400 rpm.
>
> This car: about **190 km/h**, held there by the rev limiter.

</div>
</div>

<!--
**Say:** Hands-on 1 ended on this question: what would you add to get a believable top speed? A
torque curve. Here it is. Push equals drag plus rolling, as before, but the push falls away at
high revs.

**Derivation, if asked:** engine rpm = v / 0.31 × 4 × 60/2π, which is 34.2 rpm per km/h. So
6500 rpm is 189.9 km/h, 6300 is 184.1 and 1000 is 29.2. At 192 km/h (6570 rpm) the engine gives
96 N·m at full load (the map at 100 kPa, under the `full_load.csv` cap); × 4 / 0.31 = 1239 N =
0.378 × 53.3² + 165. Solving that balance over the tables gives 191.9 km/h; the limiter at
189.9 km/h comes first.

**Ask the room:** is the rev limiter what limits a real car's top speed? *(Rarely in top gear;
here the car has only one gear, ratio 4, which is a third or second gear on a real car.)*

**TODO (checkpoint):** confirm in `HandsOn02.MappedCarWOTTransient` whether the speed saws
between 184 and 190 km/h or sits at 190; and the time to 100 km/h.
-->

---

## Duplicate `Car`, swap the engine

<div class="grid grid-cols-2 gap-8">
<div>

1. **Components** → right-click `Car` → **Duplicate** → `MappedCar`.
2. Delete `engine`. **+** → `Vehicle › Engine › MappedEngine`, named `engine`.
3. Rename the input `tau_cmd` to `pedal`; wire it to `engine.pedal`.
4. `no_booster` = `Constant(k = 0)` → `engine.mdot_bst`.
5. `engine.spline` → `driveline`, `engine.support` → `rot_ground`, as before.
6. New outputs on the right edge:
   - `p_m` ← `engine.p_m`
   - `fuel_lph` ← `Gain(k = 4832.2)` ← `engine.mdot_fuel`

</div>
<div>

> **Why 4832.2?**
>
> kg/s → L/h: × 3600 s/h, ÷ 0.745 kg/L petrol.
>
> 3600 / 0.745 = **4832.2**

**Bench `MappedCarWOT`:** `Constant(k = 1)` → `car.pedal`; from rest; run **120 s**; plot
`car.v_kmh`.

Page: [The car with a mapped engine](../handson/lecture-02/#mapped-car)

</div>
</div>

<!--
**Say:** Duplicate, do not edit: your hands-on 1 car stays as it was, and Lecture 1's cruise
control still runs on it.

**Point at:** the gain. Fuel comes out of the engine in kilograms per second, a tiny number. A
gain turns it into liters per hour, the number on the dashboard.

**They get wrong:** leaving `mdot_bst` unconnected. The model then has an input nobody drives and
does not compile: the same "unbalanced" error as hands-on 1's missing support.

**TODO (checkpoint):** the bench's `initial` lines. The crankshaft is tied to the wheel through
the gear, so only `car.body.mass.s`, `car.body.mass.v` and `car.engine.air.manifold.p` should be
set; confirm on the reference before the session.

**TODO (screenshots):** `step04-mapped-car.png`, `step04-wot-plot.png`.
-->
