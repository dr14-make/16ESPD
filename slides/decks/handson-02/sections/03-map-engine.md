---
routeAlias: map-engine
layout: section
---

###### Step 03 · 20 min

# Map engine on a dynamometer

Pedal in, torque, fuel and CO₂ out: your own engine, drawn from six given blocks, at a speed the bench holds. Then fuel cut, pasted in.

[page: step 03](../handson/lecture-02/#map-engine) · reference `dyad/HandsOn02/MapEngine.dyad`, `MapEngineDyno.dyad`, `MapEngineFuelCut.dyad`, `MapEngineFuelCutDyno.dyad`

<!--
**Say:** This is the lecture's engine as a picture you draw. The pedal opens the throttle, the air
path gives the manifold pressure, and two maps read at speed and pressure give torque and fuel.
CO2 is fuel times 3.09.

**Built or given:** students draw `MapEngine` from given blocks: `AirPath` (exactly the bench of
step 02, packaged), `TorqueMap` and `FuelMap` (the tables are already inside), a speed sensor, a
gain and a torque source. Nothing to type but 3.09. The dyno bench is pasted. At the end they
paste fuel cut into their own engine: the library's `FuelCutLogic` (overrun cut and rev limiter),
and the two maps changed to `CutTorqueMap` and `CutFuelMap`, which take its cut signal. That engine
goes into their car in step 04.

**Timing:** 20 minutes: 3 of theory, 8 to draw the engine, 3 to paste the bench, 3 for the two
runs, 3 for the fuel-cut paste and its run. The 15-wire drawing is the tight part: if the room is slow, hand out the
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

## Paste in fuel cut

<div class="grid grid-cols-2 gap-8">
<div>

Closed pedal at 3000 rpm, your engine still burns **0.097 g/s** — for a negative torque.

A real ECU cuts the fuel on overrun. Paste it into **your** `MapEngine`:

1. Over the `torque_map` and `fuel_map` lines: `CutTorqueMap`, `CutFuelMap`, and `cut_logic` = `FuelCutLogic`.
2. After the last `connect`: four wires, pedal and speed in, the cut out to both maps.
3. In `MapEngineDyno`'s `speed` line: `Constant(…)` → a `Ramp` to 800 rpm from 2 s.

▷ once, then run with `rpm = 3000`, `pedal_initial = 1`, `pedal_final = 0`, `p_m0 = 99889.9`, `stop = 6`.

</div>
<div>

> **Checkpoint · pedal released at 1 s**
>
> - `mdot_fuel` 99 % gone in **30 ms**, then **0**
> - `torque_map.y` → **−18.7 N·m**, the closed-throttle curve; `MappedEngine` gives the same
> - fuel back at **4.73 s**, as the shaft passes **1000 rpm**
> - at 800 rpm: **33.0 kPa**, **0.096 g/s**, torque ≈ 0

| | arms | ends |
| --- | --- | --- |
| overrun | pedal closed, > 1300 rpm | pedal opens, or < 1000 rpm |
| rev limiter | > 6500 rpm | < 6300 rpm |

</div>
</div>

<!--
**Say:** Your engine is correct as far as it goes, and it wastes fuel. On overrun, with the pedal
up and the car driving the engine, there is no reason to inject anything. Every modern engine cuts
the fuel there: it saves fuel, keeps unburned fuel out of the catalyst, and brakes the car a little
harder. It turns the fuel back on near idle so the engine does not stall.

**Why two speeds:** with one threshold the injectors would chatter on and off around it. Between
1000 and 1300 rpm the logic keeps its last decision: hysteresis, like a thermostat. The rev limiter
is the same latch at 6500 / 6300 rpm; step 04's car meets it.

**The torque in the cut:** no combustion, so the engine is an air pump driven by the shaft. The
test bench measured that torque with the fuel off, over speed alone: `closed_throttle.csv`, −18.7
N·m at 3000 rpm. `CutTorqueMap` blends from the map to that curve with the cut fraction, and
`CutFuelMap` gates the fuel to zero. Run 2's closed pedal read −18.2 N·m from the map: the 0.5 N·m
is what the 0.097 g/s was still giving.

**The paste:** the two new map blocks have their ports where `TorqueMap`'s and `FuelMap`'s are, so
retyping the two lines moves no wire. The `cut_logic` block lands at the bottom left with its
placement and wires annotated; those wires follow `HandsOn02.MapEngineFuelCut`'s layout, so on a
student's own layout they may cut diagonally across blocks. The connections are right. The blocks
end without a line break: a student who selects whole lines from the margin gets the next line
joined onto the paste's last one. The ramp starts at 2 s, so runs 1 and 2
(which stop at 2 s) are unchanged; rerun run 2 now and its closed pedal starts in the cut, 0 fuel and −18.7 N·m.

**▷ before the REPL run:** the REPL keeps the `MapEngine` and `MapEngineDyno` it loaded before the
paste and runs them without an error, so a student who skips ▷ sees no cut, or a speed that never
ramps. One ▷ on `MapEngineDynoTransient` loads the edited ones.

**Against `MappedEngine`:** the same −18.7 N·m after the same release, because it uses the same
`FuelCutLogic` and curve. Its fuel goes a little later: its 50 ms throttle actuator keeps the
manifold full a moment longer. In the cut the torque does not depend on `p_m`.

**Where the numbers come from:** `HandsOn02.MapEngineFuelCutDynoTransient`, the bench after the
paste, in the "Hands-on 02 fuel cut" testset of `test/engine_plausibility.jl`. The cut and resume
speeds are `FuelCutLogic`'s defaults (1300, 1000, 6500, 6300 rpm, assumed).

**TODO (screenshot):** `step03-fuel-cut-plot.png`.
-->
