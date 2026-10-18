---
title: Lecture 2 hands-on — drive a mapped engine
---

[← Vehicle Systems & Components](../../index.html) · [Tutor deck →](../../handson-02/index.html){target="_self"}

# Lecture 2 hands-on: drive a mapped engine

From measured engine maps to the fuel and CO₂ your car burns at 50, 90 and 130 km/h

**Why we build it.** Lecture 1's engine gave 150 N·m at every speed and could not say how much fuel it burned. A real engine control unit reads tables measured on a test bench, at the engine speed and the pressure in the intake manifold. **What you build:** the manifold, whose pressure fills and empties, and a small engine of your own that reads torque and fuel from those tables. Then you paste the course library's fuel cut into your engine, put it into your hands-on 1 car and drive it: flat out, at steady speeds, lifting off and braking. By the end you have your car's fuel consumption in L/100 km and its CO₂ in g/km, the two numbers on a car's sticker.

**How each step works.** It starts with the idea it needs. Your tutor explains it from the [tutor deck](../../handson-02/index.html){target="_self"}, and the *Theory* link under each step's goal opens those slides. Then you build, and the checkpoint is a number you could have predicted first. **Before this session:** the [engine lecture](../../lecture-02/index.html#/mapped-engine){target="_self"}, whose last section shows what you build here.

You build on your `MyCar` library from [hands-on 1](../lecture-01/). The throttle, the cylinders' air flow, the map tables and the fuel-cut logic come from the course library, `VehicleSystemsComponents`: they are physics the lecture stated, not what this session teaches. The budgets add up to about 90 minutes; step 07 is for when time is left.

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

   It downloads and precompiles: a few minutes. Read step 01 meanwhile. A yellow warning that packages are precompiled but "different versions are currently loaded … Restart julia" is harmless: carry on.
3. <kbd>F1</kbd> → `Dyad: Compile`.
4. Open any diagram (double-click it in the **Components** tree), click **+** and open `VehicleSystemsComponents` → `Vehicle` → `Engine`. The course library shows under **+**, not in the **Components** tree on the left: that is expected.

[![The diagram toolbar's plus popup opened at VehicleSystemsComponents › Vehicle › Engine: under the folders HandsOn, HandsOn02, Lecture1, Lecture2 and Vehicle › Brake, the Engine folder lists AirPath, CutBlend, CutFuelMap, CutMap, CutTorqueMap, CylinderAirflow, ElectronicThrottle and more, down to MappedEngine, PedalMap and the Test models; Throttle is further down the list.](/handson/lecture-02/img/step00-engine-library.png){style="max-width:324px" width="324" height="878"}](/handson/lecture-02/img/step00-engine-library.png)
<!-- TODO: pin Pkg.add to a tag once the course library's branch merges. -->

::: tip Checkpoint

`Engine` includes `AirPath`, `CylinderAirflow`, `MappedEngine` and `Throttle`, among many more, and `using VehicleSystemsComponents` runs in the REPL without an error.

:::

::: warning The answers are in the + tree

Under **+**, `VehicleSystemsComponents` also holds a `HandsOn02` folder and, in `Vehicle › Engine`, the `Test…` components: they are the reference answers to today's steps. Build your own; open them only to compare.

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
   kpa, rpm, T = engine_map("torque_Nm.csv");
   heatmap(kpa, rpm, T; xlabel = "p_m [kPa]", ylabel = "N [rpm]", title = "torque [N·m]")
   ```

2. Do the same for `fuel_gps.csv` and `lambda.csv`, under their own names so `T` stays the torque map: `_, _, F = engine_map("fuel_gps.csv");` and `_, _, L = engine_map("lambda.csv");`, then `heatmap(kpa, rpm, F; …)` and `heatmap(kpa, rpm, L; …)`.
3. **Find 90 km/h.** From hands-on 1, step 05: at 90 km/h the engine turns **3080 rpm** and must give **31.1 N·m**. Print the nearest row of the torque map next to its pressures with `[kpa vec(T[rpm .== 3000, :])]` and find the two pressures between which it passes 31.1 N·m. Interpolate. Give your own results names longer than one letter, such as `p_cruise` and `fuel_cruise`: a one-letter name like `f` is easy to reuse by accident later.
4. Read the fuel map's 3000 rpm row at that pressure.
5. Turn it into consumption: g/s × 3600 ÷ 745 g/L = L/h; then L/h ÷ 90 km/h × 100 = L/100 km.

[![The torque map as a heat map, engine speed against manifold pressure: torque rises from about −25 N·m at low pressure to about 175 N·m at full pressure, and a white dot marks the 90 km/h point at 3080 rpm and 47.8 kPa.](/handson/lecture-02/img/step01-torque-map.png){width="990" height="528"}](/handson/lecture-02/img/step01-torque-map.png)

[![The fuel map on the same axes: fuel flow rises from near 0 g/s at low pressure to about 8 g/s at full pressure and high speed, with the 90 km/h point at 3080 rpm and 47.8 kPa marked.](/handson/lecture-02/img/step01-fuel-map.png){width="990" height="528"}](/handson/lecture-02/img/step01-fuel-map.png)

::: tip Checkpoint

Computed from the tables:

- The map gives **160.3 N·m** at 4000 rpm and 100 kPa, and peaks at **177 N·m** near 3250 rpm and 105 kPa. It is negative at low pressure: the engine pumping against a vacuum.
- The 3000 rpm row passes 31.1 N·m at about **47.7 kPa** (30.7 N·m at 47.5, 35.6 at 50).
- Fuel there: about **0.82 g/s** → 4.0 L/h → **4.4 L/100 km**.
- The 90 km/h point itself, at 3080 rpm between the 3000 and 3250 rpm rows, sits at **47.8 kPa**: 0.850 g/s, 4.11 L/h and **4.6 L/100 km**. Step 05 measures it. Mark your plots there.
- λ is **1** up to about 80 kPa and **0.87** at 3000 rpm, 100 kPa: the engine runs rich only near full load.

The same reading at the other two speeds step 05 drives, from hands-on 1's holding torques:

| km/h | engine rpm | N·m | `p_m` kPa | fuel g/s | L/h | L/100 km | g CO₂/km |
| --: | --: | --: | --: | --: | --: | --: | --: |
| 50 | 1710 | 18.4 | 41.9 | 0.346 | 1.67 | **3.3** | **77** |
| 90 | 3080 | 31.1 | 47.8 | 0.850 | 4.11 | **4.6** | **105** |
| 130 | 4450 | 51.0 | 60.8 | 1.892 | 9.14 | **7.0** | **162** |

g CO₂/km is 3.09 × fuel in g/s ÷ speed in m/s × 1000.

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
2. Toggle to code (⇄), select everything with <kbd>Ctrl</kbd>+<kbd>A</kbd>, paste the block below and save. This also replaces the template's `metadata` block: that is fine.

The `{"Dyad": …}` annotation after each port only places it on the block's edge: three flows in on the left, `p_m` out on the right.

::: code-group

```txt [Manifold]
"""
Intake manifold as one isothermal receiver: the pressure is its only state.
"""
component Manifold
  "Air flow in through the throttle [kg/s]"
  mdot_thr = RealInput() {"Dyad": {"placement": {"icon": {"x1": -50, "y1": 200, "x2": 50, "y2": 300}, "diagram": {"x1": -50, "y1": 200, "x2": 50, "y2": 300}}}}
  "Air flow in from the brake booster [kg/s]"
  mdot_bst = RealInput() {"Dyad": {"placement": {"icon": {"x1": -50, "y1": 450, "x2": 50, "y2": 550}, "diagram": {"x1": -50, "y1": 450, "x2": 50, "y2": 550}}}}
  "Air flow out into the cylinders [kg/s]"
  mdot_cyl = RealInput() {"Dyad": {"placement": {"icon": {"x1": -50, "y1": 700, "x2": 50, "y2": 800}, "diagram": {"x1": -50, "y1": 700, "x2": 50, "y2": 800}}}}
  "Manifold absolute pressure [Pa]"
  p_m = RealOutput() {"Dyad": {"placement": {"icon": {"x1": 950, "y1": 450, "x2": 1050, "y2": 550}, "diagram": {"x1": 950, "y1": 450, "x2": 1050, "y2": 550}}}}
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

[![The Manifold component in the code view: the three RealInput ports mdot_thr, mdot_bst and mdot_cyl, the RealOutput p_m, the parameters V_m, T_m and R, the variable p, and the one equation V_m / (R * T_m) * der(p) = mdot_thr + mdot_bst - mdot_cyl with p_m = p.](/handson/lecture-02/img/step02-manifold-code.png){width="638" height="584"}](/handson/lecture-02/img/step02-manifold-code.png)

#### B · The bench

| Name | Library path | Set |
| --- | --- | --- |
| `throttle_cmd` | BlockComponents › Sources › Step | `offset = 0`, `height = 0.005`, `start_time = 1` |
| `speed` | BlockComponents › Sources › Constant | `k = 83.776` (800 rpm in rad/s) |
| `no_booster` | BlockComponents › Sources › Constant | `k = 0` |
| `throttle` | VehicleSystemsComponents › Vehicle › Engine › Throttle | — |
| `cylinders` | VehicleSystemsComponents › Vehicle › Engine › CylinderAirflow | — |
| `manifold` | your `Manifold` | — |

3. <Badge type="tip" text="New component" /> Add a component `AirPathStep` and place the six parts of the table: **+** → type the name in the search box → drag the result onto the canvas.
   - Search "Manifold" also offers `IntakeManifold` from the course library: take your own `MyCar › Manifold`.
   - Search "Throttle" offers four throttles: take the plain `Vehicle › Engine › Throttle`, not `ElectronicThrottle`, `ThrottleEndStops` or `ThrottlePositionSensor`.
   - The parts arrive as `step`, `constant1`, `constant2`, `throttle`, `cylinderairflow` and `manifold`. Rename each to the **Name** column: select it → **Edit Parameters** → the pencil next to its name. Set its parameters first, then rename.
   - To set a parameter, click its field, <kbd>End</kbd>, <kbd>Shift</kbd>+<kbd>Home</kbd> to select the old value, type the new one, <kbd>Enter</kbd>. Not <kbd>Ctrl</kbd>+<kbd>A</kbd>: in Studio it selects the whole page.
4. Wire `throttle_cmd` → `throttle.u_thr`, `speed` → `cylinders.omega`, `no_booster` → `manifold.mdot_bst`. The icons do not say which input is which: hover a port to read its name before you wire it. On `Throttle` the top input is `u_thr` and the bottom one `p_m`; on `CylinderAirflow` the top input is `p_m` and the bottom one `omega`.
5. Wire the flows: `throttle.mdot_thr` → `manifold.mdot_thr`, `cylinders.mdot_cyl` → `manifold.mdot_cyl`.
6. Wire the pressure back: `manifold.p_m` → `throttle.p_m` and → `cylinders.p_m`. Both flows depend on it; this loop is what makes the pressure settle.
7. Toggle to code and add `initial manifold.p = 101325` after the last `connect`, before `metadata`: the manifold starts full of outside air.
8. <Badge type="tip" text="New analysis" /> ▷ (top right of the diagram) → **Create New Analysis** → `TransientAnalysis` → name it `AirPathStepTransient`. In the analysis that opens, **Edit Parameters** → `stop` = `3`, and save.

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

[![The AirPathStep diagram: throttle_cmd feeds throttle, no_booster feeds the manifold's middle input and speed feeds cylinders; the throttle and cylinder flows run into the manifold's top and bottom inputs, and the manifold output p_m loops back to both throttle and cylinders.](/handson/lecture-02/img/step02-airpath-bench.png){width="638" height="584"}](/handson/lecture-02/img/step02-airpath-bench.png)

#### C · Run it at idle, then at 3000 rpm

9. Run `AirPathStepTransient` with ▷ on its analysis tab first. Then plot the pressure in the REPL:

   ```julia
   using Plots
   r = MyCar.AirPathStepTransient()
   plot(r; idxs = r."manifold.p_m")
   ```

   A REPL opened before `AirPathStep` existed answers `UndefVarError: AirPathStepTransient not defined`. Running once with ▷ loads the new components into it; restarting the REPL does too.
10. Set `speed` to `k = 314.159` (3000 rpm) and `throttle_cmd` to `height = 1` (wide open at 1 s): click the field, <kbd>End</kbd>, <kbd>Shift</kbd>+<kbd>Home</kbd>, type, <kbd>Enter</kbd>. Run and plot again.

[![Manifold pressure of AirPathStepTransient at idle: it falls from 101.3 kPa to 33.0 kPa within the first second, then rises to 37.3 kPa after the small throttle step at 1 s.](/handson/lecture-02/img/step02-idle-plot.png){width="990" height="528"}](/handson/lecture-02/img/step02-idle-plot.png)

::: tip Checkpoint

The same numbers as the course model's tests (`Vehicle.Engine.TestAirPath`), which use this equation:

- **Idle, 800 rpm:** 101.3 kPa falls to **33.0 kPa** well within the first second; the small throttle step at 1 s lifts it to **37.3 kPa**, settling with a time constant of about **0.15 s**. Read τ on that small step: the first big fall from 101 kPa is not a straight lag, and its 1/e time is about 0.10 s.
- **3000 rpm:** closed, the pressure falls to **13.5 kPa** (overrun); wide open it rises to **99.9 kPa**, almost the outside air. It settles about five times faster than at idle, τ ≈ **0.03 s**.

The plot is in pascals: 33 000 is 33 kPa.

:::

Commit: **Source Control** → message `Step 02: manifold` → **Commit** → **Sync Changes**.

::: details Stuck? The full model

From `dyad/HandsOn02/Manifold.dyad` and `dyad/HandsOn02/AirPathStep.dyad`, diagram annotations omitted.

```txt
component Manifold
  mdot_thr = RealInput()
  mdot_bst = RealInput()
  mdot_cyl = RealInput()
  p_m = RealOutput()
  parameter V_m::Volume = 1.0e-3
  parameter T_m::Temperature = 298.15
  parameter R::Real = 287.05
  variable p::Pressure
relations
  V_m / (R * T_m) * der(p) = mdot_thr + mdot_bst - mdot_cyl
  p_m = p
end

component AirPathStep
  throttle_cmd = BlockComponents.Sources.Step(offset = 0, height = 0.005, start_time = 1)
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
```

:::

### 03 Map engine on a dynamometer <Badge type="info" text="20 min" /> {#map-engine}

An engine of your own, drawn from six given blocks: pedal in; torque, fuel and CO₂ out, read from the maps at speed and manifold pressure. Then you paste in fuel cut.

Theory: [tutor slides — three lines make the engine](../../handson-02/index.html#/engine-equations){target="_self"}

#### Where you are, where you are going

Your engine has three lines that matter:

- torque is the torque map at (*N*, *p<sub>m</sub>*), never more than the full-load curve;
- fuel is the fuel map at (*N*, *p<sub>m</sub>*);
- CO₂ is 3.09 × fuel: each kilogram of petrol burned completely makes 3.09 kg of CO₂.

The pedal sets the throttle directly. The manifold pressure comes from `AirPath`, the course library's version of your step 02 bench, packaged as one part. The two maps are given parts too, `TorqueMap` and `FuelMap`: each already holds its table and converts rad/s and Pa to the rpm and kPa the table uses, and `TorqueMap` caps itself at the full-load curve. A `VelocitySensor` on the shaft reads the engine speed. You place the parts and draw the wires; the only number you type is 3.09.

You test the engine on a **dynamometer**: a bench that holds the shaft at a fixed speed whatever the engine does, so a pedal step shows only the engine.

[![The finished MapEngine diagram: pedal and mdot_bst ports on the left feed air; air.p_m fans out to torque_map, fuel_map and the p_m output, and speed.w from the shaft sensor runs over the top to air and both maps; torque_map drives the torque source on the spline and support ports, and fuel_map feeds mdot_fuel and, through the gain co2 with k = 3.09, mdot_co2 on the right edge.](/handson/lecture-02/img/step03-map-engine.png){width="638" height="584"}](/handson/lecture-02/img/step03-map-engine.png)

#### A · Draw the engine

| Name | Library path | Set |
| --- | --- | --- |
| `pedal` | Dyad › RealInput | port, left edge |
| `mdot_bst` | Dyad › RealInput | port, left edge, below `pedal`: the brake booster's air, zero today |
| `spline` | Dyad › Spline | port, right edge: the output shaft |
| `support` | Dyad › Spline | port, right edge, below `spline`: the engine mounts |
| `mdot_fuel`, `mdot_co2`, `p_m` | Dyad › RealOutput | ports, right edge, below `support` |
| `air` | VehicleSystemsComponents › Vehicle › Engine › AirPath | — |
| `speed` | RotationalComponents › Sensors › VelocitySensor | — |
| `torque_map` | VehicleSystemsComponents › Vehicle › Engine › TorqueMap | — |
| `fuel_map` | VehicleSystemsComponents › Vehicle › Engine › FuelMap | — |
| `co2` | BlockComponents › Math › Gain | `k = 3.09` |
| `torque` | RotationalComponents › Sources › TorqueSource | — |

1. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `MyCar` → **Add Component** and name it `MapEngine`. It opens as an empty diagram.
2. With **+**, place the six parts of the table and rename each. Set `co2`'s `k` to `3.09`. Arrange them as the picture above: `air` on the left; `torque_map` above `fuel_map` to its right; `torque` right of `torque_map`, `co2` right of `fuel_map`; `speed` above `torque`.
3. Place the seven ports from the `Dyad` library: drag each from **+** and drop it straight onto the dashed outline, on the edge the table says. Place and name ports here, in `MapEngine`'s own diagram, never on an instance of it in another diagram. To grab a port, click just outside its triangle or circle, not on it: a click on the port itself starts a wire. Then drag it to move it, or **Edit Parameters** → pencil to rename it.
4. Draw the 15 wires. Hover a port to read its name. `air`'s inputs are, from the top, `u_thr`, `mdot_bst`, `omega`, and its outputs `mdot_thr`, `p_m`, `mdot_cyl`. On `torque_map` and `fuel_map`, `omega` is the top input and `p_m` the one below. Each wire starts at the port named first:
   - **Air in:** `pedal` → `air.u_thr`; `mdot_bst` → `air.mdot_bst`.
   - **Speed**, three wires from `speed.w`: → `air.omega`, → `torque_map.omega`, → `fuel_map.omega`.
   - **Pressure**, three wires from `air.p_m`: → `torque_map.p_m`, → `fuel_map.p_m`, → the `p_m` port.
   - **Torque:** `torque_map.y` → `torque.tau`; `torque`'s right-hand circle → `spline`; `torque`'s bottom circle → `support`.
   - **Shaft speed:** `speed`'s circle → `spline`, so the sensor reads the shaft the torque drives.
   - **Fuel:** `fuel_map.y` → `mdot_fuel`; `fuel_map.y` → `co2.u`; `co2.y` → `mdot_co2`.
5. Save with <kbd>Ctrl</kbd>+<kbd>S</kbd>, twice: a single save right after the last wire can miss it, a known Studio bug. The **Problems** tab should show nothing for `MapEngine`.

Read what you drew:

- The two maps hang off the same two wires, speed and pressure. That picture is the lecture: an engine control unit knows *N* and *p<sub>m</sub>* and looks everything up there.
- The pedal moves the throttle at once. Whatever lag you see between pedal and torque is the manifold filling, the state you built in step 02.
- There is no flywheel: on the dynamometer the bench sets the speed. Step 04 adds one in the car.

::: details Stuck? The full model

From `dyad/HandsOn02/MapEngine.dyad`, diagram annotations omitted.

```txt
component MapEngine
  pedal = RealInput()
  mdot_bst = RealInput()
  spline = Spline()
  support = Spline()
  p_m = RealOutput()
  mdot_fuel = RealOutput()
  mdot_co2 = RealOutput()
  air = VehicleSystemsComponents.Vehicle.Engine.AirPath()
  speed = RotationalComponents.Sensors.VelocitySensor()
  torque_map = VehicleSystemsComponents.Vehicle.Engine.TorqueMap()
  fuel_map = VehicleSystemsComponents.Vehicle.Engine.FuelMap()
  co2 = BlockComponents.Math.Gain(k = 3.09)
  torque = RotationalComponents.Sources.TorqueSource()
relations
  connect(pedal, air.u_thr)
  connect(mdot_bst, air.mdot_bst)
  connect(speed.w, air.omega)
  connect(speed.w, torque_map.omega)
  connect(speed.w, fuel_map.omega)
  connect(air.p_m, torque_map.p_m)
  connect(air.p_m, fuel_map.p_m)
  connect(air.p_m, p_m)
  connect(torque_map.y, torque.tau)
  connect(fuel_map.y, co2.u)
  connect(fuel_map.y, mdot_fuel)
  connect(co2.y, mdot_co2)
  connect(torque.spline, spline)
  connect(speed.spline, spline)
  connect(torque.support, support)
end
```

:::

#### B · The dynamometer bench

The bench is given as code: paste it. Its parameters are the knobs of the two runs below.

6. <Badge type="tip" text="New component" /> Add a component `MapEngineDyno`, toggle to code, select everything, paste the block below and save. Toggle back to see it, left to right: `pedal` and `no_booster` feed the engine, `speed` drives the `dyno`, and both supports go to `mounts`. The `{"Dyad": …}` annotations only place the parts in the diagram.
7. <Badge type="tip" text="New analysis" /> Create `MapEngineDynoTransient` as in step 02, or paste the `analysis` block below into its own file.

::: code-group

```txt [MapEngineDyno and MapEngineDynoTransient]
component MapEngineDyno
  "Held engine speed [rpm]"
  parameter rpm::Real = 3080.0
  "Pedal before the step"
  parameter pedal_initial::Real = 0.1034
  "Pedal after the step"
  parameter pedal_final::Real = 0.12
  "Pedal step time"
  parameter t_step::Time = 1.0
  "Initial manifold pressure"
  parameter p_m0::Pressure = 47829.1
  pedal = BlockComponents.Sources.Step(height = pedal_final - pedal_initial, offset = pedal_initial, start_time = t_step) {"Dyad": {"placement": {"diagram": {"x1": 50, "y1": 250, "x2": 150, "y2": 350}}}}
  no_booster = BlockComponents.Sources.Constant(k = 0) {"Dyad": {"placement": {"diagram": {"x1": 50, "y1": 550, "x2": 150, "y2": 650}}}}
  engine = MapEngine() {"Dyad": {"placement": {"diagram": {"x1": 300, "y1": 300, "x2": 500, "y2": 500}}}}
  mounts = RotationalComponents.Components.Fixed() {"Dyad": {"placement": {"diagram": {"x1": 550, "y1": 750, "x2": 650, "y2": 850}}}}
  dyno = RotationalComponents.Sources.VelocitySource() {"Dyad": {"placement": {"diagram": {"x1": 650, "y1": 350, "x2": 750, "y2": 450}}}}
  speed = BlockComponents.Sources.Constant(k = rpm * pi / 30) {"Dyad": {"placement": {"diagram": {"x1": 850, "y1": 350, "x2": 950, "y2": 450}}}}
relations
  connect(pedal.y, engine.pedal)
  connect(no_booster.y, engine.mdot_bst)
  connect(speed.y, dyno.w_ref)
  connect(engine.spline, dyno.spline)
  connect(engine.support, mounts.spline)
  connect(dyno.support, mounts.spline)
  initial dyno.phi = 0
  initial engine.air.manifold.p = p_m0
end

analysis MapEngineDynoTransient
  extends TransientAnalysis(stop = 2.0, saveat = 0.001)
  parameter rpm::Real = 3080.0
  parameter pedal_initial::Real = 0.1034
  parameter pedal_final::Real = 0.12
  parameter t_step::Time = 1.0
  parameter p_m0::Pressure = 47829.1
  model = MapEngineDyno(rpm = rpm, pedal_initial = pedal_initial, pedal_final = pedal_final, t_step = t_step, p_m0 = p_m0)
end
```

:::

[![The MapEngineDyno bench left to right: the pedal step and no_booster feed engine; the speed constant k = rpm * pi / 30 drives dyno, which holds the engine shaft; the supports of engine and dyno both go to mounts below.](/handson/lecture-02/img/step03-dyno-bench.png){width="638" height="584"}](/handson/lecture-02/img/step03-dyno-bench.png)

#### C · Run 1: a small pedal step at 90 km/h

The defaults hold the 90 km/h cruise point of step 01, 3080 rpm and 31.1 N·m, and at 1 s open the pedal from 0.1034 to 0.12.

8. Run `MapEngineDynoTransient` once with ▷ on its analysis tab: that loads the engine and bench you just drew into the REPL. Then plot the pressure and the torque, then the fuel:

   ```julia
   r = MyCar.MapEngineDynoTransient()
   plot(r; idxs = [r."engine.p_m", r."engine.torque_map.y"], layout = (2, 1))
   plot(r; idxs = r."engine.mdot_fuel")
   ```

   Zoom into 0.9–1.3 s: the pedal jumped, the torque follows the pressure.

[![MapEngineDynoTransient zoomed to 0.9–1.3 s: after the pedal step from 0.1034 to 0.12 at 1 s, the manifold pressure rises from 47.8 to 52.9 kPa and the map torque follows it from 31.1 to 41.4 N·m.](/handson/lecture-02/img/step03-step-plot.png){width="990" height="528"}](/handson/lecture-02/img/step03-step-plot.png)

::: tip Checkpoint

| | before the step | after |
| --- | --: | --: |
| `engine.p_m` | 47.8 kPa | 52.9 kPa |
| `engine.torque_map.y` | 31.1 N·m | 41.4 N·m |
| `engine.mdot_fuel` | 0.85 g/s | 1.02 g/s |

The torque takes about **50 ms** to go from 10 % to 90 % of its rise; the pressure covers 63 % of its rise in about 23 ms. The pedal moved in no time: that 50 ms is the manifold filling. The plot shows kg/s: 0.00085 is 0.85 g/s.

:::

#### D · Run 2: closed pedal, then wide open

9. Run the same bench at 3000 rpm, from closed to wide open, starting at step 02's overrun pressure:

   ```julia
   r = MyCar.MapEngineDynoTransient(rpm = 3000, pedal_initial = 0, pedal_final = 1, p_m0 = 13482.4)
   plot(r; idxs = [r."engine.p_m", r."engine.torque_map.y"], layout = (2, 1))
   ```

::: tip Checkpoint

At 3000 rpm, the pressures from step 02 and the maps read there:

| | pedal closed | pedal floored |
| --- | --: | --: |
| `engine.p_m` | 13.5 kPa | 99.9 kPa |
| `engine.torque_map.y` | −18.2 N·m | **148.4 N·m** |
| `engine.mdot_fuel` | 0.097 g/s | 3.75 g/s |
| `engine.mdot_co2` | 0.30 g/s | 11.6 g/s |

Without the cap the map would give 163.0 N·m. The torque now rises 10–90 % in about 2 ms: a wide-open throttle fills the manifold almost at once, so a big step hides the lag that run 1 shows.

:::

#### E · Paste in fuel cut

With the pedal closed at 3000 rpm your engine still burns 0.097 g/s while making negative torque. The dynamometer turns the engine, as the wheels do in a car that rolls with the pedal up, and that fuel does nothing useful.

**Deceleration fuel cut.** Every modern engine control unit stops injecting when the driver lifts off at speed. It saves the fuel the engine would burn for nothing, sends no unburned fuel to the catalyst, and makes the engine brake the car harder.

**When it cuts.** The course library's `FuelCutLogic` decides. It starts the cut when the pedal is closed and the engine turns faster than **1300 rpm**. It ends the cut as soon as the pedal opens, or when the engine falls below **1000 rpm**, so that it idles on its own instead of stalling.

**Why two speeds.** With one threshold, an engine turning right at it would switch the fuel on and off at every small wobble of speed. Between 1000 and 1300 rpm the logic keeps whatever it last decided. That gap is called hysteresis; a thermostat works the same way.

**The rev limiter.** The same block also cuts the fuel above **6500 rpm**, whatever the pedal, and turns it back on below **6300 rpm**. Your car meets it at full throttle in step 04.

**The torque during the cut.** No fuel burns, so the engine makes no combustion torque. The wheels turn it, and it pumps air through the closed throttle. The torque it then takes from the shaft was measured on the test bench with the fuel off, as a curve over speed alone: the **closed-throttle (motoring) curve**. While the cut is on, `CutTorqueMap` gives that curve instead of your torque map, and `CutFuelMap` gives zero fuel. Both switch over about 10 ms, so the solver never sees a jump.

You edit your own `MapEngine` in place. The two new map blocks have their ports where `TorqueMap`'s and `FuelMap`'s are, so your wires stay where they are. The course library keeps both versions for reference: `HandsOn02.MapEngine` before the paste, `HandsOn02.MapEngineFuelCut` after it.

10. Open `MapEngine` and toggle to code (⇄). Select from the `t` of `torque_map =` to the end of the `fuel_map =` line, and paste the first block over it. If the two lines are not next to each other, delete both, click at the end of the last component line, press <kbd>Enter</kbd> and paste the block there. The blocks end without a line break: select whole lines from the margin instead and the line after the paste joins its last line.
11. Click at the end of the last `connect(…)` line, press <kbd>Enter</kbd> and paste the second block. Save, and toggle back to the diagram: `cut_logic` sits at the bottom left, its output goes up into both maps from below, and nothing you drew has moved. The four new wires are drawn for the course's layout, `HandsOn02.MapEngineFuelCut`, so on your own they may run diagonally or across a block: only the drawing is off, the connections are right. The **Problems** tab should show nothing.
12. Open `MapEngineDyno` and toggle to code. In the line that starts `speed =`, select `Constant(k = rpm * pi / 30)` and paste the third block over it. Save. The dynamometer now holds `rpm` until 2 s, then slows the shaft to 800 rpm over 3 s. Runs 1 and 2 stop at 2 s, so the ramp does not change them.

::: code-group

```txt [1 · MapEngine, over torque_map and fuel_map]
  torque_map = VehicleSystemsComponents.Vehicle.Engine.CutTorqueMap() {^torque_map}
  fuel_map = VehicleSystemsComponents.Vehicle.Engine.CutFuelMap() {^fuel_map}
  cut_logic = VehicleSystemsComponents.Vehicle.Engine.FuelCutLogic() {"Dyad": {"placement": {"diagram": {"x1": 200, "y1": 800, "x2": 300, "y2": 900}}}}
```

```txt [2 · MapEngine, after the last connect]
  connect(pedal, cut_logic.pedal) {"Dyad": {"edges": [{"S": 1, "M": [{"x": 60, "y": 200}, {"x": 60, "y": 830}], "E": 2}]}}
  connect(speed.w, cut_logic.omega) {"Dyad": {"edges": [{"S": 1, "M": [{"x": 970, "y": 110}, {"x": 970, "y": 30}, {"x": 400, "y": 30}, {"x": 400, "y": 380}, {"x": 110, "y": 380}, {"x": 110, "y": 870}], "E": 2}]}}
  connect(cut_logic.cut, fuel_map.cut) {"Dyad": {"edges": [{"S": 1, "M": [{"x": 500, "y": 850}], "E": 2}]}}
  connect(cut_logic.cut, torque_map.cut) {"Dyad": {"edges": [{"S": 1, "M": [{"x": 580, "y": 850}, {"x": 580, "y": 340}, {"x": 500, "y": 340}], "E": 2}]}}
```

```txt [3 · MapEngineDyno, over Constant(…) in the speed line]
Ramp(offset = rpm * pi / 30, height = (800 - rpm) * pi / 30, start_time = 2, duration = 3)
```

:::

The `{"Dyad": …}` annotations only draw the new block and its four wires: the logic reads the pedal and the shaft speed, and its one output, the cut fraction from 0 to 1, goes to both maps.

13. Run `MapEngineDynoTransient` once with ▷ on its analysis tab. The REPL keeps the `MapEngine` and `MapEngineDyno` it loaded before your pastes, and runs them without an error; ▷ loads the new ones. Then run the release from wide open for 6 s, and plot the shaft speed, the fuel and the torque:

    ```julia
    r = MyCar.MapEngineDynoTransient(rpm = 3000, pedal_initial = 1, pedal_final = 0, p_m0 = 99889.9, stop = 6)
    plot(r; idxs = [r."engine.speed.w", r."engine.mdot_fuel", r."engine.torque_map.y"], layout = (3, 1))
    ```

    The speed is in rad/s: 1000 rpm is 104.7 rad/s.

[![The release run of MapEngineDynoTransient, three panels over 6 s. Speed: 3000 rpm until 2 s, then down to 800 rpm at 5 s. Fuel: 3.75 g/s, cut to 0 at 1 s, back at 4.73 s as the speed passes 1000 rpm. Torque: 148.4 N·m, then −18.7 N·m on the closed-throttle curve, rising to about 0 at 800 rpm.](/handson/lecture-02/img/step03-fuel-cut-plot.png){width="990" height="528"}](/handson/lecture-02/img/step03-fuel-cut-plot.png)

::: tip Checkpoint

From `HandsOn02.MapEngineFuelCutDynoTransient`, the course's copy of your bench:

- Before 1 s, run 2's wide-open numbers: **148.4 N·m** and **3.75 g/s**.
- At the release the fuel is 99 % gone within **30 ms** and then **0**. The torque settles at **−18.7 N·m**, the closed-throttle curve at 3000 rpm, and `p_m` falls to **13.5 kPa**, as in run 2. Run 2's closed pedal gave −18.2 N·m: the 0.5 N·m between them is what the 0.097 g/s of fuel was still giving.
- The course engine `MappedEngine` ends on the same **−18.7 N·m** after the same release: it uses the same `FuelCutLogic` and the same curve. Its fuel takes a little longer to go, because its throttle actuator closes over 50 ms and keeps the manifold full a moment longer. In the cut the torque does not depend on `p_m`, so the end value is the same.
- From 2 s the speed falls, and the fuel stays at 0 through 1300 rpm and below. It comes back at **4.73 s**, as the shaft passes **1000 rpm**, with `p_m` at **27.0 kPa**.
- At 800 rpm, 6 s: `p_m` **33.0 kPa**, step 02's idle; fuel **0.096 g/s**; torque about **0**: with the pedal closed, the engine burns just enough to turn itself.

If you run run 2 again now, its closed pedal shows 0 fuel and −18.7 N·m: the engine starts above 1300 rpm with the pedal closed, so it starts in the cut.

:::

Commit: **Source Control** → message `Step 03: map engine` → **Commit** → **Sync Changes**.

## Drive the car

Steps 4–6 · your engine in your hands-on 1 car · 32 min

### 04 The car with a mapped engine <Badge type="info" text="12 min" /> {#mapped-car}

Your hands-on 1 car with your own engine and a pedal — and a real top speed.

Theory: [tutor slides — top speed, with a torque curve](../../handson-02/index.html#/top-speed-again){target="_self"}

#### Where you are, where you are going

Same body, same driveline, same single gear of 4.0. The engine changes to your `MapEngine` from step 03, fuel cut included, and with it the input: a pedal from 0 to 1 instead of a torque. Two new outputs read the manifold pressure and the fuel in liters per hour. Hands-on 1's car reached 246 km/h at 8400 rpm; this engine gives less at high revs, and its rev limiter stops fueling at 6500 rpm.

The car needs one part the dynamometer did not: the inertia of the crankshaft and flywheel. On the bench the dynamometer set the speed, so the engine's own rotating mass did not matter. In the car it resists every change of speed, like 0.15 × (4 / 0.31)² = 25 kg more car. You add it as one block on the shaft between the engine and the driveline, with the value the course library's `MappedEngine` assumes, J = 0.15 kg·m².

#### Do this

1. In **Components**, right-click your `Car` → **Duplicate**, and name the copy `MappedCar`. Your hands-on 1 car stays as it was.
2. Open `MappedCar`. Delete `engine`. Click **+** → `MyCar › MapEngine`, your own engine, name it `engine`, and put it where the old one was.
3. Rename the input port `tau_cmd` to `pedal`, and wire it to `engine.pedal`. Rename and place `MappedCar`'s ports here, in its own diagram, not on a `car` instance in a bench: click just outside the port to select it, then **Edit Parameters** → pencil.
4. Add `flywheel` = `RotationalComponents › Components › Inertia` with `J = 0.15`, between `engine` and `driveline`. Wire `engine.spline` → `flywheel.spline_a` and `flywheel.spline_b` → `driveline.spline`. Wire `engine.support` → `rot_ground`, as before.
5. Add `no_booster` = `BlockComponents › Sources › Constant` (`k = 0`) → `engine.mdot_bst`.
6. Drop two `RealOutput` ports from **+** straight onto the right edge, `p_m` and `fuel_lph`. Wire `engine.p_m` → `p_m`. Add `to_lph` = `BlockComponents › Math › Gain` with `k = 4832.2` between `engine.mdot_fuel` and `fuel_lph`: × 3600 s/h ÷ 0.745 kg/L turns kg/s of petrol into L/h.
7. <Badge type="tip" text="New component" /> The bench `MappedCarWOT`: `pedal` = `Constant(k = 1)` → `car.pedal`, with the `initial` lines below. <Badge type="tip" text="New analysis" /> `MappedCarWOTTransient`, `stop = 120`.

::: code-group

```txt [MappedCar, as code]
component MappedCar
  pedal = RealInput()
  v_kmh = RealOutput()
  p_m = RealOutput()
  fuel_lph = RealOutput()
  engine = MapEngine()
  "Crankshaft and flywheel, J as MappedEngine assumes"
  flywheel = RotationalComponents.Components.Inertia(J = 0.15)
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
  connect(engine.spline, flywheel.spline_a)
  connect(flywheel.spline_b, driveline.spline)
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

<!-- TODO(reference): confirm the initial lines on HandsOn02.MappedCarWOT. The engine shaft and the
flywheel are tied to the wheel through the gear, so they should take no initial speed of their own.
Two findings from a trial of this car: from v = 0 it does not move, because the full-load curve is
0 N·m at 0 rpm and caps the torque there; started at 2 m/s it reaches 189.9 km/h, and then the
solver stops at about 87 s with MaxIters while the rev limiter holds it. The car with MappedEngine
does the same, so the fix belongs to the bench or the limiter, not to the engine choice. -->
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

The car tops out at about **190 km/h**, not 246. Drag alone would hold it at 192 km/h, where the engine turns 6570 rpm and gives 96 N·m; but at **6500 rpm = 189.9 km/h** the rev limiter in your `cut_logic` cuts the fuel, and it refuels at 6300 rpm = 184.1 km/h.

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

1. <Badge type="tip" text="New component" /> The bench `MappedCarCruise`: `pedal` = `Constant(k = 0.1)` → `car.pedal`, with the `initial` lines below. <Badge type="tip" text="New analysis" /> `MappedCarCruiseTransient`, `stop = 60`.
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
  pedal = BlockComponents.Sources.Constant(k = 0.1)
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
three decimals, from HandsOn02.MappedCarCruise. The car runs the student's MapEngine, whose pedal
drives the throttle directly: on the dynamometer it holds the three cruise torques at
0.044 / 0.103 / 0.190 ("Hands-on 02 map engine" testset), not MappedEngine's 0.124 / 0.220 / 0.331. -->
<!-- TODO(screenshots): step05-cruise-bench.png, step05-cruise-90-plot.png. -->

::: tip Checkpoint

Predicted from the maps for this car, the table of step 01; your table should match to the last digit shown:

| km/h | engine rpm | `p_m` kPa | `fuel_lph` | L/100 km | g CO₂/km |
| --: | --: | --: | --: | --: | --: |
| 50 | 1710 | 41.9 | 1.67 | **3.3** | **77** |
| 90 | 3080 | 47.8 | 4.11 | **4.6** | **105** |
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
<!-- TODO(checkpoint): p_m at the fuel-resume instant, from HandsOn02.MappedCarCoastTransient. -->

::: tip Checkpoint

- At 5 s the fuel drops from 4.11 L/h to **0**, and `p_m` falls to about **13.5 kPa**.
- The car slows at **0.46 m/s²**: 401 N of drag and rolling plus 246 N of engine braking (−19 N·m × 4 / 0.31) on 1400 kg. In neutral it would be 0.29 m/s².
- The fuel comes back on at **29 km/h**, where the engine drops below 1000 rpm.

:::

#### B · Brake

3. In `MappedCar`, add an input `F_brake` and `brake` = `TranslationalComponents › Sources › Force`. Wire `F_brake` → `brake.f`, one flange of `brake` to `body.flange` and the other to `trans_ground`.
4. In `MappedCarCoast`, add `brake_cmd` = `Step(height = 4000, start_time = 5)` → `car.F_brake`, and set `stop = 10`. Your other car benches now have an input nobody drives: give each a `Constant(k = 0)` into `car.F_brake` before running them again.
5. Run it and plot `car.v_kmh` and `car.p_m`.

<!-- TODO(reference): the brake force's sign as wired, p_m during the stop and the time to 25 km/h,
from HandsOn02.MappedCarCoast's brake-stop run; then give the one correct flange wiring instead of
"swap". -->
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
