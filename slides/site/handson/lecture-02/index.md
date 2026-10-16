---
title: Lecture 2 hands-on — drive a mapped engine
---

[← Vehicle Systems & Components](../../index.html) · [Tutor deck →](../../handson-02/index.html){target="_self"}

# Lecture 2 hands-on: drive a mapped engine

From measured engine maps to the fuel and CO₂ your car burns at 50, 90 and 130 km/h

**Why we build it.** Lecture 1's engine gave 150 N·m at every speed and could not say how much fuel it burned. A real engine control unit reads tables measured on a test bench, at the engine speed and the pressure in the intake manifold. **What you build:** the manifold, whose pressure fills and empties, and a small engine of your own that reads torque and fuel from those tables. Then you put the finished course engine into your hands-on 1 car and drive it: flat out, at steady speeds, lifting off and braking. By the end you have your car's fuel consumption in L/100 km and its CO₂ in g/km, the two numbers on a car's sticker.

**How each step works.** It starts with the idea it needs. Your tutor explains it from the [tutor deck](../../handson-02/index.html){target="_self"}, and the *Theory* link under each step's goal opens those slides. Then you build, and the checkpoint is a number you could have predicted first. **Before this session:** the [engine lecture](../../lecture-02/index.html#/mapped-engine){target="_self"}, whose last section shows what you build here.

You build on your `MyCar` library from [hands-on 1](../lecture-01/). The throttle, the cylinders' air flow and the finished mapped engine come from the course library, `VehicleSystemsComponents`: they are physics the lecture stated, not what this session teaches. The budgets add up to about 90 minutes; step 07 is for when time is left.

0. [Set up](#setup) — 8 min
1. [Read the maps](#maps) — 12 min
2. [Manifold: a pressure that fills](#manifold) — 15 min
3. [Map engine on a dynamometer](#map-engine) — 20 min
4. [The car with a mapped engine](#mapped-car) — 12 min
5. [Cruise: fuel and CO₂](#cruise) — 12 min
6. [Coast-down and a brake stop](#coast-brake) — 8 min

- [Hand in: open a pull request](#hand-in) — 3 min

7. [WLTC: the test cycle](#wltc) — if time allows

## Build the engine

Steps 0–3 · from the tables to an engine on a test bench · 55 min

### 00 Set up <Badge type="info" text="8 min" /> {#setup}

A branch for today on your `MyCar`, and the course library beside your own.

#### Do this

1. In the status bar, switch to the branch that holds your car — `handson-01`, or wherever Lecture 1 left it. Then click the branch name → **Create new branch…** → `handson-02`. All of today goes on it.
2. **Dyad: Open Julia REPL** and add the course library:

   ```julia
   using Pkg
   Pkg.add(url = "https://github.com/dr14-make/16ESPD")
   ```

   It downloads and precompiles: a few minutes. Read step 01 meanwhile.
3. Bottom right, **Julia Commands → Dyad Compile**.
4. Open any diagram, click **+** and open `VehicleSystemsComponents` → `Vehicle` → `Engine`.

<!-- TODO(screenshot): step00-engine-library.png, the + tree at Vehicle › Engine. -->
<!-- TODO(rehearsal): confirm Pkg.add(url = …) is enough for Dyad Studio to list the library, or
switch the action to Actions → Import Library; pin to a tag once tasks 3–4 merge. -->

::: tip Checkpoint

`Engine` lists `AirPath`, `CylinderAirflow`, `MappedEngine` and `Throttle`, and `using VehicleSystemsComponents` runs in the REPL without an error.

:::

### 01 Read the maps <Badge type="info" text="12 min" /> {#maps}

Find the 90 km/h cruise point on the torque map and read its fuel flow — before any model runs.

Theory: [tutor slides — speed × manifold pressure, and 90 km/h from the table](../../handson-02/index.html#/speed-density){target="_self"}

#### Where you are, where you are going

Every map is a grid over engine speed *N* (26 speeds, 500–6750 rpm, down the side) and manifold absolute pressure *p<sub>m</sub>* (43 pressures, 0–105 kPa, across the top). The engine control unit knows both at every instant, from the crankshaft sensor and the MAP sensor, and looks everything up there.

| File | Gives | Unit |
| --- | --- | --- |
| `torque_Nm.csv` | brake torque | N·m |
| `fuel_gps.csv` | fuel mass flow | g/s |
| `lambda.csv` | λ, the air-fuel ratio over 14.6 | — |
| `full_load.csv` | the most torque the engine reaches at each speed | N·m |

The data is the US EPA's ALPHA map of a 2014 Mazda 2.0 L Skyactiv, scaled to 1.5 L. How it was converted, and every assumption, is in `data/engine/README.md` in the course repository.

#### Do this

1. In the Julia REPL, load a map and draw it:

   ```julia
   using DelimitedFiles, Plots, VehicleSystemsComponents
   dir = joinpath(pkgdir(VehicleSystemsComponents), "data", "engine")
   function engine_map(name)
       M, head = readdlm(joinpath(dir, name), ','; header = true)
       return parse.(Float64, vec(head)[2:end]), M[:, 1], M[:, 2:end]
   end
   kpa, rpm, T = engine_map("torque_Nm.csv")
   heatmap(kpa, rpm, T; xlabel = "p_m [kPa]", ylabel = "N [rpm]", title = "torque [N·m]")
   ```

2. Do the same for `fuel_gps.csv` and `lambda.csv`.
3. **Find 90 km/h.** From hands-on 1, step 05: at 90 km/h the engine turns **3080 rpm** and must give **31.1 N·m**. Print the nearest row of the torque map with `T[rpm .== 3000, :]` and find the two pressures between which it passes 31.1 N·m. Interpolate.
4. Read the fuel map's 3000 rpm row at that pressure.
5. Turn it into consumption: g/s × 3600 ÷ 745 g/L = L/h; then L/h ÷ 90 km/h × 100 = L/100 km.

<!-- TODO(screenshot): step01-torque-map.png and step01-fuel-map.png, the 90 km/h point marked. -->

::: tip Checkpoint

Computed from the tables:

- Torque reaches about **150 N·m** near 4000 rpm at 100 kPa, and is negative at low pressure: the engine pumping against a vacuum.
- The 3000 rpm row passes 31.1 N·m at about **47.7 kPa** (30.7 N·m at 47.5, 35.6 at 50).
- Fuel there: about **0.82 g/s** → 4.0 L/h → **4.4 L/100 km**. Interpolating to 3080 rpm exactly gives 0.85 g/s, 4.10 L/h and **4.6 L/100 km**; step 05 measures it.
- λ is **1** up to about 80 kPa and **0.87** at 3000 rpm, 100 kPa: the engine runs rich only near full load.

:::

### 02 Manifold: a pressure that fills <Badge type="info" text="15 min" /> {#manifold}

Build the intake manifold as one equation, and watch its pressure pull down to 33 kPa at idle.

Theory: [tutor slides — mass in, mass out](../../handson-02/index.html#/filling){target="_self"}

#### Where you are, where you are going

The manifold is a box of air between the throttle and the cylinders. Air comes in through the throttle and leaves into the cylinders; its pressure is what is left, and it takes time to change:

**V<sub>m</sub> / (R T<sub>m</sub>) · dp<sub>m</sub>/dt = ṁ<sub>thr</sub> + ṁ<sub>bst</sub> − ṁ<sub>cyl</sub>**

You write this equation as a component, then put it on a bench between two given parts: the `Throttle`, whose flow the pedal sets, and `CylinderAirflow`, which draws more air the higher the pressure and the faster the engine turns. The brake booster's flow `ṁ_bst` is zero today.

#### A · Paste the manifold

1. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `MyCar` → **Add Component** and name it `Manifold`.
2. Toggle to code (⇄), select everything with <kbd>Ctrl</kbd>+<kbd>A</kbd>, paste the block below and save.

::: code-group

```txt [Manifold]
"""
Intake manifold as one isothermal receiver: the pressure is its only state.
"""
component Manifold
  "Air flow in through the throttle [kg/s]"
  mdot_thr = RealInput()
  "Air flow in from the brake booster [kg/s]"
  mdot_bst = RealInput()
  "Air flow out into the cylinders [kg/s]"
  mdot_cyl = RealInput()
  "Manifold absolute pressure [Pa]"
  p_m = RealOutput()
  "Manifold volume"
  parameter V_m::Volume = 1.0e-3
  "Manifold air temperature"
  parameter T_m::Temperature = 298.15
  "Gas constant of air [J/(kg.K)]"
  parameter R::Real = 287.05
  "Manifold absolute pressure"
  variable p::Pressure
relations
  V_m / (R * T_m) * der(p) = mdot_thr + mdot_bst - mdot_cyl
  p_m = p
end
```

:::

<!-- TODO(screenshot): step02-manifold-code.png. -->

#### B · The bench

| Name | Library path | Set |
| --- | --- | --- |
| `throttle_cmd` | BlockComponents › Sources › Step | `offset = 0`, `height = 0.005`, `start_time = 1` |
| `speed` | BlockComponents › Sources › Constant | `k = 83.776` (800 rpm in rad/s) |
| `no_booster` | BlockComponents › Sources › Constant | `k = 0` |
| `throttle` | VehicleSystemsComponents › Vehicle › Engine › Throttle | — |
| `cylinders` | VehicleSystemsComponents › Vehicle › Engine › CylinderAirflow | — |
| `manifold` | your `Manifold` | — |

3. <Badge type="tip" text="New component" /> Add a component `AirPathStep` and place the six parts of the table.
4. Wire `throttle_cmd` → `throttle.u_thr`, `speed` → `cylinders.omega`, `no_booster` → `manifold.mdot_bst`.
5. Wire the flows: `throttle.mdot_thr` → `manifold.mdot_thr`, `cylinders.mdot_cyl` → `manifold.mdot_cyl`.
6. Wire the pressure back: `manifold.p_m` → `throttle.p_m` and → `cylinders.p_m`. Both flows depend on it; this loop is what makes the pressure settle.
7. Toggle to code and add `initial manifold.p = 101325` at the end of `relations`: the manifold starts full of outside air.
8. <Badge type="tip" text="New analysis" /> ▷ **Run Analysis** → **TransientAnalysis**, named `AirPathStepTransient`, `stop = 3`.

::: code-group

```txt [AirPathStep and AirPathStepTransient]
component AirPathStep
  throttle_cmd = BlockComponents.Sources.Step(offset = 0, height = 0.005, start_time = 1)
  "800 rpm"
  speed = BlockComponents.Sources.Constant(k = 83.776)
  no_booster = BlockComponents.Sources.Constant(k = 0)
  throttle = VehicleSystemsComponents.Vehicle.Engine.Throttle()
  cylinders = VehicleSystemsComponents.Vehicle.Engine.CylinderAirflow()
  manifold = Manifold()
relations
  connect(throttle_cmd.y, throttle.u_thr)
  connect(speed.y, cylinders.omega)
  connect(no_booster.y, manifold.mdot_bst)
  connect(throttle.mdot_thr, manifold.mdot_thr)
  connect(cylinders.mdot_cyl, manifold.mdot_cyl)
  connect(manifold.p_m, throttle.p_m, cylinders.p_m)
  initial manifold.p = 101325
end

analysis AirPathStepTransient
  extends TransientAnalysis(stop = 3)
  model = AirPathStep()
end
```

:::

<!-- TODO(screenshot): step02-airpath-bench.png. -->

#### C · Run it at idle, then at 3000 rpm

9. Run `AirPathStepTransient` and plot the pressure:

   ```julia
   using Plots
   r = MyCar.AirPathStepTransient()
   plot(r; idxs = r."manifold.p_m")
   ```

10. Set `speed` to `k = 314.159` (3000 rpm) and `throttle_cmd` to `height = 1` (wide open at 1 s). Run and plot again.

<!-- TODO(screenshot): step02-idle-plot.png. -->

::: tip Checkpoint

The same numbers as the course model's tests (`Vehicle.Engine.TestAirPath`), which use this equation:

- **Idle, 800 rpm:** 101.3 kPa falls to **33.0 kPa** well within the first second, settling with a time constant of about **0.15 s**; the small throttle step at 1 s lifts it to **37.3 kPa**.
- **3000 rpm:** closed, the pressure falls to **13.5 kPa** (overrun); wide open it rises to **99.9 kPa**, almost the outside air. It settles about five times faster than at idle, τ ≈ **0.03 s**.

The plot is in pascals: 33 000 is 33 kPa.

:::

Commit: **Source Control** → message `Step 02: manifold` → **Commit** → **Sync Changes**.

<!-- TODO(reference): a "Stuck? The full model" block from dyad/HandsOn02/Manifold.dyad once it exists. -->

### 03 Map engine on a dynamometer <Badge type="info" text="20 min" /> {#map-engine}

An engine of your own: pedal in; torque, fuel and CO₂ out, read from the maps at speed and manifold pressure.

Theory: [tutor slides — four lines make the engine](../../handson-02/index.html#/engine-equations){target="_self"}

#### Where you are, where you are going

Your engine has four lines that matter:

- the throttle follows the pedal through a progressive curve, `u_thr = pedal^1.5`;
- torque is the torque map at (*N*, *p<sub>m</sub>*), never more than the full-load curve;
- fuel is the fuel map at (*N*, *p<sub>m</sub>*);
- CO₂ is 3.09 × fuel: each kilogram of petrol burned completely makes 3.09 kg of CO₂.

The manifold pressure comes from `AirPath`, the course library's version of your step 02 bench, packaged as one part. The maps come from `EngineMapData`, which holds the CSV files as parameters. You test the engine on a **dynamometer**: a bench that holds the shaft at a fixed speed whatever the engine does, so a pedal step shows only the engine.

#### A · Paste the engine and read it

1. <Badge type="tip" text="New component" /> Add a component `MapEngine`, toggle to code, select everything, paste the block below and save.

::: code-group

```txt [MapEngine]
"""
Pedal in; torque, fuel and CO2 out, read from the maps at engine speed and manifold pressure.
"""
component MapEngine
  extends VehicleSystemsComponents.Vehicle.Engine.EngineMapData
  "Pedal, 0 released to 1 floored"
  pedal = RealInput()
  "Output shaft"
  spline = Spline()
  "Engine mounts"
  support = Spline()
  "Manifold absolute pressure [Pa]"
  p_m = RealOutput()
  "Brake torque [N.m]"
  tau_e = RealOutput()
  "Fuel mass flow [kg/s]"
  mdot_fuel = RealOutput()
  "CO2 mass flow [kg/s]"
  mdot_co2 = RealOutput()
  air = VehicleSystemsComponents.Vehicle.Engine.AirPath()
  no_booster = BlockComponents.Sources.Constant(k = 0)
  torque_map = BlockComponents.Tables.InterpolatedTable(axis1 = rpm_axis, axis2 = kpa_axis, data = torque_data, interpolation_dim1 = BlockComponents.Tables.InterpolationDimension.LinearInterpolationDimension(), interpolation_dim2 = BlockComponents.Tables.InterpolationDimension.LinearInterpolationDimension())
  fuel_map = BlockComponents.Tables.InterpolatedTable(axis1 = rpm_axis, axis2 = kpa_axis, data = fuel_data, interpolation_dim1 = BlockComponents.Tables.InterpolationDimension.LinearInterpolationDimension(), interpolation_dim2 = BlockComponents.Tables.InterpolationDimension.LinearInterpolationDimension())
  full_load = BlockComponents.Tables.InterpolatedTable(axis1 = full_load_rpm, axis2 = curve_axis, data = full_load_data, interpolation_dim1 = BlockComponents.Tables.InterpolationDimension.LinearInterpolationDimension(), interpolation_dim2 = BlockComponents.Tables.InterpolationDimension.LinearInterpolationDimension())
  torque = RotationalComponents.Sources.TorqueSource()
  crankshaft = RotationalComponents.Components.Inertia(J = 0.15)
  "Engine speed [rpm], clamped to the map"
  variable N::Real
  "Manifold pressure [kPa], clamped to the map"
  variable p_kPa::Real
relations
  air.u_thr = min(max(pedal, 0), 1)^1.5
  air.omega = crankshaft.w
  connect(no_booster.y, air.mdot_bst)
  connect(air.p_m, p_m)
  N = min(max(crankshaft.w * 30 / pi, 500), 6750)
  p_kPa = min(max(air.p_m / 1000, 0), 105)
  torque_map.u1 = N
  torque_map.u2 = p_kPa
  fuel_map.u1 = N
  fuel_map.u2 = p_kPa
  full_load.u1 = N
  full_load.u2 = 0
  tau_e = min(torque_map.y, full_load.y)
  mdot_fuel = fuel_map.y / 1000
  mdot_co2 = 3.09 * mdot_fuel
  torque.tau = tau_e
  connect(torque.spline, crankshaft.spline_a)
  connect(crankshaft.spline_b, spline)
  connect(torque.support, support)
end
```

:::

<!-- TODO(reference): verify against dyad/HandsOn02/MapEngine.dyad once written; EngineMapData and
its field names (rpm_axis, kpa_axis, torque_data, fuel_data, full_load_rpm, curve_axis,
full_load_data) are on feat/lecture02-mapped-engine, task 3, not merged. -->
<!-- TODO(screenshot): step03-map-engine-code.png. -->

2. Read it top to bottom:
   - `extends …EngineMapData` brings in the axes and the tables as parameters.
   - `air` is the given air path; `no_booster` holds its booster input at zero.
   - `N` and `p_kPa` convert rad/s to rpm and Pa to kPa — the units the tables use — and clamp them to the tables' edges.
   - `tau_e = min(…)` is the full-load cap: the map runs to 105 kPa, which the engine never reaches.
   - `mdot_fuel` converts g/s to kg/s; `mdot_co2` is 3.09 × fuel.
   - The torque drives a 0.15 kg·m² `crankshaft` inertia; `spline` and `support` are the shaft and the mounts, as in hands-on 1.

#### B · The dynamometer bench

| Name | Library path | Set |
| --- | --- | --- |
| `pedal` | BlockComponents › Sources › Step | `height = 1`, `offset = 0`, `start_time = 1` |
| `speed` | BlockComponents › Sources › Constant | `k = 314.159` (3000 rpm) |
| `engine` | your `MapEngine` | — |
| `dyno` | RotationalComponents › Sources › VelocitySource | — |
| `mounts` | RotationalComponents › Components › Fixed | — |

3. <Badge type="tip" text="New component" /> Add a component `MapEngineDyno` and place the parts.
4. Wire `pedal` → `engine.pedal`, `speed` → `dyno.w_ref`, `engine.spline` → `dyno.spline`, and both `engine.support` and `dyno.support` → `mounts`.
5. In code, add the two `initial` lines from the block below. The manifold starts at the 3000 rpm overrun pressure from step 02.
6. <Badge type="tip" text="New analysis" /> **TransientAnalysis**, named `MapEngineDynoTransient`, `stop = 3`.

::: code-group

```txt [MapEngineDyno and MapEngineDynoTransient]
component MapEngineDyno
  pedal = BlockComponents.Sources.Step(height = 1, offset = 0, start_time = 1)
  "3000 rpm"
  speed = BlockComponents.Sources.Constant(k = 314.159)
  engine = MapEngine()
  dyno = RotationalComponents.Sources.VelocitySource()
  mounts = RotationalComponents.Components.Fixed()
relations
  connect(pedal.y, engine.pedal)
  connect(speed.y, dyno.w_ref)
  connect(engine.spline, dyno.spline)
  connect(engine.support, mounts.spline)
  connect(dyno.support, mounts.spline)
  initial engine.crankshaft.phi = 0
  initial engine.air.manifold.p = 13482.4
end

analysis MapEngineDynoTransient
  extends TransientAnalysis(stop = 3)
  model = MapEngineDyno()
end
```

:::

<!-- TODO(screenshot): step03-dyno-bench.png. -->

#### C · Run it

7. Run it and plot the pressure and the torque, then the fuel:

   ```julia
   r = MyCar.MapEngineDynoTransient()
   plot(r; idxs = [r."engine.p_m", r."engine.tau_e"], layout = (2, 1))
   plot(r; idxs = r."engine.mdot_fuel")
   ```

   Zoom into 0.9–1.3 s: the torque follows the pressure, not the pedal.

<!-- TODO(screenshot): step03-tip-in-plot.png. -->
<!-- TODO(checkpoint): the 10–90 % rise time of engine.tau_e after the step, from
HandsOn02.MapEngineDynoTransient. -->

::: tip Checkpoint

At 3000 rpm, the pressures from step 02 and the maps read there:

| | pedal released | pedal floored |
| --- | --: | --: |
| `engine.p_m` | 13.5 kPa | 99.9 kPa |
| `engine.tau_e` | −18.2 N·m | **148.4 N·m** |
| `engine.mdot_fuel` | 0.097 g/s | 3.75 g/s |
| `engine.mdot_co2` | 0.30 g/s | 11.6 g/s |

Without the cap the map would give 163.1 N·m. The plot shows kg/s: 0.00375 is 3.75 g/s.

:::

#### D · Swap in the course engine: fuel cut

With the pedal released at 3000 rpm your engine still burns 0.097 g/s while making negative torque. A real engine control unit cuts the fuel on overrun and turns it back on near idle so the engine does not stall. The course library's `MappedEngine` does; otherwise it reads the same maps.

8. In `MapEngineDyno`, delete `engine`. Click **+** → `VehicleSystemsComponents › Vehicle › Engine › MappedEngine` and name it `engine`. Rewire `pedal`, `spline` and `support` as before.
9. `MappedEngine` has one more input, the brake booster's air flow. Add `no_booster` = `BlockComponents › Sources › Constant` with `k = 0` and wire it to `engine.mdot_bst`.
10. Make the pedal a release: `pedal` with `offset = 1`, `height = -1`. Change the manifold's initial value to `99889.9`, the wide-open pressure. Run and plot `engine.mdot_fuel` and `engine.tau_e`.

<!-- TODO(screenshot): step03-fuel-cut-plot.png. -->

::: tip Checkpoint

Before 1 s the course engine gives the same 148.4 N·m and 3.75 g/s as yours. At the release the fuel drops to **0**, and the torque to **−18.7 N·m**, the engine's measured closed-throttle (motored) torque at 3000 rpm. It would refuel below 1000 rpm; the cut only arms above 1300 rpm.

`MappedEngine` also has `lambda`, `mdot_hc`, `mdot_co` and `mdot_nox` outputs. The HC, CO and NOx tables are **assumed**: their shapes follow textbook trends and their sizes are typical, not measured. Use them for trends only.

:::

Commit: **Source Control** → message `Step 03: map engine` → **Commit** → **Sync Changes**.

## Drive the car

Steps 4–6 · the course engine in your hands-on 1 car · 32 min

### 04 The car with a mapped engine <Badge type="info" text="12 min" /> {#mapped-car}

Your hands-on 1 car with the course engine and a pedal — and a real top speed.

Theory: [tutor slides — top speed, with a torque curve](../../handson-02/index.html#/top-speed-again){target="_self"}

#### Where you are, where you are going

Same body, same driveline, same single gear of 4.0. The engine changes, and with it the input: a pedal from 0 to 1 instead of a torque. Two new outputs read the manifold pressure and the fuel in liters per hour. Hands-on 1's car reached 246 km/h at 8400 rpm; this engine gives less at high revs and stops fueling at 6500 rpm.

#### Do this

1. In **Components**, right-click your `Car` → **Duplicate**, and name the copy `MappedCar`. Your hands-on 1 car stays as it was.
2. Open `MappedCar`. Delete `engine`. Click **+** → `VehicleSystemsComponents › Vehicle › Engine › MappedEngine`, name it `engine`, and put it where the old one was.
3. Rename the input port `tau_cmd` to `pedal`, and wire it to `engine.pedal`.
4. Wire `engine.spline` → `driveline.spline` and `engine.support` → `rot_ground`, as before.
5. Add `no_booster` = `BlockComponents › Sources › Constant` (`k = 0`) → `engine.mdot_bst`.
6. Add two `RealOutput` ports on the right edge, `p_m` and `fuel_lph`. Wire `engine.p_m` → `p_m`. Add `to_lph` = `BlockComponents › Math › Gain` with `k = 4832.2` between `engine.mdot_fuel` and `fuel_lph`: × 3600 s/h ÷ 0.745 kg/L turns kg/s of petrol into L/h.
7. <Badge type="tip" text="New component" /> The bench `MappedCarWOT`: `pedal` = `Constant(k = 1)` → `car.pedal`, with the `initial` lines below. <Badge type="tip" text="New analysis" /> `MappedCarWOTTransient`, `stop = 120`.

::: code-group

```txt [MappedCar, as code]
component MappedCar
  pedal = RealInput()
  v_kmh = RealOutput()
  p_m = RealOutput()
  fuel_lph = RealOutput()
  engine = VehicleSystemsComponents.Vehicle.Engine.MappedEngine()
  no_booster = BlockComponents.Sources.Constant(k = 0)
  "kg/s of petrol to L/h: 3600 / 0.745"
  to_lph = BlockComponents.Math.Gain(k = 4832.2)
  driveline = Driveline()
  body = Body()
  vsensor = TranslationalComponents.Sensors.VelocitySensor()
  to_kmh = BlockComponents.Math.Gain(k = 3.6)
  rot_ground = RotationalComponents.Components.Fixed()
  trans_ground = TranslationalComponents.Components.Fixed()
relations
  connect(pedal, engine.pedal)
  connect(no_booster.y, engine.mdot_bst)
  connect(engine.spline, driveline.spline)
  connect(engine.support, rot_ground.spline)
  connect(driveline.support_r, rot_ground.spline)
  connect(driveline.flange, body.flange)
  connect(driveline.support_t, trans_ground.flange)
  connect(vsensor.flange, body.flange)
  connect(vsensor.v, to_kmh.u)
  connect(to_kmh.y, v_kmh)
  connect(engine.p_m, p_m)
  connect(engine.mdot_fuel, to_lph.u)
  connect(to_lph.y, fuel_lph)
end
```

```txt [MappedCarWOT and MappedCarWOTTransient]
component MappedCarWOT
  "Pedal floored"
  pedal = BlockComponents.Sources.Constant(k = 1)
  car = MappedCar()
relations
  connect(pedal.y, car.pedal)
  initial car.body.mass.s = 0
  initial car.body.mass.v = 0
  initial car.engine.air.manifold.p = 101325
end

analysis MappedCarWOTTransient
  extends TransientAnalysis(stop = 120)
  model = MappedCarWOT()
end
```

:::

<!-- TODO(reference): confirm the initial lines on HandsOn02.MappedCarWOT. The crankshaft is tied to
the wheel through the gear, so it should take no initial speed of its own. -->
<!-- TODO(screenshot): step04-mapped-car.png. -->

8. Run it and plot the speed:

   ```julia
   r = MyCar.MappedCarWOTTransient()
   plot(r; idxs = r."car.v_kmh")
   ```

<!-- TODO(screenshot): step04-wot-plot.png. -->
<!-- TODO(checkpoint): time to 100 km/h, and whether the speed saws between 184 and 190 km/h, from
HandsOn02.MappedCarWOTTransient. -->

::: tip Checkpoint

The car tops out at about **190 km/h**, not 246. Drag alone would hold it at 192 km/h, where the engine turns 6570 rpm and gives 96 N·m; but at **6500 rpm = 189.9 km/h** the rev limiter cuts the fuel, and it refuels at 6300 rpm = 184.1 km/h.

:::

Commit: **Source Control** → message `Step 04: mapped car` → **Commit** → **Sync Changes**.

### 05 Cruise: fuel and CO₂ <Badge type="info" text="12 min" /> {#cruise}

Hold 50, 90 and 130 km/h, read the fuel in liters per hour, and turn it into L/100 km and g CO₂/km.

Theory: [tutor slides — from L/h to the sticker](../../handson-02/index.html#/per-distance){target="_self"}

#### Where you are, where you are going

At a steady speed the fuel flow in L/h, divided by the speed in km/h, is liters per kilometer:

- **L/100 km** = L/h ÷ km/h × 100
- **g CO₂/km** = L/h × 2302 ÷ km/h

2302 g of CO₂ per liter is 745 g of petrol × 3.09. Step 01 predicted 4.6 L/100 km at 90 km/h from the table alone; now the car gives it.

#### Do this

1. <Badge type="tip" text="New component" /> The bench `MappedCarCruise`: `pedal` = `Constant(k = 0.2)` → `car.pedal`, with the `initial` lines below. <Badge type="tip" text="New analysis" /> `MappedCarCruiseTransient`, `stop = 60`.
2. Run it and plot speed and fuel:

   ```julia
   r = MyCar.MappedCarCruiseTransient()
   plot(r; idxs = [r."car.v_kmh", r."car.fuel_lph"], layout = (2, 1))
   ```

3. **Find the pedal that holds 90 km/h.** If `car.v_kmh` creeps up over the 60 s, lower `pedal`'s `k`; if it creeps down, raise it. Steps of 0.01 are fine. The car's own time constant is about a minute, so a wrong pedal shows as a slow drift.
4. When the speed stays within ±1 km/h, read `car.fuel_lph` and `car.p_m` at 60 s and work out L/100 km and g CO₂/km.
5. Repeat for **50 km/h** (`car.body.mass.v` = 13.89, manifold 41900) and **130 km/h** (36.11, 60800).

::: code-group

```txt [MappedCarCruise and MappedCarCruiseTransient]
component MappedCarCruise
  pedal = BlockComponents.Sources.Constant(k = 0.2)
  car = MappedCar()
relations
  connect(pedal.y, car.pedal)
  initial car.body.mass.s = 0
  "90 km/h"
  initial car.body.mass.v = 25
  initial car.engine.air.manifold.p = 47800
end

analysis MappedCarCruiseTransient
  extends TransientAnalysis(stop = 60)
  model = MappedCarCruise()
end
```

:::

<!-- TODO(actions): replace the pedal search with the values that hold 50, 90 and 130 km/h, to
three decimals, from task 4's cruise runs. -->
<!-- TODO(screenshots): step05-cruise-bench.png, step05-cruise-90-plot.png. -->

::: tip Checkpoint

Predicted from the maps for this car; your table should match to the last digit shown:

| km/h | engine rpm | `p_m` kPa | `fuel_lph` | L/100 km | g CO₂/km |
| --: | --: | --: | --: | --: | --: |
| 50 | 1710 | 41.9 | 1.67 | **3.4** | **77** |
| 90 | 3080 | 47.8 | 4.10 | **4.6** | **105** |
| 130 | 4450 | 60.8 | 9.14 | **7.0** | **162** |

λ is 1 at all three. These are steady-state, one-gear figures with a warm engine and nothing switched on, so they sit below a real car's label; step 07 makes the fair comparison.

:::

Commit: **Source Control** → message `Step 05: cruise` → **Commit** → **Sync Changes**.

### 06 Coast-down and a brake stop <Badge type="info" text="8 min" /> {#coast-brake}

Lift off at 90 km/h and the fuel stops; brake, and read the vacuum the brake booster draws on.

Theory: [tutor slides — lift off at 90 km/h](../../handson-02/index.html#/coast-brake){target="_self"}

#### Where you are, where you are going

With the pedal up at speed, the throttle closes and the manifold drops to the overrun pressure of step 02. The engine control unit cuts the fuel completely, and the engine, driven by the wheels, pumps air against that vacuum: it brakes the car. A brake booster draws its vacuum from this manifold, so you plot that too.

#### A · Coast down

1. <Badge type="tip" text="New component" /> Copy `MappedCarCruise` as `MappedCarCoast`. Make `pedal` a `BlockComponents › Sources › Step` with `offset` = your 90 km/h pedal value, `height` = minus it, `start_time = 5`. <Badge type="tip" text="New analysis" /> `MappedCarCoastTransient`, `stop = 90`.
2. Run it; plot `car.v_kmh`, `car.fuel_lph` and `car.p_m`, one above the other.

<!-- TODO(screenshot): step06-coast-plot.png. -->
<!-- TODO(checkpoint): p_m at the fuel-resume instant, from task 4's coast-down run. -->

::: tip Checkpoint

- At 5 s the fuel drops from 4.10 L/h to **0**, and `p_m` falls to about **13.5 kPa**.
- The car slows at **0.46 m/s²**: 401 N of drag and rolling plus 246 N of engine braking (−19 N·m × 4 / 0.31) on 1400 kg. In neutral it would be 0.29 m/s².
- The fuel comes back on at **29 km/h**, where the engine drops below 1000 rpm.

:::

#### B · Brake

3. In `MappedCar`, add an input `F_brake` and `brake` = `TranslationalComponents › Sources › Force`. Wire `F_brake` → `brake.f`, one flange of `brake` to `body.flange` and the other to `trans_ground`.
4. In `MappedCarCoast`, add `brake_cmd` = `Step(height = 4000, start_time = 5)` → `car.F_brake`, and set `stop = 10`. Your other car benches now have an input nobody drives: give each a `Constant(k = 0)` into `car.F_brake` before running them again.
5. Run it and plot `car.v_kmh` and `car.p_m`.

<!-- TODO(reference): the brake force's sign as wired, p_m during the stop and the time to 25 km/h,
from task 4's brake-stop run; then give the one correct flange wiring instead of "swap". -->
<!-- TODO(screenshot): step06-brake-plot.png. -->

::: tip Checkpoint

The car slows far faster than in the coast-down — if it speeds up, swap the two flanges of `brake`. `p_m` stays deep below the outside 101 kPa through the stop: that is the vacuum the brake booster works with. The car has no clutch, so below about 25 km/h the engine is dragged toward a stall; read the plot only down to there.

:::

Commit: **Source Control** → message `Step 06: coast and brake` → **Commit** → **Sync Changes**.

### Hand in: open a pull request <Badge type="info" text="3 min" /> {#hand-in}

A pull request that asks to merge `handson-02` into the branch you started from.

#### Do this

1. In **Source Control**, check there is nothing left to commit and nothing waiting to sync.
2. Open your `MyCar` repository on github.com → **Compare & pull request**. Base: the branch `handson-02` was created from. Compare: `handson-02`.
3. Title: `Lecture 2 hands-on`. In the description, put your step 05 table — three speeds, L/100 km and g CO₂/km — and anything that did not match.
4. Click **Create pull request**. Do *not* merge it.

::: tip Checkpoint

The pull request is open on github.com and its **Commits** tab lists one commit per step.

:::

### 07 WLTC: the test cycle <Badge type="info" text="if time allows" /> {#wltc}

The same engine with a gearbox and a driver, following the 30-minute speed trace a car's label is measured on.

Theory: [tutor slides — what changes, and what to compare](../../handson-02/index.html#/wltc){target="_self"}

Steady cruise is not how anyone drives, and it is not how the label is measured. The WLTC class 3 trace runs 1800 s through town, suburb, road and motorway, up to 131 km/h. To follow it the car needs a gearbox with a shift schedule, so the engine stays near its efficient middle, and a driver: a PI controller from speed error to pedal, Lecture 1's cruise control following a trace instead of a setpoint. Compare your L/100 km and g CO₂/km over the whole cycle with a real 1.5 L petrol car's label.

<!-- TODO(whole step): task 6 (scope B). Model names, actions, the checkpoint numbers, and a real
1.5 L car's label figure with its source. If task 6 is not ready, link the prepared notebook. -->

---

Data: `data/engine/` in the course repository, from the US EPA ALPHA package (2014 Mazda 2.0L SKYACTIV Engine LEV III Fuel, version 2018-02). Design notes: `docs/lecture-02-mapped-engine-plan.md` and `docs/lecture-02-handson-plan.md`.
