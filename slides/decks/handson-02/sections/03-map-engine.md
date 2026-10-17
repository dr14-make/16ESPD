---
routeAlias: map-engine
layout: section
---

###### Step 03 · 20 min

# Map engine on a dynamometer

Pedal in, torque, fuel and CO₂ out: your own engine, drawn from six given blocks, at a speed the bench holds.

[page: step 03](../handson/lecture-02/#map-engine) · reference `dyad/HandsOn02/MapEngine.dyad`, `MapEngineDyno.dyad`

<!--
**Say:** This is the lecture's engine as a picture you draw. The pedal opens the throttle, the air
path gives the manifold pressure, and two maps read at speed and pressure give torque and fuel.
CO2 is fuel times 3.09.

**Built or given:** students draw `MapEngine` from given blocks: `AirPath` (exactly the bench of
step 02, packaged), `TorqueMap` and `FuelMap` (the tables are already inside), a speed sensor, a
gain and a torque source. Nothing to type but 3.09. The dyno bench is pasted. At the end they swap
in the finished library `MappedEngine`, which adds fuel cut, a rev limiter, a pedal curve, a
throttle actuator lag and the emission maps.

**Timing:** 20 minutes: 3 of theory, 8 to draw the engine, 3 to paste the bench, 3 for the two
runs, 3 for the swap. The 15-wire drawing is the tight part: if the room is slow, hand out the
"Stuck?" code from the page and keep the runs.
-->

---
routeAlias: engine-equations
---

## Three lines make the engine

<div class="grid grid-cols-[1.2fr_1fr] gap-8">
<div>

$$ T_e = \min\big(\,T_{\text{map}}(N, p_m),\; T_{\text{full}}(N)\,\big) $$

$$ \dot m_f = \dot m_{f,\text{map}}(N, p_m) $$

$$ \dot m_{\text{CO}_2} = 3.09\,\dot m_f $$

</div>
<div>

- **Pedal = throttle:** here the pedal opens the throttle directly, so any lag you see is the
  manifold's.
- **The cap:** the map runs to 105 kPa; the engine never gets there. `full_load.csv` holds what it
  really reaches at each speed. `TorqueMap` applies it inside.
- **3.09:** each kilogram of petrol burned completely makes 3.09 kg of CO₂ — carbon balance.

</div>
</div>

<!--
**Say:** Three lines. The torque is the map, but never more than the full-load curve. The fuel is
the other map. CO2 is chemistry. And the pedal goes straight to the throttle: no pedal curve, no
actuator, so the only thing between pedal and torque is the manifold of step 02.

**Where 3.09 comes from:** each kg of carbon burns to 44/12 = 3.67 kg of CO2. Carbon is about
84 % of petrol by mass, and 0.84 × 3.67 = 3.09. It holds only at full oxidation; the CO the
engine makes is a small correction.

**Why the cap matters, in numbers:** at 3000 rpm the map reads 163.0 N·m at 99.9 kPa; the
full-load curve says 148.4. The map's last columns are extrapolated past what ALPHA measured.

**Ask the room:** what does the engine do with the pedal closed at 3000 rpm? *(Pressure 13.5 kPa
from step 02; the map at 13.5 kPa says −18.2 N·m and still 0.097 g/s of fuel. Keep it: it is the
last slide of this step.)*
-->

---

## Draw `MapEngine`: six blocks, fifteen wires

<div class="grid grid-cols-[1fr_1.2fr] gap-6">
<div>

**Blocks**

- `air` = `Vehicle › Engine › AirPath`
- `speed` = `Sensors › VelocitySensor`
- `torque_map` = `Vehicle › Engine › TorqueMap`
- `fuel_map` = `Vehicle › Engine › FuelMap`
- `co2` = `Math › Gain(k = 3.09)`
- `torque` = `Sources › TorqueSource`

**Ports:** `pedal`, `mdot_bst` in; `spline`, `support`; `p_m`, `mdot_fuel`, `mdot_co2` out.

</div>
<div>

**Wires**

- `pedal` → `air.u_thr`; `mdot_bst` → `air.mdot_bst`
- `speed.w` → `air.omega`, `torque_map.omega`, `fuel_map.omega`
- `air.p_m` → `torque_map.p_m`, `fuel_map.p_m`, `p_m`
- `torque_map.y` → `torque.tau`
- `torque` → `spline`, `support`; `speed` → `spline`
- `fuel_map.y` → `mdot_fuel`, `co2.u`; `co2.y` → `mdot_co2`

</div>
</div>

<!--
**Say:** Two map blocks hanging off the same two wires, speed and pressure: that is the picture
of the lecture. The engine control unit knows N and p_m and looks everything up there.

**Point at:** `TorqueMap` and `FuelMap` take rad/s and Pa, as everything in the solver does, and
convert to rpm and kPa inside, at the table. Their tables come with them from the course
library's `EngineMapData`.

**They get wrong:** the shaft. The speed sensor's circle goes to `spline`, the same port as the
torque source's, or the sensor reads a shaft nobody drives. And there is no flywheel: on the
dynamometer the bench sets the speed.

**Ports:** drop each one from **+** straight onto the outline, in `MapEngine`'s own diagram. To
move or rename one, click just outside it (a click on it starts a wire), then drag, or Edit
Parameters → pencil. Hover to read port names: `air` has
`u_thr`, `mdot_bst`, `omega` in from the top and `mdot_thr`, `p_m`, `mdot_cyl` out; the maps
have `omega` on top, `p_m` below.

**Save twice** after the last wire: one <kbd>Ctrl</kbd>+<kbd>S</kbd> can miss it (a known Studio
bug). Then check the **Problems** tab is empty.

**TODO (screenshot):** `step03-map-engine.png`.
-->

---

## The dynamometer: hold the speed, step the pedal

<div class="grid grid-cols-2 gap-8">
<div>

**Bench `MapEngineDyno`** (pasted): a pedal `Step`, `Constant(0)` into `mdot_bst`, a
`VelocitySource` holding `rpm`, mounts.

**Run 1:** 90 km/h cruise, 3080 rpm, pedal 0.1034 → 0.12 at 1 s.

**Run 2:** 3000 rpm, pedal 0 → 1.

</div>
<div>

> **Checkpoint · run 1**
>
> | | before | after |
> | --- | --: | --: |
> | `p_m` | 47.8 kPa | 52.9 kPa |
> | torque | 31.1 N·m | 41.4 N·m |
>
> Torque rise 10–90 %: **50 ms**.

> **Checkpoint · run 2**
>
> | | closed | wide open |
> | --- | --: | --: |
> | `p_m` | 13.5 kPa | 99.9 kPa |
> | torque | −18.2 N·m | **148.4 N·m** |
> | fuel | 0.097 g/s | 3.75 g/s |
> | CO₂ | 0.30 g/s | 11.6 g/s |

</div>
</div>

<!--
**Say:** A real engine is tested on a dynamometer: a machine that holds the shaft at a fixed speed
whatever the engine does. Then you can change the pedal and watch only the engine. That is this
bench.

**Point at (run 1):** the time between the pedal step and the torque. The pedal jumps; the torque
takes about 50 ms, because the manifold has to fill to the new pressure. That is the state of
step 02, not Lecture 1's 0.6 s of delay plus lag.

**Point at (run 2):** wide open, the torque rises 10–90 % in about 2 ms. A big throttle opening
fills the manifold almost at once, so the big step hides the lag; that is why run 1 is a small
step.

**Where the numbers come from:** `HandsOn02.MapEngineDynoTransient`, checked in
`test/engine_plausibility.jl`. Run 1 starts at the 90 km/h point of step 01 (31.1 N·m,
47.8 kPa, 0.85 g/s; the pedal 0.1034 was found by bisection) and ends at 1.02 g/s. Run 2's
pressures are `TestAirPath`'s at 3000 rpm; the torques and fuel are the maps read there:
`torque_Nm` at (3000, 99.9) = 163.0, capped by `full_load.csv` at 3000 rpm = 148.4;
`fuel_gps` 3.75 g/s; × 3.09 = 11.6 g/s. Closed: `torque_Nm` at (3000, 13.5) = −18.2, `fuel_gps`
= 0.097 g/s. Fuel in the plot is in kg/s: 0.00375.

**The pasted bench carries placement annotations,** so it lays out left to right. Without them
the parts pile up in one corner.

**TODO (screenshots):** `step03-dyno-bench.png`, `step03-step-plot.png`.
-->

---
routeAlias: fuel-cut
---

## Swap in the library engine: fuel cut

<div class="grid grid-cols-2 gap-8">
<div>

Closed pedal at 3000 rpm, your engine still burns **0.097 g/s** — for a negative torque.

A real ECU cuts the fuel on overrun. The library engine does:

1. Delete `engine`; **+** → `Vehicle › Engine › MappedEngine`, named `engine`; rewire. `spline` is the bottom-right circle, `support` the bottom centre: zoom in.
2. Run with `pedal_initial = 1`, `pedal_final = 0`, `p_m0 = 99889.9`: released at 1 s.

</div>
<div>

> **Checkpoint · pedal released**
>
> - `mdot_fuel` → **0** within about 30 ms
> - `tau_e` → **−18.7 N·m**, the closed-throttle curve
> - fueled again below **1000 rpm**; armed above 1300 rpm

`MappedEngine` also brings a pedal curve, a 50 ms throttle actuator, λ, HC, CO and NOx outputs,
and a rev limiter at 6500 rpm.

</div>
</div>

<!--
**Say:** Your engine is correct as far as it goes, and it wastes fuel. On overrun, with the pedal
up and the car driving the engine, there is no reason to inject anything. Every modern engine cuts
the fuel there; it resumes near idle so the engine does not stall. The library engine adds that
switch, and the same maps otherwise: same pressure and torque with the pedal floored.

**Its pedal is not yours:** `MappedEngine` puts a progressive pedal curve (pedal^1.5) and a 50 ms
throttle actuator in front of the same air path, so it holds 90 km/h at pedal 0.220, not 0.103.
Its booster input is already wired: the bench feeds `mdot_bst` from the start.

**Where the numbers come from:** `closed_throttle.csv` at 3000 rpm, interpolated, = −18.7 N·m;
the cut and resume speeds are `MappedEngine`'s parameters (1300 and 1000 rpm, task 3, assumed).

**Emissions:** HC, CO and NOx come from assumed tables; shapes follow textbook trends, magnitudes
are typical, not measured. Say so if anyone plots them.

**TODO (screenshot):** `step03-fuel-cut-plot.png`. **TODO (reference):** the swapped bench as
`HandsOn02.MappedEngineDyno` with its analysis.
-->
