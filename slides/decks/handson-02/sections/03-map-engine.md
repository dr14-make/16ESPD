---
routeAlias: map-engine
layout: section
---

###### Step 03 · 20 min

# Map engine on a dynamometer

Pedal in, torque, fuel and CO₂ out: your own engine, read from the maps, at a speed the bench holds.

[page: step 03](../handson/lecture-02/#map-engine)

<!--
**Say:** This is the lecture's engine in under forty lines. The pedal opens the throttle, the air
path gives the manifold pressure, and two tables read at speed and pressure give torque and fuel.
A third caps the torque at what the engine can really do. CO2 is fuel times 3.09.

**Built or given:** students paste and read `MapEngine`; it uses the given `AirPath` (exactly the
bench of step 02, packaged) and the given map data. At the end they swap in the finished library
`MappedEngine`, which adds fuel cut, a rev limiter, a throttle actuator lag and the emission maps.

**Timing:** 20 minutes: 3 of theory, 5 to paste and read, 5 for the dyno bench, 4 to run, 3 for
the swap.

**TODO (reference):** `HandsOn02.MapEngine`, `HandsOn02.MapEngineDyno`,
`HandsOn02.MapEngineDynoTransient`. `MapEngine` extends `Vehicle.Engine.EngineMapData`, which
is on `feat/lecture02-mapped-engine` (task 3) and not merged: confirm its name and fields
(`rpm_axis`, `kpa_axis`, `torque_data`, `fuel_data`, `full_load_rpm`, `curve_axis`,
`full_load_data`) when it lands. Add `reference dyad/HandsOn02/MapEngine.dyad` to the line above.
-->

---
routeAlias: engine-equations
---

## Four lines make the engine

<div class="grid grid-cols-[1.2fr_1fr] gap-8">
<div>

$$ u_{\text{thr}} = \text{pedal}^{1.5} $$

$$ T_e = \min\big(\,T_{\text{map}}(N, p_m),\; T_{\text{full}}(N)\,\big) $$

$$ \dot m_f = \dot m_{f,\text{map}}(N, p_m) $$

$$ \dot m_{\text{CO}_2} = 3.09\,\dot m_f $$

</div>
<div>

- **Pedal curve:** progressive, so the first half of the pedal is gentle (lecture section 04,
  drive by wire).
- **The cap:** the map runs to 105 kPa; the engine never gets there. `full_load.csv` holds what it
  really reaches at each speed.
- **3.09:** each kilogram of petrol burned completely makes 3.09 kg of CO₂ — carbon balance.

</div>
</div>

<!--
**Say:** Four lines. The throttle follows the pedal through a curve. The torque is the map, but
never more than the full-load curve. The fuel is the other map. CO2 is chemistry.

**Where 3.09 comes from:** each kg of carbon burns to 44/12 = 3.67 kg of CO2. Carbon is about
84 % of petrol by mass, and 0.84 × 3.67 = 3.09. It holds only at full oxidation; the CO the
engine makes is a small correction.

**Why the cap matters, in numbers:** at 3000 rpm the map reads 163 N·m at 100 kPa; the full-load
curve says 148.4. The map's last columns are extrapolated past what ALPHA measured.

**Ask the room:** what does the engine do with the pedal closed at 3000 rpm? *(Pressure 13.5 kPa
from step 02; the map at 13.5 kPa says −18 N·m and still 0.1 g/s of fuel. Keep it: it is the last
slide of this step.)*
-->

---

## Paste `MapEngine`, then read it

<div class="grid grid-cols-[1.25fr_1fr] gap-6">
<div>

```julia [MapEngine — the relations]
air.u_thr = min(max(pedal, 0), 1)^1.5
air.omega = crankshaft.w
N = min(max(crankshaft.w * 30 / pi, 500), 6750)
p_kPa = min(max(air.p_m / 1000, 0), 105)
torque_map.u1 = N
torque_map.u2 = p_kPa
tau_e = min(torque_map.y, full_load.y)
mdot_fuel = fuel_map.y / 1000
mdot_co2 = 3.09 * mdot_fuel
torque.tau = tau_e
```

</div>
<div>

- `extends …EngineMapData`: the maps, already loaded as parameters.
- `air` = the given `AirPath`: your step 02 bench, packaged.
- `N` in rpm, `p_kPa` in kPa: the units the tables use, clamped to their edges.
- `torque` drives a 0.15 kg·m² `crankshaft` inertia; `spline` and `support` as in hands-on 1.

Full code on the page — paste it whole.

</div>
</div>

<!--
**Say:** Paste the whole component from the page; this slide shows the part that matters. Read it
top to bottom: pedal to throttle, speed and pressure into the tables, the cap, the fuel, the CO2,
the torque onto the shaft.

**Point at:** the unit conversions. The solver works in rad/s, Pa and kg/s; the tables in rpm,
kPa and g/s. Convert at the table, nowhere else.

**They get wrong:** a missing `extends` line, so `rpm_axis` is "not defined". Paste the whole
block, not just the relations.
-->

---

## The dynamometer: hold the speed, step the pedal

<div class="grid grid-cols-2 gap-8">
<div>

**Bench `MapEngineDyno`**

- `pedal` = `Step(height = 1, offset = 0, start_time = 1)` → `engine.pedal`
- `speed` = `Constant(k = 314.159)` → `dyno.w_ref` (3000 rpm)
- `dyno` = `RotationalComponents › Sources › VelocitySource`
- `engine.spline` → `dyno.spline`; both supports → `mounts` (`Fixed`)
- `initial engine.crankshaft.phi = 0`, `initial engine.air.manifold.p = 13482.4`

Run 3 s; plot `engine.p_m`, `engine.tau_e`, `engine.mdot_fuel`.

</div>
<div>

> **Checkpoint · 3000 rpm**
>
> | | closed | wide open |
> | --- | --: | --: |
> | `p_m` | 13.5 kPa | 99.9 kPa |
> | `tau_e` | −18.2 N·m | **148.4 N·m** |
> | `mdot_fuel` | 0.097 g/s | 3.75 g/s |
> | `mdot_co2` | 0.30 g/s | 11.6 g/s |
>
> Without the cap: 163.1 N·m.

</div>
</div>

<!--
**Say:** A real engine is tested on a dynamometer: a machine that holds the shaft at a fixed speed
whatever the engine does. Then you can change the pedal and watch only the engine. That is this
bench.

**Point at:** the time between the pedal step and the torque. It is the manifold filling, tens of
milliseconds at 3000 rpm, not Lecture 1's 0.6 seconds of delay plus lag.

**Where the numbers come from:** the pressures are `TestAirPath`'s at 3000 rpm (merged); torque and
fuel are the maps read there: `torque_Nm` at (3000, 99.9) = 163.1, capped by `full_load.csv` at
3000 rpm = 148.4; `fuel_gps` 3.75 g/s; × 3.09 = 11.6 g/s. Closed: `torque_Nm` at (3000, 13.5) =
−18.2, `fuel_gps` = 0.097 g/s. Fuel in the plot is in kg/s: 0.00375.

**TODO (checkpoint):** the 10–90 % rise time of `tau_e` after the step, from
`HandsOn02.MapEngineDynoTransient`.

**TODO (screenshots):** `step03-dyno-bench.png`, `step03-tip-in-plot.png`.
-->

---
routeAlias: fuel-cut
---

## Swap in the library engine: fuel cut

<div class="grid grid-cols-2 gap-8">
<div>

Closed pedal at 3000 rpm, your engine still burns **0.097 g/s** — for a negative torque.

A real ECU cuts the fuel on overrun. The library engine does:

1. Delete `engine`; **+** → `Vehicle › Engine › MappedEngine`, named `engine`.
2. `Constant(k = 0)` → `engine.mdot_bst`.
3. `pedal`: `height = -1`, `offset = 1` — released at 1 s.

</div>
<div>

> **Checkpoint · pedal released**
>
> - `mdot_fuel` → **0**
> - `tau_e` → **−18.7 N·m**, the closed-throttle curve
> - fueled again below **1000 rpm**; armed above 1300 rpm

`MappedEngine` also brings λ, HC, CO and NOx outputs, and a rev limiter at 6500 rpm.

</div>
</div>

<!--
**Say:** Your engine is correct as far as it goes, and it wastes fuel. On overrun, with the pedal
up and the car driving the engine, there is no reason to inject anything. Every modern engine cuts
the fuel there; it resumes near idle so the engine does not stall. The library engine adds that
switch, and the same maps otherwise: same pressure and torque with the pedal down.

**Where the numbers come from:** `closed_throttle.csv` at 3000 rpm, interpolated, = −18.7 N·m;
the cut and resume speeds are `MappedEngine`'s parameters (1300 and 1000 rpm, task 3, assumed).

**Emissions:** HC, CO and NOx come from assumed tables; shapes follow textbook trends, magnitudes
are typical, not measured. Say so if anyone plots them.

**TODO (screenshot):** `step03-fuel-cut-plot.png`. **TODO (reference):** the swapped bench as
`HandsOn02.MappedEngineDyno` with its analysis.
-->
