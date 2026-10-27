---
title: Lecture 2 hands-on — drive a mapped engine
---

[← Vehicle Systems & Components](../../index.html) · [Projector deck →](../../handson-02/index.html){target="_self"}

# Lecture 2 hands-on: drive a mapped engine

From measured engine maps to the fuel and CO₂ your car burns at 50, 90 and 130 km/h

**Why we build it.** Lecture 1's engine gave 150 N·m at every speed and could not say how much fuel it burned. A real engine control unit reads tables measured on a test bench, at the engine speed and the pressure in the intake manifold. **What you build:** the manifold, whose pressure fills and empties, and a small engine of your own that reads torque and fuel from those tables. Then you paste the course library's fuel cut into your engine, put it into your hands-on 1 car with a given CVT and drive it: flat out, at steady speeds, lifting off and braking. By the end you have your car's fuel consumption in L/100 km and its CO₂ in g/km, the two numbers on a car's sticker.

![The mapped engine as a chain: the pedal opens the throttle; the throttle's air flow and the brake booster's fill the intake manifold, whose state is the pressure p_m; the cylinders draw air out; maps read at engine speed and p_m return torque to the crankshaft and the car, and fuel flow to the fuel and CO₂ outputs; engine speed feeds back to the maps and the cylinders.](/handson/lecture-02/img/mapped-engine-overview.svg){style="background:#fff;padding:8px;border-radius:4px"}

**How each step works.** It starts with the idea it needs, in a short **Why** box; the *Details* boxes hold the derivations, for when you want them. Each build opens with a picture of the finished model, so you know where you are going. Then you build, and the checkpoint is a number you could have predicted first. **Before this session:** the [engine lecture](../../lecture-02/index.html#/mapped-engine){target="_self"}, whose last section shows what you build here.

You build on your `MyCar` library from [hands-on 1](../lecture-01/). The throttle, the cylinders' air flow, the map tables and the fuel-cut logic come from the course library, `VehicleSystemsComponents`: they are physics the lecture stated, not what this session teaches. The budgets add up to about 90 minutes; step 07 is a bonus task for extra points, for after the session.

0. [Set up](#setup) — 8 min
1. [Read the maps](#maps) — 12 min
2. [Manifold: a pressure that fills](#manifold) — 15 min
3. [Map engine on a dynamometer](#map-engine) — 20 min
4. [The car with a mapped engine](#mapped-car) — 12 min
5. [Cruise: fuel and CO₂](#cruise) — 12 min
6. [Coast-down and a brake stop](#coast-brake) — 8 min

- [Hand in: open a pull request](#hand-in) — 3 min

7. [Bonus: drive the WLTC](#wltc) — extra points

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

#### Where you are, where you are going

Every map is a grid over engine speed *N* (26 speeds, 500–6750 rpm, down the side) and manifold absolute pressure *p<sub>m</sub>* (43 pressures, 0–105 kPa, across the top). The engine control unit knows both at every instant, from the crankshaft sensor and the MAP sensor, and looks everything up there.

| File | Gives | Unit |
| --- | --- | --- |
| `torque_Nm.csv` | brake torque | N·m |
| `fuel_gps.csv` | fuel mass flow | g/s |
| `lambda.csv` | λ, the air-fuel ratio over 14.6 | — |
| `full_load.csv` | the most torque the engine reaches at each speed | N·m |

The data is the US EPA's ALPHA map of a 2014 Mazda 2.0 L Skyactiv, scaled to 1.5 L. How it was converted, and every assumption, is in `data/engine/README.md` in the course repository.

::: info Why speed and manifold pressure

Two numbers fix the engine's state: how fast it turns, and how much air each cylinder gets. A cylinder fills from the manifold at the manifold's pressure, so *p<sub>m</sub>* says how full it gets: more pressure, more air, more fuel, more torque. An engine control unit that reads its load this way, without an air-mass meter, is called *speed-density*.

The pedal is not on the map. It says what the driver wants; the pressure says what the cylinders actually get, a moment later, once the manifold has filled. Step 02 builds that moment.

The pressures are absolute: 101 kPa is the air outside, a wide-open throttle; 33 kPa at idle is a strong vacuum.

:::

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

::: info Why the maps look like this

Torque and fuel rise across the map with pressure, almost in a straight line: more air, more of both. At low pressure the torque is negative: the engine pumps air against a vacuum, and that costs work; step 06 uses it to brake the car. λ is 1 almost everywhere because the engine control unit holds the mixture at stoichiometric for the catalyst, the λ loop of the lecture's section 7; only near full load does it run rich, to cool the exhaust.

:::

::: details Details: where 3080 rpm and 31.1 N·m come from, and the reading worked through

- **Speed:** 90 km/h is 25 m/s; 25 / 0.31 m × 4 × 60 / 2π = 3080 rpm.
- **Torque:** at 90 km/h the car needs 236 N against drag and 165 N against rolling, 401 N; × 0.31 / 4 = 31.1 N·m.
- **Pressure:** the 3000 rpm row gives 30.66 N·m at 47.5 kPa and 35.63 at 50 kPa; (31.08 − 30.66) / 4.97 × 2.5 = 0.21, so 47.7 kPa.
- **Fuel:** the same row of `fuel_gps` gives 0.816 g/s at 47.5 kPa and 0.895 at 50; 0.816 + 0.085 × (0.895 − 0.816) = 0.823 g/s.
- **Per distance:** 0.823 × 3600 / 745 = 3.98 L/h; ÷ 90 × 100 = 4.4 L/100 km. Interpolating between the 3000 and 3250 rpm rows to 3080 rpm instead gives 47.8 kPa and 0.850 g/s: 4.11 L/h, 4.6 L/100 km.

:::

::: tip Checkpoint

Computed from the tables:

- The map gives **160.3 N·m** at 4000 rpm and 100 kPa, and peaks at **177 N·m** near 3250 rpm and 105 kPa. It is negative at low pressure: the engine pumping against a vacuum.
- The 3000 rpm row passes 31.1 N·m at about **47.7 kPa** (30.7 N·m at 47.5, 35.6 at 50).
- Fuel there: about **0.82 g/s** → 4.0 L/h → **4.4 L/100 km**.
- The 90 km/h point itself, at 3080 rpm between the 3000 and 3250 rpm rows, sits at **47.8 kPa**: 0.850 g/s, 4.11 L/h and **4.6 L/100 km**. Mark your plots there. Step 05 drives 90 km/h with a CVT, which runs the engine slower, and compares.
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

#### Where you are, where you are going

The manifold is a box of air between the throttle and the cylinders. Air comes in through the throttle and leaves into the cylinders; its pressure is what is left, and it takes time to change:

**V<sub>m</sub> / (R T<sub>m</sub>) · dp<sub>m</sub>/dt = ṁ<sub>thr</sub> + ṁ<sub>bst</sub> − ṁ<sub>cyl</sub>**

You write this equation as a component, then put it on a bench between two given parts: the `Throttle`, whose flow the pedal sets, and `CylinderAirflow`, which draws more air the higher the pressure and the faster the engine turns. The brake booster's flow `ṁ_bst` comes in through a hose port, `vacuum`, that you leave unconnected today: a hose port with nothing on it is capped, so `ṁ_bst` is zero.

::: info Why the pressure settles, and why it lags

A bathtub, as in hands-on 1: the throttle is the tap, the cylinders are the drain, and the drain pulls harder the fuller the tub. So the pressure settles where in equals out, and it gets there with a time constant. That is the engine lag of hands-on 1, a fixed 0.3 s there; here it comes out of a volume of air, it is shorter, and it depends on speed: about 0.15 s at idle, 0.03 s at 3000 rpm.

A closed throttle does not give 0 kPa. It still leaks a little air, and the cylinders draw less the lower the pressure, so at 800 rpm the two balance at 33 kPa. The idle leak was sized to give that, and the torque map gives zero torque at 800 rpm at the same pressure: the air path and the maps agree.

:::

::: details Details: where τ comes from

1. Near a balance point, a small rise δp makes the cylinders draw more: δṁ<sub>cyl</sub> = (∂ṁ<sub>cyl</sub>/∂p<sub>m</sub>)·δp. The throttle's flow does not change: below 53.5 kPa (0.528 × 101.3) it is choked, so it does not depend on *p<sub>m</sub>*.
2. So (V<sub>m</sub>/RT<sub>m</sub>)·dδp/dt = −(∂ṁ<sub>cyl</sub>/∂p<sub>m</sub>)·δp: a first-order lag with τ = (V<sub>m</sub>/RT<sub>m</sub>) / (∂ṁ<sub>cyl</sub>/∂p<sub>m</sub>).
3. V<sub>m</sub>/(R T<sub>m</sub>) = 0.001 / (287 × 298) = 1.17·10⁻⁸ kg/Pa. At 800 rpm and 33 kPa, ∂ṁ<sub>cyl</sub>/∂p<sub>m</sub> ≈ 7.5·10⁻⁸ kg/(s·Pa), so τ = 0.156 s.
4. At 3000 rpm the cylinders pump 3.75 times as often and breathe better: τ ≈ 0.034 s.

:::

#### A · Paste the manifold

[![The Manifold component in the code view: the RealInput ports mdot_thr and mdot_cyl, the GasPort vacuum, the RealOutput p_m, the parameters V_m, T_m and R, the variable p, and the one equation V_m / (R * T_m) * der(p) = mdot_thr + vacuum.mdot - mdot_cyl with vacuum.p = p and p_m = p.](/handson/lecture-02/img/step02-manifold-code.png){width="638" height="584"}](/handson/lecture-02/img/step02-manifold-code.png)

1. <Badge type="tip" text="New component" /> In the **Components** tree, right-click `MyCar` → **Add Component** and name it `Manifold`.
2. Toggle to code (⇄), select everything with <kbd>Ctrl</kbd>+<kbd>A</kbd>, paste the block below and save. This also replaces the template's `metadata` block: that is fine.

The `{"Dyad": …}` annotation after each port only places it on the block's edge: the two flows and the hose on the left, `p_m` out on the right.

`vacuum` is not a signal but a hose end, a `GasPort` from the course library. It carries two numbers: the pressure `vacuum.p`, the same at both ends of the hose, and the air flow `vacuum.mdot`, counted positive into the manifold. That is why the code has `vacuum.mdot` where the equation above has ṁ<sub>bst</sub>, and why one more line, `vacuum.p = p`, says the hose sits at manifold pressure.

::: code-group

```txt [Manifold]
"""
Intake manifold as one isothermal receiver: the pressure is its only state.
"""
component Manifold
  "Air flow in through the throttle [kg/s]"
  mdot_thr = RealInput() {"Dyad": {"placement": {"icon": {"x1": -50, "y1": 200, "x2": 50, "y2": 300}, "diagram": {"x1": -50, "y1": 200, "x2": 50, "y2": 300}}}}
  "Hose to the brake booster: manifold pressure out, the booster's air in"
  vacuum = VehicleSystemsComponents.Vehicle.GasPort() {"Dyad": {"placement": {"icon": {"iconName": "gas_port_a", "x1": -50, "y1": 450, "x2": 50, "y2": 550}, "diagram": {"iconName": "gas_port_a", "x1": -50, "y1": 450, "x2": 50, "y2": 550}}}}
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
  V_m / (R * T_m) * der(p) = mdot_thr + vacuum.mdot - mdot_cyl
  vacuum.p = p
  p_m = p
end
```

:::

#### B · The bench

[![The AirPathStep diagram: throttle_cmd feeds throttle and speed feeds cylinders; the throttle and cylinder flows run into the manifold's top and bottom inputs, the manifold's square vacuum port in between stays unconnected, and the manifold output p_m loops back to both throttle and cylinders.](/handson/lecture-02/img/step02-airpath-bench.png){width="638" height="584"}](/handson/lecture-02/img/step02-airpath-bench.png)

| Name | Library path | Set |
| --- | --- | --- |
| `throttle_cmd` | BlockComponents › Sources › Step | `offset = 0`, `height = 0.005`, `start_time = 1` |
| `speed` | BlockComponents › Sources › Constant | `k = 83.776` (800 rpm in rad/s) |
| `throttle` | VehicleSystemsComponents › Vehicle › Engine › Throttle | — |
| `cylinders` | VehicleSystemsComponents › Vehicle › Engine › CylinderAirflow | — |
| `manifold` | your `Manifold` | — |

3. <Badge type="tip" text="New component" /> Add a component `AirPathStep` and place the five parts of the table: **+** → type the name in the search box → drag the result onto the canvas.
   - Search "Manifold" also offers `IntakeManifold` from the course library: take your own `MyCar › Manifold`.
   - Search "Throttle" offers four throttles: take the plain `Vehicle › Engine › Throttle`, not `ElectronicThrottle`, `ThrottleEndStops` or `ThrottlePositionSensor`.
   - The parts arrive with default names such as `step`, `constant1`, `throttle`, `cylinderairflow` and `manifold`. Rename each to the **Name** column: select it → **Edit Parameters** → the pencil next to its name. Set its parameters first, then rename.
   - To set a parameter, click its field, <kbd>End</kbd>, <kbd>Shift</kbd>+<kbd>Home</kbd> to select the old value, type the new one, <kbd>Enter</kbd>. Not <kbd>Ctrl</kbd>+<kbd>A</kbd>: in Studio it selects the whole page.
4. Wire `throttle_cmd` → `throttle.u_thr`, `speed` → `cylinders.omega`. Leave `manifold.vacuum`, the square port in the middle of the manifold's left edge, unconnected: the hose to the brake booster, capped today. The icons do not say which input is which: hover a port to read its name before you wire it. On `Throttle` the top input is `u_thr` and the bottom one `p_m`; on `CylinderAirflow` the top input is `p_m` and the bottom one `omega`.
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
  throttle = VehicleSystemsComponents.Vehicle.Engine.Throttle()
  cylinders = VehicleSystemsComponents.Vehicle.Engine.CylinderAirflow()
  manifold = Manifold()
relations
  connect(throttle_cmd.y, throttle.u_thr)
  connect(speed.y, cylinders.omega)
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
  vacuum = VehicleSystemsComponents.Vehicle.GasPort()
  mdot_cyl = RealInput()
  p_m = RealOutput()
  parameter V_m::Volume = 1.0e-3
  parameter T_m::Temperature = 298.15
  parameter R::Real = 287.05
  variable p::Pressure
relations
  V_m / (R * T_m) * der(p) = mdot_thr + vacuum.mdot - mdot_cyl
  vacuum.p = p
  p_m = p
end

component AirPathStep
  throttle_cmd = BlockComponents.Sources.Step(offset = 0, height = 0.005, start_time = 1)
  speed = BlockComponents.Sources.Constant(k = 83.776)
  throttle = VehicleSystemsComponents.Vehicle.Engine.Throttle()
  cylinders = VehicleSystemsComponents.Vehicle.Engine.CylinderAirflow()
  manifold = Manifold()
relations
  connect(throttle_cmd.y, throttle.u_thr)
  connect(speed.y, cylinders.omega)
  connect(throttle.mdot_thr, manifold.mdot_thr)
  connect(cylinders.mdot_cyl, manifold.mdot_cyl)
  connect(manifold.p_m, throttle.p_m, cylinders.p_m)
  initial manifold.p = 101325
end
```

:::

### 03 Map engine on a dynamometer <Badge type="info" text="20 min" /> {#map-engine}

An engine of your own, drawn from six given blocks: pedal in; torque, fuel and CO₂ out, read from the maps at speed and manifold pressure. Then you paste in fuel cut.

#### Where you are, where you are going

Your engine has three lines that matter:

- torque is the torque map at (*N*, *p<sub>m</sub>*), never more than the full-load curve;
- fuel is the fuel map at (*N*, *p<sub>m</sub>*);
- CO₂ is 3.09 × fuel: each kilogram of petrol burned completely makes 3.09 kg of CO₂.

The pedal sets the throttle directly. The manifold pressure comes from `AirPath`, the course library's version of your step 02 bench, packaged as one part. The two maps are given parts too, `TorqueMap` and `FuelMap`: each already holds its table and converts rad/s and Pa to the rpm and kPa the table uses, and `TorqueMap` caps itself at the full-load curve. A `VelocitySensor` on the shaft reads the engine speed. You place the parts and draw the wires; the only number you type is 3.09.

::: info Why a cap, and why 3.09

**The cap.** The map runs to 105 kPa, past anything the engine reaches; its last columns are extrapolated beyond what was measured. `full_load.csv` holds the torque the engine really gives at each speed, and `TorqueMap` applies it inside: at 3000 rpm and 99.9 kPa the map reads 163.0 N·m, the full-load curve 148.4.

**3.09.** A kilogram of carbon burns to 44/12 = 3.67 kg of CO₂, and petrol is about 84 % carbon by mass: 0.84 × 3.67 = 3.09. That holds when the fuel burns completely; the little CO the engine makes is a small correction.

:::

You test the engine on a **dynamometer**: a bench that holds the shaft at a fixed speed whatever the engine does, so a pedal step shows only the engine.

[![The finished MapEngine diagram: the pedal port and the square vacuum hose port on the left feed air; air.p_m fans out to torque_map, fuel_map and the p_m output, and speed.w from the shaft sensor runs over the top to air and both maps; torque_map drives the torque source on the spline and support ports, and fuel_map feeds mdot_fuel and, through the gain co2 with k = 3.09, mdot_co2 on the right edge.](/handson/lecture-02/img/step03-map-engine.png){width="638" height="584"}](/handson/lecture-02/img/step03-map-engine.png)

#### A · Draw the engine

| Name | Library path | Set |
| --- | --- | --- |
| `pedal` | Dyad › RealInput | port, left edge |
| `vacuum` | VehicleSystemsComponents › Vehicle › GasPort | port, left edge, below `pedal`: the hose to the brake booster, capped today |
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
3. Place the seven ports, six from the `Dyad` library and `vacuum` from the course library: drag each from **+** and drop it straight onto the dashed outline, on the edge the table says. If **+** does not offer `GasPort` as a port, toggle to code and add the line `vacuum = VehicleSystemsComponents.Vehicle.GasPort()` below `pedal = RealInput()` instead. Place and name ports here, in `MapEngine`'s own diagram, never on an instance of it in another diagram. To grab a port, click just outside its triangle, circle or square, not on it: a click on the port itself starts a wire. Then drag it to move it, or **Edit Parameters** → pencil to rename it.
4. Draw the 15 wires. Hover a port to read its name. `air` has, down its left edge, the input `u_thr`, the square hose port `vacuum` and the input `omega`, and its outputs `mdot_thr`, `p_m`, `mdot_cyl`. On `torque_map` and `fuel_map`, `omega` is the top input and `p_m` the one below. Each wire starts at the port named first:
   - **Air in:** `pedal` → `air.u_thr`; the hose `vacuum` → `air.vacuum`. A hose has no direction, so either end can start this wire.
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
  vacuum = VehicleSystemsComponents.Vehicle.GasPort()
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
  connect(vacuum, air.vacuum)
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

[![The MapEngineDyno bench left to right: the pedal step feeds engine, whose vacuum port stays unconnected; the speed constant k = rpm * pi / 30 drives dyno, which holds the engine shaft; the supports of engine and dyno both go to mounts below.](/handson/lecture-02/img/step03-dyno-bench.png){width="638" height="584"}](/handson/lecture-02/img/step03-dyno-bench.png)

6. <Badge type="tip" text="New component" /> Add a component `MapEngineDyno`, toggle to code, select everything, paste the block below and save. Toggle back to see it, left to right: `pedal` feeds the engine, `speed` drives the `dyno`, and both supports go to `mounts`. The engine's `vacuum` port stays unconnected, so no air comes from a booster. The `{"Dyad": …}` annotations only place the parts in the diagram.
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
  engine = MapEngine() {"Dyad": {"placement": {"diagram": {"x1": 300, "y1": 300, "x2": 500, "y2": 500}}}}
  mounts = RotationalComponents.Components.Fixed() {"Dyad": {"placement": {"diagram": {"x1": 550, "y1": 750, "x2": 650, "y2": 850}}}}
  dyno = RotationalComponents.Sources.VelocitySource() {"Dyad": {"placement": {"diagram": {"x1": 650, "y1": 350, "x2": 750, "y2": 450}}}}
  speed = BlockComponents.Sources.Constant(k = rpm * pi / 30) {"Dyad": {"placement": {"diagram": {"x1": 850, "y1": 350, "x2": 950, "y2": 450}}}}
relations
  connect(pedal.y, engine.pedal)
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

::: info Why fuel cut, and how it decides

**Deceleration fuel cut.** Every modern engine control unit stops injecting when the driver lifts off at speed. It saves the fuel the engine would burn for nothing, sends no unburned fuel to the catalyst, and makes the engine brake the car harder.

**When it cuts.** The course library's `FuelCutLogic` decides. It starts the cut when the pedal is closed and the engine turns faster than **1300 rpm**. It ends the cut as soon as the pedal opens, or when the engine falls below **1000 rpm**, so that it idles on its own instead of stalling.

**Why two speeds.** With one threshold, an engine turning right at it would switch the fuel on and off at every small wobble of speed. Between 1000 and 1300 rpm the logic keeps whatever it last decided. That gap is called hysteresis; a thermostat works the same way.

**The rev limiter.** The same block also cuts the fuel above **6500 rpm**, whatever the pedal, and turns it back on below **6300 rpm**. In step 04 the CVT keeps your car just under it.

**The torque during the cut.** No fuel burns, so the engine makes no combustion torque. The wheels turn it, and it pumps air through the closed throttle. The torque it then takes from the shaft was measured on the test bench with the fuel off, as a curve over speed alone: the **closed-throttle (motoring) curve**. While the cut is on, `CutTorqueMap` gives that curve instead of your torque map, and `CutFuelMap` gives zero fuel. Both switch over about 10 ms, so the solver never sees a jump.

:::

You edit your own `MapEngine` in place. The two new map blocks have their ports where `TorqueMap`'s and `FuelMap`'s are, so your wires stay where they are. The course library keeps both versions for reference: `HandsOn02.MapEngine` before the paste, `HandsOn02.MapEngineFuelCut` after it. After the paste your engine and bench look like this, drawn without port names:

[![MapEngine after the fuel-cut paste, the course's layout: as before, plus cut_logic at the bottom left, whose inputs come from the pedal port and from speed.w, and whose output runs up into the bottom of both torque_map and fuel_map.](/handson/lecture-02/img/step03-map-engine-fuel-cut.png){width="888" height="770" style="max-width:520px"}](/handson/lecture-02/img/step03-map-engine-fuel-cut.png)

[![MapEngineDyno after the paste: the same bench, with speed now a ramp that holds rpm until 2 s and then slows the dyno to 800 rpm.](/handson/lecture-02/img/step03-dyno-bench-fuel-cut.png){width="817" height="478" style="max-width:520px"}](/handson/lecture-02/img/step03-dyno-bench-fuel-cut.png)

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

Steps 4–6 · your engine and a CVT in your hands-on 1 car · 32 min

### 04 The car with a mapped engine <Badge type="info" text="12 min" /> {#mapped-car}

Your hands-on 1 car with your own engine, a pedal and a gearbox that lets it start from rest.

#### Where you are, where you are going

Same body as hands-on 1. The engine changes to your `MapEngine` from step 03, fuel cut included, and with it the input: a pedal from 0 to 1 instead of a torque. Two new outputs read the manifold pressure and the fuel in liters per hour.

The driveline changes too. Hands-on 1's single gear of 4.0 tied the engine to the wheels, and a mapped engine cannot live with that: at a standstill the engine would turn at 0 rpm, where it gives no torque, so the car never moves; and flat out it would run into the rev limiter at 6500 rpm, 190 km/h. So the car gets the course library's `CVTDriveline`, a launch clutch and a continuously variable transmission. It has the same four mechanical ports as your `Driveline`, plus a `pedal` input.

The car also needs one part the dynamometer did not: the inertia of the crankshaft and flywheel. On the bench the dynamometer set the speed, so the engine's own rotating mass did not matter. In the car it resists every change of engine speed. You add it as one block on the shaft between the engine and the driveline, with the value the course library's `MappedEngine` assumes, J = 0.15 kg·m².

::: info Why a CVT, and what it does

**The launch clutch.** A centrifugal clutch: weights on the engine side are flung outwards and press the linings together, so its grip grows with engine speed. Below about 1100 rpm it is open, and the engine idles while the car stands. Around **1300 rpm** it engages, over about ±120 rpm, up to 230 N·m. Floor the pedal and the engine revs to 1300 rpm and stays there while the clutch slips and pulls the car away; once the car has caught up, the clutch locks.

**The ratio range.** The CVT turns the engine 12.0 times for every wheel turn at launch and 2.8 times in overdrive, final drive included. Hands-on 1's fixed gear was 4.0. Any ratio in between is available, without steps.

**Pedal-scheduled engine speed.** The CVT's controller reads the pedal and picks the engine speed: **1800 rpm** with the pedal released, **6000 rpm** with it floored, in a straight line between. It then sets the ratio that puts the engine there at the present road speed, within 12.0 to 2.8, and moves to it over about 0.5 s. So the pedal sets the throttle and the engine speed together; the road speed only decides the ratio.

:::

#### Do this

[![MappedCar, the course's layout: the pedal port feeds engine and, along the top, the driveline's pedal input; engine.vacuum unconnected; engine, flywheel, driveline, body, vsensor and to_kmh in one row to the v_kmh output; engine.p_m and engine.mdot_fuel through to_lph run along the top to the p_m and fuel_lph outputs; rot_ground and trans_ground below.](/handson/lecture-02/img/step04-mapped-car.png){width="1065" height="709" style="max-width:min(640px, 100%)"}](/handson/lecture-02/img/step04-mapped-car.png)

1. In **Components**, right-click your `Car` → **Duplicate**, and name the copy `MappedCar`. Your hands-on 1 car stays as it was. If the copy opens as an empty diagram with a red ⓘ, "Unknown entity", close it, press <kbd>Ctrl</kbd>+<kbd>P</kbd>, open `mappedcar.dyad` once, and then double-click `MappedCar` in **Components**.
2. Open `MappedCar`. Delete `engine`. Click **+** → `MyCar › MapEngine`, your own engine, name it `engine`, and put it where the old one was.
3. Delete `driveline`. Click **+** → `VehicleSystemsComponents › Vehicle › CVTDriveline`, name it `driveline`, and wire its four mechanical ports as the old one's: `spline` from the engine side, `support_r` → `rot_ground`, `flange` → `body.flange`, `support_t` → `trans_ground`.
4. Rename the input port `tau_cmd` to `pedal`, and wire it to `engine.pedal` and to `driveline.pedal`, the input at the top of the driveline's left edge. Rename and place `MappedCar`'s ports here, in its own diagram, not on a `car` instance in a bench: click just outside the port to select it, then **Edit Parameters** → pencil.
5. Add `flywheel` = `RotationalComponents › Components › Inertia` with `J = 0.15`, between `engine` and `driveline`. Wire `engine.spline` → `flywheel.spline_a` and `flywheel.spline_b` → `driveline.spline`. Wire `engine.support` → `rot_ground`, as before.
6. Leave `engine.vacuum`, the square port on the engine's left edge, unconnected: the hose to the brake booster stays capped until the brake lecture.
7. Drop two `RealOutput` ports from **+** straight onto the right edge, `p_m` and `fuel_lph`. Wire `engine.p_m` → `p_m`. Add `to_lph` = `BlockComponents › Math › Gain` with `k = 4832.2` between `engine.mdot_fuel` and `fuel_lph`: × 3600 s/h ÷ 0.745 kg/L turns kg/s of petrol into L/h.
8. Toggle to code (⇄). Above the `pedal = …RealInput()` line the rename kept hands-on 1's description, `"Commanded engine torque"`: replace that line with the two `ratio_initial` lines of the code below, and in the `driveline =` line write `CVTDriveline(ratio_initial = ratio_initial)`. The car starts at the launch ratio, 12; the cruise benches of step 05 start it at their own. Save, twice.
9. <Badge type="tip" text="New component" /> The bench `MappedCarWOT`: paste it from below. <Badge type="tip" text="New analysis" /> `MappedCarWOTTransient`, `stop = 120`, or paste it.

::: code-group

```txt [MappedCar, as code]
component MappedCar
  "Initial CVT ratio, engine to wheel"
  parameter ratio_initial::Real = 12
  pedal = RealInput()
  v_kmh = RealOutput()
  p_m = RealOutput()
  fuel_lph = RealOutput()
  engine = MapEngine()
  "Crankshaft and flywheel, J as MappedEngine assumes"
  flywheel = RotationalComponents.Components.Inertia(J = 0.15)
  "kg/s of petrol to L/h: 3600 / 0.745"
  to_lph = BlockComponents.Math.Gain(k = 4832.2)
  driveline = VehicleSystemsComponents.Vehicle.CVTDriveline(ratio_initial = ratio_initial)
  body = Body()
  vsensor = TranslationalComponents.Sensors.VelocitySensor()
  to_kmh = BlockComponents.Math.Gain(k = 3.6)
  rot_ground = RotationalComponents.Components.Fixed()
  trans_ground = TranslationalComponents.Components.Fixed()
relations
  connect(pedal, engine.pedal)
  connect(pedal, driveline.pedal)
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
  pedal = BlockComponents.Sources.Constant(k = 1) {"Dyad": {"placement": {"diagram": {"x1": 150, "y1": 390, "x2": 250, "y2": 490}}}}
  car = MappedCar() {"Dyad": {"placement": {"diagram": {"x1": 400, "y1": 400, "x2": 600, "y2": 600}}}}
relations
  connect(pedal.y, car.pedal)
  initial car.body.mass.s = 0
  initial car.body.mass.v = 0
  "Engine idling at 900 rpm"
  initial car.flywheel.w = 900 * pi / 30
  initial car.flywheel.phi = 0
  initial car.driveline.clutch.spline_b.phi = 0
  initial car.engine.air.manifold.p = 101325
end

analysis MappedCarWOTTransient
  extends TransientAnalysis(stop = 120)
  model = MappedCarWOT()
end
```

:::

The bench starts the car at rest and the engine idling at 900 rpm. The clutch lets the engine and the wheels turn at different speeds, so each side needs its own start: the flywheel's speed and angle, and the angle of the clutch's output shaft. The angles' values do not matter; the solver needs one each.

10. Run `MappedCarWOTTransient` once with ▷ on its analysis tab, as in step 03: that loads your new components into the REPL. Then plot the road speed and the engine speed:

    ```julia
    r = MyCar.MappedCarWOTTransient()
    plot(r; idxs = [r."car.v_kmh", r."car.engine.speed.w"], layout = (2, 1))
    ```

    The engine speed is in rad/s: 1300 rpm is 136 rad/s, 6000 rpm is 628 rad/s. The picture below shows rpm.

[![MappedCarWOTTransient over 120 s. Speed: from rest to 100 km/h at 10.4 s, 197 km/h at 60 s and 205 km/h at 120 s, below the dashed 246 km/h of hands-on 1's car. Engine: 900 rpm, then held at 1300 rpm while the clutch slips, up to a peak of 6390 rpm at 6.4 s, below the dashed 6500 rpm limiter, then settling at 6000 rpm.](/handson/lecture-02/img/step04-wot-plot.png){width="990" height="528"}](/handson/lecture-02/img/step04-wot-plot.png)

::: tip Checkpoint

From `HandsOn02.MappedCarWOTTransient`, the course's copy of your bench:

- **Launch.** The engine flares from 900 to **1300 rpm** and stays there while the clutch slips. The clutch locks at **1.33 s**, at **13.7 km/h** and 1414 rpm.
- **0–100 km/h in 10.4 s.**
- **The engine peaks at 6390 rpm** at 6.4 s, 110 rpm under the limiter: up to about 58 km/h the ratio sits on its 12.0 stop, so the engine runs past its 6000 rpm target. Then the ratio falls and the engine settles at **6000 rpm**. The fuel is never cut.
- **197 km/h at 60 s, 205 km/h at 120 s**. The top speed is **205.3 km/h**, at ratio 3.41, not hands-on 1's 246 and not the 190 of a fixed gear on the limiter.

:::

::: info Why 205 km/h

At top speed the push equals the drag and the rolling resistance, hands-on 1's balance. With a CVT it is easiest in power: the engine turns at 6000 rpm whatever the speed, and the ratio passes all of its power to the wheels. Wide open at 6000 rpm, the manifold reaches 98.8 kPa and the map gives **126.5 N·m**: 126.5 × 6000 × 2π / 60 = **79.5 kW**. The road takes (0.378 v² + 165) · v; that is 79.5 kW at v = 57.0 m/s, **205 km/h**. Hands-on 1's engine gave 150 N·m up to 8400 rpm, 132 kW, and reached 246.

:::

Commit: **Source Control** → message `Step 04: mapped car` → **Commit** → **Sync Changes**.

### 05 Cruise: fuel and CO₂ <Badge type="info" text="12 min" /> {#cruise}

Hold 50, 90 and 130 km/h, read the fuel in liters per hour, and turn it into L/100 km and g CO₂/km.

#### Where you are, where you are going

At a steady speed the fuel flow in L/h, divided by the speed in km/h, is liters per kilometer:

- **L/100 km** = L/h ÷ km/h × 100
- **g CO₂/km** = L/h × 2302 ÷ km/h

2302 g of CO₂ per liter is 745 g of petrol × 3.09. Step 01 predicted 4.6 L/100 km at 90 km/h for hands-on 1's fixed gear, at 3080 rpm. Your CVT runs the engine at a different speed for the same speed on the road, so it lands somewhere else on the map.

::: info Why per kilometer

The engine gives liters per hour, the car covers kilometers per hour: divide, and the hours cancel. A car idling at a standstill burns fuel and covers no distance, so its L/100 km is infinite. That is why a car's label is measured over a driving cycle, step 07, and not at one speed.

:::

#### Do this

[![MappedCarCruise: a constant pedal, k = pedal_cmd, wired into the car's pedal input.](/handson/lecture-02/img/step05-cruise-bench.png){width="527" height="333" style="max-width:360px"}](/handson/lecture-02/img/step05-cruise-bench.png)

1. <Badge type="tip" text="New component" /> The bench `MappedCarCruise`: paste it from below. <Badge type="tip" text="New analysis" /> `MappedCarCruiseTransient`, the second block. The bench starts the car steady at one speed: the engine at the speed and the CVT at the ratio its pedal settles them, so the run does not spend a minute getting there. Its defaults hold 90 km/h.
2. Run `MappedCarCruiseTransient` once with ▷, then run it at 90 km/h in the REPL and plot speed and fuel:

   ```julia
   r = MyCar.MappedCarCruiseTransient()
   plot(r; idxs = [r."car.v_kmh", r."car.fuel_lph"], layout = (2, 1))
   ```

3. Read the speed, the fuel and the pressure at 60 s, and work out L/100 km and g CO₂/km:

   ```julia
   r.sol(60, idxs = r."car.v_kmh"), r.sol(60, idxs = r."car.fuel_lph"), r.sol(60, idxs = r."car.p_m")
   ```

4. Repeat for 50 and 130 km/h, with the values of the table:

   ```julia
   r = MyCar.MappedCarCruiseTransient(speed_kmh = 50, pedal_cmd = 0.04878, rpm0 = 1992, p_m0 = 40100)
   r = MyCar.MappedCarCruiseTransient(speed_kmh = 130, pedal_cmd = 0.17373, rpm0 = 3118, p_m0 = 67220)
   ```

| km/h | `pedal_cmd` | `rpm0` | `p_m0` |
| --: | --: | --: | --: |
| 50 | 0.04878 | 1992 | 40100 |
| 90 | 0.0916 | 2182 | 54420 |
| 130 | 0.17373 | 3118 | 67220 |

::: code-group

```txt [MappedCarCruise and MappedCarCruiseTransient]
component MappedCarCruise
  "Initial road speed [km/h]"
  parameter speed_kmh::Real = 90
  "Pedal that holds speed_kmh"
  parameter pedal_cmd::Real = 0.0916
  "Initial engine speed [rpm], steady at pedal_cmd"
  parameter rpm0::Real = 2182
  "Initial manifold pressure, steady at pedal_cmd"
  parameter p_m0::Pressure = 54420
  pedal = BlockComponents.Sources.Constant(k = pedal_cmd) {"Dyad": {"placement": {"diagram": {"x1": 150, "y1": 390, "x2": 250, "y2": 490}}}}
  "Wheel radius 0.31 m"
  car = MappedCar(ratio_initial = rpm0 * pi / 30 * 0.31 / (speed_kmh / 3.6)) {"Dyad": {"placement": {"diagram": {"x1": 400, "y1": 400, "x2": 600, "y2": 600}}}}
relations
  connect(pedal.y, car.pedal)
  initial car.body.mass.s = 0
  initial car.body.mass.v = speed_kmh / 3.6
  initial car.flywheel.w = rpm0 * pi / 30
  initial car.flywheel.phi = 0
  initial car.driveline.clutch.spline_b.phi = 0
  initial car.engine.air.manifold.p = p_m0
end

analysis MappedCarCruiseTransient
  extends TransientAnalysis(stop = 60)
  parameter speed_kmh::Real = 90
  parameter pedal_cmd::Real = 0.0916
  parameter rpm0::Real = 2182
  parameter p_m0::Pressure = 54420
  model = MappedCarCruise(speed_kmh = speed_kmh, pedal_cmd = pedal_cmd, rpm0 = rpm0, p_m0 = p_m0)
end
```

:::

[![MappedCarCruiseTransient at the defaults: the speed flat at 90 km/h and the fuel flat at 3.55 L/h for 60 s.](/handson/lecture-02/img/step05-cruise-90-plot.png){width="990" height="528"}](/handson/lecture-02/img/step05-cruise-90-plot.png)

::: tip Checkpoint

From `HandsOn02.MappedCarCruiseTransient`; each pedal holds its speed within 0.25 km/h for the 60 s. Your table should match to the last digit shown:

| km/h | engine rpm | ratio | `p_m` kPa | `fuel_lph` | L/100 km | g CO₂/km | fixed gear L/100 km |
| --: | --: | --: | --: | --: | --: | --: | --: |
| 50 | 1992 | 4.64 | 40.1 | 1.84 | **3.7** | **85** | 3.3 |
| 90 | 2182 | 2.83 | 54.4 | 3.55 | **3.9** | **91** | 4.6 |
| 130 | 3118 | 2.80 | 67.2 | 7.78 | **6.0** | **138** | 7.0 |

The fuel map of step 01, read at the CVT's rpm and `p_m`, gives the same fuel flow. λ is 1 at all three. These are steady-state figures with a warm engine, a lossless CVT and nothing switched on, so they sit below a real car's label; step 07 makes the fair comparison.

:::

::: info Why the CVT burns more at 50 km/h and less at 90 and 130

At a steady speed the road asks the same power of both cars: 10.0 kW at 90 km/h. The engine can give it fast and throttled, or slow and with the throttle open wide; the second burns less, because a throttled engine spends work pumping air against the vacuum in its manifold, and a fast one spends more on its own friction.

- **At 90 and 130 km/h** the CVT turns the engine at 2182 and 3118 rpm instead of 3080 and 4450, with the manifold at 54 and 67 kPa instead of 48 and 61: **3.9 instead of 4.6** and **6.0 instead of 7.0 L/100 km**. At 130 the ratio is already on its 2.8 stop.
- **At 50 km/h** it is the other way round. The CVT's controller never asks for less than 1800 rpm, so it runs the engine at 1992 rpm where the fixed gear ran 1710, and throttles it harder, 40.1 kPa against 41.9: **3.7 instead of 3.3 L/100 km**.

The controller picks the engine speed from the pedal alone; it does not know the map. A fuel-optimal schedule would, for each power the road asks, pick the engine speed where the fuel map is lowest along that power: low speed, throttle wide open. Building that schedule is an extension for the curious, not part of today.

:::

::: info Why the fuel per kilometer rises with speed

From 50 to 130 km/h the speed grows 2.6 times, the fuel per hour 4.2 times, the fuel per kilometer 1.6 times: the drag grows with v². And even at 130 km/h the manifold sits at only 67 kPa. A cruising petrol engine is throttled hard, and pumping air against that vacuum is part of why it is inefficient at part load.

:::

Commit: **Source Control** → message `Step 05: cruise` → **Commit** → **Sync Changes**.

### 06 Coast-down and a brake stop <Badge type="info" text="8 min" /> {#coast-brake}

Lift off at 90 km/h and the fuel stops; brake to a standstill, and read the vacuum the brake booster draws on.

#### Where you are, where you are going

With the pedal up at speed, the throttle closes and the manifold empties towards the overrun pressure of step 02. The engine control unit cuts the fuel completely, and the engine, driven by the wheels, pumps air against that vacuum: it brakes the car. A brake booster draws its vacuum from this manifold, so you plot that too. With the pedal up, the CVT asks for its lowest engine speed, 1800 rpm.

::: info Why the fuel comes back only at 11 km/h

The cut ends when the engine falls below **1000 rpm**. With hands-on 1's single gear that was a road speed, 29 km/h. With the CVT it is not: with the pedal released the controller asks for 1800 rpm, and as the car slows it raises the ratio to keep the engine there, until the ratio reaches its 12.0 stop, near 15 km/h. Only then does the engine slow with the car. Near 1140 rpm the launch clutch lets go, the engine drops under 1000 rpm on its own, and the fuel comes back at about **11 km/h**. Coasting down from 90 km/h burns nothing for a full minute; afterwards the engine idles on its own fuel behind the open clutch, 0.47 L/h, as it would in neutral.

:::

::: info Why the brake needs the vacuum

A brake booster is a can of air split by a diaphragm, its vacuum side connected to this manifold. The deeper the vacuum while you brake, the harder the booster helps your foot. In the brake lecture one hose joins the booster to the engine's `vacuum` port: the booster feels the manifold pressure through it, and its own air flows back into the manifold. Today that port is capped.

:::

#### A · Coast down

1. <Badge type="tip" text="New component" /> Duplicate `MappedCarCruise` as `MappedCarCoast`, as in step 04. Make `pedal` a `BlockComponents › Sources › Step` that releases the pedal at 5 s: in code, its line becomes the one below. <Badge type="tip" text="New analysis" /> `MappedCarCoastTransient`, `stop = 100`, with `model = MappedCarCoast()`.

   ```txt
     pedal = BlockComponents.Sources.Step(height = -pedal_cmd, offset = pedal_cmd, start_time = 5)
   ```

2. Run it once with ▷, then plot four signals:

   ```julia
   r = MyCar.MappedCarCoastTransient()
   plot(r; idxs = [r."car.v_kmh", r."car.engine.speed.w", r."car.fuel_lph", r."car.p_m"], layout = (2, 2))
   ```

[![MappedCarCoastTransient over 100 s, four panels. Speed: 90 km/h, released at 5 s, down to rest at about 91 s. Engine: 2182 rpm, held near 1750 rpm from about 17 s to 60 s, then down to 775 rpm idle at 67 s. Fuel: 3.55 L/h, 0 from 5 s, back on at 66.3 s and 0.47 L/h at idle. Pressure: 54.4 kPa, down to 17.1 kPa at the release, about 19.5 kPa while the engine is held, then 33.6 kPa at idle.](/handson/lecture-02/img/step06-coast-plot.png){width="990" height="528"}](/handson/lecture-02/img/step06-coast-plot.png)

::: tip Checkpoint

From `HandsOn02.MappedCarCoastTransient`:

- At 5 s the fuel drops from 3.55 L/h to **0**, and `p_m` falls to **17.1 kPa**. The engine turns 2150 rpm, not 3000, so the vacuum is not as deep as step 02's 13.5 kPa.
- The car slows at **0.39 m/s²**: 401 N of drag and rolling plus about 140 N of engine braking, on 1400 kg. In neutral it would be 0.29 m/s².
- Below about 75 km/h the ratio climbs from 2.8 towards 12.0; from 70 down to 30 km/h it holds the engine between **1730 and 1780 rpm**, still with no fuel.
- At **66.0 s, 11.2 km/h** and 1140 rpm the clutch opens. At **66.3 s, 10.8 km/h**, the engine passes 1000 rpm and the fuel comes back, with `p_m` at **27.4 kPa**.
- The engine settles at **775 rpm** idle, 33.6 kPa, 0.47 L/h, and the car rolls to rest at about **91 s**.

:::

#### B · Brake

[![MappedCarWithBrake, the course's layout: MappedCar with an F_brake input at the bottom left, wired along the bottom and up the right into brake; brake sits below body, its flange wired to body.flange and its support to trans_ground.](/handson/lecture-02/img/step06-mapped-car-brake.png){width="1065" height="796" style="max-width:min(640px, 100%)"}](/handson/lecture-02/img/step06-mapped-car-brake.png)

3. In `MappedCar`, add an input `F_brake` and `brake` = `VehicleSystemsComponents › Vehicle › RoadBrake`. Wire `F_brake` → `brake.F_cmd`, `brake.flange` → `body.flange` and `brake.support` → `trans_ground`.
4. In `MappedCarCoast`, add `brake_cmd` = `Step(height = 4000, start_time = 5)` → `car.F_brake`: 4000 N from the moment the pedal comes up. Your other car benches now have an input nobody drives: give each a `Constant(k = 0)` into `car.F_brake` before running them again. Without it a run stops with "The system is unbalanced".
5. Run it once with ▷, which loads the `MappedCar` with its brake into the REPL, then run it for 20 s and plot the same four signals:

   ```julia
   r = MyCar.MappedCarCoastTransient(stop = 20)
   plot(r; idxs = [r."car.v_kmh", r."car.engine.speed.w", r."car.fuel_lph", r."car.p_m"], layout = (2, 2))
   ```

::: info Why a given brake, and which way round

`RoadBrake` is friction between the body and the road: it pushes against the car's motion with the force `F_brake`, and that force fades to zero as the car stops, over the last 0.05 m/s. So it stops the car and then holds it. A plain force source would keep pushing after the car had stopped and drive it backwards. Like a damper, it brakes whichever way round its two flanges are wired; a positive `F_brake` always slows the car.

:::

[![The brake stop over 20 s, four panels. Speed: 90 km/h, then a straight line down from 5 s to rest at 12.9 s. Engine: 2182 rpm, falling to about 1600 rpm as the ratio climbs, then to 775 rpm idle at 12 s. Fuel: 0 from 5 s, back on at 12.0 s. Pressure: 17.6 kPa after the release, rising to 33.6 kPa at idle.](/handson/lecture-02/img/step06-brake-plot.png){width="990" height="528"}](/handson/lecture-02/img/step06-brake-plot.png)

::: tip Checkpoint

From `HandsOn02.MappedCarBrakeStopTransient`, the course's copy of your bench after this part:

- The car slows at **3.2 m/s²**: 4000 N of brake is about 0.3 g on 1400 kg, a firm stop. It passes **25 km/h at 10.7 s** and is **at rest at 12.9 s**, 7.9 s after the brake.
- `p_m` stays between **17.6 and 33.7 kPa** through the whole stop, far below the outside 101 kPa: that is the vacuum the brake booster works with.
- The fuel comes back at 12.0 s, at 10.4 km/h, as the engine passes 1000 rpm, and the clutch opens at the same moment. The engine **does not stall**: it idles at **775 rpm** while the brake holds the car at rest.

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

### 07 Bonus: drive the WLTC <Badge type="warning" text="extra points" /> {#wltc}

Your cruise controller from Lecture 1 drives your car over the 30-minute trace a car's label is measured on. For when you have finished step 06; hand it in with your pull request.

::: info Why a driving cycle

Step 05 gave three numbers at three steady speeds, and none of them is how anyone drives. The label is measured over a fixed speed trace, the WLTC: for a car of this power, class 3b, 1800 s through town, suburb, road and motorway, up to 131.3 km/h, 23.27 km, with 242 s standing still. A test driver follows it within **±2 km/h and ±1 s**; the fuel burned over the whole trace, divided by the distance driven, is the figure on the label. A real 1.5 L petrol car with this engine family, the Mazda2 1.5 Skyactiv-G, reads **5.3 L/100 km, 120 g CO₂/km**.

:::

#### The task

Build the bench, a new component `MappedCarWLTC`, yourself: this is the task, so neither this page nor the course library shows the finished model. It has to

- give your `CruiseController` from Lecture 1, step 6d, the trace as its setpoint and your car's speed as its measurement;
- turn its one output, an effort from −1 to +1, into two commands: the positive part to the pedal, the negative part, times a maximum brake force of 4000 N (step 06's), to the brake;
- add up the fuel burned in liters and the distance driven in kilometers, over the whole run.

The parts you need, all of them ones you have used:

| Part | Where | Hint |
| --- | --- | --- |
| the trace | `VehicleSystemsComponents › Vehicle › DriveCycle` | given: its output `y` is the WLTC class 3b target speed in km/h |
| the driver | your `CruiseController` | see **Advice** below for the limits, gains and initial states |
| the car | your `MappedCar` from step 06 B | it has the `pedal` and `F_brake` inputs and the `v_kmh` and `fuel_lph` outputs you need |
| the split | `BlockComponents › Nonlinear › Limiter`, `BlockComponents › Math › Gain` | a limiter passes only the part of a signal between its `y_min` and `y_max` |
| the sums | `BlockComponents › Continuous › Integrator` | an integrator with `k = 1/3600` turns L/h into liters, and km/h into kilometers |

Name the trace `trace`, the controller `driver`, the car `car`, and the two integrators `fuel_L` and `dist_km`: the snippets below use these names.

#### Run it

1. Start the car as step 04's bench does: at rest, the engine idling, the angles set. Copy the six `initial` lines of `MappedCarWOT`, then change two of them to start the engine at the idle step 06 ended in, 775 rpm and 33.6 kPa:

   ```txt
   initial car.flywheel.w = 775 * pi / 30
   initial car.engine.air.manifold.p = 33600
   ```
2. <Badge type="tip" text="New analysis" /> ▷ → **Create New Analysis** → `TransientAnalysis` → name it `MappedCarWLTCTransient`. Open its code and make the `extends` line:

   ```txt
   extends TransientAnalysis(stop = 1800, saveat = 1, alg = ODEAlg.Rodas5P())
   ```

   Run it. The first run is mostly compilation, about a minute; every run after it takes 5–10 s. If it is too slow, run `stop = 1022` instead: the Low and Medium phases, 7.85 km, for partial credit.
3. Plot the speed over the target, and the error. In a Studio you opened after the session, run `using Plots` first:

   ```julia
   r = MyCar.MappedCarWLTCTransient()
   plot(r; idxs = [r."car.v_kmh", r."trace.y"])
   plot(r; idxs = r."driver.error.y")         # target minus speed
   ```

4. Read the label numbers at the end, and the share of the run inside the band:

   ```julia
   T = 1800                                   # 1022 if you ran stop = 1022
   L, km = r.sol(T, idxs = r."fuel_L.y"), r.sol(T, idxs = r."dist_km.y")
   100L / km, 2302L / km                      # L/100 km, g CO₂/km

   ts = 0:0.1:T
   v  = r.sol(ts, idxs = r."car.v_kmh").u
   vt = r.sol(ts, idxs = r."trace.y").u
   w(i) = max(1, i - 10):min(length(ts), i + 10)   # ±1 s
   inside = [minimum(vt[w(i)]) - 2 <= v[i] <= maximum(vt[w(i)]) + 2 for i in eachindex(ts)]
   count(inside) / length(ts)                 # share of the run inside ±2 km/h, ±1 s
   ```

::: warning Advice

- **Solver.** Set `alg = ODEAlg.Rodas5P()` in the analysis's `extends` line, as in step 2. With the default solver the full cycle stops at 1190 s with `MaxIters`.
- **Gains.** Start from `k = 0.14`, `Ti = 3.5`, `Td = 0.7`. Lecture 1's `k = 56` was N·m of torque per km/h; here the output is an effort of ±1, and `k` is 400 times smaller. Keep `Td` above zero: the derivative filter's time constant is `Td / Nd`.
- **Initial states.** `xd0 = 0` and `xi0 = 0`. Step 6d's `xd0 = -90` was the seed for a 90 km/h cruise; from rest it kicks the derivative at the first instant.
- **Limits.** `y_min = -1`, `y_max = 1`. Lecture 1's benches set `y_min = 0`: the output then never goes negative and the brake gets no command. On the course's run the effort stays between −0.67 and +0.29.
- **Low phase first.** Check the wiring on the first 589 s, `MyCar.MappedCarWLTCTransient(stop = 589)`: 3.10 km at 6.30 L/100 km. The first run of a model is mostly compilation, about a minute; runs after it take seconds.
- **Divide by `dist_km`,** from the same run, not by the cycle's 23.27 km.
- **A short lag after each stop.** The brake holds the car at rest, and the integrator keeps a negative value meanwhile, down to −4.8 on the course's run. 2 s into the next launch the car is up to 3.7 km/h behind the trace: inside the ±1 s tolerance, and none of the run's band misses is at a launch. To remove it, an extra: integrate only while the car moves, or reset the integrator at standstill.
- **Judge the band, not ±2 km/h alone.** The error leaves ±2 km/h for 14 % of the run, at every steep change of the trace; the ±1 s takes most of it back. The 1.5 % left outside the band is 13 short stretches, mostly at 10–25 km/h with the car 2–4 km/h behind.

:::

::: info Why divide by the distance you drove

The trace is 23.27 km, but your car drives its own distance. A car that lags the trace drives less and burns less, and divided by 23.27 km it would look more frugal than it is. Fuel and distance from the same run keep it honest.

:::

[![MappedCarWLTCTransient over 1800 s, two panels, dotted lines at the phase boundaries 589, 1022 and 1477 s. Speed: car.v_kmh dashed over trace.y, the two hard to tell apart, up to 131 km/h in the Extra High phase. Error, driver.error.y: mostly within the dashed ±2 km/h, with spikes to about ±5 km/h at the steepest changes, the largest 6.4 km/h at 961 s; flat near zero through the smooth High phase from 1150 to 1350 s.](/handson/lecture-02/img/step07-wltc-plot.png){width="990" height="528"}](/handson/lecture-02/img/step07-wltc-plot.png)

::: tip Checkpoint

From the course's own run of this test:

- Distance **23.27 km**, the trace's own: the car keeps up.
- Inside the ±2 km/h, ±1 s band for **98.5 %** of the run. Inside ±2 km/h alone, for only 86 %: on a steep ramp, a second behind is several km/h.
- **1.214 L** of fuel: **5.22 L/100 km**, **120 g CO₂/km**. By phase: Low 6.30, Medium 5.14, High 4.59, Extra High 5.41 L/100 km.
- Low and Medium only (`stop = 1022`): **7.85 km**, **5.59 L/100 km**, **129 g CO₂/km**, 98.6 % inside the band.

:::

#### What to hand in

In your pull request's description, under a heading `Bonus: WLTC`:

1. **Tracking.** The speed over the target and the error, as pictures, and the share of the run inside the ±2 km/h, ±1 s band. It counts at **95 %** or more.
2. **The label numbers.** L/100 km and g CO₂/km, with the fuel in liters and the distance in kilometers you divided. They count inside **±0.25 L/100 km** of the course's figures: 4.97–5.47 L/100 km and 114–126 g CO₂/km for the full cycle, 5.34–5.84 L/100 km for the Low and Medium phases.
3. **One paragraph:** why your figure differs from the Mazda2's 5.3 L/100 km and 120 g/km. Think of what step 05 showed at 50 km/h, of whose engine the maps are, and of how the real test starts its engine.

Say whether you ran the full 1800 s or the Low and Medium phases only.

Commit: **Source Control** → message `Step 07: WLTC bonus` → **Commit** → **Sync Changes**.

---

Data: `data/engine/` in the course repository, from the US EPA ALPHA package (2014 Mazda 2.0L SKYACTIV Engine LEV III Fuel, version 2018-02). Design notes: `docs/lecture-02-mapped-engine-plan.md` and `docs/lecture-02-handson-plan.md`.
